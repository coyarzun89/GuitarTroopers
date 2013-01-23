//
//  Enemy.h
//  RockZombies
//
//  Created by Pablo Jacobi on 21-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum{
    LeftToRight,
    RightToLeft
} Way;

@interface Enemy : NSObject {
    UIColor * _color;
    int _note;
    NSMutableArray * _enemyProjectiles;
    NSMutableArray * _projectiles;
    CCSprite *_monster;
    CCProgressTimer * _lifeBar;
}

@property () UIColor * color;
@property int note;
@property NSMutableArray * enemyProjectiles;
@property (strong, nonatomic) NSMutableArray * projectiles;
@property int life;
@property CCSprite *monster;
@property CCProgressTimer * lifeBar;

@end
