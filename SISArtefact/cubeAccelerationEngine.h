//
//  cubeAccelerationActions.h
//  ShakeBreaker
//
//  Created by Jan Brond on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cubeAction.h"

//State of the acceleration detection
typedef enum { accelStateIdle, accelStateThrow, accelStateHit, accelStateShake, accelStateWait} accelerationState;

@interface cubeAccelerationEngine : NSObject {
    
    //holds the buffer of 5 previous data points
    double buffer[5];
    //on set of edge detection
    BOOL onSetDetection;
    long onsetTime;
    Boolean edgeDetected;
    long previousOffsetTime;
    long airTime;
    long duration;
    int shakes;
    accelerationState accelState;
    int waitTime;
}

-(cubeAccelerationEngine*) init;
-(eCubeAction) process: (UIAcceleration *)acceleration;
-(void) setDeviceOrientationChanged: (int)orientation;
-(long) getCubeActionTime;
-(int) getShakes;
-(long) getDuration;
-(long) getAirTime;
@end
