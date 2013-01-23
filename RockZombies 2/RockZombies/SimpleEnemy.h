//
//  Enemy.h
//  RockZombies
//
//  Created by Pablo Jacobi on 11-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "HelloWorldLayer.h"
#import <UIKit/UIColor.h>
#import "Enemy.h"



@interface SimpleEnemy : Enemy {
    
    
}

-(id)initWithScene:(HelloWorldLayer *)mainLayer Color:(UIColor *)color Note:(int)note PosX:(int)posX PosY:(int)posY andWay:(Way)way;



@end
