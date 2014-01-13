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
        [self helpProcessMemberArray:fetchedGroup[k_members] intoGroup:dbGroup createdBy:fetchedGroup[k_creator_group]];
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
        [self helpProcessAttachmentArray:fetchedGroup[k_last_message][k_attachments] inMessage:lastMessage];
        lastMessage.created_at = fetchedGroup[k_last_message][k_created_at];
        lastMessage.message_id = fetchedGroup[k_last_message][k_message_id];
        [dbGroup addMessagesObject:lastMessage];
        dbGroup.last_message = lastMessage;
        [_server fetch20MessagesBeforeMessageID:lastMessage.message_id inGroup:dbGroup.group_id];
        
        [_managedObjectContext saveToPersistentStoreAndWait];
    }
}
- (void)didFetchFormerGroups:(NSNotification*)note
{
    
}
- (void)didFetchMessagesBefore:(NSNotification*)note
{
    
}
- (void)didFetchMessagesSince:(NSNotification*)note
{
    
}

- (void)helpProcessMemberArray:(NSArray*)members intoGroup:(Group*)group createdBy:(NSString*)creatorUserID
{
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
    //Obtain all current members in membership_id-member pairs
    NSMutableDictionary *membersToProcess = [[NSMutableDictionary alloc] initWithCapacity:[group.members count]];
    for (Member *member in group.members) {
        membersToProcess[member.membership_id] = member;
    }
    //Update members or create new ones, updated members are removed from membersToProcess
    for (NSDictionary* fetchedMember in members) {
        Member *updatedMember = membersToProcess[fetchedMember[k_membership_id]];
        if (!updatedMember) {
            //Is new member
            updatedMember = [Member createInContext:currentContext];
            updatedMember.user_id = fetchedMember[k_user_id];
            updatedMember.membership_id = fetchedMember[k_membership_id];
            updatedMember.group = group;
            [group addMembersObject:updatedMember];
        }else{
            //Is current member
            [membersToProcess removeObjectForKey:updatedMember.membership_id];
        }
        //Update attributes for both new and current members
        updatedMember.image = fetchedMember[k_image];
        updatedMember.name = fetchedMember[k_name_of_member];
        updatedMember.muted = fetchedMember[k_muted];
        if ([fetchedMember[k_user_id] isEqualToString:creatorUserID]) {
            updatedMember.is_creator = [NSNumber numberWithBool:YES];
            group.creator = updatedMember;
        }
    }
    //Any remaining members in membersToProcess are to be deleted from the group
//    [group removeMembers:[[NSOrderedSet alloc] initWithArray:[membersToProcess allValues]]];
    [group removeMembers:[NSSet setWithArray:[membersToProcess allValues]]];
    
    [currentContext saveToPersistentStoreAndWait];
}

- (void)helpProcessAttachmentArray:(NSArray*)attachments inMessage:(Message*)message
{
    NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
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
