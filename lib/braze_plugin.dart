import 'dart:async';
import 'dart:convert' as json;
import 'dart:io' show Platform;

import 'package:braze_plugin/braze_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/* Custom configuration keys */
const String replayCallbacksConfigKey = 'ReplayCallbacksKey';

class BrazePlugin {
  static const MethodChannel _channel = const MethodChannel('braze_plugin');
  Map<String, bool>? _brazeCustomConfigs;
  Function(BrazeSdkAuthenticationError)? _brazeSdkAuthenticationErrorHandler;

  // To be used alongside `replayCallbacksConfigKey`
  final List<BrazeInAppMessage> _queuedInAppMessages = [];
  final List<BrazeContentCard> _queuedContentCards = [];
  final List<BrazeBanner> _queuedBanners = [];
  final List<BrazePushEvent> _queuedPushEvents = [];
  final List<BrazeFeatureFlag> _queuedFeatureFlags = [];

  /// Broadcast stream to listen for in-app messages.
  StreamController<BrazeInAppMessage> inAppMessageStreamController =
      StreamController<BrazeInAppMessage>.broadcast();

  /// Broadcast stream to listen for content cards.
  StreamController<List<BrazeContentCard>> contentCardsStreamController =
      StreamController<List<BrazeContentCard>>.broadcast();

  /// Broadcast stream to listen for banners.
  StreamController<List<BrazeBanner>> bannersStreamController =
      StreamController<List<BrazeBanner>>.broadcast();

  /// Broadcast stream to listen for push notification events.
  StreamController<BrazePushEvent> pushEventStreamController =
      StreamController<BrazePushEvent>.broadcast();

  /// Broadcast stream to listen for feature flags.
  StreamController<List<BrazeFeatureFlag>> featureFlagsStreamController =
      StreamController<List<BrazeFeatureFlag>>.broadcast();

  /// The plugin used to interface with all Braze APIs with optional parameters
  /// specific customization.
  ///
  /// Each of the different handlers can subscribe to their respective streams
  /// at plugin initialization. These can also be subscribed at a later time
  /// after initialization
  BrazePlugin(
      {Function(BrazeInAppMessage)? inAppMessageHandler,
      Function(BrazeSdkAuthenticationError)? brazeSdkAuthenticationErrorHandler,
      Function(List<BrazeContentCard>)? contentCardsHandler,
      Function(List<BrazeBanner>)? bannersHandler,
      Function(List<BrazeFeatureFlag>)? featureFlagsHandler,
      Function(BrazePushEvent)? pushEventHandler,
      Map<String, bool>? customConfigs}) {
    _brazeCustomConfigs = customConfigs;
    _brazeSdkAuthenticationErrorHandler = brazeSdkAuthenticationErrorHandler;

    if (inAppMessageHandler != null) {
      subscribeToInAppMessages(inAppMessageHandler);
    }
    if (contentCardsHandler != null) {
      subscribeToContentCards(contentCardsHandler);
    }
    if (bannersHandler != null) {
      subscribeToBanners(bannersHandler);
    }
    if (featureFlagsHandler != null) {
      subscribeToFeatureFlags(featureFlagsHandler);
    }
    if (pushEventHandler != null) {
      subscribeToPushNotificationEvents(pushEventHandler);
    }

    // Called after setting up plugin settings
    _channel.setMethodCallHandler(_handleBrazeData);

    // Notify the native layer that the plugin is ready
    _setBrazePluginIsReady();
  }

  /// Subscribes to the stream of in-app messages and calls [onEvent] when it
  /// receives an in-app message.
  StreamSubscription subscribeToInAppMessages(
      void Function(BrazeInAppMessage) onEvent) {
    if (_replayCallbacksConfigEnabled() && _queuedInAppMessages.isNotEmpty) {
      print(
          "Replaying stream onEvent for previously queued Braze in-app messages.");
      _queuedInAppMessages.forEach((message) => onEvent(message));
      _queuedInAppMessages.clear();
    }

    StreamSubscription subscription =
        inAppMessageStreamController.stream.listen(onEvent);
    return subscription;
  }

  /// Subscribes to the stream of content cards and calls [onEvent] when it
  /// receives the list of content cards.
  StreamSubscription subscribeToContentCards(
      void Function(List<BrazeContentCard>) onEvent) {
    if (_replayCallbacksConfigEnabled() && _queuedContentCards.isNotEmpty) {
      print(
          "Replaying stream onEvent for previously queued Braze content cards.");
      onEvent(_queuedContentCards);
      _queuedContentCards.clear();
    }

    StreamSubscription subscription =
        contentCardsStreamController.stream.listen(onEvent);
    return subscription;
  }

  /// Subscribes to the stream of banners and calls [onEvent] when it
  /// receives the list of banners.
  StreamSubscription subscribeToBanners(
      void Function(List<BrazeBanner>) onEvent) {
    if (_replayCallbacksConfigEnabled() && _queuedBanners.isNotEmpty) {
      print("Replaying stream onEvent for previously queued BrazeBanners.");
      onEvent(_queuedBanners);
      _queuedBanners.clear();
    }

    StreamSubscription subscription =
        bannersStreamController.stream.listen(onEvent);
    return subscription;
  }

  StreamSubscription subscribeToPushNotificationEvents(
      void Function(BrazePushEvent) onEvent) {
    if (_replayCallbacksConfigEnabled() && _queuedPushEvents.isNotEmpty) {
      print(
          "Replaying stream onEvent for previously queued Braze push events.");
      _queuedPushEvents.forEach((pushEvent) => onEvent(pushEvent));
      _queuedPushEvents.clear();
    }

    StreamSubscription subscription =
        pushEventStreamController.stream.listen(onEvent);
    return subscription;
  }

  /// Sets a callback to receive in-app message data from Braze.
  void setBrazeSdkAuthenticationErrorCallback(
      Function(BrazeSdkAuthenticationError) callback) {
    _channel.invokeMethod('setSdkAuthenticationDelegate');
    _brazeSdkAuthenticationErrorHandler = callback;
  }

  /// Changes the current Braze userId.
  /// If [sdkAuthSignature] is present, passes that token to the native layer.
  ///
  /// See the Braze public docs for more info around the SDK Authentication feature.
  void changeUser(String userId, {String? sdkAuthSignature}) {
    final Map<String, dynamic> params = <String, dynamic>{
      "userId": userId,
    };
    if (sdkAuthSignature != null) {
      params["sdkAuthSignature"] = sdkAuthSignature;
    }
    _channel.invokeMethod('changeUser', params);
  }

