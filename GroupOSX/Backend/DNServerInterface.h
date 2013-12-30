//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

//Basic stuff
#import <Foundation/Foundation.h>
#include "GlobalConstants.h"
#import "NSString+NXOAuth2.h"
#import "NSURL+NXOAuth2.h"
#import "NSURLConnection+Tagged.h"
//App headers
#import "DNSocketDelegate.h"
@class DNLoginSheetController;

@interface DNServerInterface : NSObject <NSURLConnectionDelegate>

@property DNLoginSheetController *loginSheetController;

- (id)init;
- (BOOL)isLoggedIn;
- (void)authenticate;
- (void)didReceiveURL:(NSString*)urlString;
@end
