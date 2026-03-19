import XCTest
import BrazeKit

final class BrazeFlutterPluginTests: XCTestCase {
  
  override class func setUp() {
    super.setUp()
  }

  // MARK: - BrazeFlutterClient Tests

  func testCreateSubscriptions() {
    let braze = Braze.init(configuration: .init())
    let brazeClient = BrazeFlutterClient(braze: braze)
    var bannerSubscription: Braze.Cancellable? = nil
    var contentCardsSubscription: Braze.Cancellable? = nil
    var featureFlagsSubscription: Braze.Cancellable? = nil
    var notificationSubscription: Braze.Cancellable? = nil
    
    XCTAssertNil(bannerSubscription)
    XCTAssertNil(contentCardsSubscription)
    XCTAssertNil(featureFlagsSubscription)
    XCTAssertNil(notificationSubscription)

    bannerSubscription = brazeClient.createBannersSubscription({ _ in })
    contentCardsSubscription = brazeClient.createContentCardsSubscription({ _ in })
    featureFlagsSubscription = brazeClient.createFeatureFlagsSubscription({ _ in })
    notificationSubscription = brazeClient.createPushNotificationSubscription({ _ in })
    
    XCTAssertNotNil(bannerSubscription)
    XCTAssertNotNil(contentCardsSubscription)
    XCTAssertNotNil(featureFlagsSubscription)
    XCTAssertNotNil(notificationSubscription)
  }
  
  func testRemoveSubscription() {
    let braze = Braze.init(configuration: .init())
    let brazeClient = BrazeFlutterClient(braze: braze)
    var subscription: Braze.Cancellable? = braze.notifications.subscribeToUpdates({ _ in })
    XCTAssertNotNil(subscription)
    brazeClient.removeSubscription(&subscription)
    XCTAssertNil(subscription)
  }

  // MARK: - Configuration closure tests

  func testConfigurationClosureAppliesSettings() {
    let configuration = Braze.Configuration(apiKey: "test-key", endpoint: "test-endpoint")
    let configBlock: (Braze.Configuration) -> Void = { config in
      config.sessionTimeout = 42
    }
    configBlock(configuration)
    XCTAssertEqual(configuration.sessionTimeout, 42)
  }

  func testPostInitializationClosureReceivesBrazeInstance() {
    var receivedBraze: Braze?
    let postInitBlock: (Braze) -> Void = { braze in
      receivedBraze = braze
    }
    let braze = Braze(configuration: .init(apiKey: "test-key", endpoint: "test-endpoint"))
    postInitBlock(braze)
    XCTAssertTrue(receivedBraze === braze)
  }
}
