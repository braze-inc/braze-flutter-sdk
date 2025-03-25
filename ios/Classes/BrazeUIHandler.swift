import Flutter

/// Handles UI events for native iOS views.
public class BrazeUIHandler : NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    let channel = FlutterEventChannel(name: "braze_banner_view_channel", binaryMessenger: messenger)
    channel.setStreamHandler(self)
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func sendResizeEvent(height: Double, identifier: String) {
    let resizeData: [String: Any] = ["height": height, "containerId": identifier]
    eventSink?(resizeData)
  }
}
