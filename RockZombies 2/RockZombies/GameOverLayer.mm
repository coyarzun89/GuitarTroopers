//
//  GameOverLayer.m
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/13/12.
//  Copyright 2012 Razeware LLC. All rights reserved.
//

#import "GameOverLayer.h"
#import "HelloWorldLayer.h"
#import "LevelManager.h"


#import "AppDelegate.h"

@implementation GameOverLayer

@synthesize touchScreen;
+(CCScene *) sceneWithWon:(BOOL)won {
    
    CCScene *scene = [CCScene node];
    GameOverLayer *layer = [[GameOverLayer alloc] initWithWon:won];
    [scene addChild: layer];
    return scene;
}

- (id)initWithWon:(BOOL)won {
    
    if ((self = [super initWithColor:ccc4(0, 0, 0, 0)])) {
        
        NSString * message;
        if (won) {
            [[LevelManager sharedInstance] nextLevel];
            Level * curLevel = [[LevelManager sharedInstance] curLevel];
            if (curLevel) {
                message = [NSString stringWithFormat:@"Get ready for level %d! \n\n Touch the screen to continue", curLevel.levelNum];
            } else {
                message = @"You Won!";
                [[LevelManager sharedInstance] reset];
            }
        } else {
            message = @"You Lose :[";
            [[LevelManager sharedInstance] reset];
        }
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        CCLabelTTF * label = [CCLabelTTF labelWithString:message fontName:@"Arial" fontSize:16];
        label.color = ccc3(255,255,255);
        label.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:label];
       
    }
    self.isTouchEnabled = true;
    return self;
}



- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self runAction:
     [CCSequence actions:
      [CCDelayTime actionWithDuration:0.5],
      [CCCallBlockN actionWithBlock:^(CCNode *node) {
         [[CCDirector sharedDirector] replaceScene:[HelloWorldLayer scene]];
     }],
      nil]];
}



@end