  /// Returns a unique ID stored for the user.
  /// If the user is anonymous, there is no ID stored for the user and this method will return `null`.
  Future<String?> getUserId() {
    return _channel
        .invokeMethod('getUserId')
        .then<String?>((dynamic result) => result == null ? null : result);
  }

  void setSdkAuthenticationSignature(String? sdkAuthSignature) {
    final Map<String, dynamic> params = <String, dynamic>{
      "sdkAuthSignature": sdkAuthSignature
    };
    _channel.invokeMethod('setSdkAuthenticationSignature', params);
  }

  /// Logs a click for the provided Content Card data.
  void logContentCardClicked(BrazeContentCard contentCard) {
    final Map<String, dynamic> params = <String, dynamic>{
      "contentCardString": contentCard.contentCardJsonString
    };
    _channel.invokeMethod('logContentCardClicked', params);
  }

  /// Logs an impression for the provided Content Card data.
  void logContentCardImpression(BrazeContentCard contentCard) {
    final Map<String, dynamic> params = <String, dynamic>{
      "contentCardString": contentCard.contentCardJsonString
    };
    _channel.invokeMethod('logContentCardImpression', params);
  }

  /// Logs dismissal for the provided Content Card data.
  void logContentCardDismissed(BrazeContentCard contentCard) {
    final Map<String, dynamic> params = <String, dynamic>{
      "contentCardString": contentCard.contentCardJsonString
    };
    _channel.invokeMethod('logContentCardDismissed', params);
  }

  /// Gets a banner with the provided placement ID if available in cache, otherwise returns null.
  Future<BrazeBanner?> getBanner(String placementId) {
    final Map<String, dynamic> params = <String, dynamic>{
      "placementId": placementId
    };
    return _channel.invokeMethod('getBanner', params).then<BrazeBanner?>(
        (dynamic result) => result == null ? null : BrazeBanner(result));
  }

