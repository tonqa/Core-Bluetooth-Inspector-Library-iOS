//
//  AKCBKeyValueStoreServer.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "AKCBKeyValueStoreServer.h"


@interface AKCBKeyValueStoreServer ()

@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBUUID *serviceUDID;
@property (nonatomic, strong) CBUUID *valueCharactericUDID;
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
                self.serviceUDID = [CBUUID UUIDWithString:[AKCBKeyValueStoreServer getUUID]];
                self.valueCharactericUDID = [CBUUID UUIDWithString:@"VALUE"];
            }
            
            CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceUDID primary:YES];
            
            service.characteristics = @[[[CBMutableCharacteristic alloc] initWithType:self.valueCharactericUDID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsWriteable]];
            
            [peripheral addService:service];
        } break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral
            didAddService:(CBService *)service
                    error:(NSError *)error {
    
    NSDictionary *advertisingData = @{
                                      CBAdvertisementDataLocalNameKey:self.serviceName,
                                      CBAdvertisementDataServiceUUIDsKey:@[self.serviceUDID]
                                    };
    
    [peripheral startAdvertising:advertisingData];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
    didReceiveReadRequest:(CBATTRequest *)request {
    
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
  didReceiveWriteRequests:(NSArray *)requests {

}

# pragma mark - helpers

+ (NSString *)getUUID {
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * uuidString = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    
    return uuidString;
}

@end
