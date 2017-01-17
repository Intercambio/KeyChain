//
//  ICKeyChain.m
//  IntercambioCore
//
//  Created by Tobias Kraentzer on 01.06.16.
//  Copyright © 2016 Tobias Kräntzer. All rights reserved.
//

#import <TargetConditionals.h>

#import "ICKeyChain.h"
#import "ICKeyChainItem.h"

NSString *_Nonnull const ICKeyChainErrorDomain = @"ICKeyChainErrorDomain";

NSString *const ICKeyChainDidAddItemNotification = @"ICKeyChainDidAddItemNotification";
NSString *const ICKeyChainDidUpdateItemNotification = @"ICKeyChainDidUpdateItemNotification";
NSString *const ICKeyChainDidRemoveItemNotification = @"ICKeyChainDidRemoveItemNotification";
NSString *const ICKeyChainDidRemoveAllItemsNotification = @"ICKeyChainDidRemoveAllItemsNotification";

NSString *const ICKeyChainItemKey = @"ICKeyChainItemKey";

@implementation ICKeyChain

#pragma mark Life-cycle

- (instancetype)init
{
    NSAssert(NO, @"Use +[ICKEyChain initWithServiceName:];");
    return nil;
}

- (instancetype)initWithServiceName:(NSString *)serviceName
{
    static NSMutableDictionary *keyChainsByServiceName;
    static dispatch_queue_t keyChainQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyChainQueue = dispatch_queue_create("ICKeyChain", DISPATCH_QUEUE_SERIAL);
        keyChainsByServiceName = [[NSMutableDictionary alloc] init];
    });

    __block ICKeyChain *keyChain = nil;

    dispatch_sync(keyChainQueue, ^{
        keyChain = [keyChainsByServiceName objectForKey:serviceName];
        if (keyChain == nil) {
            keyChain = [super init];
            if (keyChain) {
                _serviceName = serviceName;
            }
            [keyChainsByServiceName setObject:keyChain forKey:serviceName];
        }
    });
    self = keyChain;

    return self;
}

- (NSArray<ICKeyChainItem *> *)items:(NSError **)error
{
    return [[self class] fetchItemsFromKeyChain:self.serviceName error:error];
}

- (ICKeyChainItem *)itemWithIdentifier:(nonnull NSString *)identifier error:(NSError **)error
{
    return [[self class] itemWithIdentifier:identifier inKeyChain:self.serviceName error:error];
}

- (BOOL)addItem:(ICKeyChainItem *)item error:(NSError **)error
{
    BOOL success = [[self class] addItem:item toKeyChain:self.serviceName error:error];
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICKeyChainDidAddItemNotification
                                                            object:self
                                                          userInfo:@{ICKeyChainItemKey : item}];
    }
    return success;
}

- (BOOL)updateItem:(ICKeyChainItem *)item error:(NSError **)error
{
    BOOL success = [[self class] updateItem:item inKeyChain:self.serviceName error:error];
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICKeyChainDidUpdateItemNotification
                                                            object:self
                                                          userInfo:@{ICKeyChainItemKey : item}];
    }
    return success;
}

- (BOOL)removeItem:(ICKeyChainItem *)item error:(NSError **)error
{
    BOOL success = [[self class] removeItem:item fromKeyChain:self.serviceName error:error];
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICKeyChainDidRemoveItemNotification
                                                            object:self
                                                          userInfo:@{ICKeyChainItemKey : item}];
    }
    return success;
}

- (BOOL)removeAllItems:(NSError *__autoreleasing _Nullable *)error
{
    BOOL success = [[self class] clearKeyChain:self.serviceName error:error];
    if (success) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ICKeyChainDidRemoveAllItemsNotification
                                                            object:self];
    }
    return success;
}

- (NSString *)passwordForItemWithIdentifier:(NSString *)identifier error:(NSError **)error
{
    return [[self class] passwordForItemWithIdentifier:identifier inKeyChain:self.serviceName error:error];
}

- (BOOL)setPassword:(NSString *)password forItemWithIdentifier:(NSString *)identifier error:(NSError **)error
{
    return [[self class] setPassword:password forItemWithIdentifier:identifier inKeyChain:self.serviceName error:error];
}

#pragma mark -

+ (NSArray *)fetchItemsFromKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

    CFArrayRef _result = nil;
    OSStatus resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&_result);

    if (resultCode == errSecItemNotFound) {
        return @[];
    } else if (resultCode == noErr) {
        NSMutableArray *items = [[NSMutableArray alloc] init];
        NSArray *result = (__bridge NSArray *)_result;
        [result enumerateObjectsUsingBlock:^(NSDictionary *attributes, NSUInteger idx, BOOL *_Nonnull stop) {

            NSString *identifier = [attributes objectForKey:(__bridge id)kSecAttrAccount];

            BOOL invisible = [[attributes objectForKey:(__bridge id)kSecAttrIsInvisible] boolValue];

            NSData *optionsData = [attributes objectForKey:(__bridge id)kSecAttrGeneric];
            NSDictionary *options = optionsData ? [NSKeyedUnarchiver unarchiveObjectWithData:optionsData] : @{};

            ICKeyChainItem *item = [[ICKeyChainItem alloc] initWithIdentifier:identifier
                                                                    invisible:invisible
                                                                      options:options];

            [items addObject:item];
        }];
        CFRelease(_result);

        return items;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return nil;
    }
}

