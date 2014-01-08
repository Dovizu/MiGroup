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


@end


@implementation DNServerInterface
{
    //Modules
    AFNetworkReachabilityManager *_reachabilityManager;
    AFHTTPRequestOperationManager *_HTTPRequestManager;
    FayeClient *_socketClient;
    NSNotificationCenter *_notificationCenter;
    
    //Book keeping
    NSMutableSet *_recentGUIDs;
    NSString* _userToken;
    NSDictionary *_userInfo;
    
    //State variables
    BOOL _authenticating;
    BOOL _authenticated;
    BOOL _listening;
    
    //Used by -(void)requestNextGroupsWithNewestResult:newestResult completionBlock:block
    NSInteger _currentPageNum;
    NSMutableArray *_prevResults;
    BOOL _currentlyPollingForGroups;
    
}

#pragma mark - Initialization Logic

- (id)init
{
    self = [super init];
    if (self){
        //Modules
        _HTTPRequestManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:DNRESTAPIBaseAddress]];
        NSMutableSet *acceptableTypes = [NSMutableSet setWithSet:_HTTPRequestManager.responseSerializer.acceptableContentTypes];
        [acceptableTypes addObject:@"text/html"];
        _HTTPRequestManager.responseSerializer.acceptableContentTypes = [NSSet setWithSet:acceptableTypes];
        _reachabilityManager = [_HTTPRequestManager reachabilityManager];
        //FayeClient initialization needs to wait for userInformation to be populated or (void)setup to be called
        _notificationCenter = [NSNotificationCenter defaultCenter];
        
        //Book keeping
        _userToken = [[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserToken];
        _userInfo = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserInfo]];
        _recentGUIDs = [[NSMutableSet alloc] init];

        #ifdef DEBUG_BACKEND
        _userToken = nil; //force re-authenticate
        #endif
        
        if (_userToken) {
            _authenticated = YES;
        }
        
        //For network reachability change
        __weak DNServerInterface* block_self = self;
        BOOL *_listening_pointer = &_listening;
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
                    *_listening_pointer = NO;
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
    return self;
}

#pragma mark - User Actions

//Messages
- (void)sendNewMessage:(NSString*)message
               toGroup:(NSString*)groupID
       withAttachments:(NSArray*)attachments
{
    
}

- (void)fetch20MessagesBeforeMessageID:(NSString*)beforeID
                               inGroup:(NSString*)groupID
{
    
}

- (void)fetch20MostRecentMessagesSinceMessageID:(NSString*)sinceID
                                        inGroup:(NSString*)groupID
{
    
}

//Members
- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID
{
    
}

//relies on result fetching for comeback update
- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID
{
    
}
//relies on Message Router for comeback update

- (void)fetchAllGroups
{
    [self helpRequestNextGroupsWithNewestResult:nil completionBlock:^(NSArray *groupList) {
        [_notificationCenter postNotificationName:noteAllGroupsFetch object:nil userInfo:@{kGetContentKey: groupList}];
    }];
}


- (void)fetchFormerGroups
{
    
}

- (void)fetchInformationForGroup:(NSString*)groupID
{
    
}

- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare
{
    
}

- (void)updateGroup:(NSString*)groupID
           withName:(NSString*)name
        description:(NSString*)description
              image:(id)image
           andShare:(BOOL)allowShare
{
    
}

- (void)deleteGroup:(NSString*)groupID
{
    
}


