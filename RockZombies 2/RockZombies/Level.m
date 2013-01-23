//
//  Level.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import "Level.h"

@implementation Level

- (id)initWithLevelNum:(int)levelNum minTime:(int)minTime maxTime:(int)maxTime backgroundColor:(ccColor4B)backgroundColor {
    if ((self = [super init])) {
        self.levelNum = levelNum;
        self.minTime = minTime;
        self.maxTime = maxTime;
        self.backgroundColor = backgroundColor;
    }
    return self;
}

@end