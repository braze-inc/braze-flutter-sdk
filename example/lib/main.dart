import 'dart:async';
import 'dart:io' show Platform;

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/jwt_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: BrazeFunctions(),
    );
  }
}

class BrazeFunctions extends StatefulWidget {
  @override
  BrazeFunctionsState createState() => new BrazeFunctionsState();
}

void deepLinkAlert(String link, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Deep Link Alert"),
        content: Text("Opened with deep link: $link"),
        actions: <Widget>[
          TextButton(
            child: Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class BrazeFunctionsState extends State<BrazeFunctions> {
  String _userId = "";
  String _enabled = "";
  String _ccStreamSubscription = "DISABLED";
  String _iamStreamSubscription = "DISABLED";
  String _ffStreamSubscription = "DISABLED";
  String _featureFlagPropertyType = "BOOLEAN";
  late BrazePlugin _braze;
  final userIdController = TextEditingController();
  final customEventNameController = TextEditingController();
  final customEventPropertyKeyController = TextEditingController();
  final customEventPropertyValueController = TextEditingController();
  final featureFlagController = TextEditingController();
  final featureFlagPropertyController = TextEditingController();
  late StreamSubscription inAppMessageStreamSubscription;
  late StreamSubscription contentCardsStreamSubscription;
  late StreamSubscription featureFlagsStreamSubscription;

  // Change to `true` to automatically log clicks, button clicks,
  // and impressions for in-app messages and content cards.
  final automaticallyInteract = false;

  void initState() {
    _braze = new BrazePlugin(customConfigs: {replayCallbacksConfigKey: true});

    _braze.setBrazeSdkAuthenticationErrorCallback(
        (BrazeSdkAuthenticationError error) async {
      print('Received an SDK Auth error: $error');

      final String? newSignature = await JwtGenerator.create(_userId);
      print('Setting new signature: $newSignature, userId: $_userId');
      _braze.setSdkAuthenticationSignature(newSignature);
    });

    // Deep link channel
    MethodChannel('deepLinkChannel')
        .setMethodCallHandler((MethodCall call) async {
      deepLinkAlert(call.arguments, context);
    });

    super.initState();
  }

  @override
  void dispose() {
    userIdController.dispose();
    customEventNameController.dispose();
    customEventPropertyKeyController.dispose();
    customEventPropertyValueController.dispose();
    featureFlagController.dispose();
    featureFlagPropertyController.dispose();

    /// Stop listening to streams
    inAppMessageStreamSubscription.cancel();
    contentCardsStreamSubscription.cancel();
    featureFlagsStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Braze Sample'),
      ),
      body: _buildListView(),
    );
  }

  Widget _buildListView() {
    if (_enabled == "") {
      // This is a hack to determine the enabled state of the Braze API
      // Not recommended for use in production
      _braze.getInstallTrackingId().then((result) {
        if (result == "") {
          this.setState(() {
            _enabled = "DISABLED";
          });
        } else {
          this.setState(() {
            _enabled = "ENABLED";
          });
        }
      });
    }

    return Builder(
      builder: (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20.0),
          children: <Widget>[
            Center(child: Text("SDK Status: $_enabled")),
            Center(
                child:
                    Text("IAM Stream Subscription: $_iamStreamSubscription")),
            Center(
                child: Text("CC Stream Subscription: $_ccStreamSubscription")),
            Center(
              child: Text("FF Stream Subscription: $_ffStreamSubscription"),
            ),
            Center(child: Text("User Id: $_userId")),
            TextField(
              autocorrect: false,
              controller: userIdController,
              decoration: InputDecoration(
                  hintText: 'Please enter a user id', labelText: 'User Id'),
            ),
            TextButton(
              child: const Text('CHANGE USER'),
              onPressed: () async {
                String userId = userIdController.text;
                _braze.changeUser(userId,
                    sdkAuthSignature: await JwtGenerator.create(userId));
                this.setState(() {
                  _userId = userId;
                });
              },
            ),
            TextField(
              autocorrect: false,
              controller: customEventNameController,
              decoration: InputDecoration(
                  hintText: 'Please enter a custom event name',
                  labelText: 'Event Name'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: TextField(
                    autocorrect: false,
                    controller: customEventPropertyKeyController,
                    decoration: InputDecoration(
                        hintText: 'Property Key', labelText: 'Property Key'),
                  ),
                ),
                Flexible(
                  child: TextField(
                    autocorrect: false,
                    controller: customEventPropertyValueController,
                    decoration: InputDecoration(
                        hintText: 'Property Value',
                        labelText: 'Property Value'),
                  ),
                ),
              ],
            ),
            TextButton(
              child: const Text('LOG CUSTOM EVENT'),
              onPressed: () {
                String customEvent = customEventNameController.text;
                String customPropertyKey =
                    customEventPropertyKeyController.text;
                String customPropertyValue =
                    customEventPropertyValueController.text;
                if (customEvent.isEmpty) {
                  customEvent = 'MyCustomEvent';
                }
                if (customPropertyKey.isEmpty) {
                  _braze.logCustomEvent(customEvent);
                  ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                    content: new Text("Custom event $customEvent."),
                  ));
                } else {
                  _braze.logCustomEvent(customEvent,
                      properties: {customPropertyKey: customPropertyValue});
                  ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                    content: new Text(
                        'Custom event $customEvent with properties {"$customPropertyKey":"$customPropertyValue"}.'),
                  ));
                }
              },
            ),
            TextButton(
              child: const Text('LOG PRESET EVENTS AND PURCHASES'),
              onPressed: () => _pressedLogPresetEventsAndPurchasesButton(),
            ),
            TextButton(
              child: const Text('SET PRESET ATTRIBUTES'),
              onPressed: () {
                // Nested properties
                Map<String, dynamic> nestedProps = {
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

                List<Map<String, dynamic>> arrayOfNests = [
                  {'key1': 'value1'},
                  {'key2': 'value2'},
                  {'key3': 'value3'}
                ];

                List<String> listOfStrings = ["one", "two", "three"];

                _braze.setNestedCustomUserAttribute("nested", nestedProps);
                _braze.setCustomUserAttributeArrayOfObjects(
                    "arrayOfNests", arrayOfNests);
                _braze.setCustomUserAttributeArrayOfStrings(
                    "arrayOfStrings", listOfStrings);

                _braze.addToCustomAttributeArray("arrayAttribute", "a");
                _braze.addToCustomAttributeArray("arrayAttribute", "c");
                _braze.setStringCustomUserAttribute(
                    "stringAttribute", "stringValue");
                _braze.setStringCustomUserAttribute(
                    "stringAttribute2", "stringValue");
                _braze.setDoubleCustomUserAttribute("doubleAttribute", 1.5);
                _braze.setIntCustomUserAttribute("intAttribute", 1);
                _braze.setBoolCustomUserAttribute("boolAttribute", false);
                _braze.setDateCustomUserAttribute(
                    "dateAttribute", new DateTime.now());
                _braze.setLocationCustomAttribute("work", 40.7128, 74.0060);
                _braze.setPushNotificationSubscriptionType(
                    SubscriptionType.opted_in);
                _braze.setEmailNotificationSubscriptionType(
                    SubscriptionType.opted_in);
                _braze.addToSubscriptionGroup("sampleGroup");
                _braze.setAttributionData(
                    "network1", "campaign1", "adgroup1", "creative1");
                _braze.setFirstName("firstName");
                _braze.setLastName("lastName");
                _braze.setDateOfBirth(1990, 4, 13);
                _braze.setEmail("email@email.com");
                _braze.setGender("f");
                _braze.setLanguage("es");
                _braze.setCountry("JP");
                _braze.setHomeCity("homeCity");
                _braze.setPhoneNumber("123456789");
                _braze.addAlias("alias-name-1", "alias-label-1");

                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Logged attributes"),
                ));
              },
            ),
            TextButton(
              child: const Text('SET NESTED CUSTOM ATTRIBUTE W/ MERGE'),
              onPressed: () {
                // Nested properties
                Map<String, dynamic> nestedProps = {
                  'this_is_merged': 'yes it is'
                };
                _braze.setNestedCustomUserAttribute(
                    "nested", nestedProps, true);
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Did NCA Merge"),
                ));
              },
            ),
            TextButton(
              child: const Text('UNSET/INC PRESET ATTRIBUTES'),
              onPressed: () {
                _braze.removeFromCustomAttributeArray("arrayAttribute", "a");
                _braze.unsetCustomUserAttribute("stringAttribute2");
                _braze.incrementCustomUserAttribute("intAttribute", 2);
                _braze.removeFromSubscriptionGroup("sampleGroup");
                _braze.setEmail(null);
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Unset/increment attributes"),
                ));
              },
            ),
            TextButton(
              child: const Text('REQUEST DATA FLUSH'),
              onPressed: () {
                _braze.requestImmediateDataFlush();
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Requested Data Flush"),
                ));
              },
            ),
            SectionHeader("Feature Flags"),
            TextField(
              autocorrect: false,
              controller: featureFlagController,
              decoration: InputDecoration(
                  hintText: 'Please enter a Feature Flag ID',
                  labelText: 'Feature Flag ID'),
            ),
            TextButton(
              child: const Text('GET SINGLE FEATURE FLAG'),
              onPressed: () {
                String ffId = featureFlagController.text;
                if (ffId == "") {
                  print("No Feature Flag ID entered");
                  return;
                }
                
                _braze.getFeatureFlagByID(ffId).then((ff) {
                  if (ff == null) {
                    print("No Feature Flag Found with ID: " + ffId);
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content: new Text("No Feature Flag Found with ID: " + ffId),
                    ));
                  } else {
                    print("Showing single feature flag");
                    String ffString = _featureFlagToString(ff);
                    print(ffString);
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content: new Text(ffString),
                    ));                    
                  }
                });
              },
            ),
            TextField(
              autocorrect: false,
              controller: featureFlagPropertyController,
              decoration: InputDecoration(
                  hintText: 'Please enter a Feature Flag property key',
                  labelText: 'Feature Flag Property Key'),
            ),
            DropdownButton<String>(
                value: _featureFlagPropertyType,
                alignment: Alignment.center,
                items: [
                  DropdownMenuItem(
                    value: 'BOOLEAN',
                    child: Text('BOOLEAN'),
                  ),
                  DropdownMenuItem(
                    value: 'NUMBER',
                    child: Text('NUMBER'),
                  ),
                  DropdownMenuItem(
                    value: 'STRING',
                    child: Text('STRING'),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _featureFlagPropertyType = value!;
                  });
                }),
            TextButton(
              child: const Text('GET FEATURE FLAG PROPERTY'),
              onPressed: () {
                String ffId = featureFlagController.text;
                _braze.getFeatureFlagByID(ffId).then((ff) {
                  var ffProperty;
                  switch (_featureFlagPropertyType) {
                    case 'BOOLEAN':
                      ffProperty = ff?.getBooleanProperty(
                          featureFlagPropertyController.text);
                      break;
                    case 'NUMBER':
                      ffProperty = ff?.getNumberProperty(
                          featureFlagPropertyController.text);
                      break;
                    case 'STRING':
                      ffProperty = ff?.getStringProperty(
                          featureFlagPropertyController.text);
                      break;
                  }
                  print(ffProperty);
                  ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                    content: new Text('$ffProperty'),
                  ));
                });
              },
            ),
            TextButton(
              child: const Text('LOG FEATURE FLAG IMPRESSION'),
              onPressed: () {
                String ffId = featureFlagController.text;
                print("Logging impression on feature flag $ffId.");
                _braze.logFeatureFlagImpression(ffId);
              },
            ),
            TextButton(
              child: const Text('GET ALL FEATURE FLAGS'),
              onPressed: () {
                print("Showing all feature flags");
                _braze.getAllFeatureFlags().then((ffs) => ffs.forEach((ff) {
                      String ffString = _featureFlagToString(ff);
                      print(ffString);
                      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                        content: new Text(ffString),
                      ));
                    }));
              },
            ),
            TextButton(
              child: const Text('REFRESH FEATURE FLAGS'),
              onPressed: () {
                print("Refreshing feature flags");
                _braze.refreshFeatureFlags();
              },
            ),
            TextButton(
              child: const Text('SUBSCRIBE TO FEATURE FLAG STREAM'),
              onPressed: () {
                this.setState(() {
                  _ffStreamSubscription = 'ENABLED';
                });
                featureFlagsStreamSubscription =
                    _braze.subscribeToFeatureFlags(_featureFlagsReceived);
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Listening to feature flag stream. "
                      "Feature flag data will appear in snackbars."),
                ));
              },
            ),
            SectionHeader("In-app Messages"),
            TextButton(
              child: const Text('SUBSCRIBE VIA IN-APP MESSAGE STREAM'),
              onPressed: () {
                this.setState(() {
                  _iamStreamSubscription = 'ENABLED';
                });
                inAppMessageStreamSubscription = _braze
                    .subscribeToInAppMessages((BrazeInAppMessage inAppMessage) {
                  _inAppMessageReceived(inAppMessage);
                  return;
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Listening to in-app message stream. "
                      "In-app message data will appear in snackbars."),
                ));
              },
            ),
            SectionHeader("Content Cards"),
            TextButton(
              child: const Text('REFRESH CONTENT CARDS'),
              onPressed: () {
                _braze.requestContentCardsRefresh();
              },
            ),
            TextButton(
              child: const Text('LAUNCH CONTENT CARDS'),
              onPressed: () {
                _braze.launchContentCards();
              },
            ),
            TextButton(
              child: const Text('SUBSCRIBE VIA CONTENT CARDS STREAM'),
              onPressed: () {
                this.setState(() {
                  _ccStreamSubscription = 'ENABLED';
                });
                contentCardsStreamSubscription = _braze.subscribeToContentCards(
                    (List<BrazeContentCard> contentCards) {
                  _contentCardsReceived(contentCards);
                  return;
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Listening to content cards stream. "
                      "Content Card data will appear in snackbars."),
                ));
              },
            ),
            TextButton(
              child: const Text('GET CACHED CONTENT CARDS'),
              onPressed: () {
                _braze.getCachedContentCards().then((contentCards) {
                  print("${contentCards.length} cached Content Cards found.");
                  contentCards.forEach((contentCard) {
                    String contentCardString = contentCard.toString();
                    print(contentCardString);
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content: new Text(contentCardString),
                    ));
                  });
                });
              },
            ),
            SectionHeader("Other"),
            TextButton(
              child: const Text('SET LAST KNOWN LOCATION'),
              onPressed: () {
                print(
                    'Requesting location initialization (no-op on iOS) and setting last known location');
                _braze.requestLocationInitialization();
                _braze.setLastKnownLocation(
                    latitude: 40.7128,
                    longitude: 74.0060,
                    altitude: 23.0,
                    accuracy: 25.0,
                    verticalAccuracy: 19.0);
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text('Set Last Known Location'),
                ));
              },
            ),
            TextButton(
              child: const Text('GET INSTALL TRACKING ID'),
              onPressed: () {
                _braze.getInstallTrackingId().then((result) {
                  ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                    content: new Text("Install Tracking ID: " + result),
                  ));
                });
              },
            ),
            TextButton(
              child: const Text('SET GOOGLE ADVERTISING ID'),
              onPressed: () {
                _braze.setGoogleAdvertisingId("dummy-id", false);
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                    content: new Text("Set Google Advertising ID.")));
              },
            ),
            TextButton(
              child: const Text('WIPE DATA'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: new Text("Wipe Data"),
                      content: new Text("Are you sure?"),
                      actions: <Widget>[
                        new TextButton(
                          child: new Text("Yes"),
                          onPressed: () {
                            _braze.wipeData();
                            if (Platform.isIOS) {
                              this.setState(() {
                                _enabled = "DISABLED";
                              });
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                        new TextButton(
                          child: new Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            TextButton(
              child: const Text('ENABLE SDK'),
              onPressed: () {
                _braze.enableSDK();
                if (Platform.isAndroid) {
                  this.setState(() {
                    _enabled = "ENABLED";
                  });
                }
              },
            ),
            TextButton(
              child: const Text('DISABLE SDK'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: new Text("Disable SDK"),
                      content: new Text("Are you sure?"),
                      actions: <Widget>[
                        new TextButton(
                          child: new Text("Yes"),
                          onPressed: () {
                            _braze.disableSDK();
                            this.setState(() {
                              _enabled = "DISABLED";
                            });
                            Navigator.of(context).pop();
                          },
                        ),
                        new TextButton(
                          child: new Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _inAppMessageReceived(BrazeInAppMessage inAppMessage) {
    print("Received message: ${inAppMessage.toString()}");
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text("Received message: ${inAppMessage.toString()}"),
    ));

    // Programmatically log impression, body click, and any button clicks
    if (automaticallyInteract) {
      print(
          "Logging impression, body click, and button clicks programmatically.");
      _braze.logInAppMessageImpression(inAppMessage);
      _braze.logInAppMessageClicked(inAppMessage);
      inAppMessage.buttons.forEach((button) {
        _braze.logInAppMessageButtonClicked(inAppMessage, button.id);
      });
    }
  }

  void _contentCardsReceived(List<BrazeContentCard> contentCards) {
    if (contentCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: new Text("Empty Content Cards update received."),
      ));
      return;
    }
    contentCards.forEach((contentCard) {
      print("Received content card: " + contentCard.toString());
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: new Text("Received content card: ${contentCard.toString()}"),
      ));

      // Programmatically log impression, card click, and dismissal
      if (automaticallyInteract) {
        print("Logging impression and body click programmatically.");
        _braze.logContentCardImpression(contentCard);
        _braze.logContentCardClicked(contentCard);
        // _braze.logContentCardDismissed(contentCard);
      }
    });
  }

  void _featureFlagsReceived(List<BrazeFeatureFlag> featureFlags) {
    if (featureFlags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: new Text("Empty Feature Flags update received."),
      ));
      return;
    }
    featureFlags.forEach((featureFlag) {
      print("Received feature flag: " + featureFlag.id);
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: new Text("Received feature flag: ${featureFlag.id}"),
      ));
    });
  }

  String _featureFlagToString(BrazeFeatureFlag ff) {
    String ffString = "Feature Flag ID: " +
        ff.id +
        "\n" +
        "  FF Enabled: " +
        ff.enabled.toString() +
        "\n";
    ff.properties.forEach((key, value) {
      ffString += "  FF Key: " +
          key.toString() +
          " Type: " +
          value["type"] +
          " Value: " +
          value["value"].toString() +
          "\n";
    });
    return ffString;
  }

  void _pressedLogPresetEventsAndPurchasesButton() {
    var props = <String, dynamic>{"k1": "v1", "k2": 2, "k3": 3.5, "k4": false};
    _braze.logCustomEvent("eventName");
    _braze.logCustomEvent("eventNameProps", properties: props);
    _braze.logPurchase("productId", "USD", 3.50, 2);
    _braze.logPurchase("productIdProps", "USD", 2.50, 4, properties: props);

    // Native layer should gracefully handle null properties
    props['keyWithNullValue'] = null;
    _braze.logCustomEvent("eventWithNullElementInProps", properties: props);
    _braze.logPurchase("purchaseWithNullElementInProps", "EUR", 1.23, 6,
        properties: props);

    // Nested properties
    Map<String, dynamic> nestedProps = {
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
    _braze.logCustomEvent('nestedEvent', properties: nestedProps);
    _braze.logPurchase('nestedProductId', 'EUR', 1.50, 6,
        properties: nestedProps);

    // Reject when properties is larger than 50KB
    String largeValue = 'AB' * 50 * 1024;
    Map<String, dynamic> largeProperties = {'largePayload': largeValue};
    _braze.logCustomEvent('event_propertiesTooLarge',
        properties: largeProperties);
    _braze.logPurchase('purchase_propertiesTooLarge', 'EUR', 13.3, 7,
        properties: largeProperties);

    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content: new Text("Logged preset events and purchases"),
    ));
  }
}

class SectionHeader extends StatelessWidget {
  SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Divider(
          thickness: 2,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline),
        ),
      ),
    ]);
  }
}
