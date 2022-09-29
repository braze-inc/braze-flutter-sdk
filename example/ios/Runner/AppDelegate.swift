import UIKit
import Appboy_iOS_SDK
import Flutter
import braze_plugin

let apiKey = "9292484d-3b10-4e67-971d-ff0c0d518e21"

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, ABKInAppMessageControllerDelegate {

  override func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    Appboy.start(withApiKey: apiKey,
                 in:application,
                 withLaunchOptions:launchOptions,
                 withAppboyOptions: [ABKMinimumTriggerTimeIntervalKey : 1,
                                     ABKEnableSDKAuthenticationKey : true])
    Appboy.sharedInstance()!.inAppMessageController.delegate = self

    NotificationCenter.default.addObserver(self, selector: #selector(contentCardsUpdated), name:NSNotification.Name.ABKContentCardsProcessed, object: nil)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func before(inAppMessageDisplayed inAppMessage: ABKInAppMessage) -> ABKInAppMessageDisplayChoice {
    print("Received in-app message from Braze in beforeInAppMessageDisplayed delegate.")

    // Pass in-app data to the Flutter layer.
    BrazePlugin.processInAppMessage(inAppMessage)

    // Note: return ABKInAppMessageDisplayChoice.discardInAppMessage if you would like
    // to prevent the Braze SDK from displaying the message natively.
    return ABKInAppMessageDisplayChoice.displayInAppMessageNow
  }

  @objc private func contentCardsUpdated(_ notification: Notification) {
    guard (notification.userInfo?[ABKContentCardsProcessedIsSuccessfulKey] as? Bool) == true,
           let appboy = Appboy.sharedInstance() else {
      return
    }
    
    // Pass in-app data to the Flutter layer.
    let contentCards = appboy.contentCardsController.contentCards.compactMap { $0 as? ABKContentCard }
    BrazePlugin.processContentCards(contentCards)
  }
}