- (void)helpRequestNextGroupsWithNewestResult:(NSArray*)newestResult completionBlock:(void(^)(NSArray* groupList))block
{
    NSAssert(block, @"completion block cannot be nil");
    
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
        dispatch_queue_t queue = dispatch_queue_create("com.dovizu.grouposx.groupProcessing", 0ul);
        dispatch_async(queue, ^{
            NSMutableArray *groupList = [[NSMutableArray alloc] initWithCapacity:[rawGroupList count]];
            [rawGroupList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *group = (NSDictionary*)obj;
                group = [self helpConvertRawDictionary:group];
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
        [self helpRequestNextGroupsWithNewestResult:groupsIndexData completionBlock:block];
    }];
}

- (NSDate *)helpConvertToDateFromStringOfSeconds:(NSString *)secondsString
{
    NSDate *date = nil;
    NSRegularExpression *dateRegEx = nil;
    dateRegEx = [[NSRegularExpression alloc] initWithPattern:@"^(-?\\d+)(?:([+-])(\\d{2})(\\d{2}))?$"
                                                     options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *regexResult = [dateRegEx firstMatchInString:secondsString
                                                              options:0
                                                                range:NSMakeRange(0, [secondsString length])];
    if (regexResult) {
        //Milliseconds to seconds
        NSTimeInterval seconds = [[secondsString substringWithRange:[regexResult rangeAtIndex:1]] doubleValue];
        //Timezone offset
        if ([regexResult rangeAtIndex:2].location != NSNotFound) {
            //Offset sign
            NSString *sign = [secondsString substringWithRange:[regexResult rangeAtIndex:2]];
            //Offset hours
            seconds += [[NSString stringWithFormat:@"%@%@", sign, [secondsString substringWithRange:[regexResult rangeAtIndex:3]]] doubleValue] * 60.0 * 60.0;
            //Offset minutes
            seconds += [[NSString stringWithFormat:@"%@%@", sign, [secondsString substringWithRange:[regexResult rangeAtIndex:4]]] doubleValue] * 60.0;
        }
        date = [NSDate dateWithTimeIntervalSince1970:seconds];
    }else{
        //                DebugLog(@"Date parsing on incoming message failed: %@", oldDict);
        //If GroupMe sends an ill-formatted date, you can only hope the next update will correct it
        date = [NSDate date];
    }
    return date;
}

//Convert a JSON-serialized crappy Dictionary into one with Cocoa objects
- (NSDictionary*)helpConvertRawDictionary:(NSDictionary*)oldDict
{
    NSMutableDictionary *newDict = [oldDict mutableCopy];
    [oldDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL __unused *stop) {
        NSString *strKey = [NSString stringWithFormat:@"%@", key];
        NSString *strObj = [NSString stringWithFormat:@"%@", obj];
        
        //is a date, GroupMe uses "dddddd" seconds after 1970
        if ([strKey isEqualToString:@"created_at"] || [strKey isEqualToString:@"updated_at"]) {
            [newDict setObject:[self helpConvertToDateFromStringOfSeconds:strObj] forKey:strKey];
        }
        //is an image, either in message, or in an attachment, or user
        else if ([strKey isEqualToString:@"image_url"] || ([strKey isEqualToString:@"url"] && [oldDict[@"type"] isEqualToString:@"image"])){
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
        }
        //is generic url (as in the case of "share_url")
        else if ([strKey hasSuffix:@"url"]){
            NSURL *url = [NSURL URLWithString:strObj];
            if (url) {
                [newDict setObject:url forKey:strKey];
            }else{
                [newDict setObject:[NSNull null] forKey:strKey];
            }
        }
        //is boolean
        else if ([strObj isEqualToString:@"false"] || [strObj isEqualToString:@"true"]){
            BOOL value = [strObj isEqualToString:@"true"];
            [newDict setObject:[NSNumber numberWithBool:value] forKey:strKey];
        }
        //all other cases, leave as is
    }];
    return newDict;
}

#pragma mark - Notification Processing

- (void)messageCentralRouter:(NSDictionary *)messageDict
{
    DebugLog(@"%@", messageDict);
    DebugLogCD(@"Server received raw message:\n%@", messageDict[@"alert"]);
    
    NSDictionary *identifiersSubject    =   [messageDict objectForKey:@"subject"];
    NSString *identifierAlert           =   [messageDict objectForKey:@"alert"];
    NSString *identifierGroupID         =   [identifiersSubject objectForKey:@"group_id"];
    NSString *identifierName            =   [identifiersSubject objectForKey:@"name"];
    NSString *identifierUserID          =   [identifiersSubject objectForKey:@"user_id"];
    NSString *identifierGUID            =   [identifiersSubject objectForKey:@"source_guid"];
    
    //SYSTEM MESSAGES
    if ([identifierName isEqualToString:@"GroupMe"] && [identifierUserID isEqualToString:@"0"]) {
        NSString *name = nil;
        //GROUP MEMBER REMOVED
        if ((name = [self helpFindStringWithPattern:@"(?:.+) removed (.+) from the group" inString:identifierAlert])) {
            NSDictionary *userInfo = @{k_name:name, k_group_id:identifierGroupID}; //name is unique in a group, will be able to identify
            [_notificationCenter postNotificationName:noteMembersRemove object:nil userInfo:userInfo];
        }
        //GROUP MEMBER ADDED
        else if ((name = [self helpFindStringWithPattern:@"(?:.+) added (.+) to the group" inString:identifierAlert])) {
            //Because there is currently no way to identify whether the members are added by the user or another member in the GroupMe notifications, we have to get the names out of the alert and blindly fetch a list of members and compare in the background. If the action is generated by the user, then those users would have already been in the database. (*This class is only responsible for fetching a list of members and submit via Notification Center)
            NSArray *names = [self helpFindNamesInStringOfNames:name];
            if ([names count] == 0) {
                DebugLog(@"Failed to find any names in alert string");
            }
            [self GroupsShow:identifierGroupID andCompleteBlock:^(NSDictionary *groupDict) {
                NSArray *allMembers = groupDict[@"members"];
                //Filter only users with "nickname" in names array
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF[%@] IN %@)", @"nickname", names];
                NSArray *newMembers = [allMembers filteredArrayUsingPredicate:predicate];
                if ([names count] != [newMembers count]) {
                    DebugLog(@"Failed to obtain all the added members, will add the found ones anyway");
                }else if ([newMembers count] == 0){
                    DebugLog(@"Failed to obtain any added members");
                }
                NSMutableArray *newMembersWithImages = [[NSMutableArray alloc] initWithCapacity:[newMembers count]];
                dispatch_queue_t serial_queue = dispatch_queue_create("com.dovizu.grouposx.imageProcessing", DISPATCH_QUEUE_SERIAL);
                [newMembers enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger __unused idx, __unused BOOL *stop) {
                    NSMutableDictionary *convertedMember = [(NSDictionary*)obj mutableCopy];
                    [convertedMember setObject:convertedMember[@"nickname"] forKey:k_name];
                    [convertedMember setObject:convertedMember[@"id"] forKey:k_membership_id];
                    [self helpAsyncDownloadImage:convertedMember[@"image_url"] usingBlock:^(NSImage *image) {
                        if (image) {
                            [convertedMember setObject:image forKey:@"image"];
                        }
                        dispatch_async(serial_queue, ^{
                            [newMembersWithImages addObject:convertedMember];
                        });
                    }];
                }];
                
                NSDictionary *userInfo = @{k_members:newMembersWithImages, k_group_id:identifierGroupID};
                [_notificationCenter postNotificationName:noteMembersAdd object:nil userInfo:userInfo];
                DebugLog(@"Filtered newly added members: %@", newMembersWithImages);
            }];
        }
        //GROUP NAME CHANGED
        else if ((name = [self helpFindStringWithPattern:@"(?:.+) changed the group's name to (.+)" inString:identifierAlert])) {
            [_notificationCenter postNotificationName:noteGroupNameChange
                                               object:nil
                                             userInfo:@{k_name: name,
                                                        k_group_id: identifierGroupID}];
        }
        //GROUP AVATAR CHANGED
        else if ([identifierAlert rangeOfString:@"(?:.+) changed the group's avatar"].location != NSNotFound){
            [self GroupsShow:identifierGroupID andCompleteBlock:^(NSDictionary *groupDict) {
                if (groupDict[@"image_url"] != [NSNull null]) {
                    [self helpAsyncDownloadImage:groupDict[@"image_url"] usingBlock:^(NSImage *image) {
                        if (image) {
                            [_notificationCenter postNotificationName:noteGroupAvatarChange
                                                               object:nil
                                                             userInfo:@{k_image: image,
                                                                        k_group_id: identifierGroupID}];
                        }
                    }];
                }
            }];
        }
        //GROUP MEMBER CHANGED NICKNAME
        else if ([identifierAlert rangeOfString:@" changed name to "].location != NSNotFound) {
            NSString *oldName, *newName;
            NSError *error = nil;
            NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"(.+) changed name to (.+)" options:0 error:&error];
            NSTextCheckingResult *regexResult = [regEx firstMatchInString:identifierAlert options:0 range:NSMakeRange(0, [identifierAlert length])];
            if ([regexResult numberOfRanges] == 3) {
                oldName = [identifierAlert substringWithRange:[regexResult rangeAtIndex:1]];
                newName = [identifierAlert substringWithRange:[regexResult rangeAtIndex:2]];
                [_notificationCenter postNotificationName:noteMemberNameChange
                                                   object:nil
                                                 userInfo:@{k_name: oldName,
                                                            k_new_name: newName,
                                                            k_group_id: identifierGroupID}];
            }else{
                DebugLog(@"Parsing %@ failed, Error: %@", identifierAlert, error);
            }
        }
    }
    
    //MESSAGES BY USER
    else if (identifierGUID && [_recentGUIDs containsObject:identifierGUID]) {
        DebugLog(@"Received duplicate message: '%@'", identifierAlert);
    }
    //MESSAGES BY ANOTHER MEMBER
    else{
        NSMutableDictionary *message = [identifiersSubject mutableCopy];
        message[@"message_id"] = messageDict[@"id"];
        //No attachment support yet
        [_notificationCenter postNotificationName:noteMessage
                                           object:nil
                                         userInfo:@{k_message: message}];
    }
}

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
    }
    return nil;
}

