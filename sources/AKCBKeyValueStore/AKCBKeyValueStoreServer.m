//
//  AKCBKeyValueStoreServer.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreServer.h"

#import <AKCBKeyValueStore/AKCBKeyValueStoreUtils.h>

#define AKCB_INSPECTION_KEY_KEYPATH @"keyPath"
#define AKCB_INSPECTION_KEY_OBJECT @"object"
#define AKCB_INSPECTION_KEY_CONTEXT @"context"
#define AKCB_INSPECTION_KEY_IDENTIFIER @"identifier"

@interface AKCBKeyValueStoreServer ()

@property (nonatomic, strong) NSMutableDictionary *inspectedObjects;
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *serviceUDID;
@property (nonatomic, strong) CBUUID *readCharacteristicUDID;
@property (nonatomic, strong) CBUUID *writeCharacteristicUDID;
@property (nonatomic, strong) CBUUID *createCharacteristicUDID;
@property (nonatomic, strong) CBUUID *deleteCharacteristicUDID;
@property (nonatomic, copy) NSString *serverName;

@end


@implementation AKCBKeyValueStoreServer

# pragma mark - public methods

- (id)initWithName:(NSString *)serverName {
    self = [super init];
    if (self) {
        self.serverName = serverName;
        self.inspectedObjects = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    [self stopServices];
}

- (void)inspectValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                       options:(NSKeyValueObservingOptions)options
                    identifier:(NSString *)identifier
                       context:(id)context {
    
    [self.inspectedObjects setObject:@{
                       AKCB_INSPECTION_KEY_KEYPATH: keyPath,
                       AKCB_INSPECTION_KEY_OBJECT: object,
                       AKCB_INSPECTION_KEY_IDENTIFIER: identifier,
                       AKCB_INSPECTION_KEY_CONTEXT: (context ?: [NSNull null])
                       } forKey:identifier];
    
    [object addObserver:self forKeyPath:keyPath options:options context:nil];
}

- (void)startServices {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)stopServices {
    for (NSDictionary *inspectedObjectDict in [self.inspectedObjects allValues]) {
        NSObject *observedObject = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_OBJECT];
        [observedObject removeObserver:self forKeyPath:[inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH]];
    }
    
    self.inspectedObjects = nil;
    self.peripheralManager = nil;
    self.serviceUDID = nil;
    self.serverName = nil;
}

- (void)continueServices {
    NSDictionary *advertisingData = @{CBAdvertisementDataServiceUUIDsKey : @[self.serviceUDID]};
    [self.peripheralManager startAdvertising:advertisingData];
}

- (void)pauseServices {
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
               CBAdvertisementDataLocalNameKey:self.serverName,
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

# pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AKCBLOG(@"TEEEEEEEST");
}

@end
