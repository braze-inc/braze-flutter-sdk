import BrazeKit
import BrazeLocation
import BrazeUI
import Flutter
import SDWebImage
import UIKit
import braze_plugin

let brazeApiKey = "9292484d-3b10-4e67-971d-ff0c0d518e21"
let brazeEndpoint = "sondheim.appboy.com"

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
