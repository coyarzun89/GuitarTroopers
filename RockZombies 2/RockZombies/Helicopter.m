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

-(id) initWithScene:(HelloWorldLayer *)mainLayer minEnemies:(int) minEnemies maxEnemies:(int) maxEnemies andEnemies:(NSMutableArray *) enemies
{
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
    int numEnemies = arc4random() % (maxEnemies -  minEnemies) + minEnemies + 1;
    
    for(int i = 0; i <= numEnemies; i++){
        do{
            delay = arc4random() % (actualDuration * 1000)/(float)1000;
        }while(delay/actualDuration > 0.35 && delay/actualDuration < 0.65);
        [self performSelector:@selector(launchEnemyWithLayer:) withObject:mainLayer afterDelay:delay];
        NSLog(@" Enemigo Escogido: %d", [[enemies objectAtIndex:arc4random() % 100] intValue]);
    }
    
    return self;
}

-(void) launchEnemyWithLayer:(HelloWorldLayer *)mainLayer
{
    [[SimpleEnemy alloc] initWithScene:mainLayer Color: [UIColor blackColor] Note:1 PosX: helicopter.position.x PosY: helicopter.position.y andWay: way];
}

@end
