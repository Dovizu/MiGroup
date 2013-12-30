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


#pragma mark - Server Initialization Logic
-(id)init
{
    self = [super init];
    if (self){
        //Initialize LoginSheetController to enable login mechanism
        
        
        
        //Configure OAuth2Client to have correct client data in order to connect to GroupMe
        
//        [[NXOAuth2AccountStore sharedStore] setClientID:DNOAuth2ClientID
//                                                 secret:DNOAuth2ClientSecret
//                                       authorizationURL:[NSURL URLWithString:DNOAuth2ClientAuthorizationURL]
//                                               tokenURL:[NSURL URLWithString:DNOAuth2ClientTokenURL]
//                                            redirectURL:[NSURL URLWithString:DNOAuth2ClientRedirectURL]
//                                         forAccountType:DNOAuth2ClientAccountType];
        
//        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreAccountsDidChangeNotification
//                                                          object:[NXOAuth2AccountStore sharedStore]
//                                                           queue:nil
//                                                      usingBlock:^(NSNotification *aNotification){
//                                                          NSLog(@"Successfully authenticated");
//                                                          [self authenticatedOn];
//                                                          [self.loginSheetController closeLoginSheet];
//                                                      }];
//        
//        [[NSNotificationCenter defaultCenter] addObserverForName:NXOAuth2AccountStoreDidFailToRequestAccessNotification
//                                                          object:[NXOAuth2AccountStore sharedStore]
//                                                           queue:nil
//                                                      usingBlock:^(NSNotification *aNotification){
//                                                          NSError *error = [aNotification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
//                                                          NSLog(@"Failed to authenticate, error: %@", error);
//                                                          [self authenticatedOff]; //to be sure
//                                                          [self authenticate];
//                                                      }];
        
        
        //Configure server interface and instantiate SocketRocket
        //        socketDelegate = [[DNSocketDelegate alloc] init];
        //        socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"blah"]]];
        //        [socket setDelegate:socketDelegate];
        
        
    }
    return self;
}


#pragma mark - Authentication/Token Retrieval

//Because of the nature of GroupMe's OAuth2 system, a view is always needed for authentication
//Therefore ServerInterface keeps strong connection to LoginSheetController
- (void)authenticate
{
    if (![self isLoggedIn]) {
//        [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:DNOAuth2ClientAccountType
//                                       withPreparedAuthorizationURLHandler:^(NSURL *preparedURL){
//                                           [self.loginSheetController promptForLoginWithPreparedURL:preparedURL];
//                                       }];
        [self.loginSheetController promptForLoginWithPreparedURL:[self prepareAuthenticationURL]];
    }
}

- (NSURL*)prepareAuthenticationURL
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       DNOAuth2ClientID, @"client_id",
                                       nil];
    
    return [[NSURL URLWithString:DNOAuth2AuthorizationURL] nxoauth2_URLByAddingParameters:parameters];
}

- (void)didReceiveURL:(NSURL*)url
{
    NSLog(@"Server received URL: %@", [url absoluteString]);
//    [[NXOAuth2AccountStore sharedStore] handleRedirectURL:[NSURL URLWithString:urlString]];
    
    NSString *token = [url nxoauth2_valueForQueryParameterKey:@"access_token"];
    if (token) {
        NSLog(@"Server successfully authenticated with token: %@", token);
        [self authenticatedOn];
        [self.loginSheetController closeLoginSheet];
    }else{
        [self authenticatedOff]; //just to be sure
        [self.loginSheetController closeLoginSheet];
        [self authenticate]; //do it again
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

- (BOOL)isLoggedIn
{
    return authenticated;
}
@end