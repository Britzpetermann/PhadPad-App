#import "AppController.h"

@interface AppController ()
- (void) setup;
- (void) presentPicker:(NSString *)name;
@end

#pragma mark -
@implementation AppController

@synthesize window;
@synthesize mainViewController;

- (void) _showAlert:(NSString *)title
{
	//prevent alert and reconnect
	
	/*UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show]; 
	[alertView release];*/
	
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

- (void) setup {
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream release];
	_inStream = nil;
	_inReady = NO;

	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream release];
	_outStream = nil;
	_outReady = NO;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError *error = nil;
	if(_server == nil || ![_server start:&error]) {
		if (error == nil) {
			NSLog(@"Failed creating server: Server instance is nil");
		} else {
		NSLog(@"Failed creating server: %@", error);
		}
		[self _showAlert:@"Failed creating server"];
		return;
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
 	if (_outStream && [_outStream hasSpaceAvailable])
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
			[self _showAlert:@"Failed sending data to peer"];			
		}
		else
		{
			// NSLog(@"Send command %i", message[0]);
		}
	}
}

- (void) sendTouch:(CGPoint)point addr:(int)addr type:(int)type
{
	if (_outStream && [_outStream hasSpaceAvailable])
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
			[self _showAlert:@"Failed sending data to peer"];			
		}
		else
		{
			// NSLog(@"Send command %i %i:%i", message[0], x, y);
		}
	}	
}

- (void) openStreams
{
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

- (void) readImage
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
		bytesRead += [_inStream read:bytes2 maxLength:1024*768*4];
		[mainViewController updateProgress:bytesRead];					
	}
	
	//				NSLog(@"read %d bytes",bytesRead);
	
	if (bytesRead == 1024*768*4)
	{
		NSLog(@"draw");
		[mainViewController drawImage:bytes];
		bytesRead = 0;
		free(bytes);
		[mainViewController hideProgress];
	}	
}
@end


#pragma mark -
@implementation AppController (NSStreamDelegate)

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			[self destroyPicker];
			
			[_server release];
			_server = nil;

			if (stream == _inStream)
				_inReady = YES;
			else
				_outReady = YES;
				
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inStream) {
				
//				NSLog(@"read start");
				
				// [self readImage];
				
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
						Boolean isFirstRequest = FALSE;
						if (bytesRead == 0)
							isFirstRequest = TRUE;
						
						unsigned char *bytes2 = &bytes[bytesRead];
						bytesRead += [_inStream read:bytes2 maxLength:1024*768*4];
						
						NSString *s = [NSString stringWithCString:bytes2 length:bytesRead];
						NSLog(@"input: %@", s);
						
						[mainViewController updateProgress:bytesRead];
						
						if (isFirstRequest && bytesRead == 23)
						{
							NSLog(@"Found Policy File Request");
							
							//reset image loading
							bytesRead = 0;
							free(bytes);
							[mainViewController hideProgress];
							
//							NSString *policyFile = @"<?xml version=\"1.0\"?><!DOCTYPE cross-domain-policy SYSTEM \"http://www.adobe.com/xml/dtds/cross-domain-policy.dtd\"><cross-domain-policy><allow-access-from domain=\"*\" to-ports=\"*\"/></cross-domain-policy>";
							
							if (_outStream && [_outStream hasSpaceAvailable])
							{
								
//								NSData *policyFileBytes = [policyFile dataUsingEncoding:NSUTF8StringEncoding];
								
								NSString *filePath = [[NSBundle mainBundle] pathForResource:@"crossdomain" ofType:@"xml"];  
								NSData *policyFileBytes = [NSData dataWithContentsOfFile:filePath];  
								
								//NSData *policyFileBytes = [NSData dataWithContentsOfFile:@"crossdomain.xml"];
	
								uint32_t length = [policyFileBytes length];
								
								NSLog(@"len: %i", length);
								
								if([_outStream write:(const uint8_t *)[policyFileBytes bytes] maxLength:length] == -1)									
								{
									[self _showAlert:@"Failed sending data to peer"];			
								}
								else
								{
									uint8_t end = 0;
									if ([_outStream write:(const uint8_t *)&end maxLength:1] == -1)
									{
										NSLog(@"could not terminate");
										
									}
									else
									{
										NSLog(@"terminated");
										
									}
									NSLog(@"sended policy file");
								}
							}	
							
						}
						else if (isFirstRequest && bytesRead == 0)
						{
							NSLog(@"Found Policy File Request Artifact");
							
							//reset image loading
							bytesRead = 0;
							free(bytes);
							[mainViewController hideProgress];
						}
					}
					
					//				NSLog(@"read %d bytes",bytesRead);
					
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
			NSLog(@"%s", _cmd);
			[self _showAlert:@"Error encountered on stream!"];			
			break;
		}
			
		case NSStreamEventEndEncountered:
		{
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
	if (_inStream || _outStream || server != _server)
		return;
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

@end
