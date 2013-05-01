//
//  CubeOrientationState.h
//  ShakeBreaker
//
//  Created by Jan Brond on 6/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cubeAction.h"

typedef enum { portraitBalance, portraitStable, landscapeSteepRight, landscapeSteepLeft, faceUp, faceDown } cubeOrientation;

@interface CubeOrientationState : NSObject {
    
    cubeOrientation currentCubeOrientation;
    
    cubeAction * cubeActions[6]; //all 6 possible orientations of the cube
}

@end
