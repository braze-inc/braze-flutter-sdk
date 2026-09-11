import Flutter

extension FlutterMethodCall {

  /// Safely extracts the arguments from a Flutter method call
  ///
  /// - Returns: The arguments passed into the Flutter method call, formatted as a dictionary, or nil if not available.
  func argumentsAsDictionary() -> [String: Any]? {
    let argumentsDescription = String(describing: arguments)
    guard let argumentsDictionary = arguments as? [String: Any] else {
      print("Invalid args: \(argumentsDescription), iOS method: \(method)")
      return nil
    }
    return argumentsDictionary
  }

}
