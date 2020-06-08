//
//  NSString+Util.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "NSString+Util.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CoreServices/CoreServices.h>

@implementation NSString (Util)

- (NSString *)stringToMD5
{
    //1.首先将字符串转换成UTF-8编码, 因为MD5加密是基于C语言的,所以要先把字符串转化成C语言的字符串
    const char *fooData = [self UTF8String];
    
    //2.然后创建一个字符串数组,接收MD5的值
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    //3.计算MD5的值, 这是官方封装好的加密方法:把我们输入的字符串转换成16进制的32位数,然后存储到result中
    CC_MD5(fooData, (CC_LONG)strlen(fooData), result);
    /**
     第一个参数:要加密的字符串
     第二个参数: 获取要加密字符串的长度
     第三个参数: 接收结果的数组
     */
    
    //4.创建一个字符串保存加密结果
    NSMutableString *saveResult = [NSMutableString string];
    
    //5.从result 数组中获取加密结果并放到 saveResult中
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [saveResult appendFormat:@"%02x", result[i]];
    }
    /*
     x表示十六进制，%02X  意思是不足两位将用0补齐，如果多余两位则不影响
     NSLog("%02X", 0x888);  //888
     NSLog("%02X", 0x4); //04
     */
    return saveResult;
}

- (BOOL)isJSOrCSSFile {
    if (self.length == 0) {
        return NO;
    }
    NSString * pattern = @"\\.(js|css)";
    
    NSRegularExpression * result = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray * array = [result matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    if (array.count > 0) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *) mimeType:(NSString *)pathExtension {
    if (!pathExtension) {
        return @"application/octet-stream";
    }
    NSString * uti = (__bridge NSString *)(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)(pathExtension), nil));
    if (uti) {
        NSString * mimetype = (__bridge NSString *)(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(uti), kUTTagClassMIMEType));
        return mimetype;
    } else {
        //文件资源类型如果不知道，传万能类型application/octet-stream，服务器会自动解析文件类
        return @"application/octet-stream";
    }
}

@end
