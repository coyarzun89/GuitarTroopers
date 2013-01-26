//
//  WeaponAux.h
//  RockZombies
//
//  Created by Pablo Jacobi on 25-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface WeaponAux : NSObject {
    int _damage;
    NSString * _rutaSprite;
}

@property int damage;
@property NSString * rutaSprite;

-(id) initWithDamage:(int)Damage RutaSprite:(NSString *) RutaSprite;

@end
