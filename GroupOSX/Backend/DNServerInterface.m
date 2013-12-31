//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"
#import "DNLoginSheetController.h"
#import "DNSocketManager.h"

#ifdef DEBUG
#import "DNAsynchronousUnitTesting.h"
#endif

//Macros for HTTPRequestManager calls
#define baseURLPlus(string) [NSString stringWithFormat:@"%@%@", DNRESTAPIBaseAddress, string]
#define NSNumber(num) [NSNumber numberWithInteger:num]
#define token_pair @"token":userToken
#define report_request_error DebugLog(@"%s: %@",__PRETTY_FUNCTION__, error)
#define get_response(responseObject) (NSDictionary*)responseObject[@"response"]

@interface DNServerInterface ()
{
    BOOL authenticated;
    BOOL connected;
    AFHTTPRequestOperationManager *HTTPRequestManager;
    DNSocketManager *socketManager;
    
    //User information
    NSDictionary *userInformation;
    NSString *userToken;
}

@end

@implementation DNServerInterface

#pragma mark - Initialization Logic

- (id)init
{
    self = [super init];
    if (self){
        socketManager = [[DNSocketManager alloc] init];
        socketManager.server = self;
        HTTPRequestManager = [AFHTTPRequestOperationManager manager];
        [self establishObserversForNetworkEvents];
    }
    return self;
}

- (void)establishObserversForNetworkEvents
{
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInformationChanged object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        DebugLog(@"UserInformation Changed: %@", userInformation);
        [self establishSockets];
    }];
}


#pragma mark - Requests and Connection Logic

//Users - me
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userInfo))completeBlock
{
    [HTTPRequestManager GET:baseURLPlus(@"/users/me")
                 parameters:@{token_pair}
     
                    success:^(AFHTTPRequestOperation *operation, id responseObject){
                        completeBlock(get_response(responseObject));
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error){
                        report_request_error;
                    }];
}

//Groups - Index
- (void)GroupsIndexPage:(NSInteger)nthPage
                   with:(NSInteger)pagesPerPage
       andCompleteBlock:(void(^)(NSDictionary* groupsIndexData))completeBlock
{
    [HTTPRequestManager GET:baseURLPlus(@"/groups")
                 parameters:@{token_pair,
                              @"page":NSNumber(nthPage),
                              @"per_page":NSNumber(pagesPerPage)}
     
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        completeBlock(get_response(responseObject));
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        report_request_error;
                    }];
}

//Groups - Former
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSDictionary* groupsFormerData))completeBlock
{
    [HTTPRequestManager GET:baseURLPlus(@"/groups/former")
                 parameters:@{token_pair}
     
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        completeBlock(get_response(responseObject));
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        report_request_error;
                    }];
}

//Groups - Show
- (void)GroupsShow:(NSString*)groupID andCompleteBlock:(void(^)(NSDictionary* groupsShowData))completeBlock
{
    [HTTPRequestManager GET:[NSString stringWithFormat:@"%@%@%@", DNRESTAPIBaseAddress, @"/groups/", groupID]
                 parameters:@{token_pair,
                              @"id":groupID}
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        completeBlock(get_response(responseObject));
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        report_request_error;
                    }];
}


#pragma mark - Authentication/Token Retrieval

//Three step authentication/connection documentation
//Step one: authenticate using webview and get token, wait for GroupMe to send in token-carrying URL
//Step two: an AppleEvent with toekn-carrying URL will be sent in, didReceiveURL:url handles it
//Step three: didReceiveURL:url requests for UserInformation, NSNotificationCenter gets kUserInformationChanged and calls establishSockets in callback block

- (void)authenticate
{
    if (![self isLoggedIn]) {
        NSDictionary *parameters = @{@"client_id": DNOAuth2ClientID};
        NSURL *preparedAuthorizationURL = [[NSURL URLWithString:DNOAuth2AuthorizationURL] nxoauth2_URLByAddingParameters:parameters];
        DebugLog(@"Server is authenticating at %@", [preparedAuthorizationURL absoluteString]);
        [self.loginSheetController promptForLoginWithPreparedURL:preparedAuthorizationURL];
    }
}

//Step two: close loginSheet and use this token to get user information, redirect to establishSockets
- (void)didReceiveURL:(NSURL*)url
{
    DebugLog(@"Server received URL: %@", [url absoluteString]);
    NSString *token = [url nxoauth2_valueForQueryParameterKey:@"access_token"];
    
    if (token) {
        authenticated = YES;
        [self.loginSheetController closeLoginSheet];
        DebugLog(@"Server successfully authenticated with token: %@", token);
        userToken = token;

#ifdef DEBUG
        [DNAsynchronousUnitTesting testAllAsynchronousUnits:self];
        [DNAsynchronousUnitTesting testAllSockets:socketManager];
#endif
        
        [self UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
            userInformation = userInfo;
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserInformationChanged object:nil];
        }];
        
    }else{
        DebugLog(@"Server failed to retrieve token, authentication restart...");
        authenticated = NO; //just to be sure
        [self.loginSheetController closeLoginSheet];
        [self authenticate]; //do it again
    }
}

//Step three: after receiving tokens and userInformation, establish websockets to listen for incoming messages
- (void)establishSockets
{
    if (!connected) {
    }
}


- (BOOL)isLoggedIn
{
    return authenticated;
}

- (BOOL)isConnected
{
    return connected;
}

- (NSString*)getUserToken
{
    return userToken;
}

@end