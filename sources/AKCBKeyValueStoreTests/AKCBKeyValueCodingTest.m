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

#pragma GCC diagnostic ignored "-Wundeclared-selector"

@interface AKCBKeyValueCodingTest : XCTestCase

@property (nonatomic, retain) AKCBKeyValueStoreServer *server;
@property (nonatomic, assign) BOOL observedValue;

@end

@implementation AKCBKeyValueCodingTest

- (void)setUp
{
    [super setUp];

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

}

- (void)testObservingValues {
    id serverMock = [OCMockObject partialMockForObject:self.server];
    [serverMock inspectValueForKeyPath:@"observedValue" ofObject:self
                               options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                            identifier:@"observedValue" context:nil];

    [[serverMock expect] observeValueForKeyPath:[OCMArg any] ofObject:[OCMArg any] change:[OCMArg any] context:nil];
    
    self.observedValue = YES;
    
    [serverMock verify];
}

@end
