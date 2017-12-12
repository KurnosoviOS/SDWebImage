//
//  MemoryTrackingCache.h
//  SDWebImage
//
//  Created by EastWind on 12.12.2017.
//  Copyright © 2017 Dailymotion. All rights reserved.
//

#ifndef MemoryTrackingCache_h
#define MemoryTrackingCache_h

@interface MemoryTrackingCache : NSCache

@property (assign, nonatomic) NSUInteger trackingMemorySize;

//@property (nonatomic, copy) void(^deletingProcess)(void);

//@property (nonatomic, strong, nullable) NSMutableDictionary<id *, NSDate *> *cachedItems;

@end

#endif /* MemoryTrackingCache_h */
