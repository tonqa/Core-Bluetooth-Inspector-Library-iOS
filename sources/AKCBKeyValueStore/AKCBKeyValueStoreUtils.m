//
//  AKCBKeyValueStoreUtils.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreUtils.h"

@implementation AKCBKeyValueStoreUtils

+ (NSString *)getUUID {
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

+ (NSData *)serialize:(id)object {
    return [NSJSONSerialization dataWithJSONObject:object options:kNilOptions error:nil];
}

+ (id)deserialize:(NSData *)data {
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:NULL];
}

@end
