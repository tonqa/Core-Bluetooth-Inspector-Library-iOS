//
//  AKCBKeyValueStoreUtils.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AKCBUtils : NSObject

+ (NSString *)getUUID;
+ (NSData *)serialize:(id)object;
+ (id)deserialize:(NSData *)data;

@end
