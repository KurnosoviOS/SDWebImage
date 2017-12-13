//
//  MemoryTrackingCache.m
//  SDWebImage
//
//  Created by EastWind on 12.12.2017.
//  Copyright © 2017 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MemoryTrackingCache.h"

@interface CacheItemInfo : NSObject

@property (nonatomic, strong) NSDate *date;
@property (assign, nonatomic) NSUInteger cost;

- (nonnull instancetype)initWithDate:(nonnull NSDate *)date andCost:(NSUInteger) cost;

@end

@implementation CacheItemInfo

- (instancetype)initWithDate:(NSDate *)date andCost:(NSUInteger)cost {
    if ((self = [super init])) {
        self.date = date;
        self.cost = cost;
    }
    
    return self;
}

@end

@implementation MemoryTrackingCache {
    NSMutableDictionary<id, CacheItemInfo *> *cachedItems;
    void(^deletingProcess)(void);
}

- (void) setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    @synchronized (self) {
        
        [super setObject:obj forKey:key cost:g];
        
        if (g == 0) return;
        
        if (!self->cachedItems) {
            self->cachedItems = [[NSMutableDictionary alloc] init];
        }
        
        CacheItemInfo *info = [[CacheItemInfo alloc] initWithDate:[NSDate date] andCost:g];
        
        [self->cachedItems setObject:info forKey:key];
        
        self.trackingMemorySize += g;
        
        if (self.trackingMemorySize > self.totalCostLimit){
            [self deleteOld];
        }
    }
}

- (void) removeObjectForKey:(id)key {
    @synchronized(self) {
        [super removeObjectForKey:key];
        
        CacheItemInfo* info = [self->cachedItems objectForKey:key];
        
        if (info) {
            self.trackingMemorySize -= info.cost;
            [self->cachedItems removeObjectForKey:key];
        }
    }
}

- (void)removeAllObjects {
    @synchronized(self) {
        [super removeAllObjects];
        self.trackingMemorySize = 0;
        [self->cachedItems removeAllObjects];
    }
}

- (void) deleteOld {
    if (self->deletingProcess) {
        return;
    }
    
    if (!self->cachedItems) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    self->deletingProcess = ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            typeof(self) slf = weakSelf;
            
            if(!slf) return;
            
            NSArray<NSString *> *sortedkeys = [slf->cachedItems keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [((CacheItemInfo *)obj1).date compare:((CacheItemInfo *)obj2).date];
            }];
            
            for (NSString *key in sortedkeys) {
                
                @synchronized (slf) {
                    
                    CacheItemInfo *info = [slf->cachedItems objectForKey:key];
                    
                    if (info) {
                        [slf->cachedItems removeObjectForKey:key];
                        slf.trackingMemorySize -= info.cost;
                    }
                    
                    if([slf objectForKey:key]){
                        [slf removeObjectForKey:key];
                    }
                }
                
                if (slf.trackingMemorySize < slf.totalCostLimit/2){
                    break;
                }
            }
        });
    };
    
    self->deletingProcess();
}

@end