+ (ICKeyChainItem *)itemWithIdentifier:(nonnull NSString *)identifier inKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:identifier forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];

    CFDictionaryRef _result = nil;
    OSStatus resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&_result);

    if (resultCode == errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeItemNotFound userInfo:nil];
        }
        return nil;
    } else if (resultCode == noErr) {
        NSDictionary *result = (__bridge NSDictionary *)_result;

        NSString *identifier = [result objectForKey:(__bridge id)kSecAttrAccount];

        BOOL invisible = [[result objectForKey:(__bridge id)kSecAttrIsInvisible] boolValue];

        NSData *optionsData = [result objectForKey:(__bridge id)kSecAttrGeneric];
        NSDictionary *options = optionsData ? [NSKeyedUnarchiver unarchiveObjectWithData:optionsData] : @{};

        ICKeyChainItem *item = [[ICKeyChainItem alloc] initWithIdentifier:identifier
                                                                invisible:invisible
                                                                  options:options];

        CFRelease(_result);

        return item;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return nil;
    }
}

+ (BOOL)addItem:(ICKeyChainItem *)item toKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    NSData *optionsData = [NSKeyedArchiver archivedDataWithRootObject:item.options ?: @{}];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:item.identifier forKey:(__bridge id)kSecAttrAccount];
    [query setObject:@(item.invisible) forKey:(__bridge id)kSecAttrIsInvisible];
    [query setObject:optionsData forKey:(__bridge id)kSecAttrGeneric];

    OSStatus resultCode = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (resultCode == noErr) {
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return NO;
    }
}

+ (BOOL)updateItem:(ICKeyChainItem *)item inKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:item.identifier forKey:(__bridge id)kSecAttrAccount];

    NSData *optionsData = [NSKeyedArchiver archivedDataWithRootObject:item.options ?: @{}];

    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:@(item.invisible) forKey:(__bridge id)kSecAttrIsInvisible];
    [attributes setObject:optionsData forKey:(__bridge id)kSecAttrGeneric];

    OSStatus resultCode = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);

    if (resultCode == errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeItemNotFound userInfo:nil];
        }
        return NO;
    } else if (resultCode == noErr) {
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return NO;
    }
}

+ (BOOL)removeItem:(ICKeyChainItem *)item fromKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:item.identifier forKey:(__bridge id)kSecAttrAccount];

    OSStatus resultCode = SecItemDelete((__bridge CFDictionaryRef)query);

    if (resultCode == errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeItemNotFound userInfo:nil];
        }
        return NO;
    } else if (resultCode == noErr) {
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return NO;
    }
}

+ (BOOL)clearKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
#if !TARGET_OS_IPHONE
    [query setObject:(__bridge id)kSecMatchLimitAll
              forKey:(__bridge id)kSecMatchLimit];
#endif

    OSStatus resultCode = SecItemDelete((__bridge CFDictionaryRef)query);

    if (resultCode == errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeItemNotFound userInfo:nil];
        }
        return NO;
    } else if (resultCode == noErr) {
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return NO;
    }
}

+ (NSString *)passwordForItemWithIdentifier:(nonnull NSString *)identifier inKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:identifier forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

    CFDataRef _data = nil;
    OSStatus resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&_data);

    if (resultCode == errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeItemNotFound userInfo:nil];
        }
        return nil;
    } else if (resultCode == noErr) {

        NSData *data = (__bridge NSData *)_data;

        NSString *password = [data length] > 0 ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;

        if (_data) {
            CFRelease(_data);
        }
        
        if (password == nil && error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeNoPassword userInfo:nil];
        }
        return password;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return nil;
    }
}

+ (BOOL)setPassword:(NSString *)password forItemWithIdentifier:(nonnull NSString *)identifier inKeyChain:(NSString *)keyChainServiceName error:(NSError **)error
{
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];

    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:keyChainServiceName forKey:(__bridge id)kSecAttrService];
    [query setObject:identifier forKey:(__bridge id)kSecAttrAccount];

    NSData *passwordData = password ? [password dataUsingEncoding:NSUTF8StringEncoding] : [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *values = @{(__bridge id)kSecValueData : passwordData};

    __unused OSStatus resultCode = SecItemUpdate((__bridge CFDictionaryRef)query,
                                                 (__bridge CFDictionaryRef)values);

    if (resultCode == errSecItemNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeItemNotFound userInfo:nil];
        }
        return NO;
    } else if (resultCode == noErr) {
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:ICKeyChainErrorDomain code:ICKeyChainErrorCodeUndefined userInfo:nil];
        }
        return NO;
    }
}

@end
