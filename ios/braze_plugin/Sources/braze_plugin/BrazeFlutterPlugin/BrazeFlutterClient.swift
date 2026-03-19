/**
 * This file contains the direct method calls to the Braze Swift SDK.
 *
 * The methods defined in this file are directly consumed by the Flutter `BrazePlugin` class.
 */

import Foundation
import BrazeKit
import BrazeUI

final class BrazeFlutterClient: BrazeProviding {

  /// The encapsulated Braze SDK instance.
  public let braze: Braze
  
  init(braze: Braze) {
    self.braze = braze
  }
  
  // MARK: - Channel subscription methods
  
  public func removeSubscription(_ subscription: inout Braze.Cancellable?) {
    subscription?.cancel()
    subscription = nil
  }
  
  /// Subscribes to content cards updates and passes them to the Dart layer.
  public func createContentCardsSubscription(_ processAction: @escaping ([Braze.ContentCard]) -> Void) -> Braze.Cancellable? {
    braze.contentCards.subscribeToUpdates { contentCards in
      processAction(contentCards)
    }
  }

  /// Subscribes to banners updates and passes them to the Dart layer.
  public func createBannersSubscription(_ processAction: @escaping ([String: Braze.Banner]) -> Void) -> Braze.Cancellable? {
    braze.banners.subscribeToUpdates { banners in
      processAction(banners)
    }
  }

  /// Subscribes to push updates and passes them to the Dart layer.
  public func createPushNotificationSubscription(_ processAction: @escaping (Braze.Notifications.Payload) -> Void) -> Braze.Cancellable? {
    braze.notifications.subscribeToUpdates { payload in
      processAction(payload)
    }
  }

  /// Subscribes to feature flags updates and passes them to the Dart layer.
  public func createFeatureFlagsSubscription(_ processAction: @escaping ([Braze.FeatureFlag]) -> Void) -> Braze.Cancellable? {
    braze.featureFlags.subscribeToUpdates { featureFlags in
      processAction(featureFlags)
    }
  }

  /// Sets the default in-app message presenter,
  /// which subscribes to in-app message updates and passes them to the Dart layer.
  @MainActor
  public func setDefaultPresenter(_ processAction: @escaping (Braze.InAppMessage) -> Void) {
    let inAppMessageUI = DefaultFlutterInAppMessagePresenter(processAction)
    braze.inAppMessagePresenter = inAppMessageUI
  }
}

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

protocol BrazeProviding {
  var braze: Braze { get }
  
  func createBannersSubscription(_ processAction: @escaping ([String: Braze.Banner]) -> Void) -> Braze.Cancellable?
  func createContentCardsSubscription(_ processAction: @escaping ([Braze.ContentCard]) -> Void) -> Braze.Cancellable?
  func createPushNotificationSubscription(_ processAction: @escaping (Braze.Notifications.Payload) -> Void) -> Braze.Cancellable?
  func createFeatureFlagsSubscription(_ processAction: @escaping ([Braze.FeatureFlag]) -> Void) -> Braze.Cancellable?

  @MainActor
  func setDefaultPresenter(_ processAction: @escaping (Braze.InAppMessage) -> Void)

  func removeSubscription(_ subscription: inout Braze.Cancellable?)
}
