//
//  LevelManager.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//


#import "EnemiesReader.h"

@implementation EnemiesReader

@synthesize enemiesList;


- (id)readPlist:(NSString *)fileName {
    NSData *plistData;
    NSString *error;
    NSPropertyListFormat format;
    id plist;
    
    NSString *localizedPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"plist"];
    plistData = [NSData dataWithContentsOfFile:localizedPath];
    
    plist = [NSPropertyListSerialization propertyListFromData:plistData mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if (!plist) {
        NSLog(@"Error reading plist from file '%s'", [localizedPath UTF8String]);
    }
    
    return plist;
}

- (NSArray *)getArray:(NSString *)fileName {
    return (NSArray *)[self readPlist:fileName];
}

- (NSDictionary *)getDictionary:(NSString *)fileName {
    return (NSDictionary *)[self readPlist:fileName];
}

- (id)initWithScece:(HelloWorldLayer *) mainLayer {
    if ((self = [super init])) {
        enemiesList = [[NSMutableArray alloc] init];
        NSArray *enemiesData = [self getArray:@"EnemiesData"];
        for(NSMutableDictionary * enemy in [LevelManager sharedInstance].curLevel.enemiesList)
        {
            [enemiesData objectAtIndex:[[enemy valueForKey:@"enemyType"] intValue]];
        [enemiesList addObject:[[Enemy alloc] initWithScene:mainLayer Type: [enemy valueForKey:@"enemyType"] Time: [enemy valueForKey:@"time"] Life:[[[enemiesData objectAtIndex:[[enemy valueForKey:@"enemyType"] intValue]] valueForKey: @"HP"] intValue] Damage:[[[enemiesData objectAtIndex:[[enemy valueForKey:@"enemyType"] intValue]] valueForKey: @"Damage"] intValue] Sprite:[[enemiesData objectAtIndex:[[enemy valueForKey:@"enemyType"] intValue]] valueForKey: @"spriteNormal"]  String:[[enemy valueForKey:@"string"] floatValue] Fret:[enemy valueForKey:@"fret"]]];
        }
    }
    return self;
}



@end
