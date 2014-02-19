//
//  Socket.m
//  Eko
//
//  Created by David Zhang on 12/7/13.
//
//

#import "Socket.h"
#import "SocketPackets.h"
#import "TimerService.h"

static const BOOL kSecureConnection = YES;
static NSString *const kHost = @"app.ekoapp.com";
static const NSInteger kPort = 443;

// interval for reconnecting to websocket, in ms
static const NSInteger kReconnectInterval = 2000;

@interface Socket ()

// setup ping interval
- (void)performPingAtInterval:(NSInteger)interval;
- (void)stopPing;

// watchdog timers to make sure we're still connected
- (void)setupWatchdogAtInterval:(NSInteger)interval;
- (void)kickWatchdog;
- (void)stopWatchdog;

// cleanup datastructures after a socket has been closed
- (void)cleanupSocket;

// schedule a reconnect 
- (void)tryReconnect;

// manage socket states, and call the necessary delegate state functions
- (void)setSocketState:(SocketState)state;

@end

@implementation Socket

#pragma mark - Instance functions

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        // set defaults
        socketURL = url;
        self.state = SocketStateDefault;
    }
    return self;
}

- (void)connectToServer
{
    // if we're already trying to connect to server, just return
    if (socket && (socket.readyState == SR_CONNECTING || socket.readyState == SR_OPEN)) {
        return;
    }
    
    // cleanup any old remaining data
    [self cleanupSocket];
    
    // since SRWebSocket is only meant to be opened once, always instantiate a new one
    NSLog(@"Attempting to connect to websocket...");
    socket = [[SRWebSocket alloc] initWithURL:socketURL];
    socket.delegate = self;
    [socket open];
}

- (void)disconnect {
    // we want to cleanup socket as well as close it, this way we don't get an extra "didClose" delegate call
    socket.delegate = nil;
    [socket closeWithCode:-1 reason:@"Manually disconnected"];
    [self cleanupSocket];
    
    [self setSocketState:SocketStateDisconnected];
}

#pragma mark - Private functions

- (void)sendMessage:(NSString *)message
{
    NSString *msg = [NSString stringWithFormat:@"%d%@", PacketTypeMessage, message];
    if (socket && socket.readyState == SR_OPEN) {
        NSLog(@"Sent message: %@", msg);
        [socket send:msg];
    }
    else {
        NSLog(@"Socket not opened, not sending message: %@", msg);
    }
}

- (void)performPingAtInterval:(NSInteger)interval
{
    NSString *pingMessage = [NSString stringWithFormat:@"%dping", PacketTypePing];
    
    // stop previous ping timers
    [self stopPing];
    
    pingTimer = [[TimerService sharedInstance] createIntervalTimerWithInterval:interval queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) andBlock:^{
        // ping the server
        if (socket) {
            [socket send:pingMessage];
        }
    }];
}

- (void)stopPing
{
    if (pingTimer) {
        [[TimerService sharedInstance] suspendIntervalTimerWithSource:pingTimer];
        pingTimer = nil;
    }
}

- (void)setupWatchdogAtInterval:(NSInteger)interval
{
    // if timer already exist, stop it first
    [self stopWatchdog];
    
    watchdogTimer = [[TimerService sharedInstance] createIntervalTimerWithInterval:interval queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) andBlock:^{
        // if the watchdog still hasn't been kicked during this entire interval,
        // something is wrong with the server, and we should close the socket
        if (!watchdogKicked) {
            if (socket) {
                NSLog(@"Watchdog timer closing socket");
                [socket closeWithCode:-1 reason:@"Server unresponsive"];
            }
				[self stopWatchdog];
        }
        watchdogKicked = NO;
    }];
    
    // startoff with a kicked watchdog
    [self kickWatchdog];
}

- (void)kickWatchdog
{
    // just set the flag, all other logic is in timer block
    watchdogKicked = YES;
}

- (void)stopWatchdog
{
    if (watchdogTimer) {
        [[TimerService sharedInstance] suspendIntervalTimerWithSource:watchdogTimer];
        watchdogTimer = nil;
    }
}

- (void)cleanupSocket
{
    socket = nil;
    [self stopPing];
    [self stopWatchdog];
    [self kickWatchdog];
}

- (void)tryReconnect
{
    // make sure we don't have multiple reconnect scheduled (can cause a cascade of tryReconnect calls)
    static BOOL reconnectScheduled = NO;

    if (!reconnectScheduled) {
		 // make sure watchdog and ping timers are disabled
		 [self stopPing];
		 [self stopWatchdog];
		 
        reconnectScheduled = YES;
        double delayInMilliSeconds = kReconnectInterval;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInMilliSeconds * NSEC_PER_MSEC));
        dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [self connectToServer];
            reconnectScheduled = NO;
        });
    }
}

- (void)setSocketState:(SocketState)state
{
    // used to track if the stream has ever connected before
    static BOOL wasConnected = NO;
    static SocketState oldState = SocketStateDefault;
    
    // don't do anything if the state didn't change
    if (state == oldState) {
        return;
    }
    
    if (state == SocketStateConnected) {
        if (wasConnected) {
            [self.delegate didReconnect];
        }
        else {
            [self.delegate didConnect];
        }
        wasConnected = YES;
    }
    else if (state == SocketStateDisconnected) {
        [self.delegate didDisconnect];
    }
    
    oldState = self.state = state;
}

#pragma mark - Web socket delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Did connect to websocket");
    [self setSocketState:SocketStateConnected];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    // only process message if it's a string type message
    if (![[message class] isSubclassOfClass:[NSString class]]) {
        return;
    }
    
    @try {
        // first character identifies the packet type
        // since it's a char, offset by 48 to get true int value
        PacketType type = [message characterAtIndex:0] - 48;
        
        // the message data is rest of packet
        NSString *data = [message substringFromIndex:1];
        
        switch (type) {
            case PacketTypeOpen: { // open packet
                // parse JSON data and set necessary parameters
                NSError *error;
                NSDictionary* parsed = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
                if (error) {
                    NSLog(@"Error parsing packen open data: %@ | %@", data, error);
                    return;
                }
                
                sid = parsed[@"sid"];
                pingInterval = [parsed[@"pingInterval"] integerValue];
                pingTimeout = [parsed[@"pingTimeout"] integerValue];
                [self performPingAtInterval:pingInterval];
                [self setupWatchdogAtInterval:pingTimeout];
                [self kickWatchdog];
                break;
            }
            case PacketTypeClose: { // close packet
                [socket closeWithCode:-1 reason:@"Server requested socket be closed"];
                break;
            }
            case PacketTypePing: { // ping packet
                // send back a pong packet
                [socket send:[NSString stringWithFormat:@"%dprobe", PacketTypePong]];
                break;
            }
            case PacketTypePong: {
                // don't do anything for pong packets, since it's probably just the server
                // responding to our regular pings
                break;
            }
            case PacketTypeMessage: { // message packet
                [self.delegate didReceiveMessage:data];
                break;
            }
            default: {
                NSLog(@"Stream: Unknown packet type %d", type);
                break;
            }
        }
        
        // kick watchdog everytime we get a new message
        [self kickWatchdog];
    }
    @catch (NSException *e) {
        NSLog(@"Socket: Exception on ws message: %@, %@", message, e);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    // TODO: should look at code, and not reconnect when close reason is requested by the client
    NSLog(@"Websocket closed: %d, %@, clean: %d", code, reason, wasClean);
    [self setSocketState:SocketStateDisconnected];
    [self tryReconnect];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"Websocket failed: %@", error);
    [self setSocketState:SocketStateDisconnected];
    [self tryReconnect];
}

@end
