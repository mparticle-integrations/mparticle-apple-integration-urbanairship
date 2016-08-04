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
#import "AirshipLib.h"
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

NSString* const UAConfigAppKey = @"applicationKey";
NSString* const UAConfigAppSecret = @"applicationSecret";
NSString *const UAConfigEnableTags = @"enableTags";
NSString *const UAConfigIncludeUserAttributes = @"includeUserAttributes";

NSString* const UAChannelIdIntegrationKey = @"com.urbanairship.channel_id";

NSString * const kMPUAEventTagKey = @"eventUserTags";
NSString * const kMPUAEventAttributeTagKey = @"eventAttributeUserTags";
NSString * const kMPUAMapTypeEventClass = @"EventClass.Id";
NSString * const kMPUAMapTypeEventClassDetails = @"EventClassDetails.Id";
NSString * const kMPUAMapTypeEventAttributeClass = @"EventAttributeClass.Id";
NSString * const kMPUAMapTypeEventAttributeClassDetails = @"EventAttributeClassDetails.Id";


#pragma mark - MPUATagMapping
@interface MPUATagMapping : NSObject

@property (nonatomic, strong, readonly) NSString *mapType;
@property (nonatomic, strong, readonly) NSString *value;
@property (nonatomic, strong, readonly) NSString *mapHash;

- (instancetype)initWithConfiguration:(NSDictionary<NSString *, NSString *> *)configuration;

@end

@implementation MPUATagMapping

- (instancetype)initWithConfiguration:(NSDictionary<NSString *, NSString *> *)configuration {
    self = [super init];
    if (self) {
        _mapType = configuration[@"maptype"];
        _value = configuration[@"value"];
        _mapHash = configuration[@"map"];
    }
    
    if (!_mapType || (NSNull *)_mapType == [NSNull null] ||
        !_value || (NSNull *)_value == [NSNull null] ||
        !_mapHash || (NSNull *)_mapHash == [NSNull null])
    {
        return nil;
    } else {
        return self;
    }
}

@end


#pragma mark - MPKitUrbanAirship
@interface MPKitUrbanAirship()

@property (nonatomic, strong) NSMutableArray<MPUATagMapping *> *eventTagsMapping;
@property (nonatomic, strong) NSMutableArray<MPUATagMapping *> *eventAttributeTagsMapping;
@property (nonatomic, unsafe_unretained) BOOL enableTags;
@property (nonatomic, unsafe_unretained) BOOL includeUserAttributes;

@end


@implementation MPKitUrbanAirship

+ (NSNumber *)kitCode {
    return @25;
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
        
        NSString *auxString = configuration[UAConfigEnableTags];
        _enableTags = auxString ? [auxString boolValue] : NO;
        
        auxString = configuration[UAConfigIncludeUserAttributes];
        _includeUserAttributes = auxString ? [auxString boolValue] : NO;
        
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

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter postNotificationName:mParticleKitDidBecomeActiveNotification
                                          object:nil
                                        userInfo:userInfo];

        [notificationCenter addObserver:self
                               selector:@selector(updateChannelIntegration)
                                   name:UAChannelCreatedEvent
                                 object:nil];

        [self updateChannelIntegration];
    });
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id const)providerKitInstance {
    return [self started] ? [UAirship shared] : nil;
}

