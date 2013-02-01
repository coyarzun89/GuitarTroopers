//
//  AppDelegate.h
//  RockZombies
//
//  Created by Osvaldo Mena on 21-12-12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

#import "FFTBufferManager.h"
#import "CAStreamBasicDescription.h"
#import "aurio_helper.h"

@interface AppController : NSObject <UIApplicationDelegate, CCDirectorDelegate>
{
    
	UIWindow *window_;
	UINavigationController *navController_;
    CCDirectorIOS	*__unsafe_unretained director_;							// weak ref
    
    SInt32*						fftData;
	NSUInteger					fftLength;
	BOOL						hasNewFFTData;
	
	AudioUnit					rioUnit;
	BOOL						unitIsRunning;
	BOOL						unitHasBeenCreated;
    
    BOOL						mute;
    BOOL                        shouldRecord;
    FFTBufferManager*			fftBufferManager;
	DCRejectionFilter*			dcFilter;
    CAStreamBasicDescription	thruFormat;
    AURenderCallbackStruct		inputProc;
    Float64						hwSampleRate;
    int32_t*					l_fftData;
    
}

@property (nonatomic, strong) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (unsafe_unretained, readonly) CCDirectorIOS *director;
@property						FFTBufferManager*		fftBufferManager;
@property (nonatomic, assign)	AudioUnit				rioUnit;
@property (nonatomic, assign)	BOOL						unitIsRunning;
@property (nonatomic, assign)	BOOL						unitHasBeenCreated;
@property (nonatomic, assign)	BOOL					mute;
@property (nonatomic, assign)	BOOL					shouldRecord;
@property (nonatomic, assign)	AURenderCallbackStruct	inputProc;

- (void)doFFT;
- (SInt32*) fftData;
- (NSUInteger) fftLength;

@end