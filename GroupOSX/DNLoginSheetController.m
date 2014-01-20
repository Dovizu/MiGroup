//
//  DNLoginSheetController.m
//  GroupOSX
//
//  Created by Donny Reynolds on 1/19/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import "DNLoginSheetController.h"
#import "DNMainController.h"

@interface DNLoginSheetController ()

@end

@implementation DNLoginSheetController

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

- (void)openSheetWithURL:(NSURL *)url
{
    [_mainController.window beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {}];
    [[_loginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)openURLOnly:(NSURL*)url
{
    [[_loginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (IBAction)closeLoginSheet:(id)sender
{
    if ([_mainController.window attachedSheet]) {
        [_mainController.window endSheet:self.window];
    }
}

@end
