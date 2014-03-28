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
static NSString * const kIDMOAuth2SuccessPagePrefix = @"Success";
static NSString * const kIDMOAuth2AccountType = @"Google API";

- (void)viewDidLoad
{
    [super viewDidLoad];
    //in order to login to Google APIs using OAuth2 we must show an embedded browser (UIWebView)
    [self setupOAuth2AccountStore];
    [self requestOAuth2Access];
    
	self.WebView.delegate = self;
}
- (void)setupOAuth2AccountStore
{
    //these steps are docmented in the NXOAuth2Client readme.md
    //https://github.com/nxtbgthng/OAuth2Client
    //the values used are documented above along with their origin
    [[NXOAuth2AccountStore sharedStore] setClientID:@"808528885177-joht12lu4762v7d62ff9dmrm478lia8j.apps.googleusercontent.com"
                                             secret:@"AUOSoqLhIl-kZuLD2KokYT-_"
                                              scope:[NSSet setWithObject:@"https://www.googleapis.com/auth/userinfo.profile"]
                                   authorizationURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/auth"]
                                           tokenURL:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/token"]
                                        redirectURL:[NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"]
                                     forAccountType:@"googleClientAuthService"];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      
                                                      if (aNotification.userInfo) {
                                                          //account added, we have access
                                                          //we can now request protected data
                                                          NSLog(@"Success!! We have an access token.");
                                                          [self requestOAuth2ProtectedDetails];
                                                      } else {
                                                          //account removed, we lost access
                                                      }
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                      object:[NXOAuth2AccountStore sharedStore]
                                                       queue:nil
                                                  usingBlock:^(NSNotification *aNotification){
                                                      
                                                      NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                      NSLog(@"Error!! %@", error.localizedDescription);
                                                      
                                                  }];
}
-(void)requestOAuth2Access
{
    //in order to login to Google APIs using OAuth2 we must show an embedded browser (UIWebView)
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"googleClientAuthService"
                                   withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                       
                                       //navigate to the URL returned by NXOAuth2Client
                                       [self.WebView loadRequest:[NSURLRequest requestWithURL:preparedURL]];
                                   }];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    //if the UIWebView is showing our authorization URL, show the UIWebView control
    if ([webView.request.URL.absoluteString rangeOfString:[NSURL URLWithString:@"https://accounts.google.com/o/oauth2/auth"] options:NSCaseInsensitiveSearch].location != NSNotFound) {
        self.WebView.hidden = NO;
    } else {
        //otherwise hide the UIWebView, we've left the authorization flow
        self.WebView.hidden = YES;
        
        //read the page title from the UIWebView, this is how Google APIs is returning the
        //authentication code and relation information
        //this is controlled by the redirect URL we chose to use from Google APIs
        NSString *pageTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        
        //continue the OAuth2 flow using the info from the page title
    }
}
- (void)handleOAuth2AccessResult:(NSString *)accessResult
{
    //parse the page title for success or failure
    BOOL success = [accessResult rangeOfString:kIDMOAuth2SuccessPagePrefix options:NSCaseInsensitiveSearch].location != NSNotFound;
    
    //if success, complete the OAuth2 flow by handling the redirect URL and obtaining a token
    if (success) {
        //authentication code and details are passed back in the form of a query string in the page title
        //parse those arguments out
        NSString * arguments = accessResult;
        if ([arguments hasPrefix:kIDMOAuth2SuccessPagePrefix]) {
            arguments = [arguments substringFromIndex:kIDMOAuth2SuccessPagePrefix.length + 1];
        }
        
        //append the arguments found in the page title to the redirect URL assigned by Google APIs
        NSString *redirectURL = [NSString stringWithFormat:@"%@?%@", [NSURL URLWithString:@"urn:ietf:wg:oauth:2.0:oob"], arguments];
        
        //finally, complete the flow by calling handleRedirectURL
        [[NXOAuth2AccountStore sharedStore] handleRedirectURL:[NSURL URLWithString:redirectURL]];
    } else {
        //start over
        [self requestOAuth2Access];
    }
}
- (NSString *)nxoauth2_valueForQueryParameterKey:(NSString *)key;
{
    //self may not contain a scheme
    //for instance Google API redirect url may look like urn:ietf:wg:oauth:2.0:oob
    //NSURL requires a valid scheme or query will return nil
    NSString *absoluteString = self.absoluteString;
    if ([absoluteString rangeOfString:@"://"].location == NSNotFound) {
        absoluteString = [NSString stringWithFormat:@"http://%@", absoluteString];
    }
    NSURL *qualifiedURL = [NSURL URLWithString:absoluteString];
    
    NSString *queryString = [qualifiedURL query];
    NSDictionary *parameters = [queryString nxoauth2_parametersFromEncodedQueryString];
    return [parameters objectForKey:key];
}
- (void)requestOAuth2ProtectedDetails
{
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:kIDMOAuth2AccountType];
    
    
    [NXOAuth2Request performMethod:@"GET"
                        onResource:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]
                   usingParameters:nil
                       withAccount:accounts[0]
               sendProgressHandler:^(unsigned long long bytesSend, unsigned long long bytesTotal) {
                   // e.g., update a progress indicator
               }
                   responseHandler:^(NSURLResponse *response, NSData *responseData, NSError *error){
                       // Process the response
                       if (responseData) {
                           NSError *error;
                           NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                           NSLog(@"%@", userInfo);
                       }
                       if (error) {
                           NSLog(@"%@", error.localizedDescription);
                       }
                   }];
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
