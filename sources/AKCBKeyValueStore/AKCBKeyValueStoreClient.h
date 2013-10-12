//
//  AKCBKeyValueStoreClient.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AKCBKeyValueStore/AKCBKeyValueStoreConstants.h>

@interface AKCBKeyValueStoreClient : NSObject

/**
 * All properties of the connected KeyValueStore Server.
 */
@property (nonatomic, retain) NSDictionary *connectedServer;

/**
 * Fetch a list of all currently reachable servers.
 */
- (void)fetchListOfServersWithServiceName:(NSString *)serviceName
                               completion:(AKHandlerWithResult)completion;

/**
 * Connect to a Bluetooth LE service, which should be able
 * to handle the AKCBKeyValueStore protocol.
 */
- (void)connectToServiceWithUUID:(NSString *)serviceUUID;

/**
 * Fetches all UUIDs of stored objects.
 */
- (void)getAllObjectUUIDs:(AKHandlerWithResult)completion;

/**
 * Fetches the object data with an object UUID.
 */
- (void)getObjectWithUUID:(NSString *)uuid
               completion:(AKHandlerWithResult)completion;

/**
 * Deletes an entry with a given UUID. An error can occur if
 * either the connection is broken or the value does not exist.
 */
- (void)deleteObjectWithUUID:(NSString *)uuid
                  completion:(AKHandlerWithoutResult)completion;

/**
 * Creates an object and returns an UUID, which
 * can be saved locally to
 */
- (void)createObjectWithUUID:(NSString *)uuid
                  completion:(AKHandlerWithoutResult)completion;


/**
 * Save a value to the AKCBKeyValueStore, which we are currently
 * connected to. This operation could fail, which results in an
 * error given to the completion block.
 */
- (void)setValue:(NSData *)value forObjectUUID:(NSString *)uuid
      completion:(AKHandlerWithoutResult)completion;

@end
