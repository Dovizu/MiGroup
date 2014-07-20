//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"
#import "DNRESTAPI.h"
#import "DNDataManager.h"
#import "DNMainController.h"

#ifdef DEBUG_BACKEND
#import "DNAsynchronousUnitTesting.h"
#endif

#define baseURLPlus(string) [NSString stringWithFormat:@"%@%@", DNRESTAPIBaseAddress, string]
#define token_pair @"token":_userToken
#define report_request_error DebugLog(@"%s: %@",__PRETTY_FUNCTION__, error)
#define get_response(responseObject) (NSDictionary*)responseObject[@"response"]

enum DNJSONDictionaryType {
    DNMemberJSONDictionary,
    DNGroupJSONDictionary,
    DNMessageJSONDictionary,
    DNAttachmentJSONDictionary
    };

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
    DNRESTAPI *API;
    FayeClient *_socketClient;
    NSNotificationCenter *_notificationCenter;
    DNDataManager *_dataManager;
    
    //Book keeping
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

- (id)initWithDataManager: (DNDataManager*) dataManager
{
    self = [super init];
    if (self){
        
        _dataManager = dataManager;
        _notificationCenter = [NSNotificationCenter defaultCenter];
        __block NSNotificationCenter *blockNoteCenter = _notificationCenter;
        
        //Book keeping
        _userToken = [[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserToken];
        _userInfo = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserInfo]];

        #ifdef DEBUG_BACKEND
        _userToken = nil; //force re-authenticate
        #endif
        
        //API Setup
        API = [[DNRESTAPI alloc] init];
        __weak DNServerInterface* block_self = self;
        BOOL *_listening_pointer = &_listening;
        [API setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            NSLog(@"Reachability changed to %ld (blocks)", status);
            switch (status) {
                case AFNetworkReachabilityStatusReachableViaWiFi:
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    DebugLog(@"GroupMe now reachable");
                    [block_self authenticate];
                    [block_self establishSockets];
                    [blockNoteCenter postNotificationName:noteOnline object:nil];
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                {//variable assignment not allowed inside switch without explicit scope
                    DebugLog(@"Lost Connection to GroupMe");
                    *_listening_pointer = NO;
                    NSError *error = [[NSError alloc] initWithDomain:DNErrorDomain code:eNoNetworkConnectivityGeneral userInfo:@{NSLocalizedDescriptionKey: eNoNetworkConnectivityGeneralDesc}];
                    [block_self.mainWindowController presentError:error];
                    [blockNoteCenter postNotificationName:noteOffline object:nil];
                    break;
                }
                case AFNetworkReachabilityStatusUnknown:
                default:
                    break;
            }
        }];
        if (_userToken) {
            _authenticated = YES;
            [API setUserToken:_userToken];
        }
    }
    return self;
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
    DebugLog(@"Reachability: %hhd", [API isReachable]);
    if (!_authenticating && !_authenticated && [API isReachable]) {
//        _authenticating = YES;
        NSDictionary *parameters = @{@"client_id": DNOAuth2ClientID};
        NSURL *preparedAuthorizationURL = [[NSURL URLWithString:DNOAuth2AuthorizationURL] nxoauth2_URLByAddingParameters:parameters];
        DebugLog(@"Server is authenticating at %@", [preparedAuthorizationURL absoluteString]);
        [self.mainWindowController promptForLoginWithPreparedURL:preparedAuthorizationURL];
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
        [self.mainWindowController closeLoginSheet];
        DebugLog(@"Server successfully authenticated with token: %@", token);
        _userToken = token;
        [API setUserToken:token];
        [[NSUserDefaults standardUserDefaults] setObject:_userToken forKey:DNUserDefaultsUserToken];
        _authenticating = NO;
        #ifdef DEBUG_BACKEND
        [DNAsynchronousUnitTesting testAllAsynchronousUnits:self];
        [DNAsynchronousUnitTesting testAllSockets:self];
        #endif
        
        //First time log-on
        [_dataManager firstTimeLogonSetup];
        
        [API UsersGetInformationAndCompleteBlock:^(NSDictionary *userInfo) {
            _userInfo = userInfo;
            NSData *userInfoData = [NSKeyedArchiver archivedDataWithRootObject:userInfo];
            [[NSUserDefaults standardUserDefaults] setObject:userInfoData forKey:DNUserDefaultsUserInfo];
            DebugLog(@"UserInformation Changed: %@", _userInfo);
            [self establishSockets];
        }];
        
    }else{
        DebugLog(@"Server failed to retrieve token, authentication restart...");
        _authenticated = NO; //just to be sure
        [self.mainWindowController closeLoginSheet];
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

- (BOOL)isUser:(NSString*)userID
{
    return _authenticated && [_userInfo[@"user_id"] isEqualToString:userID];
}

#pragma mark - Web Socket

- (void)establishSockets
{
    if (_authenticated && !_listening && [API isReachable]) {
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

//messages from another user
- (void)messageReceived:(NSDictionary*)messageDict channel:(NSString* __unused)channel
{
    //When another client subscribes to user's account, it will receive a "type = subscribe" message
    if (![messageDict[@"type"] isEqualToString:@"subscribe"]) {
        [self messageCentralRouter:messageDict];
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
    _listening = YES;
//    [self addNewMembers:@[@{k_name_member:@"kha", k_user_id:@"11201736"}] toGroup:@"6736514"];
//    [self removeMember:@"35121596" fromGroup:@"6736514"];
//    [self fetchAllGroups];
//    [self fetch20MessagesBeforeMessageID:@"138923697178086374" inGroup:@"4011747"];
//    [self fetch20MostRecentMessagesSinceMessageID:@"138913977064154353" inGroup:@"4011747"];
#ifdef DEBUG_CORE_DATA
    [_notificationCenter postNotificationName:noteFirstTimeLogon object:nil];
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
            NSDictionary *userInfo = @{k_name_of_member:name, k_group_id:identifierGroupID}; //name is unique in a group, will be able to identify
            //still need to tell DataManager to remove the group member from Core Data
            [_notificationCenter postNotificationName:noteMemberRemove object:nil userInfo:userInfo];
        }
        //GROUP MEMBER ADDED
        else if ((name = [self helpFindStringWithPattern:@"(?:.+) added (.+) to the group" inString:identifierAlert])) {
            //Because there is currently no way to identify whether the members are added by the user or another member in the GroupMe notifications, we have to get the names out of the alert and blindly fetch a list of members and compare in the background. If the action is generated by the user, then those users would have already been in the database. (*This class is only responsible for fetching a list of members and submit via Notification Center)
            NSArray *names = [self helpFindNamesInStringOfNames:name];
            if ([names count] == 0) {
                DebugLog(@"Failed to find any names in alert string");
            }
            [API GroupsShow:identifierGroupID andCompleteBlock:^(NSDictionary *groupDict) {
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
                [newMembers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSDictionary *member = (NSDictionary*)obj;
                    NSDictionary *convertedMember = @{k_name_of_member:    member[k_name_of_member],
                                                      k_membership_id:  member[k_membership_id],
                                                      k_image:          [self helpURLFromString:member[k_image]],
                                                      k_user_id:        member[k_user_id],
                                                      k_muted:          member[k_muted]};
                    [newMembersWithImages addObject:convertedMember];
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
                                             userInfo:@{k_name_of_group: name,
                                                        k_group_id: identifierGroupID}];
        }
        //GROUP AVATAR CHANGED
        else if ([identifierAlert rangeOfString:@"changed the group's avatar"].location != NSNotFound){
            [API GroupsShow:identifierGroupID andCompleteBlock:^(NSDictionary *groupDict) {
                [_notificationCenter postNotificationName:noteGroupAvatarChange
                                                   object:nil
                                                 userInfo:@{k_image: [self helpURLFromString:groupDict[@"image_url"]],
                                                            k_group_id: identifierGroupID}];
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
                                                 userInfo:@{k_name_of_member: oldName,
                                                            k_new_name: newName,
                                                            k_group_id: identifierGroupID}];
            }else{
                DebugLog(@"Parsing %@ failed, Error: %@", identifierAlert, error);
            }
        }
        
    }
    
    //MESSAGES BY USER
    else if (identifierGUID && [API hasGUID:identifierGUID]) {
        DebugLog(@"Received duplicate message: '%@'", identifierAlert);
    }
    //LIKE  BY ANOTHER USER
    else if ([identifierAlert rangeOfString:@"liked your message"].location != NSNotFound) {
        return;
    }
    //MESSAGES BY ANOTHER MEMBER
    else{
        NSString* lastMessageID = [_dataManager getLastMessageIDForGroupID:identifierGroupID];
        [self fetch20MostRecentMessagesSinceMessageID:lastMessageID inGroup:identifierGroupID];
        [_notificationCenter postNotificationName:noteNewMessage
                                           object:nil
                                         userInfo:[self helpConvertRawDictionary:identifiersSubject
                                                                          ofType:DNMessageJSONDictionary]];
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


#pragma mark - User Actions

- (void)sendNewMessage:(NSString*)message
               toGroup:(NSString*)groupID
       withAttachments:(NSArray*)attachments {
    if (attachments) {
        for (NSDictionary* attachment in attachments) {
            //if ([attachment[k_attachment_type] isEqualToString:k_attach_type_image])
            // construct attachment dictionary with groupme format in server interface instead of data manager
            if ([attachment[@"type"]  isEqualToString: @"image"]) {
                NSString *urlString = [(NSURL*)attachment[@"url"] absoluteString];
                NSString *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:urlString];  //NSHomeDirectory() may not be necessary when getting file path from user interface
                [API uploadImage:imagePath withBlock:^(NSDictionary *response) {
                    if (response) {
                        NSString* imageURL = response[@"payload"][@"url"];
                        DebugLog(@"imageURL from server interface: %@", imageURL);
                        NSDictionary* imageAttachment = @{@"type":@"image", @"url":imageURL};
                        NSArray* imageAttachArray = [NSArray arrayWithObject:imageAttachment];
                        [API MessagesCreateInGroup:groupID
                                              text:message
                                       attachments: imageAttachArray
                                  andCompleteBlock:^(NSDictionary *sentMessage) {
                                      if (sentMessage) {
                                          sentMessage = [self helpConvertRawDictionary:sentMessage ofType:DNMessageJSONDictionary];
                                          NSArray* messages =[NSArray arrayWithObject:sentMessage];
                                          [_dataManager didReceiveMessages:messages forGroup:groupID];
                                      } else {
                                          DebugLog(@"Failed to send message: %@", message);
                                      }
                                  }];
                    } else {
                        DebugLog(@"Failed to upload image: %@", urlString);
                    }
                    
                }];
            }
        }
    } else {
        [API MessagesCreateInGroup:groupID
                              text:message
                       attachments: attachments
                  andCompleteBlock:^(NSDictionary *sentMessage) {
                      if (sentMessage) {
                          sentMessage = [self helpConvertRawDictionary:sentMessage ofType:DNMessageJSONDictionary];
                          NSArray* messages =[NSArray arrayWithObject:sentMessage];
                          [_dataManager didReceiveMessages:messages forGroup:groupID];
                      } else {
                          DebugLog(@"Failed to send message: %@", message);
                      }
                  }];
    }
}

- (void)fetch20MessagesBeforeMessageID:(NSString*)beforeID
                               inGroup:(NSString*)groupID {
    [API MessagesIndex20BeforeID:beforeID
                         inGroup:groupID
                andCompleteBlock:^(NSArray *messages) {
                    NSMutableArray *messagesConverted = [[NSMutableArray alloc] initWithCapacity:[messages count]];
                    for (NSDictionary* msg in messages) {
                        [messagesConverted addObject:[self helpConvertRawDictionary:msg
                                                                             ofType:DNMessageJSONDictionary]];
                    }
                    [_dataManager didReceiveMessages:messagesConverted forGroup:groupID];
                }];

    
}

- (void)fetch20MostRecentMessagesSinceMessageID:(NSString*)sinceID
                                        inGroup:(NSString*)groupID {
    [API MessagesIndexMostRecent20SinceID:sinceID
                                  inGroup:groupID
                         andCompleteBlock:^(NSArray *messages) {
                             NSMutableArray *messagesConverted = [[NSMutableArray alloc] initWithCapacity:[messages count]];
                             for (NSDictionary* msg in messages) {
                                 [messagesConverted addObject:[self helpConvertRawDictionary:msg
                                                                             ofType:DNMessageJSONDictionary]];
                            }
                             [_dataManager didReceiveMessages:messagesConverted forGroup:groupID];
                         }];

}

- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID {
    [API MembersAdd:members
            toGroup:groupID
   andCompleteBlock:^(NSArray *addedMembers) {
       [_dataManager didUpdateMembers:addedMembers forGroup:groupID];
   }];
}


- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID {
    [API MembersRemoveUser:membershipID
                 fromGroup:groupID
          andCompleteBlock:^(NSString* removeMembbershipID) {
              [_dataManager didRemoveMember:membershipID fromGroup:groupID];
        }];
}


- (void)fetchAllGroups {
    [self helpRequestNextGroupsWithNewestResult:nil completionBlock:^(NSArray *groupList) {
        [_dataManager didFetchAllGroups:groupList];
    }];
}


- (void)fetchFormerGroups {
    [API GroupsFormerAndCompleteBlock:^(NSArray *formerGroupArray) {
        NSMutableArray *formerGroupsConverted = [[NSMutableArray alloc] initWithCapacity:[formerGroupArray count]];
        for (NSDictionary* formerGroup in formerGroupArray) {
            [formerGroupsConverted addObject:[self helpConvertRawDictionary:formerGroup
                                                                     ofType:DNGroupJSONDictionary]];
        }
        [_dataManager didFetchFormerGroups:formerGroupsConverted];
    }];
}


- (void)fetchInformationForGroup:(NSString*)groupID {
    [API GroupsShow:groupID
   andCompleteBlock:^(NSDictionary *groupDict) {
       NSDictionary* convertedDict = [self helpConvertRawDictionary:groupDict
                                                             ofType:DNGroupJSONDictionary];
       [_dataManager didFetchInformationForGroup:convertedDict];
   }];
}

- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare {
    [API GroupsCreateName:name
              description:description
                    image:image
                    share:allowShare
         andCompleteBlock:^(NSDictionary *createdGroupDict) {
             NSDictionary* convertedDict = [self helpConvertRawDictionary:createdGroupDict
                                                                  ofType:DNGroupJSONDictionary];
             [_dataManager didCreateGroup: convertedDict];
         }];
}


- (void)updateGroup:(NSString*)groupID
           withName:(NSString*)name
        description:(NSString*)description
              image:(id)image
           andShare:(BOOL)allowShare {
    [API GroupsUpdate:groupID
             withName:name
          description:description
                image:image
              orShare:allowShare
     andCompleteBlock:^(NSDictionary *updatedGroupDict) {
         NSDictionary* convertedDict = [self helpConvertRawDictionary:updatedGroupDict
                                                               ofType:DNGroupJSONDictionary];
         [_dataManager didUpdateGroup:convertedDict];
     }];
}


- (void)deleteGroup:(NSString*)groupID {
    [API GroupsDestroy:groupID
      andCompleteBlock:^(NSString *deleted_group_id) {
          [_dataManager didDeleteGroup:deleted_group_id];
      }];
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
                group = [self helpConvertRawDictionary:group ofType:DNGroupJSONDictionary];
                [groupList addObject:group];
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(groupList);
            });
        });
        _currentlyPollingForGroups = NO;
        _prevResults = nil;
        return;
    }
    
    DebugLog(@"Group Polling page: %d", (int)_currentPageNum);
    NSInteger num = 50; //Poll as many as possible at once to avoid repeated polling recursion
#ifdef DEBUG_BACKEND
    num = 1; //Small to see if repeated polling works or not
#endif
    
    [API GroupsIndexPage:_currentPageNum with:num perPageAndCompleteBlock:^(NSArray *groupsIndexData) {
        [self helpRequestNextGroupsWithNewestResult:groupsIndexData completionBlock:block];
    }];
}