- (NSArray*)helpFindNamesInStringOfNames:(NSString*)string
{
    string = [string stringByReplacingOccurrencesOfString:@"\\s*(?:(?:and|,)\\s*)+"
                                             withString:@","
                                                options:NSRegularExpressionSearch
                                                  range:(NSRange){0, [string length]}];
    return [string componentsSeparatedByString:@","];
}

#pragma mark - Authentication/Token Retrieval

//The almighty setup always makes sure everything is set up
- (void)setup
{
    if (!_authenticated) {
        [self authenticate];
    }else if(!_listening){
        [self establishMessageSocket];
    }
}

- (void)authenticate
{
    DebugLog(@"Reachability: %hhd", _reachabilityManager.reachable);
    if (!_authenticating && !_authenticated && _reachabilityManager.reachable) {
        _authenticating = YES;
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
    _userToken = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DNUserDefaultsUserToken];
    _userInfo = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:DNUserDefaultsUserInfo];
    _authenticated = NO;
    
    [_socketClient disconnectFromServer];
    _listening = NO;
        
    [self authenticate];
}

- (void)didReceiveURL:(NSURL*)url
{
    DebugLog(@"Server received URL: %@", [url absoluteString]);
    NSString *token = [url nxoauth2_valueForQueryParameterKey:@"access_token"];
    
    if (token) {
        _authenticated = YES;
        [self.loginSheetController closeLoginSheet];
        DebugLog(@"Server successfully authenticated with token: %@", token);
        _userToken = token;
        [[NSUserDefaults standardUserDefaults] setObject:_userToken forKey:DNUserDefaultsUserToken];
        _authenticating = NO;
        #ifdef DEBUG_BACKEND
        [DNAsynchronousUnitTesting testAllAsynchronousUnits:self];
        [DNAsynchronousUnitTesting testAllSockets:self];
        #endif
        
        //First time log-on
        [[NSNotificationCenter defaultCenter] postNotificationName:noteFirstTimeLogon object:nil];
        
        [self UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
            _userInfo = userInfo;
            NSData *userInfoData = [NSKeyedArchiver archivedDataWithRootObject:userInfo];
            [[NSUserDefaults standardUserDefaults] setObject:userInfoData forKey:DNUserDefaultsUserInfo];
            DebugLog(@"UserInformation Changed: %@", _userInfo);
            [self establishSockets];
        }];
        
    }else{
        DebugLog(@"Server failed to retrieve token, authentication restart...");
        _authenticated = NO; //just to be sure
        [self.loginSheetController closeLoginSheet];
        [self authenticate]; //do it again
    }
}

