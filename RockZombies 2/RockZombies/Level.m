//
//  Level.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import "Level.h"

@implementation Level

- (id)initWithLevelNum:(int)levelNum minTime:(int)minTime maxTime:(int)maxTime minEnemy:(int)minEnemy maxEnemy:(int)maxEnemy backgroundColor:(ccColor4B)backgroundColor andEnemiesList:(NSMutableDictionary *) enemiesList{
    if ((self = [super init])) {
        self.levelNum = levelNum;
        self.minTime = minTime;
        self.maxTime = maxTime;
        self.minEnemy = minEnemy;
        self.maxEnemy = maxEnemy;
        self.backgroundColor = backgroundColor;
        self.enemiesList = enemiesList;
    }
    return self;
}

@end