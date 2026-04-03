import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter/material.dart';

import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/screens/home_screen.dart';

/// Shows a snackbar and returns false when the sample app's [brazeSdkEnabled]
/// (from `home_screen.dart`) is false.
bool validateBrazeSdkEnabled(BuildContext context) {
  if (!brazeSdkEnabled) {
    context.showBrazeAppSnackbar(
      'SDK is not enabled. Unable to retrieve data.',
    );
    return false;
  }
  return true;
}

/// Pretty-prints a feature flag for snackbars / console.
String formatFeatureFlag(BrazeFeatureFlag ff) {
  final buffer = StringBuffer()
    ..writeln('Feature Flag ID: ${ff.id}')
    ..writeln('  Enabled: ${ff.enabled}');
  ff.properties.forEach((key, value) {
    buffer.writeln(
      '  Key: $key  Type: ${value["type"]}  Value: ${value["value"]}',
    );
  });
  return buffer.toString();
}

/// Logs the same preset events and purchases used for SDK QA.
void logPresetEventsAndPurchases() {
  var props = <String, dynamic>{
    'k1': 'v1',
    'k2': 2,
    'k3': 3.5,
    'k4': false,
  };
  braze.logCustomEvent('eventName');
  braze.logCustomEvent('eventNameProps', properties: props);
  braze.logPurchase('productId', 'USD', 3.50, 2);
  braze.logPurchase('productIdProps', 'USD', 2.50, 4, properties: props);

  props['keyWithNullValue'] = null;
  braze.logCustomEvent('eventWithNullElementInProps', properties: props);
  braze.logPurchase(
    'purchaseWithNullElementInProps',
    'EUR',
    1.23,
    6,
    properties: props,
  );

  final nestedProps = <String, dynamic>{
    'map_key': {'foo': 'bar'},
    'array_key': ['string', 123, false],
    'nested_map': {
      'inner_array': ['hello', 'world', 123.45, true],
      'inner_map': {'double': 101.1},
    },
    'nested_array': [
      [
        'obj',
        {'key': 'value'},
        ['element', 'element2', 50],
        12,
      ],
    ],
  };
  braze.logCustomEvent('nestedEvent', properties: nestedProps);
  braze.logPurchase('nestedProductId', 'EUR', 1.50, 6,
      properties: nestedProps);

  final largeValue = 'AB' * 50 * 1024;
  braze.logCustomEvent(
    'event_propertiesTooLarge',
    properties: {'largePayload': largeValue},
  );
  braze.logPurchase(
    'purchase_propertiesTooLarge',
    'EUR',
    13.3,
    7,
    properties: {'largePayload': largeValue},
  );
}
