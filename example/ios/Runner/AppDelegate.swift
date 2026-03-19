import BrazeKit
import BrazeLocation
import BrazeUI
import Flutter
import SDWebImage
import UIKit
import braze_plugin

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as? FlutterViewController

    // Store Braze configuration for delayed initialization.
    // The Braze instance will be created when initialize(apiKey, endpoint) is called from Dart.
    BrazePlugin.configure(
      { configuration in
        configuration.sessionTimeout = 1
        configuration.triggerMinimumTimeInterval = 0
        configuration.location.automaticLocationCollection = true
        configuration.location.brazeLocationProvider = BrazeLocationProvider()
        configuration.logger.level = .debug

        // Flush Braze SDK logs to the Dart layer.
        // This is strictly for testing purposes to display logs in the sample app.
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
            DispatchQueue.main.async {
              brazeLogChannel.invokeMethod("printLog", arguments: arguments)
            }
          }
          return true
        }

        configuration.push.appGroup = "group.com.braze.flutterPluginExample.PushStories"
        configuration.push.automation = true
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
