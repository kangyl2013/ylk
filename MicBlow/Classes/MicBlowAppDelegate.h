//
//  MicBlowAppDelegate.h
//  MicBlow
//
//  Created by Yu on 11-5-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MicBlowAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UIViewController *controller;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UIViewController *controller;

@end

