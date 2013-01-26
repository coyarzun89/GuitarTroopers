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
    CCSprite * _sprite;
    int damage;
    int offRealX;
    int offRealY;
}

@property CCSprite * sprite;
@property int offRealX;
@property int offRealY;

-(id) initWithLayer:(HelloWorldLayer *) mainLayer SpriteRute:(NSString *) SpriteRute Damage:(int) Damage InitialPosX:(int) InitialPosX InicialPosY:(int)InitialPosY FinalPosX:(int)FinalPosX FinalPosY:(int)FinalPosY;

@end
