//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"

#import "DNLoginSheetController.h"
#import "DNMainWindowController.h"

#ifdef DEBUG_BACKEND
#import "DNAsynchronousUnitTesting.h"
#endif

//Macros for HTTPRequestManager calls
#define baseURLPlus(string) [NSString stringWithFormat:@"%@%@", DNRESTAPIBaseAddress, string]
#define NSNumber(num) [NSNumber numberWithInteger:num]
#define token_pair @"token":self.userToken
#define report_request_error DebugLog(@"%s: %@",__PRETTY_FUNCTION__, error)
#define get_response(responseObject) (NSDictionary*)responseObject[@"response"]


/*
 Authentication Flow Documentation (for GroupMe's weird non-standard interface)
 
 1. Server initiated, BOOL authenticated and BOOL listening are false, indicating that the app has not yet obtained a NSString *userToken and a working FayeClient *socketClient
 2. When (void)authenticate is called, it calls LoginSheetController to open up a web portal through OAuth2ClientID-carrying URL
 3. When web OAuth2 authentication completes, app receives an Apple event containing an URL that contains the golden NSString *userToken
 4. AppDelegate will redirect this URL string to didReceiveURL:url, which will receive userToken and set BOOL authenticated = YES, then send a HTTP request for user information, update it internally and post a NSNotification of kUserInformationChanged
 5. Upon receiving kUserInformationChanged, the block will continue to establish sockets
 6. Once sockets are good, BOOL listening = YES, the delegate method called by FayeClient will proceed to call controllers and reload its interface elements and update internal data
 
 Note: each authentication provides extensive fallbacks in case of network error or authentication error.
 */


/*
 Authentication Flow Error Fallback Scheme
 1. Web portal authentication
    1. No network connection - reachability check within (void)authenticate and (void)establishSockets
    2. Authentication failure: retry within (void)authenticate
 */

@interface DNServerInterface ()

//Internal bookkeeping
@property BOOL authenticated;
@property BOOL listening;
@property AFHTTPRequestOperationManager *HTTPRequestManager;
@property FayeClient *socketClient;
@property KSReachability *reachability;

//User information
@property NSDictionary *userInfo;
@property NSString *userToken;

@end


@implementation DNServerInterface

#pragma mark - Initialization Logic

- (id)init
{
    self = [super init];
    if (self){
        self.HTTPRequestManager = [AFHTTPRequestOperationManager manager];
        //FayeClient initialization needs to wait for userInformation to be populated
        self.reachability = [KSReachability reachabilityToHost:DNRESTAPIBaseAddress];
        self.userToken = [[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserToken];
        self.userInfo =  (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserInfo]];
        if (self.userToken) {
            self.authenticated = YES;
        }
        [self establishObserversForNetworkEvents];
    }
    return self;
}

- (void)establishObserversForNetworkEvents
{
    //For network reachability change
    __weak DNServerInterface* block_self = self;
    self.reachability.onReachabilityChanged = ^(KSReachability* reachability)
    {
        NSLog(@"Reachability changed to %d (blocks)", reachability.reachable);
        switch (reachability.reachable) {
            case YES:
                DebugLog(@"GroupMe now reachable");
                [block_self authenticate];
                [block_self establishSockets];
                break;
            case NO:
            {//variable assignment not allowed inside switch without explicit scope
                DebugLog(@"Lost Connection to GroupMe");
                block_self.listening = NO;
                NSError *error = [[NSError alloc] initWithDomain:DNErrorDomain code:eNoNetworkConnectivityGeneral userInfo:@{NSLocalizedDescriptionKey: eNoNetworkConnectivityGeneralDesc}];
                [block_self.loginSheetController.mainWindowController presentError:error];
                break;
            }
            default:
                break;
        }
    };
    
    //For authentication
    [[NSNotificationCenter defaultCenter] addObserverForName:kUserInformationChanged object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        DebugLog(@"UserInformation Changed: %@", self.userInfo);
        if (!self.listening) {
            [self establishSockets];
        }
    }];
}


#pragma mark - Requests and Connection Logic

