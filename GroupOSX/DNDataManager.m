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
        [self establishObserversForNotifications];
    }
    return self;
}

#pragma mark - Actions

- (void)logout
{
    [_server teardown];
}

- (void)sendNewMessage:(NSString*)text toGroup:(NSString*)groupID withAttachments:(NSArray*)attachments
{
    /**
     *  In future releases, this section is supposed to process attachments and replace text emoji's.
     */
    NSAssert(text && groupID, @"Message text or group cannot be nil");
    [_server sendNewMessage:text toGroup:groupID withAttachments:nil];
}

#pragma mark - Message Routing

- (void)establishObserversForNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    //First time logon
    [center addObserver:self selector:@selector(firstTimeLogonSetup:)   name:noteFirstTimeLogon object:nil];
    [center addObserver:self selector:@selector(didReceiveMessage:)     name:noteNewMessage object:nil];
    [center addObserver:self selector:@selector(didChangeMemberName:)   name:noteMemberNameChange object:nil];
    [center addObserver:self selector:@selector(didChangeGroupAvatar:)  name:noteGroupAvatarChange object:nil];
    [center addObserver:self selector:@selector(didChangeGroupName:)    name:noteGroupNameChange object:nil];
    [center addObserver:self selector:@selector(didUpdateGroup:)        name:noteGroupUpdate object:nil];
    [center addObserver:self selector:@selector(didRemoveGroup:)        name:noteGroupRemove object:nil];
    [center addObserver:self selector:@selector(didFetchGroupInfo:)     name:noteGroupInfoFetch object:nil];
    [center addObserver:self selector:@selector(didCreateGroup:)        name:noteGroupCreate object:nil];
    [center addObserver:self selector:@selector(didRemoveMember:)       name:noteMemberRemove object:nil];
    [center addObserver:self selector:@selector(didAddMember:)          name:noteMembersAdd object:nil];
    [center addObserver:self selector:@selector(didFetchAllGroups:)     name:noteGroupsAllFetch object:nil];
    [center addObserver:self selector:@selector(didFetchFormerGroups:)  name:noteGroupsFormerFetch object:nil];
    [center addObserver:self selector:@selector(didFetchMessagesBefore:)name:noteMessagesBeforeFetch object:nil];
    [center addObserver:self selector:@selector(didFetchMessagesSince:) name:noteMessagesSinceFetch object:nil];
}

- (void)firstTimeLogonSetup:(NSNotification*)note
{
    [_server fetchAllGroups];
}

- (void)didReceiveMessage:(NSNotification*)note
{
    NSArray *messages = @[note.userInfo];
    Group *group = [[Group findByAttribute:@"group_id" withValue:note.userInfo[k_target_group] inContext:_managedObjectContext] firstObject];
    [self helpProcessMessages:messages toGroup:group.objectID];
}
- (void)didChangeMemberName:(NSNotification*)note
{
    NSDictionary *info = note.userInfo;
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Member *dbMember = [[[Member findByAttribute:@"name" withValue:info[k_name_of_member] inContext:currentContext]
                        filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"group.group_id == %@", info[k_group_id]]] firstObject];
    dbMember.name = info[k_new_name];
    [currentContext saveToPersistentStoreAndWait];
}
- (void)didChangeGroupAvatar:(NSNotification*)note
{
    
}
- (void)didChangeGroupName:(NSNotification*)note
{
    
}
- (void)didUpdateGroup:(NSNotification*)note
{
    
}
- (void)didRemoveGroup:(NSNotification*)note
{
    
}
- (void)didFetchGroupInfo:(NSNotification*)note
{
    
}
- (void)didCreateGroup:(NSNotification*)note
{
    
}
- (void)didRemoveMember:(NSNotification*)note
{
    
}
- (void)didAddMember:(NSNotification*)note
{
    
}

- (void)didFetchAllGroups:(NSNotification*)note
{
    NSArray *fetchedGroups = note.userInfo[k_fetched_groups];
    for (NSDictionary *fetchedGroup in fetchedGroups) {
        [self helpProcessGroup:fetchedGroup];
    }
}
- (void)didFetchFormerGroups:(NSNotification*)note
{
    
}
- (void)didFetchMessagesBefore:(NSNotification*)note
{
    NSArray *fetchedMessages = note.userInfo[k_messages];
    
    if ([fetchedMessages count] != 0) {
        Group *dbGroup = [[Group findByAttribute:@"group_id"
                                      withValue:[fetchedMessages firstObject][k_target_group]
                                       inContext:_managedObjectContext] firstObject];
        [self helpProcessMessages:fetchedMessages toGroup:dbGroup.objectID];
    }
}
- (void)didFetchMessagesSince:(NSNotification*)note
{
    
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
    
    [self helpProcessMessages:@[fetchedGroup[k_last_message]] toGroup:dbGroup.objectID];
    [_server fetch20MessagesBeforeMessageID:fetchedGroup[k_last_message][k_message_id] inGroup:dbGroup.group_id];
    [self helpProcessMemberArray:fetchedGroup[k_members] intoGroup:dbGroup.objectID createdBy:fetchedGroup[k_creator_group]];
}

- (void)helpProcessMessages:(NSArray*)fetchedMessages toGroup:(NSManagedObjectID*)groupID;
{
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
            dbMessage.sender_name = fetchedMessage[k_sender_name];
            if (fetchedMessage[k_user_id]) {
                dbMessage.sender_user_id = fetchedMessage[k_user_id];
            }
            dbMessage.text = fetchedMessage[k_text];
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
            if (dbMessage.sender_user_id && ![_server isUser:dbMessage.sender_user_id]) {
                [_mainController notifyUserOfGroupMessage:dbMessage fromGroup:group];
            }
            [self helpProcessAttachmentArray:fetchedMessage[k_attachments] inMessage:dbMessage.objectID];
        }
    }
    [currentContext saveToPersistentStoreAndWait];
}

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

@end
