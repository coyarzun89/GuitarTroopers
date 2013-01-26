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
#import "Enemy.h"
#import "Helicopter.h"
#import "Enemy.h"
#import "LevelManager.h"
#import "EnemiesReader.h"
#import "WeaponsReader.h"

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
@synthesize maxEnemies;
@synthesize minEnemies;
@synthesize enemiesProbability;
@synthesize enemiesList;
@synthesize weaponsList;
@synthesize selectedWeapon;

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
    
    [[Helicopter new] initWithScene:self minEnemies:minEnemies maxEnemies:maxEnemies EnemiesList:enemiesList andEnemiesProbability:enemiesProbability];
    int minTime = [LevelManager sharedInstance].curLevel.minTime;
    int maxTime = [LevelManager sharedInstance].curLevel.maxTime;
    [self unschedule:@selector(gameLogic)];
    
    [self schedule:@selector(gameLogic:) interval:arc4random() % maxTime + minTime];
    
}

- (id) init
{
    if ((self = [super initWithColor:ccc4(255,255,255,255)])) {
        
        selectedWeapon = 0;
        NSMutableDictionary *dictionary = [LevelManager sharedInstance].curLevel.enemiesList;
        enemiesProbability = [self enemiesGenerator:dictionary];
        
        enemiesList = [[[EnemiesReader alloc] initWithScece:self] enemiesList];
        
        weaponsList = [[[WeaponsReader alloc] initWithScene:self] weaponsList];

        CGSize winSize = [CCDirector sharedDirector].winSize;
        CCSprite *fondo = [CCSprite spriteWithFile:@"fondo.jpg"];
        fondo.position = ccp(winSize.width/2, winSize.height/2);
        [self addChild:fondo];
        
        enemiesKilled = [NSString stringWithFormat:@"Enemies kills %d!", monstersDestroyed];
        label = [CCLabelTTF labelWithString:enemiesKilled fontName:@"Arial" fontSize:16];
        label.color = ccc3(255,255,255);
        label.position = ccp(winSize.width-100, 40);
        [self addChild:label];

        self.isTouchEnabled = YES;
        player = [CCSprite spriteWithFile:@"shooter.png"];
        player.position = ccp(winSize.width/2, player.contentSize.height/2);
        [self addChild:player];
        int minTime = [LevelManager sharedInstance].curLevel.minTime;
        int maxTime = [LevelManager sharedInstance].curLevel.maxTime;
        
        maxEnemies = [LevelManager sharedInstance].curLevel.maxEnemy;
        minEnemies = [LevelManager sharedInstance].curLevel.minEnemy;
        [self schedule:@selector(gameLogic:) interval:rand() % maxTime + minTime];
        
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

    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    if(location.y > winSize.height * 3.0 / 4.0) /*Aquí la implementación del cambio de arma*/
        if(selectedWeapon < [weaponsList count] - 1)
            selectedWeapon++;
        else
            selectedWeapon = 0;
    NSLog(@"Arma: %d", selectedWeapon);
    
    WeaponAux *selectedProjectile = [weaponsList objectAtIndex:selectedWeapon];
    Projectile *projectile = [[Projectile alloc] initWithLayer:self SpriteRute:[selectedProjectile rutaSprite] Damage:[selectedProjectile damage] InitialPosX:player.position.x InicialPosY:player.position.y FinalPosX: location.x FinalPosY:location.y];
    [self addChild:[projectile sprite]];
    [projectiles addObject:[projectile sprite]];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
}

- (void)update:(ccTime)dt {
    
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *projectile in projectiles) {
        
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (Enemy *monster in monsters)
            if (CGRectIntersectsRect(projectile.boundingBox, monster.monster.boundingBox))
            {
                NSLog(@"Vida antes del disparo: %d", monster.remainingLife);
                monster.remainingLife -=  50;
                NSLog(@"Vida Porcentual antes del disparo: %f", monster.lifeBar.percentage);
                [monster.lifeBar runAction:[CCProgressFromTo actionWithDuration:0.3f from: monster.lifeBar.percentage to: monster.remainingLife * [monster originalLife] / 100.0]];
                
                NSLog(@"Vida Restante Porcentual: %f", monster.lifeBar.percentage);
                [projectilesToDelete addObject:projectile];
                if(monster.remainingLife <= 0)
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
    enemiesKilled = [NSString stringWithFormat:@"Enemies kills %d!", monstersDestroyed];
    label.string=enemiesKilled;
    
    for (CCSprite *projectile in projectilesToDelete) {
        [projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    
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

-(NSMutableArray *) enemiesGenerator:(NSMutableDictionary *) enemies
{
    int enemyChoosen;
    int totalProbabilities = 0;
    int probability;
    NSMutableArray * enemyWithProbability = [[NSMutableArray alloc] init];
    for(int i = 0; i < enemies.count; i++)
    {
        probability = [[enemies objectForKey:[NSString stringWithFormat:@"%d",i]] intValue];

        for(int j = 0; j < probability; j++){
            [enemyWithProbability addObject:[NSNumber numberWithInt:i]];
            NSLog(@"%@", [enemyWithProbability objectAtIndex:[enemyWithProbability count] - 1]);
        }
        totalProbabilities += probability;
    }
    return enemyWithProbability;
}

@end
