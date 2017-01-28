#import "HWPHello.h"
#import "AnatomyViewController.h"

@implementation HWPHello

- (void)greet:(CDVInvokedUrlCommand*)command
{    
    NSString* jsonDataString = [[command arguments] objectAtIndex:0];
    
    AnatomyViewController *anatomyViewController = [[AnatomyViewController alloc] init];
    anatomyViewController.jsonDataString = jsonDataString;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:anatomyViewController];
    [self.viewController presentViewController:navController animated:YES completion:nil];
   
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



@end
