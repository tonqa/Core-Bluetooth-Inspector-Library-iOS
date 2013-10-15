//
//  AKCBKeyValueStoreConstants.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#ifndef AKCBInspection_AKCBConstants_h
#define AKCBInspection_AKCBConstants_h

typedef void (^AKHandlerWithoutResult)(NSError *);
typedef void (^AKHandlerWithResult)(id, NSError *);

#define AKCB_FORMAT(STRVAL) @"%s: %@", __PRETTY_FUNCTION__, STRVAL

#define AKCB_LOG(LOGVAL) NSLog(AKCB_FORMAT(LOGVAL))


#define AKCB_INSPECTION_KEY_KEYPATH     @"keyPath"
#define AKCB_INSPECTION_KEY_OBJECT      @"object"
#define AKCB_INSPECTION_KEY_CONTEXT     @"context"
#define AKCB_INSPECTION_KEY_IDENTIFIER  @"identifier"
#define AKCB_INSPECTION_KEY_OPTIONS     @"options"
#define AKCB_INSPECTION_KEY_SERVICEUUID @"serviceUUID"
#define AKCB_INSPECTION_KEY_SERVICE     @"service"
#define AKCB_INSPECTION_KEY_READCHARACTERISTIC   @"read"
#define AKCB_INSPECTION_KEY_WRITECHARACTERISTIC  @"write"
#define AKCB_INSPECTION_KEY_NOTIFYCHARACTERISTIC @"notify"

#define AKCB_SENT_KEY_SERVER    @"server"
#define AKCB_SENT_KEY_VALUE     @"value"

#define AKCB_READ    1
#define AKCB_WRITE   1 << 1
#define AKCB_NOTIFY  1 << 2

#endif
