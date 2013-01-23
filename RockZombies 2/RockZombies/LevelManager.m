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
    NSDictionary *level01 = [levelData valueForKey:@"level01"];
    NSDictionary *level02 = [levelData valueForKey:@"level02"];
    NSDictionary *level03 = [levelData valueForKey:@"level03"];
    NSDictionary *level04 = [levelData valueForKey:@"level04"];
    NSDictionary *level05 = [levelData valueForKey:@"level05"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:
    //                  @"levels" ofType:@"plist"];
    
    // Build the array from the plist
    //NSMutableArray *array2 = [[NSMutableArray alloc] initWithContentsOfFile:path];
    
    // Show the string values
    //for (NSString *str in array2)
    //  NSLog(@"--%@", str);
    
    if ((self = [super init])) {
        _curLevelIdx = 0;
        Level * level1 = [[Level alloc] initWithLevelNum:1 minTime:[[level01 valueForKey:@"minTime"] intValue] maxTime:[[level01 valueForKey:@"maxTime"] intValue] backgroundColor:ccc4(255, 255, 255, 255)];
        Level * level2 = [[Level alloc] initWithLevelNum:2 minTime:[[level02 valueForKey:@"minTime"] intValue] maxTime:[[level02 valueForKey:@"maxTime"] intValue] backgroundColor:ccc4(100, 150, 20, 255)];
        Level * level3 = [[Level alloc] initWithLevelNum:3 minTime:[[level03 valueForKey:@"minTime"] intValue] maxTime:[[level03 valueForKey:@"maxTime"] intValue] backgroundColor:ccc4(100, 0, 20, 255)];
        Level * level4 = [[Level alloc] initWithLevelNum:4 minTime:[[level04 valueForKey:@"minTime"] intValue] maxTime:[[level04 valueForKey:@"maxTime"] intValue] backgroundColor:ccc4(100, 250, 20, 255)];
        Level * level5 = [[Level alloc] initWithLevelNum:5 minTime:[[level05 valueForKey:@"minTime"] intValue] maxTime:[[level05 valueForKey:@"maxTime"] intValue] backgroundColor:ccc4(250, 250, 20, 255)];
        _levels = @[level1, level2, level3, level4, level5];
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