- (BOOL)isLoggedIn
{
    return _authenticated;
}

- (BOOL)isListening
{
    return _listening;
}

- (BOOL)isUser:(NSString*)name
{
    return _authenticated && [_userInfo[@"name"] isEqualToString:name];
}

#pragma mark - Web Socket

- (void)establishSockets
{
    if (_authenticated && !_listening && _reachabilityManager.reachable) {
        [self establishMessageSocket];
    }
}

//One message socket is needed for the entire application
- (void)establishMessageSocket
{
    _socketClient = [[FayeClient alloc] initWithURLString:@"https://push.groupme.com/faye"
                                         channel:[NSString stringWithFormat:@"/user/%@",_userInfo[@"id"]]];
    _socketClient.delegate = self;
    NSDictionary *externalInformation = @{@"access_token":_userToken,
                                          @"timestamp":[[NSDate date] description]};
    [_socketClient connectToServerWithExt:externalInformation];
}




- (void)messageReceived:(NSDictionary*)messageDict channel:(NSString* __unused)channel
{
    [self messageCentralRouter:messageDict];
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
    _listening = YES;
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
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:@"users/me"
                      parameters:@{@"token":_userToken}
                         success:^(AFHTTPRequestOperation *operation, id responseObject){
                             completeBlock((NSDictionary*)responseObject[@"response"]);
                         }
                         failure:^(AFHTTPRequestOperation *operation, NSError *error){
                             report_request_error;
                             completeBlock(nil);
                         }];
}

