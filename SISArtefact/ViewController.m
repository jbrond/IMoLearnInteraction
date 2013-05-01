//
//  ViewController.m
//  SISArtefact
//
//  Created by Jan Brond on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#include <sys/time.h>


#define WELCOME_MSG  0
#define ECHO_MSG     1
#define WARNING_MSG  2
#define ORIENTATION_MSG 3
#define SHAKE_START_MSG 4
#define HIT_MSG 5
#define THROW_MSG 6
#define BALANCE_MSG 7
#define SHAKE_END_MSG 8
#define TILT_LEFT_MSG 9
#define TILT_RIGHT_MSG 10
#define TILT_SHAKE_MSG 11
#define SHAKE_DETECTED_MSG 12

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    waitTime = 0;
    
    mm = [[CMMotionManager alloc] init];
    
    if (mm.isDeviceMotionAvailable) {
        [mm setGyroUpdateInterval:1.0f/30.0f];
        [mm setDeviceMotionUpdateInterval:1.0f/30.0f];
        [mm startDeviceMotionUpdates];
    }
    //alloc the acceleration processing engine and call the default init constructor
    cubeAccelEngine = [cubeAccelerationEngine alloc];
    [cubeAccelEngine init];
    
    //aloc the class engine
    cubeGyroTiltEngine = [cubeGyroEngine alloc];
    
    isRunning = false;
    
    //Initializing the acceleration delegate
    UIAccelerometer*  theAccelerometer = [UIAccelerometer sharedAccelerometer];
    theAccelerometer.updateInterval = 1.0f / 30.0f;
    theAccelerometer.delegate = self;
    
    //Starting the device orientation notifications
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification object:nil];
    
    currentOrientation = -1;
    
    asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    // Create an array to hold accepted incoming connections.
	
	connectedSockets = [[NSMutableArray alloc] init];
	
	// Now we tell the socket to accept incoming connections.
	// We don't care what port it listens on, so we pass zero for the port number.
	// This allows the operating system to automatically assign us an available port.
	
	NSError *err = nil;
	if ([asyncSocket acceptOnPort:0 error:&err])
	{
		// So what port did the OS give us?
		
		UInt16 port = [asyncSocket localPort];
		
        NSLog(@"Port Assigned: %d",port);
		// Create and publish the bonjour service.
		// Obviously you will be using your own custom service type.
        
        //Get name of ipod
        UIDevice * dev = [UIDevice currentDevice];
        
        NSString * devName = [ @"" stringByAppendingString:dev.name];
		
		netService = [[NSNetService alloc] initWithDomain:@"local."
		                                             type:@"_ArtefactService._tcp."
		                                             name:devName
		                                             port:port];
		
		[netService setDelegate:self];
		[netService publish];
		
		// You can optionally add TXT record stuff
		
		//NSMutableDictionary *txtDict = [NSMutableDictionary dictionaryWithCapacity:2];
		
		//[txtDict setObject:@"moo" forKey:@"cow"];
		//[txtDict setObject:@"quack" forKey:@"duck"];
		
		//NSData *txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];
		//[netService setTXTRecordData:txtData];
	}
	else
	{
		NSLog(@"Error in acceptOnPort:error: -> %@", err);
	}
    
        
    //Setting the background image
    //no controls so something that can identify the app is running
    
    self.view.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"Background.png"]];
    
    //Need to monitor entering in background
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appHasGoneInBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    //Setting the status line on the app
    [statusLabel setText:@"Status: Init Ok and Running..."];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

//Need
- (void)appHasGoneInBackground
{
    [asyncSocket disconnect];
    asyncSocket = nil;
    
    [netService stop];    
    [netService release];
    
    NSLog(@"Entering Background");
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	NSLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
	
	// The newSocket automatically inherits its delegate & delegateQueue from its parent.
	
	[connectedSockets addObject:newSocket];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[pool release];
	});
    
    [self sendOrientation];
    //Now we have a connection
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	[sock disconnect];
    
    [connectedSockets removeObject:sock];
}

- (void)netServiceDidPublish:(NSNetService *)ns
{
	NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)",
			  [ns domain], [ns type], [ns name], (int)[ns port]);
}

-(void) sendNewOrientation:(UIDeviceOrientation) orientation {
    //UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSString *msg = [NSString stringWithFormat:@"OG:%d\r\n",orientation];
    
    currentOrientation = (int) orientation;
    
    [self sendMessage:msg :ORIENTATION_MSG];
}


- (void)netService:(NSNetService *)ns didNotPublish:(NSDictionary *)errorDict
{
	// Override me to do something here...
	// 
	// Note: This method in invoked on our bonjour thread.
	
	NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@",
               [ns domain], [ns type], [ns name], errorDict);
    
    [statusLabel setText:@"Status: Failed to publish..."];
}

- (IBAction)sendOrientation4Command:(id)sender {
    [self sendNewOrientation:4];
}

- (IBAction)sendOrientation5Command:(id)sender {
    [self sendNewOrientation:5];
}

- (IBAction)sendOrientation6Command:(id)sender {
    [self sendNewOrientation:6];
}

- (IBAction)sendHitCommand:(id)sender {
    [self sendHitDetection:0.0];
}

- (IBAction)sendOrientation2Command:(id)sender {
    [self sendNewOrientation:2];
}

- (IBAction)sendOrientation3Command:(id)sender {
    [self sendNewOrientation:3];
}

- (IBAction)sendTiltLeftCommand:(id)sender {
    [self sendTiltLeft];
}

- (IBAction)sendOrientation1Command:(id)sender {
    [self sendNewOrientation:1];
}

