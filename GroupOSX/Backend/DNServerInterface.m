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

//Asynchronous chain-recursion variables
@property NSInteger currentPageNum;
@property NSMutableArray *prevResults;
@property BOOL currentlyPollingForGroups;

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
#ifdef DEBUG_BACKEND
        self.userToken = nil;
        self.userInfo = nil;
#endif
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
}

#pragma mark - High-Level Request Triggers (Public)

- (void)requestGroups
{
    [self requestNextGroupsWithNewestResult:nil triggerType:noteForceRequestGroupData];
}

#pragma mark - High-Level Requests API

- (void)requestNextGroupsWithNewestResult:(NSArray*)newestResult triggerType:(NSString*)type
{
    if (!_prevResults && !_currentlyPollingForGroups) {
        //first call
        _currentlyPollingForGroups = YES;
        _currentPageNum = 1;
        _prevResults = [[NSMutableArray alloc] init];
    }else if ([newestResult count] != 0){
        //new results arrived
        [_prevResults addObjectsFromArray:newestResult];
        _currentPageNum += 1;
    }else{
        //no more groups, post notification with complete results
        NSArray *rawGroupList = _prevResults;
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
            NSMutableArray *groupList = [[NSMutableArray alloc] initWithCapacity:[rawGroupList count]];
            [rawGroupList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *group = (NSDictionary*)obj;
                group = [self convertRawDictionary:group];
                [groupList addObject:group];
            }];
            NSDictionary *userInfo = @{kGetContentKey: groupList, kGetTypeKey:type};
            [[NSNotificationCenter defaultCenter] postNotificationName:finalGroupIndexResultsArrived object:nil userInfo:userInfo];

        });
        _currentlyPollingForGroups = NO;
        _prevResults = nil;
        return;
    }

    DebugLogCD(@"Group Polling page: %d", (int)self.currentPageNum);
    NSInteger num = 50; //Poll as many as possible at once to avoid repeated polling recursion
#ifdef DEBUG_BACKEND
    num = 1; //Small to see if repeated polling works or not
#endif
    
    [self GroupsIndexPage:self.currentPageNum with:num perPageAndCompleteBlock:^(NSArray *groupsIndexData) {
        [self requestNextGroupsWithNewestResult:groupsIndexData triggerType:type];
    }];
}

#pragma mark - Low-Level Requests and Connection Logic

//Convert a JSON-serialized crappy Dictionary into one with Cocoa objects
- (NSDictionary*)convertRawDictionary:(NSDictionary*)oldDict
{
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    [oldDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *strKey = [NSString stringWithFormat:@"%@", key];
        NSString *strObj = [NSString stringWithFormat:@"%@", obj];
        
        //is a date, GroupMe uses "ddddd" seconds after 1970
        if ([strKey isEqualToString:@"created_at"] || [strKey isEqualToString:@"updated_at"]) {
            NSDate *date = nil;
            NSRegularExpression *dateRegEx = nil;
            dateRegEx = [[NSRegularExpression alloc] initWithPattern:@"^(-?\\d+)(?:([+-])(\\d{2})(\\d{2}))?$"
                                                             options:NSRegularExpressionCaseInsensitive error:nil];
            NSTextCheckingResult *regexResult = [dateRegEx firstMatchInString:strObj
                                                                      options:0
                                                                        range:NSMakeRange(0, [strObj length])];
            if (regexResult) {
                //Milliseconds to seconds
                NSTimeInterval seconds = [[strObj substringWithRange:[regexResult rangeAtIndex:1]] doubleValue];
                //Timezone offset
                if ([regexResult rangeAtIndex:2].location != NSNotFound) {
                    //Offset sign
                    NSString *sign = [strObj substringWithRange:[regexResult rangeAtIndex:2]];
                    //Offset hours
                    seconds += [[NSString stringWithFormat:@"%@%@", sign, [strObj substringWithRange:[regexResult rangeAtIndex:3]]] doubleValue] * 60.0 * 60.0;
                    //Offset minutes
                    seconds += [[NSString stringWithFormat:@"%@%@", sign, [strObj substringWithRange:[regexResult rangeAtIndex:4]]] doubleValue] * 60.0;
                }
                date = [NSDate dateWithTimeIntervalSince1970:seconds];
            }else{
                DebugLog(@"Date parsing on incoming message failed: %@", oldDict);
                //If GroupMe sends an ill-formatted date, you can only hope the next update will correct it
                date = [NSDate date];
            }
            [newDict setObject:date forKey:strKey];
        //is an image, either in message, or in an attachment
        }else if ([strKey isEqualToString:@"image_url"] || ([strKey isEqualToString:@"url"] && [oldDict[@"type"] isEqualToString:@"image"])){
            NSURL *imageUrl = [NSURL URLWithString:strObj];
            if (imageUrl) {
                NSImage *image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:imageUrl]];
                if (image) {
                    [newDict setObject:image forKey:@"image"];
                }else{
                    [newDict setObject:[NSNull null] forKey:@"image"];
                }
            }
        //is generic url (as in the case of "share_url"
        }else if ([strKey hasSuffix:@"url"]){
            NSURL *url = [NSURL URLWithString:strObj];
            if (url) {
                [newDict setObject:url forKey:strKey];
            }else{
                [newDict setObject:[NSNull null] forKey:strKey];
            }
        //is boolean
        }else if ([strObj isEqualToString:@"false"] || [strObj isEqualToString:@"true"]){
            BOOL value = [strObj isEqualToString:@"true"];
            [newDict setObject:[NSNumber numberWithBool:value] forKey:strKey];
        //all other cases, treat as string
        }else{
            if (![obj isKindOfClass:[NSString class]]) {
                strObj = obj;
            }
            [newDict setObject:strObj forKey:strKey];
        }
    }];
    return newDict;
}

