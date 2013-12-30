//
//  DNLoginSheetController.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNLoginSheetController.h"

#import "DNMainWindowController.h"
@interface DNLoginSheetController ()

//Methods listed here are "private"
- (IBAction)quitButtonPressed:(id)sender;

@end

@implementation DNLoginSheetController

#pragma mark - Instatiation

- (id)init
{
    self = [super initWithWindowNibName:@"LoginSheet"]; //Invisible at launch
    if (self){
    }
    return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark - Login Sheet Actions

- (void)promptForLoginWithPreparedURL:(NSURL *)url
{
    [self.mainWindowController.window beginSheet:self.window completionHandler:^void (NSModalResponse returnCode){}];
    [[loginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)closeLoginSheet
{
    [self.mainWindowController.window endSheet:self.window];
}

- (IBAction)quitButtonPressed:(id)sender
{
    [self closeLoginSheet];
}

#pragma mark - Authentication Catch

//- (void)webView:(WebView *)sender willPerformClientRedirectToURL:(NSURL *)URL
//          delay:(NSTimeInterval)seconds
//       fireDate:(NSDate *)date
//       forFrame:(WebFrame *)frame
//{
//    NSLog(@"Redirect: %@", URL);
//}

@end