- (IBAction)sendTiltRightCommand:(id)sender {
    [self sendTiltRight];
}

- (IBAction)sendTiltShakeCommand:(id)sender {
    [self sendTiltShake];
}

-(void) sendMessage:(NSString *)msg :(long)mTag
{
    NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
	
    for (GCDAsyncSocket *socket in connectedSockets) {
        [socket writeData:msgData withTimeout:-1 tag:mTag];        
    }
    
    //[msgData release];
}

-(void) sendOrientation {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSString *msg = [NSString stringWithFormat:@"OG:%d\r\n",orientation];
    
    currentOrientation = (int) orientation;
    
    [self sendMessage:msg :ORIENTATION_MSG];
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSString *msg = [NSString stringWithFormat:@"OG:%d\r\n",orientation];
                    
    //NSLog(msg);

    currentOrientation = (int) orientation;
    
    [self sendMessage:msg :ORIENTATION_MSG];
	
    //Release the message
    //[msg release];
}

-(void) sendHitDetection:(double) timeSinceLastHit
{
    NSString *msg = [NSString stringWithFormat:@"HT:%2.3f\r\n",timeSinceLastHit];
    
    [self sendMessage:msg :HIT_MSG];
	
    //Release the message
    //[msg release];
}

-(void) sendThrowDetection:(double) airTime
{
    //Should send shuffle number!
    NSString *msg = [NSString stringWithFormat:@"TD:%2.3f\r\n",airTime];
    
    [self sendMessage:msg :THROW_MSG];
	
    //Release the message
    //[msg release];
}

- (IBAction)sendShakeCommand:(id)sender {
    [self sendShakeDetection:3];
}

- (IBAction)sendThrowCommand:(id)sender {
    
    [self sendThrowDetection:1.0];
}

-(void) sendShakeStartDetection
{
    NSString *msg = [NSString stringWithFormat:@"SS:0\r\n"];
    
    [self sendMessage:msg :SHAKE_START_MSG];
	
    //Release the message
    //[msg release];
}

-(void) sendShakeEndDetection:(int) shakings
{
    NSString *msg = [NSString stringWithFormat:@"SE:%d\r\n",shakings];
    
    [self sendMessage:msg :SHAKE_END_MSG];
}

-(void) sendShakeDetection:(int) shakings
{
    NSString *msg = [NSString stringWithFormat:@"SD:%d\r\n",shakings];
    
    [self sendMessage:msg :SHAKE_DETECTED_MSG];
}

-(void) sendTiltRight
{
    NSString *msg = [NSString stringWithFormat:@"TR:0\r\n"];
    
    [self sendMessage:msg :TILT_RIGHT_MSG];
}

-(void) sendTiltLeft
{
    NSString *msg = [NSString stringWithFormat:@"TL:0\r\n"];
    
    [self sendMessage:msg :TILT_LEFT_MSG];
}

-(void) sendTiltShake
{
    NSString *msg = [NSString stringWithFormat:@"TS:0\r\n"];
    
    [self sendMessage:msg :TILT_SHAKE_MSG];
}

-(void) sendBalance:(double) balance
{
    NSString *msg = [NSString stringWithFormat:@"BA:%2.3f\r\n",balance];
    
    [self sendMessage:msg :BALANCE_MSG];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	// This method is executed on the socketQueue (not the main thread)
	
	if (tag == ECHO_MSG)
	{
		[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
	}
}


/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
	if (elapsed <= READ_TIMEOUT)
	{
		NSString *warningMsg = @"Are you still there?\r\n";
		NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[sock writeData:warningData withTimeout:-1 tag:WARNING_MSG];
		
		return READ_TIMEOUT_EXTENSION;
	}
	
	return 0.0;
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration

{
    //Process acceleration
    eCubeAction cubeAction = [cubeAccelEngine process:acceleration];
    
    eCubeAction cubeTittAction = [cubeGyroTiltEngine process:mm.deviceMotion.attitude];
    
    if (waitTime>0) {
        waitTime--;
        
        return;
    }
    
    //process the cube action if noAction nothing happened just yet!
    if (cubeAction == noAction && cubeTittAction==noAction)
        return;
    
    //this will swollow the hit actions...
    //if place in the right orientation
    if (currentOrientation==2 && cubeTittAction !=noAction) {
        cubeAction = cubeTittAction;
    }
    
    NSLog(@"Action: %d %d", cubeAction, waitTime);
    
    //any acceleration action?
    switch (cubeAction) {
        case hitAction: [self sendHitDetection:0.0];
            break;
        case shakeAction: [self sendShakeDetection:0];
            break;
        case throwAction: [self sendThrowDetection:0.0];
            break;
        case shakeStartAction: [self sendShakeStartDetection];
            break;
        case shakeEndAction: [self sendShakeEndDetection:0];
            break;
        case tiltLeftAction: [self sendTiltLeft];
            break;
        case tiltRightAction: [self sendTiltRight];
            break;
        case tiltShakeAction: [self sendTiltShake];
            break;
        default:
            break;
    }
    
    waitTime = 20;
    
}

- (void)onTimer {
    
    
}

- (void)viewDidUnload
{
    [asyncSocket disconnect];
    asyncSocket = nil;
    
    [netService stop];    
    [netService release];
    
    [statusLabel release];
    statusLabel = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return false;
}

- (void)asyncSocket:(GCDAsyncSocket *)sock didReadData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
	NSString *msg = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	if (msg)
	{
		NSLog(@"%@",msg);
	}
	else
	{
		NSLog(@"Error converting received data into UTF-8 String");
	}
}

- (void)dealloc {
    [statusLabel release];
    [super dealloc];
}
@end
