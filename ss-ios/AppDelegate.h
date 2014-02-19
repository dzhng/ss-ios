//
//  AppDelegate.h
//  ss-ios
//
//  Created by David Zhang on 2/18/14.
//  Copyright (c) 2014 David Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stream.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, StreamDelegate> {
    Stream *stream;
}

@property (strong, nonatomic) UIWindow *window;

@end
