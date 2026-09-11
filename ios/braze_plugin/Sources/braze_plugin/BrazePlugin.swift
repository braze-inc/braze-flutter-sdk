import BrazeKit
import BrazeUI
import Flutter

/// Stores all channels, including ones across different BrazePlugin instances
var channels = [FlutterMethodChannel]()

public class BrazePlugin: NSObject, FlutterPlugin, BrazeSDKAuthDelegate {

  public static let shared: BrazePlugin = .init()

  private static var bannerViewFactory: BrazeBannerViewFactory? = nil

  var brazeClient: BrazeFlutterClient?

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

  /// Default return values for methods with non-nullable Dart return types,
  /// used when the SDK is not yet initialized.
  private static let uninitializedDefaultResults: [String: Any] = [
    "getDeviceId": "",
    "getAllFeatureFlags": [] as [Any],
    "getCachedContentCards": [] as [Any],
  ]

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

      // Report a result back to the Dart layer.
      if let code = UninitializedPolicy.failureCode(for: call.method) {
        result(FlutterError(
          code: code,
          message: UninitializedPolicy.failureMessage(for: call.method),
          details: UninitializedPolicy.failureDetails))
      } else {
        result(BrazePlugin.uninitializedDefaultResults[call.method] ?? NSNull())
      }
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
      guard let args = call.argumentsAsDictionary() else {
        result(nil)
        return
      }
      brazeClient?.changeUser(callArguments: args)
      result(nil)

    case "getUserId":
      result(brazeClient?.getUserId())

    case "setSdkAuthenticationSignature":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setSdkAuthenticationSignature(callArguments: args)

    case "setSdkAuthenticationDelegate":
      brazeClient?.setSdkAuthDelegate(self)

    case "setBrazePluginIsReady":
      // This is an Android only feature, do nothing.
      break

    case "setLogLevel":
      if let args = call.arguments as? [String: Any],
         let levelName = args["level"] as? String,
         let levelValues = args["levelValues"] as? [String: Int],
         let state = DartLogState(name: levelName, values: levelValues) {
        BrazePlugin.dartLog = state
      }
      result(nil)

    case "getDeviceId":
      result(brazeClient?.getDeviceId() ?? "")

    case "requestContentCardsRefresh":
      brazeClient?.requestContentCardsRefresh()

    case "launchContentCards":
      brazeClient?.launchContentCards()

    case "logContentCardClicked":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logContentCardClicked(callArguments: args)

    case "logContentCardDismissed":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logContentCardDismissed(callArguments: args)

    case "logContentCardImpression":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logContentCardImpression(callArguments: args)

    case "getCachedContentCards":
      result(brazeClient?.getCachedContentCards())

    case "getBanner":
      brazeClient?.getBanner(callArguments: call.argumentsAsDictionary() ?? [:]) { outcome in
        switch outcome {
        case .success(let value):
          result(value)
        case .failure(let error):
          result(FlutterError(
            code: error.code,
            message: error.message,
            details: nil
          ))
        }
      }

    case "requestBannersRefresh":
      brazeClient?.requestBannersRefresh(callArguments: call.argumentsAsDictionary() ?? [:]) { outcome in
        switch outcome {
        case .success(let value):
          result(value)
        case .failure(let error):
          result(FlutterError(
            code: error.code,
            message: error.message,
            details: nil
          ))
        }
      }

    case "logBannerClicked":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logBannerClicked(callArguments: args)

    case "logBannerImpression":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logBannerImpression(callArguments: args)

    case "dismissBanner":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.dismissBanner(callArguments: args)

    case "logInAppMessageClicked":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logInAppMessageClicked(callArguments: args)

    case "logInAppMessageImpression":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logInAppMessageImpression(callArguments: args)

    case "logInAppMessageButtonClicked":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logInAppMessageButtonClicked(callArguments: args)

    case "hideCurrentInAppMessage":
      brazeClient?.hideCurrentInAppMessage { result(nil) }

    case "addAlias":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.addAlias(callArguments: args)

    case "logCustomEvent", "logCustomEventWithProperties":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logCustomEvent(callArguments: args)

    case "logPurchase", "logPurchaseWithProperties":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logPurchase(callArguments: args)

