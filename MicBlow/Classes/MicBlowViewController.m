//
//  MicBlowViewController.m
//  MicBlow
//
//  Created by Yu on 11-5-3.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>

#include"wpdef.h"
#include"filter.h"
#include "windpeak.h"

#import "MicBlowViewController.h"
#include <AudioToolbox/AudioToolbox.h>
#import "ArrayUtil.h"
#import "SpeedController.h"


#define INP_BUFFER_SIZE 4096

@implementation MicBlowViewController

@synthesize recorder;
@synthesize energyTimer;

@synthesize wheel;
@synthesize speedLabel;
@synthesize viewReport;
@synthesize startPage;

@synthesize temEnergyArr;

@synthesize currentSpeed;

@synthesize arrayUtilController;


- (void)didReceiveMemoryWarning {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"内存警告" message:@"内存警告" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    [alert release];
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

-(void)startTime:(id)sender{
    //每0。5秒钟读取一次峰值
    energyTimer = [NSTimer scheduledTimerWithTimeInterval:0.5  
                                                    target:self selector:@selector(rollTime:) userInfo:nil repeats:YES];
}

-(void)rollTime:(id)sender{
    //return;
    //double maxvalue = [arrayUtilController getMaxValue:temEnergyArr];
    double maxvalue = [arrayUtilController getAvgValue:temEnergyArr];
    if (maxvalue==-1) {//防止maxValue在temMutitableArray长度为0的时候为0
        return;
    }
    trace(@"avgvalue: %f",maxvalue);
    [temEnergyArr removeAllObjects];
    currentSpeed = [speedController getSpeedByEnergy:maxvalue];
    speedLabel.text = [NSString stringWithFormat:@"%d",currentSpeed];
    
    if(currentSpeed>=1){
        isMoving = YES;
    }else{
        isMoving = NO;
    }
}     

-(UIImageView *)wheel{
    
}

-(void) viewDidLoad{
    arrayUtilController = [[ArrayUtil alloc] init];
    speedController = [[SpeedController alloc] init];
    
    //trace(@"temEnergyArr retainCount: %d",[temEnergyArr retainCount]);
    temEnergyArr  = [[NSMutableArray alloc] init];
    //trace(@"temEnergyArr retainCount: %d",[temEnergyArr retainCount]);
    [self startTime:nil];
	[super viewDidLoad];
    
	recorder=[[Recorder alloc] init];
	[self performSelector:@selector(loadEnterPage)];

}

- (void)viewDidUnload {
	viewReport = nil;
}

-(IBAction)startApp:(id)sender{
	[startPage removeFromSuperview];
}


-(IBAction)stoprecord:(id)sender{
	[recorder stop];
}

#define DEBUG yes

#pragma mark record filter delegate method
- (void)filterRecordData:(short int *)inData length:(UInt32)length{

#ifdef	DEBUG 
    dataout = calloc(length,2);
    
    filter(inData,length/2,dataout,b_filter,N_fil);
    
    double d = energy(dataout, length);
    
    //speedLabel.text = [NSString stringWithFormat:@"%d",(int)d];
    //NSLog(@"强度：%f",d);
    
    [temEnergyArr addObject:[NSNumber numberWithDouble:d]];
#endif
    
}   
    
-(IBAction)startrecord:(id)sender{
    
    wheeltime  = [NSTimer scheduledTimerWithTimeInterval: 0.01 target:self selector: @selector(controlTheWheel:) userInfo:nil repeats:YES];
    
#ifdef writeToFile
	NSString *filePath=[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
						stringByAppendingPathComponent:@"audio.caf"];
	[recorder start:filePath filterCallback:recordBufferHandler];
#else
	[recorder start:self];
#endif
    
}   
    
-(void)recordsound:(id)sender{
    NSLog(@"fsdf");
}   
    
    
    
-(IBAction)analysize:(id)sender{
    
}   
    
    
- (void)listenForBlow:(NSTimer *)timer{
    
}   
    
//控制风筝旋转
-(void)controlTheWheel:(NSTimer *)timer{
    
	if (isMoving) {
        CGAffineTransform transform = wheel.transform;
        wheel.transform = CGAffineTransformRotate(transform, currentSpeed*0.02);
    }else{
        
    }
    
    return;
	if (isMoving) {
		_speed = _speed+_cha;
		NSLog(@"%f",_speed);
		if (_speed>0.2) {
			_speed = 0.2;
		}
		CGAffineTransform transform = wheel.transform;
		wheel.transform = CGAffineTransformRotate(transform, _speed);
		return;
	}else {
		NSLog(@"%f_",_speed);
		if (_speed==0) {
			return;
		}
		_speed = _speed-_cha;
		if (_speed<0) {
			_speed = 0;
		}
		CGAffineTransform transform = wheel.transform;
		wheel.transform = CGAffineTransformRotate(transform, _speed);
	}
}


-(void)setSpeedText:(double)speed{
	double v = speed*100-20; 
	if (speed==0) {
		v = 0;
	}
	NSString *value = [[NSString alloc] initWithFormat:@"%.01f",v];
	speedLabel.text = value;
	[value release];
}

-(void) wheelmyFengChe:(double)curValue{	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDuration:1];
	[UIView setAnimationDidStopSelector:@selector(animationOver:)];
	
	
	//angel += M_PI;
	NSLog(@"开始运动 angel:%f",angel);	
	CGAffineTransform form = wheel.transform;
	//form = CGAffineTransformRotate(form, angel);
	form = CGAffineTransformRotate(form, 1.570796);
	wheel.transform = form;	//printf("%f \n",angel); 
	//wheel.transform = CGAffineTransformRotate(CGAffineTransformMakeRotation(1.570796), 1.570796);
	//wheel.transform = CGAffineTransformMakeRotation(angel);
	[UIView commitAnimations];
}
	 
-(void)animationOver:(id *)sender{
	[wheeltime fire];

	printf("运动完成！！！ \n");
	isMoving=NO;
	[self setSpeedText:0];
}

- (void)dealloc {
	[viewReport release];
	[levelTimer release]; 	
	[wheeltime release];
    [temEnergyArr release];
    [super dealloc];
}

-(void)loadEnterPage{
	[self.view addSubview: startPage];
}

#pragma mark ----显示状态报告----

-(IBAction)showReport:(id)sender{
	printf("显示报告 \n");
	[self.view addSubview:viewReport];
	//[self.view bringSubviewToFront:viewReport];
	
	CGRect r =  viewReport.frame;
	r.origin.x = 0;
	r.origin.y = -500;
	[viewReport setFrame:r];

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.5];
	CGRect r2 =  viewReport.frame;
	r2.origin.x = 0;
	r2.origin.y = 0;
	[viewReport setFrame:r2];
	[UIView commitAnimations];
}

-(IBAction)exitFromReport:(id)sender{
	printf("推出报告 \n");

	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.5];
	CGRect r =  viewReport.frame;
	r.origin.x = 0;
	r.origin.y = -500;
	[viewReport setFrame:r];
	[UIView commitAnimations];
}

-(void)hiddenReport:(id)sender{
	printf("删除 \n");
	[viewReport removeFromSuperview];
}

-(void)levelTimerCallback:(NSTimer *)timer{
    
}









@end
