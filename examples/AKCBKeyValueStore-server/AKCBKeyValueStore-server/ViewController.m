//
//  ViewController.m
//  AKCBKeyValueStore-server
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import "ViewController.h"

#define CHUNK_SIZE 20

@interface ViewController ()

@end

@implementation ViewController
@synthesize Label;
@synthesize Log;

- (void)viewDidLoad
{
    [super viewDidLoad];
    perimanager = [[CBPeripheralManager alloc]initWithDelegate:self queue:nil];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOn:{
                CBUUID *sUDID = [CBUUID UUIDWithString:@"EBA38950-0D9B-4DBA-B0DF-BC7196DD44FC"];
                CBUUID *cUDID = [CBUUID UUIDWithString:@"DA18"];
                CBUUID *cUDID1 = [CBUUID UUIDWithString:@"DA17"];
                CBUUID *cUDID2 = [CBUUID UUIDWithString:@"DA16"];
            
                servicea = [[CBMutableService alloc]initWithType:sUDID primary:YES];
                characteristic = [[CBMutableCharacteristic alloc]initWithType:cUDID properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
                characteristic1 = [[CBMutableCharacteristic alloc]initWithType:cUDID1 properties:CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsWriteable];
                characteristic2 = [[CBMutableCharacteristic alloc]initWithType:cUDID2 properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
                servicea.characteristics = @[characteristic,characteristic1,characteristic2];
                [peripheral addService:servicea];
            } break;
            
        default:
            break;
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    NSDictionary *advertisingData = @{
                                      CBAdvertisementDataLocalNameKey: @"KhaosT",
                                      CBAdvertisementDataServiceUUIDsKey: @[[CBUUID UUIDWithString:@"EBA38950-0D9B-4DBA-B0DF-BC7196DD44FC"]]
                              };
    
    [peripheral startAdvertising:advertisingData];
}

// first time
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic12{
    NSDictionary *dict = @{ @"NAME": @"Khaos Tian", @"EMAIL": @"khaos.tian@gmail.com" };
    mainData = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:nil];
    [self sendDataChunkForPeripheralManager:peripheralManager];
}

// next times
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheralManager {
    [self sendDataChunkForPeripheralManager:peripheralManager];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager didReceiveReadRequest:(CBATTRequest *)request{
    NSString *mainString = [NSString stringWithFormat:@"GN123"];
    request.value = [mainString dataUsingEncoding:NSUTF8StringEncoding];
    [peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
}

- (void)peripheralManager:(CBPeripheralManager *)peripheralManager didReceiveWriteRequests:(NSArray *)requests{
    for (CBATTRequest *aReq in requests){
        NSString *text = [[NSString alloc] initWithData:aReq.value encoding:NSUTF8StringEncoding];
        Log.text = [Log.text stringByAppendingFormat:@"%@ \n", text];
        [peripheralManager respondToRequest:aReq withResult:CBATTErrorSuccess];
    }
}

# pragma mark - Others

- (void)sendDataChunkForPeripheralManager:(CBPeripheralManager *)peripheralManager {
    while ([self hasData]) {
        if ([peripheralManager updateValue:[self getNextData] forCharacteristic:characteristic onSubscribedCentrals:nil]){
            [self updateRestData];
        } else return;
    }
}

- (BOOL)hasData {
    return [mainData length] > 0;
}

- (void)updateRestData {
    mainData = ([mainData length] < CHUNK_SIZE) ? nil : [mainData subdataWithRange:range];
}

- (NSData *)getNextData {
    range = NSMakeRange(CHUNK_SIZE, [mainData length] - CHUNK_SIZE);
    return [mainData subdataWithRange: NSMakeRange(0, MIN([mainData length], CHUNK_SIZE))];
}

- (void)willEnterBackgroud{
    [perimanager stopAdvertising];
    [centmanager stopScan];
}

- (void)willBacktoForeground{
    NSDictionary *advertisingData = @{CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:@"EBA38950-0D9B-4DBA-B0DF-BC7196DD44FC"]]};
    [perimanager startAdvertising:advertisingData];
    [centmanager scanForPeripheralsWithServices:nil options:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end