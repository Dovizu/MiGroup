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
    IBOutlet NSTableCellView *_samplingView;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    NSString *text = ((Message*)[tableView preparedCellAtColumn:0 row:row].objectValue).text;
    NSTextField *textField;
    for (NSView *subview in tableView.subviews) {
        if ([subview isKindOfClass:[NSTextField class]]) {
            textField = (NSTextField*)subview;
        }
    }
    NSRect rect = [text boundingRectWithSize:CGSizeMake(textField.frame.size.width, CGFLOAT_MAX)
                       options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                    attributes:@{NSFontAttributeName: textField.font}];
    
    return rect.size.height;
    
    
}

#pragma mark - GUI Actions
- (IBAction)logout:(id)sender
{

}
@end
