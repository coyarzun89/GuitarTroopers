//
//  LevelManager.m
//  RockZombies
//
//  Created by Cristopher on 23-01-13.
//
//


#import "LevelManager.h"

@implementation LevelManager {
    NSArray * _levels;
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
    
    NSDictionary *levelData = [self getDictionary:@"levelData"];
    NSDictionary *levelData01 = [levelData valueForKey:@"level01"];
    NSDictionary *levelData02 = [levelData valueForKey:@"level02"];
    NSDictionary *levelData03 = [levelData valueForKey:@"level03"];
    NSDictionary *levelData04 = [levelData valueForKey:@"level04"];
    NSDictionary *levelData05 = [levelData valueForKey:@"level05"];
    NSDictionary *levelData06 = [levelData valueForKey:@"level06"];
    NSDictionary *levelData07 = [levelData valueForKey:@"level07"];
    NSDictionary *levelData08 = [levelData valueForKey:@"level08"];
    NSDictionary *levelData09 = [levelData valueForKey:@"level09"];
    NSDictionary *levelData10 = [levelData valueForKey:@"level10"];
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:
    //                  @"levels" ofType:@"plist"];
    
    // Build the array from the plist
    //NSMutableArray *array2 = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    // Show the string values
    //for (NSString *str in array2)
    //  NSLog(@"--%@", str);
    
    if ((self = [super init])) {
        _curLevelIdx = 0;
        Level * level1 = [[Level alloc] initWithLevelNum:1 minTime:[[levelData01 valueForKey:@"minTime"] intValue] maxTime:[[levelData01 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData01 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData01 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(255, 255, 255, 255) andEnemiesList:[levelData01 valueForKey:@"enemies"]];
        
        Level * level2 = [[Level alloc] initWithLevelNum:2 minTime:[[levelData02 valueForKey:@"minTime"] intValue] maxTime:[[levelData02 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData02 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData02 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(100, 150, 20, 255) andEnemiesList:[levelData02 valueForKey:@"enemies"]];
        
        Level * level3 = [[Level alloc] initWithLevelNum:3 minTime:[[levelData03 valueForKey:@"minTime"] intValue] maxTime:[[levelData03 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData03 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData03 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(100, 0, 20, 255) andEnemiesList:[levelData03 valueForKey:@"enemies"]];
        
        Level * level4 = [[Level alloc] initWithLevelNum:4 minTime:[[levelData04 valueForKey:@"minTime"] intValue] maxTime:[[levelData04 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData04 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData04 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(100, 250, 20, 255) andEnemiesList:[levelData04 valueForKey:@"enemies"]];
        
        Level * level5 = [[Level alloc] initWithLevelNum:5 minTime:[[levelData05 valueForKey:@"minTime"] intValue] maxTime:[[levelData05 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData05 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData05 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(250, 250, 20, 255) andEnemiesList:[levelData05 valueForKey:@"enemies"]];
        
        Level * level6 = [[Level alloc] initWithLevelNum:6 minTime:[[levelData06 valueForKey:@"minTime"] intValue] maxTime:[[levelData06 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData06 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData06 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(250, 250, 20, 255) andEnemiesList:[levelData06 valueForKey:@"enemies"]];
        
        Level * level7 = [[Level alloc] initWithLevelNum:7 minTime:[[levelData07 valueForKey:@"minTime"] intValue] maxTime:[[levelData07 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData07 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData07 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(250, 250, 20, 255) andEnemiesList:[levelData07 valueForKey:@"enemies"]];
        
        Level * level8 = [[Level alloc] initWithLevelNum:8 minTime:[[levelData08 valueForKey:@"minTime"] intValue] maxTime:[[levelData08 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData08 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData08 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(250, 250, 20, 255) andEnemiesList:[levelData08 valueForKey:@"enemies"]];
        
        Level * level9 = [[Level alloc] initWithLevelNum:9 minTime:[[levelData09 valueForKey:@"minTime"] intValue] maxTime:[[levelData09 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData09 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData09 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(250, 250, 20, 255) andEnemiesList:[levelData09 valueForKey:@"enemies"]];
        
        Level * level10 = [[Level alloc] initWithLevelNum:10 minTime:[[levelData10 valueForKey:@"minTime"] intValue] maxTime:[[levelData10 valueForKey:@"maxTime"] intValue] minEnemy:[[levelData10 valueForKey:@"minEnemies"] intValue] maxEnemy:[[levelData10 valueForKey:@"maxEnemies"] intValue] backgroundColor:ccc4(250, 250, 20, 255) andEnemiesList:[levelData10 valueForKey:@"enemies"]];
        _levels = @[level1, level2, level3, level4, level5, level6, level7, level8, level9, level10];
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
