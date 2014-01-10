//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"
#import "DNRESTAPI.h"
#import "DNLoginSheetController.h"
#import "DNMainWindowController.h"

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
        
        _notificationCenter = [NSNotificationCenter defaultCenter];
        
        //Book keeping
        _userToken = [[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserToken];
        _userInfo = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:DNUserDefaultsUserInfo]];
        _recentGUIDs = [[NSMutableSet alloc] init];

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
        if (_userToken) {
            _authenticated = YES;
            [API setUserToken:_userToken];
        }
    }
    return self;
}

#pragma mark - User Actions

//Messages
- (void)sendNewMessage:(NSString*)message
               toGroup:(NSString*)groupID
       withAttachments:(NSArray*)attachments
{
    [API MessagesCreateInGroup:groupID
                          text:message
                   attachments:nil
              andCompleteBlock:^(NSDictionary *sentMessage) {
                  [_notificationCenter postNotificationName:noteNewMessage
                                                     object:nil
                                                   userInfo:[self helpConvertRawDictionary:sentMessage
                                                                                    ofType:DNMessageJSONDictionary]];
              }];
    
}

- (void)fetch20MessagesBeforeMessageID:(NSString*)beforeID
                               inGroup:(NSString*)groupID
{
    [API MessagesIndex20BeforeID:beforeID
                         inGroup:groupID
                andCompleteBlock:^(NSArray *messages) {
                    NSMutableArray *messagesConverted = [[NSMutableArray alloc] initWithCapacity:[messages count]];
                    for (NSDictionary* msg in messages) {
                        [messagesConverted addObject:[self helpConvertRawDictionary:msg ofType:DNMessageJSONDictionary]];
                    }
                    [_notificationCenter postNotificationName:noteMessagesBeforeFetch
                                                       object:nil userInfo:@{k_messages: messagesConverted}];
                }];
}

- (void)fetch20MostRecentMessagesSinceMessageID:(NSString*)sinceID
                                        inGroup:(NSString*)groupID
{
    [API MessagesIndexMostRecent20SinceID:sinceID
                                  inGroup:groupID
                         andCompleteBlock:^(NSArray *messages) {
                             NSMutableArray *messagesConverted = [[NSMutableArray alloc] initWithCapacity:[messages count]];
                             for (NSDictionary* msg in messages) {
                                 [messagesConverted addObject:[self helpConvertRawDictionary:msg ofType:DNMessageJSONDictionary]];
                             }
                             [_notificationCenter postNotificationName:noteMessagesSinceFetch
                                                                object:nil userInfo:@{k_messages: messagesConverted}];
                         }];
}

//Members
- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID
{
    [API MembersAdd:members toGroup:groupID
   andCompleteBlock:^(NSArray *addedMembers) {
       //Do nothing because Central Message Router will take care of this comeback notification
   }];
}

//relies on result fetching for comeback update
- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID
{
    [API MembersRemoveUser:membershipID
                 fromGroup:groupID
          andCompleteBlock:^(NSString *removedMembershipID) {
              //Do nothing because Central Message Router will take care of this comeback notification
          }];
}
//relies on Message Router for comeback update

- (void)fetchAllGroups
{
    [self helpRequestNextGroupsWithNewestResult:nil completionBlock:^(NSArray *groupList) {
        [_notificationCenter postNotificationName:noteGroupsAllFetch
                                           object:nil
                                         userInfo:@{k_fetched_groups: groupList}];
    }];
}


- (void)fetchFormerGroups
{
    [API GroupsFormerAndCompleteBlock:^(NSArray *formerGroupArray) {
        NSMutableArray *formerGroupsConverted = [[NSMutableArray alloc] initWithCapacity:[formerGroupArray count]];
        for (NSDictionary* formerGroup in formerGroupArray) {
            [formerGroupsConverted addObject:[self helpConvertRawDictionary:formerGroup ofType:DNGroupJSONDictionary]];
        }
        [_notificationCenter postNotificationName:noteGroupsFormerFetch
                                           object:nil
                                         userInfo:@{k_fetched_groups: formerGroupsConverted}];
    }];
}

