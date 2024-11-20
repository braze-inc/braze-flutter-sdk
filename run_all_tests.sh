echo "-> Running braze_plugin unit tests..."
flutter test test/braze_plugin_test.dart

echo "\n-> Running Android integration tests..."
cd example
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/braze_plugin_integration_test.dart

echo "\n-> Testing Android Embedding..."
flutter build apk
cd android
./gradlew app:connectedAndroidTest -Ptarget=`pwd`/../integration_test/braze_plugin_integration_test.dart
./gradlew braze_plugin:connectedAndroidTest
cd ..

echo "-> Done running tests! ✅"
