//
//  ReuseWebView.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "ReuseWebView.h"

@implementation ReuseWebView

+ (void)clearAllWebCache {
    NSSet * set = [NSSet setWithArray:@[WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]];
    
    NSDate * data = [NSDate dateWithTimeIntervalSince1970:0];
    
    [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:set modifiedSince:data completionHandler:^{
        
    }];
}

- (void)dealloc {
    [self.configuration.userContentController removeAllUserScripts];
    [self stopLoading];
    self.UIDelegate = nil;
    self.navigationDelegate = nil;
    self.holdObject = nil;
    NSLog(@"WKWebView 销毁了！！！");
}

- (void)willReuse {
    
}

- (void)endReuse {
    self.holdObject = [NSNull null];
    self.scrollView.delegate = nil;
    [self stopLoading];
    self.navigationDelegate = nil;
    self.UIDelegate = nil;
    [self loadHTMLString:@"" baseURL:nil];
}

@end
