import 'dart:async';
import 'dart:io' show Platform;

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/constants/config.dart';
import 'package:braze_plugin_example/screens/home_screen.dart';
import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/jwt_generator.dart';
import 'package:braze_plugin_example/log_console.dart';
import 'package:braze_plugin_example/sdk_helpers.dart';
import 'package:braze_plugin_example/theme.dart';
import 'package:flutter/material.dart';

/// User identity, events, attributes, location, tracking, and SDK controls.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _userId = '';
  String _sdkStatus = '';
  String _pushStreamStatus = 'Disabled';
  String _iamStreamStatus = 'Disabled';
  late BrazeLogLevel _currentLogLevel;
  StreamSubscription? _pushEventsSubscription;
  StreamSubscription? _inAppMessageSubscription;

  static const bool _automaticallyInteractIam = false;

  final _userIdController = TextEditingController();
  final _pushTokenController = TextEditingController();
  final _customEventNameController = TextEditingController();
  final _customEventPropKeyController = TextEditingController();
  final _customEventPropValueController = TextEditingController();
  final _initApiKeyController = TextEditingController();
  final _initEndpointController = TextEditingController();

  void _setLogLevel(BrazeLogLevel level) {
    BrazePlugin.logLevel = level;
    braze = BrazePlugin(customConfigs: {replayCallbacksConfigKey: true});
    braze.initialize(_initApiKeyController.text, _initEndpointController.text);
    setState(() => _currentLogLevel = level);
  }

  @override
  void initState() {
    super.initState();
    _currentLogLevel = BrazePlugin.logLevel;
    if (Platform.isAndroid) {
      _initApiKeyController.text = defaultAndroidApiKey;
    } else if (Platform.isIOS) {
      _initApiKeyController.text = defaultIOSApiKey;
    }
    _initEndpointController.text = defaultEndpoint;

    braze.getUserId().then((userId) {
      if (userId != null && mounted) {
        setState(() {
          _userId = userId;
          currentUserId = userId;
          _userIdController.text = _userId;
        });
      }
    });

    braze.getDeviceId().then((result) {
      brazeSdkEnabled = result.isNotEmpty;
      if (mounted) {
        setState(() {
          _sdkStatus = result.isEmpty ? 'Disabled' : 'Enabled';
        });
      }
    });
  }

  @override
  void dispose() {
    _pushEventsSubscription?.cancel();
    _inAppMessageSubscription?.cancel();
    _userIdController.dispose();
    _pushTokenController.dispose();
    _customEventNameController.dispose();
    _customEventPropKeyController.dispose();
    _customEventPropValueController.dispose();
    _initApiKeyController.dispose();
    _initEndpointController.dispose();
    super.dispose();
  }

  void _pushNotificationEventReceived(BrazePushEvent pushEvent) {
    if (!mounted || !brazeSdkEnabled) return;
    print('Received push notification event: ${pushEvent.toString()}');
    context.showBrazeAppSnackbar('Push event: $pushEvent');
  }

  void _inAppMessageReceived(BrazeInAppMessage inAppMessage) {
    if (!mounted || !brazeSdkEnabled) return;
    print(
      'Received message of type ${inAppMessage.messageType.name}: ${inAppMessage.toString()}',
    );
    context.showBrazeAppSnackbar(
      'Received message: ${inAppMessage.toString()}',
    );
    if (_automaticallyInteractIam) {
      braze.logInAppMessageImpression(inAppMessage);
      braze.logInAppMessageClicked(inAppMessage);
      for (final button in inAppMessage.buttons) {
        braze.logInAppMessageButtonClicked(inAppMessage, button.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: const [
          LogConsoleToggleButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: BrazeAppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Events, user attributes, in-app messages, SDK controls, and more',
              style: TextStyle(
                fontSize: 16,
                color: BrazeAppColors.textGray,
              ),
            ),
            const SizedBox(height: 12),
            if (_sdkStatus.isNotEmpty)
              StatusRow(label: 'SDK Status', value: _sdkStatus),
            StatusRow(label: 'IAM Stream', value: _iamStreamStatus),
            StatusRow(label: 'Push Stream', value: _pushStreamStatus),
            if (_userId.isNotEmpty) StatusRow(label: 'User ID', value: _userId),
            const SizedBox(height: 16),
            BrazeAppCard(
              title: 'User Management',
              children: [
                BrazeAppButton(
                  title: 'Get Device ID',
                  onPressed: () {
                    braze.getDeviceId().then((result) {
                      if (!mounted) return;
                      brazeSdkEnabled = result.isNotEmpty;
                      context.showBrazeAppSnackbar('Device ID: $result');
                    });
                  },
                ),
                BrazeAppInput(
                  label: 'User ID',
                  hint: 'Enter user ID',
                  controller: _userIdController,
                ),
                BrazeAppButton(
                  title: 'Set User ID',
                  onPressed: () async {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final userId = _userIdController.text;
                    braze.changeUser(
                      userId,
                      sdkAuthSignature: await JwtGenerator.create(userId),
                    );
                    setState(() {
                      _userId = userId;
                      currentUserId = userId;
                    });
                    if (!mounted) return;
                    context.showBrazeAppSnackbar('User changed to: $userId');
                  },
                ),
                BrazeAppButton(
                  title: 'Get User ID',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () async {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final userId = await braze.getUserId();
                    if (!mounted) return;
                    if (userId == null) {
                      context.showBrazeAppSnackbar('User ID not found.');
                    } else {
                      setState(() {
                        _userId = userId;
                        currentUserId = userId;
                      });
                      context.showBrazeAppSnackbar('User ID: $userId');
                    }
                  },
                ),
              ],
            ),
            BrazeAppCard(
              title: 'Events',
              children: [
                BrazeAppInput(
                  label: 'Event Name',
                  hint: 'Enter custom event name',
                  controller: _customEventNameController,
                ),
                Row(
                  children: [
                    Expanded(
                      child: BrazeAppInput(
                        label: 'Property Key',
                        hint: 'Key',
                        controller: _customEventPropKeyController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BrazeAppInput(
                        label: 'Property Value',
                        hint: 'Value',
                        controller: _customEventPropValueController,
                      ),
                    ),
                  ],
                ),
                BrazeAppButton(
                  title: 'Log Custom Event',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    String eventName = _customEventNameController.text;
                    if (eventName.isEmpty) {
                      eventName = 'MyCustomEvent';
                    }
                    final key = _customEventPropKeyController.text;
                    final value = _customEventPropValueController.text;
                    if (key.isEmpty) {
                      braze.logCustomEvent(eventName);
                      context.showBrazeAppSnackbar('Custom event: $eventName');
                    } else {
                      braze.logCustomEvent(
                        eventName,
                        properties: {key: value},
                      );
                      context.showBrazeAppSnackbar(
                        'Event: $eventName with {$key: $value}',
                      );
                    }
                  },
                ),
                BrazeAppButton(
                  title: 'Log Preset Events and Purchases',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    logPresetEventsAndPurchases();
                    context.showBrazeAppSnackbar(
                      'Logged preset events and purchases',
                    );
                  },
                ),
                BrazeAppButton(
                  title: 'Request Immediate Data Flush',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.requestImmediateDataFlush();
                    context.showBrazeAppSnackbar('Requested data flush');
                  },
                ),
              ],
            ),
            BrazeAppCard(
              title: 'In-App Messages',
              children: [
                BrazeAppButton(
                  title: 'Subscribe to In-App Message Stream',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    setState(() => _iamStreamStatus = 'Enabled');
                    _inAppMessageSubscription = braze.subscribeToInAppMessages(
                      _inAppMessageReceived,
                    );
                    context.showBrazeAppSnackbar(
                      'Listening to in-app message stream.',
                    );
                  },
                ),
                BrazeAppButton(
                  title: 'Hide Current In-App Message',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.hideCurrentInAppMessage();
                  },
                ),
              ],
            ),
            BrazeAppCard(
              title: 'Push Notifications',
              children: [
                BrazeAppButton(
                  title: 'Subscribe to Push Events',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    setState(() => _pushStreamStatus = 'Enabled');
                    _pushEventsSubscription =
                        braze.subscribeToPushNotificationEvents(
                      _pushNotificationEventReceived,
                    );
                    context.showBrazeAppSnackbar(
                      'Listening to push notification events stream.',
                    );
                  },
                ),
                BrazeAppInput(
                  label: 'Push Token',
                  hint: 'Enter push token (hex string)',
                  controller: _pushTokenController,
                ),
                BrazeAppButton(
                  title: 'Register Push Token',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final token = _pushTokenController.text;
                    braze.registerPushToken(token);
                    context.showBrazeAppSnackbar(
                      'Registered push token: $token',
                    );
                  },
                ),
              ],
            ),
            BrazeAppCard(
              title: 'User Attributes',
              children: [
                BrazeAppButton(
                  title: 'Set Preset Attributes',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final nestedProps = <String, dynamic>{
                      'map_key': {'foo': 'bar'},
                      'array_key': ['string', 123, false],
                      'nested_map': {
                        'inner_array': [
                          'hello',
                          'world',
                          123.45,
                          true,
                        ],
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
                    final arrayOfNests = [
                      {'key1': 'value1'},
                      {'key2': 'value2'},
                      {'key3': 'value3'},
                    ];
                    braze.setNestedCustomUserAttribute('nested', nestedProps);
                    braze.setCustomUserAttributeArrayOfObjects(
                      'arrayOfNests',
                      arrayOfNests,
                    );
                    braze.setCustomUserAttributeArrayOfStrings(
                      'arrayOfStrings',
                      ['one', 'two', 'three'],
                    );
                    braze.addToCustomAttributeArray('arrayAttribute', 'a');
                    braze.addToCustomAttributeArray('arrayAttribute', 'c');
                    braze.setStringCustomUserAttribute(
                      'stringAttribute',
                      'stringValue',
                    );
                    braze.setStringCustomUserAttribute(
                      'stringAttribute2',
                      'stringValue',
                    );
                    braze.setDoubleCustomUserAttribute('doubleAttribute', 1.5);
                    braze.setIntCustomUserAttribute('intAttribute', 1);
                    braze.setBoolCustomUserAttribute('boolAttribute', false);
                    braze.setDateCustomUserAttribute(
                      'dateAttribute',
                      DateTime.now(),
                    );
                    braze.setLocationCustomAttribute('work', 40.7128, 74.0060);
                    braze.setPushNotificationSubscriptionType(
                      SubscriptionType.opted_in,
                    );
                    braze.setEmailNotificationSubscriptionType(
                      SubscriptionType.opted_in,
                    );
                    braze.addToSubscriptionGroup('sampleGroup');
                    braze.setAttributionData(
                      'network1',
                      'campaign1',
                      'adgroup1',
                      'creative1',
                    );
                    braze.setFirstName('firstName');
                    braze.setLastName('lastName');
                    braze.setDateOfBirth(1990, 4, 13);
                    braze.setEmail('email@email.com');
                    braze.setGender('f');
                    braze.setLanguage('es');
                    braze.setCountry('JP');
                    braze.setHomeCity('homeCity');
                    braze.setPhoneNumber('123456789');
                    braze.addAlias('alias-name-1', 'alias-label-1');
                    context.showBrazeAppSnackbar('Preset attributes set');
                  },
                ),
                BrazeAppButton(
                  title: 'Set Nested Custom Attribute w/ Merge',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.setNestedCustomUserAttribute(
                      'nested',
                      {'this_is_merged': 'yes it is'},
                      true,
                    );
                    context.showBrazeAppSnackbar('NCA merge applied');
                  },
                ),
                BrazeAppButton(
                  title: 'Unset / Increment Preset Attributes',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.removeFromCustomAttributeArray(
                      'arrayAttribute',
                      'a',
                    );
                    braze.unsetCustomUserAttribute('stringAttribute2');
                    braze.incrementCustomUserAttribute('intAttribute', 2);
                    braze.removeFromSubscriptionGroup('sampleGroup');
                    braze.setFirstName(null);
                    braze.setLastName(null);
                    braze.setEmail(null);
                    braze.setGender(null);
                    braze.setLanguage(null);
                    braze.setCountry(null);
                    braze.setHomeCity(null);
                    braze.setPhoneNumber(null);
                    context.showBrazeAppSnackbar(
                      'Unset/incremented attributes',
                    );
                  },
                ),
              ],
            ),
            BrazeAppCard(
              title: 'Location',
              children: [
                if (Platform.isAndroid)
                  BrazeAppButton(
                    title: 'Request Location Initialization',
                    onPressed: () {
                      if (!validateBrazeSdkEnabled(context)) return;
                      braze.requestLocationInitialization();
                      context.showBrazeAppSnackbar(
                        'Location initialization requested',
                      );
                    },
                  ),
                BrazeAppButton(
                  title: 'Set Last Known Location',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.requestLocationInitialization();
                    braze.setLastKnownLocation(
                      latitude: 40.7128,
                      longitude: 74.0060,
                      altitude: 23.0,
                      accuracy: 25.0,
                      verticalAccuracy: 19.0,
                    );
                    context.showBrazeAppSnackbar('Last known location set');
                  },
                ),
                BrazeAppButton(
                  title: 'Set Custom Location Attribute',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.setLocationCustomAttribute('work', 40.7128, 74.0060);
                    context.showBrazeAppSnackbar(
                      'Custom location attribute set',
                    );
                  },
                ),
              ],
            ),
            BrazeAppCard(
              title: 'Tracking & Attribution',
              children: [
                BrazeAppButton(
                  title: 'Update Tracking Property List',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final list = BrazeTrackingPropertyList();
                    list.adding = {
                      TrackingProperty.first_name,
                      TrackingProperty.gender,
                    };
                    list.removing = {TrackingProperty.last_name};
                    list.addingCustomEvents = {'custom-event-1'};
                    list.removingCustomAttributes = {
                      'custom-attr-2',
                      'custom-attr-3',
                    };
                    braze.updateTrackingPropertyAllowList(list);
                    context.showBrazeAppSnackbar(
                      'Updated tracking property allow list',
                    );
                  },
                ),
                BrazeAppButton(
                  title: 'Set Ad Tracking Enabled',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.setAdTrackingEnabled(true, 'dummy-id');
                    context.showBrazeAppSnackbar('Ad tracking enabled');
                  },
                ),
                BrazeAppButton(
                  title: 'Set Attribution Data',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    braze.setAttributionData(
                      'network1',
                      'campaign1',
                      'adgroup1',
                      'creative1',
                    );
                    context.showBrazeAppSnackbar('Attribution data set');
                  },
                ),
                BrazeAppButton(
                  title: 'Get Install Tracking ID (deprecated)',
                  variant: BrazeButtonVariant.secondary,
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    // ignore: deprecated_member_use
                    braze.getInstallTrackingId().then((result) {
                      if (!mounted) return;
                      context.showBrazeAppSnackbar(
                        'Install Tracking ID: $result',
                      );
                    });
                  },
                ),
                if (Platform.isAndroid)
                  BrazeAppButton(
                    title: 'Set Google Advertising ID (deprecated)',
                    variant: BrazeButtonVariant.secondary,
                    onPressed: () {
                      if (!validateBrazeSdkEnabled(context)) return;
                      // ignore: deprecated_member_use
                      braze.setGoogleAdvertisingId('dummy-id', false);
                      context.showBrazeAppSnackbar(
                        'Set Google Advertising ID',
                      );
                    },
                  ),
              ],
            ),
            BrazeAppCard(
              title: 'Logger',
              children: [
                StatusRow(
                  label: 'Log Level',
                  value: _currentLogLevel == BrazeLogLevel.debug
                      ? 'Debug'
                      : _currentLogLevel == BrazeLogLevel.info
                          ? 'Info'
                          : 'Error',
                ),
                Row(
                  children: [
                    Expanded(
                      child: BrazeAppButton(
                        title: 'Debug',
                        variant: _currentLogLevel == BrazeLogLevel.debug
                            ? BrazeButtonVariant.primary
                            : BrazeButtonVariant.secondary,
                        onPressed: () {
                          _setLogLevel(BrazeLogLevel.debug);
                          context.showBrazeAppSnackbar('Log level: Debug');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BrazeAppButton(
                        title: 'Info',
                        variant: _currentLogLevel == BrazeLogLevel.info
                            ? BrazeButtonVariant.primary
                            : BrazeButtonVariant.secondary,
                        onPressed: () {
                          _setLogLevel(BrazeLogLevel.info);
                          context.showBrazeAppSnackbar('Log level: Info');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BrazeAppButton(
                        title: 'Error',
                        variant: _currentLogLevel == BrazeLogLevel.error
                            ? BrazeButtonVariant.primary
                            : BrazeButtonVariant.secondary,
                        onPressed: () {
                          _setLogLevel(BrazeLogLevel.error);
                          context.showBrazeAppSnackbar('Log level: Error');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            BrazeAppCard(
              title: 'SDK Controls',
              children: [
                BrazeAppCard(
                  title: 'Initialize SDK',
                  children: [
                    BrazeAppInput(
                      label: 'API Key',
                      hint: 'Enter API key',
                      controller: _initApiKeyController,
                    ),
                    BrazeAppInput(
                      label: 'Endpoint',
                      hint: 'Enter endpoint',
                      controller: _initEndpointController,
                    ),
                    BrazeAppButton(
                      title: 'Initialize Braze SDK',
                      onPressed: () {
                        final apiKey = _initApiKeyController.text.trim();
                        final endpoint = _initEndpointController.text.trim();
                        if (apiKey.isEmpty || endpoint.isEmpty) {
                          context.showBrazeAppSnackbar(
                            'API key and endpoint are required',
                          );
                          return;
                        }
                        braze.initialize(apiKey, endpoint);
                        braze.getDeviceId().then((id) {
                          brazeSdkEnabled = id.isNotEmpty;
                        });
                        context.showBrazeAppSnackbar('Braze SDK initialized');
                      },
                    ),
                  ],
                ),
                BrazeAppButton(
                  title: 'Enable SDK',
                  onPressed: () {
                    braze.enableSDK();
                    brazeSdkEnabled = true;
                    if (Platform.isAndroid) {
                      setState(() => _sdkStatus = 'Enabled');
                    }
                    context.showBrazeAppSnackbar('SDK enabled');
                  },
                ),
                BrazeAppButton(
                  title: 'Disable SDK',
                  variant: BrazeButtonVariant.danger,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Disable SDK'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: const Text('Yes'),
                            onPressed: () {
                              braze.disableSDK();
                              brazeSdkEnabled = false;
                              setState(() => _sdkStatus = 'Disabled');
                              Navigator.of(ctx).pop();
                              context.showBrazeAppSnackbar('SDK disabled');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                BrazeAppButton(
                  title: 'Wipe Data',
                  variant: BrazeButtonVariant.danger,
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Wipe Data'),
                        content: const Text('Are you sure?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: const Text('Yes'),
                            onPressed: () {
                              braze.wipeData();
                              brazeSdkEnabled = false;
                              if (Platform.isIOS) {
                                setState(() => _sdkStatus = 'Disabled');
                              }
                              Navigator.of(ctx).pop();
                              context.showBrazeAppSnackbar('Data wiped');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
