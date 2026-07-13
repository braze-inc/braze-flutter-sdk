import BrazeKit
import BrazeUI
import Flutter

/// Stores all channels, including ones across different BrazePlugin instances
var channels = [FlutterMethodChannel]()

public class BrazePlugin: NSObject, FlutterPlugin, BrazeSDKAuthDelegate {

  public static let shared: BrazePlugin = .init()

  private static var bannerViewFactory: BrazeBannerViewFactory? = nil

  /// Snapshot of the Dart-side log configuration mirrored on the native side.
  /// The Dart layer is the single source of truth; native receives updates via
  /// `setLogLevel` and uses them for both threshold filtering and forwarding.
  struct DartLogState {
    let name: String
    let values: [String: Int]
    let minimum: Int

    /// Sentinel default: empty mapping, `Int.max` minimum so logs are dropped
    /// until Dart syncs the real mapping via `setLogLevel`.
    static let initial = DartLogState(name: "info", values: [:], minimum: .max)

    private init(name: String, values: [String: Int], minimum: Int) {
      self.name = name
      self.values = values
      self.minimum = minimum
    }

    init?(name: String, values: [String: Int]) {
      guard let minimum = values[name] else { return nil }
      self.init(name: name, values: values, minimum: minimum)
    }
  }

  static var dartLog: DartLogState = .initial
  
  /// Stores the configuration closure to be applied when the Dart `initialize` method is called.
  private static var configure: ((Braze.Configuration) -> Void)?
  /// Stores the post-initialization closure to be executed after the Braze instance is created.
  private static var postInitialization: ((Braze) -> Void)?

  private static var brazeSubscriptionManager: ChannelSubscriptionManager? = nil

  /// Default return values for methods with non-nullable Dart return types,
  /// used when the SDK is not yet initialized.
  private static let uninitializedDefaultResults: [String: Any] = [
    "getDeviceId": "",
    "getAllFeatureFlags": [] as [Any],
    "getCachedContentCards": [] as [Any],
  ]

  var brazeClient: BrazeProviding?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "braze_plugin", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(shared, channel: channel)

    // Register for Banner Cards and resizing
    let uiHandler = BrazeUIHandler(messenger: registrar.messenger())
    BrazePlugin.bannerViewFactory = BrazeBannerViewFactory(
      messenger: registrar.messenger(),
      uiHandler: uiHandler
    )
    registrar.register(BrazePlugin.bannerViewFactory!, withId: "BrazeBannerView")

