//
//  ViewController.m
//  testCloudPrint
//
//  Created by Suwitcha Sugthana on 3/29/14.
//  Copyright (c) 2014 Suwitcha Sugthana. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    //in order to login to Google APIs using OAuth2 we must show an embedded browser (UIWebView)
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"googleClientAuthService"
                                   withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                       
                                       //navigate to the URL returned by NXOAuth2Client
                                       [self.WebView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                   }];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)testButton:(id)sender {
    NSLog(@"XXX");
}
@end
