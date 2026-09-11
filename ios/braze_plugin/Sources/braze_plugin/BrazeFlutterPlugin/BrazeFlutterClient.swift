/**
 * This file contains the direct method calls to the Braze Swift SDK.
 *
 * The methods defined in this file are directly consumed by the Flutter `BrazePlugin` class.
 */

import Foundation
import UIKit
import BrazeKit
import BrazeUI

final class BrazeFlutterClient {

  /// The encapsulated Braze SDK instance. Nil when constructed from mock modules.
  let braze: Braze?

  private var subscriptionManager: ChannelSubscriptionManager?

  let coreModule: Braze.CoreModule
  let userModule: Braze.UserModule
  let contentCardsModule: Braze.ContentCardsModule
  let bannersModule: Braze.BannersModule
  let featureFlagsModule: Braze.FeatureFlagsModule
  let notificationsModule: Braze.NotificationsModule
  let liveActivitiesModule: Braze.LiveActivitiesModule?

  convenience init(braze: Braze) {
    let liveActivities: Braze.LiveActivitiesModule?
    if #available(iOS 16.1, *) {
      liveActivities = braze.liveActivities
    } else {
      liveActivities = nil
    }
    self.init(
      braze: braze,
      coreModule: braze,
      userModule: braze.user,
      contentCardsModule: braze.contentCards,
      bannersModule: braze.banners,
      featureFlagsModule: braze.featureFlags,
      notificationsModule: braze.notifications,
      liveActivitiesModule: liveActivities
    )
  }

  /// Used for testing via dependency injection. Production uses `init(braze:)`.
  init(
    braze: Braze? = nil,
    coreModule: Braze.CoreModule,
    userModule: Braze.UserModule,
    contentCardsModule: Braze.ContentCardsModule,
    bannersModule: Braze.BannersModule,
    featureFlagsModule: Braze.FeatureFlagsModule,
    notificationsModule: Braze.NotificationsModule,
    liveActivitiesModule: Braze.LiveActivitiesModule?
  ) {
    self.braze = braze
    self.coreModule = coreModule
    self.userModule = userModule
    self.contentCardsModule = contentCardsModule
    self.bannersModule = bannersModule
    self.featureFlagsModule = featureFlagsModule
    self.notificationsModule = notificationsModule
    self.liveActivitiesModule = liveActivitiesModule
  }

  /// Applies Flutter SDK flavor and metadata without constructing `Braze`.
  static func applyMetadata(_ configuration: Braze.Configuration) {
    configuration.api.addSDKMetadata([.flutter])
    configuration.api.sdkFlavor = .flutter
  }

  /// Creates a client that owns a new `Braze` instance configured for Flutter.
  @MainActor
  static func create(configuration: Braze.Configuration) -> (BrazeFlutterClient, Braze) {
    applyMetadata(configuration)
    let braze = Braze(configuration: configuration)
    return (BrazeFlutterClient(braze: braze), braze)
  }

  /// Replaces any existing channel subscriptions with `manager`.
  @MainActor
  func startSubscriptions(_ manager: ChannelSubscriptionManager) {
    subscriptionManager?.cancelAllSubscriptions()
    subscriptionManager = manager
    manager.subscribeToAllChannels()
  }

  /// Cancels channel subscriptions and clears the in-app message presenter.
  @MainActor
  func teardown() {
    subscriptionManager?.cancelAllSubscriptions()
    subscriptionManager = nil
    clearInAppMessagePresenter()
  }

}

// MARK: - Channel subscription methods

extension BrazeFlutterClient : BrazeProviding {

  public func removeSubscription(_ subscription: inout Braze.Cancellable?) {
    subscription?.cancel()
    subscription = nil
  }

  /// Subscribes to content cards updates and passes them to the Dart layer.
  public func createContentCardsSubscription(_ processAction: @escaping ([Braze.ContentCard]) -> Void) -> Braze.Cancellable? {
    contentCardsModule.subscribeToUpdates { contentCards in
      processAction(contentCards)
    }
  }