//Groups - Index
//Response should be an array of dictionaries
- (void)GroupsIndexPage:(NSInteger)nthPage
                   with:(NSInteger)groups
perPageAndCompleteBlock:(void(^)(NSArray* groupArray))completeBlock
{
    NSAssert(nthPage, @"nthPage param cannot be nil");
    NSAssert(groups, @"groups param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:@"groups"
                      parameters:@{@"token":_userToken,
                                   @"page":NSNumber(nthPage),
                                   @"per_page":NSNumber(groups)}
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completeBlock((NSArray*)responseObject[@"response"]);
                         }
                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             report_request_error;
                             completeBlock(nil);
                         }];
}

//Groups - Former
//Response should be an array of dictionaries
- (void)GroupsFormerAndCompleteBlock:(void(^)(NSArray* formerGroupArray))completeBlock
{
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:@"groups/former"
                      parameters:@{@"token":_userToken}
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completeBlock((NSArray*)responseObject[@"response"]);
                         }
                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             report_request_error;
                             completeBlock(nil);
                         }];
}

//Groups - Show
//Response should be a dictionary
- (void)GroupsShow:(NSString*)groupID
  andCompleteBlock:(void(^)(NSDictionary* groupDict))completeBlock
{
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager GET:concatStrings(@"groups/%@", groupID)
                      parameters:@{@"token":_userToken,
                                   @"id":groupID}
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             completeBlock((NSDictionary*)responseObject[@"response"]);
                         }
                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             report_request_error;
                             completeBlock(nil);
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
    NSAssert(name, @"name param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    void (^createGroup)(NSString*) = ^void(NSString* imageURL){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:name          forKey:@"name"];
        [params setObject:_userToken    forKey:@"token"];
        if (description)    {[params setObject:description  forKey:@"description"];}
        if (imageURL)       {[params setObject:imageURL     forKey:@"image_url"];}
        if (allowShare)     {[params setObject:@"true"      forKey:@"share"];}
        [_HTTPRequestManager POST:@"groups"
                       parameters:params
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              completeBlock((NSDictionary*)responseObject[@"response"]);
                          }
                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              report_request_error;
                              completeBlock(nil);
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
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    void (^updateGroup)(NSString*) = ^void(NSString* imageURL){
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:_userToken forKey:@"token"];
        if (name)           {[params setObject:name forKey:@"name"];}
        if (description)    {[params setObject:description forKey:@"description"];}
        if (allowShare)     {[params setObject:@"true" forKey:@"share"];}else{[params setObject:@"false" forKey:@"share"];}
        if (imageURL)       {[params setObject:imageURL forKey:@"image"];}
        //"baseURL/groups/group_id/update"
        [_HTTPRequestManager POST:concatStrings(@"groups/%@/update", groupID)
                       parameters:params
                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                              completeBlock((NSDictionary*)responseObject[@"response"]);
                          }
                          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                              report_request_error;
                              completeBlock(nil);
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
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/destroy", groupID)
                   parameters:@{@"token": _userToken}
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          completeBlock(groupID);
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          //Do not expect a response but does check statusCode
                          if ([[operation response] statusCode] / 100 == 2) {
                              completeBlock(groupID);
                              completeBlock(nil);
                          }else{
                              report_request_error;
                          }
                      }];
}

