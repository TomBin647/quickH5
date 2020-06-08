//
//  ViewController.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "WebViewReusePool.h"

@interface ViewController ()<WKNavigationDelegate>

@property (nonatomic,strong) ReuseWebView * webview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated {
    ReuseWebView * webview = [[WebViewReusePool shared]getReusedWebView:self];
    webview.frame = CGRectMake(0, 0, 375, 600);
    webview.navigationDelegate = self;
    self.webview = webview;
    [self.view addSubview:self.webview];
    NSURL * url = [NSURL URLWithString:@"customScheme://langeasy.com.cn/"];
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:urlRequest];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    NSString *urlStr = url.absoluteString;
    NSLog(@"%@",urlStr);
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"加载完毕");
}

@end
