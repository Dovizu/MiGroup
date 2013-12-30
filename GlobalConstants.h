//
//  Constants.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#ifndef GroupOSX_Constants_h
#define GroupOSX_Constants_h

typedef NSDictionary DNConnectionType;
//Authentication Constants
extern NSString* const DNOAuth2ClientID;
extern NSString * const DNOAuth2AuthorizationURL;
extern NSString * const DNOAuth2TokenURL;
extern NSString * const DNOAuth2RedirectURL;
extern NSString * const DNOAuth2TokenArgumentKey;
extern NSString * const DNRESTAPIBaseAddress;

//RESTful constants
extern NSString * const HTTPMethod;
extern NSString * const partialURL;
extern NSString * const URLTokenParamKey;
extern NSString * const JSONRequestContentTypeValue;
extern NSString * const JSONRequestContentTypeKey;
extern NSString * const JSONRequestContentLengthKey;
extern NSString * const connectionTag;

#endif
