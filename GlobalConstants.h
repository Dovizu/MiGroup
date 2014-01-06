//
//  Constants.h
//  GroupOSX
//
//  Created by Donny Reynolds on 12/26/13.
//  Copyright (c) 2013 Dovizu Network. All rights reserved.
//

#ifndef GlobalConstants
#define GlobalConstants

typedef NSString* DNNotificationType;
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

extern NSString * const JSONObjectEmojiPlaceholderString;

//Network observer names
extern NSString * const noteUserInfoReceivedReadyForSockets;

extern NSString * const noteFirstTimeLogon;
extern NSString * const finalGroupIndexAllResultsArrived;

extern NSString * const finalGroupMemberAdded;
extern NSString * const finalGroupMemberRemoved;
extern NSString * const finalGroupAvatarChanged;
extern NSString * const finalUserOwnMessageReceived;
extern NSString * const finalMemberMessageReceived;
extern NSString * const kGetContentKey;
extern NSString * const kGetTypeKey;


extern NSString * const finalGroupIndexResultsArrived;
extern NSString * const finalGroupSpecificResultArrived;

//Error domain names
extern NSString * const DNErrorDomain;

extern NSInteger const eNoNetworkConnectivityGeneral;
extern NSString * const eNoNetworkConnectivityGeneralDesc;
extern NSInteger const eLogOutPurgingFailure;
extern NSString * const eLogOutPurgingFailureDesc;

//User Defaults
extern NSString * const DNUserDefaultsUserToken;
extern NSString * const DNUserDefaultsUserInfo;

#endif
