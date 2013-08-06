//
//  SpeedController.m
//  MicBlow
//
//  Created by zhang xiaosong on 11-10-21.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "SpeedController.h"

#define km_h 1
#define pm_h 2
#define m_s  3


@implementation SpeedController

-(NSInteger)getSpeedByEnergy:(double)energy{
    energy = energy *2;
    if (energy<400) {
        return 0;
    }else if (energy>=400&&energy<1000) {//1-3
        double r = 1+(energy-400)*(3-1)/(1000-400);
        return r;
    }else if (energy>=1000&&energy<=3000) {//3-15
        double r = 3+(energy-1000)*(15-3)/(3000-1000);
        return r;
    }else{
        double r = 15+(energy-3000)*20/(6000);
        return r;
    }
}

@end
