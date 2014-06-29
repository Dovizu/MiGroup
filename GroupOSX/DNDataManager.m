//
//  DNDataManager.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNDataManager.h"
#import "DNServerInterface.h"
#import "DNAppDelegate.h"
#import "DNMainController.h"

@interface DNDataManager ()
@end

@implementation DNDataManager
{
    AFHTTPRequestOperationManager *_requestManager;
    AFNetworkReachabilityManager *_reachability;
    BOOL _firstLogonSuppressNotification;
    NSInteger _countUntilReleaseNotification;
    DNServerInterface* _server;
}

#pragma mark - Initialization
- (id)init
{
    self = [super init];
    if (self) {
        NSLog(@"Init called");
        _requestManager = [AFHTTPRequestOperationManager manager];
        _reachability = [_requestManager reachabilityManager];
        _requestManager.responseSerializer = [[AFImageResponseSerializer alloc] init];
    }
    return self;
}

#pragma mark - Convenience Methods
- (BOOL)isUser:(NSString *)userID
{
    return userID ? [_server isUser:userID] : NO;
}

#pragma mark - Actions

- (void)logOut
{
    NSHTTPCookieStorage *jar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [jar cookies]) {
        [jar deleteCookie:cookie];
    }
    [_server teardown];
}
- (void)signIn
{
    [_server setup];
}

- (void)sendNewMessage:(NSString*)text toGroup:(NSString*)groupID withAttachments:(NSArray*)attachments
{
    /**
     *  In future releases, this section is supposed to process attachments and replace text emoji's.
     */
    NSAssert(text && groupID, @"Message text or group cannot be nil");
    [_server sendNewMessage:text toGroup:groupID withAttachments:nil];
}

#pragma mark - Data Management

// called by ServerInterface in didReceiveURL
- (void)firstTimeLogonSetup
{
    [_server fetchAllGroups];
    _firstLogonSuppressNotification = YES;
}

- (void)addNewMembers:(NSArray*)members
              toGroup:(NSString*)groupID {
    [_server addNewMembers:members toGroup:groupID];
}

- (void)removeMember:(NSString*)membershipID
           fromGroup:(NSString*)groupID {
    //remember to first update CoreData
    [_server removeMember:membershipID fromGroup:groupID];
}

- (void)changeGroupAvatar:(id)image forGroup: (NSString*)groupID {
    // fetch name, description, and allowShare from CoreData
    NSString* name;
    NSString* description;
    BOOL allowShare = 0;
    [_server updateGroup:groupID withName:name description:description image:image andShare:allowShare];
    
}

- (void)changeGroupName:(NSString*)name forGroup:(NSString *)groupID {
    // fetch description, image, and allowShare from CoreData
    NSString* description;
    id image = nil;
    BOOL allowShare = 0;
    [_server updateGroup:groupID withName:name description:description image:image andShare:allowShare];
}

- (void)createGroupNamed:(NSString*)name
             description:(NSString*)description
                   image:(id)image
                andShare:(BOOL)allowShare {
    
    [_server createGroupNamed:name
                  description:description
                        image:image
                     andShare:allowShare];
}

- (void)deleteGroup:(NSString*)groupID {
    [_server deleteGroup:groupID];
}

- (void)fetchAllGroups {
    [_server fetchAllGroups];
}

- (void)fetchFormerGroups {
    [_server fetchFormerGroups];
}

#pragma mark methods called by DNServerInterface

- (void)didFetchAllGroups:(NSArray*)groups {
    //update CoreData with groups
    if (_firstLogonSuppressNotification) _countUntilReleaseNotification = [groups count];
    for (NSDictionary *fetchedGroup in groups) {
        [self helpProcessGroup:fetchedGroup];
    }
}

- (void)didFetchFormerGroups:(NSArray*)groups {
    //needs to be implemented
}


- (void)didReceiveMessages:(NSArray*)messages forGroup:(NSString *)groupID{
    //update CoreData with messages. only add the new messages.
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *dbGroup = [Group findFirstByAttribute:@"group_id" withValue:groupID inContext:currentContext];
    [self helpProcessMessages:messages toGroup:dbGroup.objectID];
}

//should handle added and updated members
- (void)didUpdateMembers: (NSArray*)members forGroup: (NSString*)groupID {
    //update CoreData with members. should handle adding and updating members
}


- (void)didUpdateGroup:(NSDictionary*)group {
    // update this group in CoreData
}

- (void) didFetchInformationForGroup:(NSDictionary*)group {
    
}

- (void)didRemoveMember:(NSString *)membershipID fromGroup:(NSString *)groupID {
    
}



- (void)didCreateGroup:(NSDictionary*)createdGroup {
    [self helpProcessGroup: createdGroup];
}

