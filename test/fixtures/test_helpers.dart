import 'dart:convert';
import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

class TestHelpers {
  /// Test a property getter with type checking.
  ///
  /// Verifies that a property getter returns the correct value for the specified type
  /// and returns null when the type doesn't match.
  static void testPropertyGetter<T>({
    required String propertyKey,
    required dynamic propertyValue,
    required String propertyType,
    required T? Function(BrazeFeatureFlag) getter,
    required T? expectedValue,
  }) {
    final json = jsonEncode({
      'id': 'test',
      'enabled': true,
      'properties': {
        propertyKey: {
          'type': propertyType,
          'value': propertyValue,
        }
      }
    });

    final flag = BrazeFeatureFlag(json);
    expect(getter(flag), equals(expectedValue));
  }

  /// Test a property getter with wrong type returns null.
  static void testPropertyGetterWrongType<T>({
    required String propertyKey,
    required dynamic propertyValue,
    required String propertyType,
    required T? Function(BrazeFeatureFlag) getter,
  }) {
    final json = jsonEncode({
      'id': 'test',
      'enabled': true,
      'properties': {
        propertyKey: {
          'type': propertyType,
          'value': propertyValue,
        }
      }
    });

    final flag = BrazeFeatureFlag(json);
    expect(getter(flag), isNull);
  }

  /// Test a property getter on a banner with type checking.
  static void testBannerPropertyGetter<T>({
    required String propertyKey,
    required dynamic propertyValue,
    required String propertyType,
    required T? Function(BrazeBanner) getter,
    required T? expectedValue,
  }) {
    final json = jsonEncode({
      'id': 'test',
      'placement_id': 'test_placement',
      'html': '<p>Test</p>',
      'properties': {
        propertyKey: {
          'type': propertyType,
          'value': propertyValue,
        }
      }
    });

    final banner = BrazeBanner(json);
    expect(getter(banner), equals(expectedValue));
  }

  /// Create a banner from a JSON map.
  static BrazeBanner bannerFromMap(Map<String, dynamic> data) {
    return BrazeBanner(jsonEncode(data));
  }

  /// Create a feature flag from a JSON map.
  static BrazeFeatureFlag featureFlagFromMap(Map<String, dynamic> data) {
    return BrazeFeatureFlag(jsonEncode(data));
  }

  /// Create a content card from a JSON map.
  static BrazeContentCard contentCardFromMap(Map<String, dynamic> data) {
    return BrazeContentCard(jsonEncode(data));
  }

  /// Create a push event from a JSON map.
  static BrazePushEvent pushEventFromMap(Map<String, dynamic> data) {
    return BrazePushEvent(jsonEncode(data));
  }

  /// Create an in-app message from a JSON map.
  static BrazeInAppMessage inAppMessageFromMap(Map<String, dynamic> data) {
    return BrazeInAppMessage(jsonEncode(data));
  }
}
