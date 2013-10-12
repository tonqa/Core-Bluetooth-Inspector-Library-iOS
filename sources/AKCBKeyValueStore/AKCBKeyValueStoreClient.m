//
//  AKCBKeyValueStoreClient.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreClient.h"

@implementation AKCBKeyValueStoreClient

- (void)fetchListOfServersWithServiceName:(NSString *)serviceName
                               completion:(AKHandlerWithResult)completion {
    
}

- (void)connectToServiceWithUUID:(NSString *)serviceUUID {
    
}

- (void)sendValue:(id)value forKey:(NSString *)key
       completion:(AKHandlerWithoutResult)completion {
}

- (void)fetchValueForKey:(NSString *)key
              completion:(AKHandlerWithResult)completion {
}

@end
