//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"

#import "DNLoginSheetController.h"


@interface DNServerInterface ()
{
    SRWebSocket *socket;
    DNSocketDelegate *socketDelegate;
    BOOL authenticated;
    NSString *userToken;
    AFHTTPRequestOperationManager *HTTPRequestManager;
}

- (void)authenticatedOn;
- (void)authenticatedOff;

@end

@implementation DNServerInterface


#pragma mark - Server Initialization Logic
- (id)init
{
    self = [super init];
    if (self){
        //Configure server interface and instantiate SocketRocket
        socketDelegate = [[DNSocketDelegate alloc] init];
        HTTPRequestManager = [AFHTTPRequestOperationManager manager];
    }
    return self;
}


#pragma mark - Requests and Connection Logic

- (NSDictionary*)getUserInformation
{
    NSDictionary* userInfo;
    [HTTPRequestManager GET:[NSString stringWithFormat:@"%@%@", DNRESTAPIBaseAddress, @"/users/me"]
                 parameters:[NSDictionary dictionaryWithObjectsAndKeys:userToken, URLTokenParamKey, nil]
                    success:^(AFHTTPRequestOperation *operation, id responseObject){
                        DebugLog(@"%@", responseObject);
                        NSError *error = [[NSError alloc] init];
                        __block NSDictionary *userInfo = [NSJSONSerialization JSONObjectWithData:(NSData*)responseObject options:0 error:&error];
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error){
                        DebugLog(@"%s: %@",__PRETTY_FUNCTION__, error);
                    }];
    return userInfo;
}

#pragma mark - Authentication/Token Retrieval

//Because of the nature of GroupMe's OAuth2 system, a view is always needed for authentication
//Therefore ServerInterface keeps strong connection to LoginSheetController
- (void)authenticate
{
    if (![self isLoggedIn]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           DNOAuth2ClientID, @"client_id",
                                           nil];
        NSURL *preparedAuthorizationURL = [[NSURL URLWithString:DNOAuth2AuthorizationURL] nxoauth2_URLByAddingParameters:parameters];
        DebugLog(@"Server is authenticating at %@", [preparedAuthorizationURL absoluteString]);
        [self.loginSheetController promptForLoginWithPreparedURL:preparedAuthorizationURL];
    }
}

- (void)didReceiveURL:(NSURL*)url
{
    DebugLog(@"Server received URL: %@", [url absoluteString]);
    NSString *token = [url nxoauth2_valueForQueryParameterKey:DNOAuth2TokenArgumentKey];
    
    if (token) {
        [self authenticatedOn];
        [self.loginSheetController closeLoginSheet];
        DebugLog(@"Server successfully authenticated with token: %@", token);
        //save user setting right here
        userToken = token;
        [self getUserInformation];
    }else{
        DebugLog(@"Server failed to retrieve token, authentication restart...");
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