//
//  Level.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import "Level.h"

@implementation Level

- (id)initWithLevelNum:(int)levelNum EnemiesList:(NSMutableArray *) enemiesList
{
    if ((self = [super init])) {
        self.levelNum = levelNum;
        self.enemiesList = enemiesList;
    }
    return self;
}

@end