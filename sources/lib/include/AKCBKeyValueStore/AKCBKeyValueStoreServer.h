//
//  AKCBKeyValueStoreServer.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import <AKCBKeyValueStore/AKCBKeyValueStoreConstants.h>

@interface AKCBKeyValueStoreServer : NSObject <CBPeripheralManagerDelegate>

/**
 * A list of all properties for connected clients.
 */
@property (nonatomic, strong) NSArray *connectedClients;

/**
 * Initializes the server with a name, which will be observable at the client side.
 */
- (id)initWithName:(NSString *)serverName;

/**
 * Observes a value at a keyPath and sets up
 */
- (void)inspectValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                    identifier:(NSString *)identifier
                       options:(NSInteger)options
                       context:(id)context;

/**
 * This starts a AKCBKeyValueStore service, where
 * clients can connect to.
 */
- (void)start;

/**
 * This stops the current service.
 */
- (void)stop;

/**
 * This continues a paused service, which should be done
 * when waking up from the background.
 */
- (void)resume;

/**
 * This pauses a running service, which should be done
 * when going to the background.
 */
- (void)pause;

@end
