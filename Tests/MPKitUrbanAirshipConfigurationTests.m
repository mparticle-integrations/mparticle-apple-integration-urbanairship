#import <XCTest/XCTest.h>
@import mParticle_UrbanAirship;

// Helper: encode a tag-mapping array to a JSON string as setConfiguration: expects.
static NSString *jsonString(NSArray *tagArray) {
    NSData *data = [NSJSONSerialization dataWithJSONObject:tagArray options:0 error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

// ─────────────────────────────────────────────────────────────────────────────
// Each tag-mapping dict must supply "maptype", "value", and "map" or
// MPUATagMapping returns nil and the entry is silently dropped.
// ─────────────────────────────────────────────────────────────────────────────

@interface MPKitUrbanAirshipConfigurationTests : XCTestCase
@end

@implementation MPKitUrbanAirshipConfigurationTests

// ── Regression: event tags must come from "eventUserTags", not "eventAttributeUserTags" ──

- (void)testEventTagsMappingIsPopulatedFromEventUserTagsKey {
    NSString *eventJSON = jsonString(@[@{@"maptype": @"EventClass.Id",
                                         @"value":   @"eventValue",
                                         @"map":     @"eventHash"}]);
    NSString *attrJSON  = jsonString(@[@{@"maptype": @"EventAttributeClass.Id",
                                         @"value":   @"attrValue",
                                         @"map":     @"attrHash"}]);

    MPKitUrbanAirship *kit = [[MPKitUrbanAirship alloc] init];
    [kit setConfiguration:@{@"eventUserTags": eventJSON,
                             @"eventAttributeUserTags": attrJSON}];

    NSArray *eventMappings = [kit valueForKey:@"eventTagsMapping"];
    NSArray *attrMappings  = [kit valueForKey:@"eventAttributeTagsMapping"];

    XCTAssertEqual(eventMappings.count, 1u, @"eventTagsMapping should have exactly one entry");
    XCTAssertEqual(attrMappings.count,  1u, @"eventAttributeTagsMapping should have exactly one entry");

    XCTAssertEqualObjects([eventMappings.firstObject valueForKey:@"value"], @"eventValue",
                          @"eventTagsMapping must be sourced from eventUserTags, not eventAttributeUserTags");
    XCTAssertEqualObjects([attrMappings.firstObject valueForKey:@"value"], @"attrValue",
                          @"eventAttributeTagsMapping must be sourced from eventAttributeUserTags");
}

// ── Both mappings must be distinct when the two keys carry different data ──

- (void)testEventTagsAndAttributeTagMappingsContainDistinctValues {
    NSString *eventJSON = jsonString(@[@{@"maptype": @"EventClass.Id",
                                         @"value":   @"eventOnly",
                                         @"map":     @"e1"}]);
    NSString *attrJSON  = jsonString(@[@{@"maptype": @"EventAttributeClass.Id",
                                         @"value":   @"attrOnly",
                                         @"map":     @"a1"}]);

    MPKitUrbanAirship *kit = [[MPKitUrbanAirship alloc] init];
    [kit setConfiguration:@{@"eventUserTags": eventJSON,
                             @"eventAttributeUserTags": attrJSON}];

    NSString *eventVal = [[kit valueForKey:@"eventTagsMapping"].firstObject valueForKey:@"value"];
    NSString *attrVal  = [[kit valueForKey:@"eventAttributeTagsMapping"].firstObject valueForKey:@"value"];

    XCTAssertNotEqualObjects(eventVal, attrVal,
                             @"eventTagsMapping and eventAttributeTagsMapping must not share data");
}

// ── Providing only eventUserTags must not populate eventAttributeTagsMapping ──

- (void)testOnlyEventUserTagsKeyPopulatesEventTagsMapping {
    NSString *eventJSON = jsonString(@[@{@"maptype": @"EventClass.Id",
                                         @"value":   @"eventOnly",
                                         @"map":     @"e1"}]);

    MPKitUrbanAirship *kit = [[MPKitUrbanAirship alloc] init];
    [kit setConfiguration:@{@"eventUserTags": eventJSON}];

    XCTAssertEqual([[kit valueForKey:@"eventTagsMapping"] count],          1u);
    XCTAssertEqual([[kit valueForKey:@"eventAttributeTagsMapping"] count], 0u);
}

// ── Providing only eventAttributeUserTags must not populate eventTagsMapping ──

- (void)testOnlyEventAttributeUserTagsKeyPopulatesEventAttributeTagsMapping {
    NSString *attrJSON = jsonString(@[@{@"maptype": @"EventAttributeClass.Id",
                                         @"value":   @"attrOnly",
                                         @"map":     @"a1"}]);

    MPKitUrbanAirship *kit = [[MPKitUrbanAirship alloc] init];
    [kit setConfiguration:@{@"eventAttributeUserTags": attrJSON}];

    XCTAssertEqual([[kit valueForKey:@"eventTagsMapping"] count],          0u);
    XCTAssertEqual([[kit valueForKey:@"eventAttributeTagsMapping"] count], 1u);
}

@end