//Members - Add
//Response should be a dictionary
- (void)MembersAdd:(NSArray*)members toGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* addedMembers))completeBlock
{
    NSAssert((members), @"members param cannot be nil");
    NSAssert([members count], @"members param cannot be empty array");
    NSAssert([members[0] isKindOfClass:[NSDictionary class]], @"members param does not contain dictionaries");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    [members enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id obj, NSUInteger __unused idx, BOOL __unused *stop) {
        NSDictionary *member = (NSDictionary*)obj;
        NSAssert(member[@"nickname"], @"One or more users don't have a valid nickname");
    }];
    
    NSDictionary *userInfo = @{@"members": members,
                               @"token": _userToken};
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/members/add", groupID)
                   parameters:userInfo
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          [self MembersResults:((NSDictionary*)responseObject)[@"response"][@"results_id"]
                                       inGroup:groupID
                              andCompleteBlock:completeBlock
                                       attempt:1];
                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          report_request_error;
                      }];
}

//Members - Remove
//Response should be the removed member's membership ID
- (void)MembersRemoveUser:(NSString*)membershipID
            fromGroup:(NSString*)groupID
     andCompleteBlock:(void(^)(NSString* removedMembershipID))completeBlock
{
    NSAssert(membershipID, @"membershipID param cannot be nil");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    NSDictionary *params = @{@"token": _userToken};
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/members/%@/remove", groupID, membershipID)
                   parameters:params
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                           completeBlock(membershipID);
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          report_request_error;
                          completeBlock(nil);
                      }];
}

//Members - Results
//Response should be an array
- (void)MembersResults:(NSString*)resultsID
               inGroup:(NSString*)groupID
      andCompleteBlock:(void(^)(NSArray* addedMembers))completeBlock
               attempt:(NSInteger)nthAttempt
{
    NSAssert(resultsID, @"resultsID param cannot be nil");
    NSAssert(completeBlock, @"completeBlock cannot be nil");
    NSAssert(nthAttempt, @"nthAttempt cannot be nil or 0");
    if (nthAttempt > 10) {
        DebugLog(@"Error fetching results for newly added members");
        completeBlock(nil);
        return;
    }
    
    NSDictionary *params = @{@"token": _userToken,
                            @"results_id": resultsID};
    [_HTTPRequestManager GET:concatStrings(@"groups/%@/members/results/%@", groupID, resultsID)
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock(((NSDictionary*)responseObject)[@"response"][@"members"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         dispatch_queue_t queue = dispatch_queue_create("com.dovizu.grouposx.resultsFetching", DISPATCH_QUEUE_CONCURRENT);
                         dispatch_async(queue, ^{
                             NSLog(@"%@", [NSThread currentThread]);
                             usleep(1000000); //wait for 1 second and try again
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self MembersResults:resultsID
                                              inGroup:groupID
                                     andCompleteBlock:completeBlock
                                              attempt:nthAttempt+1];
                             });
                         });
                     }];
}

