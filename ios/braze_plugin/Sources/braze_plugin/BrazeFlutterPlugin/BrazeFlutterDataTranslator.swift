import Foundation
import BrazeKit

/// Flutter-agnostic mapping from native BrazeKit types to the JSON shapes Dart expects.
enum BrazeFlutterDataTranslator {

  /// Modifies the Swift SDK's push payload to match Android push payloads
  /// and the expected payload in Dart.
  ///
  /// - Parameter originalJson: The unedited push event JSON.
  /// - Parameter pushEvent: The Braze push notification event in native Swift.
  /// - Returns: The push event JSON after updating some fields.
  static func updatePushEventJson(
    _ originalJson: [String: Any],
    pushEvent: Braze.Notifications.Payload
  ) -> [String: Any] {
    var pushEventJson = originalJson

    // - Use the `"push_` prefix for consistency with Android. The Swift SDK internally uses `"opened"`.
    if pushEventJson["payload_type"] as? String == "opened" {
      pushEventJson["payload_type"] = "push_opened"
    }

    // - Map the value with the key name "summary_text"
    pushEventJson["summary_text"] = pushEvent.subtitle

    // - Ensure the timestamp is an Int instead of a Double
    pushEventJson["timestamp"] = Int(pushEvent.date.timeIntervalSince1970)

    // - If present, add the URL of the image attached to the notification.
    //   This avoids the need to extract the field from UserInfo.
    if let brazeUserInfo = pushEvent.userInfo["ab"] as? [String: Any],
      let att = brazeUserInfo["att"] as? [String: Any],
      let imageUrl = att["url"] as? String
    {
      pushEventJson["image_url"] = imageUrl
    }

    return pushEventJson
  }

}
