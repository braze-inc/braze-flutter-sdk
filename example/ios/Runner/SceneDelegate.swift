import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  private var appDelegate: AppDelegate? {
    UIApplication.shared.delegate as? AppDelegate
  }

  // Cold start: the launch URL or user activity arrives in the connection options instead of the
  // open URL and continue callbacks.
  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    connectionOptions.urlContexts.forEach { appDelegate?.forwardURL($0.url) }
    connectionOptions.userActivities.forEach(forwardUniversalLink)
  }

  // Custom scheme
  // See https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app for more information.
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    URLContexts.forEach { appDelegate?.forwardURL($0.url) }
    super.scene(scene, openURLContexts: URLContexts)
  }

  // Universal link
  // See https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content for more information.
  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    forwardUniversalLink(userActivity)
    super.scene(scene, continue: userActivity)
  }

  private func forwardUniversalLink(_ userActivity: NSUserActivity) {
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    else { return }
    appDelegate?.forwardURL(url)
  }
}
