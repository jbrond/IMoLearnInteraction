//
//  ViewController.h
//  SISArtefact
//
//  Created by Jan Brond on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "GCDAsyncSocket.h"
#import "cubeAccelerationEngine.h"
#import "cubeGyroEngine.h"

@interface ViewController : UIViewController <NSNetServiceDelegate, UIAccelerometerDelegate>
{
    NSNetService *netService;
    CMMotionManager *mm;
    
    cubeAccelerationEngine * cubeAccelEngine;
    cubeGyroEngine * cubeGyroTiltEngine;
    
    UIDeviceOrientation previousOrientation;
    UIDeviceOrientation currentOrientation;
    
    NSString *serviceIP;
	
    IBOutlet UILabel *statusLabel;
	GCDAsyncSocket *asyncSocket;
    NSMutableArray *connectedSockets;	
    BOOL isRunning;
    
    int waitTime;
}
- (IBAction)sendOrientation4Command:(id)sender;
- (IBAction)sendOrientation5Command:(id)sender;
- (IBAction)sendOrientation6Command:(id)sender;
- (IBAction)sendHitCommand:(id)sender;
- (IBAction)sendOrientation2Command:(id)sender;
- (IBAction)sendOrientation3Command:(id)sender;
- (IBAction)sendTiltLeftCommand:(id)sender;
- (IBAction)sendOrientation1Command:(id)sender;
- (IBAction)sendTiltRightCommand:(id)sender;
- (IBAction)sendTiltShakeCommand:(id)sender;
-(void) sendMessage:(NSString *)msg : (long)mTag;
-(void) sendThrowDetection:(double) airTime;
- (IBAction)sendShakeCommand:(id)sender;
- (IBAction)sendThrowCommand:(id)sender;
-(void) sendShakeDetection:(int) shakes;
@end