  /// Subscribes to banners updates and passes them to the Dart layer.
  public func createBannersSubscription(_ processAction: @escaping ([String: Braze.Banner]) -> Void) -> Braze.Cancellable? {
    bannersModule.subscribeToUpdates { banners in
      processAction(banners)
    }
  }

  /// Subscribes to push updates and passes them to the Dart layer.
  public func createPushNotificationSubscription(_ processAction: @escaping (Braze.Notifications.Payload) -> Void) -> Braze.Cancellable? {
    notificationsModule.subscribeToUpdates { payload in
      processAction(payload)
    }
  }

  /// Subscribes to feature flags updates and passes them to the Dart layer.
  public func createFeatureFlagsSubscription(_ processAction: @escaping ([Braze.FeatureFlag]) -> Void) -> Braze.Cancellable? {
    featureFlagsModule.subscribeToUpdates { featureFlags in
      processAction(featureFlags)
    }
  }

  /// Sets the default in-app message presenter,
  /// which subscribes to in-app message updates and passes them to the Dart layer.
  @MainActor
  public func setDefaultPresenter(_ processAction: @escaping (Braze.InAppMessage) -> Void) {
    let inAppMessageUI = DefaultFlutterInAppMessagePresenter(processAction)
    coreModule.inAppMessagePresenter = inAppMessageUI
  }

}

// MARK: - SDK Controls

extension BrazeFlutterClient {

  func enableSDK() {
    coreModule.enabled = true
  }

  func disableSDK() {
    coreModule.enabled = false
  }

  func wipeData() {
    coreModule.wipeData()
  }

  func logCustomEvent(callArguments: [String: Any]) {
    guard let eventName = callArguments["eventName"] as? String else { return }
    let properties = callArguments["properties"] as? [String: Any]
    coreModule.logCustomEvent(name: eventName, properties: properties)
  }

  func logPurchase(callArguments: [String: Any]) {
    guard let productId = callArguments["productId"] as? String,
          let currencyCode = callArguments["currencyCode"] as? String,
          let price = callArguments["price"] as? Double,
          let quantity = callArguments["quantity"] as? NSNumber else {
      return
    }
    let properties = callArguments["properties"] as? [String: Any]
    coreModule.logPurchase(
      productId: productId,
      currency: currencyCode,
      price: price,
      quantity: quantity.intValue,
      properties: properties
    )
  }

  func setAdTrackingEnabled(callArguments: [String: Any]) {
    guard let adTrackingEnabled = callArguments["adTrackingEnabled"] as? Bool else { return }
    coreModule.set(adTrackingEnabled: adTrackingEnabled)
  }

  func requestImmediateDataFlush() {
    coreModule.requestImmediateDataFlush()
  }

  func setSdkAuthDelegate(_ delegate: BrazeSDKAuthDelegate?) {
    coreModule.sdkAuthDelegate = delegate
  }

  func clearInAppMessagePresenter() {
    coreModule.inAppMessagePresenter = nil
  }

  func applyBraze(_ body: (Braze) -> Void) {
    guard let braze else { return }
    body(braze)
  }

  func updateTrackingPropertyAllowList(callArguments: [String: Any]) {
    var addingSet = Set<Braze.Configuration.TrackingProperty>()
    var removingSet = Set<Braze.Configuration.TrackingProperty>()

    if let adding = callArguments["adding"] as? [String] {
      adding.forEach { propertyString in
        if let trackingProperty = getTrackingProperty(from: propertyString) {
          addingSet.insert(trackingProperty)
        } else {
          print("Invalid Braze tracking property for string \(propertyString)")
        }
      }
    }
    if let removing = callArguments["removing"] as? [String] {
      removing.forEach { propertyString in
        if let trackingProperty = getTrackingProperty(from: propertyString) {
          removingSet.insert(trackingProperty)
        } else {
          print("Invalid Braze tracking property for string \(propertyString)")
        }
      }
    }
    if let addingCustomEvents = callArguments["addingCustomEvents"] as? [String] {
      addingSet.insert(.customEvent(Set(addingCustomEvents)))
    }
    if let removingCustomEvents = callArguments["removingCustomEvents"] as? [String] {
      removingSet.insert(.customEvent(Set(removingCustomEvents)))
    }
    if let addingCustomAttributes = callArguments["addingCustomAttributes"] as? [String] {
      addingSet.insert(.customAttribute(Set(addingCustomAttributes)))
    }
    if let removingCustomAttributes = callArguments["removingCustomAttributes"] as? [String] {
      removingSet.insert(.customAttribute(Set(removingCustomAttributes)))
    }
    coreModule.updateTrackingAllowList(adding: addingSet, removing: removingSet)
  }

}

