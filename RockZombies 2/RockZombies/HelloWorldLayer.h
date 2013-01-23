//
//  HelloWorldLayer.h
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/13/12.
//  Copyright Razeware LLC 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface HelloWorldLayer : CCLayerColor
{
    NSMutableArray * _monsters;
    NSMutableArray * _helicopters;
    NSMutableArray * _projectiles;
    NSMutableArray * _enemyProjectiles;
    int _monstersDestroyed;
    CCSprite *_player;
    CCSprite *_nextProjectile;
    CCProgressTimer * _playerLifeBar;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
@property (strong, nonatomic) NSMutableArray * monsters;
@property (unsafe_unretained) CCSprite * player;
@property (unsafe_unretained) NSMutableArray * helicopters;
@property (unsafe_unretained) CCSprite *nextProjectile;
@property (unsafe_unretained) int monstersDestroyed;
@property (strong, nonatomic) NSMutableArray * projectiles;
@property (strong, nonatomic) NSMutableArray * enemyProjectiles;
@property CCProgressTimer * playerLifeBar;

@end
