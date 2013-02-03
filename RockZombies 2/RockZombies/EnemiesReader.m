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
        NSDictionary *enemiesData = [self getDictionary:@"EnemiesData"];
        int i = 0;
        for(id enemyId in enemiesData){
            [enemiesList addObject:[[Enemy alloc] initWithScene:mainLayer Type: [[NSString stringWithFormat:@"%d",i] intValue] PosX:nil PosY:nil Life:[[enemyId  valueForKey: @"HP"] intValue]  Damage:[[enemyId  valueForKey: @"Damage"] intValue]  Sprite:[enemyId  valueForKey: @"spriteNormal"] Chord: 0 ]];
            i++;
        }
        }
    return self;
}



@end
