//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NXOAuth2.h>

#import "DNSocketDelegate.h"
@class DNLoginSheetController;

@interface DNServerInterface : NSObject
{
    //Variables
    SRWebSocket *socket;
    DNSocketDelegate *socketDelegate;
    BOOL authenticated;
}

@property DNLoginSheetController *loginSheetController;

//Internal methods
- (id)init;
- (BOOL)loggedIn;
- (void)authenticate;
@end
