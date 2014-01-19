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
    [self helpProcessMessages:messages];
}
- (void)didChangeMemberName:(NSNotification*)note
{
    
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
        Group *dbGroup;
        (dbGroup = [Group findFirstByAttribute:@"group_id" withValue:fetchedGroup[k_group_id]]) ? (nil) : (dbGroup = [Group createInContext:_managedObjectContext]);
        dbGroup.desc = fetchedGroup[k_desc];
        dbGroup.created_at = fetchedGroup[k_created_at];
        dbGroup.group_id = fetchedGroup[k_group_id];
        dbGroup.name = fetchedGroup[k_name_of_group];
        dbGroup.share_url = fetchedGroup[k_share_url];
        dbGroup.type = fetchedGroup[k_type_of_group];
        dbGroup.updated_at = fetchedGroup[k_updated_at];
        [self helpProcessMemberArray:fetchedGroup[k_members] intoGroup:dbGroup.objectID createdBy:fetchedGroup[k_creator_group]];
        //Obtain image asynchronously
        if (![fetchedGroup[k_image] isKindOfClass:[NSNull class]]) {
            [_requestManager GET:[fetchedGroup[k_image] absoluteString]
                      parameters:nil
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             NSImage *image = (NSImage*)responseObject;
                             dbGroup.image = image;
                             [_managedObjectContext saveToPersistentStoreAndWait];
                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                             DebugLogCD(@"Failed to obtain image for group: %@, error:\n%@", dbGroup.name, error);
                         }];
        }
        
        //Process last message, special case because of GroupMe's weird API
        NSSet *tempSet = [dbGroup.members filteredSetUsingPredicate:
                          [NSPredicate predicateWithFormat:@"name == %@", fetchedGroup[k_last_message][k_name_of_member]]];
        NSAssert([tempSet count] == 1, @"More than one creator found for one group");
        Member *lastMessageCreator = [tempSet anyObject];
        Message *lastMessage = [Message createInContext:_managedObjectContext];
        lastMessage.creator = lastMessageCreator;
        lastMessage.text = fetchedGroup[k_last_message][k_text];
        lastMessage.created_at = fetchedGroup[k_last_message][k_created_at];
        lastMessage.message_id = fetchedGroup[k_last_message][k_message_id];
        lastMessage.target_group = dbGroup;
        [dbGroup addMessagesObject:lastMessage];
        dbGroup.last_message = lastMessage;
        [_managedObjectContext saveToPersistentStoreAndWait];
        
        [self helpProcessAttachmentArray:fetchedGroup[k_last_message][k_attachments] inMessage:lastMessage.objectID];
        [_server fetch20MessagesBeforeMessageID:lastMessage.message_id inGroup:dbGroup.group_id];
    }
}
- (void)didFetchFormerGroups:(NSNotification*)note
{
    
}
- (void)didFetchMessagesBefore:(NSNotification*)note
{
    NSArray *fetchedMessages = note.userInfo[k_messages];
    if ([fetchedMessages count] != 0) {
        [self helpProcessMessages:fetchedMessages];
    }
}
- (void)didFetchMessagesSince:(NSNotification*)note
{
    
}

- (void)helpProcessMessages:(NSArray*)fetchedMessages
{
    NSAssert([fetchedMessages count] != 0, @"0-length messages array is passed in");
    
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *group = [[Group findByAttribute:@"group_id" withValue:[fetchedMessages firstObject][k_target_group]] firstObject];
    for (NSDictionary *fetchedMessage in fetchedMessages) {
        Message *dbMessage = [[group.messages filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"message_id == %@", fetchedMessage[k_message_id]]] anyObject];
        if (!dbMessage) {
            dbMessage = [Message createInContext:currentContext];
            dbMessage.message_id = fetchedMessage[k_message_id];
            dbMessage.text = fetchedMessage[k_text];
            dbMessage.target_group = group;
            dbMessage.created_at = fetchedMessage[k_created_at];
            dbMessage.creator = [[Member findByAttribute:@"user_id" withValue:fetchedMessage[k_creator_of_message] inContext:currentContext] firstObject];
            if ([group.last_message.created_at compare:dbMessage.created_at] == NSOrderedAscending) {
                group.last_message = dbMessage;
            }
            [self helpProcessAttachmentArray:fetchedMessage[k_attachments] inMessage:dbMessage.objectID];
        }
    }
    [currentContext saveToPersistentStoreAndWait];
}

- (void)helpProcessMemberArray:(NSArray*)members intoGroup:(NSManagedObjectID*)groupID createdBy:(NSString*)creator_user_id
{
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    Group *group = (Group*)[currentContext objectWithID:groupID];

    NSLog(@"group members count: %d", (int)[group.members count]);
    //Obtain all current members in membership_id-member pairs
    NSMutableDictionary *membersToProcess = [[NSMutableDictionary alloc] initWithCapacity:[group.members count]];
    for (Member *member in group.members) {
        if (![member.user_id isEqualToString:@"system"]) {
            membersToProcess[member.membership_id] = member;
        }
    }
    
    //First, create "system" member if this is a new group
    if ([group.members count] == 0) {
        Member *system = [Member createInContext:currentContext];
        system.name = @"System";
        system.membership_id = @"system";
        system.user_id = @"system";
        system.is_creator = NO;
        system.muted = NO;
        system.group = group;
        [group addMembersObject:system];
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
            [_requestManager GET:[fetchedMember[k_image] absoluteString]
                      parameters:nil
                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                             NSImage *image = (NSImage*)responseObject;
                             dbMember.image = image;
                             [currentContext saveToPersistentStoreAndWait];
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
