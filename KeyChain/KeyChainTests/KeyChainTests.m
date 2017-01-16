//
//  ICKeyChainTests.m
//  IntercambioCore
//
//  Created by Tobias Kraentzer on 31.05.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import <KeyChain/KeyChain.h>
#import <XCTest/XCTest.h>

@interface ICKeyChainTests : XCTestCase
@property (nonatomic, readwrite) NSURL *temporaryDirectoryURL;
@property (nonatomic, readwrite) NSString *keyChainServiceName;
@property (nonatomic, readwrite) ICKeyChain *keyChain;
@end

@implementation ICKeyChainTests

- (void)setUp
{
    [super setUp];

    NSString *path = NSTemporaryDirectory();
    if (path) {
        path = [path stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
        self.temporaryDirectoryURL = [[NSURL alloc] initFileURLWithPath:path];
        [[NSFileManager defaultManager] createDirectoryAtURL:self.temporaryDirectoryURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:nil];
    }

    self.keyChainServiceName = [[NSUUID UUID] UUIDString];
    self.keyChain = [[ICKeyChain alloc] initWithServiceName:self.keyChainServiceName];
}

- (void)tearDown
{
    if (self.temporaryDirectoryURL) {
        [[NSFileManager defaultManager] removeItemAtURL:self.temporaryDirectoryURL
                                                  error:nil];
        self.temporaryDirectoryURL = nil;
    }

    [[[ICKeyChain alloc] initWithServiceName:self.keyChainServiceName] removeAllItems:nil];

    [super tearDown];
}

- (void)testKeyChain
{
    NSString *keyChainServiceName = [[NSUUID UUID] UUIDString];
    ICKeyChain *keyChainA = [[ICKeyChain alloc] initWithServiceName:keyChainServiceName];
    ICKeyChain *keyChainB = [[ICKeyChain alloc] initWithServiceName:keyChainServiceName];
    XCTAssertEqual(keyChainA, keyChainB);
}

- (void)testAddAndUpdateItem
{
    ICKeyChainItem *item = [[ICKeyChainItem alloc] initWithIdentifier:@"romeo@example.com"
                                                            invisible:YES
                                                              options:@{ @"foo" : @(23) }];

    NSError *error = nil;
    BOOL success = YES;

    success = [self.keyChain addItem:item
                               error:&error];
    XCTAssertTrue(success, @"Failed to add item to key chain: %@", [error localizedDescription]);

    ICKeyChainItem *storedItem = [self.keyChain itemWithIdentifier:@"romeo@example.com"
                                                             error:&error];
    XCTAssertEqualObjects(item.identifier, storedItem.identifier);
    XCTAssertEqual(item.invisible, storedItem.invisible);
    XCTAssertEqualObjects(item.options, storedItem.options);

    ICKeyChainItem *updatedItem = [[ICKeyChainItem alloc] initWithIdentifier:@"romeo@example.com"
                                                                   invisible:NO
                                                                     options:@{ @"foo" : @(24) }];

    success = [self.keyChain updateItem:updatedItem

                                  error:&error];
    XCTAssertTrue(success, @"Failed to update item in key chain: %@", [error localizedDescription]);

    storedItem = [self.keyChain itemWithIdentifier:@"romeo@example.com"

                                             error:&error];
    XCTAssertEqualObjects(updatedItem.identifier, storedItem.identifier);
    XCTAssertEqual(updatedItem.invisible, storedItem.invisible);
    XCTAssertEqualObjects(updatedItem.options, storedItem.options);
}

- (void)testRemoveItem
{
    ICKeyChainItem *item = [[ICKeyChainItem alloc] initWithIdentifier:@"romeo@example.com"
                                                            invisible:YES
                                                              options:@{ @"foo" : @(23) }];

    NSError *error = nil;
    BOOL success = YES;

    success = [self.keyChain addItem:item
                               error:&error];
    XCTAssertTrue(success, @"Failed to add item to key chain: %@", [error localizedDescription]);

    success = [self.keyChain removeItem:item
                                  error:&error];
    XCTAssertTrue(success, @"Failed to remove item from key chain: %@", [error localizedDescription]);

    ICKeyChainItem *storedItem = [self.keyChain itemWithIdentifier:@"romeo@example.com"
                                                             error:&error];
    XCTAssertNil(storedItem);
}

- (void)testClearItems
{
    ICKeyChainItem *item1 = [[ICKeyChainItem alloc] initWithIdentifier:@"romeo@example.com"
                                                             invisible:YES
                                                               options:@{ @"foo" : @(23) }];

    ICKeyChainItem *item2 = [[ICKeyChainItem alloc] initWithIdentifier:@"juliet@example.com"
                                                             invisible:YES
                                                               options:@{ @"foo" : @(23) }];

    NSError *error = nil;
    BOOL success = YES;

    success = [self.keyChain addItem:item1
                               error:&error];
    XCTAssertTrue(success, @"Failed to add item1 to key chain: %@", [error localizedDescription]);

    success = [self.keyChain addItem:item2
                               error:&error];
    XCTAssertTrue(success, @"Failed to add item2 to key chain: %@", [error localizedDescription]);

    success = [self.keyChain removeAllItems:&error];
    XCTAssertTrue(success, @"Failed to clear items in key chain: %@", [error localizedDescription]);

    ICKeyChainItem *storedItem = [self.keyChain itemWithIdentifier:@"romeo@example.com"
                                                             error:&error];
    XCTAssertNil(storedItem);

    storedItem = [self.keyChain itemWithIdentifier:@"juliet@example.com"
                                             error:&error];
    XCTAssertNil(storedItem);
}

- (void)testManagePassword
{
    ICKeyChainItem *item = [[ICKeyChainItem alloc] initWithIdentifier:@"romeo@example.com"
                                                            invisible:YES
                                                              options:@{ @"foo" : @(23) }];

    NSError *error = nil;
    BOOL success = YES;

    success = [self.keyChain addItem:item
                               error:&error];
    XCTAssertTrue(success, @"Failed to add item to key chain: %@", [error localizedDescription]);

    NSString *password = [self.keyChain passwordForItemWithIdentifier:@"romeo@example.com"
                                                                error:&error];
    XCTAssertNil(password);

    success = [self.keyChain setPassword:@"123"
                   forItemWithIdentifier:@"romeo@example.com"
                                   error:&error];
    XCTAssertTrue(success);

    password = [self.keyChain passwordForItemWithIdentifier:@"romeo@example.com"
                                                      error:&error];
    XCTAssertEqualObjects(password, @"123");

    success = [self.keyChain setPassword:nil
                   forItemWithIdentifier:@"romeo@example.com"
                                   error:&error];
    XCTAssertTrue(success);

    password = [self.keyChain passwordForItemWithIdentifier:@"romeo@example.com"
                                                      error:&error];
    XCTAssertNil(password);
}

@end
