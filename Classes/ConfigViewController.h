#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@interface ConfigViewController : UIViewController
{
	UILabel *ipAddress;
	UIImageView *image;
}

@property (nonatomic, retain) IBOutlet UILabel *ipAddress;
@property (nonatomic, retain) IBOutlet UIImageView *image;

- (NSString *)getIPAddress;

@end