  /// Requests a refresh of the banners associated with the provided placement IDs.
  ///
  /// If the banners are unsuccessfully refreshed, a failure will be logged on iOS only.
  void requestBannersRefresh(List<String> placementIds) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "placementIds": placementIds,
    };

    try {
      final result =
          await _channel.invokeMethod('requestBannersRefresh', params);
      print('Success: $result');
    } catch (error) {
      print('Failure: $error');
    }
  }

  /// Logs a click for the provided in-app message data.
  void logInAppMessageClicked(BrazeInAppMessage inAppMessage) {
    final Map<String, dynamic> params = <String, dynamic>{
      "inAppMessageString": inAppMessage.inAppMessageJsonString
    };
    _channel.invokeMethod('logInAppMessageClicked', params);
  }

  /// Logs an impression for the provided in-app message data.
  void logInAppMessageImpression(BrazeInAppMessage inAppMessage) {
    final Map<String, dynamic> params = <String, dynamic>{
      "inAppMessageString": inAppMessage.inAppMessageJsonString
    };
    _channel.invokeMethod('logInAppMessageImpression', params);
  }

  /// Logs a button click for the provided in-app message button data.
  void logInAppMessageButtonClicked(
      BrazeInAppMessage inAppMessage, int buttonId) {
    final Map<String, dynamic> params = <String, dynamic>{
      "inAppMessageString": inAppMessage.inAppMessageJsonString,
      "buttonId": buttonId
    };
    _channel.invokeMethod('logInAppMessageButtonClicked', params);
  }

  /// Dismisses the currently displayed in-app message.
  void hideCurrentInAppMessage() {
    _channel.invokeMethod('hideCurrentInAppMessage');
  }

  /// Add alias for current user.
  void addAlias(String aliasName, String aliasLabel) {
    final Map<String, dynamic> params = <String, dynamic>{
      'aliasName': aliasName,
      'aliasLabel': aliasLabel
    };
    _channel.invokeMethod('addAlias', params);
  }

  /// Logs a custom event to Braze.
  void logCustomEvent(String eventName, {Map<String, dynamic>? properties}) {
    final Map<String, dynamic> params = <String, dynamic>{
      "eventName": eventName,
    };
    if (properties != null) {
      // Omits entry when properties is null
      params["properties"] = properties;
    }
    _channel.invokeMethod('logCustomEvent', params);
  }

  /// Logs a custom event to Braze.
  @Deprecated('Use logCustomEvent(eventName, properties: properties) instead.')
  void logCustomEventWithProperties(
      String eventName, Map<String, dynamic> properties) {
    final Map<String, dynamic> params = <String, dynamic>{
      "eventName": eventName,
      "properties": properties
    };
    _channel.invokeMethod('logCustomEvent', params);
  }

  /// Logs a purchase event to Braze.
  void logPurchase(
      String productId, String currencyCode, double price, int quantity,
      {Map<String, dynamic>? properties}) {
    final Map<String, dynamic> params = <String, dynamic>{
      "productId": productId,
      "currencyCode": currencyCode,
      "price": price,
      "quantity": quantity,
    };
    if (properties != null) {
      // Omits entry when properties is null
      params["properties"] = properties;
    }
    _channel.invokeMethod('logPurchase', params);
  }

  /// Logs a purchase event to Braze.
  @Deprecated(
      'Use logPurchase(productId, currencyCode, price, quantity, properties: properties) instead.')
  void logPurchaseWithProperties(String productId, String currencyCode,
      double price, int quantity, Map<String, dynamic> properties) {
    final Map<String, dynamic> params = <String, dynamic>{
      "productId": productId,
      "currencyCode": currencyCode,
      "price": price,
      "quantity": quantity,
      "properties": properties
    };
    _channel.invokeMethod('logPurchase', params);
  }

  /// Adds an element to a custom attribute array.
  void addToCustomAttributeArray(String key, String value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('addToCustomAttributeArray', params);
  }

  /// Removes an element from a custom attribute array.
  void removeFromCustomAttributeArray(String key, String value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('removeFromCustomAttributeArray', params);
  }

  /// Sets a string typed custom attribute.
  void setNestedCustomUserAttribute(String key, Map<String, dynamic> value,
      [bool merge = false]) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value,
      'merge': merge
    };
    _channel.invokeMethod('setNestedCustomUserAttribute', params);
  }

  void setCustomUserAttributeArrayOfStrings(String key, List<String> value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('setCustomUserAttributeArrayOfStrings', params);
  }

  /// Sets a string typed custom attribute.
  void setCustomUserAttributeArrayOfObjects(
      String key, List<Map<String, dynamic>> value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('setCustomUserAttributeArrayOfObjects', params);
  }

  /// Sets a string typed custom attribute.
  void setStringCustomUserAttribute(String key, String value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('setStringCustomUserAttribute', params);
  }

  /// Sets a double typed custom attribute.
  void setDoubleCustomUserAttribute(String key, double value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('setDoubleCustomUserAttribute', params);
  }

  /// Sets a boolean typed custom attribute.
  void setBoolCustomUserAttribute(String key, bool value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('setBoolCustomUserAttribute', params);
  }

  /// Sets a integer typed custom attribute.
  void setIntCustomUserAttribute(String key, int value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('setIntCustomUserAttribute', params);
  }

  /// Increments an integer typed custom attribute.
  void incrementCustomUserAttribute(String key, int value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value
    };
    _channel.invokeMethod('incrementCustomUserAttribute', params);
  }

  /// Sets a location custom attribute.
  void setLocationCustomAttribute(String key, double lat, double long) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'lat': lat,
      'long': long
    };
    _channel.invokeMethod('setLocationCustomAttribute', params);
  }

  /// Sets a date custom attribute.
  void setDateCustomUserAttribute(String key, DateTime value) {
    final Map<String, dynamic> params = <String, dynamic>{
      'key': key,
      'value': value.millisecondsSinceEpoch ~/ 1000
    };
    _channel.invokeMethod('setDateCustomUserAttribute', params);
  }

  /// Unsets a custom attribute.
  void unsetCustomUserAttribute(String key) {
    _callStringMethod('unsetCustomUserAttribute', 'key', key);
  }

  /// Sets the first name default user attribute.
  void setFirstName(String firstName) {
    _callStringMethod('setFirstName', 'firstName', firstName);
  }

  /// Sets the last name default user attribute.
  void setLastName(String lastName) {
    _callStringMethod('setLastName', 'lastName', lastName);
  }

  /// Sets the email default user attribute.
  /// Pass in `null` to unset the user's email.
  void setEmail(String? email) {
    _callStringMethod('setEmail', 'email', email);
  }

  /// Sets the dob default user attribute.
  void setDateOfBirth(int year, int month, int day) {
    final Map<String, dynamic> params = <String, dynamic>{
      'year': year,
      'month': month,
      'day': day
    };
    _channel.invokeMethod('setDateOfBirth', params);
  }

  /// Sets the gender default user attribute.
  void setGender(String gender) {
    _callStringMethod('setGender', 'gender', gender);
  }

  /// Sets the language default user attribute.
  void setLanguage(String language) {
    _callStringMethod('setLanguage', 'language', language);
  }

  /// Sets the country default user attribute.
  void setCountry(String country) {
    _callStringMethod('setCountry', 'country', country);
  }

  /// Sets the home city default user attribute.
  void setHomeCity(String homeCity) {
    _callStringMethod('setHomeCity', 'homeCity', homeCity);
  }

  /// Sets the phone number default user attribute.
  void setPhoneNumber(String phoneNumber) {
    _callStringMethod('setPhoneNumber', 'phoneNumber', phoneNumber);
  }

  /// Sets attribution data.
  void setAttributionData(
      String? network, String? campaign, String? adGroup, String? creative) {
    final Map<String, dynamic> params = <String, dynamic>{
      'network': network,
      'campaign': campaign,
      'adGroup': adGroup,
      'creative': creative
    };
    _channel.invokeMethod('setAttributionData', params);
  }

  /// Registers a push token for the current Android device with Braze.
  /// - No-op on iOS.
  /// This method is deprecated in favor of `registerPushToken`, which supports iOS and Android.
  @Deprecated('Use registerPushToken(pushToken) instead.')
  void registerAndroidPushToken(String pushToken) {
    if (Platform.isAndroid) {
      registerPushToken(pushToken);
    }
  }

  /// Registers a push token for the current device with Braze.
  void registerPushToken(String pushToken) {
    _callStringMethod('registerPushToken', 'pushToken', pushToken);
  }

  /// Requests an immediate data flush.
  void requestImmediateDataFlush() {
    _channel.invokeMethod('requestImmediateDataFlush');
  }

  /// Wipes Data on board the SDK. Please consult iOS and Android-specific
  /// implementation details before using.
  void wipeData() {
    _channel.invokeMethod('wipeData');
  }

  /// Refreshes Content Cards.
  void requestContentCardsRefresh() {
    _channel.invokeMethod('requestContentCardsRefresh');
  }

  /// Launches Content Card Feed.
  void launchContentCards() {
    _channel.invokeMethod('launchContentCards');
  }

  /// Requests location initialization.
  void requestLocationInitialization() {
    _channel.invokeMethod('requestLocationInitialization');
  }

  /// Sets the last known location.
  void setLastKnownLocation(
      {required double latitude,
      required double longitude,
      double? altitude,
      double? accuracy,
      double? verticalAccuracy}) {
    final Map<String, dynamic> params = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy ?? 0.0,
    };
    if (altitude != null) {
      params["altitude"] = altitude;
    }
    if (verticalAccuracy != null) {
      params["verticalAccuracy"] = verticalAccuracy;
    }
    _channel.invokeMethod('setLastKnownLocation', params);
  }

  /// Enables the SDK. Please consult iOS and Android-specific
  /// implementation details before using.
  void enableSDK() {
    _channel.invokeMethod('enableSDK');
  }

  /// Disables the SDK. Please consult iOS and Android-specific
  /// implementation details before using.
  void disableSDK() {
    _channel.invokeMethod('disableSDK');
  }

  /// Sets push subscription state for the current user.
  void setPushNotificationSubscriptionType(SubscriptionType type) {
    final Map<String, dynamic> params = <String, dynamic>{
      'type': type.toString()
    };
    _channel.invokeMethod('setPushNotificationSubscriptionType', params);
  }

  /// Sets email subscription state for the current user.
  void setEmailNotificationSubscriptionType(SubscriptionType type) {
    final Map<String, dynamic> params = <String, dynamic>{
      'type': type.toString()
    };
    _channel.invokeMethod('setEmailNotificationSubscriptionType', params);
  }

  /// Adds the user to a Subscription Group using the group's UUID provided
  /// in the Braze dashboard.
  void addToSubscriptionGroup(String groupId) {
    final Map<String, dynamic> params = <String, dynamic>{'groupId': groupId};
    _channel.invokeMethod('addToSubscriptionGroup', params);
  }

  /// Removes the user from a Subscription Group using the group's UUID provided
  /// in the Braze dashboard.
  void removeFromSubscriptionGroup(String groupId) {
    final Map<String, dynamic> params = <String, dynamic>{'groupId': groupId};
    _channel.invokeMethod('removeFromSubscriptionGroup', params);
  }

  /// Gets the device id.
  Future<String> getDeviceId() {
    return _channel
        .invokeMethod('getDeviceId')
        .then<String>((dynamic result) => result);
  }

  /// Gets the install tracking id.
  @Deprecated('Use getDeviceId instead.')
  Future<String> getInstallTrackingId() {
    return _channel
        .invokeMethod('getDeviceId')
        .then<String>((dynamic result) => result);
  }

  /// Sets Google Advertising Id for the current user.
  /// - No-op on iOS.
  @Deprecated('Use setAdTrackingEnabled(adTrackingEnabled, id) instead.')
  void setGoogleAdvertisingId(String id, bool adTrackingEnabled) {
    final Map<String, dynamic> params = <String, dynamic>{
      "id": id,
      "adTrackingEnabled": adTrackingEnabled
    };
    _channel.invokeMethod('setGoogleAdvertisingId', params);
  }

  /// Sets ad tracking configuration for the current user.
  ///
  /// - `googleAdvertisingId` is required on Android.
  void setAdTrackingEnabled(
      bool adTrackingEnabled, String? googleAdvertisingId) {
    final Map<String, dynamic> params = <String, dynamic>{
      "adTrackingEnabled": adTrackingEnabled
    };
    if (googleAdvertisingId != null) {
      // Omits entry when id is null
      params["id"] = googleAdvertisingId;
    }
    _channel.invokeMethod('setAdTrackingEnabled', params);
  }

  /// Updates the existing tracking property allow list.
  /// No-op on Android.
  void updateTrackingPropertyAllowList(BrazeTrackingPropertyList allowList) {
    final Map<String, dynamic> params = {};
    if (allowList.adding != null) {
      params["adding"] =
          allowList.adding?.map((value) => value.toString()).toList();
    }
    if (allowList.removing != null) {
      params["removing"] =
          allowList.removing?.map((value) => value.toString()).toList();
    }
    if (allowList.addingCustomEvents != null) {
      params["addingCustomEvents"] = allowList.addingCustomEvents?.toList();
    }
    if (allowList.removingCustomEvents != null) {
      params["removingCustomEvents"] = allowList.removingCustomEvents?.toList();
    }
    if (allowList.addingCustomAttributes != null) {
      params["addingCustomAttributes"] =
          allowList.addingCustomAttributes?.toList();
    }
    if (allowList.removingCustomAttributes != null) {
      params["removingCustomAttributes"] =
          allowList.removingCustomAttributes?.toList();
    }
    _channel.invokeMethod('updateTrackingPropertyAllowList', params);
  }

  /// Get a single Feature Flag.
  /// Returns null if there is no feature flag with that ID.
  Future<BrazeFeatureFlag?> getFeatureFlagByID(String id) {
    final Map<String, dynamic> params = <String, dynamic>{"id": id};
    return _channel
        .invokeMethod('getFeatureFlagByID', params)
        .then<BrazeFeatureFlag?>((dynamic result) =>
            result == null ? null : BrazeFeatureFlag(result));
  }

  /// Get all Feature Flags from current cache.
  Future<List<BrazeFeatureFlag>> getAllFeatureFlags() {
    return _channel
        .invokeMethod('getAllFeatureFlags')
        .then<List<BrazeFeatureFlag>>((dynamic result) => (result as List)
            .map((ffJson) => BrazeFeatureFlag(ffJson))
            .toList());
  }

  /// Get all Content Cards from current cache.
  Future<List<BrazeContentCard>> getCachedContentCards() {
    return _channel
        .invokeMethod('getCachedContentCards')
        .then<List<BrazeContentCard>>((dynamic result) => (result as List)
            .map((ccJson) => BrazeContentCard(ccJson))
            .toList());
  }

  /// Request a refresh of the feature flags. This may not always occur
  /// if called too soon.
  void refreshFeatureFlags() {
    _channel.invokeMethod('refreshFeatureFlags');
  }

  /// Log an impression for the Feature Flag with the provided id.
  void logFeatureFlagImpression(String id) {
    final Map<String, dynamic> params = <String, dynamic>{'id': id};
    _channel.invokeMethod('logFeatureFlagImpression', params);
  }

  /// Subscribes to the stream of feature flags and calls [onEvent] when it
  /// receives the list of feature flags.
  StreamSubscription subscribeToFeatureFlags(
      void Function(List<BrazeFeatureFlag>) onEvent) {
    StreamSubscription subscription =
        featureFlagsStreamController.stream.listen(onEvent);

    // Give any existing feature flags
    getAllFeatureFlags().then((ffs) => onEvent(ffs));

    return subscription;
  }

  /// Notifies the native layer that the plugin is ready to receive data.
  void _setBrazePluginIsReady() {
    _channel.invokeMethod('setBrazePluginIsReady');
  }

  void _callStringMethod(String methodName, String paramName, String? value) {
    final Map<String, dynamic> params = <String, dynamic>{paramName: value};
    _channel.invokeMethod(methodName, params);
  }

  Future<dynamic> _handleBrazeData(MethodCall call) async {
    switch (call.method) {
      case "handleBrazeInAppMessage":
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        String? inAppMessageString = argumentsMap['inAppMessage'];
        if (inAppMessageString == null) {
          print("Invalid input. Missing value for key 'inAppMessage'.");
          return Future<void>.value();
        }
        final inAppMessage = BrazeInAppMessage(inAppMessageString);
        if (inAppMessageStreamController.hasListener) {
          inAppMessageStreamController.add(inAppMessage);
        } else {
          print(
              "Braze in-app message subscription not present. Adding to queue.");
          _queuedInAppMessages.add(inAppMessage);
        }

        return Future<void>.value();

      case "handleBrazeContentCards":
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        List<BrazeContentCard> brazeCards = [];
        for (dynamic card in argumentsMap['contentCards']) {
          brazeCards.add(BrazeContentCard(card));
        }

        if (contentCardsStreamController.hasListener) {
          contentCardsStreamController.add(brazeCards);
        } else {
          print(
              "Braze content card subscription not present. Removing any queued cards and adding only the recent refresh.");
          _queuedContentCards.clear();
          _queuedContentCards.addAll(brazeCards);
        }

        return Future<void>.value();

      case "handleBrazeBanners":
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        List<BrazeBanner> brazeBanners = [];
        for (dynamic banner in argumentsMap['banners']) {
          brazeBanners.add(BrazeBanner(banner));
        }
        if (bannersStreamController.hasListener) {
          bannersStreamController.add(brazeBanners);
        } else {
          print(
              "Braze banner subscription not present. Removing any queued banners and adding only the recent refresh.");
          _queuedBanners.clear();
          _queuedBanners.addAll(brazeBanners);
        }
        print(
            "Received banner placementIds: ${brazeBanners.map((banner) => banner.placementId.toString()).join(', ')}.");
        return Future<void>.value();

      case "handleBrazePushNotificationEvent":
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        String? pushEventString = argumentsMap['pushEvent'];
        if (pushEventString == null) {
          print("Invalid input. Missing value for key 'pushEvent'.");
          return Future<void>.value();
        }
        final pushEvent = BrazePushEvent(pushEventString);

        if (pushEventStreamController.hasListener) {
          pushEventStreamController.add(pushEvent);
        } else {
          print(
              "Braze push notification event subscription not present. Adding to queue.");
          _queuedPushEvents.add(pushEvent);
        }

        return Future<void>.value();

      case "handleBrazeFeatureFlags":
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        List<BrazeFeatureFlag> brazeFeatureFlags = [];
        for (dynamic ff in argumentsMap['featureFlags']) {
          brazeFeatureFlags.add(BrazeFeatureFlag(ff));
        }

        if (featureFlagsStreamController.hasListener) {
          featureFlagsStreamController.add(brazeFeatureFlags);
        } else {
          print(
              "Braze feature flags subscription not present. Removing any queued flags and adding only the recent refresh.");
          _queuedFeatureFlags.clear();
          _queuedFeatureFlags.addAll(brazeFeatureFlags);
        }

        return Future<void>.value();

      case "handleSdkAuthenticationError":
        final Map<dynamic, dynamic> argumentsMap = call.arguments;
        String? sdkAuthenticationErrorString =
            argumentsMap['sdkAuthenticationError'];
        if (sdkAuthenticationErrorString == null) {
          print(
              "Invalid input. Missing value for key 'sdkAuthenticationError'.");
          return Future<void>.value();
        }

        final sdkAuthenticationError =
            BrazeSdkAuthenticationError(sdkAuthenticationErrorString);
        if (_brazeSdkAuthenticationErrorHandler != null) {
          _brazeSdkAuthenticationErrorHandler!(sdkAuthenticationError);
        } else {
          print("Braze SDK Authentication error callback not present.");
        }
        return Future<void>.value();

      default:
        print("Unknown method ${call.method} called. Doing nothing.");
        return Future<void>.value();
    }
  }

  /* Braze Plugin custom configurations */

  bool _replayCallbacksConfigEnabled() {
    return _brazeCustomConfigs?[replayCallbacksConfigKey] == true;
  }
}

