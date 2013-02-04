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
@synthesize enemiesTypeListAux;
@synthesize weaponsList;
@synthesize selectedWeapon;
@synthesize chords;
@synthesize enemiesPositionsList;
@synthesize chordsList;


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
    if([enemiesPositionsList count] > 0)
        [[Helicopter new] initWithScene:self minEnemies:minEnemies maxEnemies:maxEnemies EnemiesList:enemiesTypeListAux andEnemiesProbability:enemiesProbability];
    int minTime = [LevelManager sharedInstance].curLevel.minTime;
    int maxTime = [LevelManager sharedInstance].curLevel.maxTime;
    [self unschedule:@selector(gameLogic)];
    
    [self schedule:@selector(gameLogic:) interval:arc4random() % maxTime + minTime];
    
}

- (id) init
{
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [app getFFTBufferManager]->RegisterDelegate(self);
    
    if ((self = [super initWithColor:ccc4(255,255,255,255)])) {
        CGSize winSize = [CCDirector sharedDirector].winSize;
        
        enemiesPositionsList = [[NSMutableArray alloc ] init];
        for(int i = 0; i < 6; i ++)
            [enemiesPositionsList addObject:[NSNumber numberWithFloat:i * ((winSize.width - 70)/13.0)]];
        for(int i = 8; i < 14; i ++)
            [enemiesPositionsList addObject:[NSNumber numberWithFloat:i * ((winSize.width - 70)/13.0)]];
        
        chordsList = [[NSMutableArray alloc ] init];
        for(int i = 0; i < 12; i ++)
            [chordsList addObject:[NSNumber numberWithInt: i]];
                
        selectedWeapon = 1;
        NSMutableDictionary *dictionary = [LevelManager sharedInstance].curLevel.enemiesList;
        enemiesProbability = [self enemiesGenerator:dictionary];
        
        enemiesTypeListAux = [[[EnemiesReader alloc] initWithScece:self] enemiesList];
        
        weaponsList = [[[WeaponsReader alloc] initWithScene:self] weaponsList];
        
        
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
        
        chords = [[NSMutableArray alloc] init];
        for(int i = 0; i < 6; i++)
        {
            CCSprite * chord;
            if(i == 0)
                chord = [CCSprite spriteWithFile: [NSString stringWithFormat:@"%d Selected.png", i]];
            else
                chord = [CCSprite spriteWithFile: [NSString stringWithFormat:@"%d.png", i]];
            chord.position = ccp(winSize.width * (0.60 + 0.15 * (i / 3)), winSize.height * ( 0.03 * (i % 3)) + 20);
            [chords addObject:chord];
            [self addChild:chord];
        }
         [self schedule:@selector(moveEnemies) interval:0.2];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];        
    }
    return self;
}


- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [self convertTouchToNodeSpace:touch];
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    for(int i =0; i < 6; i++)
        if(selectedWeapon == i){
            [[CCTextureCache sharedTextureCache] removeTexture: [[chords objectAtIndex:i] texture]];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"%d.png", i]];
            CGSize size = [tex contentSize];
            [[chords objectAtIndex:i] setTexture: tex];
            [[chords objectAtIndex:i] setTextureRect:CGRectMake(0.0f, 0.0f, size.width,size.height)];
        }
    
    if(location.y > winSize.height * 3.0 / 4.0) {/*Aquí la implementación del cambio de arma*/
        if(selectedWeapon < [weaponsList count] - 1)
            selectedWeapon++;
        else
            selectedWeapon = 0;
    }
    
    for(int i =0; i < 6; i++)
        if(selectedWeapon == i){
            [[CCTextureCache sharedTextureCache] removeTexture: [[chords objectAtIndex:i] texture]];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"%d Selected.png", i]];
            CGSize size = [tex contentSize];
            [[chords objectAtIndex:i] setTexture: tex];
            [[chords objectAtIndex:i] setTextureRect:CGRectMake(0.0f, 0.0f, size.width,size.height)];
        }
    
    WeaponAux *selectedProjectile = [weaponsList objectAtIndex:selectedWeapon];
    Projectile *projectile = [[Projectile alloc] initWithLayer:self SpriteRute:[selectedProjectile rutaSprite] Damage:[selectedProjectile damage] InitialPosX:player.position.x InicialPosY:player.position.y FinalPosX: location.x FinalPosY:location.y Fret:0];
    [self addChild:[projectile sprite]];
    [projectiles addObject: projectile];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
}

