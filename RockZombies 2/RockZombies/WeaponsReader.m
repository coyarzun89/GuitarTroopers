//
//  LevelManager.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//

#import "WeaponsReader.h"

@implementation WeaponsReader

@synthesize weaponsList;


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

- (id)initWithScene:(HelloWorldLayer *) mainLayer {
    if ((self = [super init])) {
        weaponsList = [[NSMutableArray alloc] init];
        NSArray *weaponsData = [self getArray:@"WeaponsData"];
        for(id weaponId in weaponsData) 
            [weaponsList addObject:[[WeaponAux alloc] initWithDamage:[[weaponId valueForKey: @"Damage"]intValue] RutaSprite:[weaponId valueForKey: @"Sprite"]]];
    }
    return self;
}



@end
