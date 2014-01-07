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
#define concatStrings(format, ...) [NSString stringWithFormat:format, ##__VA_ARGS__]
#define NSNumber(num) [NSNumber numberWithInteger:num]
#define token_pair @"token":_userToken
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

//User information
@property NSDictionary *userInfo;
@property NSString *userToken;

- (void)notifyMembersRemoveActionWithMemberName:(NSString*)name andGroupID:(NSString*)identifierGroupID;
- (void)notifyMembersAddActionWithMemberNames:(NSArray*)names andGroupID:(NSString*)identifierGroupID;
- (void)notifyGroupAvatarChangeActionWithGroupID:(NSString*)identifierGroupID;
- (void)notifyGroupNameChangeActionWithName:(NSString*)name GroupID:(NSString*)identifierGroupID;
- (void)notifyGroupMemberNickNameChangeActionWithOldName:(NSString*)old newName:(NSString*)new;
- (void)notifyMessageFromSelf:(NSDictionary*)messageDict;
- (void)notifyMessageFromGeneric:(NSDictionary*)messageDict;
@end

//GroupMe HTTP request constants
NSString * const HTTPParamToken = @"token";

@implementation DNServerInterface
{
    
    AFNetworkReachabilityManager *_reachabilityManager;
    
    //Used by -(void)requestNextGroupsWithNewestResult:newestResult completionBlock:block
    NSInteger _currentPageNum;
    NSMutableArray *_prevResults;
    BOOL _currentlyPollingForGroups;
    NSNotificationCenter *_notificationCenter;
}

#pragma mark - Initialization Logic

- (id)init
{
    self = [super init];
    if (self){
        //Configure HTTP Request Manager
        _HTTPRequestManager = [AFHTTPRequestOperationManager manager];
        NSMutableSet *acceptableTypes = [NSMutableSet setWithSet:_HTTPRequestManager.responseSerializer.acceptableContentTypes];
        [acceptableTypes addObject:@"text/html"];
        _HTTPRequestManager.responseSerializer.acceptableContentTypes = [NSSet setWithSet:acceptableTypes];
        //FayeClient initialization needs to wait for userInformation to be populated
        _reachabilityManager = [_HTTPRequestManager reachabilityManager];
        _notificationCenter = [NSNotificationCenter defaultCenter];
        _userToken = [[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserToken];
        _userInfo =  (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserInfo]];
        #ifdef DEBUG_BACKEND
        _userToken = nil;
        #endif
        if (_userToken) {
            _authenticated = YES;
        }
        [self establishObserversForNetworkEvents];
    }
    return self;
}

- (void)establishObserversForNetworkEvents
{
    //For network reachability change
    __weak DNServerInterface* block_self = self;
    [_reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Reachability changed to %ld (blocks)", status);
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWiFi:
            case AFNetworkReachabilityStatusReachableViaWWAN:
                DebugLog(@"GroupMe now reachable");
                [block_self authenticate];
                [block_self establishSockets];
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {//variable assignment not allowed inside switch without explicit scope
                DebugLog(@"Lost Connection to GroupMe");
                block_self.listening = NO;
                NSError *error = [[NSError alloc] initWithDomain:DNErrorDomain code:eNoNetworkConnectivityGeneral userInfo:@{NSLocalizedDescriptionKey: eNoNetworkConnectivityGeneralDesc}];
                [block_self.loginSheetController.mainWindowController presentError:error];
                break;
            }
            case AFNetworkReachabilityStatusUnknown:
            default:
                break;
        }
    }];
}

#pragma mark - Notification Processing

- (void)notifyMembersRemoveActionWithMemberName:(NSString*)name andGroupID:(NSString*)identifierGroupID
{
    NSDictionary *userInfo = @{k_name:name, k_group_id:identifierGroupID};
    [_notificationCenter postNotificationName:noteMembersRemove object:nil userInfo:userInfo];
}