//Users - me
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userInfo))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/users/me")
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
    [self.HTTPRequestManager GET:baseURLPlus(@"/groups")
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
    [self.HTTPRequestManager GET:baseURLPlus(@"/groups/former")
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
    [self.HTTPRequestManager GET:[NSString stringWithFormat:@"%@%@%@", DNRESTAPIBaseAddress, @"/groups/", groupID]
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

//The almighty setup always makes sure everything is set up
- (void)setup
{
    if (!self.authenticated) {
        [self authenticate];
    }else if(!self.listening){
        [self establishMessageSocket];
    }
}

- (void)authenticate
{
    DebugLog(@"Reachability: %hhd", self.reachability.reachable);
    if (!self.authenticated && self.reachability.reachable) {
        NSDictionary *parameters = @{@"client_id": DNOAuth2ClientID};
        NSURL *preparedAuthorizationURL = [[NSURL URLWithString:DNOAuth2AuthorizationURL] nxoauth2_URLByAddingParameters:parameters];
        DebugLog(@"Server is authenticating at %@", [preparedAuthorizationURL absoluteString]);
        [self.loginSheetController promptForLoginWithPreparedURL:preparedAuthorizationURL];
    }
}

- (void)teardown
{
    DebugLog(@"Deauthenticating...");
    self.userToken = nil;
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DNUserDefaultsUserToken];
    self.userInfo = nil;
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:DNUserDefaultsUserInfo];
    self.authenticated = NO;
    
    [self.socketClient disconnectFromServer];
    self.listening = NO;
        
    [self authenticate];
}

- (void)didReceiveURL:(NSURL*)url
{
    DebugLog(@"Server received URL: %@", [url absoluteString]);
    NSString *token = [url nxoauth2_valueForQueryParameterKey:@"access_token"];
    
    if (token) {
        self.authenticated = YES;
        [self.loginSheetController closeLoginSheet];
        DebugLog(@"Server successfully authenticated with token: %@", token);
        self.userToken = token;
        [[NSUserDefaults standardUserDefaults] setObject:self.userToken forKey:DNUserDefaultsUserToken];

#ifdef DEBUG_BACKEND
        [DNAsynchronousUnitTesting testAllAsynchronousUnits:self];
        [DNAsynchronousUnitTesting testAllSockets:self];
#endif
        
        [self UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
            self.userInfo = userInfo;
            NSData *userInfoData = [NSKeyedArchiver archivedDataWithRootObject:userInfo];
            [[NSUserDefaults standardUserDefaults] setObject:userInfoData forKey:DNUserDefaultsUserInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserInformationChanged object:nil];
        }];
        
    }else{
        DebugLog(@"Server failed to retrieve token, authentication restart...");
        self.authenticated = NO; //just to be sure
        [self.loginSheetController closeLoginSheet];
        [self authenticate]; //do it again
    }
}

- (BOOL)isLoggedIn
{
    return self.authenticated;
}

- (BOOL)isListening
{
    return self.listening;
}

#pragma mark - Web Sockets / Faye Push Notification

- (void)establishSockets
{
    if (self.authenticated && !self.listening && self.reachability.reachable) {
        [self establishMessageSocket];
    }
}

//One message socket is needed for the entire application
- (void)establishMessageSocket
{
    self.socketClient = [[FayeClient alloc] initWithURLString:@"https://push.groupme.com/faye"
                                         channel:[NSString stringWithFormat:@"/user/%@",self.userInfo[@"id"]]];
    self.socketClient.delegate = self;
    NSDictionary *externalInformation = @{@"access_token":self.userToken,
                                          @"timestamp":[[NSDate date] description]};
    [self.socketClient connectToServerWithExt:externalInformation];
}

- (void)connectedToServer {
    DebugLog(@"Push server connected");
}

- (void)disconnectedFromServer {
    DebugLog(@"Push server disconnected");
}

- (void)messageReceived:(NSDictionary *)messageDict channel:(NSString *)channel
{
    DebugLog(@"%@", messageDict);
}

- (void)connectionFailed
{
    DebugLog(@"Push server connection failed");
}
- (void)didSubscribeToChannel:(NSString *)channel
{
    DebugLog(@"Subscribed to channel: %@", channel);
    self.listening = YES;
}
- (void)didUnsubscribeFromChannel:(NSString *)channel
{
    DebugLog(@"Subscribed from channel: %@", channel);
}
- (void)subscriptionFailedWithError:(NSString *)error
{
    DebugLog(@"Subscription Failed: %@", error);
}
- (void)fayeClientError:(NSError *)error
{
    DebugLog(@"FayeClient error: %@", error);
}

//This method is optional, and only intercepts messages being sent
#ifdef DEBUG_BACKEND
- (void)fayeClientWillSendMessage:(NSDictionary *)messageDict withCallback:(FayeClientMessageHandler)callback
{
    DebugLog(@"Sending Faye message: %@", messageDict);
    callback(messageDict); //callback is critical, it actually sends the message
}
#endif

@end