// MARK: - Device

extension BrazeFlutterClient {

  func getDeviceId() -> String? {
    coreModule.deviceId
  }

}

// MARK: - User

extension BrazeFlutterClient {

  func getUserId() -> String? {
    userModule.id
  }

  func changeUser(callArguments: [String: Any]) {
    guard let userId = callArguments["userId"] as? String else { return }
    if Array(callArguments.keys).contains("sdkAuthSignature"),
       let sdkAuthSignature = callArguments["sdkAuthSignature"] as? String {
      coreModule.changeUser(userId: userId, sdkAuthSignature: sdkAuthSignature)
    } else {
      coreModule.changeUser(userId: userId, sdkAuthSignature: nil)
    }
  }

  func setSdkAuthenticationSignature(callArguments: [String: Any]) {
    guard let sdkAuthSignature = callArguments["sdkAuthSignature"] as? String else { return }
    coreModule.set(sdkAuthenticationSignature: sdkAuthSignature)
  }

  func addAlias(callArguments: [String: Any]) {
    guard let aliasName = callArguments["aliasName"] as? String,
          let aliasLabel = callArguments["aliasLabel"] as? String else {
      return
    }
    userModule.add(alias: aliasName, label: aliasLabel)
  }

  func setFirstName(callArguments: [String: Any]) {
    if let firstName = callArguments["firstName"] as? String {
      userModule.set(firstName: firstName)
    } else {
      userModule.set(firstName: nil)
    }
  }

  func setLastName(callArguments: [String: Any]) {
    if let lastName = callArguments["lastName"] as? String {
      userModule.set(lastName: lastName)
    } else {
      userModule.set(lastName: nil)
    }
  }

  func setEmail(callArguments: [String: Any]) {
    if let email = callArguments["email"] as? String {
      userModule.set(email: email)
    } else {
      userModule.set(email: nil)
    }
  }

  func setLanguage(callArguments: [String: Any]) {
    if let language = callArguments["language"] as? String {
      userModule.set(language: language)
    } else {
      userModule.set(language: nil)
    }
  }

  func setCountry(callArguments: [String: Any]) {
    if let country = callArguments["country"] as? String {
      userModule.set(country: country)
    } else {
      userModule.set(country: nil)
    }
  }

  func setGender(callArguments: [String: Any]) {
    if let gender = callArguments["gender"] as? String {
      userModule.set(gender: parseUserGenderInput(gender))
    } else {
      userModule.set(gender: nil)
    }
  }

  func setHomeCity(callArguments: [String: Any]) {
    if let homeCity = callArguments["homeCity"] as? String {
      userModule.set(homeCity: homeCity)
    } else {
      userModule.set(homeCity: nil)
    }
  }

  func setDateOfBirth(callArguments: [String: Any]) {
    guard let day = callArguments["day"] as? NSNumber,
          let month = callArguments["month"] as? NSNumber,
          let year = callArguments["year"] as? NSNumber else {
      return
    }
    let calendar = Calendar(identifier: .gregorian)
    var components = DateComponents()
    components.setValue(day.intValue, for: .day)
    components.setValue(month.intValue, for: .month)
    components.setValue(year.intValue, for: .year)
    userModule.set(dateOfBirth: calendar.date(from: components))
  }

  func setPhoneNumber(callArguments: [String: Any]) {
    if let phoneNumber = callArguments["phoneNumber"] as? String {
      userModule.set(phoneNumber: phoneNumber)
    } else {
      userModule.set(phoneNumber: nil)
    }
  }

  func setPushNotificationSubscriptionType(callArguments: [String: Any]) {
    guard let type = callArguments["type"] as? String else { return }
    userModule.set(pushNotificationSubscriptionState: getSubscriptionType(type))
  }

