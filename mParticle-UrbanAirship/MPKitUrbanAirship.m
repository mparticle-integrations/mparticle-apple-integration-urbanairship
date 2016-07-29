//
//  MPKitUrbanAirship.m
//
//  Copyright 2016 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPKitUrbanAirship.h"

#import "MPEvent.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPCommerceEventInstruction.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "MPIHasher.h"
#import "mParticle.h"
#import "MPKitRegister.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPDateFormatter.h"
#import "MPEnums.h"

#import <AirshipKit/AirshipLib.h>
#import "UARetailEvent.h"

static BOOL enableNotifications_;

NSString* const UAIdentityEmail = @"email";
NSString* const UAIdentityFacebook = @"facebook_id";
NSString* const UAIdentityTwitter = @"twitter_id";
NSString* const UAIdentityGoogle = @"google_id";
NSString* const UAIdentityMicrosoft = @"microsoft_id";
NSString* const UAIdentityYahoo = @"yahoo_id";
NSString* const UAIdentityFacebookCustomAudienceId = @"facebook_custom_audience_id";
NSString* const UAIdentityCustomer = @"customer_id";

NSString* const UAConfigAppKey = @"appKey";
NSString* const UAConfigAppSecret = @"appSecret";

@implementation MPKitUrbanAirship

+ (NSNumber *)kitCode {
    return @104;
}

+ (void)enableUserNotifications {
    if ([UAirship push]) {
        [UAirship push].userPushNotificationsEnabled = YES;
    } else {
        enableNotifications_ = YES;
    }
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Urban Airship"
                                                           className:@"MPKitUrbanAirship"
                                                    startImmediately:YES];
    [MParticle registerExtension:kitRegister];
}

#pragma mark - MPKitInstanceProtocol methods

#pragma mark Kit instance and lifecycle

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super init];

    if (self) {
        self.configuration = configuration;
        if (startImmediately) {
            [self start];
        }
    }

    return self;
}

