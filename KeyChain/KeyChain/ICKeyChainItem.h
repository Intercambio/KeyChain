//
//  ICKeyChainItem.h
//  IntercambioCore
//
//  Created by Tobias Kraentzer on 30.05.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

@import Foundation;

@class XMPPJID;

NS_SWIFT_NAME(KeyChainItem)
@interface ICKeyChainItem : NSObject

#pragma mark Life-cycle
- (nonnull instancetype)initWithIdentifier:(nonnull NSString *)identifier
                                 invisible:(BOOL)invisible
                                   options:(nonnull NSDictionary *)options;

#pragma mark Identifier
@property (nonatomic, readonly) NSString *_Nonnull identifier;

#pragma mark Properties
@property (nonatomic, readonly) BOOL invisible;
@property (nonatomic, readonly) NSDictionary *_Nonnull options;

@end
