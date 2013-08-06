//
//  ArrayUtil.m
//  MicBlow
//
//  Created by zhang xiaosong on 11-10-18.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ArrayUtil.h"


@implementation ArrayUtil

-(double)getMaxValue:(NSMutableArray *)arr{
    int len  = [arr count];
    if (len==0) {
        return -1;
    }
    double max = 0;
    //NSLog(@"%d",len);
    for (int a=0; a<len; a++) {
        double cur = [[arr objectAtIndex:a] doubleValue];
        if(cur >max){
            max = cur;
        }
    }
    return max;
}



-(double)getAvgValue:(NSMutableArray *)arr{
    int len  = [arr count];
    if (len==0) {
        return -1;
    }
    double max = 0;
    //NSLog(@"%d",len);
    for (int a=0; a<len; a++) {
        double cur = [[arr objectAtIndex:a] doubleValue];
        max += cur;
    }
    return max/len;
}



@end