- (void)notifyMembersAddActionWithMemberNames:(NSArray*)names andGroupID:(NSString*)identifierGroupID
{
    [self GroupsShow:identifierGroupID andCompleteBlock:^(NSDictionary *groupsShowData) {
        NSArray *allMembers = groupsShowData[@"members"];
        DebugLog(@"Got unfiltered members: %@", allMembers);
        //Filter only users with "nickname" in names array
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF[%@] IN %@)", @"nickname", names];
        NSArray *filteredMembers = [allMembers filteredArrayUsingPredicate:predicate];
        if ([names count] == [filteredMembers count]) {
            DebugLog(@"Newly added members: %@", filteredMembers);
            NSMutableArray *filteredConvertedMembers = [[NSMutableArray alloc] initWithCapacity:[filteredMembers count]];
            dispatch_queue_t serial_queue = dispatch_queue_create("com.dovizu.grouposx", DISPATCH_QUEUE_SERIAL);
            [filteredMembers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *convertedMember = [self convertRawDictionary:(NSDictionary*)obj];
                dispatch_async(serial_queue, ^{
                    [filteredConvertedMembers addObject:convertedMember];
                });
            }];
            NSDictionary *userInfo = @{k_members:filteredConvertedMembers, k_group_id:identifierGroupID};
            [_notificationCenter postNotificationName:noteMembersAdd object:nil userInfo:userInfo];
            DebugLog(@"Filtered newly added members: %@", filteredConvertedMembers);
        }else{
            DebugLog(@"Failed to obtain all the added members");
        }
    }];
}

- (void)notifyGroupAvatarChangeActionWithGroupID:(NSString*)identifierGroupID
{
    
}
- (void)notifyGroupNameChangeActionWithName:(NSString*)name GroupID:(NSString*)identifierGroupID
{
    
}
- (void)notifyGroupMemberNickNameChangeActionWithOldName:(NSString*)old newName:(NSString*)new
{
    
}
- (void)notifyMessageFromSelf:(NSDictionary*)messageDict
{
    
}
- (void)notifyMessageFromGeneric:(NSDictionary*)messageDict
{
    
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
    DebugLog(@"Reachability: %hhd", _reachabilityManager.reachable);
    if (!self.authenticated && _reachabilityManager.reachable) {
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
//        [[NSNotificationCenter defaultCenter] postNotificationName:noteFirstTimeLogon object:nil];
        
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

#pragma mark - Notification Reception (Web Sockets)

- (void)establishSockets
{
    if (self.authenticated && !self.listening && _reachabilityManager.reachable) {
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

//This is a giant router of raw messages, the type of message dictates the next method to call, or nothing at all
- (void)messageReceived:(NSDictionary*)messageDict channel:(NSString* __unused)channel
{
    DebugLog(@"%@", messageDict);
    DebugLogCD(@"Server received raw message:\n%@", messageDict[@"alert"]);
    
    return;
    
    NSDictionary *identifiersSubject    =   [messageDict objectForKey:@"subject"];
    NSString *identifierAlert           =   [messageDict objectForKey:@"alert"];
    NSString *identifierGroupID         =   [identifiersSubject objectForKey:@"group_id"];
    NSString *identifierName            =   [identifiersSubject objectForKey:@"name"];
    NSString *identifierUserID          =   [identifiersSubject objectForKey:@"user_id"];
    
    //SYSTEM MESSAGES
    if ([identifierName isEqualToString:@"GroupMe"] && [identifierUserID isEqualToString:@"0"]) {
        NSString *name = nil;
        if ((name = [self helpFindStringWithPattern:@"(?:.+) removed (.+) from the group" inString:identifierAlert])) {
            //GROUP MEMBER REMOVED
            [self notifyMembersRemoveActionWithMemberName:name andGroupID:identifierGroupID];
        }else if ((name = [self helpFindStringWithPattern:@"(?:.+) added (.+) to the group" inString:identifierAlert])) {
            //GROUP MEMBER ADDED

            [self notifyMembersAddActionWithMemberNames:@[name] andGroupID:identifierGroupID];
        }else if ((name = [self helpFindStringWithPattern:@"(?:.+) changed the group's name to (.+)" inString:identifierAlert])) {
            //GROUP NAME CHANGED
            [self notifyGroupNameChangeActionWithName:name GroupID:identifierGroupID];
        }else if ([identifierAlert rangeOfString:@"(?:.+) changed the group's avatar"].location != NSNotFound){
            //GROUP AVATAR CHANGED
            [self notifyGroupAvatarChangeActionWithGroupID:identifierGroupID];
        }else if ([identifierAlert rangeOfString:@" changed name to "].location != NSNotFound) {
            //GROUP MEMBER CHANGED NICKNAME
            NSString *oldName, *newName;
            NSError *error = nil;
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(.+) changed name to (.+)" options:0 error:&error];
            NSTextCheckingResult *regexResult = [regEx firstMatchInString:identifierAlert options:0 range:NSMakeRange(0, [identifierAlert length])];
            if ([regexResult numberOfRanges] == 3) {
                oldName = [identifierAlert substringWithRange:[regexResult rangeAtIndex:1]];
                newName = [identifierAlert substringWithRange:[regexResult rangeAtIndex:2]];
                [self notifyGroupMemberNickNameChangeActionWithOldName:oldName newName:newName];
            }else{
                DebugLog(@"Parsing %@ failed, Error: %@", identifierAlert, error);
            }
        }
    }
    //ALL MESSAGES
    if ([self isUser:identifierName]) {
        //OWNER MESSAGE
        [self notifyMessageFromSelf:messageDict[@"subject"]];
    }else{
        //GENERIC MESSAGE
        [self notifyMessageFromGeneric: messageDict[@"subject"]];
    }
}

- (void)connectedToServer {
    DebugLog(@"Push server connected");
}

- (void)disconnectedFromServer {
    DebugLog(@"Push server disconnected");
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


#pragma mark - HTTP Requests Methods (Low-Level)

//Users - me
//Response should be a dictionary
- (void)UsersGetInformationAndCompleteBlock:(void(^)(NSDictionary* userDict))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/users/me")
                      parameters:@{HTTPParamToken:_userToken}
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
perPageAndCompleteBlock:(void(^)(NSArray* groupArray))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/groups")
                      parameters:@{HTTPParamToken:_userToken,
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
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSArray* formerGroupArray))completeBlock
{
    [self.HTTPRequestManager GET:baseURLPlus(@"/groups/former")
                      parameters:@{HTTPParamToken:_userToken}
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completeBlock((NSArray*)responseObject[@"response"]);
                         }
                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             report_request_error;
                         }];
}

//Groups - Show
//Response should be a dictionary
- (void)GroupsShow:(NSString*)groupID
  andCompleteBlock:(void(^)(NSDictionary* groupDict))completeBlock
{
    [self.HTTPRequestManager GET:[NSString stringWithFormat:@"%@%@%@", DNRESTAPIBaseAddress, @"/groups/", groupID]
                      parameters:@{HTTPParamToken:_userToken,
                                   @"id":groupID}
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completeBlock((NSDictionary*)responseObject[@"response"]);
                         }
                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             report_request_error;
                         }];
}

