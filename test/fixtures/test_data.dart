import 'dart:convert';

class TestData {
  static const String mockDeviceId = '_test_device_id_';
  static const String mockUserId = '_test_user_id_';

  static const Map<String, dynamic> jsonObject = {
    'jsonobject': {
      'string': 'Braze1234',
      'number': 123.45,
      'boolean': true,
      'datetime': 456000,
      'image': 'https://picsum.photos/200/300',
      'array': ['Hello', 'World'],
      'null_value': null,
      'nested_json': {
        'string': 'Braze1234',
        'number': 123.45,
        'boolean': true,
        'datetime': 456000,
        'image': 'https://picsum.photos/200/300',
        'array': ['Hello', 'World'],
      }
    }
  };

  static String get jsonObjectString => jsonEncode(jsonObject);

  static String get featureFlagJson => jsonEncode({
    'id': 'test',
    'enabled': true,
    'properties': {
      'stringkey': {'type': 'string', 'value': 'stringValue'},
      'booleankey': {'type': 'boolean', 'value': true},
      'number1key': {'type': 'number', 'value': 4},
      'number2key': {'type': 'number', 'value': 5.1},
      'timestamp1Key': {'type': 'datetime', 'value': 12345},
      'timestamp2Key': {'type': 'datetime', 'value': 9223372036854775807},
      'jsonKey': {'type': 'jsonobject', 'value': jsonObject},
      'image1Key': {'type': 'image', 'value': 'image_name_here'},
      'image2Key': {'type': 'image', 'value': 'https://picsum.photos/200/300'},
    }
  });

  static String get contentCardJson => jsonEncode({
    'ca': 1234567890,
    'cl': false,
    'db': true,
    'dm': '',
    'ds': 'Description of Card',
    'e': {'timestamp': '1234567890'},
    'ea': 1234567890,
    'id': 'someID=',
    'p': false,
    'r': false,
    't': false,
    'tp': 'short_news',
    'tt': 'Title of Card',
    'uw': true,
    'v': false,
  });

  static String get bannerJson => jsonEncode({
    'id': 'test',
    'placement_id': 'test_placement_id',
    'is_test_send': false,
    'is_control': false,
    'html': '<p>Test</p>',
    'expires_at': -1,
    'properties': {
      'stringkey': {'type': 'string', 'value': 'stringValue'},
      'booleankey': {'type': 'boolean', 'value': true},
      'number1key': {'type': 'number', 'value': 4},
      'number2key': {'type': 'number', 'value': 5.1},
      'timestamp1Key': {'type': 'datetime', 'value': 12345},
      'timestamp2Key': {'type': 'datetime', 'value': 9223372036854775807},
      'jsonKey': {'type': 'jsonobject', 'value': jsonObject},
      'image1Key': {'type': 'image', 'value': 'image_name_here'},
      'image2Key': {'type': 'image', 'value': 'https://picsum.photos/200/300'},
    }
  });

  static String get inAppMessageJson => jsonEncode({
    'message': 'body body',
    'type': 'MODAL',
    'text_align_message': 'CENTER',
    'click_action': 'NONE',
    'message_close': 'SWIPE',
    'extras': {'test': '123', 'foo': 'bar'},
    'header': 'hello',
    'text_align_header': 'CENTER',
    'image_url': 'https://cdn-staging.braze.com/appboy/communication/marketing/slide_up/slide_up_message_parameters/images/5ba53198bf5cea446b153b77/0af410cf267a4686ac6cac571bd2be4da4c8e63c/original.jpg?1572663749',
    'image_style': 'TOP',
    'btns': [
      {
        'id': 0,
        'text': 'button 1',
        'click_action': 'URI',
        'uri': 'https://www.google.com',
        'use_webview': true,
        'bg_color': 4294967295,
        'text_color': 4279990479,
        'border_color': 4279990479,
      },
      {
        'id': 1,
        'text': 'button 2',
        'click_action': 'NONE',
        'bg_color': 4279990479,
        'text_color': 4294967295,
        'border_color': 4279990479,
      },
    ],
    'close_btn_color': 4291085508,
    'bg_color': 4294243575,
    'frame_color': 3207803699,
    'text_color': 4280624421,
    'header_text_color': 4280624421,
    'trigger_id': 'NWJhNTMxOThiZjVjZWE0NDZiMTUzYjZiXyRfbXY9NWJhNTMxOThiZjVjZWE0NDZiMTUzYjc1JnBpPWNtcA==',
    'is_test_send': false,
  });

  static Map<String, dynamic> makeFeatureFlag({
    String id = 'test',
    bool enabled = true,
    Map<String, dynamic>? properties,
  }) => {
    'id': id,
    'enabled': enabled,
    'properties': properties ?? {},
  };

