//
//  DNServerInterface.m
//  GroupOSX
//
//  Created by Donny Reynolds on 12/25/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#import "DNServerInterface.h"

#import "DNLoginSheetController.h"


@interface DNServerInterface ()
{
    SRWebSocket *socket;
    DNSocketDelegate *socketDelegate;
    BOOL authenticated;
    NSString *userToken;
    
    //Connection Types Constants
    DNConnectionType *TypeGetUserInfo;
    DNConnectionType *TypeIndexGroups;
}

- (void)authenticatedOn;
- (void)authenticatedOff;
- (void)startConnectionType:(DNConnectionType*)connectionType withBody:(NSDictionary*)bodyDict andParameters:(NSDictionary*)parameters;

@end

@implementation DNServerInterface


#pragma mark - Server Initialization Logic
- (id)init
{
    self = [super init];
    if (self){
        //Configure server interface and instantiate SocketRocket
        socketDelegate = [[DNSocketDelegate alloc] init];
        [self initializeConnectionTypes];
    }
    return self;
}

- (void)initializeConnectionTypes
{
    TypeGetUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"/users/me", partialURL,
                       @"GET", HTTPMethod,
                       @"TypeGetUserInfo", connectionTag,
                       nil];
    
    TypeIndexGroups = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"/groups", partialURL,
                       @"GET", HTTPMethod,
                       @"TypeIndexGroups", connectionTag,
                       nil];
}

#pragma mark - Requests and Connection Logic



- (void)startConnectionType:(DNConnectionType*)connectionType withBody:(NSDictionary*)bodyDict andParameters:(NSDictionary*)parameters
{
    //Construct URL
    NSString *URLWithoutParams = [NSString stringWithFormat:@"%@%@",
                                      DNRESTAPIBaseAddress,
                                      [[connectionType objectForKey:partialURL] nxoauth2_URLEncodedString]];
    //Add token and parameters if necessary
    if (parameters) {
        [parameters setValue:userToken forKey:URLTokenParamKey];
    }else{
        parameters = [NSDictionary dictionaryWithObjectsAndKeys:userToken, URLTokenParamKey, nil];
    }
    
    //Create request with this URL
    NSURL *URL = [[NSURL URLWithString:URLWithoutParams] nxoauth2_URLByAddingParameters:parameters];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setHTTPMethod:[connectionType objectForKey:HTTPMethod]];

    //Add JSON data if necessary
    if (bodyDict) {
        NSError *error = [[NSError alloc] init];
        NSData *JSONData = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&error];
        if (JSONData) {
            NSString *JSONString = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
            [request setHTTPBody:JSONData];
            [request setValue:[NSString stringWithFormat:@"%u", (unsigned int)[JSONData length]]
                       forKey:JSONRequestContentLengthKey];
            [request setValue:JSONRequestContentTypeValue forKey:JSONRequestContentTypeKey];
        }else{
            DebugLog(@"JSONSerialization Error occured: %@", [error description]);
        }
    }
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request
                                                                  delegate:self
                                                          startImmediately:NO
                                                                       tag:[connectionType objectForKey:connectionTag]];
    if (connection) {
        DebugLog(@"Connection ready: %@", [connection description]);
        [connection start];
    }
}

#pragma mark - Authentication/Token Retrieval

//Because of the nature of GroupMe's OAuth2 system, a view is always needed for authentication
//Therefore ServerInterface keeps strong connection to LoginSheetController
- (void)authenticate
{
    if (![self isLoggedIn]) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           DNOAuth2ClientID, @"client_id",
                                           nil];
        NSURL *preparedAuthorizationURL = [[NSURL URLWithString:DNOAuth2AuthorizationURL] nxoauth2_URLByAddingParameters:parameters];
        DebugLog(@"Server is authenticating at %@", [preparedAuthorizationURL absoluteString]);
        [self.loginSheetController promptForLoginWithPreparedURL:preparedAuthorizationURL];
    }
}

- (void)didReceiveURL:(NSURL*)url
{
    DebugLog(@"Server received URL: %@", [url absoluteString]);
    NSString *token = [url nxoauth2_valueForQueryParameterKey:DNOauth2TokenArgKey];
    
    if (token) {
        [self authenticatedOn];
        [self.loginSheetController closeLoginSheet];
        DebugLog(@"Server successfully authenticated with token: %@", token);
        //save user setting right here
        userToken = token;

    }else{
        DebugLog(@"Server failed to retrieve token, authentication restart...");
        [self authenticatedOff]; //just to be sure
        [self.loginSheetController closeLoginSheet];
        [self authenticate]; //do it again
    }
}

- (void)authenticatedOn
{
    authenticated = YES;
}

- (void)authenticatedOff
{
    authenticated = NO;
}

- (BOOL)isLoggedIn
{
    return authenticated;
}

@end