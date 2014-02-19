//
//  TimerService.m
//  Eko
//
//  Created by David Zhang on 12/12/13.
//
//

#import "TimerService.h"

@implementation TimerService

+ (TimerService *)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (dispatch_source_t)createIntervalTimerWithInterval:(NSInteger)interval queue:(dispatch_queue_t)queue andBlock:(dispatch_block_t)block
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    uint64_t interval_ns = interval * NSEC_PER_MSEC;
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval_ns, 0.3*interval_ns);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

- (void)suspendIntervalTimerWithSource:(dispatch_source_t)timer
{
    dispatch_source_cancel(timer);
}

@end
