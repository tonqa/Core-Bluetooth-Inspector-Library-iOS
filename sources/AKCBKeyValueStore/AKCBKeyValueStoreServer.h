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
 * This starts a AKCBKeyValueStore service, where
 * clients can connect to.
 */
- (void)startServiceWithName:(NSString *)serviceName;

/**
 * This stops the current service.
 */
- (void)stopService;

/**
 * This continues a paused service, which should be done
 * when waking up from the background.
 */
- (void)continueService;

/**
 * This pauses a running service, which should be done
 * when going to the background.
 */
- (void)pauseService;

@end
