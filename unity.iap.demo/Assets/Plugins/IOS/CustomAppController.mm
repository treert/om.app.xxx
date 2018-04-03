/*header
    > File Name: CustomAppController.mm
    > Create Time: 2018-04-03 星期二 20时03分20秒
    > Athor: treertzhu
*/
#import "UnityAppController.h"
#import "WXApi.h"

@interface CustomAppController : UnityAppController
@end

IMPL_APP_CONTROLLER_SUBCLASS (CustomAppController)

@implementation CustomAppController

- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [super application:application didFinishLaunchingWithOptions:launchOptions];

    
    return YES;
}

@end