    case "setFirstName":
      brazeClient?.setFirstName(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setLastName":
      brazeClient?.setLastName(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setLanguage":
      brazeClient?.setLanguage(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setCountry":
      brazeClient?.setCountry(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setGender":
      brazeClient?.setGender(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setHomeCity":
      brazeClient?.setHomeCity(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setDateOfBirth":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setDateOfBirth(callArguments: args)

    case "setEmail":
      brazeClient?.setEmail(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setPhoneNumber":
      brazeClient?.setPhoneNumber(callArguments: call.argumentsAsDictionary() ?? [:])

    case "setPushNotificationSubscriptionType":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setPushNotificationSubscriptionType(callArguments: args)

    case "setEmailNotificationSubscriptionType":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setEmailNotificationSubscriptionType(callArguments: args)

    case "addToSubscriptionGroup":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.addToSubscriptionGroup(callArguments: args)

    case "removeFromSubscriptionGroup":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.removeFromSubscriptionGroup(callArguments: args)

    case "setStringCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setStringCustomUserAttribute(callArguments: args)

    case "setIntCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setIntCustomUserAttribute(callArguments: args)

    case "setDoubleCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setDoubleCustomUserAttribute(callArguments: args)

    case "setBoolCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setBoolCustomUserAttribute(callArguments: args)

    case "setDateCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setDateCustomUserAttribute(callArguments: args)

    case "setLocationCustomAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setLocationCustomAttribute(callArguments: args)

    case "addToCustomAttributeArray":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.addToCustomAttributeArray(callArguments: args)

    case "removeFromCustomAttributeArray":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.removeFromCustomAttributeArray(callArguments: args)

    case "incrementCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.incrementCustomUserAttribute(callArguments: args)

    case "setNestedCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setNestedCustomUserAttribute(callArguments: args)

    case "setCustomUserAttributeArrayOfStrings":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setCustomUserAttributeArrayOfStrings(callArguments: args)

    case "setCustomUserAttributeArrayOfObjects":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setCustomUserAttributeArrayOfObjects(callArguments: args)

    case "unsetCustomUserAttribute":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.unsetCustomUserAttribute(callArguments: args)

    case "setGoogleAdvertisingId":
      // Android-only features, do nothing.
      break

    case "setAdTrackingEnabled":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setAdTrackingEnabled(callArguments: args)

    case "requestImmediateDataFlush":
      brazeClient?.requestImmediateDataFlush()

    case "setAttributionData":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setAttributionData(callArguments: args)

    case "registerPushToken":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.registerPushToken(callArguments: args)

    case "unregisterPush":
      brazeClient?.unregisterPush { outcome in
        switch outcome {
        case .success:
          result(nil)
        case .failure(let error):
          result(FlutterError(
            code: error.code,
            message: error.message,
            details: error.details
          ))
        }
      }

    case "wipeData":
      brazeClient?.wipeData()

    case "logout":
      brazeClient?.logout { outcome in
        switch outcome {
        case .success:
          result(nil)
        case .failure(let error):
          result(FlutterError(
            code: error.code,
            message: error.message,
            details: error.details
          ))
        }
      }

    case "requestLocationInitialization":
      // This is an Android only feature, do nothing.
      break

    case "setLastKnownLocation":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.setLastKnownLocation(callArguments: args)

    case "enableSDK":
      brazeClient?.enableSDK()
      result(nil)

    case "disableSDK":
      brazeClient?.disableSDK()
      result(nil)

    case "getFeatureFlagByID":
      result(brazeClient?.getFeatureFlag(callArguments: call.argumentsAsDictionary() ?? [:]))

    case "getAllFeatureFlags":
      result(brazeClient?.getAllFeatureFlags() ?? [])

    case "refreshFeatureFlags":
      brazeClient?.requestFeatureFlagsRefresh()

    case "logFeatureFlagImpression":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.logFeatureFlagImpression(callArguments: args)

    case "updateTrackingPropertyAllowList":
      guard let args = call.argumentsAsDictionary() else { return }
      brazeClient?.updateTrackingPropertyAllowList(callArguments: args)

    default:
      result(FlutterMethodNotImplemented)
    }
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

    // Tear down the previous client (cancels subscriptions and clears the presenter).
    BrazePlugin.shared.brazeClient?.teardown()
    BrazePlugin.shared.brazeClient = nil

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
    let (brazeClient, braze) = BrazeFlutterClient.create(configuration: configuration)
    BrazePlugin.shared.brazeClient = brazeClient

    brazeClient.applyBraze { BrazePlugin.bannerViewFactory?.setBraze($0) }
    brazeClient.startSubscriptions(BrazeSubscriptionManager(brazeClient))
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

    pushEventJson = BrazeFlutterDataTranslator.updatePushEventJson(
      pushEventJson,
      pushEvent: pushEvent
    )

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
