#import "TCPServer.h"
#import "MainViewController.h"
#import "ConfigViewController.h"

@class MainViewController;

@interface AppController : NSObject <UIApplicationDelegate,
									 TCPServerDelegate,
									 NSStreamDelegate>
{
    UIWindow *window;
	MainViewController *mainViewController;
	
	TCPServer			*_server;
	NSInputStream		*_inStream;
	NSOutputStream		*_outStream;
	BOOL				_inReady;
	BOOL				_outReady;
	UIDeviceOrientation lastOrientation;
	unsigned char *bytes;
	int bytesRead;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;

- (void) sendTouch:(CGPoint)point addr:(int)addr type:(int)type;
- (void) sendAcceleration:(UIAcceleration*)acceleration;
- (void) sendSize:(short)width height:(short)height;
@end