  static Map<String, dynamic> makeBanner({
    String id = 'test',
    String placementId = 'test_placement',
    String stableKey = 'test_stable_key',
    bool isTestSend = false,
    bool isControl = false,
    String html = '<p>Test</p>',
    int expiresAt = -1,
    Map<String, dynamic>? properties,
  }) => {
    'id': id,
    'placement_id': placementId,
    'stable_key': stableKey,
    'is_test_send': isTestSend,
    'is_control': isControl,
    'html': html,
    'expires_at': expiresAt,
    'properties': properties ?? {},
  };

  static Map<String, dynamic> makeContentCard({
    String id = 'test_id',
    bool clicked = false,
    int created = 1234567890,
    String description = 'test description',
    bool dismissable = true,
    int expiresAt = 1592545002,
    Map<String, dynamic>? extras,
    String image = 'https://example.com/image.jpg',
    double imageAspectRatio = 1.2,
    String linkText = 'link text',
    bool pinned = false,
    bool removed = false,
    String title = 'title',
    String type = 'short_news',
    String url = 'https://example.com',
    bool useWebView = true,
    bool viewed = false,
  }) => {
    'id': id,
    'cl': clicked,
    'ca': created,
    'ds': description,
    'db': dismissable,
    'ea': expiresAt,
    'e': extras ?? {},
    'i': image,
    'ar': imageAspectRatio,
    'dm': linkText,
    'p': pinned,
    'r': removed,
    'tt': title,
    'tp': type,
    'u': url,
    'uw': useWebView,
    'v': viewed,
  };

  static Map<String, dynamic> makePushEvent({
    String payloadType = 'push_opened',
    String title = 'Test Title',
    String body = 'Test Body',
    String? url,
    String? imageUrl,
    String summaryText = 'Test Summary',
    int badgeCount = 0,
    bool useWebview = false,
    bool isSilent = false,
    bool isBrazeInternal = false,
    int timestamp = 0,
    Map<String, dynamic>? brazeProperties,
    Map<String, dynamic>? ios,
    Map<String, dynamic>? android,
  }) => {
    'payload_type': payloadType,
    'title': title,
    'body': body,
    if (url != null) 'url': url,
    if (imageUrl != null) 'image_url': imageUrl,
    'summary_text': summaryText,
    'badge_count': badgeCount,
    'use_webview': useWebview,
    'is_silent': isSilent,
    'is_braze_internal': isBrazeInternal,
    'timestamp': timestamp,
    if (brazeProperties != null) 'braze_properties': brazeProperties,
    if (ios != null) 'ios': ios,
    if (android != null) 'android': android,
  };

  static Map<String, dynamic> makeInAppMessage({
    String message = '',
    String type = 'SLIDEUP',
    String textAlignMessage = 'CENTER',
    String clickAction = 'NONE',
    String messageClose = 'AUTO_DISMISS',
    Map<String, dynamic>? extras,
    String header = '',
    String textAlignHeader = 'CENTER',
    String imageUrl = '',
    String imageStyle = 'TOP',
    List<Map<String, dynamic>>? buttons,
    int closeButtonColor = 4291085508,
    int bgColor = 4294243575,
    int frameColor = 3207803699,
    int textColor = 4280624421,
    int headerTextColor = 4280624421,
    String triggerId = 'test_trigger_id',
    String? uri,
    String? zippedAssetsUrl,
    int duration = 5,
    bool useWebview = false,
    bool isTestSend = false,
  }) => {
    'message': message,
    'type': type,
    'text_align_message': textAlignMessage,
    'click_action': clickAction,
    'message_close': messageClose,
    if (extras != null) 'extras': extras,
    'header': header,
    'text_align_header': textAlignHeader,
    'image_url': imageUrl,
    'image_style': imageStyle,
    if (buttons != null) 'btns': buttons,
    'close_btn_color': closeButtonColor,
    'bg_color': bgColor,
    'frame_color': frameColor,
    'text_color': textColor,
    'header_text_color': headerTextColor,
    'trigger_id': triggerId,
    if (uri != null) 'uri': uri,
    if (zippedAssetsUrl != null) 'zipped_assets_url': zippedAssetsUrl,
    'duration': duration,
    'use_webview': useWebview,
    'is_test_send': isTestSend,
  };

  static Map<String, dynamic> makeButton({
    int id = 0,
    String text = '',
    String clickAction = 'NONE',
    String? uri,
    bool useWebview = false,
    int bgColor = 4294967295,
    int textColor = 4279990479,
    int borderColor = 4279990479,
  }) => {
    'id': id,
    'text': text,
    'click_action': clickAction,
    if (uri != null) 'uri': uri,
    'use_webview': useWebview,
    'bg_color': bgColor,
    'text_color': textColor,
    'border_color': borderColor,
  };

  static Map<String, dynamic> makePropertyValue({
    required String type,
    required dynamic value,
  }) => {
    'type': type,
    'value': value,
  };
}
