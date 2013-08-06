//
//  MicBlowViewController.h
//  MicBlow
//
//  Created by Yu on 11-5-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "Recorder.h"

@class ArrayUtil;
@class SpeedController;


@interface MicBlowViewController : UIViewController  <RecordFilterDelegate>{
	//AVAudioRecorder *recorder;
	NSTimer *levelTimer; 
	double lowPassResults; 
	
	UIImageView *wheel;
	NSTimer *wheeltime;
	
	double angel;
	
	Boolean isMoving;
	
	UILabel *speedLabel;
	
	double _speed;
	double _cha;
    
    NSInteger currentSpeed;
	
	IBOutlet UIView *viewReport;
	IBOutlet UIView *startPage;
    
    
    Recorder *recorder;
    
	NSMutableArray *temEnergyArr;
    
    NSTimer *energyTimer;
    
    ArrayUtil *arrayUtilController;
    
    
    //!!!!!!!!!!!!!!contoller!!!!!!!!!
    SpeedController *speedController;
}
@property(nonatomic,assign) NSInteger currentSpeed;

@property(nonatomic,retain) SpeedController *speedController; 

@property(nonatomic,retain) ArrayUtil *arrayUtilController;

@property (nonatomic,retain) NSMutableArray *temEnergyArr;

@property (nonatomic,retain) Recorder *recorder;

@property (nonatomic,assign) NSTimer *energyTimer;


@property(nonatomic ,retain) IBOutlet UIView *viewReport;
@property(nonatomic ,retain) IBOutlet UIView *startPage;

@property (nonatomic ,retain) IBOutlet UIImageView * wheel;
@property (nonatomic ,retain) IBOutlet UILabel *speedLabel;

- (void)levelTimerCallback:(NSTimer *)timer;

-(IBAction)showReport:(id)sender;
-(IBAction)exitFromReport:(id)sender;
-(IBAction)startApp:(id)sender;
-(IBAction)stoprecord:(id)sender;
-(IBAction)analysize:(id)sender;
-(IBAction)startrecord:(id)sender;



-(void)wheelInTime:(double)value;

-(void) wheelmyFengChe:(double)curValue;
-(void)animationOver:(id *)sender;
-(void)setSpeedText:(double)speed;

@end
