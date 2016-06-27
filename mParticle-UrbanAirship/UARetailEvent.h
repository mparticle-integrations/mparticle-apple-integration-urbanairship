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

#import <Foundation/Foundation.h>
#import <AirshipKit/UACustomEvent.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A UARetailEvent captures information regarding a custom retail event for
 * UAAnalytics.
 */

@interface UARetailEvent : NSObject

/**
 * Factory method for creating a browsed event.
 */
+ (instancetype)browsedEvent;

/**
 * Factory method for creating a browsed event with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)browsedEventWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating a browsed event with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)browsedEventWithValue:(nullable NSNumber *)eventValue;

/**
 * Factory method for creating an addedToCart event.
 */
+ (instancetype)addedToCartEvent;

/**
 * Factory method for creating an addedToCart event with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)addedToCartEventWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating an addedToCart event with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)addedToCartEventWithValue:(nullable NSNumber *)eventValue;

/**
 * Factory method for creating a starredProduct event.
 */
+ (instancetype)starredProductEvent;

/**
 * Factory method for creating a starredProduct event with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)starredProductEventWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating a starredProduct event with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)starredProductEventWithValue:(nullable NSNumber *)eventValue;

/**
 * Factory method for creating a purchased event.
 */
+ (instancetype)purchasedEvent;

/**
 * Factory method for creating a purchased event with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)purchasedEventWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating a purchased event with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)purchasedEventWithValue:(nullable NSNumber *)eventValue;

/**
 * Factory method for creating a sharedProduct event.
 */
+ (instancetype)sharedProductEvent;

/**
 * Factory method for creating a sharedProduct event with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)sharedProductEventWithValueFromString:(nullable NSString *)eventValue;

/**
 * Factory method for creating a sharedProduct event with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
+ (instancetype)sharedProductEventWithValue:(nullable NSNumber *)eventValue;

/**
 * Factory method for creating a sharedProduct event.
 * @param source The source as an NSString.
 * @param medium The medium as an NSString.
 */
+ (instancetype)sharedProductEventWithSource:(nullable NSString *)source
                                  withMedium:(nullable NSString *)medium;

/**
 * Factory method for creating a sharedProduct event with a value.
 *
 * @param eventValue The value of the event as as string. The value must be between
 * -2^31 and 2^31 - 1 or it will invalidate the event.
 * @param source The source as an NSString.
 * @param medium The medium as an NSString.
 */
+ (instancetype)sharedProductEventWithValueFromString:(nullable NSString *)eventValue
                                           withSource:(nullable NSString *)source
                                           withMedium:(nullable NSString *)medium;

/**
 * Factory method for creating a sharedProduct event with a value.
 *
 * @param eventValue The value of the event. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 * @param source The source as an NSString.
 * @param medium The medium as an NSString.
 */
+ (instancetype)sharedProductEventWithValue:(nullable NSNumber *)eventValue
                                 withSource:(nullable NSString *)source
                                 withMedium:(nullable NSString *)medium;

/**
 * The event's value. The value must be between -2^31 and
 * 2^31 - 1 or it will invalidate the event.
 */
@property (nonatomic, strong, nullable) NSDecimalNumber *eventValue;

/**
 * The event's transaction ID. The transaction ID's length must not exceed 255
 * characters or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *transactionID;

/**
 * The event's ID. The ID's length must not exceed 255 characters or it will
 * invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *identifier;

/**
 * The event's category. The category's length must not exceed 255 characters or
 * it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *category;

/**
 * The event's description. The description's length must not exceed 255 characters
 * or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *eventDescription;

/**
 * The event's brand. The brand's length must not exceed 255 characters
 * or it will invalidate the event.
 */
@property (nonatomic, copy, nullable) NSString *brand;

/**
 * `YES` if the product is a new item, else `NO`.
 */
@property (nonatomic, assign) BOOL isNewItem;

/**
 * Creates and track the custom account event.
 */
- (UACustomEvent *)track;

@end

NS_ASSUME_NONNULL_END
