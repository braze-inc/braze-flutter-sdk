import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/constants/config.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Can initialize plugin', (WidgetTester tester) async {
    BrazePlugin plugin = BrazePlugin();
    Future<String> getDeviceId = plugin.getDeviceId();
    expect(plugin, isNotNull);
    expect(getDeviceId, isNotNull);
  });

  testWidgets(
      'Synchronous method calls succeed immediately after initialize call',
      (WidgetTester tester) async {
    final plugin = BrazePlugin(customConfigs: {replayCallbacksConfigKey: true});
    final apiKey = Platform.isIOS ? defaultIOSApiKey : defaultAndroidApiKey;

    plugin.initialize(apiKey, defaultEndpoint);

    const testUserId = 'test-user';
    plugin.changeUser(testUserId);

    final userId = await plugin.getUserId();
    expect(userId, testUserId);
  });
}
