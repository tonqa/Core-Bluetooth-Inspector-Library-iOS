//
//  AKCBKeyValueStoreClient.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AKCBKeyValueStore/AKCBKeyValueStoreConstants.h>


@protocol AKCBKeyValueStoreClientDelegate <NSObject>

/**
 * This is called when an observed value was changed
 * on the server side.
 */
- (void)observedChangeAtKeyPath:(NSString *)keyPath
                          value:(id)value
                     identifier:(NSString *)identifier
                        context:(id)context;

@end


@interface AKCBKeyValueStoreClient : NSObject

/**
 * This is the delegate that gets informed for changes.
 */
@property (nonatomic, weak) id<AKCBKeyValueStoreClientDelegate> delegate;

/**
 * All properties of the connected AKCBServer.
 */
@property (nonatomic, retain) NSDictionary *connectedServer;

/**
 * Fetches all services which offer value observation.
 */
- (void)findAllValueServices:(AKHandlerWithResult)completion;

/**
 * Fetches the value data with an ID.
 */
- (void)readValueWithID:(NSString *)identifier
             completion:(AKHandlerWithResult)completion;

/**
 * Save a value to the AKCBServer, which we are currently
 * connected to. The value given must correspond to the
 * NSCopying protocol to send it over the wire. You can do this
 * by using NSNumber or NSValue instead of primitive types.
 * This operation could fail, which results in an
 * error given to the completion block.
 */
- (void)writeValue:(id<NSCopying>)value withID:(NSString *)identifier
        completion:(AKHandlerWithoutResult)completion;

@end
