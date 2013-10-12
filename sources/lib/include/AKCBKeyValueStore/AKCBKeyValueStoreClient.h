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
 * Save a value to the AKCBKeyValueStore, which we are currently
 * connected to. This operation could fail, which results in an
 * error given to the completion block.
 */
- (void)sendValue:(id)value forKey:(NSString *)key
       completion:(AKHandlerWithoutResult)completion;

/**
 * Fetch a value from the AKCBKeyValueStore, which we are currently
 * connected to. If this operation is successful, the completion block
 * is called with a result value, otherwise an error is set.
 */
- (void)fetchValueForKey:(NSString *)key
              completion:(AKHandlerWithResult)completion;

@end