- (void)didDeleteGroup:(NSString*)groupID {
    
}

- (void)helpProcessGroup:(NSDictionary *)fetchedGroup
{
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *dbGroup = [Group findFirstByAttribute:@"group_id" withValue:fetchedGroup[k_group_id] inContext:currentContext];
    if (!dbGroup) {
        dbGroup = [Group createInContext:currentContext];
    }
    dbGroup.desc = fetchedGroup[k_desc];
    dbGroup.created_at = fetchedGroup[k_created_at];
    dbGroup.group_id = fetchedGroup[k_group_id];
    dbGroup.name = fetchedGroup[k_name_of_group];
    dbGroup.share_url = fetchedGroup[k_share_url];
    dbGroup.type = fetchedGroup[k_type_of_group];
    dbGroup.updated_at = fetchedGroup[k_updated_at];
    
    //Obtain group image
    BOOL hasNoImage = [fetchedGroup[k_image] isKindOfClass:[NSNull class]];
    BOOL hasUpdated = !hasNoImage && ![dbGroup.image.id_url isEqualToString:[fetchedGroup[k_image] absoluteString]];
    if (hasNoImage || !dbGroup.image) {
        dbGroup.image = [Image createInContext:currentContext];
    }
    if (hasUpdated) {
        dbGroup.image.id_url = [fetchedGroup[k_image] absoluteString];
        [_requestManager GET:[[fetchedGroup[k_image] absoluteString] stringByAppendingString:@".preview"]
                  parameters:nil
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         NSImage *image = (NSImage*)responseObject;
                         dbGroup.image.preview = image;
                         [currentContext saveOnlySelfAndWait];
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         DebugLogCD(@"Failed to obtain image for group: %@, error:\n%@", dbGroup.name, error);
                     }];
    }
    //sometimes, last message doesn't exit in a newly created group
    if (![fetchedGroup[k_last_message] isKindOfClass:[NSNull class]]) {
        [self helpProcessMessages:@[fetchedGroup[k_last_message]] toGroup:dbGroup.objectID];
        /* Special case for last message processing, since this invokes "helpProcessMessages:toGroup: but does not count as
         the end of processing this group*/
        _countUntilReleaseNotification += 1;
        [_server fetch20MessagesBeforeMessageID:fetchedGroup[k_last_message][k_message_id] inGroup:dbGroup.group_id];
    }
    [self helpProcessMemberArray:fetchedGroup[k_members] intoGroup:dbGroup.objectID createdBy:fetchedGroup[k_creator_group]];
}

- (void)helpProcessMessages:(NSArray*)fetchedMessages toGroup:(NSManagedObjectID*)groupID;
{
    NSAssert(fetchedMessages, @"fetchedMessages must not be nil");
    NSAssert([fetchedMessages count] != 0, @"0-length messages array is passed in");
    NSAssert(groupID, @"groupID cannot be nil");
    
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *group = (Group*)[currentContext objectWithID:groupID];
    
    for (NSDictionary *fetchedMessage in fetchedMessages) {
        Message *dbMessage = [[group.messages filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"message_id == %@", fetchedMessage[k_message_id]]] anyObject];
        if (!dbMessage) {
            //New message
            dbMessage = [Message createInContext:currentContext];
            dbMessage.created_at = fetchedMessage[k_created_at];
            dbMessage.message_id = fetchedMessage[k_message_id];
            if ([fetchedMessage[k_sender_name] isKindOfClass:[NSNull class]]) {
                //break;
            }
            dbMessage.sender_name = fetchedMessage[k_sender_name];
            if (fetchedMessage[k_user_id]) {
                dbMessage.sender_user_id = fetchedMessage[k_user_id];
            }
            if ([fetchedMessage[k_text] isKindOfClass:[NSString class]]) {
                dbMessage.text = fetchedMessage[k_text];
            }
            dbMessage.target_group = group;
            dbMessage.system = fetchedMessage[k_is_system];
            [group addMessagesObject:dbMessage];
            if (!group.last_message || [group.last_message.created_at compare:dbMessage.created_at] == NSOrderedAscending) {
                group.last_message = dbMessage;
            }
            
            Image *avatar;
            BOOL hasImage = ![fetchedMessage[k_sender_avatar] isKindOfClass:[NSNull class]];
            if (hasImage) {
                avatar = [[Image findByAttribute:@"id_url" withValue:[fetchedMessage[k_sender_avatar] absoluteString] inContext:currentContext] firstObject];
                if (!avatar) {
                    avatar = [Image createInContext:currentContext];
                    avatar.id_url = [fetchedMessage[k_sender_avatar] absoluteString];
                    [_requestManager GET:[[fetchedMessage[k_sender_avatar] absoluteString] stringByAppendingString:@".avatar"]
                              parameters:nil
                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                     avatar.avatar = (NSImage*)responseObject;
                                     [currentContext saveOnlySelfAndWait];
                                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                     DebugLogCD(@"Failed to obtain image for message by: %@, error:\n%@", dbMessage.sender_name, error);
                                 }];
                }
                dbMessage.sender_avatar = avatar;
            }else{
                dbMessage.sender_avatar = [Image createInContext:currentContext];
            }
            
            if (!_firstLogonSuppressNotification) [_mainController notifyUserOfGroupMessage:dbMessage fromGroup:group];
            [self helpProcessAttachmentArray:fetchedMessage[k_attachments] inMessage:dbMessage.objectID];
        }
    }
    [currentContext saveToPersistentStoreAndWait];
    if (_firstLogonSuppressNotification) {
        _countUntilReleaseNotification -= 1;
        DebugLogCD(@"FirstLogonSuppressCount: %d", (int)_countUntilReleaseNotification);
        if (_countUntilReleaseNotification == 0) _firstLogonSuppressNotification = NO;
    }
}

