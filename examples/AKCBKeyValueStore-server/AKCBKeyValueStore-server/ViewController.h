//
//  ViewController.h
//  AKCBKeyValueStore-server
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CBPeripheralManagerDelegate,CBCentralManagerDelegate,CBPeripheralDelegate>{
    CBPeripheralManager *perimanager;
    CBMutableService *servicea;
    CBMutableCharacteristic *characteristic;
    CBMutableCharacteristic *characteristic1;
    CBMutableCharacteristic *characteristic2;

    CBCentralManager *centmanager;
    CBPeripheral *aCperipheral;

    NSData *mainData;
    NSRange range;
    
}
@property (weak, nonatomic) IBOutlet UILabel *Label;
@property (weak, nonatomic) IBOutlet UITextView *Log;

- (void)willEnterBackgroud;
- (void)willBacktoForeground;

@end