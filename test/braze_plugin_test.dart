import 'dart:convert' as json;
import 'dart:io' show Platform;

import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];
  final String mockInstallTrackingId = '_test_install_tracking_id_';

  final String mockFeatureFlagJson =
      "{\"id\":\"test\",\"enabled\":true,\"properties\":{\"stringkey\":{\"type\":\"string\",\"value\":\"stringValue\"},\"booleankey\":{\"type\":\"boolean\",\"value\": true },\"number1key\":{\"type\":\"number\",\"value\": 4 },\"number2key\":{\"type\":\"number\",\"value\": 5.1}}}";

  final String mockContentCardJson =
      "{\"ca\":1234567890,\"cl\":false,\"db\":true,\"dm\":\"\",\"ds\":\"Description of Card\",\"e\":{\"timestamp\":\"1234567890\"},\"ea\":1234567890,\"id\":\"someID=\",\"p\":false,\"r\":false,\"t\":false,\"tp\":\"short_news\",\"tt\":\"Title of Card\",\"uw\":true,\"v\":false}";

  bool nullFeatureFlag = false;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(MethodChannel('braze_plugin'),
            (MethodCall methodCall) async {
      log.add(methodCall);
      // If needed to mock return values:
      switch (methodCall.method) {
        case 'getInstallTrackingId':
          return mockInstallTrackingId;
        case 'getAllFeatureFlags':
          return List<String>.generate(1, (index) => mockFeatureFlagJson);
        case 'getFeatureFlagByID':
          return nullFeatureFlag == true ? null : mockFeatureFlagJson;
        case 'getCachedContentCards':
          return List<String>.generate(1, (index) => mockContentCardJson);
        default:
          return null;
      }
    });
  });
  tearDown(() async {
    log.clear();
  });

  String testInAppMessageJson = '{\"message\":\"body body\",\"type\":\"MODAL\",'
      '\"text_align_message\":\"CENTER\",\"click_action\":\"NONE\",\"message_close'
      '\":\"SWIPE\",\"extras\":{\"test\":\"123\",\"foo\":\"bar\"},\"header\":\"hell'
      'o\",\"text_align_header\":\"CENTER\",\"image_url\":\"https:\\/\\/cdn-staging'
      '.braze.com\\/appboy\\/communication\\/marketing\\/slide_up\\/slide_up_messag'
      'e_parameters\\/images\\/5ba53198bf5cea446b153b77\\/0af410cf267a4686ac6cac571'
      'bd2be4da4c8e63c\\/original.jpg?1572663749\",\"image_style\":\"TOP\",\"btns\"'
      ':[{\"id\":0,\"text\":\"button 1\",\"click_action\":\"URI\",\"uri\":\"https:'
      '\\/\\/www.google.com\",\"use_webview\":true,\"bg_color\":4294967295,\"text_c'
      'olor\":4279990479,\"border_color\":4279990479},{\"id\":1,\"text\":\"button 2'
      '\",\"click_action\":\"NONE\",\"bg_color\":4279990479,\"text_color\":42949672'
      '95,\"border_color\":4279990479}],\"close_btn_color\":4291085508,\"bg_color\"'
      ':4294243575,\"frame_color\":3207803699,\"text_color\":4280624421,\"header_te'
      'xt_color\":4280624421,\"trigger_id\":\"NWJhNTMxOThiZjVjZWE0NDZiMTUzYjZiXyRfb'
      'XY9NWJhNTMxOThiZjVjZWE0NDZiMTUzYjc1JnBpPWNtcA==\"}';

  test('should call changeUser', () {
    BrazePlugin _braze = new BrazePlugin();
    String _testUser = 'thistestuser';
    _braze.changeUser(_testUser);
    expect(log, <Matcher>[
      isMethodCall(
        'changeUser',
        arguments: <String, dynamic>{'userId': _testUser},
      ),
    ]);
  });

  test('should call changeUser with sdkAuthSignature', () {
    BrazePlugin _braze = new BrazePlugin();
    String _testUser = 'thistestuser';
    String _sdkAuthSignature = 'sdkauthsignature';
    _braze.changeUser(_testUser, sdkAuthSignature: _sdkAuthSignature);
    expect(log, <Matcher>[
      isMethodCall(
        'changeUser',
        arguments: <String, dynamic>{
          'userId': _testUser,
          'sdkAuthSignature': _sdkAuthSignature
        },
      ),
    ]);
  });

  test('should call setSdkAuthenticationSignature', () {
    BrazePlugin _braze = new BrazePlugin();
    String _sdkAuthSignature = 'sdkauthsignature';
    _braze.setSdkAuthenticationSignature(_sdkAuthSignature);
    expect(log, <Matcher>[
      isMethodCall(
        'setSdkAuthenticationSignature',
        arguments: <String, dynamic>{'sdkAuthSignature': _sdkAuthSignature},
      ),
    ]);
  });

  test('should call logContentCardClicked', () {
    BrazePlugin _braze = new BrazePlugin();
    String _data = '{"someJson":"data"}';
    BrazeContentCard _contentCard = new BrazeContentCard(_data);
    _braze.logContentCardClicked(_contentCard);
    expect(log, <Matcher>[
      isMethodCall(
        'logContentCardClicked',
        arguments: <String, dynamic>{
          'contentCardString': _contentCard.contentCardJsonString
        },
      ),
    ]);
  });

  test('should include isControl field', () {
    String _data = '{"tp":"control"}';
    BrazeContentCard _contentCard = new BrazeContentCard(_data);
    expect(_contentCard.isControl, equals(true));
  });

  test('should call logContentCardImpression', () {
    BrazePlugin _braze = new BrazePlugin();
    String _data = '{"someJson":"data"}';
    BrazeContentCard _contentCard = new BrazeContentCard(_data);
    _braze.logContentCardImpression(_contentCard);
    expect(log, <Matcher>[
      isMethodCall(
        'logContentCardImpression',
        arguments: <String, dynamic>{
          'contentCardString': _contentCard.contentCardJsonString
        },
      ),
    ]);
  });

  test('should call logContentCardDismissed', () {
    BrazePlugin _braze = new BrazePlugin();
    String _data = '{"someJson":"data"}';
    BrazeContentCard _contentCard = new BrazeContentCard(_data);
    _braze.logContentCardDismissed(_contentCard);
    expect(log, <Matcher>[
      isMethodCall(
        'logContentCardDismissed',
        arguments: <String, dynamic>{
          'contentCardString': _contentCard.contentCardJsonString
        },
      ),
    ]);
  });

  test('should call getCachedContentCards', () async {
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getCachedContentCards();
    expect(log, <Matcher>[
      isMethodCall(
        'getCachedContentCards',
        arguments: null,
      )
    ]);
    expect(result.length, 1);
    expect(result[0].contentCardJsonString, mockContentCardJson);
  });

  test('should call logInAppMessageClicked', () {
    BrazePlugin _braze = new BrazePlugin();
    String _data = '{"someJson":"data"}';
    BrazeInAppMessage _inAppMessage = new BrazeInAppMessage(_data);
    _braze.logInAppMessageClicked(_inAppMessage);
    expect(log, <Matcher>[
      isMethodCall(
        'logInAppMessageClicked',
        arguments: <String, dynamic>{
          'inAppMessageString': _inAppMessage.inAppMessageJsonString
        },
      ),
    ]);
  });

  test('should call logInAppMessageImpression', () {
    BrazePlugin _braze = new BrazePlugin();
    String _data = '{"someJson":"data"}';
    BrazeInAppMessage _inAppMessage = new BrazeInAppMessage(_data);
    _braze.logInAppMessageImpression(_inAppMessage);
    expect(log, <Matcher>[
      isMethodCall(
        'logInAppMessageImpression',
        arguments: <String, dynamic>{
          'inAppMessageString': _inAppMessage.inAppMessageJsonString
        },
      ),
    ]);
  });

  test('should call logInAppMessageButtonClicked', () {
    BrazePlugin _braze = new BrazePlugin();
    String _data = '{"someJson":"data"}';
    int _buttonId = 42;
    BrazeInAppMessage _inAppMessage = new BrazeInAppMessage(_data);
    _braze.logInAppMessageButtonClicked(_inAppMessage, _buttonId);
    expect(log, <Matcher>[
      isMethodCall(
        'logInAppMessageButtonClicked',
        arguments: <String, dynamic>{
          'inAppMessageString': _inAppMessage.inAppMessageJsonString,
          'buttonId': _buttonId
        },
      ),
    ]);
  });

  test('should call getInstallTrackingId', () async {
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getInstallTrackingId();
    expect(log, <Matcher>[
      isMethodCall(
        'getInstallTrackingId',
        arguments: null,
      )
    ]);
    expect(result, mockInstallTrackingId);
  });

  test('should call addAlias', () {
    BrazePlugin _braze = new BrazePlugin();
    String _aliasName = 'someAlias';
    String _aliasLabel = 'someLabel';
    _braze.addAlias(_aliasName, _aliasLabel);
    expect(log, <Matcher>[
      isMethodCall(
        'addAlias',
        arguments: <String, dynamic>{
          'aliasName': _aliasName,
          'aliasLabel': _aliasLabel
        },
      ),
    ]);
  });

  test('should call logCustomEvent with no properties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _eventName = 'someEvent';
    _braze.logCustomEvent(_eventName);
    expect(log, <Matcher>[
      isMethodCall(
        'logCustomEvent',
        arguments: <String, dynamic>{
          'eventName': _eventName,
        },
      ),
    ]);
  });

  test('should call logCustomEvent with optional properties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _eventName = 'someEvent';
    Map<String, dynamic> _properties = {'someKey': 'someValue'};
    _braze.logCustomEvent(_eventName, properties: _properties);
    expect(log, <Matcher>[
      isMethodCall(
        'logCustomEvent',
        arguments: <String, dynamic>{
          'eventName': _eventName,
          'properties': _properties,
        },
      ),
    ]);
  });

  test('should call logCustomEvent with nested properties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _eventName = 'someEvent';
    Map<String, dynamic> _properties = {
      'map_key': {'foo': 'bar'},
      'array_key': ['string', 123, false],
      'nested_map': {
        'inner_array': ['hello', 'world', 123.45, true],
        'inner_map': {'double': 101.1}
      },
      'nested_array': [
        [
          'obj',
          {'key': 'value'},
          ['element', 'element2', 50],
          12
        ]
      ]
    };
    _braze.logCustomEvent(_eventName, properties: _properties);
    expect(log, <Matcher>[
      isMethodCall(
        'logCustomEvent',
        arguments: <String, dynamic>{
          'eventName': _eventName,
          'properties': _properties,
        },
      ),
    ]);
  });

  test('should call logCustomEventWithProperties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _eventName = 'someEvent';
    Map<String, dynamic> _properties = {'someKey': 'someValue'};
    // ignore: deprecated_member_use_from_same_package
    _braze.logCustomEventWithProperties(_eventName, _properties);
    expect(log, <Matcher>[
      isMethodCall(
        'logCustomEvent',
        arguments: <String, dynamic>{
          'eventName': _eventName,
          'properties': _properties
        },
      ),
    ]);
  });

  test('should call logPurchase with no properties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _productId = 'someProduct';
    String _currencyCode = 'someCurrencyCode';
    double _price = 4.2;
    int _quantity = 42;
    _braze.logPurchase(_productId, _currencyCode, _price, _quantity);
    expect(log, <Matcher>[
      isMethodCall(
        'logPurchase',
        arguments: <String, dynamic>{
          'productId': _productId,
          'currencyCode': _currencyCode,
          'price': _price,
          'quantity': _quantity,
        },
      ),
    ]);
  });

  test('should call logPurchase with optional properties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _productId = 'someProduct';
    String _currencyCode = 'someCurrencyCode';
    double _price = 4.2;
    int _quantity = 42;
    Map<String, dynamic> _properties = {'someKey': 'someValue'};
    _braze.logPurchase(_productId, _currencyCode, _price, _quantity,
        properties: _properties);
    expect(log, <Matcher>[
      isMethodCall(
        'logPurchase',
        arguments: <String, dynamic>{
          'productId': _productId,
          'currencyCode': _currencyCode,
          'price': _price,
          'quantity': _quantity,
          'properties': _properties
        },
      ),
    ]);
  });

  test('should call logPurchase with nested properties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _productId = 'someProduct';
    String _currencyCode = 'someCurrencyCode';
    double _price = 4.2;
    int _quantity = 42;
    Map<String, dynamic> _properties = {
      'map_key': {'foo': 'bar'},
      'array_key': ['string', 123, false],
      'nested_map': {
        'inner_array': ['hello', 'world', 123.45, true],
        'inner_map': {'double': 101.1}
      },
      'nested_array': [
        [
          'obj',
          {'key': 'value'},
          ['element', 'element2', 50],
          12
        ]
      ]
    };
    _braze.logPurchase(_productId, _currencyCode, _price, _quantity,
        properties: _properties);
    expect(log, <Matcher>[
      isMethodCall(
        'logPurchase',
        arguments: <String, dynamic>{
          'productId': _productId,
          'currencyCode': _currencyCode,
          'price': _price,
          'quantity': _quantity,
          'properties': _properties,
        },
      ),
    ]);
  });

  test('should call logPurchaseWithProperties', () {
    BrazePlugin _braze = new BrazePlugin();
    String _productId = 'someProduct';
    String _currencyCode = 'someCurrencyCode';
    double _price = 4.2;
    int _quantity = 42;
    Map<String, dynamic> _properties = {'someKey': 'someValue'};
    // ignore: deprecated_member_use_from_same_package
    _braze.logPurchaseWithProperties(
        _productId, _currencyCode, _price, _quantity, _properties);
    expect(log, <Matcher>[
      isMethodCall(
        'logPurchase',
        arguments: <String, dynamic>{
          'productId': _productId,
          'currencyCode': _currencyCode,
          'price': _price,
          'quantity': _quantity,
          'properties': _properties
        },
      ),
    ]);
  });

  test('should call addToCustomAttributeArray', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    String _value = 'someValue';
    _braze.addToCustomAttributeArray(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'addToCustomAttributeArray',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call removeFromCustomAttributeArray', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    String _value = 'someValue';
    _braze.removeFromCustomAttributeArray(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'removeFromCustomAttributeArray',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setStringCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    String _value = 'someValue';
    _braze.setStringCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setStringCustomUserAttribute',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setNestedCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    Map<String, dynamic> _value = {'k': 'v'};
    _braze.setNestedCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setNestedCustomUserAttribute',
        arguments: <String, dynamic>{
          'key': _key,
          'value': _value,
          'merge': false
        },
      ),
    ]);
  });

  test('should call setNestedCustomUserAttribute with `merge: true`', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    Map<String, dynamic> _value = {'k': 'v'};
    _braze.setNestedCustomUserAttribute(_key, _value, true);
    expect(log, <Matcher>[
      isMethodCall(
        'setNestedCustomUserAttribute',
        arguments: <String, dynamic>{
          'key': _key,
          'value': _value,
          'merge': true
        },
      ),
    ]);
  });

  test('should call setCustomUserAttributeArrayOfStrings', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    List<String> _value = ['a', 'b'];
    _braze.setCustomUserAttributeArrayOfStrings(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setCustomUserAttributeArrayOfStrings',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setCustomUserAttributeArrayOfObjects', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    List<Map<String, dynamic>> _value = [
      {'a': 'b'},
      {'c': 'd'}
    ];
    _braze.setCustomUserAttributeArrayOfObjects(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setCustomUserAttributeArrayOfObjects',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setDoubleCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    double _value = 4.2;
    _braze.setDoubleCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setDoubleCustomUserAttribute',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setBoolCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    bool _value = false;
    _braze.setBoolCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setBoolCustomUserAttribute',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setIntCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    int _value = 42;
    _braze.setIntCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setIntCustomUserAttribute',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call incrementCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    int _value = 42;
    _braze.incrementCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'incrementCustomUserAttribute',
        arguments: <String, dynamic>{'key': _key, 'value': _value},
      ),
    ]);
  });

  test('should call setLocationCustomAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    double _lat = 12.34;
    double _long = 56.78;
    _braze.setLocationCustomAttribute(_key, _lat, _long);
    expect(log, <Matcher>[
      isMethodCall(
        'setLocationCustomAttribute',
        arguments: <String, dynamic>{'key': _key, 'lat': _lat, 'long': _long},
      ),
    ]);
  });

  test('should call setDateCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    DateTime _value = new DateTime.now();
    _braze.setDateCustomUserAttribute(_key, _value);
    expect(log, <Matcher>[
      isMethodCall(
        'setDateCustomUserAttribute',
        arguments: <String, dynamic>{
          'key': _key,
          'value': _value.millisecondsSinceEpoch ~/ 1000
        },
      ),
    ]);
  });

  test('should call unsetCustomUserAttribute', () {
    BrazePlugin _braze = new BrazePlugin();
    String _key = 'someKey';
    _braze.unsetCustomUserAttribute(_key);
    expect(log, <Matcher>[
      isMethodCall(
        'unsetCustomUserAttribute',
        arguments: <String, dynamic>{'key': _key},
      ),
    ]);
  });

  test('should call setFirstName', () {
    BrazePlugin _braze = new BrazePlugin();
    String _firstName = 'someFirstName';
    _braze.setFirstName(_firstName);
    expect(log, <Matcher>[
      isMethodCall(
        'setFirstName',
        arguments: <String, dynamic>{'firstName': _firstName},
      ),
    ]);
  });

  test('should call setLastName', () {
    BrazePlugin _braze = new BrazePlugin();
    String _lastName = 'someLastName';
    _braze.setLastName(_lastName);
    expect(log, <Matcher>[
      isMethodCall(
        'setLastName',
        arguments: <String, dynamic>{'lastName': _lastName},
      ),
    ]);
  });

  test('should call setEmail', () {
    BrazePlugin _braze = new BrazePlugin();
    String _email = 'someEmail';
    _braze.setEmail(_email);
    expect(log, <Matcher>[
      isMethodCall(
        'setEmail',
        arguments: <String, dynamic>{'email': _email},
      ),
    ]);
  });

  test('should call setDateOfBirth', () {
    BrazePlugin _braze = new BrazePlugin();
    int _year = 2000;
    int _month = 1;
    int _day = 22;
    _braze.setDateOfBirth(_year, _month, _day);
    expect(log, <Matcher>[
      isMethodCall(
        'setDateOfBirth',
        arguments: <String, dynamic>{
          'year': _year,
          'month': _month,
          'day': _day
        },
      ),
    ]);
  });

  test('should call setGender', () {
    BrazePlugin _braze = new BrazePlugin();
    String _gender = 'f';
    _braze.setGender(_gender);
    expect(log, <Matcher>[
      isMethodCall(
        'setGender',
        arguments: <String, dynamic>{'gender': _gender},
      ),
    ]);
  });

  test('should call setLanguage', () {
    BrazePlugin _braze = new BrazePlugin();
    String _language = 'es';
    _braze.setLanguage(_language);
    expect(log, <Matcher>[
      isMethodCall(
        'setLanguage',
        arguments: <String, dynamic>{'language': _language},
      ),
    ]);
  });

  test('should call setCountry', () {
    BrazePlugin _braze = new BrazePlugin();
    String _country = 'JP';
    _braze.setCountry(_country);
    expect(log, <Matcher>[
      isMethodCall(
        'setCountry',
        arguments: <String, dynamic>{'country': _country},
      ),
    ]);
  });

  test('should call setHomeCity', () {
    BrazePlugin _braze = new BrazePlugin();
    String _homeCity = 'someHomeCity';
    _braze.setHomeCity(_homeCity);
    expect(log, <Matcher>[
      isMethodCall(
        'setHomeCity',
        arguments: <String, dynamic>{'homeCity': _homeCity},
      ),
    ]);
  });

  test('should call setPhoneNumber', () {
    BrazePlugin _braze = new BrazePlugin();
    String _phoneNumber = '8675309';
    _braze.setPhoneNumber(_phoneNumber);
    expect(log, <Matcher>[
      isMethodCall(
        'setPhoneNumber',
        arguments: <String, dynamic>{'phoneNumber': _phoneNumber},
      ),
    ]);
  });

  test('should call setAttributionData', () {
    BrazePlugin _braze = new BrazePlugin();
    String _network = 'someNetwork';
    String _campaign = 'someCampaign';
    String _adGroup = 'someAdGroup';
    String _creative = 'someCreative';
    _braze.setAttributionData(_network, _campaign, _adGroup, _creative);
    expect(log, <Matcher>[
      isMethodCall(
        'setAttributionData',
        arguments: <String, dynamic>{
          'network': _network,
          'campaign': _campaign,
          'adGroup': _adGroup,
          'creative': _creative
        },
      ),
    ]);
  });

  test('should call registerAndroidPushToken', () {
    BrazePlugin _braze = new BrazePlugin();
    String _pushToken = 'someToken';
    // ignore: deprecated_member_use_from_same_package
    _braze.registerAndroidPushToken(_pushToken);
    if (Platform.isAndroid) {
      expect(log, <Matcher>[
        isMethodCall(
          'registerPushToken',
          arguments: <String, dynamic>{'pushToken': _pushToken},
        ),
      ]);
    } else {
      expect(log, []);
    }
  });

  test('should call registerPushToken', () {
    BrazePlugin _braze = new BrazePlugin();
    String _pushToken = 'someToken';
    _braze.registerPushToken(_pushToken);
    expect(log, <Matcher>[
      isMethodCall(
        'registerPushToken',
        arguments: <String, dynamic>{'pushToken': _pushToken},
      ),
    ]);
  });

  test('should call requestImmediateDataFlush', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.requestImmediateDataFlush();
    expect(log, <Matcher>[
      isMethodCall(
        'requestImmediateDataFlush',
        arguments: null,
      ),
    ]);
  });

  test('should call setGoogleAdvertisingId', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.setGoogleAdvertisingId('some_id', false);
    expect(log, <Matcher>[
      isMethodCall(
        'setGoogleAdvertisingId',
        arguments: <String, dynamic>{
          'id': 'some_id',
          'adTrackingEnabled': false
        },
      ),
    ]);
  });

  test('should call wipeData', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.wipeData();
    expect(log, <Matcher>[
      isMethodCall(
        'wipeData',
        arguments: null,
      ),
    ]);
  });

  test('should call requestContentCardsRefresh', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.requestContentCardsRefresh();
    expect(log, <Matcher>[
      isMethodCall(
        'requestContentCardsRefresh',
        arguments: null,
      ),
    ]);
  });

  test('should call launchContentCards', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.launchContentCards();
    expect(log, <Matcher>[
      isMethodCall(
        'launchContentCards',
        arguments: null,
      ),
    ]);
  });

  test('should call requestLocationInitialization', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.requestLocationInitialization();
    expect(log, <Matcher>[
      isMethodCall(
        'requestLocationInitialization',
        arguments: null,
      ),
    ]);
  });

  test('should call setLastKnownLocation with all params', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.setLastKnownLocation(
        latitude: 12,
        longitude: 34.5,
        altitude: 6,
        accuracy: 78,
        verticalAccuracy: 90.12);
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

  test('should call setLastKnownLocation with without optional params', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.setLastKnownLocation(latitude: 12, longitude: 34.5);
    _braze.setLastKnownLocation(latitude: 12, longitude: 34.5, accuracy: 6);
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

  test('should call enableSDK', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.enableSDK();
    expect(log, <Matcher>[
      isMethodCall(
        'enableSDK',
        arguments: null,
      ),
    ]);
  });

  test('should call disableSDK', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.disableSDK();
    expect(log, <Matcher>[
      isMethodCall(
        'disableSDK',
        arguments: null,
      ),
    ]);
  });

  test('should call setPushNotificationSubscriptionType', () {
    BrazePlugin _braze = new BrazePlugin();
    SubscriptionType _type = SubscriptionType.opted_in;
    _braze.setPushNotificationSubscriptionType(_type);
    expect(log, <Matcher>[
      isMethodCall(
        'setPushNotificationSubscriptionType',
        arguments: <String, dynamic>{'type': _type.toString()},
      ),
    ]);
  });

  test('should call setEmailNotificationSubscriptionType', () {
    BrazePlugin _braze = new BrazePlugin();
    SubscriptionType _type = SubscriptionType.opted_in;
    _braze.setEmailNotificationSubscriptionType(_type);
    expect(log, <Matcher>[
      isMethodCall(
        'setEmailNotificationSubscriptionType',
        arguments: <String, dynamic>{'type': _type.toString()},
      ),
    ]);
  });

  test('should call addToSubscriptionGroup', () {
    BrazePlugin _braze = new BrazePlugin();
    String _groupId = 'someGroupId';
    _braze.addToSubscriptionGroup(_groupId);
    expect(log, <Matcher>[
      isMethodCall(
        'addToSubscriptionGroup',
        arguments: <String, dynamic>{'groupId': _groupId},
      ),
    ]);
  });

  test('should call removeFromSubscriptionGroup', () {
    BrazePlugin _braze = new BrazePlugin();
    String _groupId = 'someGroupId';
    _braze.removeFromSubscriptionGroup(_groupId);
    expect(log, <Matcher>[
      isMethodCall(
        'removeFromSubscriptionGroup',
        arguments: <String, dynamic>{'groupId': _groupId},
      ),
    ]);
  });

  test('should call refreshFeatureFlags', () {
    BrazePlugin _braze = new BrazePlugin();
    _braze.refreshFeatureFlags();
    expect(log, <Matcher>[
      isMethodCall(
        'refreshFeatureFlags',
        arguments: null,
      ),
    ]);
  });

  test('should call getAllFeatureFlags', () async {
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getAllFeatureFlags();
    expect(log, <Matcher>[
      isMethodCall(
        'getAllFeatureFlags',
        arguments: null,
      )
    ]);
    expect(result.length, 1);
    expect(result[0].id, "test");
  });

  test('featureFlag convenience functions work', () async {
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getFeatureFlagByID("test");
    expect(result?.id, "test");
    expect(result?.enabled, true);
    expect(result?.properties.length, 4);
    expect(result?.getStringProperty("stringkey"), "stringValue");
    expect(result?.getBooleanProperty("booleankey"), true);
    expect(result?.getNumberProperty("number1key"), 4);
    expect(result?.getNumberProperty("number2key"), 5.1);
  });

  test('featureFlag convenience functions return null for non-existent keys',
      () async {
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getFeatureFlagByID("test");
    expect(result?.getStringProperty("keyThatDoesntExist"), null);
    expect(result?.getBooleanProperty("keyThatDoesntExist"), null);
    expect(result?.getNumberProperty("keyThatDoesntExist"), null);
  });

  test('should call getFeatureFlagByID', () async {
    nullFeatureFlag = false;
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getFeatureFlagByID("test");
    expect(log, <Matcher>[
      isMethodCall(
        'getFeatureFlagByID',
        arguments: <String, dynamic>{'id': "test"},
      ),
    ]);
    expect(result?.id, "test");
    expect(result?.enabled, true);
    expect(result?.properties.length, 4);
    expect(result?.getStringProperty("stringkey"), "stringValue");
    expect(result?.getStringProperty("stringkeyThatDoesntExist"), null);
    expect(result?.getBooleanProperty("booleankey"), true);
    expect(result?.getBooleanProperty("booleanKeyThatDoesntExist"), null);
    expect(result?.getNumberProperty("number1key"), 4);
    expect(result?.getNumberProperty("number2key"), 5.1);
    expect(result?.getNumberProperty("numberKeyThatDoesntExist"), null);
  });

  test('getFeatureFlagByID returns null for non-existent Feature Flag', () async {
    nullFeatureFlag = true;
    BrazePlugin _braze = new BrazePlugin();
    final result = await _braze.getFeatureFlagByID("idThatDoesntExist");
    expect(log, <Matcher>[
      isMethodCall(
        'getFeatureFlagByID',
        arguments: <String, dynamic>{'id': "idThatDoesntExist"},
      ),
    ]);
    expect(result, null);
    expect(result?.id, null);
    expect(result?.enabled, null);
    expect(result?.properties.length, null);
    expect(result?.getStringProperty("stringkey"), null);
    expect(result?.getStringProperty("stringkeyThatDoesntExist"), null);
    expect(result?.getBooleanProperty("booleankey"), null);
    expect(result?.getBooleanProperty("booleanKeyThatDoesntExist"), null);
    expect(result?.getNumberProperty("number1key"), null);
    expect(result?.getNumberProperty("number2key"), null);
    expect(result?.getNumberProperty("numberKeyThatDoesntExist"), null);
  });

  test('instantiate a BrazeInAppMessage object from JSON', () {
    String testMessageBody = "some message body";
    String testMessageType = 'MODAL';
    String testUri = "https:\\/\\/www.sometesturi.com";
    String testImageUrl = "https:\\/\\/www.sometestimageuri.com";
    String testZippedAssetsUrl = "https:\\/\\/www.sometestzippedassets.com";
    bool testUseWebView = true;
    int testDuration = 42;
    String testExtras = '{\"test\":\"123\",\"foo\":\"bar\"}';
    String testClickAction = 'URI';
    String testDismissType = 'SWIPE';
    String testHeader = "some header";
    String testButton0 = '{\"id\":0,\"text\":\"button 1\",\"click_action\":\"UR'
        'I\",\"uri\":\"https:\\/\\/www.google.com\",\"use_webview\":true,\"bg_col'
        'or\":4294967295,\"text_color\":4279990479,\"border_color\":4279990479}';
    String testButton1 = '{\"id\":1,\"text\":\"button 2\",\"click_action\":\"NO'
        'NE\",\"bg_color\":4279990479,\"text_color\":4294967295,\"border_color\":'
        '4279990479}';
    String testButtonString = '[$testButton0, $testButton1]';
    List<BrazeButton> testButtons = [];
    testButtons.add(BrazeButton(json.jsonDecode(testButton0)));
    testButtons.add(BrazeButton(json.jsonDecode(testButton1)));
    String testJson = '{\"message\":\"$testMessageBody\",\"type\":\"'
        '$testMessageType\",\"text_align_message\":\"CENTER\",\"click_action\":\"'
        '$testClickAction\",\"message_close\":\"SWIPE\",\"extras\":$testExtras,\"h'
        'eader\":\"$testHeader\",\"text_align_header\":\"CENTER\",\"image_url\":\"'
        '$testImageUrl\",\"image_style\":\"TOP\",\"btns\":$testButtonString,\"clos'
        'e_btn_color\":4291085508,\"bg_color\":4294243575,\"frame_color\":32078036'
        '99,\"text_color\":4280624421,\"header_text_color\":4280624421,\"trigger_i'
        'd\":\"NWJhNTMxOThiZjVjZWE0NDZiMTUzYjZiXyRfbXY9NWJhNTMxOThiZjVjZWE0NDZiMTU'
        'zYjc1JnBpPWNtcA==\",\"uri\":\"$testUri\",\"zipped_assets_url\":\"'
        '$testZippedAssetsUrl\",\"duration\":$testDuration,\"message_close\":\"'
        '$testDismissType\",\"use_webview\":$testUseWebView}';
    BrazeInAppMessage inAppMessage = new BrazeInAppMessage(testJson);
    expect(inAppMessage.message, equals(testMessageBody));
    expect(describeEnum(inAppMessage.messageType),
        equals(testMessageType.toLowerCase()));
    expect(inAppMessage.uri, equals(json.jsonDecode('"$testUri"')));
    expect(inAppMessage.useWebView, equals(testUseWebView));
    expect(inAppMessage.zippedAssetsUrl,
        equals(json.jsonDecode('"$testZippedAssetsUrl"')));
    expect(inAppMessage.duration, equals(testDuration));
    expect(inAppMessage.extras, equals(json.jsonDecode(testExtras)));
    expect(describeEnum(inAppMessage.clickAction),
        equals(testClickAction.toLowerCase()));
    expect(describeEnum(inAppMessage.dismissType),
        equals(testDismissType.toLowerCase()));
    expect(inAppMessage.imageUrl, equals(json.jsonDecode('"$testImageUrl"')));
    expect(inAppMessage.header, equals(testHeader));
    expect(inAppMessage.inAppMessageJsonString, equals(testJson));
    expect(
        inAppMessage.buttons[0].toString(), equals(testButtons[0].toString()));
    expect(
        inAppMessage.buttons[1].toString(), equals(testButtons[1].toString()));
  });

  test('instantiate a BrazeInAppMessage object with expected defaults', () {
    String defaultMessageBody = '';
    String defaultMessageType = 'SLIDEUP';
    String defaultUri = '';
    String defaultImageUrl = '';
    String defaultZippedAssetsUrl = '';
    bool defaultUseWebView = false;
    int defaultDuration = 5;
    Map defaultExtras = Map();
    String defaultClickAction = 'NONE';
    String defaultDismissType = 'AUTO_DISMISS';
    String defaultHeader = '';
    List<BrazeButton> defaultButtons = [];
    String testJson = '{}';
    BrazeInAppMessage inAppMessage = new BrazeInAppMessage(testJson);
    expect(inAppMessage.message, equals(defaultMessageBody));
    expect(describeEnum(inAppMessage.messageType),
        equals(defaultMessageType.toLowerCase()));
    expect(inAppMessage.uri, equals(defaultUri));
    expect(inAppMessage.useWebView, equals(defaultUseWebView));
    expect(inAppMessage.zippedAssetsUrl, equals(defaultZippedAssetsUrl));
    expect(inAppMessage.duration, equals(defaultDuration));
    expect(inAppMessage.extras, equals(defaultExtras));
    expect(describeEnum(inAppMessage.clickAction),
        equals(defaultClickAction.toLowerCase()));
    expect(describeEnum(inAppMessage.dismissType),
        equals(defaultDismissType.toLowerCase()));
    expect(inAppMessage.imageUrl, equals(defaultImageUrl));
    expect(inAppMessage.header, equals(defaultHeader));
    expect(json.jsonEncode(inAppMessage.inAppMessageJsonString),
        json.jsonEncode(testJson));
    expect(inAppMessage.buttons, equals(defaultButtons));
  });

  test('return the original JSON when calling BrazeInAppMessage.toString()',
      () {
    BrazeInAppMessage inAppMessage =
        new BrazeInAppMessage(testInAppMessageJson);
    expect(inAppMessage.toString(), equals(testInAppMessageJson));
  });

  test('should call AppboyReactBridge.logInAppMessageClicked', () {
    BrazePlugin _braze = new BrazePlugin();
    BrazeInAppMessage inAppMessage =
        new BrazeInAppMessage(testInAppMessageJson);
    _braze.logInAppMessageClicked(inAppMessage);
    expect(log, <Matcher>[
      isMethodCall(
        'logInAppMessageClicked',
        arguments: <String, dynamic>{
          'inAppMessageString': testInAppMessageJson
        },
      ),
    ]);
  });

  test('should call AppboyReactBridge.logInAppMessageImpression', () {
    BrazePlugin _braze = new BrazePlugin();
    BrazeInAppMessage inAppMessage =
        new BrazeInAppMessage(testInAppMessageJson);
    _braze.logInAppMessageImpression(inAppMessage);
    expect(log, <Matcher>[
      isMethodCall(
        'logInAppMessageImpression',
        arguments: <String, dynamic>{
          'inAppMessageString': testInAppMessageJson
        },
      ),
    ]);
  });

  test('should call AppboyReactBridge.logInAppMessageButtonClicked', () {
    BrazePlugin _braze = new BrazePlugin();
    BrazeInAppMessage inAppMessage =
        new BrazeInAppMessage(testInAppMessageJson);
    int testId = 23;
    _braze.logInAppMessageButtonClicked(inAppMessage, testId);
    expect(log, <Matcher>[
      isMethodCall(
        'logInAppMessageButtonClicked',
        arguments: <String, dynamic>{
          'inAppMessageString': testInAppMessageJson,
          'buttonId': testId
        },
      ),
    ]);
  });

  test('instantiate a BrazeButton object from JSON', () {
    int testId = 53;
    String testClickAction = 'URI';
    String testText = 'some text';
    String testUri = "https:\\/\\/www.sometesturi.com";
    bool testUseWebView = true;
    String testButtonJson = '{\"id\":$testId,\"text\":\"$testText\",\"click_ac'
        'tion\":\"$testClickAction\",\"uri\":\"$testUri\",\"use_webview\":'
        '$testUseWebView,\"bg_color\":4294967295,\"text_color\":4279990479,\"bor'
        'der_color\":4279990479}';
    BrazeButton button = new BrazeButton(json.jsonDecode(testButtonJson));
    expect(button.id, equals(testId));
    expect(describeEnum(button.clickAction),
        equals(testClickAction.toLowerCase()));
    expect(button.text, equals(testText));
    expect(button.uri, equals(json.jsonDecode('"$testUri"')));
    expect(button.useWebView, equals(testUseWebView));
    expect(
        button.toString(),
        equals("BrazeButton text:" +
            button.text +
            " uri:" +
            button.uri +
            " clickAction:" +
            button.clickAction.toString() +
            " useWebView:" +
            button.useWebView.toString()));
  });

  test('instantiate a BrazeButton object with expected defaults', () {
    int defaultId = 0;
    String defaultClickAction = 'NONE';
    String defaultText = '';
    String defaultUri = '';
    bool defaultUseWebView = false;
    BrazeButton button = new BrazeButton({});
    expect(button.id, equals(defaultId));
    expect(describeEnum(button.clickAction),
        equals(defaultClickAction.toLowerCase()));
    expect(button.text, equals(defaultText));
    expect(button.uri, equals(defaultUri));
    expect(button.useWebView, equals(defaultUseWebView));
  });

  test('instantiate a BrazeContentCard object from JSON', () {
    bool testClicked = false;
    int testCreated = 1;
    String testDescription = "some description";
    bool testDismissable = true;
    int testExpiresAt = 1592545002;
    String testExtras = '{\"test\":\"123\",\"foo\":\"bar\"}';
    String testId = "some id";
    String testImageUrl = "https:\\/\\/www.sometestimageuri.com";
    double testImageAspectRatio = 1.2;
    String testLinkText = "some link text";
    bool testPinned = true;
    bool testRemoved = false;
    String testTitle = "some title";
    String testType = "some type";
    String testUri = "https:\\/\\/www.sometesturi.com";
    bool testUseWebView = true;
    bool testViewed = false;
    String testContentCardJson = '{\"id\":\"$testId\",\"cl\":$testClicked,\"ca'
        '\":$testCreated,\"ds\":\"$testDescription\",\"db\":$testDismissable,\"ea\"'
        ':$testExpiresAt,\"e\":$testExtras,\"i\":\"$testImageUrl\",\"ar\":'
        '$testImageAspectRatio,\"dm\":\"$testLinkText\",\"p\":$testPinned,\"r\":'
        '$testRemoved,\"tt\":\"$testTitle\",\"tp\":\"$testType\",\"u\":\"$testUri\"'
        ',\"uw\":$testUseWebView,\"v\":$testViewed}';
    BrazeContentCard contentCard = new BrazeContentCard(testContentCardJson);
    expect(contentCard.id, equals(testId));
    expect(contentCard.clicked, equals(testClicked));
    expect(contentCard.created, equals(testCreated));
    expect(contentCard.description, equals(testDescription));
    expect(contentCard.dismissable, equals(testDismissable));
    expect(contentCard.expiresAt, equals(testExpiresAt));
    expect(contentCard.extras, equals(json.jsonDecode(testExtras)));
    expect(contentCard.image, equals(json.jsonDecode('"$testImageUrl"')));
    expect(contentCard.imageAspectRatio, equals(testImageAspectRatio));
    expect(contentCard.linkText, equals(testLinkText));
    expect(contentCard.pinned, equals(testPinned));
    expect(contentCard.removed, equals(testRemoved));
    expect(contentCard.title, equals(testTitle));
    expect(contentCard.type, equals(testType));
    expect(contentCard.url, equals(json.jsonDecode('"$testUri"')));
    expect(contentCard.useWebView, equals(testUseWebView));
    expect(contentCard.viewed, equals(testViewed));
    expect(contentCard.contentCardJsonString, equals(testContentCardJson));
  });
}
