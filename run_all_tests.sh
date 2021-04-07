echo "Running braze_plugin unit tests..."
flutter test test/braze_plugin_test.dart

echo "\nRunning Android integration tests..."
cd example
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/braze_plugin_integration_test.dart

echo "\nTesting Android V1 and V2 Embedding..."
flutter build apk
cd android
./gradlew app:connectedAndroidTest -Ptarget=`pwd`/../integration_test/braze_plugin_integration_test.dart
cd ..

echo "Done running tests! ✅"