enum SubscriptionType { subscribed, unsubscribed, opted_in }

/// Braze in-app message dismiss types
///
/// Messages with a dismiss type of "swipe" should appear until manually
/// dismissed by the  user. Messages with a dismiss type of "auto_dismiss"
/// should dismiss automatically after the amount of time specified in the
/// "duration" field of the message's BrazeInAppMessage object elapses.
enum DismissType { swipe, auto_dismiss }

/// Braze in-app message click actions
///
/// Messages with a "uri" click action should navigate to the specified uri
/// while respecting the "useWebView" field of the message's BrazeInAppMessage
/// object if appropriate.
enum ClickAction { news_feed, uri, none }

/// Braze in-app message types
enum MessageType { slideup, modal, full, html_full }

/// Braze property types to be marked for user tracking
enum TrackingProperty {
  all_custom_attributes,
  all_custom_events,
  analytics_events,
  attribution_data,
  country,
  date_of_birth,
  device_data,
  email,
  email_subscription_state,
  everything,
  first_name,
  gender,
  home_city,
  language,
  last_name,
  notification_subscription_state,
  phone_number,
  push_token,
  push_to_start_tokens
}

/// Braze data properties to be either added or removed from the allow list.
class BrazeTrackingPropertyList {
  /// Enumerated tracking properties to be added for tracking.
  Set<TrackingProperty>? adding;

