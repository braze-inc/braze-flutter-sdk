import 'dart:convert' as json;

import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/test_data.dart';
import 'fixtures/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> log;
  bool wasInitialized = false;
  bool shouldReturnNullFeatureFlag = false;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel('braze_plugin'),
            (MethodCall methodCall) async {
      if (methodCall.method == 'setBrazePluginIsReady') {
        wasInitialized = true;
        return null;
      }
      if (!wasInitialized) {
        throw Exception('Plugin not initialized');
      }
      if (methodCall.method == 'setLogLevel') {
        return null;
      }
      log.add(methodCall);
      switch (methodCall.method) {
        case 'getDeviceId':
          return TestData.mockDeviceId;
        case 'getUserId':
          return TestData.mockUserId;
        case 'getAllFeatureFlags':
          return [TestData.featureFlagJson];
        case 'getFeatureFlagByID':
          return shouldReturnNullFeatureFlag ? null : TestData.featureFlagJson;
        case 'getCachedContentCards':
          return [TestData.contentCardJson];
        default:
          return null;
      }
    });
  });

  setUp(() {
    log = [];
    shouldReturnNullFeatureFlag = false;
  });

  group('Braze Plugin Initialization', () {
    test('should call initialize', () {
      final braze = BrazePlugin();
      const apiKey = 'test-api-key';
      const endpoint = 'test-endpoint';
      braze.initialize(apiKey, endpoint);
      expect(log, <Matcher>[
        isMethodCall(
          'initialize',
          arguments: <String, dynamic>{
            'apiKey': apiKey,
            'endpoint': endpoint
          },
        ),
      ]);
    });
  });

  group('User Management', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call changeUser', () {
      const testUser = 'thistestuser';
      const sdkAuthSignature = 'sdkauthsignature';
      braze.changeUser(testUser);
      braze.changeUser(testUser, sdkAuthSignature: sdkAuthSignature);
      expect(log, <Matcher>[
        isMethodCall('changeUser',
            arguments: <String, dynamic>{'userId': testUser}),
        isMethodCall('changeUser', arguments: <String, dynamic>{
          'userId': testUser,
          'sdkAuthSignature': sdkAuthSignature,
        }),
      ]);
    });

    test('should call getUserId with current user', () async {
      final result = await braze.getUserId();
      expect(log, <Matcher>[
        isMethodCall('getUserId', arguments: null)
      ]);
      expect(result, TestData.mockUserId);
    });

    test('should call setSdkAuthenticationSignature', () {
      const sdkAuthSignature = 'sdkauthsignature';
      braze.setSdkAuthenticationSignature(sdkAuthSignature);
      expect(log, <Matcher>[
        isMethodCall(
          'setSdkAuthenticationSignature',
          arguments: <String, dynamic>{'sdkAuthSignature': sdkAuthSignature},
        ),
      ]);
    });

    test('should call setBrazeSdkAuthenticationErrorCallback', () {
      braze.setBrazeSdkAuthenticationErrorCallback((error) {});
      expect(log, <Matcher>[
        isMethodCall(
          'setSdkAuthenticationDelegate',
          arguments: null,
        ),
      ]);
    });
  });

  group('Event Logging', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call logCustomEvent with no properties', () {
      const eventName = 'someEvent';
      braze.logCustomEvent(eventName);
      expect(log, <Matcher>[
        isMethodCall(
          'logCustomEvent',
          arguments: <String, dynamic>{
            'eventName': eventName,
          },
        ),
      ]);
    });

    test('should call logCustomEvent with optional properties', () {
      const eventName = 'someEvent';
      final properties = {'someKey': 'someValue'};
      braze.logCustomEvent(eventName, properties: properties);
      expect(log, <Matcher>[
        isMethodCall(
          'logCustomEvent',
          arguments: <String, dynamic>{
            'eventName': eventName,
            'properties': properties,
          },
        ),
      ]);
    });

    test('should call logCustomEvent with nested properties', () {
      const eventName = 'someEvent';
      final properties = <String, dynamic>{
        'map_key': {'foo': 'bar'},
        'array_key': ['string', 123, false],
        'nested_map': {
          'inner_array': ['hello', 'world', 123.45, true],
          'inner_map': {'double': 101.1}
        },
        'nested_array': [
          ['obj', {'key': 'value'}, ['element', 'element2', 50], 12]
        ]
      };
      braze.logCustomEvent(eventName, properties: properties);
      expect(log, <Matcher>[
        isMethodCall(
          'logCustomEvent',
          arguments: <String, dynamic>{
            'eventName': eventName,
            'properties': properties,
          },
        ),
      ]);
    });

    test('should call logPurchase with no properties', () {
      const productId = 'someProduct';
      const currencyCode = 'someCurrencyCode';
      const price = 4.2;
      const quantity = 42;
      braze.logPurchase(productId, currencyCode, price, quantity);
      expect(log, <Matcher>[
        isMethodCall(
          'logPurchase',
          arguments: <String, dynamic>{
            'productId': productId,
            'currencyCode': currencyCode,
            'price': price,
            'quantity': quantity,
          },
        ),
      ]);
    });

    test('should call logPurchase with optional properties', () {
      const productId = 'someProduct';
      const currencyCode = 'someCurrencyCode';
      const price = 4.2;
      const quantity = 42;
      final properties = {'someKey': 'someValue'};
      braze.logPurchase(productId, currencyCode, price, quantity,
          properties: properties);
      expect(log, <Matcher>[
        isMethodCall(
          'logPurchase',
          arguments: <String, dynamic>{
            'productId': productId,
            'currencyCode': currencyCode,
            'price': price,
            'quantity': quantity,
            'properties': properties
          },
        ),
      ]);
    });

    test('should call logPurchase with nested properties', () {
      const productId = 'someProduct';
      const currencyCode = 'someCurrencyCode';
      const price = 4.2;
      const quantity = 42;
      final properties = <String, dynamic>{
        'map_key': {'foo': 'bar'},
        'array_key': ['string', 123, false],
        'nested_map': {
          'inner_array': ['hello', 'world', 123.45, true],
          'inner_map': {'double': 101.1}
        },
        'nested_array': [
          ['obj', {'key': 'value'}, ['element', 'element2', 50], 12]
        ]
      };
      braze.logPurchase(productId, currencyCode, price, quantity,
          properties: properties);
      expect(log, <Matcher>[
        isMethodCall(
          'logPurchase',
          arguments: <String, dynamic>{
            'productId': productId,
            'currencyCode': currencyCode,
            'price': price,
            'quantity': quantity,
            'properties': properties,
          },
        ),
      ]);
    });

    test('should call logFeatureFlagImpression', () {
      const id = 'test_flag_id';
      braze.logFeatureFlagImpression(id);
      expect(log, <Matcher>[
        isMethodCall(
          'logFeatureFlagImpression',
          arguments: <String, dynamic>{'id': id},
        ),
      ]);
    });
  });

  group('Content Cards', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call logContentCardClicked', () {
      const data = '{"someJson":"data"}';
      final contentCard = BrazeContentCard(data);
      braze.logContentCardClicked(contentCard);
      expect(log, <Matcher>[
        isMethodCall(
          'logContentCardClicked',
          arguments: <String, dynamic>{
            'contentCardString': contentCard.contentCardJsonString
          },
        ),
      ]);
    });

    test('should call logContentCardImpression', () {
      const data = '{"someJson":"data"}';
      final contentCard = BrazeContentCard(data);
      braze.logContentCardImpression(contentCard);
      expect(log, <Matcher>[
        isMethodCall(
          'logContentCardImpression',
          arguments: <String, dynamic>{
            'contentCardString': contentCard.contentCardJsonString
          },
        ),
      ]);
    });

    test('should call logContentCardDismissed', () {
      const data = '{"someJson":"data"}';
      final contentCard = BrazeContentCard(data);
      braze.logContentCardDismissed(contentCard);
      expect(log, <Matcher>[
        isMethodCall(
          'logContentCardDismissed',
          arguments: <String, dynamic>{
            'contentCardString': contentCard.contentCardJsonString
          },
        ),
      ]);
    });

    test('should call getCachedContentCards', () async {
      final result = await braze.getCachedContentCards();
      expect(log, <Matcher>[
        isMethodCall('getCachedContentCards', arguments: null)
      ]);
      expect(result.length, equals(1));
      expect(result[0].contentCardJsonString, equals(TestData.contentCardJson));
    });

    test('should include isControl field', () {
      const data = '{"tp":"control"}';
      final contentCard = BrazeContentCard(data);
      expect(contentCard.isControl, isTrue);
    });

    group('ContentCard parsing', () {
      test('with all fields parsed correctly', () {
        final data = TestData.makeContentCard(
          id: 'card_id',
          clicked: true,
          created: 111,
          description: 'desc',
          dismissable: false,
          expiresAt: 222,
          extras: {'key': 'val'},
          image: 'img',
          imageAspectRatio: 2.5,
          linkText: 'link',
          pinned: true,
          removed: true,
          title: 'title',
          type: 'type',
          url: 'url',
          useWebView: false,
          viewed: true,
        );
        final card = TestHelpers.contentCardFromMap(data);
        expect(card.id, equals('card_id'));
        expect(card.clicked, isTrue);
        expect(card.created, equals(111));
        expect(card.description, equals('desc'));
        expect(card.dismissable, isFalse);
        expect(card.expiresAt, equals(222));
        expect(card.image, equals('img'));
        expect(card.imageAspectRatio, equals(2.5));
        expect(card.linkText, equals('link'));
        expect(card.pinned, isTrue);
        expect(card.removed, isTrue);
        expect(card.title, equals('title'));
        expect(card.type, equals('type'));
        expect(card.url, equals('url'));
        expect(card.useWebView, isFalse);
        expect(card.viewed, isTrue);
      });

      test('toString works', () {
        final data = TestData.makeContentCard(title: 'test title');
        final card = TestHelpers.contentCardFromMap(data);
        final result = card.toString();
        expect(result, allOf(
          contains('BrazeContentCard'),
          contains('test title'),
        ));
      });
    });
  });

  group('In-App Messages', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call logInAppMessageClicked', () {
      final inAppMessage = BrazeInAppMessage(TestData.inAppMessageJson);
      braze.logInAppMessageClicked(inAppMessage);
      expect(log, <Matcher>[
        isMethodCall(
          'logInAppMessageClicked',
          arguments: <String, dynamic>{
            'inAppMessageString': TestData.inAppMessageJson
          },
        ),
      ]);
    });

    test('should call logInAppMessageImpression', () {
      final inAppMessage = BrazeInAppMessage(TestData.inAppMessageJson);
      braze.logInAppMessageImpression(inAppMessage);
      expect(log, <Matcher>[
        isMethodCall(
          'logInAppMessageImpression',
          arguments: <String, dynamic>{
            'inAppMessageString': TestData.inAppMessageJson
          },
        ),
      ]);
    });

    test('should call logInAppMessageButtonClicked', () {
      final inAppMessage = BrazeInAppMessage(TestData.inAppMessageJson);
      const buttonId = 42;
      braze.logInAppMessageButtonClicked(inAppMessage, buttonId);
      expect(log, <Matcher>[
        isMethodCall(
          'logInAppMessageButtonClicked',
          arguments: <String, dynamic>{
            'inAppMessageString': TestData.inAppMessageJson,
            'buttonId': buttonId
          },
        ),
      ]);
    });

    test('should call hideCurrentInAppMessage', () {
      braze.hideCurrentInAppMessage();
      expect(log, <Matcher>[
        isMethodCall('hideCurrentInAppMessage', arguments: null),
      ]);
    });

    group('InAppMessage parsing', () {
      test('instantiate with full data', () {
        final message = BrazeInAppMessage(TestData.inAppMessageJson);
        expect(message.message, isNotEmpty);
        expect(message.messageType.name, equals('modal'));
        expect(message.buttons, isNotEmpty);
      });

      test('instantiate with expected defaults', () {
        final message = BrazeInAppMessage('{}');
        expect(message.message, isEmpty);
        expect(message.messageType.name, equals('slideup'));
        expect(message.uri, isEmpty);
        expect(message.useWebView, isFalse);
        expect(message.duration, equals(5));
        expect(message.buttons, isEmpty);
      });

      test('return original JSON when calling toString', () {
        final message = BrazeInAppMessage(TestData.inAppMessageJson);
        expect(message.toString(), equals(TestData.inAppMessageJson));
      });

      test('with isTestSend field', () {
        final jsonStr = json.jsonEncode({'message': 'test', 'is_test_send': true});
        final message = BrazeInAppMessage(jsonStr);
        expect(message.isTestSend, isTrue);
      });

      group('message type parsing', () {
        final testCases = {
          'MODAL': 'modal',
          'SLIDEUP': 'slideup',
          'FULL': 'full',
          'HTML': 'html',
          'HTML_FULL': 'html_full',
        };

        testCases.forEach((type, name) {
          test('parses $type as $name', () {
            final jsonStr = json.jsonEncode({'type': type});
            final message = BrazeInAppMessage(jsonStr);
            expect(message.messageType.name, equals(name));
          });
        });
      });

      group('click action parsing', () {
        final testCases = <String, ClickAction>{
          'URI': ClickAction.uri,
          'NEWS_FEED': ClickAction.news_feed,
          'NONE': ClickAction.none,
        };

        testCases.forEach((action, expected) {
          test('parses $action correctly', () {
            final jsonStr = json.jsonEncode({'click_action': action});
            final message = BrazeInAppMessage(jsonStr);
            expect(message.clickAction, equals(expected));
          });
        });
      });

      group('dismiss type parsing', () {
        final testCases = <String, DismissType>{
          'SWIPE': DismissType.swipe,
          'AUTO_DISMISS': DismissType.auto_dismiss,
        };

        testCases.forEach((type, expected) {
          test('parses $type correctly', () {
            final jsonStr = json.jsonEncode({'message_close': type});
            final message = BrazeInAppMessage(jsonStr);
            expect(message.dismissType, equals(expected));
          });
        });
      });
    });

    group('BrazeButton', () {
      test('instantiate from JSON with all fields', () {
        final buttonData = TestData.makeButton(
          id: 53,
          text: 'some text',
          clickAction: 'URI',
          uri: 'https://test.com',
          useWebview: true,
        );
        final button = BrazeButton(buttonData);
        expect(button.id, equals(53));
        expect(button.text, equals('some text'));
        expect(button.clickAction.name, equals('uri'));
        expect(button.uri, equals('https://test.com'));
        expect(button.useWebView, isTrue);
      });

      test('instantiate with expected defaults', () {
        final button = BrazeButton({});
        expect(button.id, equals(0));
        expect(button.text, isEmpty);
        expect(button.clickAction.name, equals('none'));
        expect(button.uri, isEmpty);
        expect(button.useWebView, isFalse);
      });

      test('toString works', () {
        final button = BrazeButton({
          'id': 1,
          'text': 'Click me',
          'uri': 'https://example.com',
          'click_action': 'URI',
          'use_webview': false
        });
        final result = button.toString();
        expect(result, allOf(
          contains('BrazeButton'),
          contains('Click me'),
          contains('https://example.com'),
        ));
      });

      test('click action NONE', () {
        final button = BrazeButton({'click_action': 'NONE'});
        expect(button.clickAction, equals(ClickAction.none));
      });
    });
  });

  group('Banners', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call logBannerImpression', () {
      const placementId = 'placement1';
      braze.logBannerImpression(placementId);
      expect(log, <Matcher>[
        isMethodCall(
          'logBannerImpression',
          arguments: <String, dynamic>{'placementId': placementId},
        ),
      ]);
    });

    test('should call logBannerClicked', () {
      const placementId = 'placement1';
      const buttonId = 'button1';
      braze.logBannerClicked(placementId, buttonId);
      expect(log, <Matcher>[
        isMethodCall(
          'logBannerClicked',
          arguments: <String, dynamic>{
            'placementId': placementId,
            'buttonId': buttonId
          },
        ),
      ]);
    });

    test('should call logBannerClicked with no buttonId', () {
      const placementId = 'placement1';
      braze.logBannerClicked(placementId, null);
      expect(log, <Matcher>[
        isMethodCall(
          'logBannerClicked',
          arguments: <String, dynamic>{
            'placementId': placementId,
            'buttonId': null
          },
        ),
      ]);
    });

    test('should call requestBannersRefresh with all params', () async {
      final placementIds = [
        'placement1',
        'placement2',
        'abcdefghijkl',
        'MNOPQRSTUVWXYZ',
        '1234567890',
        '!@#%^&*()?<>-_=+'
      ];
      braze.requestBannersRefresh(placementIds);
      expect(log, <Matcher>[
        isMethodCall(
          'requestBannersRefresh',
          arguments: <String, dynamic>{'placementIds': placementIds},
        ),
      ]);
    });

    test('should call getBanner with all params', () {
      const placementId = 'placement1';
      braze.getBanner(placementId);
      expect(log, <Matcher>[
        isMethodCall(
          'getBanner',
          arguments: <String, dynamic>{'placementId': placementId},
        ),
      ]);
    });

    test('getBanner returns null when native layer returns null', () async {
      final result = await braze.getBanner('non_existent_placement');
      expect(result, isNull);
    });

    test('should call dismissBanner with placementId', () {
      const placementId = 'placement1';
      braze.dismissBanner(placementId);
      expect(log, <Matcher>[
        isMethodCall(
          'dismissBanner',
          arguments: <String, dynamic>{'placementId': placementId},
        ),
      ]);
    });

    group('BrazeBanner parsing', () {
      test('convenience functions work', () async {
        final banner = TestHelpers.bannerFromMap(
          TestData.makeBanner(
            properties: {
              'stringkey': {'type': 'string', 'value': 'stringValue'},
              'booleankey': {'type': 'boolean', 'value': true},
              'number1key': {'type': 'number', 'value': 4},
              'number2key': {'type': 'number', 'value': 5.1},
              'timestamp1Key': {'type': 'datetime', 'value': 12345},
              'timestamp2Key': {'type': 'datetime', 'value': 9223372036854775807},
              'jsonKey': {'type': 'jsonobject', 'value': TestData.jsonObject},
              'image1Key': {'type': 'image', 'value': 'image_name_here'},
              'image2Key': {'type': 'image', 'value': 'https://picsum.photos/200/300'},
            },
          ),
        );
        expect(banner.trackingId, equals('test'));
        expect(banner.properties.length, equals(9));
        expect(banner.getStringProperty('stringkey'), equals('stringValue'));
        expect(banner.getBooleanProperty('booleankey'), isTrue);
        expect(banner.getNumberProperty('number1key'), equals(4));
        expect(banner.getNumberProperty('number2key'), equals(5.1));
        expect(banner.getTimestampProperty('timestamp1Key'), equals(12345));
        expect(banner.getImageProperty('image1Key'), equals('image_name_here'));
        expect(banner.getImageProperty('image2Key'), equals('https://picsum.photos/200/300'));
      });

      test('convenience functions return null for non-existent keys', () async {
        final banner = TestHelpers.bannerFromMap(TestData.makeBanner());
        expect(banner.getStringProperty('keyThatDoesntExist'), isNull);
        expect(banner.getBooleanProperty('keyThatDoesntExist'), isNull);
        expect(banner.getNumberProperty('keyThatDoesntExist'), isNull);
        expect(banner.getTimestampProperty('keyThatDoesntExist'), isNull);
        expect(banner.getJSONProperty('keyThatDoesntExist'), isNull);
        expect(banner.getImageProperty('keyThatDoesntExist'), isNull);
      });

      test('with all fields parsed correctly', () {
        final banner = TestHelpers.bannerFromMap(
          TestData.makeBanner(
            id: 'banner_id',
            placementId: 'placement1',
            stableKey: 'stable_key_1',
            isTestSend: true,
            isControl: true,
            html: '<html>',
            expiresAt: 999,
          ),
        );
        expect(banner.trackingId, equals('banner_id'));
        expect(banner.placementId, equals('placement1'));
        expect(banner.stableKey, equals('stable_key_1'));
        expect(banner.isTestSend, isTrue);
        expect(banner.isControl, isTrue);
        expect(banner.html, equals('<html>'));
        expect(banner.expiresAt, equals(999));
      });

      test('stableKey defaults to empty string when absent', () {
        final data = TestData.makeBanner()..remove('stable_key');
        final banner = TestHelpers.bannerFromMap(data);
        expect(banner.stableKey, equals(''));
      });

      test('toString works', () {
        final banner = TestHelpers.bannerFromMap(TestData.makeBanner());
        final result = banner.toString();
        expect(result, allOf(
          contains('BrazeBanner'),
          contains('test'),
          contains('test_placement'),
          contains('test_stable_key'),
        ));
      });

      test('getJSONProperty with valid data', () {
        TestHelpers.testBannerPropertyGetter(
          propertyKey: 'jsonkey',
          propertyValue: {'nested': 'value'},
          propertyType: 'jsonobject',
          getter: (banner) => banner.getJSONProperty('jsonkey'),
          expectedValue: {'nested': 'value'},
        );
      });

    });
  });

  group('Feature Flags', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call refreshFeatureFlags', () {
      braze.refreshFeatureFlags();
      expect(log, <Matcher>[
        isMethodCall('refreshFeatureFlags', arguments: null),
      ]);
    });

    test('should call getAllFeatureFlags', () async {
      final result = await braze.getAllFeatureFlags();
      expect(log, <Matcher>[
        isMethodCall('getAllFeatureFlags', arguments: null)
      ]);
      expect(result.length, equals(1));
      expect(result[0].id, equals('test'));
    });

    test('should call getFeatureFlagByID', () async {
      shouldReturnNullFeatureFlag = false;
      final result = await braze.getFeatureFlagByID('test');
      expect(log, <Matcher>[
        isMethodCall(
          'getFeatureFlagByID',
          arguments: <String, dynamic>{'id': 'test'},
        ),
      ]);
      expect(result?.id, equals('test'));
      expect(result?.enabled, isTrue);
    });

    test('getFeatureFlagByID returns null for non-existent Feature Flag',
        () async {
      shouldReturnNullFeatureFlag = true;
      final result = await braze.getFeatureFlagByID('idThatDoesntExist');
      expect(log, <Matcher>[
        isMethodCall(
          'getFeatureFlagByID',
          arguments: <String, dynamic>{'id': 'idThatDoesntExist'},
        ),
      ]);
      expect(result, isNull);
    });

    group('BrazeFeatureFlag parsing', () {
      test('convenience functions work', () async {
        final flag = TestHelpers.featureFlagFromMap(
          TestData.makeFeatureFlag(
            properties: {
              'stringkey': {'type': 'string', 'value': 'stringValue'},
              'booleankey': {'type': 'boolean', 'value': true},
              'number1key': {'type': 'number', 'value': 4},
              'number2key': {'type': 'number', 'value': 5.1},
              'timestamp1Key': {'type': 'datetime', 'value': 12345},
              'timestamp2Key': {'type': 'datetime', 'value': 9223372036854775807},
              'jsonKey': {'type': 'jsonobject', 'value': TestData.jsonObject},
              'image1Key': {'type': 'image', 'value': 'image_name_here'},
              'image2Key': {'type': 'image', 'value': 'https://picsum.photos/200/300'},
            },
          ),
        );
        expect(flag.id, equals('test'));
        expect(flag.enabled, isTrue);
        expect(flag.properties.length, equals(9));
        expect(flag.getStringProperty('stringkey'), equals('stringValue'));
        expect(flag.getBooleanProperty('booleankey'), isTrue);
        expect(flag.getNumberProperty('number1key'), equals(4));
        expect(flag.getNumberProperty('number2key'), equals(5.1));
        expect(flag.getTimestampProperty('timestamp1Key'), equals(12345));
        expect(flag.getImageProperty('image1Key'), equals('image_name_here'));
      });

      test('convenience functions return null for non-existent keys', () async {
        final flag = TestHelpers.featureFlagFromMap(
          TestData.makeFeatureFlag(),
        );
        expect(flag.getStringProperty('keyThatDoesntExist'), isNull);
        expect(flag.getBooleanProperty('keyThatDoesntExist'), isNull);
        expect(flag.getNumberProperty('keyThatDoesntExist'), isNull);
        expect(flag.getTimestampProperty('keyThatDoesntExist'), isNull);
        expect(flag.getJSONProperty('keyThatDoesntExist'), isNull);
        expect(flag.getImageProperty('keyThatDoesntExist'), isNull);
      });

      group('property getters', () {
        test('getStringProperty with wrong type returns null', () {
          TestHelpers.testPropertyGetterWrongType<String>(
            propertyKey: 'numberkey',
            propertyValue: 42,
            propertyType: 'number',
            getter: (flag) => flag.getStringProperty('numberkey'),
          );
        });

        test('getBooleanProperty with wrong type returns null', () {
          TestHelpers.testPropertyGetterWrongType<bool>(
            propertyKey: 'stringkey',
            propertyValue: 'text',
            propertyType: 'string',
            getter: (flag) => flag.getBooleanProperty('stringkey'),
          );
        });

        test('getNumberProperty with wrong type returns null', () {
          TestHelpers.testPropertyGetterWrongType<num>(
            propertyKey: 'stringkey',
            propertyValue: 'text',
            propertyType: 'string',
            getter: (flag) => flag.getNumberProperty('stringkey'),
          );
        });

        test('getTimestampProperty with wrong type returns null', () {
          TestHelpers.testPropertyGetterWrongType<int>(
            propertyKey: 'stringkey',
            propertyValue: 'text',
            propertyType: 'string',
            getter: (flag) => flag.getTimestampProperty('stringkey'),
          );
        });

        test('getJSONProperty with valid map returns value', () {
          final expectedMap = {'nested': 'value', 'count': 123};
          TestHelpers.testPropertyGetter(
            propertyKey: 'jsonkey',
            propertyValue: expectedMap,
            propertyType: 'jsonobject',
            getter: (flag) => flag.getJSONProperty('jsonkey'),
            expectedValue: expectedMap,
          );
        });

        test('getJSONProperty with wrong type returns null', () {
          TestHelpers.testPropertyGetterWrongType<Map>(
            propertyKey: 'stringkey',
            propertyValue: 'text',
            propertyType: 'string',
            getter: (flag) => flag.getJSONProperty('stringkey'),
          );
        });

        test('getImageProperty with wrong type returns null', () {
          TestHelpers.testPropertyGetterWrongType<String>(
            propertyKey: 'stringkey',
            propertyValue: 'text',
            propertyType: 'string',
            getter: (flag) => flag.getImageProperty('stringkey'),
          );
        });
      });
    });
  });

  group('Custom Attributes', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call addToCustomAttributeArray', () {
      const key = 'someKey';
      const value = 'someValue';
      braze.addToCustomAttributeArray(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'addToCustomAttributeArray',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call removeFromCustomAttributeArray', () {
      const key = 'someKey';
      const value = 'someValue';
      braze.removeFromCustomAttributeArray(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'removeFromCustomAttributeArray',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setStringCustomUserAttribute', () {
      const key = 'someKey';
      const value = 'someValue';
      braze.setStringCustomUserAttribute(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setStringCustomUserAttribute',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setNestedCustomUserAttribute', () {
      const key = 'someKey';
      final value = <String, dynamic>{'k': 'v'};
      braze.setNestedCustomUserAttribute(key, value);
      braze.setNestedCustomUserAttribute(key, value, true);
      expect(log, <Matcher>[
        isMethodCall('setNestedCustomUserAttribute',
            arguments: <String, dynamic>{'key': key, 'value': value, 'merge': false}),
        isMethodCall('setNestedCustomUserAttribute',
            arguments: <String, dynamic>{'key': key, 'value': value, 'merge': true}),
      ]);
    });

    test('should call setCustomUserAttributeArrayOfStrings', () {
      const key = 'someKey';
      final value = <String>['a', 'b'];
      braze.setCustomUserAttributeArrayOfStrings(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setCustomUserAttributeArrayOfStrings',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setCustomUserAttributeArrayOfObjects', () {
      const key = 'someKey';
      final value = <Map<String, dynamic>>[
        {'a': 'b'},
        {'c': 'd'}
      ];
      braze.setCustomUserAttributeArrayOfObjects(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setCustomUserAttributeArrayOfObjects',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setDoubleCustomUserAttribute', () {
      const key = 'someKey';
      const value = 4.2;
      braze.setDoubleCustomUserAttribute(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setDoubleCustomUserAttribute',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setBoolCustomUserAttribute', () {
      const key = 'someKey';
      const value = false;
      braze.setBoolCustomUserAttribute(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setBoolCustomUserAttribute',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setIntCustomUserAttribute', () {
      const key = 'someKey';
      const value = 42;
      braze.setIntCustomUserAttribute(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setIntCustomUserAttribute',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call incrementCustomUserAttribute', () {
      const key = 'someKey';
      const value = 42;
      braze.incrementCustomUserAttribute(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'incrementCustomUserAttribute',
          arguments: <String, dynamic>{'key': key, 'value': value},
        ),
      ]);
    });

    test('should call setLocationCustomAttribute', () {
      const key = 'someKey';
      const lat = 12.34;
      const long = 56.78;
      braze.setLocationCustomAttribute(key, lat, long);
      expect(log, <Matcher>[
        isMethodCall(
          'setLocationCustomAttribute',
          arguments: <String, dynamic>{'key': key, 'lat': lat, 'long': long},
        ),
      ]);
    });

    test('should call setDateCustomUserAttribute', () {
      const key = 'someKey';
      final value = DateTime.now();
      braze.setDateCustomUserAttribute(key, value);
      expect(log, <Matcher>[
        isMethodCall(
          'setDateCustomUserAttribute',
          arguments: <String, dynamic>{
            'key': key,
            'value': value.millisecondsSinceEpoch ~/ 1000
          },
        ),
      ]);
    });

    test('should call unsetCustomUserAttribute', () {
      const key = 'someKey';
      braze.unsetCustomUserAttribute(key);
      expect(log, <Matcher>[
        isMethodCall(
          'unsetCustomUserAttribute',
          arguments: <String, dynamic>{'key': key},
        ),
      ]);
    });
  });

  group('Profile Properties', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call setFirstName', () {
      braze.setFirstName('someFirstName');
      braze.setFirstName(null);
      expect(log, <Matcher>[
        isMethodCall('setFirstName',
            arguments: <String, dynamic>{'firstName': 'someFirstName'}),
        isMethodCall('setFirstName',
            arguments: <String, dynamic>{'firstName': null}),
      ]);
    });

    test('should call setLastName', () {
      braze.setLastName('someLastName');
      braze.setLastName(null);
      expect(log, <Matcher>[
        isMethodCall('setLastName',
            arguments: <String, dynamic>{'lastName': 'someLastName'}),
        isMethodCall('setLastName',
            arguments: <String, dynamic>{'lastName': null}),
      ]);
    });

    test('should call setEmail', () {
      braze.setEmail('someEmail');
      braze.setEmail(null);
      expect(log, <Matcher>[
        isMethodCall('setEmail',
            arguments: <String, dynamic>{'email': 'someEmail'}),
        isMethodCall('setEmail',
            arguments: <String, dynamic>{'email': null}),
      ]);
    });

    test('should call setDateOfBirth', () {
      const year = 2000;
      const month = 1;
      const day = 22;
      braze.setDateOfBirth(year, month, day);
      expect(log, <Matcher>[
        isMethodCall(
          'setDateOfBirth',
          arguments: <String, dynamic>{
            'year': year,
            'month': month,
            'day': day
          },
        ),
      ]);
    });

    test('should call setGender', () {
      braze.setGender('f');
      braze.setGender(null);
      expect(log, <Matcher>[
        isMethodCall('setGender',
            arguments: <String, dynamic>{'gender': 'f'}),
        isMethodCall('setGender',
            arguments: <String, dynamic>{'gender': null}),
      ]);
    });

    test('should call setLanguage', () {
      braze.setLanguage('es');
      braze.setLanguage(null);
      expect(log, <Matcher>[
        isMethodCall('setLanguage',
            arguments: <String, dynamic>{'language': 'es'}),
        isMethodCall('setLanguage',
            arguments: <String, dynamic>{'language': null}),
      ]);
    });

    test('should call setCountry', () {
      braze.setCountry('JP');
      braze.setCountry(null);
      expect(log, <Matcher>[
        isMethodCall('setCountry',
            arguments: <String, dynamic>{'country': 'JP'}),
        isMethodCall('setCountry',
            arguments: <String, dynamic>{'country': null}),
      ]);
    });

    test('should call setHomeCity', () {
      braze.setHomeCity('someHomeCity');
      braze.setHomeCity(null);
      expect(log, <Matcher>[
        isMethodCall('setHomeCity',
            arguments: <String, dynamic>{'homeCity': 'someHomeCity'}),
        isMethodCall('setHomeCity',
            arguments: <String, dynamic>{'homeCity': null}),
      ]);
    });

    test('should call setPhoneNumber', () {
      braze.setPhoneNumber('8675309');
      braze.setPhoneNumber(null);
      expect(log, <Matcher>[
        isMethodCall('setPhoneNumber',
            arguments: <String, dynamic>{'phoneNumber': '8675309'}),
        isMethodCall('setPhoneNumber',
            arguments: <String, dynamic>{'phoneNumber': null}),
      ]);
    });

    test('should call setAttributionData', () {
      const network = 'someNetwork';
      const campaign = 'someCampaign';
      const adGroup = 'someAdGroup';
      const creative = 'someCreative';
      braze.setAttributionData(network, campaign, adGroup, creative);
      expect(log, <Matcher>[
        isMethodCall(
          'setAttributionData',
          arguments: <String, dynamic>{
            'network': network,
            'campaign': campaign,
            'adGroup': adGroup,
            'creative': creative
          },
        ),
      ]);
    });
  });

  group('Device & Tracking', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call getDeviceId', () async {
      final result = await braze.getDeviceId();
      expect(log, <Matcher>[
        isMethodCall('getDeviceId', arguments: null)
      ]);
      expect(result, TestData.mockDeviceId);
    });

    test('should call registerPushToken with a hex string', () {
      const pushToken =
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
      braze.registerPushToken(pushToken);
      expect(log, <Matcher>[
        isMethodCall(
          'registerPushToken',
          arguments: <String, dynamic>{'pushToken': pushToken},
        ),
      ]);
    });

    test('should call requestImmediateDataFlush', () {
      braze.requestImmediateDataFlush();
      expect(log, <Matcher>[
        isMethodCall('requestImmediateDataFlush', arguments: null),
      ]);
    });

    test('should call setAdTrackingEnabled', () {
      braze.setAdTrackingEnabled(true, 'some_id');
      braze.setAdTrackingEnabled(false, null);
      expect(log, <Matcher>[
        isMethodCall('setAdTrackingEnabled',
            arguments: <String, dynamic>{'adTrackingEnabled': true, 'id': 'some_id'}),
        isMethodCall('setAdTrackingEnabled',
            arguments: <String, dynamic>{'adTrackingEnabled': false}),
      ]);
    });

    test('should call setLastKnownLocation with all params', () {
      braze.setLastKnownLocation(
        latitude: 12,
        longitude: 34.5,
        altitude: 6,
        accuracy: 78,
        verticalAccuracy: 90.12,
      );
      expect(log, <Matcher>[
        isMethodCall(
          'setLastKnownLocation',
          arguments: <String, dynamic>{
            'latitude': 12,
            'longitude': 34.5,
            'altitude': 6,
            'accuracy': 78,
            'verticalAccuracy': 90.12,
          },
        ),
      ]);
    });

    test('should call setLastKnownLocation without optional params', () {
      braze.setLastKnownLocation(latitude: 12, longitude: 34.5);
      braze.setLastKnownLocation(latitude: 12, longitude: 34.5, accuracy: 6);
      expect(log, <Matcher>[
        isMethodCall(
          'setLastKnownLocation',
          arguments: <String, dynamic>{
            'latitude': 12,
            'longitude': 34.5,
            'accuracy': 0,
          },
        ),
        isMethodCall(
          'setLastKnownLocation',
          arguments: <String, dynamic>{
            'latitude': 12,
            'longitude': 34.5,
            'accuracy': 6,
          },
        ),
      ]);
    });

    test('should call requestLocationInitialization', () {
      braze.requestLocationInitialization();
      expect(log, <Matcher>[
        isMethodCall('requestLocationInitialization', arguments: null),
      ]);
    });
  });

  group('SDK Control', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call enableSDK', () {
      braze.enableSDK();
      expect(log, <Matcher>[
        isMethodCall('enableSDK', arguments: null),
      ]);
    });

    test('should call disableSDK', () {
      braze.disableSDK();
      expect(log, <Matcher>[
        isMethodCall('disableSDK', arguments: null),
      ]);
    });

    test('should call wipeData', () {
      braze.wipeData();
      expect(log, <Matcher>[
        isMethodCall('wipeData', arguments: null),
      ]);
    });
  });

  group('Content Cards UI', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call requestContentCardsRefresh', () {
      braze.requestContentCardsRefresh();
      expect(log, <Matcher>[
        isMethodCall('requestContentCardsRefresh', arguments: null),
      ]);
    });

    test('should call launchContentCards', () {
      braze.launchContentCards();
      expect(log, <Matcher>[
        isMethodCall('launchContentCards', arguments: null),
      ]);
    });
  });

  group('Subscription Management', () {
    late BrazePlugin braze;

    setUp(() {
      braze = BrazePlugin();
    });

    test('should call setPushNotificationSubscriptionType', () {
      const type = SubscriptionType.opted_in;
      braze.setPushNotificationSubscriptionType(type);
      expect(log, <Matcher>[
        isMethodCall(
          'setPushNotificationSubscriptionType',
          arguments: <String, dynamic>{'type': type.toString()},
        ),
      ]);
    });

    test('should call setEmailNotificationSubscriptionType', () {
      const type = SubscriptionType.opted_in;
      braze.setEmailNotificationSubscriptionType(type);
      expect(log, <Matcher>[
        isMethodCall(
          'setEmailNotificationSubscriptionType',
          arguments: <String, dynamic>{'type': type.toString()},
        ),
      ]);
    });

    test('should call addToSubscriptionGroup', () {
      const groupId = 'someGroupId';
      braze.addToSubscriptionGroup(groupId);
      expect(log, <Matcher>[
        isMethodCall(
          'addToSubscriptionGroup',
          arguments: <String, dynamic>{'groupId': groupId},
        ),
      ]);
    });

    test('should call removeFromSubscriptionGroup', () {
      const groupId = 'someGroupId';
      braze.removeFromSubscriptionGroup(groupId);
      expect(log, <Matcher>[
        isMethodCall(
          'removeFromSubscriptionGroup',
          arguments: <String, dynamic>{'groupId': groupId},
        ),
      ]);
    });
  });

  group('Tracking Property Allow List', () {
    test('should call updateTrackingAllowList', () {
      final braze = BrazePlugin();
      final list = BrazeTrackingPropertyList();
      list.removing = {TrackingProperty.country};
      list.addingCustomAttributes = {'attr-1'};
      list.addingCustomEvents = {'event-1'};
      list.removingCustomEvents = {'event-2', 'event-3'};
      braze.updateTrackingPropertyAllowList(list);
      expect(log, <Matcher>[
        isMethodCall('updateTrackingPropertyAllowList',
            arguments: <String, dynamic>{
              'removing': ['TrackingProperty.country'],
              'addingCustomAttributes': ['attr-1'],
              'addingCustomEvents': ['event-1'],
              'removingCustomEvents': ['event-2', 'event-3']
            })
      ]);
    });
  });

  group('Alias Management', () {
    test('should call addAlias', () {
      final braze = BrazePlugin();
      const aliasName = 'someAlias';
      const aliasLabel = 'someLabel';
      braze.addAlias(aliasName, aliasLabel);
      expect(log, <Matcher>[
        isMethodCall(
          'addAlias',
          arguments: <String, dynamic>{
            'aliasName': aliasName,
            'aliasLabel': aliasLabel
          },
        ),
      ]);
    });
  });

  group('Data Model Enum Values', () {
    test('BrazeLogLevel.fromValue returns debug for low values', () {
      expect(BrazeLogLevel.fromValue(0), equals(BrazeLogLevel.debug));
      expect(BrazeLogLevel.fromValue(499), equals(BrazeLogLevel.debug));
    });

    test('BrazeLogLevel.fromValue returns info for medium values', () {
      expect(BrazeLogLevel.fromValue(800), equals(BrazeLogLevel.info));
      expect(BrazeLogLevel.fromValue(999), equals(BrazeLogLevel.info));
    });

    test('BrazeLogLevel.fromValue returns error for high values', () {
      expect(BrazeLogLevel.fromValue(1000), equals(BrazeLogLevel.error));
      expect(BrazeLogLevel.fromValue(9999), equals(BrazeLogLevel.error));
    });

    test('BrazeLogLevel comparison operators are correctly ordered', () {
      expect(BrazeLogLevel.debug < BrazeLogLevel.info, isTrue);
      expect(BrazeLogLevel.info < BrazeLogLevel.error, isTrue);
      expect(BrazeLogLevel.error < BrazeLogLevel.debug, isFalse);
      expect(BrazeLogLevel.debug <= BrazeLogLevel.debug, isTrue);
      expect(BrazeLogLevel.error <= BrazeLogLevel.debug, isFalse);
      expect(BrazeLogLevel.error > BrazeLogLevel.debug, isTrue);
      expect(BrazeLogLevel.debug > BrazeLogLevel.error, isFalse);
      expect(BrazeLogLevel.error >= BrazeLogLevel.error, isTrue);
      expect(BrazeLogLevel.debug >= BrazeLogLevel.error, isFalse);
    });

  });

  group('Stream Subscriptions', () {
    test('BrazePlugin with inAppMessageHandler', () {
      final braze = BrazePlugin(
        inAppMessageHandler: (message) {},
      );
      expect(braze.inAppMessageStreamController, isNotNull);
    });

    test('BrazePlugin with contentCardsHandler', () {
      final braze = BrazePlugin(
        contentCardsHandler: (cards) {},
      );
      expect(braze.contentCardsStreamController, isNotNull);
    });

    test('BrazePlugin with bannersHandler', () {
      final braze = BrazePlugin(
        bannersHandler: (banners) {},
      );
      expect(braze.bannersStreamController, isNotNull);
    });

    test('BrazePlugin with featureFlagsHandler', () {
      final braze = BrazePlugin(
        featureFlagsHandler: (flags) {},
      );
      expect(braze.featureFlagsStreamController, isNotNull);
    });

    test('BrazePlugin with pushEventHandler', () {
      final braze = BrazePlugin(
        pushEventHandler: (event) {},
      );
      expect(braze.pushEventStreamController, isNotNull);
    });

    test('subscribeToInAppMessages returns subscription', () {
      final braze = BrazePlugin();
      final subscription = braze.subscribeToInAppMessages((message) {});
      expect(subscription, isNotNull);
      subscription.cancel();
    });

    test('subscribeToContentCards returns subscription', () {
      final braze = BrazePlugin();
      final subscription = braze.subscribeToContentCards((cards) {});
      expect(subscription, isNotNull);
      subscription.cancel();
    });

    test('subscribeToBanners returns subscription', () {
      final braze = BrazePlugin();
      final subscription = braze.subscribeToBanners((banners) {});
      expect(subscription, isNotNull);
      subscription.cancel();
    });

    test('subscribeToPushNotificationEvents returns subscription', () {
      final braze = BrazePlugin();
      final subscription =
          braze.subscribeToPushNotificationEvents((event) {});
      expect(subscription, isNotNull);
      subscription.cancel();
    });

    test('subscribeToFeatureFlags returns subscription', () async {
      final braze = BrazePlugin();
      final subscription = braze.subscribeToFeatureFlags((flags) {});
      expect(subscription, isNotNull);
      await Future.delayed(const Duration(milliseconds: 50));
      subscription.cancel();
    });
  });

  group('BrazePushEvent', () {
    test('parsing with all fields', () {
      final data = TestData.makePushEvent(
        payloadType: 'push_opened',
        title: 'Title',
        body: 'Body',
        url: 'https://test.com',
        useWebview: true,
        summaryText: 'Summary',
        badgeCount: 5,
        timestamp: 333,
        isSilent: true,
        isBrazeInternal: false,
        imageUrl: 'img_url',
      );
      final event = TestHelpers.pushEventFromMap(data);
      expect(event.payloadType, equals('push_opened'));
      expect(event.url, equals('https://test.com'));
      expect(event.useWebview, isTrue);
      expect(event.title, equals('Title'));
      expect(event.body, equals('Body'));
      expect(event.summaryText, equals('Summary'));
      expect(event.badgeCount, equals(5));
      expect(event.timestamp, equals(333));
      expect(event.isSilent, isTrue);
      expect(event.isBrazeInternal, isFalse);
      expect(event.imageUrl, equals('img_url'));
    });

    test('toString is non-empty', () {
      final event = TestHelpers.pushEventFromMap(
        TestData.makePushEvent(title: 'Test', body: 'Body'),
      );
      expect(event.toString(), isNotEmpty);
    });
  });

  group('BrazeSdkAuthenticationError', () {
    test('parses and toString works', () {
      final errorJson =
          '{"code":401,"reason":"Invalid signature","userId":"user123","signature":"sig"}';
      final error = BrazeSdkAuthenticationError(errorJson);
      expect(error.code, equals(401));
      expect(error.reason, equals('Invalid signature'));
      expect(error.userId, equals('user123'));
      expect(error.signature, equals('sig'));
      expect(error.toString(), equals(errorJson));
    });
  });

  group('BrazeBannerResizeManager', () {
    test('subscribeToResizeEvents returns subscription', () {
      final subscription = BrazeBannerResizeManager.subscribeToResizeEvents((event) {});
      expect(subscription, isNotNull);
      subscription.cancel();
    });
  });

}
