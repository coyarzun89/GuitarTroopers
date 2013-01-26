//
//  WeaponAux.m
//  RockZombies
//
//  Created by Pablo Jacobi on 25-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "WeaponAux.h"


@implementation WeaponAux

@synthesize damage;
@synthesize rutaSprite;

-(id) initWithDamage:(int)Damage RutaSprite:(NSString *) RutaSprite{
    self.damage = Damage;
    self.rutaSprite = RutaSprite;
    return self;
}


@end
