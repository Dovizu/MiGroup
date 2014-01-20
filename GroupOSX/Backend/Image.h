//
//  Image.h
//  GroupOSX
//
//  Created by Donny Reynolds on 1/19/14.
//  Copyright (c) 2014 Dovizu Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Image : NSManagedObject

@property (nonatomic, retain) id preview;
@property (nonatomic, retain) id large;
@property (nonatomic, retain) id avatar;
@property (nonatomic, retain) NSString * id_url;
@property (nonatomic, retain) NSNumber * isCached;

@end
