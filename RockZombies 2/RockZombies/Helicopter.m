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
    if(maxEnemies != minEnemies)
        numEnemies = arc4random() % (maxEnemies -  minEnemies) + minEnemies ;
    else
        numEnemies = minEnemies;
    if(numEnemies == 0)
        NSLog(@"Alerta");
    for(int i = 0; i < numEnemies; i++){
        do{
            delay = arc4random() % (actualDuration * 1000)/(float)1000;
        }while(delay/actualDuration > 0.35 && delay/actualDuration < 0.65 || delay/actualDuration < 0.15 || delay/actualDuration  > 0.85);
        [self performSelector:@selector(launchEnemyNumber:) withObject: mainLayer afterDelay:delay];
        NSLog(@" Enemigo Escogido: %d", [[enemiesProbability objectAtIndex:arc4random() % 100] intValue]);
    }
    self.mainLayer = mainLayer;
    return self;
}

-(void) launchEnemyNumber:(HelloWorldLayer *) mainLayer
{
    int choosenEnemy = [[enemiesProbability objectAtIndex:arc4random() % 100] intValue];
    NSLog(@"Numero random: %d tipos de enemigos: %d", choosenEnemy, [enemiesList count]);
    for(id enemy in enemiesList)
        if(choosenEnemy == [enemy enemyType])
            [[Enemy alloc] initWithScene: mainLayer Type:[enemy enemyType] PosX:helicopter.position.x PosY:helicopter.position.y Life: [enemy remainingLife] Damage:[enemy damage] Sprite:[enemy sprite]];
    //[[Enemy alloc] initWithScene:mainLayer PosX: helicopter.position.x PosY: helicopter.position.y Life:100 Damage:20 Sprite:@"Algo"];
             
}

@end
