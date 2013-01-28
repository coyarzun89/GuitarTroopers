//
//  Helicopter.h
//  RockZombies
//
//  Created by Pablo Jacobi on 11-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameOverLayer.h"
#import "HelloWorldLayer.h"
#import "Enemy.h"
#import "MTRandom.h"

@interface Helicopter : NSObject {

    Way _way;
    CCSprite * _helicopter;
    NSMutableArray * _enemiesList;
    NSMutableArray * _enemiesProbability;
    float _originalPositionX;
}

@property Way way;
@property (unsafe_unretained) CCSprite * helicopter;
@property NSMutableArray * enemiesList;
@property NSMutableArray * enemiesProbability;
@property float originalPositionX;

-(id) initWithScene:(HelloWorldLayer *)mainLayer minEnemies:(int) minEnemies maxEnemies:(int) maxEnemies EnemiesList:(NSMutableArray *)enemiesList andEnemiesProbability:(NSMutableArray *)enemiesProbability;
-(int) selectEnemyFromDictionary:(NSMutableDictionary *) enemies;
@end
