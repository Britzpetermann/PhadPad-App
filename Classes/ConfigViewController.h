#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#include <arpa/inet.h>

@interface ConfigViewController : UIViewController {

	 UILabel *ipAddress;
}

@property (nonatomic, retain) IBOutlet UILabel *ipAddress;

- (NSString *)getIPAddress;

@end
