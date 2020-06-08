//
//  ReuseWebView.h
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface ReuseWebView : WKWebView

@property (nonatomic,strong) id holdObject;

+ (void)clearAllWebCache;

- (void)willReuse;

- (void)endReuse;

@end