//Users - me
//Response should be a dictionary
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userInfo))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/users/me")
                 parameters:@{token_pair}
     
                    success:^(AFHTTPRequestOperation *operation, id responseObject){
                        completeBlock((NSDictionary*)responseObject[@"response"]);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error){
                        report_request_error;
                    }];
}

//Groups - Index
//Response should be an array of dictionaries
- (void)GroupsIndexPage:(NSInteger)nthPage
                   with:(NSInteger)groups
       perPageAndCompleteBlock:(void(^)(NSArray* groupsIndexData))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/groups")
                 parameters:@{token_pair,
                              @"page":NSNumber(nthPage),
                              @"per_page":NSNumber(groups)}
     
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        completeBlock((NSArray*)responseObject[@"response"]);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        report_request_error;
                    }];
}

//Groups - Former
//Response should be an array of dictionaries
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSArray* groupsFormerData))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/groups/former")
                 parameters:@{token_pair}
     
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                        completeBlock((NSArray*)responseObject[@"response"]);
                    }
                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                        report_request_error;
                    }];
}

//Groups - Show
//Response should be a dictionary
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
    //To-Do: true logout includes logout in webview
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
        
        //First time log-on
        [[NSNotificationCenter defaultCenter] postNotificationName:noteFirstTimeLogon object:nil];
        
        [self UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
            self.userInfo = userInfo;
            NSData *userInfoData = [NSKeyedArchiver archivedDataWithRootObject:userInfo];
            [[NSUserDefaults standardUserDefaults] setObject:userInfoData forKey:DNUserDefaultsUserInfo];
            DebugLog(@"UserInformation Changed: %@", self.userInfo);
            [self establishSockets];
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

- (BOOL)isUser:(NSString*)name
{
    return self.authenticated && [self.userInfo[@"name"] isEqualToString:name];
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

//This is a giant router of raw messages, the type of message dictates the next method to call, or nothing at all
- (void)messageReceived:(NSDictionary *)messageDict channel:(NSString *)channel
{
    DebugLog(@"%@", messageDict);
    DebugLogCD(@"Server received raw message:\n%@", messageDict);
    
    NSString *identifierSenderName = [[messageDict objectForKey:@"subject"] objectForKey:@"name"];
    NSString *identifierUserID = [[messageDict objectForKey:@"subject"] objectForKey:@"user_id"];
    NSString *identifierForSystemMsg = [messageDict objectForKey:@"alert"];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    NSDictionary *userInfo = @{kGetContentKey: messageDict[@"subject"]};
    
    //Sent by system
    if ([identifierSenderName isEqualToString:@"GroupMe"] && [identifierUserID isEqualToString:@"0"]) {

        //Group member removed
        if ([identifierForSystemMsg rangeOfString:@"from the group"].location != NSNotFound) {
            [self requestNextGroupsWithNewestResult:nil triggerType:noteGroupMemberRemoved];
            
        //Group member added
        }else if ([identifierForSystemMsg rangeOfString:@"to the group"].location != NSNotFound){
            [self requestNextGroupsWithNewestResult:nil triggerType:noteGroupMemberAdded];
            
        //Group avatar changed
        }else if ([identifierForSystemMsg rangeOfString:@"changed the group's avatar"].location != NSNotFound){
            [self requestNextGroupsWithNewestResult:nil triggerType:noteGroupAvatarChanged];
        }

    //user generated notification, received directly by MainWindowController
    }else{
        if ([self isUser:identifierSenderName]) {
            [notificationCenter postNotificationName:noteUserOwnMessageReceived object:nil userInfo:userInfo];
        }else{
            [notificationCenter postNotificationName:noteMemberMessageReceived object:nil userInfo:userInfo];
        }
    }
}

- (void)connectionFailed
{
    DebugLog(@"Push server connection failed");
}
- (void)didSubscribeToChannel:(NSString *)channel
{
    DebugLog(@"Subscribed to channel: %@", channel);
    self.listening = YES;
    
    #ifdef DEBUG_CORE_DATA
//    [self requestGroups];
    #endif
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