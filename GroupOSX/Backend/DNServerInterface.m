//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"

#import "DNLoginSheetController.h"
@implementation DNServerInterface

#pragma mark - Application-Wide Constants
static NSString * const DNOAuth2ClientID = @"ZKKrd820vbBu0wHiizLuq9XcKLTGueKr3FFTudjsL9kpYT0N";
static NSString * const DNOAuth2ClientSecret = @"";
static NSString * const DNOAuth2ClientAuthorizationURL = @"https://api.groupme.com/oauth/authorize";
static NSString * const DNOAuth2ClientTokenURL = @"gosx://token/";
static NSString * const DNOAuth2ClientRedirectURL = @"gosx://token/";
static NSString * const DNOAuth2ClientAccountType = @"GroupMe";


#pragma mark - Server Initialization Logic
-(id)init
{
    self = [super init];
    if (self){
        //Initialize LoginSheetController to enable login mechanism

        
        
        //Configure OAuth2Client to have correct client data in order to connect to GroupMe
        
        [[NXOAuth2AccountStore sharedStore] setClientID:DNOAuth2ClientID
                                                 secret:DNOAuth2ClientSecret
                                       authorizationURL:[NSURL URLWithString:DNOAuth2ClientAuthorizationURL]
                                               tokenURL:[NSURL URLWithString:DNOAuth2ClientTokenURL]
                                            redirectURL:[NSURL URLWithString:DNOAuth2ClientRedirectURL]
                                         forAccountType:DNOAuth2ClientAccountType];

        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
                                                          object:[NXOAuth2AccountStore sharedStore]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSLog(@"Successfully authenticated");
                                                          [self authenticatedOn];
                                                      }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
                                                          object:[NXOAuth2AccountStore sharedStore]
                                                           queue:nil
                                                      usingBlock:^(NSNotification *aNotification){
                                                          NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
                                                          NSLog(@"Failed to authenticate, error: %@", error);
                                                          [self authenticatedOff];
                                                      }];
        
        
        //Configure server interface and instantiate SocketRocket
//        socketDelegate = [[DNSocketDelegate alloc] init];
//        socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"blah"]]];
//        [socket setDelegate:socketDelegate];

    }
    return self;
}


#pragma mark - Authentication Methods

//Because of the nature of GroupMe's OAuth2 system, a view is always needed for authentication
//Therefore ServerInterface keeps strong connection to LoginSheetController
- (void)authenticate
{
    if (![self loggedIn]) {
        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:DNOAuth2ClientAccountType
                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
                                           [self.loginSheetController promptForLoginWithPreparedURL:preparedURL];
                                       }];
    }
}

- (void)authenticatedOn
{
    authenticated = YES;
}

- (void)authenticatedOff
{
    authenticated = NO;
}

- (BOOL)loggedIn
{
    return authenticated;
}
@end