- (void)setConfiguration:(NSDictionary *)configuration {
    _configuration = configuration;
    
    // Configure event tags mapping
    
    NSString *tagMappingStr = [configuration[kMPUAEventTagKey] stringByRemovingPercentEncoding];
    NSData *tagMappingData = [tagMappingStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSArray<NSDictionary<NSString *, NSString *> *> *tagMappingConfig = nil;
    
    @try {
        tagMappingConfig = [NSJSONSerialization JSONObjectWithData:tagMappingData options:kNilOptions error:&error];
    } @catch (NSException *exception) {
    }
    
    if (tagMappingConfig && !error) {
        [self configureEventTagsMapping:tagMappingConfig];
    }

    // Configure event attribute tags mapping
    tagMappingStr = [configuration[kMPUAEventAttributeTagKey] stringByRemovingPercentEncoding];
    tagMappingData = [tagMappingStr dataUsingEncoding:NSUTF8StringEncoding];
    error = nil;
    tagMappingConfig = nil;
    
    @try {
        tagMappingConfig = [NSJSONSerialization JSONObjectWithData:tagMappingData options:kNilOptions error:&error];
    } @catch (NSException *exception) {
    }
    
    if (tagMappingConfig && !error) {
        [self configureEventAttributeTagsMapping:tagMappingConfig];
    }
}

- (NSMutableArray<MPUATagMapping *> *)eventTagsMapping {
    if (!_eventTagsMapping) {
        _eventTagsMapping = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return _eventTagsMapping;
}

- (NSMutableArray<MPUATagMapping *> *)eventAttributeTagsMapping {
    if (!_eventAttributeTagsMapping) {
        _eventAttributeTagsMapping = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return _eventAttributeTagsMapping;
}

#pragma mark e-Commerce

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                                                returnCode:MPKitReturnCodeSuccess forwardCount:0];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventClassDetails];
    NSArray<MPUATagMapping *> *eventTagMappings = [self.eventTagsMapping filteredArrayUsingPredicate:predicate];
    
    predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventAttributeClassDetails];
    NSArray<MPUATagMapping *> *eventAttributeTagMappings = [self.eventAttributeTagsMapping filteredArrayUsingPredicate:predicate];

    if ([self logAirshipRetailEventFromCommerceEvent:commerceEvent]) {
        [self setTagMappings:eventTagMappings forCommerceEvent:commerceEvent];
        [self setTagMappings:eventAttributeTagMappings forAttributesInCommerceEvent:commerceEvent];
        
        [execStatus incrementForwardCount];
    } else {
        for (MPCommerceEventInstruction *commerceEventInstruction in [commerceEvent expandedInstructions]) {
            [self logUrbanAirshipEvent:commerceEventInstruction.event];
            
            NSNumber *eventType = @(commerceEventInstruction.event.type);
            [self setTagMappings:eventTagMappings forEvent:commerceEventInstruction.event eventType:eventType];
            [self setTagMappings:eventAttributeTagMappings forAttributesInEvent:commerceEventInstruction.event eventType:eventType];

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

    // Event class tags
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventClass];
    NSArray<MPUATagMapping *> *tagMappings = [self.eventTagsMapping filteredArrayUsingPredicate:predicate];
    NSNumber *eventType = @(event.type);
    [self setTagMappings:tagMappings forEvent:event eventType:eventType];
    
    // Event attribute class tags
    predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventAttributeClass];
    tagMappings = [self.eventAttributeTagsMapping filteredArrayUsingPredicate:predicate];
    [self setTagMappings:tagMappings forAttributesInEvent:event eventType:eventType];
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [[UAirship shared].analytics trackScreen:event.name];

    // Event class detail tags
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventClassDetails];
    NSArray<MPUATagMapping *> *tagMappings = [self.eventTagsMapping filteredArrayUsingPredicate:predicate];
    NSNumber *eventType = @0; // logScreen does not have a corresponding event type
    [self setTagMappings:tagMappings forEvent:event eventType:eventType];
    
    // Event attribute class detail tags
    predicate = [NSPredicate predicateWithFormat:@"mapType == %@", kMPUAMapTypeEventAttributeClassDetails];
    tagMappings = [self.eventAttributeTagsMapping filteredArrayUsingPredicate:predicate];
    [self setTagMappings:tagMappings forAttributesInEvent:event eventType:eventType];

    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode]
                                         returnCode:MPKitReturnCodeSuccess];
}

#pragma mark User attributes and identities
- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    MPKitReturnCode returnCode;
    
    if (_enableTags) {
        NSString *uaTag = nil;
        
        if (!value || (NSNull *)value == [NSNull null] || [value isEqualToString:@""]) {
            uaTag = key;
        } else if (_includeUserAttributes) {
            uaTag = [NSString stringWithFormat:@"%@-%@", key, value];
        }
        
        if (uaTag) {
            [[UAirship push] addTag:uaTag];
            [[UAirship push] updateRegistration];
            
            returnCode = MPKitReturnCodeSuccess;
        } else {
            returnCode = MPKitReturnCodeRequirementsNotMet;
        }
    } else {
        returnCode = MPKitReturnCodeCannotExecute;
    }
    
    return [[MPKitExecStatus alloc] initWithSDKCode:[MPKitUrbanAirship kitCode] returnCode:returnCode];
}

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
    [UAirship shared].analytics.enabled = !optOut;

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
            
        default:
            return nil;
    }
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
            
        default:
            return NO;
    }
}

- (void)populateRetailEvent:(UARetailEvent *)event
              commerceEvent:(MPCommerceEvent *)commerceEvent
                    product:(MPProduct *)product {

    event.category = product.category;
    event.identifier = product.sku;
    event.eventDescription = product.name;
    event.brand = product.brand;
    event.eventValue = [NSDecimalNumber decimalNumberWithDecimal:[commerceEvent.transactionAttributes.revenue decimalValue]];
}

- (void)updateChannelIntegration  {
    NSString *channelID = [UAirship push].channelID;

    if (channelID.length) {
        NSDictionary<NSString *, NSString *> *integrationAttributes = @{UAChannelIdIntegrationKey:channelID};
        [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
    }
}

- (void)configureEventTagsMapping:(NSArray<NSDictionary<NSString *, NSString *> *> *)config {
    [config enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPUATagMapping *tagMapping = [[MPUATagMapping alloc] initWithConfiguration:obj];
        
        if (tagMapping) {
            [self.eventTagsMapping addObject:tagMapping];
        }
    }];
}

