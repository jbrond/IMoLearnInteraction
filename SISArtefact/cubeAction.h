//
//  cubeAction.h
//  ShakeBreaker
//
//  Created by Jan Brond on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//defining the various cube actions possible
typedef enum { noAction, hitAction, shakeAction, throwAction, tiltRightAction, tiltLeftAction, tiltShakeAction, shakeStartAction, shakeEndAction, tiltShakeStartAction, tiltShakeEndAction } eCubeAction;


@interface cubeAction : NSObject {
    
    //the action that can be done
    eCubeAction action;
    //time for which the action has be registered
    long actionTime; 
    
    
}


@end
