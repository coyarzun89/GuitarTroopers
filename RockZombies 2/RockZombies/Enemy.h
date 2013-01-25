//
//  Enemy.h
//  RockZombies
//
//  Created by Pablo Jacobi on 11-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"
#import <UIKit/UIColor.h>
#import "Enemy.h"

typedef enum{
    LeftToRight,
    RightToLeft
} Way;

@interface Enemy : NSObject {
    int _note;
    NSMutableArray * _enemyProjectiles;
    NSMutableArray * _projectiles;
    CCSprite *_monster;
    CCProgressTimer * _lifeBar;
    int enemyType;
    int damage;
    NSString * sprite;
}

@property int note;
@property NSMutableArray * enemyProjectiles;
@property (strong, nonatomic) NSMutableArray * projectiles;
@property int life;
@property CCSprite *monster;
@property CCProgressTimer * lifeBar;
@property int enemyType;
@property int damage;
@property NSString * sprite;;

-(id)initWithScene:(HelloWorldLayer *)mainLayer Type:(int)type PosX:(int)posX PosY:(int)posY Life:(int)life Damage:(int)damage Sprite:(NSString *) sprite;



@end
