import BrazeKit

final class BrazeSubscriptionManager: ChannelSubscriptionManager {
  private let brazeClient: BrazeProviding
  
  private var contentCardsSubscription: Braze.Cancellable? = nil
  private var bannersSubscription: Braze.Cancellable? = nil
  private var featureFlagsSubscription: Braze.Cancellable? = nil
  private var notificationSubscription: Braze.Cancellable? = nil
  
  init(_ brazeClient: BrazeProviding) {
    self.brazeClient = brazeClient
  }
  
  /// Creates subscriptions to content cards, banners, feature flags, push notifications, and in-app messages.
  @MainActor
  func subscribeToAllChannels() {
    contentCardsSubscription = brazeClient.createContentCardsSubscription { contentCards in
      BrazePlugin.processContentCards(contentCards)
    }
    bannersSubscription = brazeClient.createBannersSubscription { banners in
      BrazePlugin.processBanners(banners)
    }
    featureFlagsSubscription = brazeClient.createFeatureFlagsSubscription { featureFlags in
      BrazePlugin.processFeatureFlags(featureFlags)
    }
    notificationSubscription = brazeClient.createPushNotificationSubscription { payload in
      BrazePlugin.processPushEvent(payload)
    }
    brazeClient.setDefaultPresenter { inAppMessage in
      BrazePlugin.processInAppMessage(inAppMessage)
    }
  }
  
  /// Cancels all subscriptions to content cards, banners, feature flags, push notifications, and in-app messages. 
  func cancelAllSubscriptions() {
    brazeClient.removeSubscription(&contentCardsSubscription)
    brazeClient.removeSubscription(&bannersSubscription)
    brazeClient.removeSubscription(&notificationSubscription)
    brazeClient.removeSubscription(&featureFlagsSubscription)
  }
}

protocol ChannelSubscriptionManager {
  func subscribeToAllChannels()
  func cancelAllSubscriptions()
}