-(void) weaponChange
{
    for(int i =0; i < 6; i++)
        if(selectedWeapon == i){
            [[CCTextureCache sharedTextureCache] removeTexture: [[chords objectAtIndex:i] texture]];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"%d.png", i]];
            CGSize size = [tex contentSize];
            [[chords objectAtIndex:i] setTexture: tex];
            [[chords objectAtIndex:i] setTextureRect:CGRectMake(0.0f, 0.0f, size.width,size.height)];
        }
    /*Aquí la implementación del cambio de arma*/
        if(selectedWeapon < [weaponsList count] - 1)
            selectedWeapon++;
        else
            selectedWeapon = 1;
    
    for(int i =0; i < 6; i++)
        if(selectedWeapon == i){
            [[CCTextureCache sharedTextureCache] removeTexture: [[chords objectAtIndex:i] texture]];
            CCTexture2D* tex = [[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"%d Selected.png", i]];
            CGSize size = [tex contentSize];
            [[chords objectAtIndex:i] setTexture: tex];
            [[chords objectAtIndex:i] setTextureRect:CGRectMake(0.0f, 0.0f, size.width,size.height)];
        }
}

-(id) shootWithFret:(NSNumber *)Fret {
    
    CGPoint location = ccp(0, 0);
  
    NSLog(@"NSNumber: %d", Fret);
    if(monsters.count > 0)
        for(Enemy * enemy in monsters) /*Si hay un enemigo que corresponda a la nota tocada, la bala irá hacia él)*/
            if(enemy.fret == Fret)
                location = enemy.monster.position;
    
    if(CGPointEqualToPoint(location, CGPointZero)) /*Si no hay enemigos que correspondan a la nota, (0, 0) se considera no inicializado)*/
        return self;
    
    CGSize winSize = [[CCDirector sharedDirector] winSize];
        
    WeaponAux *selectedProjectile = [weaponsList objectAtIndex:selectedWeapon];
    Projectile *projectile = [[Projectile alloc] initWithLayer:self SpriteRute:[selectedProjectile rutaSprite] Damage:[selectedProjectile damage] InitialPosX:player.position.x InicialPosY:player.position.y FinalPosX: location.x FinalPosY:location.y Fret: [Fret intValue]];
    [self addChild:[projectile sprite]];
    [projectiles addObject: projectile];
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
    return self;
}

-(void) moveEnemies
{
    for (Projectile * projectile in projectiles)
        for (Enemy *monster in monsters)
            if ([projectile fret] == [monster.fret intValue]){
                [projectile.sprite stopAllActions];
                NSLog(@"Tiempo: %f", DistanceBetweenTwoPoints(projectile.sprite.position, monster.monster.position) / DistanceBetweenTwoPoints(player.position, monster.monster.position) * projectile.originalTime);
                [projectile.sprite runAction: [CCMoveTo actionWithDuration: DistanceBetweenTwoPoints(projectile.sprite.position, monster.monster.position) / DistanceBetweenTwoPoints(player.position, monster.monster.position) /** projectile.originalTime*/ position:monster.monster.position]];
            }
}


- (void)update:(ccTime)dt {
    
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [app doFFT];
    
    //NSLog(@"Número de enemigos: %d", [monsters count]);
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (Projectile * projectile in projectiles) {
        
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (Enemy *monster in monsters)
            if (CGRectIntersectsRect([projectile sprite].boundingBox, monster.monster.boundingBox) && [projectile fret] == [monster.fret intValue])
            {
                monster.remainingLife -=  50;
                [monster.lifeBar runAction:[CCProgressFromTo actionWithDuration:0.3f from: monster.lifeBar.percentage to: monster.remainingLife * [monster originalLife] / 100.0]];
                
                [projectilesToDelete addObject:projectile];
                if(monster.remainingLife <= 0)
                    [monstersToDelete addObject:monster];
            }
        for (Enemy *monster in monstersToDelete) {
            [monsters removeObject:monster];
            [self removeChild:monster.monster cleanup:YES];
            [self removeChild:monster.lifeBar cleanup:YES];
            [self removeChild:monster.palabra cleanup:YES];
            [chordsList addObject: monster.fret];
            [enemiesPositionsList addObject:[NSNumber numberWithFloat:monster.originalPositionX]];
            monstersDestroyed++;
            if (monstersDestroyed > 3) {
                CCScene *gameOverScene = [GameOverLayer sceneWithWon:YES];
                [[CCDirector sharedDirector] replaceScene:gameOverScene];
            }
        }
    }
    enemiesKilled = [NSString stringWithFormat:@"Enemies kills %d!", monstersDestroyed];
    label.string=enemiesKilled;
    
    for (id projectile in projectilesToDelete) {
        [projectiles removeObject:projectile];
        [self removeChild: [projectile sprite] cleanup:YES];
    }
    
    NSMutableArray *enemyProjectilesToDelete = [[NSMutableArray alloc] init];
    for (id projectile in enemyProjectiles)
        if (CGRectIntersectsRect([projectile sprite].boundingBox, player.boundingBox)){
            [playerLifeBar runAction:[CCProgressFromTo actionWithDuration:0.3f from: playerLifeBar.percentage to: playerLifeBar.percentage - 10]];
            [enemyProjectilesToDelete addObject:projectile];
        }
    for (id projectile in enemyProjectilesToDelete) {
        [enemyProjectiles removeObject:projectile];
        [self removeChild: [projectile sprite] cleanup:YES];
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

CGFloat DistanceBetweenTwoPoints(CGPoint point1,CGPoint point2)
{
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy );
};

@end
