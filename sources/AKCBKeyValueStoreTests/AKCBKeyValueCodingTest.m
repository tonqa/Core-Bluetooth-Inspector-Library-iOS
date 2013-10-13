//
//  AKCBKeyValueCodingTest.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 13.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AKCBKeyValueStore/AKCBKeyValueStore.h>
#import <OCMock/OCMock.h>

#import "AKCBKeyValueStoreUtils.h"

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@interface AKCBKeyValueCodingTest : XCTestCase

@property (nonatomic, retain) AKCBKeyValueStoreServer *server;
@property (nonatomic, assign) BOOL observedValue;

@end

@implementation AKCBKeyValueCodingTest

- (void)setUp
{
    [super setUp];

    self.observedValue = NO;
    self.server = [[AKCBKeyValueStoreServer alloc] initWithName:@"Test Server"];
}

- (void)tearDown
{
    self.server = nil;
    self.observedValue = NO;
    
    [super tearDown];
}

- (void)testSettingKeyPathes {
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self
                               options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                            identifier:@"observedValue" context:nil];

    NSDictionary *inspectedObjectDict = [self.server performSelector:@selector(inspectedObjects)];
    NSArray *inspectedObjects = [inspectedObjectDict allValues];
    XCTAssertEqual([inspectedObjects count], (NSUInteger)1, AKCBFORMAT(@"Inspected object was not saved"));

    NSDictionary *inspectedObject = [inspectedObjects objectAtIndex:0];
    XCTAssertEqualObjects([inspectedObject objectForKey:@"keyPath"], @"observedValue", AKCBFORMAT(@"Inspected object's keyPath is wrong"));
    XCTAssertEqualObjects([inspectedObject objectForKey:@"object"], self, AKCBFORMAT(@"Inspected object's pointer is wrong"));
    XCTAssertEqualObjects([inspectedObject objectForKey:@"context"], [NSNull null], AKCBFORMAT(@"Inspected object's context is wrong"));
    XCTAssertEqualObjects([inspectedObject objectForKey:@"identifier"], @"observedValue", AKCBFORMAT(@"Inspected object's identifier is wrong"));

    [self.server stopServices];
}

- (void)testObservingValues {
    id serverMock = [OCMockObject partialMockForObject:self.server];
    [[serverMock expect] observeValueForKeyPath:[OCMArg any] ofObject:[OCMArg any] change:[OCMArg any] context:nil];
    [serverMock inspectValueForKeyPath:@"observedValue" ofObject:self
                               options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                            identifier:@"observedValue" context:nil];
    
    self.observedValue = YES;
    
    [serverMock verify];
    [serverMock stopServices];
}

- (void)testReadWriteValuesForKeyPathes {
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                             identifier:@"observedValue" context:nil];
    
    [self.server performSelector:@selector(_setValue:forIdentifier:) withObject:@(YES) withObject:@"observedValue"];
    XCTAssertEqual(self.observedValue, YES, AKCBFORMAT(@"Observed Value must be read and changed"));

    NSNumber *value = [self.server performSelector:@selector(_valueForIdentifier:) withObject:@"observedValue"];
    XCTAssertEqual(self.observedValue, [value boolValue], AKCBFORMAT(@"Observed Value must be read and changed"));
    
    [self.server stopServices];
}

- (void)testPersistingObservedObject {
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self
                                options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                             identifier:@"observedValue" context:nil];
    
    NSData *persistedObject = [self.server performSelector:@selector(_persistObjectWithIdentifier:) withObject:@"observedValue"];
    XCTAssertNotNil(persistedObject, AKCBFORMAT(@"Persisted data should not be nil"));
    
    NSDictionary *unpersistedObject = [AKCBKeyValueStoreUtils deserialize:persistedObject];
    XCTAssertEqualObjects([unpersistedObject objectForKey:@"id"], @"observedValue", AKCBFORMAT(@"Persisted data has wrong id"));
    XCTAssertEqualObjects([unpersistedObject objectForKey:@"keyPath"], @"observedValue", AKCBFORMAT(@"Persisted data has wrong keyPath"));
    XCTAssertEqual([[unpersistedObject objectForKey:@"value"] boolValue], NO, AKCBFORMAT(@"Persisted data has wrong value"));
    XCTAssertEqual([unpersistedObject objectForKey:@"context"], [NSNull null], AKCBFORMAT(@"Persisted data has wrong context"));
    XCTAssertEqualObjects([unpersistedObject objectForKey:@"server"], @"Test Server", AKCBFORMAT(@"Persisted data has wrong server"));
    
    [self.server stopServices];

}

@end
