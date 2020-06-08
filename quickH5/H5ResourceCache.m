//
//  H5ResourceCache.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "H5ResourceCache.h"
#import "MemoryCache.h"
#import "DiskFileCache.h"
#import "NSString+Util.h"

@interface H5ResourceCache () {
    // 内存缓存大小：10M
    uint kMemoryCacheCostLimit;
    // 磁盘文件缓存大小： 10M
    uint kDiskCacheCostLimit;
    // 磁盘文件缓存时长：30 分钟
    NSTimeInterval kDiskCacheAgeLimit;
}

@property (nonatomic,strong) MemoryCache * memoryCache;

@property (nonatomic,strong) DiskFileCache * diskCache;

@end

@implementation H5ResourceCache

- (instancetype) init {
    self = [super init];
    if (self) {
        kMemoryCacheCostLimit = 10 * 1024 * 1024;
        kDiskCacheCostLimit = 10 * 1024 * 1024;
        kDiskCacheAgeLimit = 30 * 60;
        
        self.memoryCache = [MemoryCache shared];
        self.memoryCache.costLimit = kMemoryCacheCostLimit;
        
        self.diskCache = [[DiskFileCache alloc]initWithCacheDirectoryName:@"H5ResourceCache"];
        self.diskCache.costLimit = kDiskCacheCostLimit;
        self.diskCache.ageLimit = kDiskCacheAgeLimit;
    }
    return self;
}

//  缓存是否存在
- (BOOL)contain:(NSString *)key {
    return [self.memoryCache contain:key] || [self.diskCache contain:key];
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    NSString * dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self.memoryCache setObject:[dataString dataUsingEncoding:NSUTF8StringEncoding] forKey:key cost:(uint)[data length]];
    
    [self.diskCache setObject:[dataString dataUsingEncoding:NSUTF8StringEncoding] forKey:key cost:(uint)[data length]];
}

- (NSData *)dataForKey:(NSString *)key {
    NSData * data = [self.memoryCache object:key];
    if (data) {
        NSLog(@"这是内存缓存");
        return data;
    } else {
        NSData * data = [self.diskCache object:key];
        if (!data) {
            return nil;
        }
        [self.memoryCache setObject:data forKey:key cost:(uint)[data length]];
        NSLog(@"这是磁盘缓存");
        return data;
    }
}

- (void)removeDataForkey:(NSString *)key {
    [self.memoryCache removeObject:key];
    [self.diskCache removeObject:key];
}

- (void)removeAll {
    [self.memoryCache removeAllObject];
    [self.diskCache removeAllObject];
}

@end
