part of './braze_plugin.dart';

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
  static StreamSubscription<Map<String, dynamic>> subscribeToResizeEvents(Function(Map<String, dynamic>) onResize) {
    return bannerResizeStream.listen(onResize);
  }
}

/// Helper class to manage key-value properties of a given channel campaign.
class _CampaignProperties implements Map<dynamic, dynamic> {
  /// Map of optional additional properties of the campaign.
  Map _properties;

  _CampaignProperties(Map inputProperties) : _properties = inputProperties {}

  /// Returns a string value of the campaign's properties for the given key.
  /// Returns null if the key is not a string property or if there is no property for that key.
  String? getStringProperty(String key) {
    var data = _properties[key];
    if (data != null && data["type"] == "string") {
      return _safeCast(data["value"]);
    }
    return null;
  }

  /// Returns a boolean value of the campaign's properties for the given key.
  /// Returns null if the key is not a boolean property or if there is no property for that key.
  bool? getBooleanProperty(String key) {
    var data = _properties[key];
    if (data != null && data["type"] == "boolean") {
      return _safeCast(data["value"]);
    }
    return null;
  }

  /// Returns a number value of the campaign's properties for the given key.
  /// Returns null if the key is not a number or if there is no property for that key.
  num? getNumberProperty(String key) {
    var data = _properties[key];
    if (data != null && data["type"] == "number") {
      return _safeCast(data["value"]);
    }
    return null;
  }

  /// Returns an integer value (which can hold the value of any `long`) of the
  /// campaign's properties for the given key.
  /// Returns null if the key is not an integer or if there is no property for that key.
  int? getTimestampProperty(String key) {
    var data = _properties[key];
    if (data != null && data["type"] == "datetime") {
      return _safeCast(data["value"]);
    }
    return null;
  }

  /// Returns a Map of the campaign's properties for the given key.
  /// Returns null if the key is not a Map object or if there is no property for that key.
  Map<String, dynamic>? getJSONProperty(String key) {
    var data = _properties[key];
    if (data != null && data["type"] == "jsonobject") {
      return _safeCast(data["value"]);
    }
    return null;
  }

  /// Returns a string representing an image of the campaign's properties
  /// for the given key.
  /// Returns null if the key is not a string or if there is no property for that key.
  String? getImageProperty(String key) {
    var data = _properties[key];
    if (data != null && data["type"] == "image") {
      return _safeCast(data["value"]);
    }
    return null;
  }

  // Helper Methods

  /// Tries to cast a value to type `T`. If it cannot be cast, the result wil be `null`.
  T? _safeCast<T>(Object? value) {
    return value is T ? value : null;
  }

  // Map Methods

  @override
  dynamic operator [](Object? key) => _properties[key];

  @override
  void operator []=(dynamic key, dynamic value) {
    _properties[key] = value;
  }

  @override
  void clear() => _properties.clear();

  @override
  Iterable<dynamic> get keys => _properties.keys;

  @override
  dynamic remove(Object? key) => _properties.remove(key);

  @override
  bool containsKey(Object? key) => _properties.containsKey(key);

  @override
  bool containsValue(Object? value) => _properties.containsValue(value);

  @override
  void forEach(void Function(dynamic key, dynamic value) action) =>
      _properties.forEach(action);

  @override
  bool get isEmpty => _properties.isEmpty;

  @override
  bool get isNotEmpty => _properties.isNotEmpty;

  @override
  int get length => _properties.length;

  @override
  void addAll(Map<dynamic, dynamic> other) => _properties.addAll(other);

  @override
  Map<RK, RV> cast<RK, RV>() => _properties.cast<RK, RV>();

  @override
  dynamic putIfAbsent(dynamic key, dynamic Function() ifAbsent) =>
      _properties.putIfAbsent(key, ifAbsent);

  @override
  void addEntries(Iterable<MapEntry<dynamic, dynamic>> entries) =>
      _properties.addEntries(entries);

  @override
  dynamic update(dynamic key, dynamic Function(dynamic value) update,
          {dynamic Function()? ifAbsent}) =>
      _properties.update(key, update, ifAbsent: ifAbsent);

  @override
  void updateAll(dynamic Function(dynamic key, dynamic value) update) =>
      _properties.updateAll(update);

  @override
  Iterable<dynamic> get values => _properties.values;

  @override
  void removeWhere(bool Function(dynamic key, dynamic value) predicate) =>
      _properties.removeWhere(predicate);

  @override
  String toString() => _properties.toString();

  @override
  Iterable<MapEntry> get entries => _properties.entries;

  @override
  Map<K2, V2> map<K2, V2>(
      MapEntry<K2, V2> Function(dynamic key, dynamic value) convert) {
    return _properties.map(convert);
  }
}
