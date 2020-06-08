//
//  MemoryCache.h
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheProtocol.h"

// 链表节点
@interface LinkedNode : NSObject

// 链表前驱节点
@property (nonatomic, strong) LinkedNode * prev;

// 链表后继节点
@property (nonatomic, strong) LinkedNode * next;

@property (nonatomic, strong) NSString * key;

@property (nonatomic, strong) id value;

@property (nonatomic, assign) uint cost;

@property (nonatomic, assign) NSTimeInterval time;

@end


@interface LinkedNodeMap : NSObject

@property (nonatomic, strong) NSMutableDictionary * dict;

@property (nonatomic, assign) uint totalCost;

@property (nonatomic, assign) uint totalCount;

@property (nonatomic, strong) LinkedNode * head;

@property (nonatomic, strong) LinkedNode * tail;

@end

@interface MemoryCache : NSObject <CacheProtocol>

+(instancetype)shared;

// 缓存大小限制
@property (nonatomic,assign) uint costLimit;

@end
