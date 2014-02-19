//
//  Stream.h
//  Eko
//
//  Created by David Zhang on 12/7/13.
//
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

// socket state is used to tell the current state of server connection
typedef enum {
    SocketStateDefault,
    SocketStateConnected,
    SocketStateDisconnected,
} SocketState;

@protocol SocketDelegate <NSObject>

- (void)didReceiveMessage:(NSString *)message;
- (void)didDisconnect;
- (void)didReconnect;
- (void)didConnect;

@end

@interface Socket : NSObject <SRWebSocketDelegate> {
    NSURL *socketURL;
    
    // websocket transport
    SRWebSocket *socket;
    
    // socket connection settings
    NSString *sid;
    NSInteger pingInterval;
    NSInteger pingTimeout;
    
    // watchdog settings
    BOOL watchdogKicked;
    
    // timer ids;
    dispatch_source_t pingTimer;
    dispatch_source_t watchdogTimer;
}

@property (nonatomic, weak) id<SocketDelegate> delegate;
@property (nonatomic, assign) SocketState state;

- (id)initWithURL:(NSURL *)url;

- (void)connectToServer;
- (void)disconnect;
- (void)sendMessage:(NSString *)message;

@end
