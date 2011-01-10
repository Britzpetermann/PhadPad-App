#import "TCPServer.h"
#import "MainViewController.h"
#import "ConfigViewController.h"

@class MainViewController;

@interface AppController : NSObject <UIApplicationDelegate,
									 TCPServerDelegate,
									 NSStreamDelegate>
{
    UIWindow *window;
	UIImageView *splashView;
	MainViewController *mainViewController;
	
	TCPServer			*_server;
	NSInputStream		*_inStream;
	NSOutputStream		*_outStream;
	
	NSTimer *sendPolicyTimer;
	
	unsigned char *bytes;
	int bytesRead;
	bool blockForPolicy;
;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;

- (void) sendTouch:(CGPoint)point addr:(int)addr type:(int)type;
- (void) sendAcceleration:(UIAcceleration*)acceleration;
@end
