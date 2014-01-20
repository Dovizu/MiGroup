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

@class DNDataManager, DNMainController, DNLoginSheetController, DNRESTAPI;

#ifdef DEBUG_BACKEND
@class DNAsynchronousUnitTesting;
#endif

@interface DNServerInterface : NSObject <FayeClientDelegate>

@property DNLoginSheetController *loginSheetController;
@property DNMainController *mainWindowController;

- (id)init;
- (void)setup;
- (void)teardown;
- (void)didReceiveURL:(NSString*)urlString;

#pragma mark - GroupMe Interface

#pragma mark Messages
/**
 *  Send a new message
 *
 *  @param message     the pure text form of the message
 *  @param groupID     target group
 *  @param attachments an array of attachment, currently not supported
 *  @discussion on completion, posts "noteMessage" notificaiton, the userInfo contains:
 *      k_text, k_target_group, k_creator_message, k_created_at, k_message_id, k_sender_name, k_sender_avatar, k_sender_user_id
 */
- (void)sendNewMessage:(NSString*)message
               toGroup:(NSString*)groupID
       withAttachments:(NSArray*)attachments;

/**
 *  Fetch 20 Messages immediately before the message specified by beforeID
 *
 *  @param beforeID the message before which 20 earlier messages will be fetched
 *  @param groupID  target group
 *  @discussion on completion, posts "noteMessageBeforeFetch" notification, the userInfo contains:
 *      k_messages
 */
- (void)fetch20MessagesBeforeMessageID:(NSString*)beforeID
                               inGroup:(NSString*)groupID;

/**
 *  Fetch 20 _most recent_ messages since message specified by sinceID
 *
 *  @param sinceID the message after which most recent 20 messages will be fetched
 *  @param groupID target group
 *  @discussion on completion, posts "noteMessageSinceFetch" notification, the userInfo contains:
 *      k_messages
 *      Each message has the same keys as noteMessage's userInfo
 */
- (void)fetch20MostRecentMessagesSinceMessageID:(NSString*)sinceID
                                        inGroup:(NSString*)groupID;

#pragma mark Members

/**
 *  Add a new member
 *
 *  @param members an NSArray of member dictionaries to be added
 *  @param groupID target group
 *  @discussion On completion, posts "noteMembersAdd" notification, the userInfo contains:
 *      k_members, k_group_id
 */
- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID;

/**
 *  Remove a member from a group
 *
 *  @param membershipID the membership_id of the user
 *  @param groupID      target group
 *  @warning    membership_id is not user_id, a user may have multiple membership_id's but only a single user_id
 *  @discussion On completion, posts "noteMembersRemove" notification, the userInfo contains:
 *      k_name_member, k_group_id
 */
- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID;

#pragma mark Groups

/**
 *  Fetch all the groups the user is in
 *  @discussion On completion, posts "noteAllGroupsFetch", the userInfo contains:
 *      k_fetched_groups
 */
- (void)fetchAllGroups;

/**
 *  Fetch all the former groups the user was in, but can rejoin
 *  @discussion On completion, posts "noteFormerGroupsFetch", the userInfo contains:
 *      k_fetched_groups
 */
- (void)fetchFormerGroups;

/**
 *  Fetch information for a specific group
 *
 *  @param groupID target group
 *  @discussion On completion, posts "noteGroupInfoFetch", the userInfo contains:
 *      k_fetched_group
 */
- (void)fetchInformationForGroup:(NSString*)groupID;

/**
 *  Create a group with given parameters
 *
 *  @param name        (required) the name of the group
 *  @param description (optional) the description of the group
 *  @param image       (optional) the ________ of the image
 *  @param allowShare  (optional) whether the group can be shared via a share_url
 *  @discussion On completion, posts "noteGroupCreate", the userInfo contains:
 *      k_group (dictionary with the newly created group information)
 */
- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare;

/**
 *  Update a group with given information
 *
 *  @param groupID     (required) the ID of the group to be updated
 *  @param name        (optional) new name
 *  @param description (optional) new description
 *  @param image       (optional) ______ of new image
 *  @param allowShare  (optional) new boolean value for whether the group can be shared via a share_url
 *  @discussion On completion, posts "noteGroupUpdate", the userInfo contains:
 *      k_group (dictionary with updated information)
 */
- (void)updateGroup:(NSString*)groupID
           withName:(NSString*)name
        description:(NSString*)description
              image:(id)image
           andShare:(BOOL)allowShare;

/**
 *  Delete a group
 *
 *  @param groupID the group to be deleted
 *  @discussion On Completion, posts "noteGroupRemove", the userInfo contains:
 *      k_group_id (the id of the group removed)
 */
- (void)deleteGroup:(NSString*)groupID;


//Other notifications this class posts

//noteMemberNameChange
//k_name_member, k_new_name, k_group_id

//noteGroupAvatarChange
//k_image, k_group_id

//noteGroupNameChange
//k_name_group, k_group_id

- (BOOL)isUser:(NSString*)name;

@end


