import BrazeKit
import BrazeLocation
import BrazeUI
import Flutter
import SDWebImage
import UIKit
import braze_plugin

let brazeApiKey = "9292484d-3b10-4e67-971d-ff0c0d518e21"
let brazeEndpoint = "sondheim.braze.com"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  // These subscriptions need to be retained to be active
  var contentCardsSubscription: Braze.Cancellable?
  var featureFlagsSubscription: Braze.Cancellable?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // - Setup Braze
    let configuration = Braze.Configuration(apiKey: brazeApiKey, endpoint: brazeEndpoint)
    configuration.sessionTimeout = 1
    configuration.triggerMinimumTimeInterval = 0
    configuration.location.automaticLocationCollection = true
    configuration.location.brazeLocationProvider = BrazeLocationProvider()
    configuration.logger.level = .debug
    configuration.push.appGroup = "group.com.braze.flutterPluginExample.PushStories"

    // Automatic push notification setup
    configuration.push.automation = .init(
      automaticSetup: true,
      requestAuthorizationAtLaunch: true,
      setNotificationCategories: true,
      registerDeviceToken: true,
      handleBackgroundNotification: true,
      handleNotificationResponse: true,
      willPresentNotification: true
    )

    let braze = BrazePlugin.initBraze(configuration)

    // - GIF support
    GIFViewProvider.shared = .sdWebImage

    // - InAppMessage UI
    let inAppMessageUI = CustomInAppMessagePresenter()
    braze.inAppMessagePresenter = inAppMessageUI

    contentCardsSubscription = braze.contentCards.subscribeToUpdates { contentCards in
      print("=> [Content Card Subscription] Received cards:", contentCards)

      // Pass each content card model to the Dart layer.
      BrazePlugin.processContentCards(contentCards)
    }
    
    featureFlagsSubscription = braze.featureFlags.subscribeToUpdates { featureFlags in
      print("=> [Feature Flag Subscription] Received feature Flags:", featureFlags)
      
      // Pass each feature flag model to the Dart layer.
      BrazePlugin.processFeatureFlags(featureFlags)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: In-app message UI

class CustomInAppMessagePresenter: BrazeInAppMessageUI {

  override func present(message: Braze.InAppMessage) {
    print("=> [In-app Message] Received message from Braze:", message)

    // Pass in-app message data to the Dart layer.
    BrazePlugin.processInAppMessage(message)

    // If you want the default UI to display the in-app message.
    super.present(message: message)
  }

}

// MARK: GIF support

extension GIFViewProvider {
  public static let sdWebImage = Self(
    view: { SDAnimatedImageView(image: image(for: $0)) },
    updateView: { ($0 as? SDAnimatedImageView)?.image = image(for: $1) }
  )
  private static func image(for url: URL?) -> UIImage? {
    guard let url = url else { return nil }
    return url.pathExtension == "gif"
      ? SDAnimatedImage(contentsOfFile: url.path)
      : UIImage(contentsOfFile: url.path)
  }
}
  
// MARK: Linking
  
extension AppDelegate {
  
  private func forwardURL(_ url: URL) {
    guard let controller: FlutterViewController = window?.rootViewController as? FlutterViewController else { return }
    let deepLinkChannel = FlutterMethodChannel(name: "deepLinkChannel", binaryMessenger: controller.binaryMessenger)
    deepLinkChannel.invokeMethod("receiveDeepLink", arguments: url.absoluteString)
  }
  
  // Custom scheme
  // See https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app for more information.
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    forwardURL(url)
    return true
  }
  
  // Universal link
  // See https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content for more information.
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
      return false
    }
    forwardURL(url)
    return true
  }
}
