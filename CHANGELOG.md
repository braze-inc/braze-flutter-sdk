## 8.1.0

##### Added
- Updates the native iOS bridge [from Braze Swift SDK 7.2.0 to 7.3.0](https://github.com/braze-inc/braze-swift-sdk/compare/7.2.0...7.3.0#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).

## 8.0.0

##### Breaking
- Updates the native Android bridge [from Braze Android SDK 27.0.1 to 29.0.1](https://github.com/braze-inc/braze-android-sdk/compare/v27.0.0...v29.0.1#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).
- Updates the native iOS bridge [from Braze Swift SDK 6.6.1 to 7.2.0](https://github.com/braze-inc/braze-swift-sdk/compare/6.6.1...7.2.0#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).
- Modifies the behavior for Feature Flags methods.
  - `BrazePlugin.getFeatureFlagByID(String id)` will now return `null` if the feature flag does not exist.
  - `BrazePlugin.subscribeToFeatureFlags(void Function(List<BrazeFeatureFlag>) onEvent))` will only trigger in the following situations:
    - When a refresh request completes with success or failure.
    - Upon initial subscription if there was previously cached data from the current session.
- The minimum supported Android SDK version is 21.

##### Fixed
- Moved the `compileSDKVersion` for Android down to 33 to match Flutter's versioning.

## 7.0.0

##### Breaking
- Updates the native Android bridge [from Braze Android SDK 26.1.1 to 27.0.1](https://github.com/braze-inc/braze-android-sdk/blob/master/CHANGELOG.md#2701).
- Adds support for Gradle 8.

##### Added
- Updates the native iOS bridge [from Braze Swift SDK 6.3.0 to 6.6.1](https://github.com/braze-inc/braze-swift-sdk/compare/6.3.0...6.6.1#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).
- Adds `BrazePlugin.logFeatureFlagImpression(String id)` to log a Feature Flag impression.
- Adds support for custom user attributes to be nested objects.
  - `BrazeUser.setNestedCustomUserAttribute()`
  - `BrazeUser.setCustomUserAttributeArrayOfObjects()`
  - You can specify that the Dictionary be merged with the existing value.
    - `BrazeUser.setNestedCustomUserAttribute(string, Map<string, dynamic>, true)`
  - See https://www.braze.com/docs/user_guide/data_and_analytics/custom_data/custom_attributes/nested_custom_attribute_support/ for more information.
- Adds `BrazeUser.setCustomUserAttributeArrayOfStrings()` to set arrays of strings as a custom attribute.
- Adds `BrazePlugin.getCachedContentCards()` to get the most recent content cards from the cache.
- Adds `BrazePlugin.registerPushToken()` to send a push token to Braze's servers.
  - Deprecates `BrazePlugin.registerAndroidPushToken()` in favor of this new method.
- Adds an example integration of iOS push notifications as well as custom scheme deep links, [universal links](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links) (iOS), and [app links](https://docs.flutter.dev/cookbook/navigation/set-up-app-links) (Android) to the Flutter sample app.

## 6.0.1

##### Fixed
- Updates the native Android bridge [from Braze Android SDK 26.1.0 to 26.1.1](https://github.com/braze-inc/braze-android-sdk/blob/master/CHANGELOG.md#2611).

## 6.0.0

##### Breaking
- Updates the native Android bridge [from Braze Android SDK 25.0.0 to 26.1.0](https://github.com/braze-inc/braze-android-sdk/compare/v25.0.0...v26.1.0#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).

##### Fixed
- Fixes an issue where `BrazeContentCard.imageAspectRatio` would always return `1` for whole-number `int` values.
  - The field `imageAspectRatio` is now a `num` type instead of a `double` type. No changes are required.

##### Added
- Added support for Braze Feature Flags.
  - `BrazePlugin.getFeatureFlagByID(String id)` - Get a single Feature Flag
  - `BrazePlugin.getAllFeatureFlags()` - Get all Feature Flags
  - `BrazePlugin.refreshFeatureFlags()` - Request a refresh of Feature Flags
  - `BrazePlugin.subscribeToFeatureFlags(void Function(List<BrazeFeatureFlag>) onEvent))` - Subscribe to Feature Flag updates
  - Feature Flag property getter methods for the following types:
    - Boolean: `featureFlag.getBooleanProperty(String key)`
    - Number: `featureFlag.getNumberProperty(String key)`
    - String: `featureFlag.getStringProperty(String key)`
- Updates the native iOS bridge [from Braze iOS SDK 6.0.0 to 6.3.0](https://github.com/braze-inc/braze-swift-sdk/compare/6.0.0...6.3.0#diff-06572a96a58dc510037d5efa622f9bec8519bc1beab13c9f251e97e657a9d4ed).

## 5.0.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 25.0.0](https://github.com/braze-inc/braze-android-sdk/blob/master/CHANGELOG.md#2500).
- The native iOS bridge uses [Braze iOS SDK 6.0.0](https://github.com/braze-inc/braze-swift-sdk/blob/main/CHANGELOG.md#600).
  - If you wish to access remote URLs for in-app messages instead of local URLs, replace your implementation of the `BrazeInAppMessageUIDelegate` method `inAppMessage(_:willPresent:view:)` with a custom implementation of `BrazeInAppMessagePresenter` or a `BrazeInAppMessageUI` subclass. This is relevant if you are caching asset URLs outside of the Braze SDK.
  - For reference, see our sample code [here](https://github.com/braze-inc/braze-flutter-sdk/blob/master/example/ios/Runner/AppDelegate.swift).

## 4.1.0

##### Fixed
- Fixes an issue in `4.0.0` where the version in `braze_plugin.podspec` was not incremented correctly.

##### Changed
- The native iOS bridge uses [Braze iOS SDK 5.12.0](https://github.com/braze-inc/braze-swift-sdk/blob/main/CHANGELOG.md#5120).

## 4.0.0

> Starting with this release, this SDK will use [Semantic Versioning](https://semver.org/).

##### Breaking
- Fixes the behavior in the iOS bridge introduced in version `3.0.0` when logging clicks for in-app messages and content cards. Calling `logClick` now only sends a click event for metrics, instead of both sending a click event as well as redirecting to the associated `url` field.
  - For instance, to log a content card click and redirect to a URL, you will need two commands:
  ```
  braze.logContentCardClicked(contentCard);

  // Your own custom implementation
  Linking.openUrl(contentCard.url);
  ```
  - This brings the iOS behavior to match version `2.x` and bring parity with Android's behavior.
- Removes `setBrazeInAppMessageCallback()` and `setBrazeContentCardsCallback()` in favor of subscribing via streams.
  - Reference our [sample app](https://github.com/braze-inc/braze-flutter-sdk/blob/master/example/lib/main.dart) for an example on how to use [`subscribeToInAppMessages()`](https://www.braze.com/docs/developer_guide/platform_integration_guides/flutter/inapp_messages/#receiving-in-app-message-data) or [`subscribeToContentCards()`](https://www.braze.com/docs/developer_guide/platform_integration_guides/flutter/content_cards/#receiving-content-card-data).

##### Changed
- The native Android bridge uses [Braze Android SDK 24.3.0](https://github.com/braze-inc/braze-android-sdk/blob/master/CHANGELOG.md#2430).
- The native iOS bridge uses [Braze iOS SDK 5.11.2](https://github.com/braze-inc/braze-swift-sdk/blob/main/CHANGELOG.md#5112).
- Improves behavior when using `replayCallbacksConfigKey` alongside having subscriptions to in-app messages or content cards via streams.

## 3.1.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 24.2.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#2420).
- The native iOS bridge uses [Braze iOS SDK 5.9.0](https://github.com/braze-inc/braze-swift-sdk/blob/main/CHANGELOG.md#590).
- The minimum iOS deployment target is 11.0.

## 3.0.1

##### Fixed
- Updates the `braze_plugin.podspec` file to statically link the iOS framework by default. This prevents the need to do a manual step when migrating to `3.x.x`.
- Fixes an issue introduced in version `2.2.0` where the content cards callback was not being called when receiving an empty list of content cards.

## 3.0.0

##### Breaking
- The native iOS bridge now uses the [new Braze Swift SDK](https://github.com/braze-inc/braze-swift-sdk), [version 5.6.4](https://github.com/braze-inc/braze-swift-sdk/blob/main/CHANGELOG.md#564).
  - The minimum iOS deployment target is 10.0.
- During migration, update your project with the following changes:
  - To initialize Braze, [follow these integration steps](https://braze-inc.github.io/braze-swift-sdk/tutorials/braze/a2-configure-braze) to create a `configuration` object. Then, add this code to complete the setup:
    ```
    let braze = BrazePlugin.initBraze(configuration)
    ```
  - To continue using `SDWebImage` as a dependency, add this line to your project's `/ios/Podfile`:
    ```
    pod 'SDWebImage', :modular_headers => true
    ```
      - Then, follow [these setup instructions](https://braze-inc.github.io/braze-swift-sdk/tutorials/braze/c3-gif-support).
  - For guidance around other changes such as receiving in-app message and content card data, reference our sample [`AppDelegate.swift`](https://github.com/braze-inc/braze-flutter-sdk/blob/master/example/ios/Runner/AppDelegate.swift).

##### Added
- Adds the `isControl` field to `BrazeContentCard`.

##### Changed
- Updates the parameter syntax for `subscribeToInAppMessages()` and `subscribeToContentCards()`.

## 2.6.1

##### Added
- Adds support to replay the `onEvent` method for queued in-app messages and content cards when subscribing via streams.
  - This feature must be enabled by setting `replayCallbacksConfigKey: true` in `customConfigs` for the `BrazePlugin`.

##### Changed
- The native Android bridge uses [Braze Android SDK 23.3.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#2330).
- Updates the parameter type for `subscribeToInAppMessages()` and `subscribeToContentCards()` to accept a `Function` instead of a `void`.

## 2.6.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 23.2.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#2320).
- The native iOS bridge uses [Braze iOS SDK 4.5.1](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#451).
- `process(inAppMessage)` is renamed to `processInAppMessage(inAppMessage)` in the iOS layer.

##### Added
- Adds the ability to subscribe to data for in-app messages and content cards via streams.
  - Use the methods `subscribeToInAppMessages()` and `subscribeToContentCards()`, respectively.

##### Changed
- Updates the iOS layer to use Swift. `BrazePlugin.h` and `BrazePlugin.m` are now consolidated to `BrazePlugin.swift`.
- Deprecates `setBrazeInAppMessageCallback()` and `setBrazeContentCardsCallback()` in favor of subscribing via streams.

## 2.5.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 21.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#2100).
- Removes `logContentCardsDisplayed()`. This method was not part of the recommended Content Cards integration and can be safely removed.

##### Added
- Adds support for the [SDK Authentication](https://www.braze.com/docs/developer_guide/platform_wide/sdk_authentication/) feature.
  - To handle authentication errors, use `setBrazeSdkAuthenticationErrorCallback()`, and use `setSdkAuthenticationSignature()` to update the signature. When calling `changeUser()`, be sure to pass in the `sdkAuthSignature` parameter.
  - Thanks @spaluchiewicz for contributing to this feature!
- Adds `setLastKnownLocation()` to set the last known location for the user.

## 2.4.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 20.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#2000).
- Removes `setAvatarImageUrl()`.

##### Changed
- The native iOS bridge uses [Braze iOS SDK 4.4.3](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#443).

## 2.3.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 17.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1700).
- The minimum supported Android SDK version is 19.
- Removes support for Android V1 Embedding APIs. Please reference [the Flutter migration guide](https://flutter.dev/docs/development/packages-and-plugins/plugin-api-migration) to update to the V2 APIs.

##### Added
- Custom events and purchases now support nested properties.
  - In addition to integers, floats, booleans, dates, or strings, a JSON object can be provided containing dictionaries of arrays or nested dictionaries. All properties combined can be up to 50 KB in total length.
- Adds the ability to restrict the Android automatic integration from natively displaying in-app messages.
  - To enable this feature, add this to your `braze.xml` configuration:
  ```
  <string name="com_braze_flutter_automatic_integration_iam_operation">DISCARD</string>
  ```
  - The available options are `DISPLAY_NOW` or `DISCARD`. If this entry is ommitted, the default is `DISPLAY_NOW`.

##### Changed
- The native iOS bridge uses [Braze iOS SDK 4.4.1](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#441).

## 2.2.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 16.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1600).
- The native iOS bridge uses [Braze iOS SDK 4.4.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#440).
- Streamlines the Android integration process to not involve any manual writing of code to automatically register for sessions, in-app messages, or Content Card updates from the native SDK.
  - To migrate, remove any manual calls to `registerActivityLifecycleCallbacks()`, `subscribeToContentCardsUpdates()`, and `setCustomInAppMessageManagerListener()`.
  - To disable this feature, set the boolean `com_braze_flutter_enable_automatic_integration_initializer` to `false` in your `braze.xml` configuration.

##### Added
- Adds the ability to set the in-app message callback and content cards callback in the constructor of `BrazePlugin`.
- Adds the option to store any in-app messages or content cards received before their callback is available and replay them once the corresponding callback is set.
  - To enable this feature, add this entry into the `customConfigs` map in the BrazePlugin constructor:
    ```
    replayCallbacksConfigKey : true
    ```
  - Thank you @JordyLangen for the contribution!
- Adds `BrazePlugin.addToSubscriptionGroup()` and `BrazePlugin.removeFromSubscriptionGroup()` to manage SMS/Email Subscription Groups.

##### Fixed
- Fixes an issue in the iOS bridge where custom events without any properties would not be logged correctly.

## 2.1.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 4.3.2](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#432).
- The native Android bridge uses [Braze Android SDK 15.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1500).

##### Added
- Adds `logContentCardsDisplayed()` to manually log an impression when displaying Content Cards in a custom UI.

## 2.0.0

##### Breaking
- Migrates the plugin to support null safety. All non-optional function parameters have been updated to be non-nullable unless otherwise specified. [Read here](https://dart.dev/null-safety) for more information about null safety.
  - Please reference [the Dart documentation](https://dart.dev/null-safety/migration-guide) when migrating your app to null safety.
  - Apps that have not yet migrated to null safety are compatible with this version as long as they are using Dart 2.12+.
  - Thanks @IchordeDionysos for contributing!
- Passing through `null` as a value for user attributes is no longer supported.
  - The only attribute that is able to be unset is `email` by passing in `null` into `setEmail`.
- The methods `logEvent` and `logPurchase` now take an optional `properties` parameter.
- The native Android bridge uses [Braze Android SDK 14.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1400).
- The minimum supported Dart version is `2.12.0`.

##### Changed
- `logEventWithProperties` and `logPurchaseWithProperties` are now deprecated in favor of `logEvent` and `logPurchase`.

## 1.5.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 4.0.2](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#402).
- The native Android bridge uses [Braze Android SDK 13.1.2](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1312).
- The minimum supported Flutter version is 1.10.0.

##### Added
- Adds a public repository for the Braze Flutter SDK here: https://github.com/braze-inc/braze-flutter-sdk.
  - We look forward to the community's feedback and are excited for any contributions!

## 1.4.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 13.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1300).
- The native iOS bridge uses [Braze iOS SDK 3.34.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3340).

##### Added
- Adds `BrazePlugin.setGoogleAdvertisingId()` to set the Google Advertising ID and the associated Ad-Tracking Enabled field for Android. This is a no-op on iOS.

##### Fixed
- Fixes an issue where the Braze Android SDK's `Appboy.setLogLevel()` method wasn't respected.

## 1.3.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 12.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1200).
- The native iOS bridge uses [Braze iOS SDK 3.31.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3310).

##### Added
- Adds support for the Braze plugin to be used with Android V2 Embedding APIs. Integrations using V1 Embedding will also continue to work.
- Allows the Android Braze plugin to be used with multiple Flutter engines.

## 1.2.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.30.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3300).

##### Added
- Allows the iOS Braze plugin to be used with multiple Flutter engines.

## 1.1.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 11.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#1100).
- The native iOS bridge uses [Braze iOS SDK 3.29.1](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3291).

## 1.0.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.27.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3270). This release adds support for iOS 14 and requires XCode 12. Please read the Braze iOS SDK changelog for details.

## 0.10.1

##### Changed
- The native iOS bridge uses [Braze iOS SDK 3.26.1](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3261).

## 0.10.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 8.1.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#810).
- The native iOS bridge uses [Braze iOS SDK 3.26.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3260).

##### Fixed
- Fixed an issue where `setBoolCustomUserAttribute` always set the attribute to `true` on iOS.

## 0.9.0

##### Breaking
- The native Android bridge uses [Braze Android SDK 7.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#700).
- The native iOS bridge uses [Braze iOS SDK 3.22.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3220).

## 0.8.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.21.3](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3213).
- The native Android bridge uses [Braze Android SDK 4.0.2](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#402).
  - If you are using a custom `IInAppMessageManagerListener`, then you will need to define new methods added to that interface in [Braze Android SDK 4.0.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#400). See the `MainActivity.kt` file of our sample app for a reference example.

## 0.7.0

##### Added
- Added `BrazePlugin.launchContentCards()` and `BrazePlugin.refreshContentCards()` to natively display and refresh Content Cards.
- Adds a Dart callback for receiving Braze Content Card data in the Flutter host app.
  - Similar to in-app messages, you will need to subscribe to Content Card updates in your native app code and pass Content Card objects to the Dart layer. Those objects will then be passed to your callback within a `List<BrazeContentCard>` instance.
  - To set the callback, call `BrazePlugin.setBrazeContentCardsCallback()` from your Flutter app with a function that takes a `List<BrazeContentCard>` instance.
    - The `BrazeContentCard` object supports a subset of fields available in the native model objects, including `description`, `title`, `image`, `url`, `extras`, and more.
  - On Android, you will need to register an `IEventSubscriber<ContentCardsUpdatedEvent>` instance and pass returned Content Card objects to the Dart layer using `BrazePlugin.processContentCards(contentCards)`.
    - See the `MainActivity.kt` file of our sample app for a reference example.
  - On iOS, you will need to create an `NSNotificationCenter` listener for `ABKContentCardsProcessedNotification` events and pass returned Content Card objects to the Dart layer using `BrazePlugin.processContentCards(contentCards)`.
    - See the `AppDelegate.swift` file of our sample app for a reference example.
- Added support for logging Content Card analytics to Braze using `BrazeContentCard` instances. See `logContentCardClicked()`, `logContentCardImpression()`, and `logContentCardDismissed()` on the `BrazePlugin` interface.

## 0.6.1

##### Fixed
- Fixed an issue where the Braze Kotlin plugin file's directory structure did not match its package structure.

## 0.6.0

##### Changed
- The native Android bridge uses [Braze Android SDK 3.8.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#380).
- Updated the native iOS bridge to [Braze iOS SDK 3.20.4](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.20.4).

## 0.5.2

**Important:** This patch updates the Braze iOS SDK Dependency from 3.20.1 to 3.20.2, which contains important bugfixes. Integrators should upgrade to this patch version. Please see the [Braze iOS SDK Changelog](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md) for more information.

##### Changed
- Updated the native iOS bridge to [Braze iOS SDK 3.20.2](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.20.2).

## 0.5.1

**Important** This release has known issues displaying HTML in-app messages. Do not upgrade to this version and upgrade to 0.5.2 and above instead. If you are using this version, you are strongly encouraged to upgrade to 0.5.2 or above if you make use of HTML in-app messages.

##### Changed
- Updated the native iOS bridge to [Braze iOS SDK 3.20.1](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.20.1).

## 0.5.0

**Important** This release has known issues displaying HTML in-app messages. Do not upgrade to this version and upgrade to 0.5.2 and above instead. If you are using this version, you are strongly encouraged to upgrade to 0.5.2 or above if you make use of HTML in-app messages.

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.20.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3200).
- **Important:** Braze iOS SDK 3.20.0 contains updated push token registration methods. We recommend upgrading to these methods as soon as possible to ensure a smooth transition as devices upgrade to iOS 13. In `application:didRegisterForRemoteNotificationsWithDeviceToken:`, replace
```
[[Appboy sharedInstance] registerPushToken:
                [NSString stringWithFormat:@"%@", deviceToken]];
```
with
```
[[Appboy sharedInstance] registerDeviceToken:deviceToken]];
```
- `registerPushToken()` was renamed to `registerAndroidPushToken()` and is now a no-op on iOS. On iOS, push tokens must now be registered through native methods.

## 0.4.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.18.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3180).
- The native Android bridge uses [Braze Android SDK 3.6.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#360).

##### Added
- Added the following new field to `BrazeInAppMessage`: `zippedAssetsUrl`.
  - Note that a known issue in the iOS plugin prevents HTML in-app messages from working reliably with the Dart in-app message callback. Android is not affected.

## 0.3.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.15.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3150).
- The native Android bridge uses [Braze Android SDK 3.5.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#350).
- Support for the Android configuration parameter `com_appboy_inapp_show_inapp_messages_automatically` has been removed.
  - To control whether an in-app message object should be displayed natively or not, create and register an instance of `IInAppMessageManagerListener` in your native Android code and implement decisioning in the `beforeInAppMessageDisplayed` method. See `MainActivity` in our sample app for an example.
- On Android, in-app message objects are no longer sent automatically to the Dart in-app message callback after calling `BrazePlugin.setBrazeInAppMessageCallback()` in your Dart code.
  - Similar to iOS, you will need to implement a delegate interface in your native app code and pass in-app message objects to the Dart layer for passing to the callback.
  - On Android, the delegate interface is `IInAppMessageManagerListener` and the method for passing objects to Dart is `BrazePlugin.processInAppMessage(inAppMessage)`.
  - See the sample `IInAppMessageManagerListener` implementation in the `MainActivity.kt` file of our sample app for an example.
  - This approach gives the integrator more flexibility in deciding when a message should be displayed natively, discarded, or passed into the Dart layer.

##### Added
- Added support for logging in-app message analytics to Braze using `BrazeInAppMessage` instances. See `logInAppMessageClicked`, `logInAppMessageImpression`, and `logInAppMessageButtonClicked` on the `BrazePlugin` interface.

## 0.2.1

##### Added
- Added the following new fields to `BrazeInAppMessage`: `imageUrl`, `useWebView`, `duration`, `clickAction`, `dismissType`, `messageType`
- Added the following new fields to `BrazeButton`: `useWebView`, `clickAction`.

## 0.2.0

##### Breaking
- The native iOS bridge uses [Braze iOS SDK 3.14.0](https://github.com/Appboy/appboy-ios-sdk/blob/master/CHANGELOG.md#3140).
- The native Android bridge uses [Braze Android SDK 3.2.1](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#321).

##### Added
- Adds `addAlias()` to the public API interface.
- Adds `requestLocationInitialization()` to the public API interface.
- Adds `getInstallTrackingId()` to the public API interface.
- Adds support for disabling native in-app message display on Android.
  - To disable automatic in-app message display, create a boolean element named `com_appboy_inapp_show_inapp_messages_automatically` in your Android app's `appboy.xml` and set it to `false`.
  - Note: Disabling automatic in-app message display was already possible for iOS. For instructions, see `README.md`.
- Adds a Dart callback for receiving Braze in-app message data in the Flutter host app.
  - Analytics are not currently supported on messages displayed through the callback.
  - To set the callback, call `BrazePlugin.setBrazeInAppMessageCallback()` from your Flutter app with a function that takes a `BrazeInAppMessage` instance.
    - The `BrazeInAppMessage` object supports a subset of fields available in the native model objects, including `uri`, `message`, `header`, `buttons`, and `extras`.
  - The callback should begin to function on Android immediately after being set.
  - On iOS, you will additionally need to implement the `ABKInAppMessageControllerDelegate` delegate as described in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/in-app_messaging/customization/#in-app-message-controller-delegate). Your `beforeInAppMessageDisplayed` delegate implementation must call `BrazePlugin.process(inAppMessage)`. For an example, see `AppDelegate.swift` in our example app.

## 0.1.1
- Formatted `braze_plugin.dart`.

## 0.1.0
- Removes the unused `dart:async` import in `braze_plugin.dart`.
- Makes `_callStringMethod` private in `braze_plugin.dart`.
- Adds basic dartdoc to the public API interface.

## 0.0.2
- Updates the version of Kotlin used by the Android plugin from `1.2.71` to `1.3.11`.

## 0.0.1
- Initial release.
- The native iOS bridge uses [Braze iOS SDK 3.12.0](https://github.com/Appboy/appboy-ios-sdk/releases/tag/3.12.0).
- The native Android bridge uses [Braze Android SDK 3.1.0](https://github.com/Appboy/appboy-android-sdk/blob/master/CHANGELOG.md#310).
