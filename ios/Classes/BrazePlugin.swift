import BrazeKit
import BrazeUI
import Flutter

/// Stores all channels, including ones across different BrazePlugin instances
var channels = [FlutterMethodChannel]()

public class BrazePlugin: NSObject, FlutterPlugin, BrazeSDKAuthDelegate {

  public static var braze: Braze? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "braze_plugin", binaryMessenger: registrar.messenger())
    let instance = BrazePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    channels.append(channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let argsDescription = String(describing: call.arguments)
    switch call.method {
    case "changeUser":
      guard let args = call.arguments as? [String: Any],
        let userId = args["userId"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      if Array(args.keys).contains("sdkAuthSignature") {
        guard let sdkAuthSignature = args["sdkAuthSignature"] as? String
        else {
          print("Invalid args: \(argsDescription), iOS method: \(call.method)")
          return
        }
        BrazePlugin.braze?.changeUser(userId: userId, sdkAuthSignature: sdkAuthSignature)
      } else {
        BrazePlugin.braze?.changeUser(userId: userId)
      }

    case "setSdkAuthenticationSignature":
      guard let args = call.arguments as? [String: Any],
        Array(args.keys).contains("sdkAuthSignature"),
        let sdkAuthSignature = args["sdkAuthSignature"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.set(sdkAuthenticationSignature: sdkAuthSignature)

    case "setSdkAuthenticationDelegate":
      BrazePlugin.braze?.sdkAuthDelegate = self

    case "getInstallTrackingId":
      if let deviceId = BrazePlugin.braze?.deviceId {
        result(deviceId)
      }

    case "requestContentCardsRefresh":
      BrazePlugin.braze?.contentCards.requestRefresh { _ in }

    case "launchContentCards":
      guard let braze = BrazePlugin.braze,
        let mainViewController = UIApplication.shared.keyWindow?.rootViewController
      else { return }
      let modalViewController = BrazeContentCardUI.ModalViewController(braze: braze)
      modalViewController.navigationItem.title = "Content Cards"
      mainViewController.present(modalViewController, animated: true)

    case "logContentCardClicked":
      guard let args = call.arguments as? [String: Any],
        let contentCardJSONString = args["contentCardString"] as? String,
        let braze = BrazePlugin.braze
      else {
        print("Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)")
        return
      }
      if let contentCard = BrazePlugin.contentCard(from: contentCardJSONString, braze: braze) {
        contentCard.logClick(using: braze)
      }

    case "logContentCardDismissed":
      guard let args = call.arguments as? [String: Any],
        let contentCardJSONString = args["contentCardString"] as? String,
        let braze = BrazePlugin.braze
      else {
        print("Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)")
        return
      }
      if let contentCard = BrazePlugin.contentCard(from: contentCardJSONString, braze: braze) {
        contentCard.logDismissed(using: braze)
      }

    case "logContentCardImpression":
      guard let args = call.arguments as? [String: Any],
        let contentCardJSONString = args["contentCardString"] as? String,
        let braze = BrazePlugin.braze
      else {
        print("Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)")
        return
      }
      if let contentCard = BrazePlugin.contentCard(from: contentCardJSONString, braze: braze) {
        contentCard.logImpression(using: braze)
      }

    case "getCachedContentCards":
      let cachedContentCards = BrazePlugin.braze?.contentCards.cards.compactMap { card in
        if let contentCardJson = card.json() {
          return String(data: contentCardJson, encoding: .utf8)
        } else {
          print("Failed to serialize Content Card with ID: \(card.id). Skipping...")
          return nil
        }
      }
      result(cachedContentCards)

    case "logInAppMessageClicked":
      guard let args = call.arguments as? [String: Any],
        let inAppMessageJSONString = args["inAppMessageString"] as? String,
        let braze = BrazePlugin.braze
      else {
        print("Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)")
        return
      }
      if let inAppMessage = BrazePlugin.inAppMessage(from: inAppMessageJSONString, braze: braze) {
        inAppMessage.logClick(buttonId: nil, using: braze)
      }

    case "logInAppMessageImpression":
      guard let args = call.arguments as? [String: Any],
        let inAppMessageJSONString = args["inAppMessageString"] as? String,
        let braze = BrazePlugin.braze
      else {
        print("Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)")
        return
      }
      if let inAppMessage = BrazePlugin.inAppMessage(from: inAppMessageJSONString, braze: braze) {
        inAppMessage.logImpression(using: braze)
      }

    case "logInAppMessageButtonClicked":
      guard let args = call.arguments as? [String: Any],
        let inAppMessageJSONString = args["inAppMessageString"] as? String,
        let idNumber = args["buttonId"] as? NSNumber,
        let braze = BrazePlugin.braze
      else {
        print("Invalid args: \(argsDescription), braze: \(String(describing: braze)), iOS method: \(call.method)")
        return
      }
      if let inAppMessage = BrazePlugin.inAppMessage(from: inAppMessageJSONString, braze: braze) {
        inAppMessage.logClick(buttonId: idNumber.stringValue, using: braze)
      }

    case "addAlias":
      guard let args = call.arguments as? [String: Any],
        let aliasName = args["aliasName"] as? String,
        let aliasLabel = args["aliasLabel"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.add(alias: aliasName, label: aliasLabel)

    case "logCustomEvent", "logCustomEventWithProperties":
      guard let args = call.arguments as? [String: Any],
        let eventName = args["eventName"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let properties = args["properties"] as? [String: Any]
      BrazePlugin.braze?.logCustomEvent(name: eventName, properties: properties)

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
      BrazePlugin.braze?.logPurchase(
        productId: productId,
        currency: currencyCode,
        price: price,
        quantity: quantity.intValue,
        properties: properties
      )

    case "setFirstName":
      guard let args = call.arguments as? [String: Any],
        let firstName = args["firstName"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.set(firstName: firstName)

    case "setLastName":
      guard let args = call.arguments as? [String: Any],
        let lastName = args["lastName"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.set(lastName: lastName)

    case "setLanguage":
      guard let args = call.arguments as? [String: Any],
        let language = args["language"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.set(language: language)

    case "setCountry":
      guard let args = call.arguments as? [String: Any],
        let country = args["country"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.set(country: country)

    case "setGender":
      guard let args = call.arguments as? [String: Any],
        let gender = args["gender"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.setGender(gender)

    case "setHomeCity":
      guard let args = call.arguments as? [String: Any],
        let homeCity = args["homeCity"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.set(homeCity: homeCity)

    case "setDateOfBirth":
      guard let args = call.arguments as? [String: Any],
        let day = args["day"] as? NSNumber,
        let month = args["month"] as? NSNumber,
        let year = args["year"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let calendar = Calendar.current
      var components = DateComponents()
      components.setValue(day.intValue, for: .day)
      components.setValue(month.intValue, for: .month)
      components.setValue(year.intValue, for: .year)
      let dateOfBirth = calendar.date(from: components)
      BrazePlugin.braze?.user.set(dateOfBirth: dateOfBirth)

    case "setEmail":
      if let callArguments = call.arguments as? [String: Any],
        let email = callArguments["email"] as? String
      {
        BrazePlugin.braze?.user.set(email: email)
      } else {
        BrazePlugin.braze?.user.set(email: nil)
      }

    case "setPhoneNumber":
      guard let args = call.arguments as? [String: Any],
        let phoneNumber = args["phoneNumber"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.set(phoneNumber: phoneNumber)

    case "setPushNotificationSubscriptionType":
      guard let args = call.arguments as? [String: Any],
        let type = args["type"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let pushNotificationSubscriptionType = BrazePlugin.getSubscriptionType(type)
      BrazePlugin.braze?.user.set(
        pushNotificationSubscriptionState: pushNotificationSubscriptionType)

    case "setEmailNotificationSubscriptionType":
      guard let args = call.arguments as? [String: Any],
        let type = args["type"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let subscriptionType = BrazePlugin.getSubscriptionType(type)
      BrazePlugin.braze?.user.set(emailSubscriptionState: subscriptionType)

    case "addToSubscriptionGroup":
      guard let args = call.arguments as? [String: Any],
        let groupId = args["groupId"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.addToSubscriptionGroup(id: groupId)

    case "removeFromSubscriptionGroup":
      guard let args = call.arguments as? [String: Any],
        let groupId = args["groupId"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.removeFromSubscriptionGroup(id: groupId)

    case "setStringCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setCustomAttribute(key: key, value: value)

    case "setIntCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setCustomAttribute(key: key, value: value.intValue)

    case "setDoubleCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setCustomAttribute(key: key, value: value.doubleValue)

    case "setBoolCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? Bool
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setCustomAttribute(key: key, value: value)

    case "setDateCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let date = Date.init(timeIntervalSince1970: value.doubleValue)
      BrazePlugin.braze?.user.setCustomAttribute(key: key, value: date)

    case "setLocationCustomAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let lat = args["lat"] as? NSNumber,
        let longitude = args["long"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setLocationCustomAttribute(
        key: key, latitude: lat.doubleValue, longitude: longitude.doubleValue)

    case "addToCustomAttributeArray":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.addToCustomAttributeStringArray(key: key, value: value)

    case "removeFromCustomAttributeArray":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.removeFromCustomAttributeStringArray(key: key, value: value)

    case "incrementCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String,
        let value = args["value"] as? NSNumber
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.incrementCustomUserAttribute(key: key, by: value.intValue)
      
    case "setNestedCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? [String: Any?]
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      let merge = args["merge"] as? Bool ?? false
      BrazePlugin.braze?.user.setCustomAttribute(key: key, dictionary: value, merge: merge)

    case "setCustomUserAttributeArrayOfStrings":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? [String]?
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setCustomAttribute(key: key, array: value)

    case "setCustomUserAttributeArrayOfObjects":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? [[String: Any?]]
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.setCustomAttribute(key: key, array: value)

    case "unsetCustomUserAttribute":
      guard let args = call.arguments as? [String: Any],
        let key = args["key"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      BrazePlugin.braze?.user.unsetCustomAttribute(key: key)

    case "setGoogleAdvertisingId":
      break  // Android-only features, do nothing.

    case "requestImmediateDataFlush":
      BrazePlugin.braze?.requestImmediateDataFlush()

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
      BrazePlugin.braze?.user.set(attributionData: attributionData)

    case "registerPushToken":
      guard let args = call.arguments as? [String: Any],
        let token = args["pushToken"] as? String
      else {
        print("Invalid args: \(argsDescription), iOS method: \(call.method)")
        return
      }
      
      if let tokenData = token.data(using: .utf8) {
        BrazePlugin.braze?.notifications.register(deviceToken: tokenData)
      } else {
        print("Invalid Push Token String: \(token)")
      }

    case "wipeData":
      BrazePlugin.braze?.wipeData()

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
        BrazePlugin.braze?.user.setLastKnownLocation(
          latitude: latitude,
          longitude: longitude,
          altitude: altitude,
          horizontalAccuracy: accuracy,
          verticalAccuracy: verticalAccuracy
        )
      } else {
        BrazePlugin.braze?.user.setLastKnownLocation(
          latitude: latitude,
          longitude: longitude,
          horizontalAccuracy: accuracy
        )
      }

    case "enableSDK":
      BrazePlugin.braze?.enabled = true
    case "disableSDK":
      BrazePlugin.braze?.enabled = false
      
    case "getFeatureFlagByID":
      guard let args = call.arguments as? [String: Any],
            let flagId = args["id"] as? String
      else {
        print("Unexpected null id in `getFeatureFlagByID`.")
        return
      }
      
      if let featureFlag = BrazePlugin.braze?.featureFlags.featureFlag(id: flagId),
        let featureFlagJson = featureFlag.json() {
          let featureFlagString = String(data: featureFlagJson, encoding: .utf8)
          result(featureFlagString)
      } else {
        result(nil)
      }
    case "getAllFeatureFlags":
      let featureFlags = BrazePlugin.braze?.featureFlags.featureFlags.compactMap { flag in
        if let featureFlagJson = flag.json() {
          return String(data: featureFlagJson, encoding: .utf8)
        } else {
          print("Failed to serialize Feature Flag with ID: \(flag.id). Skipping...")
          return nil
        }
      }
      result(featureFlags)
    case "refreshFeatureFlags":
      BrazePlugin.braze?.featureFlags.requestRefresh()
    case "logFeatureFlagImpression":
      guard let args = call.arguments as? [String: Any],
            let flagId = args["id"] as? String
      else {
        print("Unexpected null id in `logFeatureFlagImpression`.")
        return
      }
      BrazePlugin.braze?.featureFlags.logFeatureFlagImpression(id: flagId)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private class func inAppMessage(from jsonString: String, braze: BrazeKit.Braze) -> Braze.InAppMessage? {
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

  private class func contentCard(from jsonString: String, braze: BrazeKit.Braze) -> Braze.ContentCard? {
    let contentCardRaw = Braze.ContentCardRaw.from(json: Data(jsonString.utf8))
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

  private class func setGender(_ gender: String) {
    let genderInputType = parseUserGenderInput(gender)
    BrazePlugin.braze?.user.set(gender: genderInputType)
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

  // MARK: - Public methods

  /// The intialization method to create a Braze instance.
  /// Call this method in your AppDelegate `didFinishLaunching` method.
  public class func initBraze(_ configuration: Braze.Configuration) -> Braze {
    configuration.api.addSDKMetadata([.flutter])
    configuration.api.sdkFlavor = .flutter
    let braze = Braze(configuration: configuration)
    BrazePlugin.braze = braze
    return braze
  }

  /// Translates the native [inAppMessage] into JSON and passes it from the iOS layer
  /// to the Dart layer.
  /// Note: Swift closures are unable to be translated into JSON.
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
  /// Note: Swift closures are unable to be translated into JSON.
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
  
  /// Translates each of the native [featureFlags] into JSON and passes it
  /// from the iOS layer to the Dart layer.
  /// Note: Swift closures are unable to be translated into JSON.
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
