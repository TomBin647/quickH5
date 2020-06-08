//
//  MemoryCache.m
//  quickH5
//
//  Created by Gaobin on 2020/6/3.
//  Copyright © 2020 Gaobin. All rights reserved.
//

#import "MemoryCache.h"
#import <pthread/pthread.h>
#import "AppDelegate.h"

#define Lock() pthread_mutex_lock(&_lock)
#define Unlock() pthread_mutex_unlock(&_lock)

@implementation LinkedNode

@end

@implementation LinkedNodeMap

- (instancetype)init {
    self = [super init];
    if (self) {
        self.totalCost = 0;
        self.totalCount = 0;
        self.head = nil;
        self.tail = nil;
    }
    return self;
}

- (void)insertNodeAtHead:(LinkedNode *)node {
    self.dict[node.key] = node;
    self.totalCost += node.cost;
    self.totalCount += 1;
    if (_head) {
        node.next = _head;
        _head.prev = node;
        _head = node;
    } else {
        _head = node;
        _tail = node;
    }
}

// 将节点移动到头节点位置
- (void)bringNodeToHead:(LinkedNode *)node {
    if (_head == node) {
        return;
    }
    if (_tail == node) {
        _tail = node.prev;
        _tail.next = nil;
    } else {
        node.next.prev = node.prev;
        node.prev.next = node.next;
    }
    
    node.next = _head;
    node.prev = nil;
    _head.prev = node;
    _head = node;
}

- (void)removeNode:(LinkedNode *)node {
    [_dict removeObjectForKey:node.key];
    _totalCost -= node.cost;
    _totalCount -= 1;
    if (node.next != nil) {
        node.next.prev = node.prev;
    }
    if (node.prev != nil) {
        node.prev.next = node.next;
    }
    if (_head == node) {
        _head = node.next;
    }
    if (_tail == node) {
        _tail = node.prev;
    }
}

- (void)removeTailNode {
    LinkedNode * tempTail = _tail;
    if (tempTail == nil) {
        return;
    }
    
    [_dict removeObjectForKey:tempTail.key];
    _totalCost -= tempTail.cost;
    _totalCount -= 1;
    if (_head == _tail) {
        _head = nil;
        _tail = nil;
    } else {
        _tail = tempTail.next;
        _tail.next = nil;
    }
}

- (void)removeAll {
    _totalCost = 0;
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    if (_dict.count > 0) {
        [_dict removeAllObjects];
    }
}

@end

@interface MemoryCache () {
    pthread_mutex_t _lock;
    // 缓存数量限制
    uint countLimit;
    // 缓存时长限制
    NSTimeInterval ageLimit;
    // 自动清理缓存时间间隔
    NSTimeInterval autoTrimInterval;
    // 串行队列
    dispatch_queue_t queue;
}

@property (nonatomic,strong) LinkedNodeMap * linedMap;

@end

@implementation MemoryCache

+(instancetype)shared {
    static MemoryCache * cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[MemoryCache alloc] init];
    });
    return cache;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        self.linedMap = [[LinkedNodeMap alloc] init];
        queue = dispatch_queue_create("MemoryCache.queue", DISPATCH_QUEUE_CONCURRENT);
        self.costLimit = UINT_MAX;
        countLimit = UINT_MAX;
        ageLimit = FLT_MAX;
        autoTrimInterval = 5;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [self trimRecursively];
    }
    return self;
}

- (void)didReceiveMemoryWarningNotification {
    [self removeAllObject];
}

- (void)didEnterBackgroundNotification {
    [self removeAllObject];
}

- (void)trimRecursively {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self trimInBackground];
        [self trimRecursively];
    });
}

- (void)trimInBackground {
    dispatch_async(queue, ^{
        [self trimWithCount:self->countLimit];
        [self trimWithCost:self->_costLimit];
        [self trimWithAge:self->ageLimit];
    });
}

- (BOOL)contain:(NSString *)key {
    Lock();
    BOOL contain = NO;
    if ([self.linedMap.dict objectForKey:key]) {
        contain = YES;
    }
    Unlock();
    return contain;
}

