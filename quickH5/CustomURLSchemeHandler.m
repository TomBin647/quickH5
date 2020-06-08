//
//  CustomURLSchemeHandler.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "CustomURLSchemeHandler.h"
#import <AFNetworking.h>
#import "H5ResourceCache.h"
#import "NSString+Util.h"
#import "SDWebImageManager.h"

@interface CustomURLSchemeHandler ()

@property (nonatomic,strong) AFHTTPSessionManager * httpSessionManager;

@property (nonatomic,strong) NSMutableDictionary * holdUrlSchemeTasks;

@property (nonatomic,strong) H5ResourceCache * resourceCache;

@end

@implementation CustomURLSchemeHandler

- (instancetype) init {
    self = [super init];
    if (self) {
        self.holdUrlSchemeTasks = [[NSMutableDictionary alloc] init];
        self.resourceCache = [[H5ResourceCache alloc] init];
    }
    return self;
}

- (AFHTTPSessionManager *)httpSessionManager {
    if (_httpSessionManager == nil) {
        _httpSessionManager = [[AFHTTPSessionManager alloc] init];
        _httpSessionManager.requestSerializer = [[AFHTTPRequestSerializer alloc] init];
        _httpSessionManager.responseSerializer = [[AFHTTPResponseSerializer alloc] init];
        _httpSessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithArray:@[@"text/html", @"application/json", @"text/json", @"text/javascript", @"text/plain", @"application/javascript", @"text/css", @"image/svg+xml", @"application/font-woff2", @"font/woff2", @"application/octet-stream"]];
    }
    return _httpSessionManager;;
}

- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask  API_AVAILABLE(ios(11.0)){
    [self.holdUrlSchemeTasks setObject:[NSNumber numberWithBool:YES] forKey:urlSchemeTask.description];
    NSDictionary * headers = urlSchemeTask.request.allHTTPHeaderFields;
    if (![headers.allKeys containsObject:@"Accept"]) {
        return;
    }
    if (!urlSchemeTask.request.URL.absoluteString) {
        return;
    }
    NSString * accept = [headers objectForKey:@"Accept"];
    NSString * requestUrlString = urlSchemeTask.request.URL.absoluteString;
    if (accept.length >= [@"text" length] && [accept containsString:@"text/html"]) {
        NSLog(@"html = %@",requestUrlString);
        [self loadLocalFile:[self creatCacheKey:urlSchemeTask] urlSchemeTask:urlSchemeTask];
    } else if (requestUrlString.isJSOrCSSFile) {
        NSLog(@"js || css = %@",requestUrlString);
        [self loadLocalFile:[self creatCacheKey:urlSchemeTask] urlSchemeTask:urlSchemeTask];
    } else if (accept.length >= [@"image" length] && [accept containsString:@"image"]) {
        NSLog(@"image = %@",requestUrlString);
        NSString * originUrlString = urlSchemeTask.request.URL.absoluteString;
        if ([originUrlString containsString:@"customscheme"]) {
            originUrlString = [originUrlString stringByReplacingOccurrencesOfString:@"customscheme" withString:@"https"];
            [[SDWebImageManager sharedManager] loadImageWithURL:[NSURL URLWithString:originUrlString] options:SDWebImageRetryFailed progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                if (image) {
                    NSData * imageData = UIImageJPEGRepresentation(image, 1);
                    if (!imageData) {
                        return;
                    }
                    [self resendRequset:urlSchemeTask mineType:@"image/jpeg" requestData:imageData];
                } else {
                    [self loadLocalFile:[self creatCacheKey:urlSchemeTask] urlSchemeTask:urlSchemeTask];
                }
            }];
        } else {
            return;
        }
    } else {
        NSLog(@"other resources = %@",requestUrlString);
        NSString * cacheKey = [self creatCacheKey:urlSchemeTask];
        if (!cacheKey) {
            return;
        }
        [self requestRomote:cacheKey urlSchemeTask:urlSchemeTask];
    }
}

//加载本地资源
- (void)loadLocalFile:(NSString *)fileName urlSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    if (fileName == nil && fileName.length == 0) {
        return;
    }
    if ([self.resourceCache contain:fileName]) {
        NSLog(@"有缓存");

        NSData * data = [self.resourceCache dataForKey:fileName];
        if (!data) {
            return;
        }
        NSString * mimeType = [NSString mimeType:[self creatCacheKey:urlSchemeTask]];
        [self resendRequset:urlSchemeTask mineType:mimeType requestData:data];
    } else {
        NSLog(@"没有缓存");
        [self requestRomote:fileName urlSchemeTask:urlSchemeTask];
    }
}

- (void)requestRomote:(NSString *)fileName urlSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    NSString * urlString = urlSchemeTask.request.URL.absoluteString;
    if ([urlString containsString:@"customscheme"]) {
        urlString = [urlString stringByReplacingOccurrencesOfString:@"customscheme" withString:@"https"];
    } else {
        return;
    }
    NSLog(@"开始重新发送网络请求");
    [self.httpSessionManager GET:urlString parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        id isValid = self.holdUrlSchemeTasks[urlSchemeTask.description];
        if (!isValid) {
            return;
        }
        if (!(task.response && responseObject)) {
            return;
        }
        
        [urlSchemeTask didReceiveResponse:task.response];
        [urlSchemeTask didReceiveData:responseObject];
        [urlSchemeTask didFinish];
        NSString * accept = [urlSchemeTask.request.allHTTPHeaderFields objectForKey:@"Accept"];
        if (!accept) {
            return;
        }
        if (!(accept.length > [@"image" length] && [accept containsString:@"image"])) {
            // 图片不下载
            [self.resourceCache setData:responseObject forKey:fileName];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error.localizedDescription);
        id isValid = self.holdUrlSchemeTasks[urlSchemeTask.description];
        if (!isValid) {
            return;
        }
        // 错误处理
        [urlSchemeTask didFailWithError:error];
    }];
}
    
- (void)resendRequset:(nonnull id<WKURLSchemeTask>)urlSchemeTask mineType:(NSString *)mineType requestData:(NSData *)requestData {
    NSURL * url = urlSchemeTask.request.URL;
    if (!url) {
        return;
    }
    id isValid = self.holdUrlSchemeTasks[urlSchemeTask.description];
    if (!isValid) {
        return;
    }
    
    NSString * mineT = mineType ? : @"text/html";
    
    NSURLResponse * response = [[NSURLResponse alloc] initWithURL:url MIMEType:mineT expectedContentLength:[requestData length] textEncodingName:@"utf-8"];
    [urlSchemeTask didReceiveResponse:response];
    [urlSchemeTask didReceiveData:requestData];
    [urlSchemeTask didFinish];
}

- (NSString *)creatCacheKey:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    NSString * fileName = urlSchemeTask.request.URL.absoluteString;
    if ([fileName containsString:@"customscheme://"]) {
        fileName = [fileName stringByReplacingOccurrencesOfString:@"customscheme://" withString:@""];
    } else {
        return nil;
    }
    NSString * extensionName = urlSchemeTask.request.URL.pathExtension;
    
    NSString * result = [fileName stringToMD5];
    if (extensionName.length == 0) {
        result = [result stringByAppendingString:@".html"];
    } else {
        result = [result stringByAppendingFormat:@".%@",extensionName];
    }
    return result;
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask
    API_AVAILABLE(ios(11.0)){
    
}


@end
