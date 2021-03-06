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
extern NSString * const DNOAuth2DeauthorizationURL;

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

extern NSString * const noteNewMessage;
extern NSString * const noteFirstTimeLogon;
extern NSString * const noteMemberNameChange;
extern NSString * const noteGroupsAllFetch;
extern NSString * const noteGroupInfoFetch;
extern NSString * const noteGroupNameChange;
extern NSString * const noteGroupCreate;
extern NSString * const noteGroupUpdate;
extern NSString * const noteGroupRemove;
extern NSString * const noteMemberRemove;
extern NSString * const noteMembersAdd;
extern NSString * const noteGroupAvatarChange;
extern NSString * const noteMessagesBeforeFetch;
extern NSString * const noteMessagesSinceFetch;
extern NSString * const noteGroupsFormerFetch;
extern NSString * const noteOnline;
extern NSString * const noteOffline;


//Database attribute names
extern NSString * const k_name_of_group;
extern NSString * const k_name_of_member;
extern NSString * const k_fetched_groups;
extern NSString * const k_fetched_group;
extern NSString * const k_group;
extern NSString * const k_group_id;
extern NSString * const k_created_at;
extern NSString * const k_type_of_group;
extern NSString * const k_desc;
extern NSString * const k_image;
extern NSString * const k_share_url;
extern NSString * const k_type_of_group;
extern NSString * const k_updated_at;
extern NSString * const k_creator_group;
extern NSString * const k_creator_of_message;
extern NSString * const k_members;
extern NSString * const k_messages;
extern NSString * const k_last_message;
extern NSString * const k_muted;
extern NSString * const k_user_id;
extern NSString * const k_membership_id;
extern NSString * const k_message_id;
extern NSString * const k_target_group;
extern NSString * const k_text;
extern NSString * const k_attachments;
extern NSString * const k_url;
extern NSString * const k_message;
extern NSString * const k_email;
extern NSString * const k_new_name;
extern NSString * const k_phone_number;
extern NSString * const k_attach_type_image;
extern NSString * const k_attach_type_location;
extern NSString * const k_attach_type_split;
extern NSString * const k_attach_type_emoji;
extern NSString * const k_attachment_type;
extern NSString * const k_sender_name;
extern NSString * const k_sender_avatar;
extern NSString * const k_sender_user_id;
extern NSString * const k_is_system;

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