  func setEmailNotificationSubscriptionType(callArguments: [String: Any]) {
    guard let type = callArguments["type"] as? String else { return }
    userModule.set(emailSubscriptionState: getSubscriptionType(type))
  }

  func addToSubscriptionGroup(callArguments: [String: Any]) {
    guard let groupId = callArguments["groupId"] as? String else { return }
    userModule.addToSubscriptionGroup(id: groupId)
  }

  func removeFromSubscriptionGroup(callArguments: [String: Any]) {
    guard let groupId = callArguments["groupId"] as? String else { return }
    userModule.removeFromSubscriptionGroup(id: groupId)
  }

  func setStringCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? String else {
      return
    }
    userModule.setCustomAttribute(key: key, value: value)
  }

  func setIntCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? NSNumber else {
      return
    }
    userModule.setCustomAttribute(key: key, value: value.intValue)
  }

  func setDoubleCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? NSNumber else {
      return
    }
    userModule.setCustomAttribute(key: key, value: value.doubleValue)
  }

  func setBoolCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? Bool else {
      return
    }
    userModule.setCustomAttribute(key: key, value: value)
  }

  func setDateCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? NSNumber else {
      return
    }
    userModule.setCustomAttribute(key: key, value: Date(timeIntervalSince1970: value.doubleValue))
  }

  func setLocationCustomAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let lat = callArguments["lat"] as? NSNumber,
          let longitude = callArguments["long"] as? NSNumber else {
      return
    }
    userModule.setLocationCustomAttribute(
      key: key, latitude: lat.doubleValue, longitude: longitude.doubleValue)
  }

  func addToCustomAttributeArray(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? String else {
      return
    }
    userModule.addToCustomAttributeStringArray(key: key, value: value)
  }

  func removeFromCustomAttributeArray(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? String else {
      return
    }
    userModule.removeFromCustomAttributeStringArray(key: key, value: value)
  }

  func incrementCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? NSNumber else {
      return
    }
    userModule.incrementCustomUserAttribute(key: key, by: value.intValue)
  }

  func setNestedCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? [String: Any?] else {
      return
    }
    let merge = callArguments["merge"] as? Bool ?? false
    userModule.setCustomAttribute(key: key, dictionary: value, merge: merge)
  }

  func setCustomUserAttributeArrayOfStrings(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? [String]? else {
      return
    }
    userModule.setCustomAttribute(key: key, array: value)
  }

  func setCustomUserAttributeArrayOfObjects(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String,
          let value = callArguments["value"] as? [[String: Any?]] else {
      return
    }
    userModule.setCustomAttribute(key: key, array: value)
  }

  func unsetCustomUserAttribute(callArguments: [String: Any]) {
    guard let key = callArguments["key"] as? String else { return }
    userModule.unsetCustomAttribute(key: key)
  }

  func setLastKnownLocation(callArguments: [String: Any]) {
    guard let latitude = callArguments["latitude"] as? Double,
          let longitude = callArguments["longitude"] as? Double,
          let accuracy = callArguments["accuracy"] as? Double else {
      return
    }
    if let altitude = callArguments["altitude"] as? Double,
       let verticalAccuracy = callArguments["verticalAccuracy"] as? Double,
       verticalAccuracy > 0.0 {
      userModule.setLastKnownLocation(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        horizontalAccuracy: accuracy,
        verticalAccuracy: verticalAccuracy
      )
    } else {
      userModule.setLastKnownLocation(
        latitude: latitude,
        longitude: longitude,
        altitude: nil,
        horizontalAccuracy: accuracy,
        verticalAccuracy: nil
      )
    }
  }

  func setAttributionData(callArguments: [String: Any]) {
    guard let network = callArguments["network"] as? String,
          let campaign = callArguments["campaign"] as? String,
          let adGroup = callArguments["adGroup"] as? String,
          let creative = callArguments["creative"] as? String else {
      return
    }
    userModule.set(attributionData: Braze.User.AttributionData(
      network: network, campaign: campaign, adGroup: adGroup, creative: creative))
  }
}

