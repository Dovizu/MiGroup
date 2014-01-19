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
    IBOutlet NSTableView *messageTableView;
}

- (IBAction)sendMessage:(id)sender
{
    NSTextField *inputField = (NSTextField*)sender;
    NSString *messageText = inputField.stringValue;
    [_dataManager sendNewMessage:messageText toGroup:[[_groupArrayController selection] valueForKey:@"group_id"] withAttachments:nil];
    [inputField setStringValue:@""];
}

#pragma mark - NSArrayController

- (NSArray*)messagesSortDescriptors
{
    return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"created_at" ascending:YES]];
}

#pragma mark - Message Table View Delegate

/**
 *  Reload data in order to calculate row heights when re-sized
 */
- (void)tableViewColumnDidResize:(NSNotification *)notification
{
    [messageTableView reloadData];
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
    
    CGFloat width = [[[tableView tableColumns] objectAtIndex:0] width];
    [_samplingView setFrameSize:NSMakeSize(width, CGFLOAT_MAX)];
    width = _samplingViewMessage.frame.size.width;

    NSTextFieldCell *cell = _samplingViewMessage.cell;
    NSSize optimalSize = [cell cellSizeForBounds:NSMakeRect(0, 0, width, CGFLOAT_MAX)];
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
}
@end
