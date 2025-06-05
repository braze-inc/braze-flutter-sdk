import BrazeUI
import Flutter
import UIKit

class BrazeBannerViewFactory: NSObject, FlutterPlatformViewFactory {
  private var messenger: FlutterBinaryMessenger
  private var uiHandler: BrazeUIHandler
  private var braze: Braze?

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
    return BrazeBannerView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      binaryMessenger: messenger,
      braze: self.braze,
      uiHandler: self.uiHandler
    )
  }

  /// Required when the `arguments` in `createWithFrame` is not `nil`
  public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }

  /// Stores the Braze instance after initialization.
  ///
  /// This must be called before creating any banner views.
  public func setBraze(_ braze: Braze) {
    self.braze = braze
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

    super.init()

    // Use "" in place of a null placementId until the Swift SDK supports null.
    createNativeView(
      braze: braze!,
      placementId: placementId ?? ""
    )
  }
  
  // deinit {
  //   // Flutter doesn't automatically resize after destroying the view.
  //   resizeView(height: 0)
  // }

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
