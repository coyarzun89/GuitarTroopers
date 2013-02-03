//
//  Projectile.m
//  RockZombies
//
//  Created by Pablo Jacobi on 25-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Projectile.h"


@implementation Projectile

@synthesize sprite;
@synthesize offRealX;
@synthesize offRealY;
@synthesize chord;

-(id) initWithLayer:(HelloWorldLayer *) mainLayer SpriteRute:(NSString *) SpriteRute Damage:(int) Damage InitialPosX:(int) InitialPosX InicialPosY:(int)InitialPosY FinalPosX:(int)FinalPosX FinalPosY:(int)FinalPosY Chord:(int) Chord
{
    self.chord = Chord;
    
    CGPoint location = CGPointMake(FinalPosX, FinalPosY);
    
    sprite = [CCSprite spriteWithFile: SpriteRute];
    sprite.position = ccp(InitialPosX, InitialPosY);
    
    // Determine offset of location to projectile
    CGPoint offset = ccpSub(location, sprite.position);
    // Bail out if you are shooting down or backwards
    
    int realY;
    float ratio;
    int realX;
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint realDest;
    
    if(FinalPosY >= InitialPosY) /*Mina*/
    {
        realY = winSize.height+(sprite.contentSize.height/2);
        ratio = (float) offset.x / (float) offset.y;
        realX = (realY * ratio) + sprite.position.x;
        realDest = ccp(realX, realY);
    }
    else{
        float relation = ((float)InitialPosY)/((float)FinalPosY - (float)InitialPosY)/2;
        realX = (InitialPosX - FinalPosX) * relation + FinalPosX;
        realY = -(sprite.contentSize.height/2);
        realDest = ccp(realX, realY);
    }
    
    // Determine the length of how far you're shooting
    offRealX = realX - sprite.position.x;
    offRealY = realY - sprite.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480pixels/1sec
    float realMoveDuration = length/velocity;
    
    // Move projectile to actual endpoint
    [sprite runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:realMoveDuration position:realDest],
      [CCCallBlockN actionWithBlock:^(CCNode *node) {
         [[mainLayer projectiles] removeObject:node];
         [node removeFromParentAndCleanup:YES];
     }],
      nil]];
   
    return self;
}

@end