  /// Enumerated tracking properties to be removed from tracking.
  Set<TrackingProperty>? removing;

  /// Custom event strings to be added for tracking.
  Set<String>? addingCustomEvents;

  /// Custom event strings to be removed from tracking.
  Set<String>? removingCustomEvents;

  /// Custom attribute strings to be added for tracking.
  Set<String>? addingCustomAttributes;

  /// Custom attribute strings to be removed from tracking.
  Set<String>? removingCustomAttributes;
}

class BrazeContentCard {
  /// Content Card json
  String contentCardJsonString = "";

  /// Content Card clicked
  bool clicked = false;

  /// Content Card created
  int created = 0;

  /// Content Card description
  String description = "";

  /// Content Card dismissable
  bool dismissable = false;

  /// Content Card expires at
  int expiresAt = -1;

  /// Key-value pair extras
  Map<String, String> extras = Map();

  /// Content Card id
  String id = "";

  /// Content Card image
  String image = "";

  /// Content Card image aspect ratio
  num imageAspectRatio = 1;

  /// Content Card link text
  String linkText = "";

  /// Content Card pinned
  bool pinned = false;

  /// Content Card removed
  bool removed = false;

  /// Content Card title
  String title = "";

  /// Content Card type
  String type = "";

  /// Content Card url
  String url = "";

  /// Content Card use web view
  bool useWebView = false;

  /// Content Card viewed
  bool viewed = false;

  /// Content Card control
  bool isControl = false;

  BrazeContentCard(String _data) {
    contentCardJsonString = _data;
    var contentCardJson = json.jsonDecode(_data);

    var clickedJson = contentCardJson["cl"];
    if (clickedJson is bool) {
      clicked = clickedJson;
    }
    var createdJson = contentCardJson["ca"];
    if (createdJson is int) {
      created = createdJson;
    }
    var descriptionJson = contentCardJson["ds"];
    if (descriptionJson is String) {
      description = descriptionJson;
    }
    var dismissableJson = contentCardJson["db"];
    if (dismissableJson is bool) {
      dismissable = dismissableJson;
    }
    var expiresAtJson = contentCardJson["ea"];
    if (expiresAtJson is int) {
      expiresAt = expiresAtJson;
    }
    var extrasJson = contentCardJson["e"];
    if (extrasJson is Map<String, dynamic>) {
      extrasJson.forEach((key, value) {
        if (extrasJson[key] is String) {
          extras[key] = value;
        }
      });
    }
    var idJson = contentCardJson["id"];
    if (idJson is String) {
      id = idJson;
    }
    var imageJson = contentCardJson["i"];
    if (imageJson is String) {
      image = imageJson;
    }
    var imageAspectRatioJson = contentCardJson["ar"];
    if (imageAspectRatioJson is num) {
      imageAspectRatio = imageAspectRatioJson;
    }
    var linkTextJson = contentCardJson["dm"];
    if (linkTextJson is String) {
      linkText = linkTextJson;
    }
    var pinnedJson = contentCardJson["p"];
    if (pinnedJson is bool) {
      pinned = pinnedJson;
    }
    var removedJson = contentCardJson["r"];
    if (removedJson is bool) {
      removed = removedJson;
    }
    var titleJson = contentCardJson["tt"];
    if (titleJson is String) {
      title = titleJson;
    }
    var typeJson = contentCardJson["tp"];
    if (typeJson is String) {
      type = typeJson;
    }
    if (type == "control") {
      isControl = true;
    }
    var urlJson = contentCardJson["u"];
    if (urlJson is String) {
      url = urlJson;
    }
    var useWebViewJson = contentCardJson["uw"];
    if (useWebViewJson is bool) {
      useWebView = useWebViewJson;
    }
    var viewedJson = contentCardJson["v"];
    if (viewedJson is bool) {
      viewed = viewedJson;
    }
  }

