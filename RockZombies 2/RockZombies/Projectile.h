//
//  Projectile.h
//  RockZombies
//
//  Created by Pablo Jacobi on 25-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"

@interface Projectile : NSObject {
   
}

@property CCSprite * sprite;
@property int offRealX;
@property int offRealY;
@property int chord;

-(id) initWithLayer:(HelloWorldLayer *) mainLayer SpriteRute:(NSString *) SpriteRute Damage:(int) Damage InitialPosX:(int) InitialPosX InicialPosY:(int)InitialPosY FinalPosX:(int)FinalPosX FinalPosY:(int)FinalPosY Chord:(int) Chord;

@end
