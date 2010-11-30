#import "ConfigViewController.h"

@implementation ConfigViewController

@synthesize ipAddress;
@synthesize image;

- (void)viewDidLoad {
    [super viewDidLoad];
	ipAddress.text = [NSString stringWithFormat:@"%@:%@", [self getIPAddress], @"4446"];
		
	UIImage *rawimage;
	UIDevice* thisDevice = [UIDevice currentDevice];
    if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
		rawimage = [UIImage imageNamed:@"config-ipad.png"];
		image.frame = CGRectMake(0, 0, 1024, 768);
		
		ipAddress.frame = CGRectMake(367, 214, 300, 40);
		ipAddress.font = [UIFont fontWithName:@"Helvetica Neue" size:20];
    }
    else
    {
		rawimage = [UIImage imageNamed:@"config.png"];
		image.frame = CGRectMake(0, 0, 480, 320);
		
		ipAddress.frame = CGRectMake(147, 78, 300, 40);		
		ipAddress.font = [UIFont fontWithName:@"Helvetica" size:10];
    }
	
	image.image = rawimage;
	[rawimage release];
}

// getIPAddress from: http://blog.zachwaugh.com/post/309927273/programmatically-retrieving-ip-address-of-iphone
- (NSString *)getIPAddress
{
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);

	return address;
}

@end
