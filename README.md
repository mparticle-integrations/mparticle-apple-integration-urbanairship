## UrbanAirship Kit Integration

This repository contains the [Airship](https://www.airship.com) integration for the [mParticle Apple SDK](https://github.com/mParticle/mparticle-apple-sdk).

### Adding the integration

1. Add the kit dependency to your app's Podfile:

    ```
    pod 'mParticle-UrbanAirship', '~> 7.0'
    ```

2. Follow the mParticle iOS SDK [quick-start](https://github.com/mParticle/mparticle-apple-sdk), then rebuild and launch your app, and verify that you see `"Included kits: { UrbanAirship }"` in your Xcode console 

> (This requires your mParticle log level to be at least Debug)

3. Reference mParticle's integration docs below to enable the integration.

## Push Registration

Push registration is not handled by the Airship SDK when the passive registration setting is enabled. This prevents out-of-the-box categories from being registered automatically. 

Registering out-of-the-box categories manually can be accomplished by accessing the defaultCategories class method on MPKitUrbanAirship and setting them on the UNNotificationCenter:

```swift
    UNUserNotificationCenter.current().requestAuthorization(options: [UNAuthorizationOptions.alert]) { (success, err) in
        UNUserNotificationCenter.current().setNotificationCategories(MPKitUrbanAirship.defaultCategories())
    }
```

### Documentation

[Airship integration](https://docs.mparticle.com/integrations/airship/event/)

### License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
