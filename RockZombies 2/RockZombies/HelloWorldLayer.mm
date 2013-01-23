//
//  HelloWorldLayer.m
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/13/12.
//  Copyright Razeware LLC 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"
#import "GameOverLayer.h"
#import "SimpleEnemy.h"
#import "Helicopter.h"
#import "Enemy.h"
#import "LevelManager.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize monsters;
@synthesize helicopters;
@synthesize player;
@synthesize nextProjectile;
@synthesize monstersDestroyed;
@synthesize projectiles;
@synthesize playerLifeBar;
@synthesize enemyProjectiles;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
    // 'scene' is an autorelease object.
    CCScene *scene = [CCScene node];
    
    // 'layer' is an autorelease object.
    HelloWorldLayer *layer = [HelloWorldLayer node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}


-(void)gameLogic:(ccTime)dt {
    
    [[Helicopter new] initWithScene:self];
    int minTime = [LevelManager sharedInstance].curLevel.minTime;
    int maxTime = [LevelManager sharedInstance].curLevel.maxTime;
    [self unschedule:@selector(gameLogic)];
    [self schedule:@selector(gameLogic:) interval:rand() % maxTime + minTime];
}

- (id) init
{
    if ((self = [super initWithColor:ccc4(255,255,255,255)])) {
        CGSize winSize = [CCDirector sharedDirector].winSize;
        CCSprite *fondo = [CCSprite spriteWithFile:@"fondo.jpg"];
        fondo.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:fondo];
        self.isTouchEnabled = YES;
        player = [CCSprite spriteWithFile:@"shooter.png"];
        player.position = ccp(winSize.width/2, player.contentSize.height/2);
        [self addChild:player];
        int minTime = [LevelManager sharedInstance].curLevel.minTime;
        int maxTime = [LevelManager sharedInstance].curLevel.maxTime;
        
        int maxEnemies = [LevelManager sharedInstance].curLevel.maxEnemy;
        [self schedule:@selector(gameLogic:) interval:rand() % maxTime + minTime];
        //[self schedule:@selector(gameLogic:) interval: rand() % 5 + 2];
   
        monsters = [[NSMutableArray alloc] init];
        projectiles = [[NSMutableArray alloc] init];
        enemyProjectiles = [[NSMutableArray alloc] init];
        
        [self schedule:@selector(update:)];
        
        playerLifeBar = [CCProgressTimer progressWithSprite:[CCSprite spriteWithFile:@"Progreso.png"]];
        playerLifeBar.type = kCCProgressTimerTypeBar;
        playerLifeBar.position = ccp(100, 50);
        playerLifeBar. midpoint = ccp(0, 0.5);
        playerLifeBar.barChangeRate = ccp(1,0);
        playerLifeBar.percentage = 100;
        [self addChild:playerLifeBar];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];        
    }
    return self;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [self convertTouchToNodeSpace:touch];
    
    // Set up initial location of projectile
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    CCSprite *projectile = [CCSprite spriteWithFile:@"Projectile.png" rect:CGRectMake(0, 0, 20, 20)];
    projectile.position = ccp(winSize.width/2, 20);
    
    // Determine offset of location to projectile
    CGPoint offset = ccpSub(location, projectile.position);
    // Bail out if you are shooting down or backwards
    if (offset.y <= player.position.y) return;
    // Ok to add now - we've double checked position
    
    int realY = winSize.height+(projectile.contentSize.height/2);
    float ratio = (float) offset.x / (float) offset.y;
    int realX = (realY * ratio) + projectile.position.x;
    CGPoint realDest = ccp(realX, realY);
    
    // Determine the length of how far you're shooting
    int offRealX = realX - projectile.position.x;
    int offRealY = realY - projectile.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480pixels/1sec
    float realMoveDuration = length/velocity;
    
    // Determine angle to face
    float angleRadians = atanf((float)offRealX / (float)offRealY);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle =  angleDegrees;
    float rotateDegreesPerSecond = 180 / 0.3; // Would take 0.5 seconds to rotate 180 degrees, or half a circle
    float degreesDiff = player.rotation - cocosAngle;
    float rotateDuration = fabs(degreesDiff / rotateDegreesPerSecond);
    [player runAction:
     [CCSequence actions:
      [CCRotateTo actionWithDuration:rotateDuration angle:cocosAngle],
      [CCCallBlock actionWithBlock:^{
         // OK to add now - rotation is finished!
         [self addChild:projectile];
         [projectiles addObject:projectile];
     }],
      nil]];
    
    // Move projectile to actual endpoint
    [projectile runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:0.5 position:realDest],
      [CCCallBlockN actionWithBlock:^(CCNode *node) {
         [projectiles removeObject:node];
         [node removeFromParentAndCleanup:YES];
     }],
      nil]];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
}

- (void)update:(ccTime)dt {
    
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *projectile in projectiles) {
        
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (Enemy *monster in monsters)
            if (CGRectIntersectsRect(projectile.boundingBox, monster.monster.boundingBox))
            {
                int remainLife = monster.lifeBar.percentage - 50;
                [monster.lifeBar runAction:[CCProgressFromTo actionWithDuration:0.3f from: monster.lifeBar.percentage to: monster.lifeBar.percentage - 50]];
                [projectilesToDelete addObject:projectile];
                if(remainLife <= 0)
                    [monstersToDelete addObject:monster];
            }
                
        for (Enemy *monster in monstersToDelete) {
            [monsters removeObject:monster];
            [self removeChild:monster.monster cleanup:YES];
            
            monstersDestroyed++;
            if (monstersDestroyed > 3) {
                CCScene *gameOverScene = [GameOverLayer sceneWithWon:YES];
                [[CCDirector sharedDirector] replaceScene:gameOverScene];
            }
        }
    }
    
    for (CCSprite *projectile in projectilesToDelete) {
        [projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    
    NSLog(@"Balas enemigas: %d", enemyProjectiles.count);
    NSMutableArray *enemyProjectilesToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *projectile in enemyProjectiles)
        if (CGRectIntersectsRect(projectile.boundingBox, player.boundingBox)){
            [playerLifeBar runAction:[CCProgressFromTo actionWithDuration:0.3f from: playerLifeBar.percentage to: playerLifeBar.percentage - 10]];
            [enemyProjectilesToDelete addObject:projectile];
        }
    for (CCSprite *projectile in enemyProjectilesToDelete) {
        [enemyProjectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
}



#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [[app navController] dismissModalViewControllerAnimated:YES];
}
@end
