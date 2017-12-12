//
//  NSCache+MemoryLimits.h
//  SDWebImage
//
//  Created by EastWind on 12.12.2017.
//  Copyright © 2017 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCache (MemoryLimits)

@property (assign, nonatomic) NSUInteger trackingMemorySize;

- (void) setObject:(id)obj forKey:(id)key withLimitCheck:(Boolean)checking;

@end
