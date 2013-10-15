//
//  AKCBKeyValueStoreServer.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBInspector.h"

#import "AKCBUtils.h"
#import "AKCBConstants.h"

@interface AKCBInspector ()

@property (nonatomic, strong)   NSMutableDictionary *inspectedObjects;
@property (nonatomic, strong)   CBPeripheralManager *peripheralManager;
@property (nonatomic, copy)     NSString *serverName;
@property (nonatomic, retain)   NSMutableArray *services;

@property (nonatomic, strong)   CBUUID *readCharacteristicUDID;
@property (nonatomic, strong)   CBUUID *writeCharacteristicUDID;
@property (nonatomic, strong)   CBUUID *notifyCharacteristicUDID;

@end


@implementation AKCBInspector

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
    [self stop];
}

- (void)inspectValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                    identifier:(NSString *)identifier
                       options:(NSInteger)options
                       context:(id)context {
    
    NSAssert(options & AKCB_READ, @"Observed values must at least support reading.");
    
    [self.inspectedObjects setObject:@{
                                       AKCB_INSPECTION_KEY_KEYPATH: keyPath,
                                       AKCB_INSPECTION_KEY_OBJECT: object,
                                       AKCB_INSPECTION_KEY_IDENTIFIER: identifier,
                                       AKCB_INSPECTION_KEY_OPTIONS: @(options),
                                       AKCB_INSPECTION_KEY_CONTEXT: (context ?: [NSNull null])
                                       } forKey:identifier];
    
    NSKeyValueObservingOptions kvcOptions = (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld);
    [object addObserver:self forKeyPath:keyPath options:kvcOptions context:nil];
}

- (void)start {
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)stop {
    for (NSDictionary *inspectedObjectDict in [self.inspectedObjects allValues]) {
        NSObject *observedObject = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_OBJECT];
        [observedObject removeObserver:self forKeyPath:[inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH]];
    }
    
    self.inspectedObjects = nil;
    self.peripheralManager = nil;
    self.services = nil;
}

- (void)resume {
    NSMutableArray *serviceUUIDs = [NSMutableArray array];
    for (CBMutableService *service in self.services) {
        [serviceUUIDs addObject:service.UUID];
    }
    
    [self.peripheralManager startAdvertising:@{
                                               CBAdvertisementDataLocalNameKey:self.serverName,
                                               CBAdvertisementDataServiceUUIDsKey:serviceUUIDs,
                                               }];
}

- (void)pause {
    [self.peripheralManager stopAdvertising];
}

