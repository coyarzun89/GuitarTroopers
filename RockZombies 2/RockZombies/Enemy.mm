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

-(id)initWithScene:(HelloWorldLayer *)mainLayer Type:(int)type Time:(NSNumber *)Time Life:(int)Life Damage:(int)Damage Sprite:(NSString *) Sprite String: (CGFloat)String Fret:(NSNumber *) Fret
{
    fret = Fret;
    self.damage = damage;
    self.enemyType = enemyType;
    lifeBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"Progreso.png"]];
    self.remainingLife = Life;
    self.originalLife = Life;
    self.sprite = Sprite;
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    if(Time)
    {
        monster = [CCSprite spriteWithFile:Sprite];
        /* Position based on the number of the string (0, 5)*/
        monster.position = ccp(winSize.width + self.monster.texture.pixelsWide / 2, 50.0 + (winSize.height - 20) * String / 6.0);
        
        /*// Determine speed of the monster
        int minDuration = 2.0;
        int maxDuration = 4.0;
        int rangeDuration = maxDuration - minDuration;
        int actualDuration = (arc4random() % rangeDuration) + minDuration;
        originalTime = actualDuration;*/
        
        CCCallBlockN * actionShoot = [CCCallBlockN actionWithBlock:^(CCNode *node) {
            Projectile * projectile = [[Projectile alloc] initWithLayer:mainLayer SpriteRute:@"Projectile.png" Damage:damage InitialPosX:monster.position.x InicialPosY:monster.position.y FinalPosX:mainLayer.player.position.x FinalPosY:mainLayer.player.position.y Fret:nil];
            [mainLayer addChild: [projectile sprite]];
            [[mainLayer enemyProjectiles] addObject:projectile];
        }];
        
        lifeBar.type = kCCProgressTimerTypeBar;
        lifeBar.position = ccp(monster.position.x, monster.position.y + monster.texture.pixelsHigh / 2 + 15);
        lifeBar. midpoint = ccp(0, 0.5);
        lifeBar.barChangeRate = ccp(1,0);
        lifeBar.percentage = 100;
        
        [lifeBar runAction:[CCSequence actions:[CCMoveTo actionWithDuration:5 position:ccp(300, lifeBar.position.y)], nil]];
        CCAction* repeat  = [CCRepeatForever actionWithAction:[CCSequence actions: [CCMoveTo actionWithDuration:5 position:ccp(270, monster.position.y)], actionShoot, [CCDelayTime actionWithDuration:2], nil]];
        [monster runAction:repeat];
        
        
        
        palabra =[[CCLabelTTF alloc] initWithString: [NSString stringWithFormat:@"%@", Fret] dimensions:CGSizeMake(100.0, 100.0) alignment:kCCTextAlignmentCenter fontName:@"verdana" fontSize:20.0f];
        palabra.position =ccp(monster.position.x, monster.position.y + monster.texture.pixelsHigh / 2 + 10);
        
        [palabra runAction:[CCSequence actions:[CCMoveTo actionWithDuration:5 position:ccp(270, palabra.position.y)], nil]];
        [self performSelector:@selector(addMonster:) withObject: mainLayer afterDelay:[Time floatValue]];
        
    }
    return self;
}

-(void) addMonster:(HelloWorldLayer *) mainLayer
{
    [[mainLayer monsters] addObject:self];
    [mainLayer addChild:monster];
    [mainLayer addChild:lifeBar];
    [mainLayer addChild:palabra];
}


@end
