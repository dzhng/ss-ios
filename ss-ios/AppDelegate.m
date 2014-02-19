//
//  AppDelegate.m
//  ss-ios
//
//  Created by David Zhang on 2/18/14.
//  Copyright (c) 2014 David Zhang. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // establish connection with localhost
    stream = [[Stream alloc] initWithHost:@"localhost" port:9002 secure:NO];
    stream.delegate = self;
    [stream connectToServer];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [stream disconnect];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [stream connectToServer];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Stream Delegate

- (void)streamDidConnect:(Stream *)stream
{
    NSLog(@"Stream did connect");
    [stream rpc:@"hello.world" withParameters:nil andCallback:^(NSArray *params) {
        NSLog(@"RPC call results: %@", params);
    }];
}

- (void)streamDidDisconnect:(Stream *)stream
{
    NSLog(@"Stream did disconnect");
}

- (void)streamDidReconnect:(Stream *)stream
{
    NSLog(@"Stream did reconnect");
}

@end