//Messages - Index Before
//Response should be a dictionary
- (void)MessagesIndex20BeforeID:(NSString*)beforeID inGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* messages))completeBlock
{
    NSAssert(beforeID, @"beforeID param cannot be nil");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    NSDictionary *params = @{@"token":    _userToken,
                             @"before_id": beforeID};
    [_HTTPRequestManager GET:concatStrings(@"groups/%@/messages", groupID)
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         completeBlock(((NSDictionary*)responseObject)[@"messages"]);
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Messages - Index Since
//Response should be a dictionary
- (void)MessagesIndexMostRecent20SinceID:(NSString*)sinceID inGroup:(NSString*)groupID andCompleteBlock:(void(^)(NSArray* messages))completeBlock
{
    NSAssert(sinceID, @"sinceID cannot be nil");
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    
    NSDictionary *params = @{@"token":    _userToken,
                             @"since_id": sinceID};
    [_HTTPRequestManager GET:concatStrings(@"groups/%@/messages", groupID)
                  parameters:params
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         if (completeBlock) {
                             completeBlock(((NSDictionary*)responseObject)[@"messages"]);
                         }
                     }
                     failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         report_request_error;
                         completeBlock(nil);
                     }];
}

//Messages - Create
//Response should be a dictionary
- (void)MessagesCreateInGroup:(NSString*)groupID
                         text:(NSString*)text
                  attachments:(NSArray*)arrayOfAttach
             andCompleteBlock:(void(^)(NSDictionary* sentMessage))completeBlock
{
    NSAssert(groupID, @"groupID param cannot be nil");
    NSAssert(text, @"text param cannot be nil");
    NSAssert(completeBlock, @"completion block cannot be nil");
    

    arrayOfAttach = nil; //Not releasing this feature yet
    if (arrayOfAttach){
        NSMutableArray *convertedAttachments = [[NSMutableArray alloc] initWithCapacity:[arrayOfAttach count]];
        
        //The block that processes an attachment
        void (^processAttachment)(NSDictionary*) = ^void(NSDictionary* attachment){
            if ([attachment[@"type"]  isEqual: @"image"]) {
                //do something about the image, check its validity
            }else if ([attachment[@"type"] isEqualToString:@"location"]){
                //do something about location, check its validity
            }else if ([attachment[@"type"] isEqualToString:@"split"]){
                //do something about the split, check its validity
            }else if ([attachment[@"type"] isEqualToString:@"emoji"]){
                //do something about this emoji, check its validity
            }
        };
        
        [arrayOfAttach enumerateObjectsWithOptions:NSEnumerationConcurrent
                                        usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                            processAttachment((NSDictionary*)obj);
                                        }];
        arrayOfAttach = convertedAttachments;
    }
    NSDictionary *params = @{@"source_guid": @"source_guid_here",
                             @"text": text};
    [_HTTPRequestManager POST:concatStrings(@"groups/%@/messages", groupID)
                   parameters:params
                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                          completeBlock((NSDictionary*)responseObject[@"message"]);
                      }
                      failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                          report_request_error;
                          completeBlock(nil);
                      }];
}

//Image Service
//Response should be a string of URL, nil if upload failed
- (void)helpAsyncUploadImageToGroupMe:(id)image usingBlock:(void(^)(NSString* imageURL))completeBlock
{
    NSAssert(image, @"Image cannot be nil");
    NSString *imageURL = nil;
    //upload image
    completeBlock(imageURL);
}

//Image Service
//Response should be NSImage, nil if download failed
- (void)helpAsyncDownloadImage:(NSString*)imageURL usingBlock:(void(^)(NSImage* image))completeBlock
{
    NSAssert(imageURL, @"Image URL cannot be nil");
    
    id image = nil;
    //download image here
    completeBlock(image);
}

#pragma mark - Helper Methods for Notification Processing






@end