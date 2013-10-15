//
//  AKCBKeyValueCodingTest.m
//  AKCBKeyValueStore
//
//  Created by Alexander Koglin on 13.10.13.
//  Copyright (c) 2013 Alexander Koglin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AKCBKeyValueStore/AKCBInspection.h>
#import <OCMock/OCMock.h>

#import "AKCBUtils.h"

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@interface AKCBKeyValueCodingTest : XCTestCase

@property (nonatomic, retain) AKCBInspector *server;
@property (nonatomic, assign) BOOL observedValue;

@end

@implementation AKCBKeyValueCodingTest

- (void)setUp
{
    [super setUp];

    self.observedValue = NO;
    self.server = [[AKCBInspector alloc] initWithName:@"Test Server"];
}

- (void)tearDown
{
    self.server = nil;
    self.observedValue = NO;
    
    [super tearDown];
}

- (void)testSettingKeyPathes {
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self identifier:@"observedValue"
                                options:AKCB_READ|AKCB_WRITE|AKCB_NOTIFY context:nil];

    NSDictionary *inspectedObjectDict = [self.server performSelector:@selector(inspectedObjects)];
    NSArray *inspectedObjects = [inspectedObjectDict allValues];
    XCTAssertEqual([inspectedObjects count], (NSUInteger)1, AKCB_FORMAT(@"Inspected object was not saved"));

    NSDictionary *inspectedObject = [inspectedObjects objectAtIndex:0];
    XCTAssertEqualObjects([inspectedObject objectForKey:@"keyPath"], @"observedValue", AKCB_FORMAT(@"Inspected object's keyPath is wrong"));
    XCTAssertEqualObjects([inspectedObject objectForKey:@"object"], self, AKCB_FORMAT(@"Inspected object's pointer is wrong"));
    XCTAssertEqualObjects([inspectedObject objectForKey:@"context"], [NSNull null], AKCB_FORMAT(@"Inspected object's context is wrong"));
    XCTAssertEqualObjects([inspectedObject objectForKey:@"identifier"], @"observedValue", AKCB_FORMAT(@"Inspected object's identifier is wrong"));

    [self.server stop];
}

- (void)testObservingValues {
    id serverMock = [OCMockObject partialMockForObject:self.server];
    [[serverMock expect] observeValueForKeyPath:[OCMArg any] ofObject:[OCMArg any] change:[OCMArg any] context:nil];
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self identifier:@"observedValue"
                                options:AKCB_READ|AKCB_WRITE|AKCB_NOTIFY context:nil];
    
    self.observedValue = YES;
    
    [serverMock verify];
    [serverMock stop];
}

- (void)testReadWriteValuesForKeyPathes {
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self identifier:@"observedValue"
                                options:AKCB_READ|AKCB_WRITE|AKCB_NOTIFY context:nil];
    
    [self.server performSelector:@selector(_setValue:forIdentifier:) withObject:@(YES) withObject:@"observedValue"];
    XCTAssertEqual(self.observedValue, YES, AKCB_FORMAT(@"Observed Value must be read and changed"));

    NSNumber *value = [self.server performSelector:@selector(_valueForIdentifier:) withObject:@"observedValue"];
    XCTAssertEqual(self.observedValue, [value boolValue], AKCB_FORMAT(@"Observed Value must be read and changed"));
    
    [self.server stop];
}

- (void)testPersistingObservedObject {
    [self.server inspectValueForKeyPath:@"observedValue" ofObject:self identifier:@"observedValue"
                                options:AKCB_READ|AKCB_WRITE|AKCB_NOTIFY context:nil];
    
    NSData *persistedObject = [self.server performSelector:@selector(_persistInfoDictForIdentifier:) withObject:@"observedValue"];
    XCTAssertNotNil(persistedObject, AKCB_FORMAT(@"Persisted data should not be nil"));
    
    NSDictionary *unpersistedObject = [AKCBUtils deserialize:persistedObject];
    XCTAssertEqualObjects([unpersistedObject objectForKey:@"identifier"], @"observedValue", AKCB_FORMAT(@"Persisted data has wrong id"));
    XCTAssertEqualObjects([unpersistedObject objectForKey:@"keyPath"], @"observedValue", AKCB_FORMAT(@"Persisted data has wrong keyPath"));
    XCTAssertEqual([[unpersistedObject objectForKey:@"value"] boolValue], NO, AKCB_FORMAT(@"Persisted data has wrong value"));
    XCTAssertEqual([unpersistedObject objectForKey:@"context"], [NSNull null], AKCB_FORMAT(@"Persisted data has wrong context"));
    XCTAssertEqualObjects([unpersistedObject objectForKey:@"server"], @"Test Server", AKCB_FORMAT(@"Persisted data has wrong server"));
    
    [self.server stop];

}

@end
