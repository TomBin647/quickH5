//
//  H5ResourceCache.h
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface H5ResourceCache : NSObject

//  缓存是否存在
- (BOOL)contain:(NSString *)key;


- (void)setData:(NSData *)data forKey:(NSString *)key;

- (NSData *)dataForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