- (id)object:(NSString *)key {
    Lock();
    if (![self.linedMap.dict.allKeys containsObject:key]) {
        Unlock();
        return nil;
    }
    LinkedNode * node = [self.linedMap.dict objectForKey:key];
    node.time = CACurrentMediaTime();
    [self.linedMap bringNodeToHead:node];
    Unlock();
    return node.value;
}

- (void)setObject:(id)object forKey:(NSString *)key cost:(uint)g {
    Lock();
    NSTimeInterval now = CACurrentMediaTime();
    if (![self.linedMap.dict.allKeys containsObject:key]) {
        LinkedNode * node = [[LinkedNode alloc] init];
        node.cost = g;
        node.time = now;
        node.key = key;
        node.value = object;
        [self.linedMap insertNodeAtHead:node];
        Unlock();
        return;
    }
    // 节点存在，1.更新节点。2. 将节点移动到链表头部
    LinkedNode * node = [self.linedMap.dict objectForKey:key];
    self.linedMap.totalCost -= node.cost;
    self.linedMap.totalCost += g;
    node.cost = g;
    node.time = now;
    node.value = object;
    [self.linedMap bringNodeToHead:node];
    
    // 判断缓存是否满了，缓存数量、缓存大小
    if (self.linedMap.totalCost > _costLimit) {
        dispatch_async(queue, ^{
            [self trimWithCount:self->_costLimit];
        });
    }
    if (self.linedMap.totalCount > countLimit) {
        [self.linedMap removeTailNode];
    }
    Unlock();
}

- (void)removeObject:(NSString*)key {
    Lock();
    if (![self.linedMap.dict.allKeys containsObject:key]) {
        Unlock();
        return;
    }
    LinkedNode * node = [self.linedMap.dict objectForKey:key];
    [self.linedMap removeNode:node];
    Unlock();
}

- (void)removeAllObject {
    Lock();
    [self.linedMap removeAll];
    Unlock();
}

- (void)trimWithCost:(uint)cost {
    BOOL finish = NO;
    Lock();
    if (_costLimit == 0) {
        [self.linedMap removeAll];
        finish = YES;
    } else if (self.linedMap.totalCost <= cost) {
        finish = YES;
    }
    Unlock();
    if (finish) {
        return;
    }
    while (finish == NO) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (self.linedMap.totalCost > cost) {
                [self.linedMap removeTailNode];
            } else {
                finish = YES;
            }
            Unlock();
        } else {
            usleep(10 * 1000);
        }
    }
}

- (void)trimWithCount:(uint)count {
    if (count == 0) {
        [self removeAllObject];
        return;
    }
    
    BOOL finish = NO;
    Lock();
    if (countLimit == 0) {
        [self.linedMap removeAll];
        finish = YES;
    } else if (self.linedMap.totalCount <= count) {
        finish = YES;
    }
    Unlock();
    if (finish) {
        return;
    }
    
    while (finish == NO) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (self.linedMap.totalCount > count) {
                [self.linedMap removeTailNode];
            } else {
                finish = YES;
            }
            Unlock();
        } else {
            usleep(10 * 1000);
        }
    }
}

- (void)trimWithAge:(uint)age {
    BOOL finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    Lock();
    if (ageLimit <= 0) {
        [self.linedMap removeAll];
        finish = YES;
    } else if (self.linedMap.tail == nil || (now - self.linedMap.tail.time) <= age) {
        finish = YES;
    }
    Unlock();
    if (finish) {
        return;
    }
    while (finish == NO) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if ((self.linedMap.tail != nil) && (now - self.linedMap.tail.time) > age) {
                [self.linedMap removeTailNode];
            } else {
                finish = YES;
            }
            Unlock();
        } else {
            usleep(10 * 1000);
        }
    }
}

- (uint)totalCount {
    Lock();
    uint count = self.linedMap.totalCount;
    Unlock();
    return count;
}

- (uint)totalCost {
    Lock();
    uint count = self.linedMap.totalCost;
    Unlock();
    return count;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self.linedMap removeAll];
    pthread_mutex_destroy(&_lock);
}

@end
