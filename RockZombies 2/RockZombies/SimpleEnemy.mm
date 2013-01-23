//
//  Enemy.m
//  RockZombies
//
//  Created by Pablo Jacobi on 11-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "SimpleEnemy.h"
#import "HelloWorldLayer.h"
#import "GameOverLayer.h"

@implementation SimpleEnemy

@synthesize color;
@synthesize note;
@synthesize enemyProjectiles;
@synthesize projectiles;

@synthesize monster;
@synthesize lifeBar;


-(id)initWithScene:(HelloWorldLayer *)mainLayer Color:(UIColor *)color Note:(int)note PosX:(int)posX PosY:(int)posY andWay:(Way)way;
{
    

    
    self.color = color;
    self.note = note;
    
    if(way == LeftToRight)
        monster = [CCSprite spriteWithFile:@"enemyLeftToRight.png"];
    else
        monster = [CCSprite spriteWithFile:@"enemyRightToLeft.png"];

    monster.position = ccp(posX, posY);
    [mainLayer addChild:monster];

    // Determine speed of the monster
    int minDuration = 2.0;
    int maxDuration = 4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;

    
    CCCallBlockN * actionShoot = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        
            CGPoint location = CGPointMake(mainLayer.player.position.x, mainLayer.player.position.y);
        
            CCSprite * projectile = [CCSprite spriteWithFile:@"Projectile.png" rect:CGRectMake(0, 0, 20, 20)];
            projectile.position = ccp(monster.position.x, monster.position.y);
        
            // Determine offset of location to projectile
            CGPoint offset = ccpSub(location, projectile.position);
            // Bail out if you are shooting down or backwards
        
            int realY = location.y;
            float ratio = (float) offset.x / (float) offset.y;
            int realX = (realY * ratio) + location.x;
            CGPoint realDest = ccp(realX, realY);
        
            // Determine the length of how far you're shooting
            int offRealX = realX - projectile.position.x;
            int offRealY = realY - projectile.position.y;
            float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
            float velocity = 480/1; // 480pixels/1sec
            float realMoveDuration = length/velocity;
        
            // Move projectile to actual endpoint
            [projectile runAction:
             [CCSequence actions:
              [CCMoveTo actionWithDuration:realMoveDuration position:location],
              [CCCallBlockN actionWithBlock:^(CCNode *node) {
                 [projectiles removeObject:node];
                 [node removeFromParentAndCleanup:YES];
             }],
              nil]];
            [mainLayer addChild:projectile];
            [[mainLayer enemyProjectiles] addObject:projectile];
    }];
    
    lifeBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"Progreso.png"]];
    lifeBar.type = kCCProgressTimerTypeBar;
    lifeBar.position = ccp(posX, posY + 70);
    lifeBar. midpoint = ccp(0, 0.5);
    lifeBar.barChangeRate = ccp(1,0);
    lifeBar.percentage = 100;
    [mainLayer addChild:lifeBar];
    [lifeBar runAction:[CCSequence actions:[CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 170)], nil]];
    CCAction* repeat  = [CCRepeatForever actionWithAction:[CCSequence actions: [CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 100)], actionShoot, [CCDelayTime actionWithDuration:2], nil]];
    [monster runAction:repeat];

    [[mainLayer monsters] addObject:self];
    return self;
}



@end
