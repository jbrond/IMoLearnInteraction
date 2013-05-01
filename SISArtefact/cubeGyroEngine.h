//
//  cubeGyroEngine.h
//  ShakeBreaker
//
//  Created by Jan Brond on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "cubeAction.h"
#import <CoreMotion/CoreMotion.h>

typedef enum { gyroStateIdle, gyroStateTilt, gyroStateShake, gyroStateWait} gyroState;

typedef enum { noTiltDirection, rightTilt, leftTilt } tiltDirection;

@interface cubeGyroEngine : NSObject
{
    //holds the buffer of 5 previous data points
    double buffer[5];
    //on set of edge detection
    BOOL onSetDetection;
    long onsetTime;
    Boolean edgeDetected;
    gyroState theGyroState;
    long waitTime;
    long waitTimeOnset;
    int shakes;
    double previousGyro;
    tiltDirection tltdirection;
    tiltDirection firstDirection;
    
}
-(eCubeAction) process: (CMAttitude *)attitudeData;
-(cubeGyroEngine*) init;
@end
