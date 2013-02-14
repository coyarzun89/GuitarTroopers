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
#import "Enemy.h"
#import "Projectile.h"

typedef enum{
    TopDown, /*LeftToRight*/
    BottomUp /* RightToLeft*/
} Way;





@interface Enemy : NSObject {

    
}

@property int note;
@property NSMutableArray * enemyProjectiles;
@property (strong, nonatomic) NSMutableArray * projectiles;
@property int remainingLife;
@property CCSprite *monster;
@property CCProgressTimer * lifeBar;
@property int enemyType;
@property int damage;
@property NSString * sprite;;
@property int originalLife;
@property int originalPositionX;
@property int originalPositionY;
@property NSNumber * fret;
@property CCLabelTTF * palabra;
@property int originalTime;

-(id)initWithScene:(HelloWorldLayer *)mainLayer Type:(int)type Time:(NSNumber *)Time Life:(int)Life Damage:(int)Damage Sprite:(NSString *) Sprite String: (CGFloat)String Fret:(NSNumber *) Fret;



@end
