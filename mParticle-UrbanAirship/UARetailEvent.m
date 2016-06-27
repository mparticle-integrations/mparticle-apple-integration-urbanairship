/*
 Copyright 2009-2015 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UARetailEvent.h"
#import "AirshipKit/AirshipLib.h"

#define kUABrowsedProductEvent @"browsed"
#define kUAAddedToCartEvent @"added_to_cart"
#define kUAStarredProductEvent @"starred_product"
#define kUASharedProductEvent @"shared_product"
#define kUAPurchasedEvent @"purchased"
#define kUARetailEventLifetimeValue @"ltv"
#define kUARetailEventIdentifier @"id"
#define kUARetailEventCategory @"category"
#define kUARetailEventDescription @"description"
#define kUARetailEventBrand @"brand"
#define kUARetailEventNewItem @"new_item"
#define kUARetailEventSource @"source"
#define kUARetailEventMedium @"medium"

@interface UARetailEvent()
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSString *source;
@property (nonatomic, copy) NSString *medium;
@property (nonatomic, assign) BOOL newItemSet;
@end

@implementation UARetailEvent

- (instancetype)initWithName:(NSString *)name
                   withValue:(NSDecimalNumber *)eventValue
                  withSource:(NSString *)source
                  withMedium:(NSString *)medium {
    self = [super init];
    if (self) {
        self.eventName = name;
        self.eventValue = eventValue;
        self.source = source;
        self.medium = medium;
    }

    return self;
}

+ (instancetype)browsedEvent {
    return [self browsedEventWithValue:nil];
}

+ (instancetype)browsedEventWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self browsedEventWithValue:decimalValue];
}

+ (instancetype)browsedEventWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUABrowsedProductEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)addedToCartEvent {
    return [self addedToCartEventWithValue:nil];
}

+ (instancetype)addedToCartEventWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self addedToCartEventWithValue:decimalValue];
}

+ (instancetype)addedToCartEventWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAAddedToCartEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)starredProductEvent {
    return [self starredProductEventWithValue:nil];
}

+ (instancetype)starredProductEventWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self starredProductEventWithValue:decimalValue];
}

+ (instancetype)starredProductEventWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAStarredProductEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)purchasedEvent {
    return [self purchasedEventWithValue:nil];
}

+ (instancetype)purchasedEventWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self purchasedEventWithValue:decimalValue];
}

+ (instancetype)purchasedEventWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUAPurchasedEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)sharedProductEvent {
    return [self sharedProductEventWithValue:nil];
}

+ (instancetype)sharedProductEventWithValueFromString:(NSString *)eventValue {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [self sharedProductEventWithValue:decimalValue];
}

+ (instancetype)sharedProductEventWithValue:(NSDecimalNumber *)eventValue {
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:eventValue
                           withSource:nil
                           withMedium:nil];
}

+ (instancetype)sharedProductEventWithSource:(NSString *)source
                                  withMedium:(NSString *)medium {
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:nil
                           withSource:source
                           withMedium:medium];
}

+ (instancetype)sharedProductEventWithValueFromString:(NSString *)eventValue
                                           withSource:(NSString *)source
                                           withMedium:(NSString *)medium {
    NSDecimalNumber *decimalValue = eventValue ? [NSDecimalNumber decimalNumberWithString:eventValue] : nil;
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:decimalValue
                           withSource:source
                           withMedium:medium];
}

+ (instancetype)sharedProductEventWithValue:(NSDecimalNumber *)eventValue
                                 withSource:(NSString *)source
                                 withMedium:(NSString *)medium {
    return [[self alloc] initWithName:kUASharedProductEvent
                            withValue:eventValue
                           withSource:source
                           withMedium:medium];
}

- (void)setEventValue:(NSDecimalNumber *)eventValue {
    if (!eventValue) {
        _eventValue = nil;
    } else {
        if ([eventValue isKindOfClass:[NSDecimalNumber class]]) {
            _eventValue = eventValue;
        } else {
            _eventValue = [NSDecimalNumber decimalNumberWithDecimal:[eventValue decimalValue]];
        }
    }
}

- (void)setIsNewItem:(BOOL)isNewItem {
    self.newItemSet = YES;
    _isNewItem = isNewItem;
}

- (UACustomEvent *)track {
    UACustomEvent *event = [UACustomEvent eventWithName:self.eventName];

    if (self.eventValue) {
        [event setEventValue:self.eventValue];
        [event setBoolProperty:YES forKey:kUARetailEventLifetimeValue];
    } else {
        [event setBoolProperty:NO forKey:kUARetailEventLifetimeValue];
    }

    if (self.transactionID) {
        [event setTransactionID:self.transactionID];
    }

    if (self.identifier) {
        [event setStringProperty:self.identifier forKey:kUARetailEventIdentifier];
    }

    if (self.category) {
        [event setStringProperty:self.category forKey:kUARetailEventCategory];
    }

    if (self.eventDescription) {
        [event setStringProperty:self.eventDescription forKey:kUARetailEventDescription];
    }

    if (self.brand) {
        [event setStringProperty:self.brand forKey:kUARetailEventBrand];
    }

    if (self.newItemSet) {
        [event setBoolProperty:self.isNewItem forKey:kUARetailEventNewItem];
    }
    if (self.source) {
        [event setStringProperty:self.source forKey:kUARetailEventSource];
    }

    if (self.medium) {
        [event setStringProperty:self.medium forKey:kUARetailEventMedium];
    }

    [[UAirship shared].analytics addEvent:event];

    return event;
}

@end
