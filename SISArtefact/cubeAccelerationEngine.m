//
//  cubeAccelerationActions.m
//  ShakeBreaker
//
//  Created by Jan Brond on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cubeAccelerationEngine.h"

@implementation cubeAccelerationEngine 

// define constructor
-(cubeAccelerationEngine*) init {

    onSetDetection = false;
    edgeDetected = false;
    
    //current acceleration state is idle
    accelState = accelStateIdle;
    
    return self;
}

-(void) setDeviceOrientationChanged: (int)orientation
{
    //reset the acceleration state and wait until stable again
    //which means that for the next 10 calls to process nothing will happen
    //based on 30 Hz update it will be .333 seconds
    accelState = accelStateWait;
    waitTime = 10;
}

-(long) getCubeActionTime
{
    return previousOffsetTime;
}

//returning the number of shakes
-(int) getShakes {
    return shakes;
}

-(long) getDuration
{
    return duration;
}

-(long) getAirTime
{
    return airTime;
}
-(eCubeAction) process: (UIAcceleration *)acceleration {
    
    struct timeval time;
    eCubeAction cubeAction = noAction;
    
    //CMAcceleration acceleration = mm.deviceMotion.userAcceleration;
    
    //get the gyro
    //CMAttitude * attitude = mm.deviceMotion.attitude;
    
    //Creating the vector magnitude
    //removing the gravity component
    double vm = sqrt(acceleration.x*acceleration.x + acceleration.y*acceleration.y + acceleration.z*acceleration.z);
    
    double edgeDetectionLevel = 0.0;
    long offsetTime = 0;
    
    //Kernel tested in Matlab code
    const double kernel [4] = { 5,1,-2,-3 };
    //const double kernel [5] = { -1, -4, 10, -4, -1 };
    gettimeofday(&time, NULL);
    long now = (time.tv_sec*1000) + (time.tv_usec / 1000);
    
    //Shifting the buffer to the right
    for (int n=0;n<4;n++) {
        //move the buffer
        buffer[n] = buffer[n+1];
        
        //after moving calculate edge detection
        edgeDetectionLevel = edgeDetectionLevel + (buffer[n]-vm)*kernel[n];
    }
    //last element in buffer is assigned for later use
    buffer[4] = vm;
    
    //debug
    //NSLog(@"EDL: %2.3f %2.3f",edgeDetectionLevel,vm);
    //thresholding to make sure we detect onset and off set
    if (edgeDetectionLevel<5.0) {
        edgeDetectionLevel = 0.0;
    }
    
    edgeDetected = false;
    //ok if we have detected an edge onset
    if (!onSetDetection) {
        if (edgeDetectionLevel>0.0) {
            onSetDetection = true;
            onsetTime = now; //Important in the throw time detection
        }
        
    } else {
        if (edgeDetectionLevel<1.0) {
            
            //waitTime--;
            
            //if (waitTime<0) {
            //this transition is important
            onSetDetection = false;
            edgeDetected = true;
            //Get the offset time
            offsetTime = now;
            NSLog(@"Peak Detected");
            //Show the buffer for debug
            //for (int n=0;n<5;n++) {
            //    NSLog(@"Buffer %d %2.3f",n,buffer[n]);
            //}
            //}
            
        }
    }
    
    switch (accelState) {
        case accelStateIdle:
            //any edgeDetection?
            if (edgeDetected)  {
                NSLog(@"Detected: %2.3f",vm);
                //if the acceleration level is below -0.8g it looks like throw
                if (vm < (0.1)) {
                    accelState = accelStateThrow;
                    waitTime = 12;
                } else {
                    accelState = accelStateHit;
                    waitTime = 6;
                }
                //Save the time of previous offset detection
                previousOffsetTime = offsetTime;
                duration = offsetTime;
            }
            break;
        case accelStateHit:
            //if no onset has been found within 200mSec its only a hit
            if (!edgeDetected) {
                waitTime--;
                //NSLog(@"Wait: %d",waitTime);
                if ( waitTime < 0) {
                    //
                    //we have only a hit
                    //
                    //back to idle
                    accelState = accelStateIdle;
                    NSLog(@"Hit detected");
                    cubeAction = hitAction;
                }
            } else {
                //We have a previous hit looks like shake?
                //switch to shake detection
                accelState = accelStateShake;
                shakes = 2;
                waitTime = 10;
                //Save the time of previous offset detection
                previousOffsetTime = offsetTime;
                NSLog(@"Look for shake");
                cubeAction = shakeStartAction;
            }
            
            break;
        case accelStateShake:
            if (!edgeDetected) {
                //if no onset has been detected check the time
                waitTime--;
                if (waitTime < 0) {
                    if (shakes>=3) {
                        //seems we have a shake detected
                        duration = duration - previousOffsetTime;
                        NSLog(@"Shake detected");
                        cubeAction = shakeAction;
                    } else {
                        NSLog(@"Shake Failed - double Hit??");
                        cubeAction = shakeEndAction;
                    }
                    accelState = accelStateWait;
                    waitTime = 10;
                }
            } else {
                //increase shakes counter
                shakes++;
                //Save the time of previous offset detection
                previousOffsetTime = offsetTime;
                waitTime = 10; //reset wait timer
            }
            
            break;
        case accelStateThrow:
            
            gettimeofday(&time, NULL);
            long throwTime = (time.tv_sec*1000) + (time.tv_usec / 1000);
            
            if (vm > 0.8) {
                //
                //seems the cube has landed
                //
                airTime = throwTime - previousOffsetTime;
                waitTime = 20;
                accelState = accelStateWait;
                
                NSLog(@"Throw detected");
                cubeAction = throwAction;
            }
            
            if (throwTime - previousOffsetTime > 1500) {
                //seems way to long - bail out
                accelState = accelStateIdle;
                NSLog(@"Throw Cancel");
            }
            
            break;
        case accelStateWait:
            //this state is used to avoid double detection during fx throw
            waitTime--;
            if (waitTime==0) {
                accelState = accelStateIdle;
            }
            
            break;
    }
    
    return cubeAction;
}
@end