- (void)fetchInformationForGroup:(NSString*)groupID
{
    [API GroupsShow:groupID
   andCompleteBlock:^(NSDictionary *groupDict) {
       [_notificationCenter postNotificationName:noteGroupInfoFetch
                                          object:nil
                                        userInfo:@{k_fetched_group: [self helpConvertRawDictionary:groupDict
                                                                                            ofType:DNGroupJSONDictionary]}];
   }];
}

- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare
{
    [API GroupsCreateName:name
              description:description
                    image:image
                    share:allowShare
         andCompleteBlock:^(NSDictionary *createdGroupDict) {
             [_notificationCenter postNotificationName:noteGroupCreate
                                                object:nil
                                              userInfo:@{k_group: [self helpConvertRawDictionary:createdGroupDict
                                                                                          ofType:DNGroupJSONDictionary]}];
         }];
}

- (void)updateGroup:(NSString*)groupID
           withName:(NSString*)name
        description:(NSString*)description
              image:(id)image
           andShare:(BOOL)allowShare
{
    [API GroupsUpdate:groupID
             withName:name
          description:description
                image:image
              orShare:allowShare
     andCompleteBlock:^(NSDictionary *updatedGroupDict) {
         [_notificationCenter postNotificationName:noteGroupUpdate
                                            object:nil
                                          userInfo:@{k_group: [self helpConvertRawDictionary:updatedGroupDict
                                                                                      ofType:DNGroupJSONDictionary]}];
     }];
}

- (void)deleteGroup:(NSString*)groupID
{
    [API GroupsDestroy:groupID
      andCompleteBlock:^(NSString *deleted_group_id) {
          [_notificationCenter postNotificationName:noteGroupRemove
                                             object:nil
                                           userInfo:@{k_group_id: deleted_group_id}];
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

    switch (type) {
        case DNGroupJSONDictionary:{
            
            newDict[k_image] = ifThen(oldDict[k_image], [self helpURLFromString:oldDict[k_image]]);
            newDict[k_updated_at] = ifThen(oldDict[k_updated_at], [self helpConvertToDateFromSeconds:oldDict[k_updated_at]]);
            newDict[k_share_url] = ifThen(oldDict[k_share_url], [self helpURLFromString:oldDict[k_share_url]]);
            newDict[k_created_at] = ifThen(oldDict[k_created_at], [self helpConvertToDateFromSeconds:oldDict[k_created_at]]);
            if (oldDict[k_members]) {
                NSMutableArray *convertedMembers = [[NSMutableArray alloc] initWithCapacity:[oldDict[k_members] count]];
                for (NSDictionary* member in oldDict[k_members]) {
                    [convertedMembers addObject:[self helpConvertRawDictionary:member ofType:DNMemberJSONDictionary]];
                }
                newDict[k_members] = convertedMembers;
            }
            break;
        }
        case DNMemberJSONDictionary:{
            newDict[k_image] = ifThen(oldDict[k_image], [self helpURLFromString:oldDict[k_image]]);
            break;
        }
        case DNMessageJSONDictionary:{
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
    else if (identifierGUID && [_recentGUIDs containsObject:identifierGUID]) {
        DebugLog(@"Received duplicate message: '%@'", identifierAlert);
    }
    //MESSAGES BY ANOTHER MEMBER
    else{
        //No attachment support yet
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
        [API setUserToken:token];
        [[NSUserDefaults standardUserDefaults] setObject:_userToken forKey:DNUserDefaultsUserToken];
        _authenticating = NO;
        #ifdef DEBUG_BACKEND
        [DNAsynchronousUnitTesting testAllAsynchronousUnits:self];
        [DNAsynchronousUnitTesting testAllSockets:self];
        #endif
        
        //First time log-on
        [[NSNotificationCenter defaultCenter] postNotificationName:noteFirstTimeLogon object:nil];
        
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

@end