import UIKit
import Appboy_iOS_SDK
import Flutter
import braze_plugin

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, ABKInAppMessageControllerDelegate {

  override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    Appboy.start(withApiKey: "c64bd03c-9486-4a15-8153-d813abc64037",
                 in:application,
                 withLaunchOptions:launchOptions,
                 withAppboyOptions: [ABKMinimumTriggerTimeIntervalKey : 1])
    Appboy.sharedInstance()!.inAppMessageController.delegate = self

    NotificationCenter.default.addObserver(self, selector: #selector(contentCardsUpdated), name:NSNotification.Name.ABKContentCardsProcessed, object: nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func before(inAppMessageDisplayed inAppMessage: ABKInAppMessage) -> ABKInAppMessageDisplayChoice {
    NSLog("Received IAM from Braze in beforeInAppMessageDisplayed delegate.")

    // Pass in-app data to the Flutter layer.
    BrazePlugin.process(inAppMessage)

    // Note: return ABKInAppMessageDisplayChoice.discardInAppMessage if you would like
    // to prevent the Braze SDK from displaying the message natively.
    return ABKInAppMessageDisplayChoice.displayInAppMessageNow
  }

  @objc private func contentCardsUpdated(_ notification: Notification) {
    if let updateIsSuccessful = notification.userInfo?[ABKContentCardsProcessedIsSuccessfulKey] as? Bool {
      if (updateIsSuccessful) {
        let contentCards = Appboy.sharedInstance()?.contentCardsController.contentCards.compactMap { $0 as? ABKContentCard }

        // Pass in-app data to the Flutter layer.
        BrazePlugin.processContentCards(contentCards)
      }
    }
  }
}
