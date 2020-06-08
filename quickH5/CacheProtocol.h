//
//  Cacheable.h
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CacheProtocol <NSObject>

// 缓存总数量
- (uint)totalCount;

// 缓存总大小
- (uint)totalCost;

//  缓存是否存在
- (BOOL)contain:(NSString *)key;

// 返回指定key的缓存
- (id)object:(NSString *)key;

// 设置缓存 k、v
//- (void)setObject:(id)object forKey:(NSDictionary *)key;

// 设置缓存 k、v、c
- (void)setObject:(id)object forKey:(NSString *)key cost:(uint)g;

// 删除指定key的缓存
- (void)removeObject:(NSString *)key;

// 删除所有缓存
- (void)removeAllObject;

// 根据缓存大小清理
- (void)trimWithCost:(uint)cost;

// 根据缓存数量清理
- (void)trimWithCount:(uint)count;

// 根据缓存时长清理
- (void)trimWithAge:(uint)age;

@end

