//
//  ICKeyChainItem.m
//  IntercambioCore
//
//  Created by Tobias Kraentzer on 30.05.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import "ICKeyChainItem.h"

@implementation ICKeyChainItem

#pragma mark Life-cycle

- (instancetype)initWithIdentifier:(NSString *)identifier
                         invisible:(BOOL)invisible
                           options:(NSDictionary *)options
{
    self = [super init];
    if (self) {
        _identifier = identifier;
        _invisible = invisible;
        _options = [options copy];
    }
    return self;
}

#pragma mark NSObject

- (NSUInteger)hash
{
    return [_identifier hash];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ICKeyChainItem class]]) {
        return [[(ICKeyChainItem *)object identifier] isEqual:_identifier];
    } else {
        return NO;
    }
}

@end
