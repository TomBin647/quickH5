//
//  DiskFileCache.m
//  quickH5
//
//  Created by Gaobin on 2020/6/4.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "DiskFileCache.h"

@interface DiskFileCache () {
    //缓存限制
    uint countLimit;
    
    //串行队列
    dispatch_queue_t queue;
    
    NSURL * fileCacheDir;
}


@end

@implementation DiskFileCache

- (instancetype)initWithCacheDirectoryName:(NSString *)directoryName {
    self = [super init];
    if (self) {
        NSURL *url = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                 inDomain:NSUserDomainMask
        appropriateForURL:nil
                   create:NO
                    error:nil];
        NSURL * folder = [url URLByAppendingPathComponent:directoryName];
        if (![[NSFileManager defaultManager] fileExistsAtPath:folder.path]) {
            [[NSFileManager defaultManager] createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:nil];
        }
        fileCacheDir = folder;
        
        queue = dispatch_queue_create("DiskFileCache.queue", DISPATCH_QUEUE_CONCURRENT);
        _costLimit = UINT_MAX;
        countLimit = UINT_MAX;
        _ageLimit = FLT_MAX;
    }
    return self;
}

- (BOOL)isValidFileDir:(NSURL *)dir {
    if (!dir) {
        return NO;
    }
    if (dir.path.length == 0) {
        return NO;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir.path]) {
        return NO;
    }
    return YES;
}

- (NSURL *)creatFileUrl:(NSString *)fileName {
    NSURL * fileUrl = [fileCacheDir URLByAppendingPathComponent:fileName];
    return fileUrl;
}

- (BOOL)contain:(NSString *)key {
    if (![self creatFileUrl:key]) {
        return NO;
    }
    NSURL * fileUrl = [self creatFileUrl:key];
    
    return [[NSFileManager defaultManager] fileExistsAtPath:fileUrl.path];
}

- (id)object:(NSString *)key {
    if (![self creatFileUrl:key]) {
        return nil;
    }
    NSURL * fileUrl = [self creatFileUrl:key];

    NSError * error;
    
    NSString * dataString = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        return nil;
    }
    NSData * data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

- (void)removeAllObject {
    if (!fileCacheDir) {
        return;
    }
    NSURL * dir = fileCacheDir;
    if (![[NSFileManager defaultManager] subpathsAtPath:dir.path]) {
        return;
    }
    NSArray * fileArray = [[NSFileManager defaultManager]subpathsAtPath:dir.path];
    for (NSString * fileName in fileArray) {
        [[NSFileManager defaultManager] removeItemAtPath:[dir.path stringByAppendingString:fileName] error:nil];
    }
}

- (void)removeObject:(NSString *)key {
    if (!fileCacheDir) {
        return;
    }
    NSURL * dir = fileCacheDir;
    NSString * fileName = key;
    NSString * fileUrl = [dir.path stringByAppendingString:fileName];
    [[NSFileManager defaultManager] removeItemAtPath:fileUrl error:nil];
}

- (void)setObject:(id)object forKey:(NSString *)key cost:(uint)g {
    if (![self creatFileUrl:key]) {
        return;
    }
    NSURL * fileUrl = [self creatFileUrl:key];

    NSError * error;
    
    NSString * dataString = [[NSString alloc] initWithData:object encoding:NSUTF8StringEncoding];
    
    [dataString writeToURL:fileUrl atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"写入缓存失败");
    }
    
    if ([self totalCost] >_costLimit) {
        dispatch_async(queue, ^{
            [self trimWithCost:self->_costLimit];
        });
    }
    if ([self totalCount] > countLimit) {
        dispatch_async(queue, ^{
            [self trimWithCount:self->countLimit];
        });
    }
    
    dispatch_async(queue, ^{
        [self trimWithAge:self->_ageLimit];
    });
}

- (uint)totalCost {
    if (![self isValidFileDir:fileCacheDir]) {
        return 0;
    }
    uint fileSize = 0;
    @try {
        NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileCacheDir.path error:nil];
        for (NSString * file in files) {
            NSURL * fileUrl = [fileCacheDir URLByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] attributesOfItemAtPath:fileUrl.path error:nil]) {
                NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileUrl.path error:nil];
                fileSize += [[attributes objectForKey:NSFileSize] unsignedIntValue];
            }
        }
        return fileSize;
    } @catch (NSException *exception) {
        return 0;
    } @finally {
        
    }
}

- (uint)totalCount {
    if (![self isValidFileDir:fileCacheDir]) {
        return 0;
    }
    NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileCacheDir.path error:nil];
    return (uint)files.count;
}

- (void)trimWithAge:(uint)age {
    if (age == 0) {
        [self removeAllObject];
    }
    if (!fileCacheDir) {
        return;
    }
    // 清理掉过期时间的缓存
    @try {
        NSArray * files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileCacheDir.path error:nil];
        for (NSString * file in files) {
            NSURL * fileUrl = [fileCacheDir URLByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] attributesOfItemAtPath:fileUrl.path error:nil]) {
                NSDictionary * attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:fileUrl.path error:nil];
                if (![attributes objectForKey:NSFileModificationDate]) {
                    return;
                }
                NSDate * modifyDate = [attributes objectForKey:NSFileModificationDate];
                if ([NSDate date].timeIntervalSince1970 - modifyDate.timeIntervalSince1970 > age) {
                    // 过期的，删除掉
                    [self removeObject:file];
                }
            }
        }
    } @catch (NSException *exception) {
    
    } @finally {
        
    }
}

- (void)trimWithCost:(uint)cost {
    if ([self totalCost] <= cost) {
        return;
    }
    if (cost == 0) {
        [self removeAllObject];
    }
    while ([self totalCost] > cost) {
        if (!fileCacheDir) {
            return;
        }
        NSURL * dir = fileCacheDir;
        if (![[NSFileManager defaultManager] subpathsAtPath:dir.path]) {
            return;
        }
        NSArray * fileArray = [[NSFileManager defaultManager]subpathsAtPath:dir.path];
        NSString * lastFileName = [fileArray lastObject];
        [self removeObject:lastFileName];
    }
}

- (void)trimWithCount:(uint)count {
    if ([self totalCount] <= count) {
        return;
    }
    if (count == 0) {
        [self removeAllObject];
    }
    while ([self totalCount] > count) {
        if (!fileCacheDir) {
            return;
        }
        NSURL * dir = fileCacheDir;
        if (![[NSFileManager defaultManager] subpathsAtPath:dir.path]) {
            return;
        }
        NSArray * fileArray = [[NSFileManager defaultManager]subpathsAtPath:dir.path];
        NSString * lastFileName = [fileArray lastObject];
        [self removeObject:lastFileName];
    }
}

@end
