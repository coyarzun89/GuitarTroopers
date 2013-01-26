//
//  LevelManager.h
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import <Foundation/Foundation.h>
#import "HelloWorldLayer.h"
#import "WeaponAux.h"

@interface WeaponsReader : NSObject{
    NSMutableArray * _weaponsList;
}

@property NSMutableArray * weaponsList;

- (id)initWithScene:(HelloWorldLayer *) mainLayer;

@end