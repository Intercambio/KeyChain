//
//  KeyChain.h
//  KeyChain
//
//  Created by Tobias Kraentzer on 01.06.16.
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
