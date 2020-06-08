//
//  DiskFileCache.h
//  quickH5
//
//  Created by Gaobin on 2020/6/4.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DiskFileCache : NSObject<CacheProtocol>

- (instancetype)initWithCacheDirectoryName:(NSString *)directoryName;

//缓存限制
@property (nonatomic,assign) uint costLimit;

@property (nonatomic,assign) uint ageLimit;

@end

NS_ASSUME_NONNULL_END
