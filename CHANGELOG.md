## 2.0.0

##### Breaking
- This release adds null-safety.
- The new minimum Dart version is now 2.12.0.

##### Added
- The functions `logEvent` and `logPurchase` now take an optional `properties` parameter.
  This parameter can be used as a replacement for `logEventWithProperties` and `logPurchaseWithProperties`.
- The functions `logEventWithProperties` and `logPurchaseWithProperties` are now deprecated in favor of the `properties` parameter.

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
  - Note that a known issue in the iOS plugin prevents HTML IAMs from working reliably with the Dart in-app message callback. Android is not affected.

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
