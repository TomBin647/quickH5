//
//  NSString+Util.h
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Util)

- (NSString *)stringToMD5;

- (BOOL)isJSOrCSSFile;

+ (NSString *) mimeType:(NSString *)pathExtension;

@end

NS_ASSUME_NONNULL_END
