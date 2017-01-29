//
//  KeyChainTests.m
//  KeyChain
//
//  Created by Tobias Kraentzer on 31.05.16.
//  Copyright © 2016, 2017 Tobias Kräntzer.
//
//  This file is part of KeyChain.
//
//  KeyChain is free software: you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option)
//  any later version.
//
//  KeyChain is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
//  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with
//  KeyChain. If not, see <http://www.gnu.org/licenses/>.
//
//  Linking this library statically or dynamically with other modules is making
//  a combined work based on this library. Thus, the terms and conditions of the
//  GNU General Public License cover the whole combination.
//
//  As a special exception, the copyright holders of this library give you
//  permission to link this library with independent modules to produce an
//  executable, regardless of the license terms of these independent modules,
//  and to copy and distribute the resulting executable under terms of your
//  choice, provided that you also meet, for each linked independent module, the
//  terms and conditions of the license of that module. An independent module is
//  a module which is not derived from or based on this library. If you modify
//  this library, you must extend this exception to your version of the library.
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
