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

#define kUrbanAirshipAppKey @"appKey"
#define kUrbanAirshipAppSecret @"appSecret"

@interface MPKitUrbanAirship()
@property (nonatomic, assign) BOOL started;
@end

@implementation MPKitUrbanAirship

+ (NSNumber *)kitCode {
    return @104;
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
        self.started = YES;

        UAConfig *config = [UAConfig defaultConfig];

        if ([MParticle sharedInstance].environment == MPEnvironmentDevelopment) {
            config.developmentAppKey = self.configuration[kUrbanAirshipAppKey];
            config.developmentAppSecret = self.configuration[kUrbanAirshipAppSecret];
            config.inProduction = NO;
        } else {
            config.productionAppKey = self.configuration[kUrbanAirshipAppKey];
            config.productionAppSecret = self.configuration[kUrbanAirshipAppSecret];
            config.inProduction = NO;
        }

        dispatch_async(dispatch_get_main_queue(), ^{

            [UAirship takeOff:config];

            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};

            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
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

#pragma mark Assorted

 - (MPKitExecStatus *)setOptOut:(BOOL)optOut {
     [UAirship shared].analytics.enabled = optOut;

     return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                          returnCode:MPKitReturnCodeSuccess];
 }

#pragma mark Helpers

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

            return true;

        case MPCommerceEventActionClick:

            for (id product in commerceEvent.products) {
                UARetailEvent *retailEvent = [UARetailEvent browsedEvent];
                [self populateRetailEvent:retailEvent commerceEvent:commerceEvent product:product];
                [retailEvent track];
            }

            return true;

        case MPCommerceEventActionAddToWishList:

            for (id product in commerceEvent.products) {
                UARetailEvent *retailEvent = [UARetailEvent starredProductEvent];
                [self populateRetailEvent:retailEvent commerceEvent:commerceEvent product:product];
                [retailEvent track];
            }

            return true;
    }

    return false;

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

@end
