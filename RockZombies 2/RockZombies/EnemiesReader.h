//
//  LevelManager.h
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import <Foundation/Foundation.h>
#import "Enemy.h"

@interface EnemiesReader : NSObject{
    NSMutableArray * _enemiesList;
}

@property NSMutableArray * enemiesList;

- (id)initWithScece:(HelloWorldLayer *) mainLayer;

@end