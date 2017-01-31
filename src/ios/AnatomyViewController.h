//
//  AnatomyViewController.h
//  Hello
//
//  Created by Grayson Sharpe on 1/18/17.
//
//

#import <UIKit/UIKit.h>

@class MBProgressHUD;

@interface AnatomyViewController : UIViewController {
    MBProgressHUD *_hud;
}

@property (strong, nonatomic) NSDictionary* jsonData;

@end
