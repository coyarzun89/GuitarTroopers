//
//  LevelManager.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//


#import "LevelManager.h"

@implementation LevelManager {
    NSMutableArray * _levels;
    int _curLevelIdx;
}

+ (LevelManager *)sharedInstance {
    static dispatch_once_t once;
    static LevelManager * sharedInstance; dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}


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

- (id)init {
    // Path to the plist (in the application bundle)
    
    NSArray *levelsData = [self getDictionary:@"LevelDetails"];
    _levels = [[NSMutableArray alloc] init];
    if ((self = [super init])) {
        _curLevelIdx = 0;
        //[[Level alloc] initWithLevelNum:0 EnemiesList:nil];
        for(NSDictionary * levelData in levelsData)
            [_levels addObject:[[Level alloc] initWithLevelNum:1 EnemiesList: [levelData valueForKey:@"Enemies"]]];
        
    }
    return self;
}

- (Level *)curLevel {
    if (_curLevelIdx >= _levels.count) {
        return nil;
    }
    return _levels[_curLevelIdx];
}

- (void)nextLevel {
    _curLevelIdx++;
}

- (void)reset {
    _curLevelIdx = 0;
}
/*
- (void)dealloc {
    [_levels release];
    _levels = nil;
    [super dealloc];
}*/



@end
