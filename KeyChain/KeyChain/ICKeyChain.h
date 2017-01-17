//
//  ICKeyChain.h
//  IntercambioCore
//
//  Created by Tobias Kraentzer on 01.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

@import Foundation;

extern NSString *_Nonnull const ICKeyChainErrorDomain NS_SWIFT_NAME(KeyChainErrorDomain);

typedef NS_ENUM(NSInteger, ICKeyChainErrorCode) {
    ICKeyChainErrorCodeUndefined,
    ICKeyChainErrorCodeItemNotFound,
    ICKeyChainErrorCodeNoPassword
} NS_SWIFT_NAME(KeyChainErrorCode);

extern NSString *_Nonnull const ICKeyChainDidAddItemNotification NS_SWIFT_NAME(KeyChainDidAddItemNotification);
extern NSString *_Nonnull const ICKeyChainDidUpdateItemNotification NS_SWIFT_NAME(KeyChainDidUpdateItemNotification);
extern NSString *_Nonnull const ICKeyChainDidRemoveItemNotification NS_SWIFT_NAME(KeyChainDidRemoveItemNotification);
extern NSString *_Nonnull const ICKeyChainDidRemoveAllItemsNotification NS_SWIFT_NAME(KeyChainDidRemoveAllItemsNotification);
extern NSString *_Nonnull const ICKeyChainItemKey NS_SWIFT_NAME(KeyChainItemKey);

@class ICKeyChainItem;

NS_SWIFT_NAME(KeyChain)
@interface ICKeyChain : NSObject

- (nonnull instancetype)initWithServiceName:(nonnull NSString *)serviceName;

@property (nonatomic, readonly) NSString *_Nonnull serviceName;

- (nullable NSArray<ICKeyChainItem *> *)items:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(items());
- (nullable ICKeyChainItem *)itemWithIdentifier:(nonnull NSString *)identifier error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(item(with:));
- (BOOL)addItem:(nonnull ICKeyChainItem *)item error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(add(_:));
- (BOOL)updateItem:(nonnull ICKeyChainItem *)item error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(update(_:));
- (BOOL)removeItem:(nonnull ICKeyChainItem *)item error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(remove(_:));
- (BOOL)removeAllItems:(NSError *_Nullable *_Nullable)error;

- (nullable NSString *)passwordForItemWithIdentifier:(nonnull NSString *)identifier error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(passwordForItem(with:));
- (BOOL)setPassword:(nullable NSString *)password forItemWithIdentifier:(nonnull NSString *)identifier error:(NSError *_Nullable *_Nullable)error NS_SWIFT_NAME(setPassword(_:forItemWith:));

@end
