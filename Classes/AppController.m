#import "AppController.h"

@interface AppController ()
- (void) setup;
- (void) presentPicker:(NSString *)name;
@end

#pragma mark -
@implementation AppController

@synthesize window;
@synthesize mainViewController;

- (void) _errorAndSetup:(NSString *)title
{
	NSLog(@"Error and Setup: %@", title);	
    [self setup];
}

- (void) applicationDidFinishLaunching:(UIApplication *)application
{	
	[UIApplication sharedApplication].idleTimerDisabled = YES;

	bytesRead = 0;
	mainViewController.view.frame = [[UIScreen mainScreen] applicationFrame];
	
	[window addSubview:mainViewController.view];			
	[window makeKeyAndVisible];
		
	UIDevice* thisDevice = [UIDevice currentDevice];	
	if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
		splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
		splashView.image = [UIImage imageNamed:@"Default-Landscape-rotated.png"];
    }
    else
    {
		splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
		splashView.image = [UIImage imageNamed:@"Default.png"];
    }
	[window addSubview:splashView];	
	[self performSelector:@selector(removeSplash) withObject:nil afterDelay:2.5];
	[window bringSubviewToFront:splashView];
}

-(void)removeSplash;
{
	[splashView removeFromSuperview];
	[splashView release];
	[self setup];
}

- (void) dealloc
{	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_inStream release];

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	[_outStream release];

	[_server release];
		
	[window release];
	
	[super dealloc];
}

- (void)startPolicyTimer
{
    [sendPolicyTimer invalidate];
	
    sendPolicyTimer = [NSTimer scheduledTimerWithTimeInterval: 0.01 target:self selector:
					   @selector(waitForOutStreamAndSendPolicy:) userInfo:nil repeats:YES];
	
    [sendPolicyTimer fire];
}

- (void)stopPolicyTimer
{
    [sendPolicyTimer invalidate];
    sendPolicyTimer = nil;
}

- (void)sendPolicyFile
{	
	if (blockForPolicy && _outStream && [_outStream hasSpaceAvailable])
	{		
		[self stopPolicyTimer];
		
		NSString *filePath = [[NSBundle mainBundle] pathForResource:@"crossdomain" ofType:@"xml"];  
		NSData *policyFileBytes = [NSData dataWithContentsOfFile:filePath]; 
		uint32_t length = [policyFileBytes length];
		
		uint8_t *bytesWithTermination = malloc(length + 1);
		memcpy(bytesWithTermination, [policyFileBytes bytes], length);
		bytesWithTermination[length] = 0;
		
		NSLog(@"Writing policy to output...");
		
		if([_outStream write:bytesWithTermination maxLength:length + 1] == -1)									
		{
			[self _errorAndSetup:@"Failed sending policy to peer"];
		}
		else
		{			
			NSLog(@"Did send policy file request.");
			[self setup];
		}
		
		blockForPolicy = false;		
	}
	else
	{
		NSLog(@"Output not available!");
	}	
}

- (void)waitForOutStreamAndSendPolicy:(NSTimer *)theTimer
{
	[self sendPolicyFile];
}

- (void) setup {
	NSLog(@"server stop...");
	
	[self stopPolicyTimer];
	
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream release];
	_inStream = nil;

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream release];
	_outStream = nil;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError *error = nil;
	if(_server == nil || ![_server start:&error])
	{
		if (error == nil) {
			NSLog(@"Failed creating server: Server instance is nil");
		} else {
			NSLog(@"Failed creating server: %@", error);
		}
		[self _errorAndSetup:@"Failed creating server"];
		return;
	}
	else
	{
		NSLog(@"server started...");		
	}

	[self presentPicker:nil];
}

- (void) presentPicker:(NSString *)name {
	[mainViewController showConfig];
}

- (void) destroyPicker {
	[mainViewController hideConfig];
}

// If we display an error or an alert that the remote disconnected, handle dismissal and return to setup
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup];
}