  @override
  String toString() {
    return "BrazeContentCard viewed:" +
        viewed.toString() +
        " url:" +
        url +
        " type:" +
        type +
        " useWebView:" +
        useWebView.toString() +
        " title:" +
        title +
        " removed:" +
        removed.toString() +
        " linkText:" +
        linkText +
        " pinned:" +
        pinned.toString() +
        " image:" +
        image +
        " imageAspectRatio:" +
        imageAspectRatio.toString() +
        " id:" +
        id +
        " extras:" +
        extras.toString() +
        " description:" +
        description +
        " created:" +
        created.toString() +
        " expiresAt:" +
        expiresAt.toString() +
        " clicked:" +
        clicked.toString() +
        " expiresAt:" +
        expiresAt.toString() +
        " dismissable:" +
        dismissable.toString() +
        " isControl:" +
        isControl.toString() +
        " contentCardJsonString:" +
        contentCardJsonString;
  }
}

class BrazeInAppMessage {
  /// In-app message text
  String message = "";

  /// In-app message header
  String header = "";

  /// Url of the image to display alongside the message
  String imageUrl = "";

  /// Url of zipped assets to display with an HTML message
  String zippedAssetsUrl = "";

  /// Uri to navigate to on-click
  String uri = "";

  /// Whether to use a webview to display the uri when clicked
  bool useWebView = false;

  // Whether the message was delivered as a test send
  bool isTestSend = false;

  /// In-app message display duration in milliseconds
  int duration = 5;

  /// In-app message body click action
  ClickAction clickAction = ClickAction.none;

  /// In-app message dismiss type
  DismissType dismissType = DismissType.auto_dismiss;

  /// In-app message type
  MessageType messageType = MessageType.slideup;

  /// Buttons to display alongside this in-app message
  List<BrazeButton> buttons = [];

  /// Key-value pair extras
  Map<String, String> extras = Map();

  /// In-app message json
  String inAppMessageJsonString = "";

  BrazeInAppMessage(String _data) {
    inAppMessageJsonString = _data;
    var inAppMessageJson = json.jsonDecode(_data);

    var messageJson = inAppMessageJson["message"];
    if (messageJson is String) {
      message = messageJson;
    }
    var headerJson = inAppMessageJson["header"];
    if (headerJson is String) {
      header = headerJson;
    }
    var uriJson = inAppMessageJson["uri"];
    if (uriJson is String) {
      uri = uriJson;
    }
    var imageUrlJson = inAppMessageJson["image_url"];
    if (imageUrlJson is String) {
      imageUrl = imageUrlJson;
    }
    var zippedAssetsUrlJson = inAppMessageJson["zipped_assets_url"];
    if (zippedAssetsUrlJson is String) {
      zippedAssetsUrl = zippedAssetsUrlJson;
    }
    var useWebViewJson = inAppMessageJson["use_webview"];
    if (useWebViewJson is bool) {
      useWebView = useWebViewJson;
    }
    var isTestSendJson = inAppMessageJson["is_test_send"];
    if (isTestSendJson is bool) {
      isTestSend = isTestSendJson;
    }
    var durationJson = inAppMessageJson["duration"];
    if (durationJson is int) {
      duration = durationJson;
    }
    var clickActionJson = inAppMessageJson["click_action"];
    if (clickActionJson is String) {
      for (ClickAction action in ClickAction.values) {
        if (action
            .toString()
            .toLowerCase()
            .endsWith(clickActionJson.toLowerCase())) {
          clickAction = action;
        }
      }
    }
    var dismissTypeJson = inAppMessageJson["message_close"];
    if (dismissTypeJson is String) {
      for (DismissType type in DismissType.values) {
        if (type
            .toString()
            .toLowerCase()
            .endsWith(dismissTypeJson.toLowerCase())) {
          dismissType = type;
        }
      }
    }
    var messageTypeJson = inAppMessageJson["type"];
    if (messageTypeJson is String) {
      for (MessageType type in MessageType.values) {
        if (type
            .toString()
            .toLowerCase()
            .endsWith(messageTypeJson.toLowerCase())) {
          messageType = type;
        }
      }
    }
    var extrasJson = inAppMessageJson["extras"];
    if (extrasJson is Map<String, dynamic>) {
      extrasJson.forEach((key, value) {
        if (extrasJson[key] is String) {
          extras[key] = value;
        }
      });
    }
    var buttonsJson = inAppMessageJson["btns"];
    if (buttonsJson is List<dynamic>) {
      for (var buttonJson in buttonsJson) {
        buttons.add(BrazeButton(buttonJson));
      }
    }
  }

  @override
  String toString() {
    return inAppMessageJsonString;
  }
}

class BrazePushEvent {
  /// Notification payload type. Only `push_opened` events are supported on iOS
  String payloadType = "";

  /// URL opened by the notification
  String? url;

  /// Specifies whether the URL should be opened in a modal webview
  bool useWebview = false;

  /// Notification title
  String? title;

  /// Notification body, or content text
  String? body;

  /// Notification summary text. Mapped from `subtitle` on iOS
  String? summaryText;

  /// Notification badge count
  int? badgeCount;

  /// In-app message body click action
  int timestamp = -1;

  /// Specifies whether the payload was received silently.
  ///
  /// For details on sending Android silent push notifications, refer to
  /// [Silent push notifications](https://www.braze.com/docs/developer_guide/platform_integration_guides/android/push_notifications/android/silent_push_notifications).
  ///
  /// For details on sending iOS silent push notifications, refer to
  /// [Silent push notifications](https://www.braze.com/docs/developer_guide/platform_integration_guides/swift/push_notifications/silent_push_notifications/).
  bool isSilent = false;

