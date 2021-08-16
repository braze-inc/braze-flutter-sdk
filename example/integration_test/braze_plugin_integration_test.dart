import 'package:flutter_test/flutter_test.dart';
import 'package:braze_plugin/braze_plugin.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Can initialize plugin', (WidgetTester tester) async {
    BrazePlugin plugin = BrazePlugin();
    Future<String> installTrackingId = plugin.getInstallTrackingId();
    expect(plugin, isNotNull);
    expect(installTrackingId, isNotNull);
  });
}
