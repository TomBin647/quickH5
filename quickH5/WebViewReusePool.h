//
//  WebViewReusePool.h
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ReuseWebView.h"


NS_ASSUME_NONNULL_BEGIN

@interface WebViewReusePool : NSObject

+(instancetype)shared;

@property (nonatomic,strong) WKWebViewConfiguration * defaultConfigeration;

- (ReuseWebView *)getReusedWebView:(id)holder;

- (void)prepareWebView;

@end

NS_ASSUME_NONNULL_END
