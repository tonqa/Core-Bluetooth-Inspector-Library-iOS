//
//  AKCBKeyValueStoreClient.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

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


@interface AKCBKeyValueStoreClient : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

/**
 * This is the delegate that gets informed for changes.
 */
@property (nonatomic, weak) id<AKCBKeyValueStoreClientDelegate> delegate;

/**
 * Initializes the client to a server with a chosen name.
 */
- (id)initWithServerName:(NSString *)serverName;

/**
 * Fetches all peripherals which offer value observation.
 */
- (void)findPeripherals:(AKHandlerWithResult)completion;

/**
 * Connects to a specific peripheral
 */
- (void)connectToPeripheral:(CBPeripheral *)peripheral completion:(AKHandlerWithoutResult)completion;

/**
 * Fetches the value data with an ID.
 */
- (void)readValueWithIdentifier:(NSString *)identifier
                 completion:(AKHandlerWithResult)completion;

/**
 * Save a value to the AKCBServer, which we are currently
 * connected to. The value given must correspond to the
 * NSCopying protocol to send it over the wire. You can do this
 * by using NSNumber or NSValue instead of primitive types.
 * This operation could fail, which results in an
 * error given to the completion block.
 */
- (void)writeValue:(id<NSCopying>)value withIdentifier:(NSString *)identifier
        completion:(AKHandlerWithoutResult)completion;

@end
