import BrazeKit
import BrazeLocation
import BrazeUI
import Flutter
import SDWebImage
import UIKit
import braze_plugin

let brazeApiKey = "9292484d-3b10-4e67-971d-ff0c0d518e21"
let brazeEndpoint = "sondheim.braze.com"

@main
@objc class AppDelegate: FlutterAppDelegate {

  // These subscriptions need to be retained to be active
  var contentCardsSubscription: Braze.Cancellable?
  var bannersSubscription: Braze.Cancellable?
  var pushEventsSubscription: Braze.Cancellable?
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
    
    // - Flush Braze SDK logs to the Dart layer.
    // This is strictly for testing purposes to display logs in the sample app.
    let controller = window?.rootViewController as? FlutterViewController
    configuration.logger.print = { [weak controller] logString, level in
      if let controller {
        let brazeLogChannel = FlutterMethodChannel(
          name: "brazeLogChannel", binaryMessenger: controller.binaryMessenger)
        var logLevel = "debug"
        switch level {
        case .debug:
          logLevel = "debug"
        case .info:
          logLevel = "info"
        case .error:
          logLevel = "error"
        case .disabled:
          logLevel = "disabled"
        @unknown default:
          logLevel = "debug"
        }
        let arguments = ["logString": logString, "level": logLevel]
        brazeLogChannel.invokeMethod("printLog", arguments: arguments)
      }
      return true
    }
    
    configuration.push.appGroup = "group.com.braze.flutterPluginExample.PushStories"

    // - Automatic push notification setup
    configuration.push.automation = true

    let braze = BrazePlugin.initBraze(configuration)

    // - GIF support
    GIFViewProvider.shared = .sdWebImage

    // - InAppMessage UI
    let inAppMessageUI = CustomInAppMessagePresenter()
    braze.inAppMessagePresenter = inAppMessageUI

    // - Subscribe to various features and pass each model to the Dart layer
    contentCardsSubscription = braze.contentCards.subscribeToUpdates { contentCards in
      print("=> [Content Card Subscription] Received cards:", contentCards)
      BrazePlugin.processContentCards(contentCards)
    }
    bannersSubscription = braze.banners.subscribeToUpdates { banners in
      print("=> [Banner Subscription] Received banners:", banners)
      BrazePlugin.processBanners(banners)
    }
    pushEventsSubscription = braze.notifications.subscribeToUpdates { payload in
      print(
        """
        => [Push Event Subscription] Received push event:
           - type: \(payload.type)
           - title: \(payload.title ?? "<empty>")
           - isSilent: \(payload.isSilent)
        """
      )
      BrazePlugin.processPushEvent(payload)
    }
    featureFlagsSubscription = braze.featureFlags.subscribeToUpdates { featureFlags in
      print("=> [Feature Flag Subscription] Received feature Flags:", featureFlags)
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
    guard
      let controller: FlutterViewController = window?.rootViewController as? FlutterViewController
    else { return }
    let deepLinkChannel = FlutterMethodChannel(
      name: "deepLinkChannel", binaryMessenger: controller.binaryMessenger)
    deepLinkChannel.invokeMethod("receiveDeepLink", arguments: url.absoluteString)
  }

  // Custom scheme
  // See https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app for more information.
  override func application(
    _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    forwardURL(url)
    return true
  }

  // Universal link
  // See https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content for more information.
  override func application(
    _ application: UIApplication, continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    else {
      return false
    }
    forwardURL(url)
    return true
  }
}