private func parseUserGenderInput(_ gender: String) -> Braze.User.Gender {
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

private func getSubscriptionType(_ subscriptionValue: String) -> Braze.User.SubscriptionState {
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

private func getTrackingProperty(from propertyString: String) -> Braze.Configuration.TrackingProperty? {
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

// MARK: - Content Cards

extension BrazeFlutterClient {

  func requestContentCardsRefresh() {
    contentCardsModule.requestRefresh { _ in }
  }

  func getCachedContentCards() -> [String] {
    let cachedContentCards: [String] = contentCardsModule.cards.compactMap { card in
      if let contentCardJson = card.json() {
        return String(data: contentCardJson, encoding: .utf8)
      } else {
        print("Failed to serialize Content Card with ID: \(card.id). Skipping...")
        return nil
      }
    }
    return cachedContentCards
  }

  class func contentCard(
    from jsonString: String,
    braze: Braze.CoreModule
  ) -> Braze.ContentCard? {
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

  func launchContentCards() {
    guard let braze,
          let mainViewController = keyWindowRootViewController else {
      return
    }
    let modalViewController = BrazeContentCardUI.ModalViewController(braze: braze)
    modalViewController.navigationItem.title = "Content Cards"
    mainViewController.present(modalViewController, animated: true)
  }

  private var keyWindowRootViewController: UIViewController? {
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }

      // Prefer the foreground-active scene, but fall back to any connected
      // scene so this still resolves during launch / scene transitions.
      let scene = scenes.first { $0.activationState == .foregroundActive }
        ?? scenes.first

      return scene?.windows.first { $0.isKeyWindow }?.rootViewController
        ?? scene?.windows.first?.rootViewController
    }

    // iOS 12: no scenes, use the app delegate's window.
    return UIApplication.shared.delegate?.window??.rootViewController
  }

  func logContentCardClicked(callArguments: [String: Any]) {
    logContentCard(callArguments: callArguments) { card, braze in
      card.logClick(using: braze)
    }
  }

  func logContentCardDismissed(callArguments: [String: Any]) {
    logContentCard(callArguments: callArguments) { card, braze in
      card.logDismissed(using: braze)
    }
  }

  func logContentCardImpression(callArguments: [String: Any]) {
    logContentCard(callArguments: callArguments) { card, braze in
      card.logImpression(using: braze)
    }
  }

  private func logContentCard(
    callArguments: [String: Any],
    action: (Braze.ContentCard, Braze) -> Void
  ) {
    guard let jsonString = callArguments["contentCardString"] as? String,
          let braze,
          let contentCard = Self.contentCard(from: jsonString, braze: coreModule) else {
      return
    }
    action(contentCard, braze)
  }

}

// MARK: - Banners

extension BrazeFlutterClient {

  func getBanner(
    callArguments: [String: Any],
    completion: @escaping (Result<String?, BrazeFlutterClientError>) -> Void
  ) {
    guard let placementId = callArguments["placementId"] as? String else {
      print("Unexpected null placementId in `getBanner`.")
      completion(.failure(BrazeFlutterClientError(
        code: "INVALID_ARGUMENT",
        message: "getBanner - Invalid placementId"
      )))
      return
    }
    bannersModule.getBanner(for: placementId) { banner in
      if let banner,
         let bannerJsonData = banner.json() {
        completion(.success(String(data: bannerJsonData, encoding: .utf8)))
      } else {
        completion(.success(nil))
      }
    }
  }

  func requestBannersRefresh(
    callArguments: [String: Any],
    completion: @escaping (Result<String, BrazeFlutterClientError>) -> Void
  ) {
    guard let placementIds = callArguments["placementIds"] as? [String] else {
      print("Unexpected null placementIds in `requestBannersRefresh`.")
      completion(.failure(BrazeFlutterClientError(
        code: "INVALID_ARGUMENT",
        message: "requestBannersRefresh - Invalid placementIds"
      )))
      return
    }
    bannersModule.requestBannersRefresh(placementIds: placementIds) { resultBanners in
      switch resultBanners {
      case .success:
        completion(.success("Refreshed Banners."))
      case .failure(let error):
        completion(.failure(BrazeFlutterClientError(
          code: "BANNER_REFRESH_ERROR",
          message: "requestBannersRefresh - Failed to refresh banners: \(error.localizedDescription)"
        )))
      }
    }
  }

  func logBannerClicked(callArguments: [String: Any]) {
    let buttonId = callArguments["buttonId"] as? String
    logBanner(callArguments: callArguments) { banner, braze in
      banner.logClick(buttonId: buttonId, using: braze)
    }
  }

  func logBannerImpression(callArguments: [String: Any]) {
    logBanner(callArguments: callArguments) { banner, braze in
      banner.logImpression(using: braze)
    }
  }

  func dismissBanner(callArguments: [String: Any]) {
    guard let placementId = callArguments["placementId"] as? String,
          !placementId.isEmpty else {
      return
    }
    logBanner(callArguments: callArguments) { banner, braze in
      DispatchQueue.main.async {
        banner.dismiss(using: braze)
      }
    }
  }

  private func logBanner(
    callArguments: [String: Any],
    action: @escaping (Braze.Banner, Braze) -> Void
  ) {
    guard let placementId = callArguments["placementId"] as? String,
          let braze else {
      return
    }
    bannersModule.getBanner(for: placementId) { banner in
      guard let banner else { return }
      action(banner, braze)
    }
  }

}

// MARK: - In-App Messages

extension BrazeFlutterClient {

  class func inAppMessage(from jsonString: String) -> Braze.InAppMessage? {
    let inAppMessageRaw = try? JSONDecoder().decode(
      Braze.InAppMessageRaw.self, from: Data(jsonString.utf8))
    guard let inAppMessageRaw else { return nil }

    do {
      return try Braze.InAppMessage(inAppMessageRaw)
    } catch {
      print("Error parsing in-app message from jsonString: \(jsonString), error: \(error)")
    }
    return nil
  }

  func logInAppMessageClicked(callArguments: [String: Any]) {
    logInAppMessage(callArguments: callArguments, buttonId: nil) { message, buttonId, braze in
      message.logClick(buttonId: buttonId, using: braze)
    }
  }

  func logInAppMessageImpression(callArguments: [String: Any]) {
    logInAppMessage(callArguments: callArguments, buttonId: nil) { message, _, braze in
      message.logImpression(using: braze)
    }
  }

  func logInAppMessageButtonClicked(callArguments: [String: Any]) {
    guard let idNumber = callArguments["buttonId"] as? NSNumber else { return }
    logInAppMessage(callArguments: callArguments, buttonId: idNumber.stringValue) { message, buttonId, braze in
      message.logClick(buttonId: buttonId, using: braze)
    }
  }

  func hideCurrentInAppMessage(completion: @escaping () -> Void) {
    guard let inAppMessagePresenter = coreModule.inAppMessagePresenter as? BrazeInAppMessageUI else {
      print("Invalid: In-app message presenter not available or not of type BrazeInAppMessageUI")
      return
    }
    DispatchQueue.main.async {
      inAppMessagePresenter.dismiss { completion() }
    }
  }

  private func logInAppMessage(
    callArguments: [String: Any],
    buttonId: String?,
    action: (Braze.InAppMessage, String?, Braze) -> Void
  ) {
    guard let jsonString = callArguments["inAppMessageString"] as? String,
          let braze,
          let inAppMessage = Self.inAppMessage(from: jsonString) else {
      return
    }
    action(inAppMessage, buttonId, braze)
  }

}

// MARK: - Feature Flags

extension BrazeFlutterClient {
  func requestFeatureFlagsRefresh() {
    featureFlagsModule.requestRefresh { _ in }
  }

  func getFeatureFlag(callArguments: [String: Any]) -> String? {
    guard let flagId = callArguments["id"] as? String else {
      print("Unexpected null id in `getFeatureFlagByID`.")
      return nil
    }
    guard let featureFlag = featureFlagsModule.featureFlag(id: flagId),
          let featureFlagJson = featureFlag.json() else {
      return nil
    }
    return String(data: featureFlagJson, encoding: .utf8)
  }

  func getAllFeatureFlags() -> [String] {
    featureFlagsModule.featureFlags.compactMap { flag in
      if let featureFlagJson = flag.json() {
        return String(data: featureFlagJson, encoding: .utf8)
      } else {
        print("Failed to serialize Feature Flag with ID: \(flag.id). Skipping...")
        return nil
      }
    }
  }

  func logFeatureFlagImpression(callArguments: [String: Any]) {
    guard let flagId = callArguments["id"] as? String else {
      print("Unexpected null id in `logFeatureFlagImpression`.")
      return
    }
    featureFlagsModule.logFeatureFlagImpression(id: flagId)
  }
}

// MARK: - Push

extension BrazeFlutterClient {

  func registerPushToken(callArguments: [String: Any]) {
    guard let token = callArguments["pushToken"] as? String else { return }
    if let tokenData = decodeHexToken(token) {
      notificationsModule.register(deviceToken: tokenData)
    } else {
      print("Invalid Push Token String (expected hex-encoded string): \(token). Skipping token registration.")
    }
  }

  /// Unregisters this device's push token, mapping the native result for the method channel.
  func unregisterPush(
    completion: @escaping @MainActor (Result<Void, BrazeFlutterClientError>) -> Void
  ) {
    notificationsModule.unregisterPush { nativeResult in
      completion(Self.mapPushUnregistration(nativeResult, errorCode: BrazeFlutterErrorCode.unregisterPush))
    }
  }

  /// Logs the current user out, mapping the native result for the method channel.
  func logout(
    completion: @escaping @MainActor (Result<Void, BrazeFlutterClientError>) -> Void
  ) {
    coreModule.logout { nativeResult in
      completion(Self.mapPushUnregistration(nativeResult, errorCode: BrazeFlutterErrorCode.logout))
    }
  }

  private static func mapPushUnregistration<Failure: FlutterPushUnregistrationFailure>(
    _ nativeResult: Result<Void, Failure>,
    errorCode: String
  ) -> Result<Void, BrazeFlutterClientError> {
    switch nativeResult {
    case .success:
      return .success(())
    case .failure(let error):
      return .failure(BrazeFlutterClientError(
        code: errorCode,
        message: error.message,
        details: BrazePushLogoutMapping.details(for: error)
      ))
    }
  }

}

// MARK: - DefaultFlutterInAppMessagePresenter

class DefaultFlutterInAppMessagePresenter: BrazeInAppMessageUI {
  private let processAction: (Braze.InAppMessage) -> Void

  init(_ processAction: @escaping (Braze.InAppMessage) -> Void) {
    self.processAction = processAction
  }

  override func present(message: Braze.InAppMessage) {
    processAction(message)
    super.present(message: message)
  }

}

// MARK: - Hex decoding (for APNs push token from Dart)

func decodeHexToken(_ hex: String) -> Data? {
  let s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
  guard s.count % 2 == 0 else { return nil }
  var data = Data(capacity: s.count / 2)
  var index = s.startIndex
  while index < s.endIndex {
    let next = s.index(index, offsetBy: 2)
    guard let byte = UInt8(s[index..<next], radix: 16) else { return nil }
    data.append(byte)
    index = next
  }
  return data
}

// MARK: - Unregister Push / Logout

/// Native errors that map to a Flutter method-channel failure for push unregistration / logout.
protocol FlutterPushUnregistrationFailure: Error {
  var message: String { get }
  var isRetriable: Bool { get }
  var httpStatusCode: Int? { get }
}

extension Braze.PushUnregistrationError: FlutterPushUnregistrationFailure {}

extension Braze.LogoutErrorResult: FlutterPushUnregistrationFailure {
  var message: String { BrazePushLogoutMapping.message(for: errors) }

  /// Resolves the HTTP status code for a logout failure with these guidelines:
  /// 1. Prefer `unregisterPush`'s status code.
  /// 2. Fall back to `unregisterPushToStart`'s status code when `unregisterPush` has none.
  ///
  /// A success will not return a `LogoutErrorResult` so it is not relevant.
  var httpStatusCode: Int? { BrazePushLogoutMapping.httpStatusCode(for: errors) }
}

/// Maps Swift SDK push-unregistration / logout errors to Flutter method-channel details.
enum BrazePushLogoutMapping {

  /// Concatenates the error messages for each endpoint in the dictionary.
  static func message(for errors: [Braze.LogoutEndpoint: Braze.PushUnregistrationError]) -> String {
    let parts = [Braze.LogoutEndpoint.unregisterPush, .unregisterPushToStart].compactMap { endpoint in
      errors[endpoint].map { "\(endpoint): \($0.message)" }
    }
    return parts.isEmpty ? "Logout failed." : parts.joined(separator: "; ")
  }

  /// Resolves the HTTP status code for a logout failure with these guidelines:
  /// 1. Prefer `unregisterPush`'s status code.
  /// 2. Fall back to `unregisterPushToStart`'s status code when `unregisterPush` has none.
  ///
  /// A success will not return a `LogoutErrorResult` so it is not relevant.
  static func httpStatusCode(
    for errors: [Braze.LogoutEndpoint: Braze.PushUnregistrationError]
  ) -> Int? {
    errors[.unregisterPush]?.httpStatusCode ?? errors[.unregisterPushToStart]?.httpStatusCode
  }

  static func details(for error: some FlutterPushUnregistrationFailure) -> [String: AnyHashable] {
    var details: [String: AnyHashable] = ["isRetriable": error.isRetriable]
    if let httpStatusCode = error.httpStatusCode {
      details["httpStatusCode"] = httpStatusCode
    }
    return details
  }
}

// MARK: - Flutter error codes

/// Method-channel error codes surfaced to Dart.
enum BrazeFlutterErrorCode {
  static let unregisterPush = "UNREGISTER_PUSH_ERROR"
  static let logout = "LOGOUT_ERROR"
}

// MARK: - Uninitialized Policy

/// Policy when specific methods are invoked before the SDK is initialized.
enum UninitializedPolicy {

  /// Method name -> Flutter error code surfaced when called before initialization.
  static let failureCodes: [String: String] = [
    "unregisterPush": BrazeFlutterErrorCode.unregisterPush,
    "logout": BrazeFlutterErrorCode.logout,
  ]

  /// Metadata associated with the failure to surface to the integrator.
  static let failureDetails: [String: AnyHashable] = ["isRetriable": false]

  /// The Flutter error code to surfaced to the integrator.
  static func failureCode(for method: String) -> String? { failureCodes[method] }

  /// The human-readablefailure message surfaced to the integrator.
  static func failureMessage(for method: String) -> String {
    "'\(method)' requires the Braze SDK to be initialized."
  }
}

// MARK: - BrazeProviding

protocol ChannelSubscriptionManager {
  func subscribeToAllChannels()
  func cancelAllSubscriptions()
}

protocol BrazeProviding: AnyObject {
  func createBannersSubscription(_ processAction: @escaping ([String: Braze.Banner]) -> Void) -> Braze.Cancellable?
  func createContentCardsSubscription(_ processAction: @escaping ([Braze.ContentCard]) -> Void) -> Braze.Cancellable?
  func createPushNotificationSubscription(_ processAction: @escaping (Braze.Notifications.Payload) -> Void) -> Braze.Cancellable?
  func createFeatureFlagsSubscription(_ processAction: @escaping ([Braze.FeatureFlag]) -> Void) -> Braze.Cancellable?

  @MainActor
  func setDefaultPresenter(_ processAction: @escaping (Braze.InAppMessage) -> Void)

  func removeSubscription(_ subscription: inout Braze.Cancellable?)
}

/// Flutter-agnostic error surfaced by `BrazeFlutterClient`.
///
/// `BrazePlugin` maps this to `FlutterError` on the method channel so that `BrazeFlutterClient` doesn't
/// depend on the Flutter framework.
struct BrazeFlutterClientError: Error, Equatable, @unchecked Sendable {
  let code: String
  let message: String
  let details: [String: AnyHashable]?

  init(code: String, message: String, details: [String: AnyHashable]? = nil) {
    self.code = code
    self.message = message
    self.details = details
  }
}
