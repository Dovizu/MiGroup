//
//  DNServerInterface.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SRWebSocket.h>

//This server model manages an internal socket, a delegate of SocketRocket
@interface DNSocketDelegate : NSObject <SRWebSocketDelegate>

//Interfaces for delegation for SRWebSocket
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
@end

@interface DNServerInterface : NSObject
{
    //Variables
    SRWebSocket *socket;
    DNSocketDelegate *socketDelegate;
}

//Internal methods
-(id)init;
-(BOOL)connectToServer;

@end
