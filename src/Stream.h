//
//  Stream.h
//  Eko
//
//  Created by David Zhang on 12/7/13.
//
//

#import <Foundation/Foundation.h>
#import "Socket.h"

typedef void (^StreamCallback)(NSArray *params);

@class Stream;

@protocol StreamDelegate

- (void)streamDidConnect:(Stream *)stream;
- (void)streamDidReconnect:(Stream *)stream;
- (void)streamDidDisconnect:(Stream *)stream;

@end

@interface Stream : NSObject <SocketDelegate> {
    // transport socket
    Socket *socket;
    
    // client session
    NSString *sessionId;
    
    // dictionary of callback functions binded
    NSMutableDictionary *bindCallbacks;
    
    // dictionary of RPC return values
    NSMutableDictionary *rpcCallbacks;
    NSInteger rpcId;
}

@property (nonatomic, weak) id<StreamDelegate> delegate;

- (id)initWithHost:(NSString *)host port:(NSInteger)port secure:(BOOL)secure;

// connection functions
- (void)connectToServer;
- (void)disconnect;

- (void)bind:(NSString *)channel withCallback:(StreamCallback)callback;
- (void)rpc:(NSString *)method withParameters:(NSArray *)params andCallback:(StreamCallback)callback;

@end
