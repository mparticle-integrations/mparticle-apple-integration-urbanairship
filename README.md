# mParticle Apple Kit Library

A kit is an extension to the core [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk). A kit works as a bridge between the mParticle SDK and a partner SDK. It abstracts the implementation complexity, simplifying the implementation for developers.

A kit takes care of initializing and forwarding information depending on what you've configured in [your app's dashboard](https://app.mparticle.com), so you just have to decide which kits you may use prior to submission to the App Store. You can easily include all of the kits, none of the kits, or individual kits – the choice is yours.

[![CocoaPods compatible](http://img.shields.io/badge/CocoaPods-compatible-brightgreen.png)](https://cocoapods.org/?q=mparticle)


## Installation

Please refer to installation instructions in the core mParticle Apple SDK [README](https://github.com/mParticle/mparticle-apple-sdk#get-the-sdk), or check out our [SDK Documentation](http://docs.mparticle.com/#mobile-sdk-guide) site to learn more.


## Push Registration

Push registration is not handled by the Urban Airship SDK when the passive registration setting is enabled. This prevents out-of-the-box categories from being registered automatically. 

Registering out-of-the-box categories manually can be accomplished by accessing the defaultCategories class method on MPKitUrbanAirship and setting them on the UNNotificationCenter:

```swift
    UNUserNotificationCenter.current().requestAuthorization(options: [UNAuthorizationOptions.alert]) { (success, err) in
        UNUserNotificationCenter.current().setNotificationCategories(MPKitUrbanAirship.defaultCategories())
    }
```

## Support

Questions? Give us a shout at <support@mparticle.com>


## License

This mParticle Apple Kit is available under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0). See the LICENSE file for more info.
