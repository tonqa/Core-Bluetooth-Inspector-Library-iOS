//
//  AKCBKeyValueStoreServer.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreServer.h"

#import <AKCBKeyValueStore/AKCBKeyValueStoreUtils.h>

@interface AKCBKeyValueStoreServer ()

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *serviceUDID;
@property (nonatomic, strong) CBUUID *readCharacteristicUDID;
@property (nonatomic, strong) CBUUID *writeCharacteristicUDID;
@property (nonatomic, strong) CBUUID *createCharacteristicUDID;
@property (nonatomic, strong) CBUUID *deleteCharacteristicUDID;
@property (nonatomic, copy) NSString *serviceName;

@end


@implementation AKCBKeyValueStoreServer

# pragma mark - public methods

- (void)startServiceWithName:(NSString *)serviceName {
    self.serviceName = serviceName;
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)stopService {
    self.peripheralManager = nil;
    self.serviceUDID = nil;
    self.serviceName = nil;
}

- (void)continueService {
    NSDictionary *advertisingData = @{CBAdvertisementDataServiceUUIDsKey : @[self.serviceUDID]};
    [self.peripheralManager startAdvertising:advertisingData];
}

- (void)pauseService {
    [self.peripheralManager stopAdvertising];
}

# pragma mark - peripheral manager delegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:{
            if (!self.serviceUDID) {
                self.serviceUDID = [CBUUID UUIDWithString:[AKCBKeyValueStoreUtils getUUID]];
                self.readCharacteristicUDID = [CBUUID UUIDWithString:@"0000"];
                self.writeCharacteristicUDID = [CBUUID UUIDWithString:@"0001"];
                self.createCharacteristicUDID = [CBUUID UUIDWithString:@"0002"];
                self.deleteCharacteristicUDID = [CBUUID UUIDWithString:@"0003"];
            }
            
            CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceUDID primary:YES];

            CBMutableCharacteristic *characteristic1 = [[CBMutableCharacteristic alloc] initWithType:self.readCharacteristicUDID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
            CBMutableCharacteristic *characteristic2 = [[CBMutableCharacteristic alloc] initWithType:self.writeCharacteristicUDID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
            CBMutableCharacteristic *characteristic3 = [[CBMutableCharacteristic alloc] initWithType:self.createCharacteristicUDID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
            CBMutableCharacteristic *characteristic4 = [[CBMutableCharacteristic alloc] initWithType:self.deleteCharacteristicUDID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
            
            service.characteristics = @[characteristic1, characteristic2, characteristic3, characteristic4];
            
            [peripheral addService:service];
        } break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    
    [peripheral startAdvertising:@{
               CBAdvertisementDataLocalNameKey:self.serviceName,
               CBAdvertisementDataServiceUUIDsKey:@[self.serviceUDID]
               }];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
    didReceiveReadRequest:(CBATTRequest *)request {
    
    [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];

}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
  didReceiveWriteRequests:(NSArray *)requests {

    for (CBATTRequest *request in requests) {
        [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

# pragma mark - Basic functionality

- (NSArray *)_allObjectUUIDs {
    return [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
}

- (void)_setObject:(NSData *)object forUUID:(NSString *)uuid {
    [[NSUserDefaults standardUserDefaults] setObject:object forKey:uuid];
}

- (NSData *)_objectForUUID:(NSString *)uuid {
    id object = [[NSUserDefaults standardUserDefaults] objectForKey:uuid];
    return (object != [NSNull null]) ? object : nil;
}

- (void)_removeObjectForUUID:(NSString *)uuid {
    return [[NSUserDefaults standardUserDefaults] removeObjectForKey:uuid];
}

- (void)_createObjectForUUID:(NSString *)uuid {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNull null] forKey:uuid];
}

- (NSData *)_emptyObject {
    return [AKCBKeyValueStoreUtils serialize:@{}];
}

@end
