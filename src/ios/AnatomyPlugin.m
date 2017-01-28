#import "AnatomyPlugin.h"
#import "AnatomyViewController.h"

@implementation AnatomyPlugin

- (void)presentAnatomyView:(CDVInvokedUrlCommand*)command
{
    NSString* jsonDataString = [[command arguments] objectAtIndex:0];

    AnatomyViewController *anatomyViewController = [[AnatomyViewController alloc] init];
    anatomyViewController.jsonDataString = jsonDataString;
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:anatomyViewController];
    [self.viewController presentViewController:anatomyViewController animated:YES completion:nil];

    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



@end
