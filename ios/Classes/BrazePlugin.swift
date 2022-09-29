import Appboy_iOS_SDK
import Flutter

/// Stores all channels, including ones across different BrazePlugin instances
var channels = [FlutterMethodChannel]()

public class BrazePlugin: NSObject, FlutterPlugin, ABKSdkAuthenticationDelegate {

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "braze_plugin", binaryMessenger: registrar.messenger())
    let instance = BrazePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    channels.append(channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "changeUser":
      guard let callArguments = call.arguments as? [String: Any],
        let userId = callArguments["userId"] as? String
      else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
        return
      }
      if Array(callArguments.keys).contains("sdkAuthSignature") {
        if let sdkAuthSignature = callArguments["sdkAuthSignature"] as? String {
          Appboy.sharedInstance()?.changeUser(userId, sdkAuthSignature: sdkAuthSignature)
          return
        } else {
          print(
            "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))"
          )
          return
        }
      }
      Appboy.sharedInstance()?.changeUser(userId)
    case "setSdkAuthenticationSignature":
      if let callArguments = call.arguments as? [String: Any],
        Array(callArguments.keys).contains("sdkAuthSignature"),
        let sdkAuthSignature = callArguments["sdkAuthSignature"] as? String
      {
        Appboy.sharedInstance()?.setSdkAuthenticationSignature(sdkAuthSignature)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setSdkAuthenticationDelegate":
      Appboy.sharedInstance()?.sdkAuthenticationDelegate = self
    case "getInstallTrackingId":
      let deviceId = Appboy.sharedInstance()?.getDeviceId()
      result(deviceId)
    case "requestContentCardsRefresh":
      Appboy.sharedInstance()?.requestContentCardsRefresh()
    case "launchContentCards":
      let contentCardsModal = ABKContentCardsViewController()
      contentCardsModal.navigationItem.title = "Content Cards"
      if let keyWindow = UIApplication.shared.keyWindow,
        let mainViewController = keyWindow.rootViewController
      {
        mainViewController.present(contentCardsModal, animated: true, completion: nil)
      }
    case "logContentCardClicked":
      if let callArguments = call.arguments as? [String: Any],
        let contentCardJSONString = callArguments["contentCardString"] as? String
      {
        let contentCard = ABKContentCard()
        BrazePlugin.getContentCardFromString(contentCardJSONString, contentCard: contentCard)
        contentCard.logContentCardClicked()
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logContentCardDismissed":
      if let callArguments = call.arguments as? [String: Any],
        let contentCardJSONString = callArguments["contentCardString"] as? String
      {
        let contentCard = ABKContentCard()
        BrazePlugin.getContentCardFromString(contentCardJSONString, contentCard: contentCard)
        contentCard.logContentCardDismissed()
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logContentCardImpression":
      if let callArguments = call.arguments as? [String: Any],
        let contentCardJSONString = callArguments["contentCardString"] as? String
      {
        let contentCard = ABKContentCard()
        BrazePlugin.getContentCardFromString(contentCardJSONString, contentCard: contentCard)
        contentCard.logContentCardImpression()
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logInAppMessageClicked":
      if let callArguments = call.arguments as? [String: Any],
        let inAppMessageJSONString = callArguments["inAppMessageString"] as? String
      {
        let inAppMessage = ABKInAppMessage()
        BrazePlugin.getInAppMessageFromString(inAppMessageJSONString, inAppMessage: inAppMessage)
        inAppMessage.logInAppMessageClicked()
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logInAppMessageImpression":
      if let callArguments = call.arguments as? [String: Any],
        let inAppMessageJSONString = callArguments["inAppMessageString"] as? String
      {
        let inAppMessage = ABKInAppMessage()
        BrazePlugin.getInAppMessageFromString(inAppMessageJSONString, inAppMessage: inAppMessage)
        inAppMessage.logInAppMessageImpression()
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logInAppMessageButtonClicked":
      if let callArguments = call.arguments as? [String: Any],
        let inAppMessageJSONString = callArguments["inAppMessageString"] as? String,
        let idNumber = callArguments["buttonId"] as? NSNumber
      {
        let inAppMessageImmersive = ABKInAppMessageImmersive()
        BrazePlugin.getInAppMessageFromString(
          inAppMessageJSONString, inAppMessage: inAppMessageImmersive)
        inAppMessageImmersive.logInAppMessageClicked(withButtonID: idNumber.intValue)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "addAlias":
      if let callArguments = call.arguments as? [String: Any],
        let aliasName = callArguments["aliasName"] as? String,
        let aliasLabel = callArguments["aliasLabel"] as? String
      {
        Appboy.sharedInstance()?.user.addAlias(aliasName, withLabel: aliasLabel)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logCustomEvent", "logCustomEventWithProperties":
      if let callArguments = call.arguments as? [String: Any],
        let eventName = callArguments["eventName"] as? String
      {
        Appboy.sharedInstance()?.sdkFlavor = .FLUTTER
        Appboy.sharedInstance()?.addSdkMetadata([ABKSdkMetadata.flutter])
        if let properties = callArguments["properties"] as? [AnyHashable: Any] {
          Appboy.sharedInstance()?.logCustomEvent(eventName, withProperties: properties)
        } else {
          Appboy.sharedInstance()?.logCustomEvent(eventName)
        }
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "logPurchase", "logPurchaseWithProperties":
      if let callArguments = call.arguments as? [String: Any],
        let productId = callArguments["productId"] as? String,
        let currencyCode = callArguments["currencyCode"] as? String,
        let priceNumber = callArguments["price"] as? NSNumber,
        let quantity = callArguments["quantity"] as? NSNumber
      {
        let price = priceNumber.decimalValue as NSDecimalNumber
        if let properties = callArguments["properties"] as? [AnyHashable: Any] {
          Appboy.sharedInstance()?.logPurchase(
            productId, inCurrency: currencyCode, atPrice: price, withQuantity: quantity.uintValue,
            andProperties: properties)
        } else {
          Appboy.sharedInstance()?.logPurchase(
            productId, inCurrency: currencyCode, atPrice: price, withQuantity: quantity.uintValue
          )
        }
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))"
        )
      }
    case "setFirstName":
      if let callArguments = call.arguments as? [String: Any],
        let firstName = callArguments["firstName"] as? String
      {
        Appboy.sharedInstance()?.user.firstName = firstName
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setLastName":
      if let callArguments = call.arguments as? [String: Any],
        let lastName = callArguments["lastName"] as? String
      {
        Appboy.sharedInstance()?.user.lastName = lastName
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setLanguage":
      if let callArguments = call.arguments as? [String: Any],
        let language = callArguments["language"] as? String
      {
        Appboy.sharedInstance()?.user.language = language
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setCountry":
      if let callArguments = call.arguments as? [String: Any],
        let country = callArguments["country"] as? String
      {
        Appboy.sharedInstance()?.user.country = country
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setGender":
      if let callArguments = call.arguments as? [String: Any],
        let gender = callArguments["gender"] as? String
      {
        BrazePlugin.setGender(gender)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setHomeCity":
      if let callArguments = call.arguments as? [String: Any],
        let homeCity = callArguments["homeCity"] as? String
      {
        Appboy.sharedInstance()?.user.homeCity = homeCity
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setDateOfBirth":
      if let callArguments = call.arguments as? [String: Any],
        let day = callArguments["day"] as? NSNumber,
        let month = callArguments["month"] as? NSNumber,
        let year = callArguments["year"] as? NSNumber
      {
        let calendar = Calendar.current
        var components = DateComponents()
        components.setValue(day.intValue, for: .day)
        components.setValue(month.intValue, for: .month)
        components.setValue(year.intValue, for: .year)
        let dateOfBirth = calendar.date(from: components)
        Appboy.sharedInstance()?.user.dateOfBirth = dateOfBirth
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setEmail":
      if let callArguments = call.arguments as? [String: Any],
        let email = callArguments["email"] as? String
      {
        Appboy.sharedInstance()?.user.email = email
      } else {
        Appboy.sharedInstance()?.user.email = nil
      }
    case "setPhoneNumber":
      if let callArguments = call.arguments as? [String: Any],
        let phoneNumber = callArguments["phoneNumber"] as? String
      {
        Appboy.sharedInstance()?.user.phone = phoneNumber
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setPushNotificationSubscriptionType":
      if let callArguments = call.arguments as? [String: Any],
        let type = callArguments["type"] as? String
      {
        let pushNotificationSubscriptionType = BrazePlugin.getSubscriptionType(type)
        Appboy.sharedInstance()?.user.setPush(pushNotificationSubscriptionType)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setEmailNotificationSubscriptionType":
      if let callArguments = call.arguments as? [String: Any],
        let type = callArguments["type"] as? String
      {
        let emailNotificationSubscriptionType = BrazePlugin.getSubscriptionType(type)
        Appboy.sharedInstance()?.user.setEmailNotificationSubscriptionType(
          emailNotificationSubscriptionType)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "addToSubscriptionGroup":
      if let callArguments = call.arguments as? [String: Any],
        let groupId = callArguments["groupId"] as? String
      {
        Appboy.sharedInstance()?.user.addToSubscriptionGroup(withGroupId: groupId)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "removeFromSubscriptionGroup":
      if let callArguments = call.arguments as? [String: Any],
        let groupId = callArguments["groupId"] as? String
      {
        Appboy.sharedInstance()?.user.removeFromSubscriptionGroup(withGroupId: groupId)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setStringCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? String
      {
        Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andStringValue: value)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setIntCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? NSNumber
      {
        Appboy.sharedInstance()?.user.setCustomAttributeWithKey(
          key, andIntegerValue: value.intValue)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setDoubleCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? NSNumber
      {
        Appboy.sharedInstance()?.user.setCustomAttributeWithKey(
          key, andDoubleValue: value.doubleValue)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setBoolCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? Bool
      {
        Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andBOOLValue: value)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setDateCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? NSNumber
      {
        let date = Date.init(timeIntervalSince1970: value.doubleValue)
        Appboy.sharedInstance()?.user.setCustomAttributeWithKey(key, andDateValue: date)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "setLocationCustomAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let lat = callArguments["lat"] as? NSNumber,
        let longitude = callArguments["long"] as? NSNumber
      {
        Appboy.sharedInstance()?.user.addLocationCustomAttribute(
          withKey: key, latitude: lat.doubleValue, longitude: longitude.doubleValue)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "addToCustomAttributeArray":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? String
      {
        Appboy.sharedInstance()?.user.addToCustomAttributeArray(withKey: key, value: value)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "removeFromCustomAttributeArray":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? String
      {
        Appboy.sharedInstance()?.user.removeFromCustomAttributeArray(withKey: key, value: value)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "incrementCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String,
        let value = callArguments["value"] as? NSNumber
      {
        Appboy.sharedInstance()?.user.incrementCustomUserAttribute(key, by: value.intValue)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "unsetCustomUserAttribute":
      if let callArguments = call.arguments as? [String: Any],
        let key = callArguments["key"] as? String
      {
        Appboy.sharedInstance()?.user.unsetCustomAttribute(withKey: key)
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "registerAndroidPushToken":
      break  // This is an Android only feature, do nothing.
    case "setGoogleAdvertisingId":
      break  // This is an Android only feature, do nothing.
    case "requestImmediateDataFlush":
      Appboy.sharedInstance()?.requestImmediateDataFlush()
    case "setAttributionData":
      if let callArguments = call.arguments as? [String: Any],
        let network = callArguments["network"] as? String,
        let campaign = callArguments["campaign"] as? String,
        let adGroup = callArguments["adGroup"] as? String,
        let creative = callArguments["creative"] as? String
      {
        let attributionData = ABKAttributionData(
          network: network, campaign: campaign, adGroup: adGroup, creative: creative)
        Appboy.sharedInstance()?.user.attributionData = attributionData
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "wipeData":
      Appboy.wipeDataAndDisableForAppRun()
    case "requestLocationInitialization":
      break  // This is an Android only feature, do nothing.
    case "setLastKnownLocation":
      if let callArguments = call.arguments as? [String: Any],
        let latitude = callArguments["latitude"] as? Double,
        let longitude = callArguments["longitude"] as? Double,
        let accuracy = callArguments["accuracy"] as? Double
      {
        if let altitude = callArguments["altitude"] as? NSNumber,
          let verticalAccuracy = callArguments["verticalAccuracy"] as? NSNumber,
          verticalAccuracy.doubleValue > 0.0
        {
          Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(
            latitude, longitude: longitude, horizontalAccuracy: accuracy,
            altitude: altitude.doubleValue, verticalAccuracy: verticalAccuracy.doubleValue)
        } else {
          Appboy.sharedInstance()?.user.setLastKnownLocationWithLatitude(
            latitude, longitude: longitude, horizontalAccuracy: accuracy)
        }
      } else {
        print(
          "Invalid arguments for \(call.method) iOS method: \(String(describing: call.arguments))")
      }
    case "enableSDK":
      Appboy.requestEnableSDKOnNextAppRun()
    case "disableSDK":
      Appboy.disableSDK()
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private class func getInAppMessageFromString(
    _ inAppMessageJSONString: String, inAppMessage: ABKInAppMessage
  ) {
    if let inAppMessageData = inAppMessageJSONString.data(
      using: String.Encoding.utf8, allowLossyConversion: false)
    {
      do {
        if let deserializedInAppMessageDict = try JSONSerialization.jsonObject(
          with: inAppMessageData, options: .mutableContainers) as? [String: Any]
        {
          inAppMessage.setValuesForKeys(deserializedInAppMessageDict)
        }
      } catch let error as NSError {
        print(error.localizedDescription)
      }
    }
  }

  private class func getContentCardFromString(
    _ contentCardJSONString: String, contentCard: ABKContentCard
  ) {
    if let contentCardData = contentCardJSONString.data(
      using: String.Encoding.utf8, allowLossyConversion: false)
    {
      do {
        if let deserializedContentCardDict = try JSONSerialization.jsonObject(
          with: contentCardData, options: .mutableContainers) as? [String: Any]
        {
          contentCard.setValuesForKeys(deserializedContentCardDict)
        }
      } catch let error as NSError {
        print(error.localizedDescription)
      }
    }
  }

  private class func getSubscriptionType(_ subscriptionValue: String)
    -> ABKNotificationSubscriptionType
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
    Appboy.sharedInstance()?.user.setGender(genderInputType)
  }

  private class func parseUserGenderInput(_ gender: String) -> ABKUserGenderType {
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

  public class func processInAppMessage(_ inAppMessage: ABKInAppMessage) {
    guard let inAppMessageData = inAppMessage.serializeToData(),
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

  public class func processContentCards(_ cards: [ABKContentCard]) {
    var cardStrings: [String] = []
    for card in cards {
      if let cardData = card.serializeToData(),
        let cardString = String(data: cardData, encoding: .utf8)
      {
        cardStrings.append(cardString)
      } else {
        print("Invalid content card: \(card)")
      }
    }
    let arguments = ["contentCards": cardStrings]

    for channel in channels {
      channel.invokeMethod("handleBrazeContentCards", arguments: arguments)
    }
  }

  // MARK: - ABKSdkAuthenticationDelegate

  public func handle(_ authError: ABKSdkAuthenticationError) {
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
