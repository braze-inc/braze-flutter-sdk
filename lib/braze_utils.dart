import 'package:flutter/services.dart';

/// A static class that manages banner card resize events.
class BrazeBannerResizeManager {
  static const EventChannel _bannerResizeChannel =
      EventChannel('braze_banner_view_channel');

  /// Lazy-loaded stream to process banner resize events
  static Stream<Map<String, dynamic>>? _bannerResizeStream;
  static Stream<Map<String, dynamic>> get bannerResizeStream {
    _bannerResizeStream ??= _bannerResizeChannel
        .receiveBroadcastStream()
        .map((dynamic event) => Map<String, dynamic>.from(event));
    return _bannerResizeStream!;
  }

  /// Subscribes to banner card resize events
  static void subscribeToResizeEvents(Function(Map<String, dynamic>) onResize) {
    bannerResizeStream.listen(onResize);
  }
}
