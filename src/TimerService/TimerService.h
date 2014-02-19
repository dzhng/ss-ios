//
//  TimerService.h
//  Eko
//
//  Created by David Zhang on 12/12/13.
//
//

#import <Foundation/Foundation.h>

@interface TimerService : NSObject

+ (TimerService *)sharedInstance;

// create an interval timer with interval in ms
- (dispatch_source_t)createIntervalTimerWithInterval:(NSInteger)interval queue:(dispatch_queue_t)queue andBlock:(dispatch_block_t)block;

- (void)suspendIntervalTimerWithSource:(dispatch_source_t)timer;

@end
