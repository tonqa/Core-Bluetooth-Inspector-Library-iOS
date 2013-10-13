//
//  AKCBKeyValueStoreConstants.h
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 12.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#ifndef AKCBKeyValueStore_AKCBKeyValueStoreConstants_h
#define AKCBKeyValueStore_AKCBKeyValueStoreConstants_h

typedef void (^AKHandlerWithoutResult)(NSError *);
typedef void (^AKHandlerWithResult)(id, NSError *);

#define AKCBFORMAT(STRVAL) @"%s: %@", __PRETTY_FUNCTION__, STRVAL
#define AKCBLOG(LOGVAL) NSLog(AKCBFORMAT(LOGVAL))

#define AKCB_INSPECTION_KEY_KEYPATH     @"keyPath"
#define AKCB_INSPECTION_KEY_OBJECT      @"object"
#define AKCB_INSPECTION_KEY_CONTEXT     @"context"
#define AKCB_INSPECTION_KEY_IDENTIFIER  @"identifier"
#define AKCB_INSPECTION_KEY_SERVICEUUID @"serviceUUID"

#define AKCB_SENT_KEY_SERVER    @"server"
#define AKCB_SENT_KEY_VALUE     @"value"

#endif
