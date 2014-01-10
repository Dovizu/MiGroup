//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FayeClient.h>
#import "NSURL+NXOAuth2.h"

@class DNRESTAPI;
@class DNLoginSheetController;
@class DNMainWindowController;

#ifdef DEBUG_BACKEND
@class DNAsynchronousUnitTesting;
#endif

@interface DNServerInterface : NSObject <FayeClientDelegate>

@property DNLoginSheetController *loginSheetController;
@property DNMainWindowController *mainWindowController;

- (id)init;
- (void)setup;
- (void)teardown;
- (void)didReceiveURL:(NSString*)urlString;

#pragma mark - GroupMe Interface
//Messages
- (void)sendNewMessage:(NSString*)message
               toGroup:(NSString*)groupID
       withAttachments:(NSArray*)attachments;
//Post noteMessage notification on success, extract from userInfo:
//k_text, k_target_group, k_creator_message, k_created_at

- (void)fetch20MessagesBeforeMessageID:(NSString*)beforeID
                               inGroup:(NSString*)groupID;
//Post noteMessageBeforeFetch, extract from userInfo:
//k_messages, an array of messages

- (void)fetch20MostRecentMessagesSinceMessageID:(NSString*)sinceID
                                        inGroup:(NSString*)groupID;
//Post noteMessageSinceFetch, extract from userInfo:
//k_messages, an array of messages, k_group_id

//Members
- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID;
//Post noteMembersAdd, extract from userInfo:
//k_members, an array of members, k_group_id
- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID;
//Post noteMembersRemove, extract from userInfo:
//k_name_member, k_group_id


//Groups
- (void)fetchAllGroups;
//Post noteAllGroupsFetch, extrac from userInfo:
//k_fetched_groups, an array of groups
- (void)fetchFormerGroups;
//Post noteFormerGroupsFetch, extrac from userInfo:
//k_fetched_groups, an array of groups
- (void)fetchInformationForGroup:(NSString*)groupID;
//Post noteGroupInfoFetch, extract from userInfo:
//k_fetched_group
- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare;
//Post noteGroupCreate, extract from userInfo:
//k_group
- (void)updateGroup:(NSString*)groupID
           withName:(NSString*)name
        description:(NSString*)description
              image:(id)image
           andShare:(BOOL)allowShare;
//Post noteGroupUpdate, extract from userInfo:
//k_group
- (void)deleteGroup:(NSString*)groupID;
//Post noteGroupRemove, extract from userInfo:
//k_group_id

//Other notifications this class posts

//noteMemberNameChange
//k_name_member, k_new_name, k_group_id

//noteGroupAvatarChange
//k_image, k_group_id

//noteGroupNameChange
//k_name_group, k_group_id



@end


