//
//  NSCache+MemoryLimits.m
//  SDWebImage
//
//  Created by EastWind on 12.12.2017.
//  Copyright © 2017 Dailymotion. All rights reserved.
//

#import "NSCache+MemoryLimits.h"

# include <malloc/malloc.h>

@interface NSCache ()

@property (nonatomic, copy) void(^deletingProcess)(void);

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSDate *> *cachedItems;

@end



@implementation NSCache (MemoryLimits)

@dynamic trackingMemorySize;


- (void) setObject:(id)obj forKey:(NSString *)key withLimitCheck:(Boolean)checking {
    
    @synchronized (self) {
        
        [self setObject:obj forKey:key];
        
        if (!checking) return;
        
        if (!self.cachedItems) {
            self.cachedItems = [[NSMutableDictionary alloc] init];
        }
        
        [self.cachedItems setObject:[NSDate date] forKey:key];
        
        self.trackingMemorySize += malloc_size((__bridge const void *) obj);
        
        if (self.trackingMemorySize > self.totalCostLimit){
            [self deleteOld];
        }
    }
}

- (void) deleteOld {
    if (self.deletingProcess) {
        return;
    }
    
    if (!self.cachedItems) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    self.deletingProcess = ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if(!weakSelf) return;
            
            NSArray<NSString *> *sortedkeys = [weakSelf.cachedItems keysSortedByValueWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                return [((NSDate *)obj1) compare:((NSDate *)obj2)];
            }];
            
            for (NSString *key in sortedkeys) {
                
                @synchronized (weakSelf) {
                    [weakSelf.cachedItems removeObjectForKey:key];
                    
                    id contained = [weakSelf objectForKey:key];
                    
                    if(contained){
                        [weakSelf removeObjectForKey:key];
                        weakSelf.trackingMemorySize -= malloc_size((__bridge const void *) contained);
                    }
                }
                
                if (weakSelf.trackingMemorySize < weakSelf.totalCostLimit/2){
                    break;
                }
            }
        });
    };
    
    self.deletingProcess();
}

@end
