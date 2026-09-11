import BrazeKit
import BrazeLocation
import BrazeUI
import Flutter
import SDWebImage
import UIKit
import UserNotifications
import braze_plugin

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    setupSampleAppChannel()

    // Store Braze configuration for delayed initialization.
    // The Braze instance will be created when initialize(apiKey, endpoint) is called from Dart.
    BrazePlugin.configure(
      { configuration in
        configuration.sessionTimeout = 1
        configuration.triggerMinimumTimeInterval = 0
        configuration.location.automaticLocationCollection = true
        configuration.location.brazeLocationProvider = BrazeLocationProvider()

        configuration.push.appGroup = "group.com.braze.flutterPluginExample.PushStories"
        configuration.push.automation = true

        // configuration.logger.level is set in the Dart layer
      },
      postInitialization: { braze in
        // Use this closure to customize the Braze instance after creation.
        // For example, set a custom in-app message presenter:
        let customPresenter = CustomInAppMessagePresenter()
        braze.inAppMessagePresenter = customPresenter
      }
    )

    // - GIF support
    GIFViewProvider.shared = .sdWebImage

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Internal channel in the sample app to communicate across the Flutter and Swift layers.
  private func setupSampleAppChannel() {
    guard
      let controller = window?.rootViewController as? FlutterViewController
    else { return }
    let pushChannel = FlutterMethodChannel(
      name: "brazeSampleAppChannel", binaryMessenger: controller.binaryMessenger)
    pushChannel.setMethodCallHandler { call, result in
      switch call.method {

      // Allows the sample app to force repopulation of the iOS push token.
      case "registerForRemoteNotifications":
        UNUserNotificationCenter.current().requestAuthorization(
          options: [.alert, .badge, .sound]
        ) { granted, error in
          // `requestAuthorization` may complete off the main thread.
          DispatchQueue.main.async {
            if let error = error {
              result(
                FlutterError(
                  code: "PUSH_AUTHORIZATION_ERROR",
                  message: error.localizedDescription,
                  details: nil))
              return
            }
            // Trigger APNs registration regardless of the prompt outcome so a
            // token is re-delivered when notifications were already authorized.
            UIApplication.shared.registerForRemoteNotifications()
            result(nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// MARK: - Custom In-App Message Presenter

class CustomInAppMessagePresenter: BrazeInAppMessageUI {

  override func present(message: Braze.InAppMessage) {
    print("=> [Custom In-App Message Presenter] Received message:", message)

    // Forward in-app message data to the Dart layer.
    BrazePlugin.processInAppMessage(message)

    // Present the default Braze UI for the in-app message.
    super.present(message: message)
  }

}

// MARK: - GIF support

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
    // Sending messages on a native platform channel must be done on the main thread.
    DispatchQueue.main.async {
      deepLinkChannel.invokeMethod("receiveDeepLink", arguments: url.absoluteString)
    }
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
