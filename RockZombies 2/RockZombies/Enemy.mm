//
//  Enemy.m
//  RockZombies
//
//  Created by Pablo Jacobi on 11-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Enemy.h"
#import "HelloWorldLayer.h"
#import "GameOverLayer.h"

@implementation Enemy

@synthesize note;
@synthesize enemyProjectiles;
@synthesize projectiles;

@synthesize monster;
@synthesize lifeBar;
@synthesize enemyType;
@synthesize damage;
@synthesize sprite;
@synthesize remainingLife;
@synthesize originalLife;

-(id)initWithScene:(HelloWorldLayer *)mainLayer Type:(int)enemyType PosX:(int)posX PosY:(int)posY Life:(int)Life Damage:(int)damage Sprite:(NSString *) sprite
{
    self.damage = damage;
    self.enemyType = enemyType;
    lifeBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"Progreso.png"]];
    //[lifeBar runAction:[CCProgressTo actionWithDuration:0.3f percent: 100]];
    self.remainingLife = Life;
    self.originalLife = Life;
    self.sprite = sprite;

  
    
    [mainLayer addChild:lifeBar];
    
    if( posX && posY)
    {
        monster = [CCSprite spriteWithFile:sprite];
        monster.position = ccp(posX, posY);
        [mainLayer addChild:monster];
        // Determine speed of the monster
        int minDuration = 2.0;
        int maxDuration = 4.0;
        int rangeDuration = maxDuration - minDuration;
        int actualDuration = (arc4random() % rangeDuration) + minDuration;
        
        CCCallBlockN * actionShoot = [CCCallBlockN actionWithBlock:^(CCNode *node) {
            Projectile * projectile = [[Projectile alloc] initWithLayer:mainLayer SpriteRute:@"Projectile.png" Damage:damage InitialPosX:monster.position.x InicialPosY:monster.position.y FinalPosX:mainLayer.player.position.x FinalPosY:mainLayer.player.position.y];
            [mainLayer addChild: [projectile sprite]];
            [[mainLayer enemyProjectiles] addObject:[projectile sprite]];
        }];
        
        lifeBar.type = kCCProgressTimerTypeBar;
        lifeBar.position = ccp(posX, posY + 70);
        lifeBar. midpoint = ccp(0, 0.5);
        lifeBar.barChangeRate = ccp(1,0);
        lifeBar.percentage = 100;
        
        [lifeBar runAction:[CCSequence actions:[CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 170)], nil]];
        CCAction* repeat  = [CCRepeatForever actionWithAction:[CCSequence actions: [CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 100)], actionShoot, [CCDelayTime actionWithDuration:2], nil]];
        [monster runAction:repeat];
        
        [[mainLayer monsters] addObject:self];
   
    }
    return self;
}



@end
