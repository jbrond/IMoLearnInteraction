//
//  cubeGyroEngine.m
//  ShakeBreaker
//
//  Created by Jan Brond on 6/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cubeGyroEngine.h"

@implementation cubeGyroEngine

//
-(cubeGyroEngine*) init {
    theGyroState = gyroStateIdle;
    previousGyro = -5;
    
    tltdirection = noTiltDirection;
    firstDirection = noTiltDirection;
    waitTimeOnset = 5;
    
    return self;
}

-(eCubeAction) process: (CMAttitude*)attitudeData
{
    eCubeAction cubeAction = noAction;
    
    //Lets find the previous value
    if (previousGyro< -4) {
        previousGyro = attitudeData.roll;
        return cubeAction;
    }
    
    struct timeval time;
    
    //detecting the tilt right, left and shake action
    
    //    double edgeDetectionLevel = 0.0;
    long offsetTime = 0;
    
    double vm = 0; //the detection angle
    
    double angle = 0;
    
    if (attitudeData.roll<0) {
        angle = -3.14 - attitudeData.roll;
    } else {
        angle = 3.14 - attitudeData.roll;
    }
    
    gettimeofday(&time, NULL);
    long now = (time.tv_usec / 1000);
    
    //Shifting the buffer to the right
    for (int n=0;n<4;n++) {
        //move the buffer
        buffer[n] = buffer[n+1];
        
        //after moving calculate edge detection
        //edgeDetectionLevel = edgeDetectionLevel + buffer[n]*kernel[n];
    }
    //last element in buffer is assigned for later use
    buffer[4] = angle;
    
    vm = buffer[0] - angle;
    
    //debug
    
    edgeDetected = false;
    //ok if we have detected an edge onset
    if (!onSetDetection) {
        waitTimeOnset--;
        if (waitTimeOnset<=0) {
            if (vm > 1.3) {
                
                onSetDetection = true;
                onsetTime = now; //Important in the throw time detection
                waitTime = 15; //Time out value
                tltdirection = leftTilt;
                //NSLog(@"tilt Left");
                
            } else if (vm < -1.3) {
                
                onSetDetection = true;
                onsetTime = now; //Important in the throw time detection
                waitTime = 15; //Time out value
                tltdirection = rightTilt;
                //NSLog(@"tilt Right");
                
            }
        }
    } else {
        waitTime--;
        if (waitTime<=0) {
            //Time out just single transition
            onSetDetection = false;
            tltdirection = noTiltDirection;
            firstDirection = noTiltDirection;
        } else {
            //ok tilting back again within time
            
            if (tltdirection == leftTilt) {
                if (vm < -1.3) {
                    onSetDetection = false;
                    edgeDetected = true;
                    //Get the offset time
                    offsetTime = now;
                    //NSLog(@"Tilt back detected");
                    waitTimeOnset = 5;
                }
            } else {
                if (vm > 1.3) {
                    onSetDetection = false;
                    edgeDetected = true;
                    //Get the offset time
                    offsetTime = now;
                    //NSLog(@"Tilt back detected");
                    waitTimeOnset = 5;
                }
            }
            
        }
        
    }
    
    previousGyro = attitudeData.roll;
    
    switch (theGyroState) {
        case gyroStateIdle:
            //any edgeDetection?
            if (edgeDetected)  {
                //NSLog(@"Detected: %2.3f",vm);
                //if the acceleration level is below -0.8g it looks like throw
                
                theGyroState = gyroStateTilt;
                waitTime = 10;
                
                //Save the time of previous offset detection
                //previousOffsetTime = offsetTime;
                //duration = offsetTime;
            }
            break;
        case gyroStateTilt:
            
            
            //NSLog(@"gyroStateTilt");
            
            if (firstDirection==noTiltDirection) {
                firstDirection = tltdirection;
            }
            //if no onset has been found within 200mSec its only a hit
            if (!edgeDetected) {
                waitTime--;
                //NSLog(@"Wait: %d",waitTime);
                if ( waitTime < 0) {
                    //
                    //we have only a hit
                    //
                    //back to idle
                    theGyroState = gyroStateIdle;
                    
                    NSLog(@"Tilt: %d",tltdirection);
                    
                    if (firstDirection == rightTilt) {
                        cubeAction = tiltRightAction;
                    } else {
                        cubeAction = tiltLeftAction;
                    }
                    
                    
                    firstDirection = noTiltDirection;
                }
                
            } else {
                //We have a previous hit looks like shake?
                //switch to shake detection
                theGyroState = gyroStateShake;
                firstDirection = noTiltDirection; //reset the firstDirection
                shakes = 2;
                waitTime = 10;
                //Save the time of previous offset detection
                //previousOffsetTime = offsetTime;
                NSLog(@"Look for Tilt shake");
                cubeAction = tiltShakeStartAction;
            }
            
            break;
        case gyroStateShake:
            if (!edgeDetected) {
                //if no onset has been detected check the time
                waitTime--;
                if (waitTime < 0) {
                    if (shakes>=3) {
                        //seems we have a shake detected
                        //duration = duration - previousOffsetTime;
                        NSLog(@"Tilts/Shakes %d", shakes);
                        cubeAction = tiltShakeAction;
                    } else {
                        //NSLog(@"Shake Failed - double Hit??");
                        cubeAction = tiltShakeEndAction;
                    }
                    theGyroState = gyroStateWait;
                    waitTime = 20;
                    
                }
            } else {
                //increase shakes counter
                shakes++;
                //Save the time of previous offset detection
                //previousOffsetTime = offsetTime;
                waitTime = 10; //reset wait timer
            }
            
            break;
        case gyroStateWait:
            //this state is used to avoid double detection during fx throw
            waitTime--;
            if (waitTime==0) {
                theGyroState = gyroStateIdle;
            }
            
            break;
    }
    
    
    return cubeAction;
}
@end