//should handle added and updated members
- (void)helpProcessMemberArray:(NSArray*)members intoGroup:(NSManagedObjectID*)groupID createdBy:(NSString*)creator_user_id
{
    return; //this release does not support members
    
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *group = (Group*)[currentContext objectWithID:groupID];
    
    NSLog(@"group members count: %d", (int)[group.members count]);
    //Obtain all current members in membership_id-member pairs
    NSMutableDictionary *membersToProcess = [[NSMutableDictionary alloc] initWithCapacity:[group.members count]];
    for (Member *member in group.members) {
        membersToProcess[member.membership_id] = member;
    }
    
    //Update members or create new ones, updated members are removed from membersToProcess
    for (NSDictionary* fetchedMember in members) {
        Member *dbMember = membersToProcess[fetchedMember[k_membership_id]];
        if (!dbMember) {
            //Is new member
            dbMember = [Member createInContext:currentContext];
            dbMember.user_id = fetchedMember[k_user_id];
            dbMember.membership_id = fetchedMember[k_membership_id];
            dbMember.group = group;
            [group addMembersObject:dbMember];
        }else{
            //Is current member
            [membersToProcess removeObjectForKey:dbMember.membership_id];
        }
        //Update attributes for both new and current members
        //Obtain image asynchronously
        if (![fetchedMember[k_image] isKindOfClass:[NSNull class]]) {
            [_requestManager GET:[[fetchedMember[k_image] absoluteString] stringByAppendingString:@".avatar"]
                      parameters:nil
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             NSImage *image = (NSImage*)responseObject;
                             dbMember.image.avatar = image;
                             [currentContext saveOnlySelfAndWait];
                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             DebugLogCD(@"Failed to obtain image for member: %@, error:\n%@", dbMember.name, error);
                         }];
        }
        dbMember.name = fetchedMember[k_name_of_member];
        dbMember.muted = fetchedMember[k_muted];
        if ([fetchedMember[k_user_id] isEqualToString:creator_user_id]) {
            dbMember.is_creator = [NSNumber numberWithBool:YES];
            group.creator = dbMember;
        }
    }
    //Any remaining members in membersToProcess are to be deleted from the group
    [group removeMembers:[NSSet setWithArray:[membersToProcess allValues]]];
    
    [currentContext saveToPersistentStoreAndWait];
}

- (void)helpProcessAttachmentArray:(NSArray*)attachments inMessage:(NSManagedObjectID*)messageID
{
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Message *message = (Message*)[currentContext objectWithID:messageID];
    for (NSDictionary* attachment in attachments) {
        Attachment *newAttachment = [Attachment createInContext:currentContext];
        newAttachment.message = message;
        if ([attachment[k_attachment_type] isEqualToString:k_attach_type_image]) {
            newAttachment.type = k_attach_type_image;
            newAttachment.url = attachment[k_url];
        }else if ([attachment[k_attachment_type] isEqualToString:k_attach_type_location]){
            //feature not yet supported
        }else if ([attachment[k_attachment_type] isEqualToString:k_attach_type_emoji]){
            //feature not yet supported
        }else if ([attachment[k_attachment_type] isEqualToString:k_attach_type_split]){
            //feature not yet supported
        }
        [message addAttachmentsObject:newAttachment];
    }
    [currentContext saveToPersistentStoreAndWait];
}

- (NSString*)getLastMessageIDForGroupID:(NSString*) groupID {
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *dbGroup = [Group findFirstByAttribute:@"group_id" withValue:groupID inContext:currentContext];
    return dbGroup.last_message.message_id;
}

@end