//Groups - Create
//Response should be a dictionary
- (void)GroupsCreateName:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                share:(BOOL)allowShare
              andCompleteBlock:(void(^)(NSDictionary* createdGroupDict))completeBlock
{
    void (^createGroup)(NSString*) = ^void(NSString* imageURL){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:name forKey:@"name"];
        [params setObject:_userToken forKey:HTTPParamToken];
        if (description)    {[params setObject:description forKey:@"description"];}
        if (imageURL)       {[params setObject:imageURL forKey:@"image_url"];}
        if (allowShare)     {[params setObject:@"true" forKey:@"share"];}
        [_HTTPRequestManager POST:baseURLPlus(@"/groups")
                       parameters:params
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              completeBlock((NSDictionary*)responseObject[@"response"]);
                          }
                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              report_request_error;
                          }];

    };
    if (image) {
        [self helpAsyncUploadImageToGroupMe:image usingBlock:^(NSString *imageURL) {
            createGroup(imageURL);
        }];
    }else{
        createGroup(nil);
    }
}

//Groups - Update
//Response should be a dictionary
- (void)GroupsUpdate:(NSString*)groupID
            withName:(NSString*)name
         description:(NSString*)description
               image:(id)image
             orShare:(BOOL)allowShare
    andCompleteBlock:(void(^)(NSDictionary* updatedGroupDict))completeBlock
{
    void (^updateGroup)(NSString*) = ^void(NSString* imageURL){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:_userToken forKey:HTTPParamToken];
        if (name)           {[params setObject:name forKey:@"name"];}
        if (description)    {[params setObject:description forKey:@"description"];}
        if (allowShare)     {[params setObject:@"true" forKey:@"share"];}else{[params setObject:@"false" forKey:@"share"];}
        if (imageURL)       {[params setObject:imageURL forKey:@"image"];}
        //"baseURL/groups/group_id/update"
        [_HTTPRequestManager POST:[NSString stringWithFormat:@"%@/%@%@", baseURLPlus(@"/groups"), groupID, @"/update"]
                       parameters:params
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              completeBlock((NSDictionary*)responseObject[@"response"]);
                          }
                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              report_request_error;
                          }];
    };
    if (image) {
        [self helpAsyncUploadImageToGroupMe:image usingBlock:^(NSString *imageURL) {
            updateGroup(imageURL);
        }];
    }else{
        updateGroup(nil);
    }
}

