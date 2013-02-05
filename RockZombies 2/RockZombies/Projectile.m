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
@synthesize fret;
@synthesize originalTime;
@synthesize originalDestination;

-(id) initWithLayer:(HelloWorldLayer *) mainLayer SpriteRute:(NSString *) SpriteRute Damage:(int) Damage InitialPosX:(int) InitialPosX InicialPosY:(int)InitialPosY FinalPosX:(int)FinalPosX FinalPosY:(int)FinalPosY Fret:(int) Fret
{
    self.fret = Fret;
    
    
    
    sprite = [CCSprite spriteWithFile: SpriteRute];
    sprite.position = ccp(InitialPosX, InitialPosY);
    
    
    originalDestination = [self RealDestinationFromX:InitialPosX Y:InitialPosY ToX:FinalPosX Y:FinalPosY];
    // Move projectile to actual endpoint
    [sprite runAction: [CCMoveTo actionWithDuration:originalTime position: originalDestination]];
   
    return self;
}


-(CGPoint) RealDestinationFromX:(float) OrigX Y:(float) OrigY ToX:(float) DestX Y:(float)DestY
{
    CGPoint location = CGPointMake(DestX, DestY);
    // Determine offset of location to projectile
    CGPoint offset = ccpSub(location, sprite.position);
    // Bail out if you are shooting down or backwards
    
    int realY;
    float ratio;
    int realX;
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CGPoint realDest;
    
    if(DestY >= OrigY) /*Mina*/
    {
        realY = winSize.height+(sprite.contentSize.height/2);
        ratio = (float) offset.x / (float) offset.y;
        realX = (realY * ratio) + sprite.position.x;
        realDest = ccp(realX, realY);
    }
    else{
        float relation = ((float)OrigY)/((float)DestY - (float)OrigY)/2;
        realX = (OrigX - DestX) * relation + DestX;
        realY = -(sprite.contentSize.height/2);
        realDest = ccp(realX, realY);
    }
    // Determine the length of how far you're shooting
    offRealX = realX - sprite.position.x;
    offRealY = realY - sprite.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480pixels/1sec
    float realMoveDuration = length/velocity;
    originalTime = realMoveDuration;
    return realDest;

}


@end
