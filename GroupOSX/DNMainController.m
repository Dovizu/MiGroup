//
//  DNMainController.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/12/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNMainController.h"
#import "DNDataManager.h"
#import "Message.h"
#import "DNLoginSheetController.h"

@interface DNMainController ()

@end

@implementation DNMainController
{
    IBOutlet NSArrayController *_groupArrayController;
    IBOutlet NSArrayController *_messagesArrayController;
    IBOutlet NSTableCellView *_samplingView;
    IBOutlet NSTextField *_samplingViewSender;
    IBOutlet NSTextField *_samplingViewMessage;
    IBOutlet NSImageView *_samplingViewImage;
    IBOutlet NSTableView *_messageTableView;
    IBOutlet NSTableView *_groupTableVIew;
}


#pragma mark - Sorting Descriptors

- (NSArray*)messagesSortDescriptors
{
    return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES]];
}

- (NSArray*)groupSortDescriptors
{
    return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"last_message.created_at" ascending:NO]];
}

#pragma mark - Notifications and Delegate
- (void)notifyUserOfGroupMessage:(Message*)message fromGroup:(Group*)targetGroup
{
    if (![(NSNumber*)(message.system) boolValue]) {
        NSString *text = message.text;
        NSString *sender = message.sender_name;
        NSImage *avatar = message.sender_avatar.avatar;
        NSString *groupName = targetGroup.name;
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.hasReplyButton = YES;
        notification.responsePlaceholder = @"Quick Reply here";
        notification.title = groupName;
        notification.subtitle = [NSString stringWithFormat:@"%@ says", sender];
        notification.informativeText = text;
        notification.contentImage = avatar;
        notification.userInfo = @{@"target_group": message.target_group.group_id};
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *selectedGroupID = [[_groupArrayController selection] valueForKey:@"group_id"];
        if ([selectedGroupID isEqualToString:message.target_group.group_id]) {
            [_messageTableView scrollRowToVisible:[_messageTableView numberOfRows]-1];
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    if (notification.activationType == NSUserNotificationActivationTypeReplied) {
        [_dataManager sendNewMessage:[notification.response string]
                             toGroup:notification.userInfo[@"target_group"]
                     withAttachments:nil];
    }else if (notification.activationType == NSUserNotificationActivationTypeContentsClicked) {
        
        NSIndexSet *indexes = [[_groupArrayController arrangedObjects] indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            Group *group = obj;
            return [group.group_id isEqualToString:notification.userInfo[@"target_group"]];
        }];
        [_groupTableVIew selectRowIndexes:indexes byExtendingSelection:NO];
        [_messageTableView scrollRowToVisible:[_messageTableView numberOfRows]-1];
    }
}

#pragma mark - Message Table View Delegate and Helpers

/**
 *  Reload data in order to calculate row heights when re-sized
 */
- (void)tableViewColumnDidResize:(NSNotification *)notification
{
    [_messageTableView reloadData];
}

/**
 *  Calculates the optimal row height for each message
 */
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    [_samplingViewMessage setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [_samplingViewSender setAutoresizingMask:NSViewNotSizable];
    [_samplingViewImage setAutoresizingMask:NSViewNotSizable];
    
    Message *message = [[_messagesArrayController arrangedObjects] objectAtIndex:row];
    _samplingView.objectValue = message;
    
    CGFloat colWidth = [(NSTableColumn*)[[tableView tableColumns] objectAtIndex:0] width];
    [_samplingView setFrameSize:NSMakeSize(colWidth, CGFLOAT_MAX)];
    colWidth = _samplingViewMessage.frame.size.width;

    NSTextFieldCell *cell = _samplingViewMessage.cell;
    NSSize optimalSize = [cell cellSizeForBounds:NSMakeRect(0, 0, colWidth, CGFLOAT_MAX)];
    CGFloat senderHeight = _samplingViewSender.frame.size.height;
    CGFloat optimalHeight = optimalSize.height + senderHeight;
    optimalHeight += 18; //compensation
    if (optimalHeight < _samplingViewImage.frame.size.height) {
        optimalHeight = _samplingViewImage.frame.size.height;
    }
    return optimalHeight;
}

#pragma mark - GUI Actions
- (IBAction)logout:(id)sender
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    dispatch_async(queue, ^{
        NSManagedObjectContext *currentContext = [NSManagedObjectContext defaultContext];
        [Group truncateAllInContext:currentContext]; //cascade delete will clear out the whole database
        [currentContext saveToPersistentStoreAndWait];
    });
    [_dataManager logout]; //dataManager will logout server and clear userDefaults
}

- (IBAction)sendMessage:(id)sender
{
    NSTextField *inputField = (NSTextField*)sender;
    NSString *messageText = inputField.stringValue;
    [_dataManager sendNewMessage:messageText toGroup:[[_groupArrayController selection] valueForKey:@"group_id"] withAttachments:nil];
    [inputField setStringValue:@""];
}

#pragma mark - Login Sheet

- (void)promptForLoginWithPreparedURL:(NSURL *)url
{
    [_loginSheetController openSheetWithURL:url];
}
- (void)closeLoginSheet
{
    [_loginSheetController closeLoginSheet:nil];
}

@end