- (void)configureEventAttributeTagsMapping:(NSArray<NSDictionary<NSString *, NSString *> *> *)config {
    [config enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MPUATagMapping *tagMapping = [[MPUATagMapping alloc] initWithConfiguration:obj];
        
        if (tagMapping) {
            [self.eventAttributeTagsMapping addObject:tagMapping];
        }
    }];
}

- (NSString *)stringRepresentation:(id)value {
    NSString *stringRepresentation = nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        stringRepresentation = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        stringRepresentation = [(NSNumber *)value stringValue];
    } else if ([value isKindOfClass:[NSDate class]]) {
        stringRepresentation = [MPDateFormatter stringFromDateRFC3339:value];
    } else if ([value isKindOfClass:[NSData class]]) {
        stringRepresentation = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
    
    return stringRepresentation;
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (!tagMappings) {
        return;
    }
    
    NSString *stringToHash = [[NSString stringWithFormat:@"%@", [@([commerceEvent type]) stringValue]] lowercaseString];
    NSString *hashedString = [MPIHasher hashString:stringToHash];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
    NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];

    if (matchTagMappings.count > 0) {
        [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
            [[UAirship push] addTag:tagMapping.value];
            [[UAirship push] updateRegistration];
        }];
    }
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forEvent:(MPEvent *)event eventType:(NSNumber *)eventType {
    if (!tagMappings) {
        return;
    }
    
    NSString *stringToHash = [[NSString stringWithFormat:@"%@%@", [eventType stringValue], event.name] lowercaseString];
    NSString *hashedString = [MPIHasher hashString:stringToHash];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
    NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];

    if (matchTagMappings.count > 0) {
        [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
            [[UAirship push] addTag:tagMapping.value];
            [[UAirship push] updateRegistration];
        }];
    }
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forAttributesInCommerceEvent:(MPCommerceEvent *)commerceEvent {
    if (!tagMappings) {
        return;
    }
    
    NSDictionary *beautifiedAtrributes = [commerceEvent beautifiedAttributes];
    NSDictionary *userDefinedAttributes = [commerceEvent userDefinedAttributes];
    NSMutableDictionary<NSString *, id> *commerceEventAttributes = [[NSMutableDictionary alloc] initWithCapacity:(beautifiedAtrributes.count + userDefinedAttributes.count)];
    
    if (beautifiedAtrributes.count > 0) {
        [commerceEventAttributes addEntriesFromDictionary:beautifiedAtrributes];
    }
    
    if (userDefinedAttributes.count > 0) {
        [commerceEventAttributes addEntriesFromDictionary:userDefinedAttributes];
    }
    
    [commerceEventAttributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *stringToHash = [[NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key] lowercaseString];
        NSString *hashedString = [MPIHasher hashString:stringToHash];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
        NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];
        
        if (matchTagMappings.count > 0) {
            [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *attributeString = [self stringRepresentation:obj];

                if (attributeString) {
                    NSString *tagPlusAttributeValue = [NSString stringWithFormat:@"%@-%@", tagMapping.value, attributeString];
                    [[UAirship push] addTag:tagPlusAttributeValue];
                    [[UAirship push] addTag:tagMapping.value];
                    [[UAirship push] updateRegistration];
                }
            }];
        }
    }];
}

- (void)setTagMappings:(NSArray<MPUATagMapping *> *)tagMappings forAttributesInEvent:(MPEvent *)event eventType:(NSNumber *)eventType {
    if (!tagMappings || event.info.count == 0) {
        return;
    }
    
    NSDictionary<NSString *, id> *eventInfo = event.info;
    
    [eventInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *stringToHash = [[NSString stringWithFormat:@"%@%@%@", [eventType stringValue], event.name, key] lowercaseString];
        NSString *hashedString = [MPIHasher hashString:stringToHash];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"mapHash == %@", hashedString];
        NSArray<MPUATagMapping *> *matchTagMappings = [tagMappings filteredArrayUsingPredicate:predicate];

        if (matchTagMappings.count > 0) {
            [matchTagMappings enumerateObjectsUsingBlock:^(MPUATagMapping * _Nonnull tagMapping, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *attributeString = [self stringRepresentation:obj];
                
                if (attributeString) {
                    NSString *tagPlusAttributeValue = [NSString stringWithFormat:@"%@-%@", tagMapping.value, attributeString];
                    [[UAirship push] addTag:tagPlusAttributeValue];
                    [[UAirship push] addTag:tagMapping.value];
                    [[UAirship push] updateRegistration];
                }
            }];
        }
    }];
}

#pragma mark App Delegate Integration

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
