//
//  AppDelegate.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "WebViewReusePool.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[WebViewReusePool shared] prepareWebView];
    ViewController * view = [[ViewController alloc] init];

    UINavigationController * navi = [[UINavigationController alloc] initWithRootViewController:view];
    
    self.window.rootViewController = navi;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
