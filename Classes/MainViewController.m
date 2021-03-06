#import "MainViewController.h"
#import "AppController.h"

@interface MainViewController()
- (void) localTouchUp:(NSSet*)touches;
@end

@implementation MainViewController

@synthesize configViewController;
@synthesize image;
@synthesize progressBar;
@synthesize accelerometer;
@synthesize soundFileURLRef;
@synthesize soundFileObject;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.accelerometer = [UIAccelerometer sharedAccelerometer];
    self.accelerometer.updateInterval = .05;
    self.accelerometer.delegate = self;
	
	[progressBar setHidden:YES];	

	// add background image
	UIImage *rawimage;
	UIDevice* thisDevice = [UIDevice currentDevice];
    if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
		rawimage = [UIImage imageNamed:@"TouchArea-ipad.png"];
    }
    else
    {
		rawimage = [UIImage imageNamed:@"TouchArea.png"];
    }	
	image.image = rawimage;
	[rawimage release];

	//play startsound
	NSURL *startSound = [[NSBundle mainBundle] URLForResource: @"TouchMe" withExtension: @"aif"];
    self.soundFileURLRef = (CFURLRef) [startSound retain];
	AudioServicesCreateSystemSoundID(soundFileURLRef, &soundFileObject);
	AudioServicesPlaySystemSound (soundFileObject);
	
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{    
   [(AppController*)[[UIApplication sharedApplication] delegate] sendAcceleration:acceleration];
}

- (void) showConfig
{
	[self.view addSubview:configViewController.view];
}

- (void) hideConfig
{
	[configViewController.view removeFromSuperview];
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{	
    if (interfaceOrientation == UIDeviceOrientationLandscapeLeft)
        return YES;
    else
        return NO;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	for(UITouch *touch in touches)
	{
		CGPoint point = [touch locationInView:self.view];		
		int addr = (unsigned int)touch;
		[(AppController*)[[UIApplication sharedApplication] delegate] sendTouch:point addr:addr type:1];
	}	
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	for(UITouch *touch in touches)
	{
		CGPoint point = [touch locationInView:self.view];
		int addr = (unsigned int)touch;
		[(AppController*)[[UIApplication sharedApplication] delegate] sendTouch:point addr:addr type:2];
	}
	
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	[self localTouchUp:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self localTouchUp:touches];
}

- (void) localTouchUp:(NSSet*)touches
{
	for(UITouch *touch in touches)
	{
		CGPoint point = [touch locationInView:self.view];		
		int addr = (unsigned int)touch;
		[(AppController*)[[UIApplication sharedApplication] delegate] sendTouch:point addr:addr type:3];
	}
}

- (void) drawImage:(unsigned char *)bytes
{
	NSLog(@"image %f, %f", image.frame.size.width, image.frame.size.height);
	
	const size_t width = 1024;
	const size_t height = 768;
	const size_t bitsPerComponent = 8;
	const size_t bitsPerPixel = 32;
	const size_t bytesPerRow = (bitsPerPixel * width)/8;
	CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
//	unsigned char *bytes = malloc(768*1024*4);
	
/*	int x, y;
	for (x = 0; x < width; x++)
	{
		for (y = 0; y < height; y++)
		{
			bytes[(y * width + x) * 4] = 255; //A
			bytes[(y * width + x) * 4 + 1] = x % 255; //R
			bytes[(y * width + x) * 4 + 2] = y % 255; //G
			bytes[(y * width + x) * 4 + 3] = 0;
		}
	}*/
	
	CGContextRef context = CGBitmapContextCreate(bytes, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
	CGImageRef imageRef = CGBitmapContextCreateImage (context);
	UIImage *rawImage = [UIImage imageWithCGImage:imageRef];
	
	image.image = rawImage;
		
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CGImageRelease(imageRef);
}

- (void) showProgress
{
	[progressBar setHidden:NO];
}

- (void) updateProgress:(int) bytes
{
	float progressValue = ((float)bytes) / (1024*768*4);
	[progressBar setProgress:progressValue];
}

- (void) hideProgress
{
	[progressBar setHidden:YES];	
}

@end
