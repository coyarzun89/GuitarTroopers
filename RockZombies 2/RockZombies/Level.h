//
//  Level.h
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Level : NSObject

@property (nonatomic, assign) int levelNum;
@property (nonatomic, assign) int minTime;
@property (nonatomic, assign) int maxTime;
@property (nonatomic, assign) int minEnemy;
@property (nonatomic, assign) int maxEnemy;
@property (nonatomic, assign) ccColor4B backgroundColor;

- (id)initWithLevelNum:(int)levelNum minTime:(int)minTime maxTime:(int)maxTime minEnemy:(int)minEnemy maxEnemy:(int)maxEnemy backgroundColor:(ccColor4B)backgroundColor;

@end
