//
//  Level.h
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Level : NSObject

@property (nonatomic, assign) int levelNum;
@property NSMutableArray * enemiesList;

- (id)initWithLevelNum:(int)levelNum EnemiesList:(NSMutableArray *) enemiesList;

@end
