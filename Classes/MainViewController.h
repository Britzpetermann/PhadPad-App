#import <UIKit/UIKit.h>
#import "ConfigViewController.h"
#include <AudioToolbox/AudioToolbox.h>

@interface MainViewController : UIViewController <UIAccelerometerDelegate> {
	ConfigViewController *configViewController;
	UIImageView *image;
	UIProgressView *progressBar;
    UIAccelerometer *accelerometer;
    
    double accelX, accelY, accelZ;
	
	CFURLRef soundFileURLRef;
    SystemSoundID soundFileObject;
}

- (void) playStartSound;
- (void) showConfig;
- (void) hideConfig;
- (void) drawImage:(unsigned char *) bytes;

- (void) showProgress;
- (void) updateProgress:(int) bytes;
- (void) hideProgress;

@property (readwrite) CFURLRef soundFileURLRef;
@property (readonly) SystemSoundID soundFileObject;
@property (nonatomic, retain) IBOutlet ConfigViewController *configViewController;
@property (nonatomic, retain) IBOutlet UIImageView *image;
@property (nonatomic, retain) IBOutlet UIProgressView *progressBar;
@property (nonatomic, retain) UIAccelerometer *accelerometer;

@end