    channels.append(channel)
  }

  @MainActor
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let argsDescription = String(describing: call.arguments)

    // Methods that configure or signal plugin lifecycle and must run before
    // `initialize` — `setLogLevel` in particular has to land before the Braze
    // instance is created so its `configuration.logger.level` is correct.
    let preInitMethods: Set<String> = ["initialize", "setLogLevel", "setBrazePluginIsReady"]
    if brazeClient == nil && !preInitMethods.contains(call.method) {
      print("""
        [BrazePlugin] Braze SDK is not initialized. \
        Ignoring '\(call.method)'. \
        Call `initialize(apiKey, endpoint)` first.
        """)
      result(BrazePlugin.uninitializedDefaultResults[call.method] ?? NSNull())
      return
    }

    switch call.method {
    case "initialize":
      guard let args = call.arguments as? [String: Any],
            let apiKey = args["apiKey"] as? String,
            let endpoint = args["endpoint"] as? String
      else {
        result(FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "apiKey and endpoint are required",
          details: nil
        ))
        return
      }
      let configuration = Braze.Configuration(apiKey: apiKey, endpoint: endpoint)
      BrazePlugin.configure?(configuration)
      let braze = BrazePlugin.createBrazeInstance(configuration)
      BrazePlugin.postInitialization?(braze)
      result(nil)

    case "changeUser":
      guard let args = call.arguments as? [String: Any],
        let userId = args["userId"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        result(nil)
        return
      }
      if Array(args.keys).contains("sdkAuthSignature") {
        guard let sdkAuthSignature = args["sdkAuthSignature"] as? String
        else {
          print("Invalid args: \(argsDescription), iOS method: \(call.method)")
          result(nil)
          return
        }
        brazeClient?.braze.changeUser(userId: userId, sdkAuthSignature: sdkAuthSignature)
      } else {
        brazeClient?.braze.changeUser(userId: userId)
      }
      result(nil)

    case "getUserId":
      result(brazeClient?.braze.user.id)

    case "setSdkAuthenticationSignature":
      guard let args = call.arguments as? [String: Any],
        Array(args.keys).contains("sdkAuthSignature"),
        let sdkAuthSignature = args["sdkAuthSignature"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.set(sdkAuthenticationSignature: sdkAuthSignature)

    case "setSdkAuthenticationDelegate":
      brazeClient?.braze.sdkAuthDelegate = self

    case "setBrazePluginIsReady":
      break  // This is an Android only feature, do nothing.

    case "setLogLevel":
      if let args = call.arguments as? [String: Any],
         let levelName = args["level"] as? String,
         let levelValues = args["levelValues"] as? [String: Int],
         let state = DartLogState(name: levelName, values: levelValues) {
        BrazePlugin.dartLog = state
      }
      result(nil)

    case "getDeviceId":
      result(brazeClient?.braze.deviceId ?? "")

    case "requestContentCardsRefresh":
      brazeClient?.braze.contentCards.requestRefresh { _ in }

    case "launchContentCards":
      guard let braze = brazeClient?.braze,
        let mainViewController = UIApplication.shared.keyWindow?.rootViewController
      else { return }
      let modalViewController = BrazeContentCardUI.ModalViewController(braze: braze)
      modalViewController.navigationItem.title = "Content Cards"
      mainViewController.present(modalViewController, animated: true)

    case "logContentCardClicked":
      guard let args = call.arguments as? [String: Any],
        let contentCardJSONString = args["contentCardString"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      if let contentCard = BrazePlugin.contentCard(from: contentCardJSONString, braze: braze) {
        contentCard.logClick(using: braze)
      }

    case "logContentCardDismissed":
      guard let args = call.arguments as? [String: Any],
        let contentCardJSONString = args["contentCardString"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      if let contentCard = BrazePlugin.contentCard(from: contentCardJSONString, braze: braze) {
        contentCard.logDismissed(using: braze)
      }

    case "logContentCardImpression":
      guard let args = call.arguments as? [String: Any],
        let contentCardJSONString = args["contentCardString"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      if let contentCard = BrazePlugin.contentCard(from: contentCardJSONString, braze: braze) {
        contentCard.logImpression(using: braze)
      }

    case "getCachedContentCards":
      let cachedContentCards = brazeClient?.braze.contentCards.cards.compactMap { card in
        if let contentCardJson = card.json() {
          return String(data: contentCardJson, encoding: .utf8)
        } else {
          print("Failed to serialize Content Card with ID: \(card.id). Skipping...")
          return nil
        }
      }
      result(cachedContentCards ?? [])

    case "getBanner":
      guard let args = call.arguments as? [String: Any],
            let placementId = args["placementId"] as? String
      else {
        print("Unexpected null placementId in `getBanner`.")
        result(FlutterError(code: "INVALID_ARGUMENT", message: "getBanner - Invalid placementId", details: nil))
        return
      }
      
      brazeClient?.braze.banners.getBanner(for: placementId) { banner in
        if let banner = banner,
           let bannerJsonData = banner.json() {
          let bannerJsonString = String(data: bannerJsonData, encoding: .utf8)
          result(bannerJsonString)
        } else {
          result(nil)
        }
      }
    
    case "requestBannersRefresh":
      guard let args = call.arguments as? [String: Any],
            let placementIds = args["placementIds"] as? [String] else {
          print("Unexpected null placementIds in `requestBannersRefresh`.")
          result(FlutterError(code: "INVALID_ARGUMENT", message: "requestBannersRefresh - Invalid placementIds", details: nil))
          return
      }
      
      brazeClient?.braze.banners.requestBannersRefresh(placementIds: placementIds) { resultBanners in
          switch resultBanners {
          case .success:
              result("Refreshed Banners.")
          case .failure(let error):
              result(FlutterError(code: "BANNER_REFRESH_ERROR", message: "requestBannersRefresh - Failed to refresh banners: \(error.localizedDescription)", details: nil))
          }
      }

    case "logBannerClicked":
      guard let args = call.arguments as? [String: Any],
        let placementId = args["placementId"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      let buttonId = args["buttonId"] as? String
      braze.banners.getBanner(for: placementId) { banner in
        if let banner = banner {
          banner.logClick(buttonId: buttonId, using: braze)
        }
      }
    
    case "logBannerImpression":
      guard let args = call.arguments as? [String: Any],
        let placementId = args["placementId"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      braze.banners.getBanner(for: placementId) { banner in
        if let banner = banner {
          banner.logImpression(using: braze)
        }
      }

    case "dismissBanner":
      guard let args = call.arguments as? [String: Any],
        let placementId = args["placementId"] as? String, !placementId.isEmpty,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      braze.banners.getBanner(for: placementId) { banner in
        if let banner = banner {
          DispatchQueue.main.async {
            banner.dismiss(using: braze)
          }
        }
      }

    case "logInAppMessageClicked":
      guard let args = call.arguments as? [String: Any],
        let inAppMessageJSONString = args["inAppMessageString"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      if let inAppMessage = BrazePlugin.inAppMessage(from: inAppMessageJSONString, braze: braze) {
        inAppMessage.logClick(buttonId: nil, using: braze)
      }

    case "logInAppMessageImpression":
      guard let args = call.arguments as? [String: Any],
        let inAppMessageJSONString = args["inAppMessageString"] as? String,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      if let inAppMessage = BrazePlugin.inAppMessage(from: inAppMessageJSONString, braze: braze) {
        inAppMessage.logImpression(using: braze)
      }

    case "logInAppMessageButtonClicked":
      guard let args = call.arguments as? [String: Any],
        let inAppMessageJSONString = args["inAppMessageString"] as? String,
        let idNumber = args["buttonId"] as? NSNumber,
        let braze = brazeClient?.braze
      else {
        print(
          "Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)"
        )
        return
      }
      if let inAppMessage = BrazePlugin.inAppMessage(from: inAppMessageJSONString, braze: braze) {
        inAppMessage.logClick(buttonId: idNumber.stringValue, using: braze)
      }

    case "hideCurrentInAppMessage":
      if let inAppMessagePresenter = brazeClient?.braze.inAppMessagePresenter
        as? BrazeInAppMessageUI
      {
        DispatchQueue.main.async {
          inAppMessagePresenter.dismiss { result(nil) }
        }
      } else {
        print(
          "Invalid: In-app message presenter not available or not of type BrazeInAppMessageUI, iOS method: \(call.method)"
        )
      }

    case "addAlias":
      guard let args = call.arguments as? [String: Any],
        let aliasName = args["aliasName"] as? String,
        let aliasLabel = args["aliasLabel"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.add(alias: aliasName, label: aliasLabel)

    case "logCustomEvent", "logCustomEventWithProperties":
      guard let args = call.arguments as? [String: Any],
        let eventName = args["eventName"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let properties = args["properties"] as? [String: Any]
      brazeClient?.braze.logCustomEvent(name: eventName, properties: properties)

    case "logPurchase", "logPurchaseWithProperties":
      guard let args = call.arguments as? [String: Any],
        let productId = args["productId"] as? String,
        let currencyCode = args["currencyCode"] as? String,
        let price = args["price"] as? Double,
        let quantity = args["quantity"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let properties = args["properties"] as? [String: Any]
      brazeClient?.braze.logPurchase(
        productId: productId,
        currency: currencyCode,
        price: price,
        quantity: quantity.intValue,
        properties: properties
      )

    case "setFirstName":
      if let args = call.arguments as? [String: Any],
        let firstName = args["firstName"] as? String
      {
        brazeClient?.braze.user.set(firstName: firstName)
      } else {
        brazeClient?.braze.user.set(firstName: nil)
      }

    case "setLastName":
      if let args = call.arguments as? [String: Any],
        let lastName = args["lastName"] as? String
      {
        brazeClient?.braze.user.set(lastName: lastName)
      } else {
        brazeClient?.braze.user.set(lastName: nil)
      }

    case "setLanguage":
      if let args = call.arguments as? [String: Any],
        let language = args["language"] as? String
      {
        brazeClient?.braze.user.set(language: language)
      } else {
        brazeClient?.braze.user.set(language: nil)
      }

    case "setCountry":
      if let args = call.arguments as? [String: Any],
        let country = args["country"] as? String
      {
        brazeClient?.braze.user.set(country: country)
      } else {
        brazeClient?.braze.user.set(country: nil)
      }

    case "setGender":
      if let args = call.arguments as? [String: Any],
        let gender = args["gender"] as? String
      {
        brazeClient?.braze.user.set(gender: BrazePlugin.parseUserGenderInput(gender))
      } else {
        brazeClient?.braze.user.set(gender: nil)
      }

    case "setHomeCity":
      if let args = call.arguments as? [String: Any],
        let homeCity = args["homeCity"] as? String
      {
        brazeClient?.braze.user.set(homeCity: homeCity)
      } else {
        brazeClient?.braze.user.set(homeCity: nil)
      }

    case "setDateOfBirth":
      guard let args = call.arguments as? [String: Any],
        let day = args["day"] as? NSNumber,
        let month = args["month"] as? NSNumber,
        let year = args["year"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      // Use the Gregorian calendar to standardize the input regardless of user's device settings.
      let calendar = Calendar(identifier: .gregorian)
      var components = DateComponents()
      components.setValue(day.intValue, for: .day)
      components.setValue(month.intValue, for: .month)
      components.setValue(year.intValue, for: .year)
      let dateOfBirth = calendar.date(from: components)
      brazeClient?.braze.user.set(dateOfBirth: dateOfBirth)

    case "setEmail":
      if let callArguments = call.arguments as? [String: Any],
        let email = callArguments["email"] as? String
      {
        brazeClient?.braze.user.set(email: email)
      } else {
        brazeClient?.braze.user.set(email: nil)
      }

    case "setPhoneNumber":
      if let args = call.arguments as? [String: Any],
        let phoneNumber = args["phoneNumber"] as? String
      {
        brazeClient?.braze.user.set(phoneNumber: phoneNumber)
      } else {
        brazeClient?.braze.user.set(phoneNumber: nil)
      }

    case "setPushNotificationSubscriptionType":
      guard let args = call.arguments as? [String: Any],
        let type = args["type"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let pushNotificationSubscriptionType = BrazePlugin.getSubscriptionType(type)
      brazeClient?.braze.user.set(
        pushNotificationSubscriptionState: pushNotificationSubscriptionType)

    case "setEmailNotificationSubscriptionType":
      guard let args = call.arguments as? [String: Any],
        let type = args["type"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let subscriptionType = BrazePlugin.getSubscriptionType(type)
      brazeClient?.braze.user.set(emailSubscriptionState: subscriptionType)

    case "addToSubscriptionGroup":
      guard let args = call.arguments as? [String: Any],
        let groupId = args["groupId"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.addToSubscriptionGroup(id: groupId)

    case "removeFromSubscriptionGroup":
      guard let args = call.arguments as? [String: Any],
        let groupId = args["groupId"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.removeFromSubscriptionGroup(id: groupId)

    case "setStringCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setCustomAttribute(key: key, value: value)

    case "setIntCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setCustomAttribute(key: key, value: value.intValue)

    case "setDoubleCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setCustomAttribute(key: key, value: value.doubleValue)

    case "setBoolCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? Bool
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setCustomAttribute(key: key, value: value)

    case "setDateCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let date = Date.init(timeIntervalSince1970: value.doubleValue)
      brazeClient?.braze.user.setCustomAttribute(key: key, value: date)

    case "setLocationCustomAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let lat = args["lat"] as? NSNumber,
        let longitude = args["long"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setLocationCustomAttribute(
        key: key, latitude: lat.doubleValue, longitude: longitude.doubleValue)

    case "addToCustomAttributeArray":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.addToCustomAttributeStringArray(key: key, value: value)

    case "removeFromCustomAttributeArray":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.removeFromCustomAttributeStringArray(key: key, value: value)

    case "incrementCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.incrementCustomUserAttribute(key: key, by: value.intValue)

    case "setNestedCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? [String: Any?]
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let merge = args["merge"] as? Bool ?? false
      brazeClient?.braze.user.setCustomAttribute(key: key, dictionary: value, merge: merge)

    case "setCustomUserAttributeArrayOfStrings":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? [String]?
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setCustomAttribute(key: key, array: value)

    case "setCustomUserAttributeArrayOfObjects":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? [[String: Any?]]
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.setCustomAttribute(key: key, array: value)

    case "unsetCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.user.unsetCustomAttribute(key: key)

    case "setGoogleAdvertisingId":
      break  // Android-only features, do nothing.

    case "setAdTrackingEnabled":
      guard let args = call.arguments as? [String: Any],
        let adTrackingEnabled = args["adTrackingEnabled"] as? Bool
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      brazeClient?.braze.set(adTrackingEnabled: adTrackingEnabled)

    case "requestImmediateDataFlush":
      brazeClient?.braze.requestImmediateDataFlush()

    case "setAttributionData":
      guard let args = call.arguments as? [String: Any],
        let network = args["network"] as? String,
        let campaign = args["campaign"] as? String,
        let adGroup = args["adGroup"] as? String,
        let creative = args["creative"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let attributionData = Braze.User.AttributionData(
        network: network, campaign: campaign, adGroup: adGroup, creative: creative)
      brazeClient?.braze.user.set(attributionData: attributionData)

    case "registerPushToken":
      guard let args = call.arguments as? [String: Any],
        let token = args["pushToken"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }

      // Expects pushToken as a hex string; decode to Data before registering.
      if let tokenData = decodeHexToken(token) {
        brazeClient?.braze.notifications.register(deviceToken: tokenData)
      } else {
        print("Invalid Push Token String (expected hex-encoded string): \(token). Skipping token registration.")
      }

    case "wipeData":
      brazeClient?.braze.wipeData()

    case "requestLocationInitialization":
      break  // This is an Android only feature, do nothing.

    case "setLastKnownLocation":
      guard let args = call.arguments as? [String: Any],
        let latitude = args["latitude"] as? Double,
        let longitude = args["longitude"] as? Double,
        let accuracy = args["accuracy"] as? Double
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      if let altitude = args["altitude"] as? Double,
        let verticalAccuracy = args["verticalAccuracy"] as? Double,
        verticalAccuracy > 0.0
      {
        brazeClient?.braze.user.setLastKnownLocation(
          latitude: latitude,
          longitude: longitude,
          altitude: altitude,
          horizontalAccuracy: accuracy,
          verticalAccuracy: verticalAccuracy
        )
      } else {
        brazeClient?.braze.user.setLastKnownLocation(
          latitude: latitude,
          longitude: longitude,
          horizontalAccuracy: accuracy
        )
      }

    case "enableSDK":
      brazeClient?.braze.enabled = true
      result(nil)
    case "disableSDK":
      brazeClient?.braze.enabled = false
      result(nil)

    case "getFeatureFlagByID":
      guard let args = call.arguments as? [String: Any],
        let flagId = args["id"] as? String
      else {
        print("Unexpected null id in `getFeatureFlagByID`.")
        return
      }

      if let featureFlag = brazeClient?.braze.featureFlags.featureFlag(id: flagId),
        let featureFlagJson = featureFlag.json()
      {
        let featureFlagString = String(data: featureFlagJson, encoding: .utf8)
        result(featureFlagString)
      } else {
        result(nil)
      }
    case "getAllFeatureFlags":
      let featureFlags = brazeClient?.braze.featureFlags.featureFlags.compactMap { flag in
        if let featureFlagJson = flag.json() {
          return String(data: featureFlagJson, encoding: .utf8)
        } else {
          print("Failed to serialize Feature Flag with ID: \(flag.id). Skipping...")
          return nil
        }
      }
      result(featureFlags ?? [])
    case "refreshFeatureFlags":
      brazeClient?.braze.featureFlags.requestRefresh()
    case "logFeatureFlagImpression":
      guard let args = call.arguments as? [String: Any],
        let flagId = args["id"] as? String
      else {
        print("Unexpected null id in `logFeatureFlagImpression`.")
        return
      }
      brazeClient?.braze.featureFlags.logFeatureFlagImpression(id: flagId)
    case "updateTrackingPropertyAllowList":
      guard let args = call.arguments as? [String: Any] else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      var addingSet = Set<Braze.Configuration.TrackingProperty>()
      var removingSet = Set<Braze.Configuration.TrackingProperty>()

      if let adding = args["adding"] as? [String] {
        adding.forEach { propertyString in
          if let trackingProperty = BrazePlugin.getTrackingProperty(from: propertyString) {
            addingSet.insert(trackingProperty)
          } else {
            print("Invalid Braze tracking property for string \(propertyString)")
          }
        }
      }
      if let removing = args["removing"] as? [String] {
        removing.forEach { propertyString in
          if let trackingProperty = BrazePlugin.getTrackingProperty(from: propertyString) {
            removingSet.insert(trackingProperty)
          } else {
            print("Invalid Braze tracking property for string \(propertyString)")
          }
        }
      }
      if let addingCustomEvents = args["addingCustomEvents"] as? [String] {
        addingSet.insert(.customEvent(Set(addingCustomEvents)))
      }
      if let removingCustomEvents = args["removingCustomEvents"] as? [String] {
        removingSet.insert(.customEvent(Set(removingCustomEvents)))
      }
      if let addingCustomAttributes = args["addingCustomAttributes"] as? [String] {
        addingSet.insert(.customAttribute(Set(addingCustomAttributes)))
      }
      if let removingCustomAttributes = args["removingCustomAttributes"] as? [String] {
        removingSet.insert(.customAttribute(Set(removingCustomAttributes)))
      }
      brazeClient?.braze.updateTrackingAllowList(
        adding: addingSet,
        removing: removingSet
      )

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private class func inAppMessage(from jsonString: String, braze: BrazeKit.Braze) -> Braze
    .InAppMessage?
  {
    let inAppMessageRaw = try? JSONDecoder().decode(
      Braze.InAppMessageRaw.self, from: Data(jsonString.utf8))
    guard let inAppMessageRaw = inAppMessageRaw else { return nil }

    do {
      let inAppMessage: Braze.InAppMessage = try Braze.InAppMessage.init(inAppMessageRaw)
      return inAppMessage
    } catch {
      print("Error parsing in-app message from jsonString: \(jsonString), error: \(error)")
    }
    return nil
  }

  private class func contentCard(from jsonString: String, braze: BrazeKit.Braze) -> Braze
    .ContentCard?
  {
    let contentCardRaw = Braze.ContentCardRaw.decoding(json: Data(jsonString.utf8))
    guard let contentCardRaw = contentCardRaw else { return nil }

    do {
      let contentCard: Braze.ContentCard = try Braze.ContentCard.init(contentCardRaw)
      return contentCard
    } catch {
      print("Error parsing Content Card from jsonString: \(jsonString), error: \(error)")
    }
    return nil
  }

  private class func getSubscriptionType(_ subscriptionValue: String)
    -> Braze.User.SubscriptionState
  {
    switch subscriptionValue {
    case "SubscriptionType.unsubscribed":
      return .unsubscribed
    case "SubscriptionType.subscribed":
      return .subscribed
    case "SubscriptionType.opted_in":
      return .optedIn
    default:
      return .unsubscribed
    }
  }

  private class func parseUserGenderInput(_ gender: String) -> Braze.User.Gender {
    switch gender.uppercased().prefix(1) {
    case "F":
      return .female
    case "M":
      return .male
    case "N":
      return .notApplicable
    case "O":
      return .other
    case "P":
      return .preferNotToSay
    case "U":
      return .unknown
    default:
      return .unknown
    }
  }

  private class func getTrackingProperty(from propertyString: String) -> Braze.Configuration
    .TrackingProperty?
  {
    switch propertyString {
    case "TrackingProperty.all_custom_attributes":
      return .allCustomAttributes
    case "TrackingProperty.all_custom_events":
      return .allCustomEvents
    case "TrackingProperty.analytics_events":
      return .analyticsEvents
    case "TrackingProperty.attribution_data":
      return .attributionData
    case "TrackingProperty.country":
      return .country
    case "TrackingProperty.date_of_birth":
      return .dateOfBirth
    case "TrackingProperty.device_data":
      return .deviceData
    case "TrackingProperty.email":
      return .email
    case "TrackingProperty.email_subscription_state":
      return .emailSubscriptionState
    case "TrackingProperty.everything":
      return .everything
    case "TrackingProperty.first_name":
      return .firstName
    case "TrackingProperty.gender":
      return .gender
    case "TrackingProperty.home_city":
      return .homeCity
    case "TrackingProperty.language":
      return .language
    case "TrackingProperty.last_name":
      return .lastName
    case "TrackingProperty.notification_subscription_state":
      return .notificationSubscriptionState
    case "TrackingProperty.phone_number":
      return .phoneNumber
    case "TrackingProperty.push_token":
      return .pushToken
    case "TrackingProperty.push_to_start_tokens":
      return .pushToStartTokens
    default:
      return nil
    }
  }

  /// Modifies the Swift SDK's push payload to match Android push payloads
  /// and the expected payload in Dart.
  ///
  /// - Parameter originalJson: The unedited push event JSON.
  /// - Parameter pushEvent: The Braze push notification event in native Swift.
  /// - Returns: The push event JSON after updating some fields.
  private class func updatePushEventJson(
    _ originalJson: [String: Any], pushEvent: Braze.Notifications.Payload
  ) -> [String: Any] {
    var pushEventJson = originalJson

    // - Use the `"push_` prefix for consistency with Android. The Swift SDK internally uses `"opened"`.
    if pushEventJson["payload_type"] as? String == "opened" {
      pushEventJson["payload_type"] = "push_opened"
    }

    // - Map the value with the key name "summary_text"
    pushEventJson["summary_text"] = pushEvent.subtitle

    // - Ensure the timestamp is an Int instead of a Double
    pushEventJson["timestamp"] = Int(pushEvent.date.timeIntervalSince1970)

    // - If present, add the URL of the image attached to the notification.
    //   This avoids the need to extract the field from UserInfo.
    if let brazeUserInfo = pushEvent.userInfo["ab"] as? [String: Any],
      let att = brazeUserInfo["att"] as? [String: Any],
      let imageUrl = att["url"] as? String
    {
      pushEventJson["image_url"] = imageUrl
    }

    return pushEventJson
  }

  /// Resolves the BrazeKit logger level from the current Dart threshold name.
  private class func brazeKitLogLevel() -> Braze.Configuration.Logger.Level {
    switch BrazePlugin.dartLog.name {
    case "error": return .error
    case "info": return .info
    default: return .debug
    }
  }

  /// Default `configuration.logger.print` closure: classifies each BrazeKit log
  /// against the Dart threshold and forwards passing messages to Dart via
  /// `handleBrazeLog`. Returns `false` so BrazeKit still emits to its own sink.
  private class func defaultPrintClosure() -> (String, Braze.Configuration.Logger.Level) -> Bool {
    return { message, level in
      let levelName: String
      switch level {
      case .debug: levelName = "debug"
      case .info: levelName = "info"
      case .error: levelName = "error"
      case .disabled: return false
      @unknown default: return false
      }
      guard let dartLevel = BrazePlugin.dartLog.values[levelName],
            dartLevel >= BrazePlugin.dartLog.minimum else { return false }
      let arguments: [String: Any] = ["message": message, "level": dartLevel]
      DispatchQueue.main.async {
        for channel in channels {
          channel.invokeMethod("handleBrazeLog", arguments: arguments)
        }
      }
      return false
    }
  }

  // MARK: - Public methods

  /// Stores configurations to be applied when the Braze instance is initialized
  /// via the Dart `initialize` method for delayed initialization.
  ///
  /// - Important: Call this method as early as possible in your AppDelegate `didFinishLaunching` method to set up
  /// non-API key configurations (e.g., `sessionTimeout`, `push.automation`)
  /// before the Dart layer triggers initialization.
  ///
  /// - Parameters:
  ///   - configure: A closure that receives a `Braze.Configuration` instance.
  ///     Use this to set all desired configuration properties.
  ///   - postInitialization: An optional closure that is executed after the
  ///     Braze instance is created. Use this to perform any setup that requires
  ///     the live `Braze` instance (e.g., setting a custom in-app message presenter).
  public static func configure(
    _ configure: @escaping (Braze.Configuration) -> Void,
    postInitialization: ((Braze) -> Void)? = nil
  ) {
    Braze.prepareForDelayedInitialization()
    BrazePlugin.configure = configure
    BrazePlugin.postInitialization = postInitialization
  }

  /// Creates and configures a Braze instance with the provided configuration.
  ///
  /// This method can be called multiple times to re-initialize the SDK with a
  /// different configuration (e.g., to change the API environment mid-flight).
  /// Each call destroys the previous Braze instance and creates a new one.
  ///
  /// This method is called internally by the Dart `initialize` method. Use
  /// `BrazePlugin.configure(_:postInitialization:)` to store configuration
  /// in your AppDelegate, then call `initialize(apiKey, endpoint)` from Dart.
  @MainActor
  @discardableResult
  private class func createBrazeInstance(_ configuration: Braze.Configuration) -> Braze {
    // BrazeKit requires that the `Braze` instance be created on the main thread.
    // Certain features fail at runtime otherwise.
    // The `@MainActor` chain guarantees this at compile time, but that isolation
    // is not enforced at the `@objc` FlutterMethodChannel boundary.
    if !Thread.isMainThread {
      print("[BrazePlugin] createBrazeInstance called off the iOS main thread. Braze features may fail.")
    }

    // Cancel previous subscriptions to prevent potential reference cycle.
    brazeSubscriptionManager?.cancelAllSubscriptions()

    // Tear down the previous Braze instance to prevent unexpected behavior.
    BrazePlugin.shared.brazeClient?.braze.inAppMessagePresenter = nil
    BrazePlugin.shared.brazeClient = nil

    // Create a new Braze instance.
    configuration.api.addSDKMetadata([.flutter])
    configuration.api.sdkFlavor = .flutter
    // If the AppDelegate provides a custom `configuration.logger.print` closure, the plugin
    // defers to it entirely — no logs are forwarded to Dart and `BrazePlugin.dartLog.minimum`
    // only filters Dart-side output.
    //
    // If no custom `print` closure is set, the plugin owns the logger: it overwrites any
    // `configuration.logger.level` set by the app and installs a `print` closure that
    // forwards logs to Dart via the `handleBrazeLog` method channel. This means a
    // `configuration.logger.level` assignment in the host app's AppDelegate is silently
    // ignored unless a custom `print` closure is also provided.
    if configuration.logger.print == nil {
      configuration.logger.level = brazeKitLogLevel()
      configuration.logger.print = defaultPrintClosure()
    }
    let braze = Braze(configuration: configuration)
    let brazeClient = BrazeFlutterClient(braze: braze)
    BrazePlugin.shared.brazeClient = brazeClient

    // Store instance on BrazeBannerViewFactory
    BrazePlugin.bannerViewFactory?.setBraze(braze)

    BrazePlugin.brazeSubscriptionManager = BrazeSubscriptionManager.init(brazeClient)
    
    // Create channel subscriptions and begin forwarding to the Dart layer.
    brazeSubscriptionManager?.subscribeToAllChannels()
    return braze
  }

  /// Creates and configures a Braze instance with the provided configuration.
  @available(*, deprecated, message: "Use BrazePlugin.configure(_:postInitialization:) to set up configuration, then call initialize(apiKey, endpoint) from Dart.")
  @MainActor
  @discardableResult
  public class func initBraze(_ configuration: Braze.Configuration) -> Braze {
    return createBrazeInstance(configuration)
  }

  /// Translates the native [inAppMessage] into JSON and passes it from the iOS layer
  /// to the Dart layer.
  ///
  /// - Note: Swift closures are unable to be translated into JSON.
  ///
  /// - Parameter inAppMessage: The Braze in-app message in native Swift.
  public class func processInAppMessage(_ inAppMessage: Braze.InAppMessage) {
    guard let inAppMessageData = inAppMessage.json(),
      let inAppMessageString = String(data: inAppMessageData, encoding: .utf8)
    else {
      print("Invalid inAppMessage: \(inAppMessage)")
      return
    }

    let arguments = ["inAppMessage": inAppMessageString]
    for channel in channels {
      channel.invokeMethod("handleBrazeInAppMessage", arguments: arguments)
    }
  }

  /// Translates each of the the native content [cards] into JSON and passes it
  /// from the iOS layer to the Dart layer.
  ///
  /// - Note: Swift closures are unable to be translated into JSON.
  ///
  /// - Parameter cards: The array of Braze content cards in native Swift.
  public class func processContentCards(_ cards: [Braze.ContentCard]) {
    var cardStrings: [String] = []
    for card in cards {
      if let cardData = card.json(),
        let cardString = String(data: cardData, encoding: .utf8)
      {
        cardStrings.append(cardString)
      } else {
        print("Invalid content card: \(card). Skipping card.")
      }
    }

    let arguments = ["contentCards": cardStrings]
    for channel in channels {
      channel.invokeMethod("handleBrazeContentCards", arguments: arguments)
    }
  }

  /// Translates each of the native banner [banners] into JSON and passes it
  /// from the iOS layer to the Dart layer.
  ///
  /// - Note: Swift closures are unable to be translated into JSON.
  ///
  /// - Parameter banners: The dictionary of Braze banners in native Swift.
  public class func processBanners(_ banners: [String: Braze.Banner]) {
    var bannerStrings: [String] = []
    for (_, banner) in banners {
      if let bannerJsonData = banner.json(),
         let bannerString = String(data: bannerJsonData, encoding: .utf8)
      {
        bannerStrings.append(bannerString)
      } else {
        print("Invalid banner: \(banner). Skipping banner.")
      }
    }

    let arguments = ["banners": bannerStrings]
    for channel in channels {
      channel.invokeMethod("handleBrazeBanners", arguments: arguments)
    }
  }

  /// Translates the native [pushEvent] into JSON, edits it to match Android's
  /// payload, and passes it from the iOS layer to the Dart layer.
  /// Note: Swift closures are unable to be translated into JSON.
  ///
  /// - Parameter pushEvent: The Braze push notification event in native Swift.
  public class func processPushEvent(_ pushEvent: Braze.Notifications.Payload) {
    guard let pushEventData = pushEvent.json(),
          let jsonObject = try? JSONSerialization.jsonObject(with: pushEventData, options: [])
    else {
      print("Invalid pushEvent: \(pushEvent)")
      return
    }

    // Explicitly declare as non-optional to satisfy the compiler
    guard var pushEventJson = jsonObject as? [String: Any] else {
      print("Invalid pushEvent: \(pushEvent)")
      return
    }

    pushEventJson = updatePushEventJson(pushEventJson, pushEvent: pushEvent)

    // Re-serialize the updated JSON
    var options: JSONSerialization.WritingOptions = [.sortedKeys]
    if #available(iOS 13.0, *) {
      options.insert(.withoutEscapingSlashes)
    }
    guard
      let updatedJsonData = try? JSONSerialization.data(
        withJSONObject: pushEventJson, options: options),
      let pushEventString = String(data: updatedJsonData, encoding: .utf8)
    else {
      print("Unable to encode updated pushEventJson: \(pushEventJson)")
      return
    }

    let arguments = ["pushEvent": pushEventString]
    for channel in channels {
      channel.invokeMethod("handleBrazePushNotificationEvent", arguments: arguments)
    }
  }

  /// Translates each of the native [featureFlags] into JSON and passes it
  /// from the iOS layer to the Dart layer.
  ///
  /// - Note: Swift closures are unable to be translated into JSON.
  ///
  /// - Parameter featureFlags: The array of Braze feature flags in native Swift.
  public class func processFeatureFlags(_ featureFlags: [Braze.FeatureFlag]) {
    let flagStrings: [String] = featureFlags.compactMap { flag in
      if let featureFlagJson = flag.json() {
        return String(data: featureFlagJson, encoding: .utf8)
      } else {
        print("Failed to serialize Feature Flag with ID: \(flag.id). Skipping...")
        return nil
      }
    }
    let arguments = ["featureFlags": flagStrings]
    for channel in channels {
      channel.invokeMethod("handleBrazeFeatureFlags", arguments: arguments)
    }
  }

  // MARK: SDK Authentication

  public func braze(
    _ braze: BrazeKit.Braze,
    sdkAuthenticationFailedWithError error: BrazeKit.Braze.SDKAuthenticationError
  ) {
    let authError = error
    let dictionary: [String: Any?] = [
      "code": authError.code,
      "reason": authError.reason,
      "userId": authError.userId,
      "signature": authError.signature,
    ]

    do {
      let authErrorData = try JSONSerialization.data(
        withJSONObject: dictionary, options: .fragmentsAllowed)
      if let authErrorString = String(data: authErrorData, encoding: .utf8) {
        let arguments = ["sdkAuthenticationError": authErrorString]
        for channel in channels {
          channel.invokeMethod("handleSdkAuthenticationError", arguments: arguments)
        }
      }
    } catch let error as NSError {
      print(error.localizedDescription)
    }
  }
}
