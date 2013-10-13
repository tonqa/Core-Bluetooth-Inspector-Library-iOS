//
//  AKCBKeyValueStoreServer.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreServer.h"

#import <AKCBKeyValueStore/AKCBKeyValueStoreUtils.h>

#define AKCB_INSPECTION_KEY_KEYPATH     @"keyPath"
#define AKCB_INSPECTION_KEY_OBJECT      @"object"
#define AKCB_INSPECTION_KEY_CONTEXT     @"context"
#define AKCB_INSPECTION_KEY_IDENTIFIER  @"identifier"
#define AKCB_INSPECTION_KEY_SERVICEUUID @"serviceUUID"

@interface AKCBKeyValueStoreServer ()

@property (nonatomic, strong)   NSMutableDictionary *inspectedObjects;
@property (nonatomic, strong)   CBPeripheralManager *peripheralManager;
@property (nonatomic, copy)     NSString *serverName;
@property (nonatomic, retain)   NSMutableArray *services;

@property (nonatomic, strong)   CBUUID *readCharacteristicUDID;
@property (nonatomic, strong)   CBUUID *writeCharacteristicUDID;
@property (nonatomic, strong)   CBUUID *notifyCharacteristicUDID;

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
    self.services = nil;
    self.serverName = nil;
}

- (void)continueServices {
    NSMutableArray *serviceUUIDs = [NSMutableArray array];
    for (CBMutableService *service in self.services) {
        [serviceUUIDs addObject:service.UUID];
    }
    
    [self.peripheralManager startAdvertising:@{
                                   CBAdvertisementDataLocalNameKey:self.serverName,
                                   CBAdvertisementDataServiceUUIDsKey:serviceUUIDs
                                   }];
}

- (void)pauseServices {
    [self.peripheralManager stopAdvertising];
}

# pragma mark - peripheral manager delegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn: {
            
            for (NSDictionary *inspectedObject in self.inspectedObjects) {
                CBUUID *serviceUUID = [CBUUID UUIDWithString:[AKCBKeyValueStoreUtils getUUID]];

                self.readCharacteristicUDID = [CBUUID UUIDWithString:@"0000"];
                self.writeCharacteristicUDID = [CBUUID UUIDWithString:@"0001"];
                self.notifyCharacteristicUDID = [CBUUID UUIDWithString:@"0002"];
                
                // remember the service identifier inside the inspected object dict
                NSString *objectIdentifier = [inspectedObject objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
                NSMutableDictionary *inspectedObjectDictCopy = [inspectedObject mutableCopy];
                [inspectedObjectDictCopy setObject:serviceUUID forKey:AKCB_INSPECTION_KEY_SERVICEUUID];
                [self.inspectedObjects setObject:inspectedObjectDictCopy forKey:objectIdentifier];
            
                CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];

                CBMutableCharacteristic *characteristic1 = [[CBMutableCharacteristic alloc] initWithType:self.readCharacteristicUDID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
                CBMutableCharacteristic *characteristic2 = [[CBMutableCharacteristic alloc] initWithType:self.writeCharacteristicUDID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
                CBMutableCharacteristic *characteristic3 = [[CBMutableCharacteristic alloc] initWithType:self.notifyCharacteristicUDID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
            
                service.characteristics = @[characteristic1, characteristic2, characteristic3];
                [peripheral addService:service];
            }
            
        } break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    
    [self continueServices];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
    didReceiveReadRequest:(CBATTRequest *)request {
    
    NSDictionary *object = [self _objectByServiceUuid:request.characteristic.service.UUID];
    NSString *identifier = [object objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
    request.value = [self _persistObjectWithIdentifier:identifier];
    
    [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];

}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
  didReceiveWriteRequests:(NSArray *)requests {

    for (CBATTRequest *request in requests) {
        
        NSDictionary *sentObjectDict = [AKCBKeyValueStoreUtils deserialize:request.value];
        NSDictionary *localObjectDict = [self _objectByServiceUuid:request.characteristic.service.UUID];
        [self _setValue:[sentObjectDict objectForKey:@"value"]
          forIdentifier:[localObjectDict objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER]];
        
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
}

# pragma mark - Other methods

- (id)_valueForIdentifier:(NSString *)identifier {
    NSDictionary *inspectedObjectDict = [self.inspectedObjects objectForKey:identifier];
    NSString *object = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_OBJECT];
    NSString *keyPath = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH];
    
    return [object valueForKeyPath:keyPath];
}

- (void)_setValue:(id)value forIdentifier:(NSString *)identifier {
    NSDictionary *inspectedObjectDict = [self.inspectedObjects objectForKey:identifier];
    NSString *object = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_OBJECT];
    NSString *keyPath = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH];
    
    [object setValue:value forKeyPath:keyPath];
}

- (NSData *)_persistObjectWithIdentifier:(NSString *)identifier {
    NSDictionary *inspectedObjectDict = [self.inspectedObjects objectForKey:identifier];
    NSString *keyPath = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH];
    id context = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_CONTEXT];

    NSDictionary *responseDictionary = @{
                             @"id": identifier,
                             @"keyPath": keyPath,
                             @"value": [self _valueForIdentifier:identifier],
                             @"context": context ?: [NSNull null],
                             @"server": self.serverName
                             };
    
    return [AKCBKeyValueStoreUtils serialize:responseDictionary];
}

- (NSDictionary *)_objectByServiceUuid:(CBUUID *)uuid {
    for (NSDictionary *inspectedObject in self.inspectedObjects) {
        if ([[inspectedObject objectForKey:AKCB_INSPECTION_KEY_SERVICEUUID] isEqual:uuid]) {
            return inspectedObject;
        }
    }
    return nil;
}

@end
