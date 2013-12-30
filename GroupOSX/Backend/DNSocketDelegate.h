//
//  DNSocketDelegate.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SRWebSocket.h>

@interface DNSocketDelegate : NSObject <SRWebSocketDelegate>
{
    SRWebSocket *messageSocket;
    SRWebSocket *groupSocket;
}

//Interface for delegation for SRWebSocket
-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
-(void)webSocketDidOpen:(SRWebSocket *)webSocket;
-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;

//Interface for server
- (void)establishSockets;

@end