# pragma mark - peripheral manager delegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager {
    switch (peripheralManager.state) {
        case CBPeripheralManagerStatePoweredOn: {
            
            for (NSDictionary *inspectedObject in [self.inspectedObjects allValues]) {
                CBUUID *serviceUUID = [CBUUID UUIDWithString:[AKCBUtils getUUID]];
                CBMutableService *service = [[CBMutableService alloc] initWithType:serviceUUID primary:YES];
                NSMutableArray *characteristics = [NSMutableArray array];

                // remember the service identifier inside the inspected object dict
                NSString *objectIdentifier = [inspectedObject objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
                NSMutableDictionary *inspectedObjectDictCopy = [inspectedObject mutableCopy];
                [inspectedObjectDictCopy setObject:serviceUUID forKey:AKCB_INSPECTION_KEY_SERVICEUUID];
                [inspectedObjectDictCopy setObject:service forKey:AKCB_INSPECTION_KEY_SERVICE];

                // evaluate the options
                NSInteger options = [[inspectedObject objectForKey:AKCB_INSPECTION_KEY_OPTIONS] intValue];
                
                if (options & AKCB_READ) {
                    self.readCharacteristicUDID = [CBUUID UUIDWithString:@"0000"];
                    CBMutableCharacteristic *characteristic1 = [[CBMutableCharacteristic alloc] initWithType:self.readCharacteristicUDID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
                    [inspectedObjectDictCopy setObject:characteristic1 forKey:AKCB_INSPECTION_KEY_READCHARACTERISTIC];
                    [characteristics addObject:characteristic1];
                }
                
                if (options & AKCB_WRITE) {
                    self.writeCharacteristicUDID = [CBUUID UUIDWithString:@"0001"];
                    CBMutableCharacteristic *characteristic2 = [[CBMutableCharacteristic alloc] initWithType:self.writeCharacteristicUDID properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
                    [inspectedObjectDictCopy setObject:characteristic2 forKey:AKCB_INSPECTION_KEY_WRITECHARACTERISTIC];
                    [characteristics addObject:characteristic2];
                }
                
                if (options & AKCB_NOTIFY) {
                    self.notifyCharacteristicUDID = [CBUUID UUIDWithString:@"0002"];
                    CBMutableCharacteristic *characteristic3 = [[CBMutableCharacteristic alloc] initWithType:self.notifyCharacteristicUDID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
                    [inspectedObjectDictCopy setObject:characteristic3 forKey:AKCB_INSPECTION_KEY_NOTIFYCHARACTERISTIC];
                    [characteristics addObject:characteristic3];
                }
                
                [self.inspectedObjects setObject:inspectedObjectDictCopy forKey:objectIdentifier];
                service.characteristics = characteristics;
                [peripheralManager addService:service];
            }
            
        } break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    
    [self resume];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
    didReceiveReadRequest:(CBATTRequest *)request {
    
    NSDictionary *object = [self _infoDictByServiceUuid:request.characteristic.service.UUID];
    NSString *identifier = [object objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
    request.value = [self _persistInfoDictForIdentifier:identifier];
    
    [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
  didReceiveWriteRequests:(NSArray *)requests {

    for (CBATTRequest *request in requests) {
        
        // deserialize sent object
        id sentObject = [AKCBUtils deserialize:request.value];
        id valueFromSentObject = nil;
        
        // try to interpret object either as a dictionary
        // (with a value) or as a single value
        if ([sentObject isKindOfClass:[NSDictionary class]]) {
            valueFromSentObject = [sentObject objectForKey:@"value"];
        } else if ([sentObject isKindOfClass:[NSObject class]]) {
            valueFromSentObject = sentObject;
        }
        
        // assign this value to the local object
        NSDictionary *localObjectDict = [self _infoDictByServiceUuid:request.characteristic.service.UUID];
        [self _setValue:valueFromSentObject forIdentifier:[localObjectDict objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER]];
        
        [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
//    NSDictionary *inspectedObjectInfo = [self _infoDictByServiceUuid:characteristic.service.UUID];
//    [self _sendNotificationForInspectedObjectInfo:inspectedObjectInfo];
}

# pragma mark - Key Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    NSDictionary *inspectedObjectInfo = [self _infoDictByObservedObject:object keyPath:keyPath];
    [self _sendNotificationForInspectedObjectInfo:inspectedObjectInfo];
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
    return [AKCBUtils serialize:@{}];
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

- (NSData *)_persistInfoDictForIdentifier:(NSString *)identifier {
    NSDictionary *inspectedObjectDict = [self.inspectedObjects objectForKey:identifier];
    NSString *keyPath = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_KEYPATH];
    id context = [inspectedObjectDict objectForKey:AKCB_INSPECTION_KEY_CONTEXT];
    
    NSDictionary *responseDictionary = @{
                                         AKCB_INSPECTION_KEY_IDENTIFIER: identifier,
                                         AKCB_INSPECTION_KEY_KEYPATH: keyPath,
                                         AKCB_INSPECTION_KEY_CONTEXT: context ?: [NSNull null],
                                         AKCB_SENT_KEY_VALUE: [self _valueForIdentifier:identifier],
                                         AKCB_SENT_KEY_SERVER: self.serverName
                                         };
    
    return [AKCBUtils serialize:responseDictionary];
}

- (NSDictionary *)_infoDictByServiceUuid:(CBUUID *)uuid {
    for (NSDictionary *inspectedObject in [self.inspectedObjects allValues]) {
        if ([[inspectedObject objectForKey:AKCB_INSPECTION_KEY_SERVICEUUID] isEqual:uuid]) {
            return inspectedObject;
        }
    }
    return nil;
}

- (NSDictionary *)_infoDictByObservedObject:(id)object keyPath:(NSString *)keyPath {
    for (NSDictionary *inspectedObject in [self.inspectedObjects allValues]) {
        if ([inspectedObject objectForKey:AKCB_INSPECTION_KEY_OBJECT] == object &&
            [[inspectedObject objectForKey:AKCB_INSPECTION_KEY_KEYPATH] isEqual:keyPath]) {
            return inspectedObject;
        }
    }
    return nil;
}

- (void)_sendNotificationForInspectedObjectInfo:(NSDictionary *)inspectedObjectInfo {
    NSString *identifier = [inspectedObjectInfo objectForKey:AKCB_INSPECTION_KEY_IDENTIFIER];
    CBMutableCharacteristic *notifyCharacteristic = [inspectedObjectInfo objectForKey:AKCB_INSPECTION_KEY_NOTIFYCHARACTERISTIC];
    NSData *value = [self _persistInfoDictForIdentifier:identifier];
    notifyCharacteristic.value = value;
    
    if (notifyCharacteristic && value && identifier) {
        if ([notifyCharacteristic.subscribedCentrals count] > 1) {
            NSLog(@"Send notification to central");
            [self.peripheralManager updateValue:value forCharacteristic:notifyCharacteristic onSubscribedCentrals:nil];
        }
    }
}

@end
