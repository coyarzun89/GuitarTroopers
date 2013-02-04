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
@synthesize originalPositionX;
@synthesize originalPositionY;
@synthesize palabra;
@synthesize fret;
@synthesize originalTime;

-(id)initWithScene:(HelloWorldLayer *)mainLayer Type:(int)enemyType PosX:(int)posX PosY:(int)posY Life:(int)Life Damage:(int)damage Sprite:(NSString *) sprite Fret:(NSNumber *) Fret
{
    fret = Fret;
    self.damage = damage;
    self.enemyType = enemyType;
    lifeBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"Progreso.png"]];

    self.remainingLife = Life;
    self.originalLife = Life;
    self.sprite = sprite;
  
    if( posX && posY)
    {
        originalPositionY = posY;
        monster = [CCSprite spriteWithFile:sprite];
        monster.position = ccp(posX, posY);
        if(monster.position.x > mainLayer.player.position.x)
            monster.flipX = 180;
        [mainLayer addChild:monster];
        // Determine speed of the monster
        int minDuration = 2.0;
        int maxDuration = 4.0;
        int rangeDuration = maxDuration - minDuration;
        int actualDuration = (arc4random() % rangeDuration) + minDuration;
        originalTime = actualDuration;
        
        CCCallBlockN * actionShoot = [CCCallBlockN actionWithBlock:^(CCNode *node) {
            Projectile * projectile = [[Projectile alloc] initWithLayer:mainLayer SpriteRute:@"Projectile.png" Damage:damage InitialPosX:monster.position.x InicialPosY:monster.position.y FinalPosX:mainLayer.player.position.x FinalPosY:mainLayer.player.position.y Fret:nil];
            [mainLayer addChild: [projectile sprite]];
            [[mainLayer enemyProjectiles] addObject:projectile];
        }];
        
        lifeBar.type = kCCProgressTimerTypeBar;
        lifeBar.position = ccp(posX, posY + 70);
        lifeBar. midpoint = ccp(0, 0.5);
        lifeBar.barChangeRate = ccp(1,0);
        lifeBar.percentage = 100;
        
        [lifeBar runAction:[CCSequence actions:[CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 170)], nil]];
        CCAction* repeat  = [CCRepeatForever actionWithAction:[CCSequence actions: [CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 100)], actionShoot, [CCDelayTime actionWithDuration:2], nil]];
        [monster runAction:repeat];
        [mainLayer addChild:lifeBar];
        [[mainLayer monsters] addObject:self];
        
        palabra =[[CCLabelTTF alloc] initWithString: [NSString stringWithFormat:@"%@", Fret] dimensions:CGSizeMake(100.0, 100.0) alignment:kCCTextAlignmentCenter fontName:@"verdana" fontSize:20.0f];
        palabra.position =ccp(posX, posY + 80);
        [mainLayer addChild:palabra];
        [palabra runAction:[CCSequence actions:[CCMoveTo actionWithDuration:actualDuration position:ccp(posX, 180)], nil]];
        
    }
    return self;
}



@end