  /// Specifies whether the payload is used by Braze for an internal SDK feature
  bool isBrazeInternal = false;

  /// URL associated with the notification image
  String? imageUrl;

  /// Braze properties associated with the campaign (key-value pairs)
  Map<String, dynamic> brazeProperties = Map();

  /// iOS-specific fields
  Map<String, dynamic> ios = Map();

  /// Android-specific fields
  Map<String, dynamic> android = Map();

  /// Push Notification event json
  String pushEventJsonString = "";

  BrazePushEvent(String _data) {
    pushEventJsonString = _data;
    var pushEventJson = json.jsonDecode(_data);

    var payloadTypeJson = pushEventJson["payload_type"];
    if (payloadTypeJson is String) {
      payloadType = payloadTypeJson;
    }
    var urlJson = pushEventJson["url"];
    if (urlJson is String) {
      url = urlJson;
    }
    var useWebviewJson = pushEventJson["use_webview"];
    if (useWebviewJson is bool) {
      useWebview = useWebviewJson;
    }
    var titleJson = pushEventJson["title"];
    if (titleJson is String) {
      title = titleJson;
    }
    var bodyJson = pushEventJson["body"];
    if (bodyJson is String) {
      body = bodyJson;
    }
    var summaryTextJson = pushEventJson["summary_text"];
    if (summaryTextJson is String) {
      summaryText = summaryTextJson;
    }
    var badgeCountJson = pushEventJson["badge_count"];
    if (badgeCountJson is int) {
      badgeCount = badgeCountJson;
    }
    var timestampJson = pushEventJson["timestamp"];
    if (timestampJson is int) {
      timestamp = timestampJson;
    }
    var isSilentJson = pushEventJson["is_silent"];
    if (isSilentJson is bool) {
      isSilent = isSilentJson;
    }
    var isBrazeInternalJson = pushEventJson["is_braze_internal"];
    if (isBrazeInternalJson is bool) {
      isBrazeInternal = isBrazeInternalJson;
    }
    var imageUrlJson = pushEventJson["image_url"];
    if (imageUrlJson is String) {
      imageUrl = imageUrlJson;
    }
    var brazePropertiesJson = pushEventJson["braze_properties"];
    if (brazePropertiesJson is Map<String, dynamic>) {
      brazePropertiesJson.forEach((key, value) {
        if (brazePropertiesJson[key] is String) {
          brazeProperties[key] = value;
        }
      });
    }
    var iosJson = pushEventJson["ios"];
    if (iosJson is Map<String, dynamic>) {
      iosJson.forEach((key, value) {
        if (iosJson[key] is String) {
          ios[key] = value;
        }
      });
    }
    var androidJson = pushEventJson["android"];
    if (androidJson is Map<String, dynamic>) {
      androidJson.forEach((key, value) {
        if (androidJson[key] is String) {
          android[key] = value;
        }
      });
    }
  }

  @override
  String toString() {
    return pushEventJsonString;
  }
}

class BrazeBanner {
  /// The tracking string of the campaign and message variation IDs.
  String trackingId = "";

  /// The placement ID this banner is matched to.
  String placementId = "";

  /// Whether the banner is from a test send.
  bool isTestSend = false;

  /// Whether the banner is a control banner.
  bool isControl = false;

  /// The HTML to display for the banner.
  String html = "";

  /// A Unix timestamp of the expiration date and time. A value of -1 means the banner never expires.
  int expiresAt = -1;

  /// The BrazeBanner object initializer.
  BrazeBanner(String _data) {
    var bannerJson = json.jsonDecode(_data);

    var trackingIdJson = bannerJson["id"];
    if (trackingIdJson is String) {
      trackingId = trackingIdJson;
    }

    var placementIdJson = bannerJson["placement_id"];
    if (placementIdJson is String) {
      placementId = placementIdJson;
    }

    var isTestSendJson = bannerJson["is_test_send"];
    if (isTestSendJson is bool) {
      isTestSend = isTestSendJson;
    }

    var isControlJson = bannerJson["is_control"];
    if (isControlJson is bool) {
      isControl = isControlJson;
    }

    var htmlJson = bannerJson["html"];
    if (htmlJson is String) {
      html = htmlJson;
    }

    var expiresAtJson = bannerJson["expires_at"];
    if (expiresAtJson is int) {
      expiresAt = expiresAtJson;
    }
  }

  @override
  String toString() {
    return "BrazeBanner trackingId:" +
        trackingId +
        " placementId:" +
        placementId +
        " isTestSend:" +
        isTestSend.toString() +
        " isControl:" +
        isControl.toString() +
        " expiresAt:" +
        expiresAt.toString() +
        " html:" +
        html;
  }
}

/// The default UI for a Braze Banner Card.
class BrazeBannerView extends StatefulWidget {
  /// The placement ID of the Banner Card.
  final String? placementId;

  /// User-specified width of the banner view.
  ///
  /// By default, this is matched to 100% of the parent widget.
  final double? width;

  /// User-specified height of the banner view.
  ///
  /// By default, this is calculated on the Braze bridge from the intrinsic
  /// content size of the HTML.
  final double? height;

  /// Optional handler for responding to calculated height changes.
  ///
  /// This callback returns the calculated height of the HTML on banner load
  /// and whenever a resize has been detected.
  final Function(double)? onHeightChanged;

  BrazeBannerView({
    Key? key,
    required this.placementId,
    this.width,
    this.height,
    this.onHeightChanged,
  }) : super(key: key);

  @override
  State<BrazeBannerView> createState() => _BrazeBannerViewState();
}

