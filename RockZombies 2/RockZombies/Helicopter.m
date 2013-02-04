//
//  Helicopter.m
//  RockZombies
//
//  Created by Pablo Jacobi on 11-01-13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Helicopter.h"


@implementation Helicopter

@synthesize way;
@synthesize helicopter;
@synthesize enemiesList;
@synthesize enemiesProbability;

-(id) initWithScene:(HelloWorldLayer *)mainLayer minEnemies:(int) minEnemies maxEnemies:(int) maxEnemies EnemiesList:(NSMutableArray *) enemiesList andEnemiesProbability:(NSMutableArray *) enemiesProbability
{
    self.enemiesProbability = enemiesProbability;
    self.enemiesList = enemiesList;
    
    if(arc4random() % 2 == 1){
        way = LeftToRight;
        helicopter = [CCSprite spriteWithFile:@"helicopterLeftToRight.png"];
    }else{
        way = RightToLeft;
        helicopter = [CCSprite spriteWithFile:@"helicopterRightToLeft.png"];
    }
    way = LeftToRight;
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    int minY = winSize.height * 3/4;
    int maxY = winSize.height - helicopter.contentSize.height/2 * 3/4;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    [mainLayer addChild:helicopter];
    
    int minDuration = 2.0;
    int maxDuration = 3.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    CCMoveTo * actionMove;
    
    if(way == RightToLeft){
        helicopter.position = ccp(winSize.width + helicopter.contentSize.width/2, actualY);
        actionMove = [CCMoveTo actionWithDuration:actualDuration position:ccp(-helicopter.contentSize.width/2, actualY)];
    }else{
        helicopter.position = ccp(-helicopter.contentSize.width/2, actualY);
        actionMove = [CCMoveTo actionWithDuration:actualDuration position:ccp(winSize.width + helicopter.contentSize.width/2, actualY)];
    }
    CCCallBlockN * actionMoveDone = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        [[mainLayer helicopters] removeObject:node];
        [node removeFromParentAndCleanup:YES];
    }];
    [helicopter runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
    
    [[mainLayer helicopters] addObject:helicopter];
    float delay = 0;
    int numEnemies;
    if(maxEnemies > [[mainLayer enemiesPositionsList] count])
        maxEnemies = [[mainLayer enemiesPositionsList] count];
    if(maxEnemies != minEnemies)
        numEnemies = arc4random() % (maxEnemies -  minEnemies) + minEnemies ;
    else
        numEnemies = minEnemies;
    if(numEnemies == 0)
        NSLog(@"Alerta");
    for(int i = 0; i < numEnemies; i++){

        NSMutableArray * auxArray = [[NSMutableArray alloc] init];
        
        int randomPositionIndex = arc4random()%[[mainLayer enemiesPositionsList] count];
        [auxArray addObject: [[mainLayer enemiesPositionsList] objectAtIndex:randomPositionIndex]];
        [[mainLayer enemiesPositionsList] removeObjectAtIndex:randomPositionIndex];
        delay = ([[auxArray objectAtIndex:0] intValue] + helicopter.contentSize.width/2 + 70) * actualDuration / (winSize.width + helicopter.contentSize.width);
        
        int randomFretIndex = arc4random() % [[mainLayer chordsList] count];
        [auxArray addObject: [NSNumber numberWithInt: [[[mainLayer chordsList] objectAtIndex: randomFretIndex] intValue]]];
        [[mainLayer chordsList] removeObjectAtIndex: randomFretIndex];
        [auxArray addObject:mainLayer];
        
        [self performSelector:@selector(launchEnemyNumber:) withObject: auxArray afterDelay:delay];
    }
    
    return self;
}

-(void) launchEnemyNumber:(NSMutableArray *) auxArray
{
    int choosenEnemy = [[enemiesProbability objectAtIndex:arc4random() % 100] intValue];
    NSLog(@"Valor chord: %@", [auxArray objectAtIndex:1]);
    for(id enemy in enemiesList)
        if(choosenEnemy == [enemy enemyType]){
            NSLog(@"Posición Real: %f", helicopter.position.x);
            [[Enemy alloc] initWithScene: [auxArray objectAtIndex:2] Type:[enemy enemyType] PosX:helicopter.position.x PosY:helicopter.position.y Life: [enemy remainingLife] Damage:[enemy damage] Sprite:[enemy sprite] Fret: [auxArray objectAtIndex:1] ].originalPositionX = [[auxArray objectAtIndex:0] intValue];
        }
    
}

@end
