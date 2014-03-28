//
//  ViewController.h
//  testCloudPrint
//
//  Created by Suwitcha Sugthana on 3/29/14.
//  Copyright (c) 2014 Suwitcha Sugthana. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UIWebViewDelegate>
- (IBAction)testButton:(id)sender;
@property (weak, nonatomic) IBOutlet UIWebView *WebView;
@property (weak, nonatomic) IBOutlet NSString *absoluteString;

@end