class _BrazeBannerViewState extends State<BrazeBannerView>
    with AutomaticKeepAliveClientMixin {
  /// Identifier for the view instance's entire lifecycle, managed internally.
  String get containerId => _containerId;
  late final String _containerId = UniqueKey().toString();

  /// Calculated height of the banner container.
  /// This will be updated from the native layers using the Braze bridge.
  double calculatedHeight = 0;

  /// Prevents the widget from being disposed when not visible.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    BrazeBannerResizeManager.subscribeToResizeEvents(
        (Map<String, dynamic> args) {
      var eventIdentifier = args["containerId"];
      var height = args["height"];
      if (eventIdentifier == null ||
          height == null ||
          eventIdentifier != containerId) {
        // The resize event is invalid or not for this view instance
        return;
      }
      resizeHeight(height);
    });
  }

  /// Resizes the banner container's height and notifies any relevant
  /// `onHeightChanged` handler.
  void resizeHeight(double height) {
    print("Resizing height of banner `${widget.placementId}` to $height");
    setState(() {
      calculatedHeight = height;
    });
    widget.onHeightChanged?.call(calculatedHeight);
  }

  @override
  Widget build(BuildContext context) {
    // Required for AutomaticKeepAliveClientMixin.
    super.build(context);

    final Key key = PageStorageKey(widget.placementId);
    const String viewType = 'BrazeBannerView';
    Widget bannerView;

    // Pass parameters to the native layers
    final Map<String, String?> creationParams = <String, String?>{
      'placementId': widget.placementId,
      'containerId': containerId,
    };

    // Use the overridden height or the calculated height from the JavaScript bridge.
    double finalHeight = widget.height ?? calculatedHeight;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (finalHeight <= 0) {
          // To force the native Android Banner view to render and set its resize
          // callback, set the container height to 1 and make it transparent.
          finalHeight = 1;
        }

        bannerView = PlatformViewLink(
          key: key,
          viewType: viewType,
          surfaceFactory: (context, controller) {
            return AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: const <Factory<
                  OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            );
          },
          onCreatePlatformView: (params) {
            return PlatformViewsService.initExpensiveAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: const StandardMessageCodec(),
              onFocus: () {
                params.onFocusChanged(true);
              },
            )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();
          },
        );
        break;

      case TargetPlatform.iOS:
        bannerView = UiKitView(
          key: key,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
        break;

      default:
        throw UnsupportedError('Unsupported platform view.');
    }

    return Container(
      color: Colors.transparent,
      height: finalHeight,
      width: widget.width ?? MediaQuery.of(context).size.width,
      child: bannerView,
    );
  }
}

class BrazeButton {
  /// Button text
  String text = "";

  /// Uri to navigate to on-click
  String uri = "";

  /// Whether to use a webview to display the uri when clicked
  bool useWebView = false;

  /// Button click action
  ClickAction clickAction = ClickAction.none;

  /// Id for analytics
  int id = 0;

  BrazeButton(dynamic buttonJson) {
    var textJson = buttonJson["text"];
    if (textJson is String) {
      text = textJson;
    }
    var uriJson = buttonJson["uri"];
    if (uriJson is String) {
      uri = uriJson;
    }
    var useWebViewJson = buttonJson["use_webview"];
    if (useWebViewJson is bool) {
      useWebView = useWebViewJson;
    }
    var clickActionJson = buttonJson["click_action"];
    if (clickActionJson is String) {
      for (ClickAction action in ClickAction.values) {
        if (action
            .toString()
            .toLowerCase()
            .endsWith(clickActionJson.toLowerCase())) {
          clickAction = action;
        }
      }
    }
    var idJson = buttonJson["id"];
    if (idJson is int) {
      id = idJson;
    }
  }

  @override
  String toString() {
    return "BrazeButton text:" +
        text +
        " uri:" +
        uri +
        " clickAction:" +
        clickAction.toString() +
        " useWebView:" +
        useWebView.toString();
  }
}

class BrazeSdkAuthenticationError {
  int code = 0;
  String reason = "";
  String userId = "";
  String signature = "";

  /// Sdk Authentication Error json
  String brazeSdkAuthenticationErrorString = "";

  BrazeSdkAuthenticationError(String _data) {
    brazeSdkAuthenticationErrorString = _data;
    var brazeSdkAuthenticationErrorJson = json.jsonDecode(_data);

    var codeJson = brazeSdkAuthenticationErrorJson["code"];
    if (codeJson is int) {
      code = codeJson;
    }

    var reasonJson = brazeSdkAuthenticationErrorJson["reason"];
    if (reasonJson is String) {
      reason = reasonJson;
    }

    var userIdJson = brazeSdkAuthenticationErrorJson["userId"];
    if (userIdJson is String) {
      userId = userIdJson;
    }

    var signatureJson = brazeSdkAuthenticationErrorJson["signature"];
    if (signatureJson is String) {
      signature = signatureJson;
    }
  }

  @override
  String toString() {
    return brazeSdkAuthenticationErrorString;
  }
}

class BrazeFeatureFlag {
  /// ID of the feature flag
  String id = "";

  /// Is this flag currently enabled?
  bool enabled = false;

  /// Map of optional additional properties of the feature flag
  Map properties = Map();

  BrazeFeatureFlag(String _data) {
    var featureFlagJson = json.jsonDecode(_data);

    var idJson = featureFlagJson["id"];
    if (idJson is String) {
      id = idJson;
    }

    var enabledJson = featureFlagJson["enabled"];
    if (enabledJson is bool) {
      enabled = enabledJson;
    }

    var propertiesJson = featureFlagJson["properties"];
    properties = propertiesJson ?? Map();
  }

  /// Returns a string value of the feature flag's properties for the given key.
  /// Returns null if the key is not a string property or if there is no property for that key.
  String? getStringProperty(String key) {
    var data = properties[key];
    if (data != null && data["type"] == "string") {
      return data["value"];
    }
    return null;
  }

  /// Returns a boolean value of the feature flag's properties for the given key.
  /// Returns null if the key is not a boolean property or if there is no property for that key.
  bool? getBooleanProperty(String key) {
    var data = properties[key];
    if (data != null && data["type"] == "boolean") {
      return data["value"];
    }
    return null;
  }

  /// Returns a number value of the feature flag's properties for the given key.
  /// Returns null if the key is not a number or if there is no property for that key.
  num? getNumberProperty(String key) {
    var data = properties[key];
    if (data != null && data["type"] == "number") {
      return data["value"];
    }
    return null;
  }

  /// Returns an integer value (which can hold the value of any `long`) of the
  /// feature flag's properties for the given key.
  /// Returns null if the key is not an integer or if there is no property for that key.
  int? getTimestampProperty(String key) {
    var data = properties[key];
    if (data != null && data["type"] == "datetime") {
      return data["value"];
    }
    return null;
  }

  /// Returns a Map of the feature flag's properties for the given key.
  /// Returns null if the key is not a Map object or if there is no property for that key.
  Map<String, dynamic>? getJSONProperty(String key) {
    var data = properties[key];
    if (data != null && data["type"] == "jsonobject") {
      return data["value"];
    }
    return null;
  }

  /// Returns a string representing an image of the feature flag's properties
  /// for the given key.
  /// Returns null if the key is not a string or if there is no property for that key.
  String? getImageProperty(String key) {
    var data = properties[key];
    if (data != null && data["type"] == "image") {
      return data["value"];
    }
    return null;
  }
}