- (NSDate*)helpConvertToDateFromSeconds:(NSNumber*)seconds
{
    NSDate *date = nil;
    NSRegularExpression *dateRegEx = nil;
    NSString *secondsString = [NSString stringWithFormat:@"%@", seconds];
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

//returns NSURL if urlString is a valid URL string, NSNull otherwise
- (id)helpURLFromString:(NSString*)urlString
{
    NSAssert(urlString, @"urlString cannot be nil");
    NSURL *url;
    
    if (!([urlString isKindOfClass:[NSNull class]]) && (url = [NSURL URLWithString:urlString])) {
        return url;
    }
    
    return [NSNull null];
}

- (NSNumber*)helpBooleanFromWord:(NSString*)word
{
    NSAssert(word, @"word param cannot be nil");
    return [NSNumber numberWithBool:[word isEqualToString:@"true"]];
}

//Convert a JSON-serialized crappy Dictionary into one with Cocoa objects
- (NSDictionary*)helpConvertRawDictionary:(NSDictionary*)oldDict ofType:(enum DNJSONDictionaryType)type
{
    NSMutableDictionary *newDict = [oldDict mutableCopy];
#define ifThen(first, second) (first ? second : [NSNull null])
#define isNull(object) [object isKindOfClass: [NSNull class]]
#define newNull [NSNull null]
    
    switch (type) {
        case DNGroupJSONDictionary:{
            newDict[k_desc] = isNull(oldDict[k_desc]) ? @"" : oldDict[k_desc];
            newDict[k_image] = isNull(oldDict[k_image]) ? newNull : [self helpURLFromString:oldDict[k_image]];
            newDict[k_share_url] = oldDict[k_share_url] ? oldDict[k_share_url] : [self helpURLFromString:oldDict[k_share_url]];
            newDict[k_created_at] = [self helpConvertToDateFromSeconds:oldDict[k_created_at]];
            newDict[k_updated_at] = [self helpConvertToDateFromSeconds:oldDict[k_updated_at]];
            if (oldDict[k_members]) {
                NSMutableArray *convertedMembers = [[NSMutableArray alloc] initWithCapacity:[oldDict[k_members] count]];
                for (NSDictionary* member in oldDict[k_members]) {
                    [convertedMembers addObject:[self helpConvertRawDictionary:member ofType:DNMemberJSONDictionary]];
                }
                newDict[k_members] = convertedMembers;
            }
            //sometimes there is no last message for newly created group
            if (![oldDict[k_messages][@"preview"][@"nickname"] isKindOfClass:[NSNull class]]) {
                NSDictionary *lastMessage = @{k_message_id: oldDict[k_messages][@"last_message_id"],
                                              k_created_at: oldDict[k_messages][@"last_message_created_at"],
                                              k_sender_name: oldDict[k_messages][@"preview"][@"nickname"],
                                              k_sender_avatar: oldDict[k_messages][@"preview"][@"image_url"],
                                              k_text: oldDict[k_messages][@"preview"][@"text"],
                                              k_attachments: oldDict[k_messages][@"preview"][k_attachments]};
                lastMessage = [self helpConvertRawDictionary:lastMessage ofType:DNMessageJSONDictionary];
                newDict[k_last_message] = lastMessage;
            }else{
                newDict[k_last_message] = [NSNull null];
            }
            break;
        }
        case DNMemberJSONDictionary:{
            newDict[k_image] = isNull(oldDict[k_image]) ? newNull : [self helpURLFromString:oldDict[k_image]];
            break;
        }
        case DNMessageJSONDictionary:{
            
            newDict[k_created_at] = [self helpConvertToDateFromSeconds:oldDict[k_created_at]];
            newDict[k_sender_avatar] = [self helpURLFromString:oldDict[k_sender_avatar]];
            if (oldDict[k_attachments]) {
                NSMutableArray *convertedAttachments = [[NSMutableArray alloc] initWithCapacity:[oldDict[k_attachments] count]];
                for (NSDictionary* attachment in oldDict[k_attachments]) {
                    [convertedAttachments addObject:[self helpConvertRawDictionary:attachment ofType:DNAttachmentJSONDictionary]];
                }
                newDict[k_attachments] = convertedAttachments;
            }
            break;
        }
        case DNAttachmentJSONDictionary:{
            newDict[k_url] = ifThen(oldDict[k_url], [self helpURLFromString:oldDict[k_url]]);
            break;
        }
        default:
            break;
    }
    return newDict;
}




@end