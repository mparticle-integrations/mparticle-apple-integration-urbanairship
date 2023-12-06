#import <Foundation/Foundation.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle-Apple-SDK.h>)
    #import <mParticle_Apple_SDK/mParticle-Apple-SDK.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle-Apple-SDK.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle-Apple-SDK.h>
#else
    #import "mParticle-Apple-SDK.h"
#endif

@interface MPKitUrbanAirship : NSObject <MPKitProtocol>

@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;
@property (nonatomic, unsafe_unretained, readonly) BOOL started;

/**
 * Default out-of-the-box categories.
 *
 * @note These notification categories need to be set on the current notification center to retain
 * out-of-the-box categories functionality.
 */
+ (NSSet<UNNotificationCategory *> *_Nonnull)defaultCategories;

@end
