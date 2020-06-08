//
//  WebViewReusePool.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "WebViewReusePool.h"
#import "CustomURLSchemeHandler.h"

@interface WebViewReusePool () {
    dispatch_semaphore_t lock;
}

@property (nonatomic,strong) NSMutableSet<ReuseWebView *> * visiableWebViewSet;

@property (nonatomic,strong) NSMutableSet<ReuseWebView *> * reusableWebViewSet;

@end

@implementation WebViewReusePool

+(instancetype)shared {
    static WebViewReusePool * reusePool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reusePool = [[WebViewReusePool alloc] init];
    });
    return reusePool;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.defaultConfigeration = [[WKWebViewConfiguration alloc] init];
        WKPreferences * preferences = [[WKPreferences alloc] init];
        preferences.javaScriptCanOpenWindowsAutomatically = YES;
        self.defaultConfigeration.preferences = preferences;
        
        if (![self.defaultConfigeration urlSchemeHandlerForURLScheme:@"customScheme"]) {
            CustomURLSchemeHandler * hander = [[CustomURLSchemeHandler alloc] init];
            [self.defaultConfigeration setURLSchemeHandler:hander forURLScheme:@"customScheme"];
        }
        
        self.visiableWebViewSet = [[NSMutableSet alloc] init];
        self.reusableWebViewSet = [[NSMutableSet alloc] init];
        
        lock = dispatch_semaphore_create(1);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarningNotification {
    [self clearReusableWebViews];
}

- (void)prepareWebView {
    dispatch_async(dispatch_get_main_queue(), ^{
        ReuseWebView * webview = [[ReuseWebView alloc] initWithFrame:CGRectZero configuration:self.defaultConfigeration];
        [self.reusableWebViewSet addObject:webview];
    });
}

- (void)tryCompactWeakHolders {
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSMutableSet * shouldreusedWebViewSet = [[NSMutableSet alloc] init];
    
    for (ReuseWebView * webview in self.visiableWebViewSet) {
        if (webview.holdObject) {
            [shouldreusedWebViewSet addObject:webview];
        }
    }
    
    for (ReuseWebView * webview in shouldreusedWebViewSet) {
        [webview endReuse];
        [self.visiableWebViewSet removeObject:webview];
        [self.reusableWebViewSet addObject:webview];
    }
    dispatch_semaphore_signal(lock);
}

- (ReuseWebView *)getReusedWebView:(id)holder {
    [self tryCompactWeakHolders];
    
    ReuseWebView * webview;
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    
    if (self.reusableWebViewSet.count > 0) {
        webview = [self.reusableWebViewSet anyObject];
        [self.reusableWebViewSet removeObject:webview];
        [self.visiableWebViewSet addObject:webview];
    } else {
        webview = [[ReuseWebView alloc] initWithFrame:CGRectZero configuration:self.defaultConfigeration];
    }
    
    webview.holdObject = holder;
    
    dispatch_semaphore_signal(lock);
    
    return webview;
}

- (void)recycleReusedWebView:(ReuseWebView *)webview {
    if (!webview) {
        return;
    }
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    if ([self.visiableWebViewSet containsObject:webview]) {
        [webview endReuse];
        [self.visiableWebViewSet removeObject:webview];
        [self.reusableWebViewSet addObject:webview];
    }
    dispatch_semaphore_signal(lock);
}

- (void)clearReusableWebViews {
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    [self.reusableWebViewSet removeAllObjects];
    dispatch_semaphore_signal(lock);
    [ReuseWebView clearAllWebCache];
}

-(void)dealloc {
    
}

@end