- (void) sendAcceleration:(UIAcceleration*)acceleration
{	
 	if (!blockForPolicy && _outStream && [_outStream hasSpaceAvailable])
	{
		int HEADER_SIZE = 1 + 4;
		int MESSAGE_SIZE = 3 * 4;
		
		uint8_t message[HEADER_SIZE + MESSAGE_SIZE];
		
		//header
		message[0] = 5;
		memcpy(&message[1], &MESSAGE_SIZE, 4);
		
        float x = acceleration.x;
        float y = acceleration.y;
        float z = acceleration.z;
        
		//message
		memcpy(&message[5], &x, 4);
		memcpy(&message[9], &y, 4);
		memcpy(&message[13], &z, 4);
		
		if([_outStream write:(const uint8_t *)&message maxLength:sizeof(message)] == -1)
		{
			[self _errorAndSetup:@"Failed sending acceleration to peer"];			
		}
		else
		{
			// NSLog(@"Send command %i", message[0]);
		}
	}
}

- (void) sendTouch:(CGPoint)point addr:(int)addr type:(int)type
{
	
	if (!blockForPolicy && _outStream && [_outStream hasSpaceAvailable])
	{
		int HEADER_SIZE = 1 + 4;
		int MESSAGE_SIZE = 2 * 4 + 4;
		
        int width = [[UIScreen mainScreen] applicationFrame].size.height;
        int height = [[UIScreen mainScreen] applicationFrame].size.width;
        
		uint8_t message[HEADER_SIZE + MESSAGE_SIZE];
		
		//header
		message[0] = type;
		memcpy(&message[1], &MESSAGE_SIZE, 4);
		
		//message
		float x = (float)point.x / width;		
		memcpy(&message[5], &x, 4);
		
		float y = (float)point.y / height;
		memcpy(&message[9], &y, 4);
		
		memcpy(&message[13], &addr, 4);
		
		if([_outStream write:(const uint8_t *)&message maxLength:sizeof(message)] == -1)
		{
			[self _errorAndSetup:@"Failed sending touch to peer"];			
		}
		else
		{
			// NSLog(@"Send command %i %i:%i", message[0], x, y);
		}
	}	
}

- (void) openStreams
{
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
}
@end

#pragma mark -
@implementation AppController (NSStreamDelegate)

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			NSLog(@"NSStreamEventOpenCompleted");
			
			[self destroyPicker];
			
			blockForPolicy = false;
			
			[_server release];
			_server = nil;

			if (stream == _inStream)
			{
				NSLog(@"NSStreamEventOpenCompleted in ready");
			}
			else
			{
				NSLog(@"NSStreamEventOpenCompleted out ready");
			}
				
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inStream) {
												
				while ([_inStream hasBytesAvailable])
				{
					
					if (bytesRead == 0)
					{					
						NSLog(@"read alloc");
						[mainViewController showProgress];
						bytes = malloc(768*1024*4);
					}
					
					while ([_inStream hasBytesAvailable])
					{					
						unsigned char *bytes2 = &bytes[bytesRead];
						int currentBytesRead = [_inStream read:bytes2 maxLength:1024*768*4];
						bytesRead += currentBytesRead;

						NSLog(@"Received bytes: %i", currentBytesRead);

						[mainViewController updateProgress:bytesRead];
						
						//found policy
						if (currentBytesRead == 23)
						{
							NSLog(@"Found policy file request");
							
							blockForPolicy = true;
							[self startPolicyTimer];
							
							//reset image loading
							bytesRead = 0;
							free(bytes);
							[mainViewController hideProgress];
						}
						else if (currentBytesRead == -1 || currentBytesRead == 0)
						{
							NSLog(@"Found Termination...");
														
							//reset image loading
							bytesRead = 0;
							free(bytes);
							[mainViewController hideProgress];
						}
					}
										
					if (bytesRead == 1024*768*4)
					{
						NSLog(@"draw");
						[mainViewController drawImage:bytes];
						bytesRead = 0;
						free(bytes);
						[mainViewController hideProgress];
					}						
				}
				
			}
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"NSStreamEventErrorOccurred");
			NSLog(@"%s", _cmd);
			[self _errorAndSetup:@"Error encountered on stream!"];			
			break;
		}
			
		case NSStreamEventEndEncountered:
		{
			NSLog(@"NSStreamEventEndEncountered");
			NSLog(@"%s", _cmd);
			[self setup];
			break;
		}
	}
}

@end


#pragma mark -
@implementation AppController (TCPServerDelegate)

- (void)didAcceptConnectionForServer:(TCPServer *)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	NSLog(@"didAcceptConnectionForServer");
	
	if (_inStream || _outStream || server != _server)
		return;

	NSLog(@"release and open stream");
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

@end
