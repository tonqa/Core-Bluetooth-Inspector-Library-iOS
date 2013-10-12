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

- (void)getAllObjectUUIDs:(AKHandlerWithResult)completion {
    
}

- (void)getObjectWithUUID:(NSString *)uuid
               completion:(AKHandlerWithResult)completion {
    
}

- (void)deleteObjectWithUUID:(NSString *)uuid
                  completion:(AKHandlerWithoutResult)completion {
    
}

- (void)createObjectWithUUID:(NSString *)uuid
                  completion:(AKHandlerWithoutResult)completio {
    
}

- (void)setValue:(NSData *)value forObjectUUID:(NSString *)uuid
      completion:(AKHandlerWithoutResult)completion {
    
}

@end
