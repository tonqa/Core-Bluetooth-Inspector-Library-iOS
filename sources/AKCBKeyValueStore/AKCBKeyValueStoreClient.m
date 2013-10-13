//
//  AKCBKeyValueStoreClient.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreClient.h"

#import <AKCBKeyValueStore/AKCBKeyValueStoreUtils.h>

@interface AKCBKeyValueStoreClient ()

@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, retain) NSMutableDictionary *foundIdentifiersToServiceUUIDs;

@property (nonatomic, copy) AKHandlerWithResult findPeripheralsBlock;
@property (nonatomic, copy) AKHandlerWithoutResult connectPeripheralBlock;
@property (nonatomic, copy) AKHandlerWithResult readValueBlock;
@property (nonatomic, copy) AKHandlerWithoutResult writeValueBlock;

@end

@implementation AKCBKeyValueStoreClient

- (id)initWithServerName:(NSString *)serverName {
    self = [super init];
    if (self) {
        self.serverName = serverName;
        self.foundIdentifiersToServiceUUIDs = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)findPeripherals:(AKHandlerWithResult)completion {
    self.findPeripheralsBlock = completion;
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

- (void)connectToPeripheral:(CBPeripheral *)peripheral completion:(AKHandlerWithoutResult)completion {
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
            [self.centralManager scanForPeripheralsWithServices:nil options:@{
                  CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]
            }]; break;
            
        default:
            NSLog(@"%i",central.state);
            break;
    }
}

- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI {
    
    if ([RSSI floatValue] >= -45.f) {
        NSDictionary *advertisedServices = [advertisementData objectForKey:CBAdvertisementDataServiceDataKey];
        
        for (NSString *serviceUuid in advertisedServices) {
            NSDictionary *serviceDict = advertisedServices[serviceUuid];
            NSString *serviceIdentifier = [serviceDict objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
            NSString *serverName = [serviceDict objectForKey:AKCB_SENT_KEY_SERVER];
            if ([serverName isEqualToString:self.serverName]) {
                [self.foundIdentifiersToServiceUUIDs setObject:serviceUuid forKey:serviceIdentifier];
            }
        }
        
        if ([self.foundIdentifiersToServiceUUIDs count] > 0) {
            [central stopScan];
            self.peripheral = peripheral;
            if (self.findPeripheralsBlock) self.findPeripheralsBlock(peripheral, nil);
            self.findPeripheralsBlock = nil;
        }
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"Failed:%@",error);
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral {
    NSLog(@"Connected");
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:[self.foundIdentifiersToServiceUUIDs allValues]];
    
    if (self.connectPeripheralBlock) self.connectPeripheralBlock(nil);
    self.connectPeripheralBlock = nil;
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    for (CBService *service in peripheral.services){
        [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    for (CBCharacteristic *characteristic in service.characteristics){
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0002"]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

// read
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    NSDictionary *notifiedDict = [AKCBKeyValueStoreUtils deserialize:characteristic.value];
    id value = [notifiedDict objectForKey:AKCB_SENT_KEY_VALUE];
    
    if (self.readValueBlock) self.readValueBlock(value, nil);
    self.readValueBlock = nil;
    //[self.centralManager cancelPeripheralConnection:aPeripheral];
}

// write
- (void)peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    if (self.writeValueBlock) self.writeValueBlock(nil);
    self.writeValueBlock = nil;
    //[self.centralManager cancelPeripheralConnection:aPeripheral];
}

// notify
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    
    NSDictionary *notifiedDict = [AKCBKeyValueStoreUtils deserialize:characteristic.value];

    NSString *keyPath = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH];
    NSString *identifier = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
    id context = [notifiedDict objectForKey:AKCB_INSPECTION_KEY_CONTEXT];
    id value = [notifiedDict objectForKey:AKCB_SENT_KEY_VALUE];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(observedChangeAtKeyPath:value:identifier:context:)]) {
        [self.delegate observedChangeAtKeyPath:keyPath value:value identifier:identifier context:context];
    }
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

@end
