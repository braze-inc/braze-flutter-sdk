import 'dart:async';
import 'dart:convert' as json;

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
  final List<BrazeFeatureFlag> _queuedFeatureFlags = [];

  /// Broadcast stream to listen for in-app messages.
  StreamController<BrazeInAppMessage> inAppMessageStreamController =
      StreamController<BrazeInAppMessage>.broadcast();

  /// Broadcast stream to listen for content cards.
  StreamController<List<BrazeContentCard>> contentCardsStreamController =
      StreamController<List<BrazeContentCard>>.broadcast();

  /// Broadcast stream to listen for feature flags.
  StreamController<List<BrazeFeatureFlag>> featureFlagsStreamController =
      StreamController<List<BrazeFeatureFlag>>.broadcast();

  /// The plugin used to interface with all Braze APIs with optional parameters
  /// specific customization.
  ///
  /// The [inAppMessageHandler] and [contentCardsHandler] can subscribe to
  /// their respective streams at plugin initialization. These can also be
  /// subscribed at a later time after initialization
  BrazePlugin(
      {Function(BrazeInAppMessage)? inAppMessageHandler,
      Function(BrazeSdkAuthenticationError)? brazeSdkAuthenticationErrorHandler,
      Function(List<BrazeContentCard>)? contentCardsHandler,
      Function(List<BrazeFeatureFlag>)? featureFlagsHandler,
      Map<String, bool>? customConfigs}) {
    _brazeCustomConfigs = customConfigs;
    _brazeSdkAuthenticationErrorHandler = brazeSdkAuthenticationErrorHandler;

    if (inAppMessageHandler != null) {
      subscribeToInAppMessages(inAppMessageHandler);
    }
    if (contentCardsHandler != null) {
      subscribeToContentCards(contentCardsHandler);
    }
    if (featureFlagsHandler != null) {
      subscribeToFeatureFlags(featureFlagsHandler);
    }

    // Called after setting up plugin settings
    _channel.setMethodCallHandler(_handleBrazeData);
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
  void registerAndroidPushToken(String pushToken) {
    _callStringMethod('registerAndroidPushToken', 'pushToken', pushToken);
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

  /// Gets the install tracking id.
  Future<String> getInstallTrackingId() {
    return _channel
        .invokeMethod('getInstallTrackingId')
        .then<String>((dynamic result) => result);
  }

  /// Sets Google Advertising Id for the current user.
  /// - No-op on iOS.
  void setGoogleAdvertisingId(String id, bool adTrackingEnabled) {
    final Map<String, dynamic> params = <String, dynamic>{
      "id": id,
      "adTrackingEnabled": adTrackingEnabled
    };
    _channel.invokeMethod('setGoogleAdvertisingId', params);
  }

  /// Get a single Feature Flag.
  Future<BrazeFeatureFlag> getFeatureFlagByID(String id) {
    final Map<String, dynamic> params = <String, dynamic>{"id": id};
    return _channel
        .invokeMethod('getFeatureFlagByID', params)
        .then<BrazeFeatureFlag>((dynamic result) => BrazeFeatureFlag(result));
  }

  /// Get all Feature Flags from current cache.
  Future<List<BrazeFeatureFlag>> getAllFeatureFlags() {
    return _channel
        .invokeMethod('getAllFeatureFlags')
        .then<List<BrazeFeatureFlag>>((dynamic result) => (result as List)
            .map((ffJson) => BrazeFeatureFlag(ffJson))
            .toList());
  }

  /// Request a refresh of the feature flags. This may not always occur
  /// if called too soon.
  void refreshFeatureFlags() {
    _channel.invokeMethod('refreshFeatureFlags');
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

  /// Returns a string of the additional properties for the given ID
  /// Returns null if the key is not a string property
  String? getStringProperty(String key) {
    var data = properties[key];
    if (data != null) {
      if (data["type"] == "string") {
        return data["value"];
      }
    }
    return null;
  }

  /// Returns a bool of the additional properties for the given ID
  /// Returns null if the key is not a boolean property
  bool? getBooleanProperty(String key) {
    var data = properties[key];
    if (data != null) {
      if (data["type"] == "boolean") {
        return data["value"];
      }
    }
    return null;
  }

  /// Returns a num of the additional properties for the given ID
  /// Returns null if the key is not a number
  num? getNumberProperty(String key) {
    var data = properties[key];
    if (data != null) {
      if (data["type"] == "number") {
        return data["value"];
      }
    }
    return null;
  }
}
