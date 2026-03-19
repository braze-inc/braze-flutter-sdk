import BrazeUI
import BrazeKit
import Flutter
import UIKit

class BrazeBannerViewFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger
  private var uiHandler: BrazeUIHandler
  private var braze: Braze?

  /// Weak references to all live banner views so they can be re-initialized
  /// in-place when the Braze SDK becomes available.
  private let liveViews = NSHashTable<BrazeBannerView>.weakObjects()

  init(messenger: FlutterBinaryMessenger, uiHandler: BrazeUIHandler) {
    self.messenger = messenger
    self.uiHandler = uiHandler
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let view = BrazeBannerView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      binaryMessenger: messenger,
      braze: self.braze,
      uiHandler: self.uiHandler
    )
    liveViews.add(view)
    return view
  }

  /// Required when the `arguments` in `createWithFrame` is not `nil`
  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  /// Stores the Braze instance and re-initializes any live banner views
  /// that were created before the SDK was available.
  public func setBraze(_ braze: Braze) {
    self.braze = braze
    for case let view as BrazeBannerView in liveViews.allObjects {
      view.initialize(with: braze)
    }
  }
}

/// Creates the iOS banner view and handles resizes.
class BrazeBannerView: NSObject, FlutterPlatformView {
  /// The parent view around the native iOS banner view
  private var _hostView: UIView

  /// Handles the resize events for the banner view
  private var _uiHandler: BrazeUIHandler

  /// The identifier of the Dart container view around the banner
  private var _containerId: String

  /// Stored for deferred initialization when the Braze SDK isn't yet available.
  private var _placementId: String?

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger?,
    braze: Braze?,
    uiHandler: BrazeUIHandler
  ) {
    let argsDict = args as? [String: Any]
    let placementId = argsDict?["placementId"] as? String
    let containerId = argsDict?["containerId"] as? String
    if placementId == nil || containerId == nil {
      print(
        """
        Invalid empty parameter. Banner will not render properly:
        - Placement id: \(String(describing: placementId))
        - Banner container id: \(String(describing: containerId))
        """
      )
    }

    _hostView = UIView()
    _uiHandler = uiHandler
    _containerId = containerId ?? ""
    _placementId = placementId

    super.init()

    guard let braze else {
      print("Braze SDK is not initialized. Banner will render once initialize() is called.")
      return
    }

    // Use "" in place of a null placementId until the Swift SDK supports null.
    createNativeView(
      braze: braze,
      placementId: placementId ?? ""
    )
  }

  /// Re-initializes the banner view in-place with a (newly available) Braze instance.
  /// Called by `BrazeBannerViewFactory.setBraze(_:)` after delayed initialization.
  func initialize(with braze: Braze) {
    _hostView.subviews.forEach { $0.removeFromSuperview() }
    createNativeView(braze: braze, placementId: _placementId ?? "")
  }

  func view() -> UIView {
    return _hostView
  }

  /// Initializes the banner view with its proper constraints. It also subscribes to
  /// resize updates which will update the view and the container view in the Dart layer.
  func createNativeView(
    braze: Braze,
    placementId: String
  ) {
    let bannerView = BrazeBannerUI.BannerUIView(
      placementId: placementId,
      braze: braze
    ) { [weak self] result in
      guard let self = self else { return }
      DispatchQueue.main.async {
        switch result {
        case .success(let update):
          if let height = update.height {
            self.resizeView(height: height)
          }
        case .failure(let error):
          print("BrazeBannerView error: \(error)")
        }
      }
    }

    // Flutter doesn't automatically resize when changing placements.
    // This allows us to create new native views with a fresh height.
    resizeView(height: 0)

    _hostView.addSubview(bannerView)
    bannerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bannerView.leadingAnchor.constraint(equalTo: _hostView.leadingAnchor),
      bannerView.trailingAnchor.constraint(equalTo: _hostView.trailingAnchor),
      bannerView.topAnchor.constraint(equalTo: _hostView.topAnchor),
      bannerView.bottomAnchor.constraint(equalTo: _hostView.bottomAnchor),
    ])
  }

  /// Resizes the banner view & container view based on the Banner object response
  private func resizeView(height: CGFloat) {
    if let superview = _hostView.superview {
      _hostView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        _hostView.heightAnchor.constraint(equalToConstant: height),
        superview.heightAnchor.constraint(equalTo: _hostView.heightAnchor),
        superview.widthAnchor.constraint(equalTo: _hostView.widthAnchor),
      ])
    }
    
    // Notify the Dart layer to resize the container view with updated height
    _uiHandler.sendResizeEvent(height: height, identifier: _containerId)
  }
}
