# Braze Flutter SDK

Effective marketing automation is an essential part of successfully scaling and managing your business.

This project contains the Braze
[plug-in package](https://flutter.io/developing-packages/),
a specialized package that allows integrators to use certain Braze APIs from Flutter app code written in Dart.

### Getting Started

1) Follow the directions in the [Install Tab](https://pub.dartlang.org/packages/braze_plugin#-installing-tab-) to import Braze into your project.

2) Instantiate an instance of the Braze plugin by calling `new BrazePlugin()`

#### Android

1) In your `res/values` directory, create a file called `braze.xml` and add your API key and set your custom endpoint as specified in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/android/initial_sdk_setup/android_sdk_integration/#step-2-configure-the-braze-sdk-in-brazexml).

2) Add required permissions to your `AndroidManifest`, as specified in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/android/initial_sdk_setup/android_sdk_integration/#step-3-add-required-permissions-to-android-manifest).

3) To integrate push, follow the directions in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/android/push_notifications/android/integration/standard_integration/). Note that only registration using our "automatic FCM registration" is currently supported from Flutter apps.

#### iOS

1) Call `Appboy.startWithApiKey()` in your `AppDelegate`'s `didFinishLaunchingWithOptions` delegate method as specified in our [integration steps](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/cocoapods/#step-4-updating-your-app-delegate) (via Cocoapods).

2) Set your custom endpoint as specified in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/initial_sdk_setup/cocoapods/#step-5-specify-your-data-cluster). We recommend the `Info.plist` approach.

#### In-app messages

##### Disabling automatic display

Native in-app messages display automatically out of the box on Android and iOS.

To disable automatic in-app message display for Android, implement the `IInAppMessageManagerListener` delegate as described in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/android/in-app_messaging/customization/#setting-a-custom-manager-listener). Your `beforeInAppMessageDisplayed` method implementation should return `InAppMessageOperation.DISCARD`. For an example, see `MainActivity.kt` in our example app.

To disable automatic in-app message display for iOS, implement the `ABKInAppMessageControllerDelegate` delegate as described in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/in-app_messaging/customization/#in-app-message-controller-delegate). Your `beforeInAppMessageDisplayed` delegate implementation should return `ABKInAppMessageDisplayChoice.discardInAppMessage`. For an example, see `AppDelegate.swift` in our example app.

##### In-app message data callback

You may set a callback in Dart to receive Braze in-app message data in the Flutter host app.

To set the callback, call `BrazePlugin.setBrazeInAppMessageCallback()` from your Flutter app with a function that takes a `BrazeInAppMessage` instance. The `BrazeInAppMessage` object supports a subset of fields available in the native model objects, including `uri`, `message`, `header`, `buttons`, `extras`, and more.

On Android, this callback works with no additional integration required.

On iOS, you will additionally need to implement the `ABKInAppMessageControllerDelegate` delegate as described in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/in-app_messaging/customization/#in-app-message-controller-delegate). Your `beforeInAppMessageDisplayed` delegate implementation must call `BrazePlugin.process(inAppMessage)`. For an example, see `AppDelegate.swift` in our example app.

To log analytics using your `BrazeInAppMessage`, pass the instance into the `logInAppMessageClicked`, `logInAppMessageImpression`, and `logInAppMessageButtonClicked` methods available on the main plugin interface.

> To store any in-app messages triggered before the callback available and replay them once it is set, add the following entry to the `customConfigs` map in the `BrazePlugin` constructor:
> `replayCallbacksConfigKey : true`

#### Content Cards

##### Content Card data callback

You may set a callback in Dart to receive Braze Content Card data in the Flutter host app.

To set the callback, call `BrazePlugin.setBrazeContentCardsCallback()` from your Flutter app with a function that takes a `List<BrazeContentCard>` instance. The `BrazeContentCard` object supports a subset of fields available in the native model objects, including `description`, `title`, `image`, `url`, `extras`, and more.

On Android, this callback works with no additional integration required.

On iOS, you will additionally need to create an `NSNotificationCenter` listener for `ABKContentCardsProcessedNotification` events as described in our [public documentation](https://www.braze.com/docs/developer_guide/platform_integration_guides/ios/content_cards/data_model/). Your `ABKContentCardsProcessedNotification` callback implementation must call `BrazePlugin.processContentCards(contentCards)`. For an example, see `AppDelegate.swift` in our example app.

To log analytics using your `BrazeContentCard`, pass the instance into the `logContentCardClicked`, `logContentCardImpression`, and `logContentCardDismissed` methods available on the main plugin interface. When using a custom UI, you can also log that the Content Cards feed itself was displayed with `logContentCardsDisplayed`.

> To store any content cards triggered before the callback available and replay them once it is set, add the following entry to the `customConfigs` map in the `BrazePlugin` constructor:
> `replayCallbacksConfigKey : true`

#### Push Notifications

##### Android Quickstart Setup

The following is a condensed setup guide for Firebase Android push notifications.

1. Add the Firebase Messaging dependency to your `android/app/build.gradle` file:
   ```groovy
    dependencies {
        implementation "com.appboy:android-sdk-ui:+"
        implementation "com.google.firebase:firebase-messaging:+"
    }
    apply plugin: 'com.google.gms.google-services'
   ```
2. Add the following to your `AndroidManifest.xml`:
   ```xml
    <service
      android:name="com.braze.push.BrazeFirebaseMessagingService"
      android:exported="false">
      <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
      </intent-filter>
    </service>
  ```
3. If you're using "com.google.firebase:firebase-messaging:20.3.0" or older, then you will also need to add your Firebase Sender ID to your `braze.xml`:
   ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <resources>
        <string translatable="false" name="com_braze_firebase_cloud_messaging_sender_id">YOUR-SENDER-ID</string>
    </resources>
   ```
    