- (void)start {
    static dispatch_once_t kitPredicate;

    dispatch_once(&kitPredicate, ^{
        _started = YES;

        UAConfig *config = [UAConfig defaultConfig];
        config.automaticSetupEnabled = NO;

        if ([MParticle sharedInstance].environment == MPEnvironmentDevelopment) {
            config.developmentAppKey = self.configuration[UAConfigAppKey];
            config.developmentAppSecret = self.configuration[UAConfigAppSecret];
            config.inProduction = NO;
        } else {
            config.productionAppKey = self.configuration[UAConfigAppKey];
            config.productionAppSecret = self.configuration[UAConfigAppSecret];
            config.inProduction = YES;
        }

        [UAirship takeOff:config];

        if (enableNotifications_) {
            [UAirship push].userPushNotificationsEnabled = YES;
        }

        [[UAirship push] updateRegistration];

        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

}

- (id const)providerKitInstance {
    if (![self started]) {
        return nil;
    }

    // Some of the more useful classes are not accessible through the UAirship instance,
    // such as push ([UAirship push]). Should we return nil?
    return [UAirship shared];
}


#pragma mark e-Commerce

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                                                returnCode:MPKitReturnCodeSuccess forwardCount:0];

    if ([self logAirshipRetailEventFromCommerceEvent:commerceEvent]) {
        [execStatus incrementForwardCount];
    } else {
        for (MPCommerceEventInstruction *commerceEventInstruction in [commerceEvent expandedInstructions]) {
            [self logUrbanAirshipEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }

    return execStatus;
}

- (MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(MPEvent *)event {
    UACustomEvent *customEvent = [UACustomEvent eventWithName:event.name
                                                        value:[NSNumber numberWithDouble:increaseAmount]];

    [[UAirship shared].analytics addEvent:customEvent];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}


#pragma mark Events

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    [self logUrbanAirshipEvent:event];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [[UAirship shared].analytics trackScreen:event.name];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark User attributes and identities

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    NSString *airshipIdentity = [self mapIdentityType:identityType];

    if (!airshipIdentity) {
        return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                             returnCode:MPKitReturnCodeUnavailable];
    }

    UAAssociatedIdentifiers *identifiers = [[UAirship shared].analytics currentAssociatedDeviceIdentifiers];
    [identifiers setValue:identityString forKey:airshipIdentity];

    [[UAirship shared].analytics associateDeviceIdentifiers:identifiers];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Assorted

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [UAirship shared].analytics.enabled = optOut;

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark Helpers

- (NSString *)mapIdentityType:(MPUserIdentity)identityType {
    switch (identityType) {
        case MPUserIdentityCustomerId:
            return UAIdentityCustomer;

        case MPUserIdentityFacebook:
            return UAIdentityFacebook;

        case MPUserIdentityTwitter:
            return UAIdentityTwitter;

        case MPUserIdentityGoogle:
            return UAIdentityGoogle;

        case MPUserIdentityMicrosoft:
            return UAIdentityMicrosoft;

        case MPUserIdentityYahoo:
            return UAIdentityYahoo;

        case MPUserIdentityEmail:
            return UAIdentityEmail;

        case MPUserIdentityFacebookCustomAudienceId:
            return UAIdentityFacebookCustomAudienceId;
    }

    return nil;
}

- (void)logUrbanAirshipEvent:(MPEvent *)event {
    UACustomEvent *customEvent = [UACustomEvent eventWithName:event.name];

    for (NSString* key in event.info) {
        [customEvent setValue:event.info[key] forKey:key];
    }

    [[UAirship shared].analytics addEvent:customEvent];
}

- (BOOL)logAirshipRetailEventFromCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (commerceEvent.products < 0) {
        return NO;
    }

    switch (commerceEvent.action) {
        case MPCommerceEventActionPurchase:

            for (id product in commerceEvent.products) {
                UARetailEvent *retailEvent = [UARetailEvent purchasedEvent];
                [self populateRetailEvent:retailEvent commerceEvent:commerceEvent product:product];
                [retailEvent track];
            }

            return YES;

        case MPCommerceEventActionAddToCart:

            for (id product in commerceEvent.products) {
                UARetailEvent *retailEvent = [UARetailEvent addedToCartEvent];
                [self populateRetailEvent:retailEvent commerceEvent:commerceEvent product:product];
                [retailEvent track];
            }

            return YES;

        case MPCommerceEventActionClick:

            for (id product in commerceEvent.products) {
                UARetailEvent *retailEvent = [UARetailEvent browsedEvent];
                [self populateRetailEvent:retailEvent commerceEvent:commerceEvent product:product];
                [retailEvent track];
            }

            return YES;

        case MPCommerceEventActionAddToWishList:

            for (id product in commerceEvent.products) {
                UARetailEvent *retailEvent = [UARetailEvent starredProductEvent];
                [self populateRetailEvent:retailEvent commerceEvent:commerceEvent product:product];
                [retailEvent track];
            }

            return YES;
    }

    return NO;
}

- (void)populateRetailEvent:(UARetailEvent *)event
              commerceEvent:(MPCommerceEvent *)commerceEvent
                    product:(MPProduct *)product {

    event.category = product.category;
    event.identifier = product.sku;
    event.eventDescription = product.name;
    event.brand = product.brand;
    event.eventValue = commerceEvent.transactionAttributes.revenue;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    // Check for UA identifiers
    if ([userInfo objectForKey:@"_"] || [userInfo objectForKey:@"com.urbanairship.metadata"]) {
        [[UAirship push] appReceivedRemoteNotification:userInfo
                                      applicationState:[UIApplication sharedApplication].applicationState];
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    [[UAirship push] appReceivedActionWithIdentifier:identifier
                                        notification:userInfo
                                    applicationState:[UIApplication sharedApplication].applicationState
                                   completionHandler:^{}];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier
                          forRemoteNotification:(NSDictionary *)userInfo
                               withResponseInfo:(NSDictionary *)responseInfo
                              completionHandler:(void (^)())completionHandler {

    [[UAirship push] appReceivedActionWithIdentifier:identifier
                                        notification:userInfo
                                        responseInfo:responseInfo
                                    applicationState:[UIApplication sharedApplication].applicationState
                                   completionHandler:completionHandler];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [[UAirship push] appRegisteredForRemoteNotificationsWithDeviceToken:deviceToken];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings {
    [[UAirship push] appRegisteredUserNotificationSettings];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

@end