//Groups - Destroy
//Response should be a status
- (void)GroupsDestroy:(NSString*)groupID andCompleteBlock:(void(^)(NSString* deleted_group_id))completeBlock
{
    [_HTTPRequestManager POST:baseURLPlus(concatStrings(@"/groups/%@/destroy", groupID))
                   parameters:@{HTTPParamToken: _userToken}
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          NSLog(@"Group %@ deleted", groupID);
                          completeBlock(groupID);
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          //Do not expect a response but does check statusCode
                          if ([[operation response] statusCode] / 100 == 2) {
                              completeBlock(groupID);
                          }else{
                              report_request_error;
                          }
                      }];
}

//Image Service
//Response should be a string of URL
- (void)helpAsyncUploadImageToGroupMe:(id)image usingBlock:(void(^)(NSString* imageURL))completeBlock
{
    NSString *imageURL = nil;
    if (image) {
        //upload image here
    }
    completeBlock(imageURL);
}

#pragma mark - Helper Methods for Notification Processing

- (void)requestNextGroupsWithNewestResult:(NSArray*)newestResult completionBlock:(void(^)(NSArray* groupList))block
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
            block(groupList);
        });
        _currentlyPollingForGroups = NO;
        _prevResults = nil;
        return;
    }
    
    DebugLogCD(@"Group Polling page: %d", (int)_currentPageNum);
    NSInteger num = 50; //Poll as many as possible at once to avoid repeated polling recursion
#ifdef DEBUG_BACKEND
    num = 1; //Small to see if repeated polling works or not
#endif
    
    [self GroupsIndexPage:_currentPageNum with:num perPageAndCompleteBlock:^(NSArray *groupsIndexData) {
        [self requestNextGroupsWithNewestResult:groupsIndexData completionBlock:block];
    }];
}

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
            //is an image, either in message, or in an attachment, or user
        }else if ([strKey isEqualToString:@"image_url"] || ([strKey isEqualToString:@"url"] && [oldDict[@"type"] isEqualToString:@"image"])){
            NSURL *imageUrl = [NSURL URLWithString:strObj];
            NSImage *image = nil;
            if (imageUrl) {
                NSData *imageData = [NSData dataWithContentsOfURL:imageUrl];
                if (imageData) {
                    image = [[NSImage alloc] initWithData:imageData];
                }
            }
            if (!image) {
                [newDict setObject:[NSNull null] forKey:k_image];
            }else{
                [newDict setObject:image forKey:k_image];
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


#pragma mark - Helper Methods
- (NSString*)helpFindStringWithPattern:(NSString*)regExPattern inString:(NSString*)string
{
    NSError *error = nil;
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:regExPattern options:0 error:&error];
    if (!regEx) {
        DebugLog(@"Regular expression error: %@ on pattern %@", error, regExPattern);
        return nil;
    }
    NSTextCheckingResult *result = [regEx firstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
    if (result) {
        NSRange range = [result rangeAtIndex:1];
        return [string substringWithRange:range];
    }else{
        DebugLog(@"Parsing %@ with pattern %@ failed, Error: %@", string, regExPattern, error);
        return nil;
    }
}

@end