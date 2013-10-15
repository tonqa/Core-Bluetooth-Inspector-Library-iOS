//
//  AKCBKeyValueStoreClient.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreClient.h"

#import <AKCBKeyValueStore/AKCBKeyValueStoreUtils.h>

NSString *kBatteryServiceUUIDString = @"180F";
NSString *kAlertServiceUUIDString = @"1802";
NSString *kTimeServiceUUIDString = @"1805";

@interface AKCBKeyValueStoreClient ()

@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableArray *subscribedServiceUUIDs;
@property (nonatomic, strong) NSMutableArray *discoveredServiceUUIDs;
@property (nonatomic, retain) NSMutableDictionary *foundIdentifiersToServiceUUIDs;

@property (nonatomic, copy) AKHandlerWithResult findPeripheralsBlock;
@property (nonatomic, copy) AKHandlerWithResult connectPeripheralBlock;
@property (nonatomic, copy) AKHandlerWithResult readValueBlock;
@property (nonatomic, copy) AKHandlerWithoutResult writeValueBlock;

@end

@implementation AKCBKeyValueStoreClient

- (id)initWithServerName:(NSString *)serverName {
    self = [super init];
    if (self) {
        self.serverName = serverName;
        self.subscribedServiceUUIDs = [NSMutableArray array];
        self.discoveredServiceUUIDs = [NSMutableArray array];
        self.foundIdentifiersToServiceUUIDs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)discoverPeripherals:(AKHandlerWithResult)completion {
    self.findPeripheralsBlock = completion;
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)stopDiscovery {
    [self.centralManager stopScan];
    self.findPeripheralsBlock = nil;
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral completion:(AKHandlerWithResult)completion {
    self.connectPeripheralBlock = completion;
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)readValueWithIdentifier:(NSString *)identifier
                     completion:(AKHandlerWithResult)completion {

    self.readValueBlock = completion;
    
    CBCharacteristic *characteristic = [self _findReadCharacteristicForIdentifier:identifier];
    [self.peripheral readValueForCharacteristic:characteristic];

}

- (void)writeValue:(id<NSCopying>)value withIdentifier:(NSString *)identifier
        completion:(AKHandlerWithoutResult)completion {

    self.writeValueBlock = completion;
    
    NSData *serializedValue = [AKCBKeyValueStoreUtils serialize:@{
                                  AKCB_INSPECTION_KEY_IDENTIFIER: identifier,
                                  AKCB_SENT_KEY_VALUE: value
                                  }];
    
    CBCharacteristic *characteristic = [self _findWriteCharacteristicForIdentifier:identifier];
    [self.peripheral writeValue:serializedValue forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];

}


# pragma mark - Central Manager Delegate methods

- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
            AKCBLOG(@"Did update state");
            [self.centralManager scanForPeripheralsWithServices:nil options:@{
                  CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]
            }]; break;
            
        default:
            break;
    }
}

- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI {
    
    if ([RSSI floatValue] >= -45.f) {
    
        NSString *serverName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        
        if ([serverName isEqualToString:self.serverName]) {
            AKCBLOG(@"Did found IDs and service UUIDs");
            self.peripheral = peripheral;
            if (self.findPeripheralsBlock) self.findPeripheralsBlock(peripheral, nil);
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{

    if (error) NSLog(@"ERROR: %@", error);
    
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral {
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:nil];
}


- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {

    if (error) NSLog(@"ERROR: %@", error);

    for (CBService *service in peripheral.services){
        
        if (![self _isDefaultServiceUUID:service.UUID]) {
            
            [self.subscribedServiceUUIDs addObject:service];
            
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {

    if (error) NSLog(@"ERROR: %@", error);
    
    for (CBCharacteristic *characteristic in service.characteristics){
        
        NSLog(@"Did find: service %s // characteristic %s",
                                                    [self CBUUIDToCString:service.UUID],
                                                    [self CBUUIDToCString:characteristic.UUID]);

        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0000"]]) {
            
            [peripheral readValueForCharacteristic:characteristic];
            
        }
    }
}

/* callback for read */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    if (error) NSLog(@"ERROR: %@", error);

    NSDictionary *notifiedDict = [AKCBKeyValueStoreUtils deserialize:characteristic.value];
    NSString *identifier = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
    id value = [notifiedDict objectForKey:AKCB_SENT_KEY_VALUE];
    
    if ([self.foundIdentifiersToServiceUUIDs objectForKey:identifier] == nil) {
        [self.foundIdentifiersToServiceUUIDs setObject:characteristic.service.UUID forKey:identifier];
    }

    // add service as discovered and return connect callback
    if (![self.discoveredServiceUUIDs containsObject:characteristic.service.UUID]) {
        [self.discoveredServiceUUIDs addObject:characteristic.service.UUID];
        
        if ([self.subscribedServiceUUIDs count] == [self.discoveredServiceUUIDs count]) {
            
            NSLog(@"Connection success");

            if (self.connectPeripheralBlock) self.connectPeripheralBlock([self.foundIdentifiersToServiceUUIDs allKeys], nil);
            self.connectPeripheralBlock = nil;
            
            for (CBService *service in self.peripheral.services) {
                if (![self _isDefaultServiceUUID:service.UUID]) {
                    for (CBCharacteristic *serviceCharacteristic in service.characteristics) {
                        if ([self _isNotifyCharacteristicUUID:serviceCharacteristic.UUID]) {
                            NSLog(@"Subscribing to notify characteristic of service %s", [self CBUUIDToCString:service.UUID]);
                            [peripheral setNotifyValue:YES forCharacteristic:serviceCharacteristic];
                        }
                    }
                }
            }

        }
    } else {
        if (self.readValueBlock) self.readValueBlock(value, nil);
        self.readValueBlock = nil;
    }
    
    //[self.centralManager cancelPeripheralConnection:aPeripheral];
}


/* callback for write */
- (void)peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    if (error) NSLog(@"ERROR: %@", error);
    
    if (self.writeValueBlock) self.writeValueBlock(nil);
    self.writeValueBlock = nil;
    //[self.centralManager cancelPeripheralConnection:aPeripheral];
}


/* callback for notify */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {

    if (error) NSLog(@"ERROR: %@", error);

    // this happens sometimes out of reason, so check..
    if (!characteristic.value) NSLog(@"ERROR: Characteristic has no value"); return;
    
    NSDictionary *notifiedDict = [AKCBKeyValueStoreUtils deserialize:characteristic.value];
    NSString *keyPath = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH];
    NSString *identifier = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
    id context = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_CONTEXT];
    id value = [notifiedDict objectForKey:AKCB_SENT_KEY_VALUE];
    
    if ([self.foundIdentifiersToServiceUUIDs objectForKey:identifier] == nil) {
        [self.foundIdentifiersToServiceUUIDs setObject:characteristic.service.UUID forKey:identifier];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(observedChangeAtKeyPath:value:identifier:context:)]) {
        [self.delegate observedChangeAtKeyPath:keyPath value:value identifier:identifier context:context];
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices {
    NSLog(@"ERROR: Services Invalidated on peripheral");
}

# pragma mark - helpers

- (CBCharacteristic *)_findReadCharacteristicForIdentifier:(NSString *)identifier {
    return [self _findCharacteristicWithUUID:[CBUUID UUIDWithString:@"0000"] forIdentifier:identifier];
}

- (CBCharacteristic *)_findWriteCharacteristicForIdentifier:(NSString *)identifier {
    return [self _findCharacteristicWithUUID:[CBUUID UUIDWithString:@"0001"] forIdentifier:identifier];
}

- (CBCharacteristic *)_findCharacteristicWithUUID:(CBUUID *)characteristicUuid forIdentifier:(NSString *)identifier {
    CBUUID *serviceUUID = [self.foundIdentifiersToServiceUUIDs objectForKey:identifier];
    
    for (CBService *service in self.peripheral.services) {
        if ([service.UUID isEqual:serviceUUID]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:characteristicUuid]) {
                    return characteristic;
                }
            }
        }
    }
    
    return nil;
}

- (const char *)CBUUIDToCString:(CBUUID *)UUID {
    return [[UUID.data description] cStringUsingEncoding:NSStringEncodingConversionAllowLossy];
}

- (BOOL)_isDefaultServiceUUID:(CBUUID *)UUID {
    return
        [UUID isEqual:[CBUUID UUIDWithString:kBatteryServiceUUIDString]] ||
        [UUID isEqual:[CBUUID UUIDWithString:kAlertServiceUUIDString]] ||
        [UUID isEqual:[CBUUID UUIDWithString:kTimeServiceUUIDString]];
}

- (BOOL)_isReadCharacteristicUUID:(CBUUID *)UUID {
    return [UUID isEqual:[CBUUID UUIDWithString:@"0000"]];
}

- (BOOL)_isWriteCharacteristicUUID:(CBUUID *)UUID {
    return [UUID isEqual:[CBUUID UUIDWithString:@"0001"]];
}

- (BOOL)_isNotifyCharacteristicUUID:(CBUUID *)UUID {
    return [UUID isEqual:[CBUUID UUIDWithString:@"0002"]];
}

@end
