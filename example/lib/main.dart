import 'dart:async';
import 'dart:io' show Platform;
import 'package:braze_plugin_example/jwt_generator.dart';
import 'package:flutter/material.dart';

import 'package:braze_plugin/braze_plugin.dart';

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

class BrazeFunctionsState extends State<BrazeFunctions> {
  String _userId = "";
  String _enabled = "";
  String _ccStreamSubscription = "DISABLED";
  String _iamStreamSubscription = "DISABLED";
  BrazePlugin _braze;
  final userIdController = TextEditingController();
  final customEventNameController = TextEditingController();
  final customEventPropertyKeyController = TextEditingController();
  final customEventPropertyValueController = TextEditingController();
  StreamSubscription inAppMessageStreamSubscription;
  StreamSubscription contentCardsStreamSubscription;
  List<BrazeContentCard> _brazeContentCards = <BrazeContentCard>[];

  void initState() {
    _braze = new BrazePlugin(customConfigs: {replayCallbacksConfigKey: true});

    _braze.setBrazeSdkAuthenticationErrorCallback(
        (BrazeSdkAuthenticationError error) async {
      print('Received an SDK Auth error: $error');

      String newSignature = await JwtGenerator.create(_userId);
      print('Setting new signature: $newSignature, userId: $_userId');
      _braze.setSdkAuthenticationSignature(newSignature);
    });

    super.initState();
  }

  @override
  void dispose() {
    userIdController.dispose();
    customEventNameController.dispose();
    customEventPropertyKeyController.dispose();
    customEventPropertyValueController.dispose();

    /// Stop listening to streams
    inAppMessageStreamSubscription.cancel();
    contentCardsStreamSubscription.cancel();
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
        if (result == null || result == "") {
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
            SectionHeader("In-app Messages"),
            TextButton(
              child: const Text('SET IN-APP MESSAGE CALLBACK'),
              onPressed: () {
                // ignore: deprecated_member_use
                _braze.setBrazeInAppMessageCallback(
                    (BrazeInAppMessage inAppMessage) {
                  _inAppMessageReceived(inAppMessage, prefix: "CALLBACK");
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("In-app message callback set. "
                      "In-app message data will appear in snackbars."),
                ));
              },
            ),
            TextButton(
              child: const Text('SUBSCRIBE VIA IN-APP MESSAGE STREAM'),
              onPressed: () {
                this.setState(() {
                  _iamStreamSubscription = 'ENABLED';
                });
                inAppMessageStreamSubscription = _braze
                    .subscribeToInAppMessages((BrazeInAppMessage inAppMessage) {
                  _inAppMessageReceived(inAppMessage, prefix: "STREAM");
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
              child: const Text('SET CONTENT CARDS CALLBACK'),
              onPressed: () {
                // ignore: deprecated_member_use
                _braze.setBrazeContentCardsCallback(
                    (List<BrazeContentCard> contentCards) {
                  _contentCardsReceived(contentCards, prefix: "CALLBACK");
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Content Cards Callback set. "
                      "Content Card data will appear in snackbars."),
                ));
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
                  _contentCardsReceived(contentCards, prefix: "STREAM");
                  return;
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Listening to content cards stream. "
                      "Content Card data will appear in snackbars."),
                ));
              },
            ),
            Visibility(
              visible: _brazeContentCards.isNotEmpty,
              child: SectionHeader("ContentCards"),
            ),
            Visibility(
              visible: _brazeContentCards.isNotEmpty,
              child: Column(
                children: _brazeContentCards
                    .map(
                      (contentCard) => ContentCard(
                        contentCard: contentCard,
                      ),
                    )
                    .toList(),
              ),
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
                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content: new Text("Install Tracking ID was null"),
                    ));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content: new Text("Install Tracking ID: " + result),
                    ));
                  }
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

  void _inAppMessageReceived(BrazeInAppMessage inAppMessage,
      {String prefix, bool automaticallyInteract = false}) {
    print("[$prefix] Received message: ${inAppMessage.toString()}");
    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
      content:
          new Text("[$prefix] Received message: ${inAppMessage.toString()}"),
    ));

    // Programmatically log impression, body click, and any button clicks
    if (automaticallyInteract) {
      print(
          "[$prefix] Logging impression, body click, and button clicks programmatically.");
      _braze.logInAppMessageImpression(inAppMessage);
      _braze.logInAppMessageClicked(inAppMessage);
      inAppMessage.buttons.forEach((button) {
        _braze.logInAppMessageButtonClicked(inAppMessage, button.id);
      });
    }
  }

  void _contentCardsReceived(List<BrazeContentCard> contentCards,
      {String prefix, bool automaticallyInteract = false}) {
    if (contentCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: new Text("Empty Content Cards update received."),
      ));
      return;
    }
    setState(() {
      _brazeContentCards = contentCards;
    });
    contentCards.forEach((contentCard) {
      print("[$prefix] Received card: " + contentCard.toString());
      ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
        content: new Text("[$prefix] Received card: ${contentCard.toString()}"),
      ));

      // Programmatically log impression, card click, and dismissal
      if (automaticallyInteract) {
        print("[$prefix] Logging impression and body click programmatically.");
        _braze.logContentCardImpression(contentCard);
        _braze.logContentCardClicked(contentCard);

        // Only for testing, remove from actual branch
        // - Executes dismissal and removes from UI too
        _braze.logContentCardDismissed(contentCard);
      }
    });
  }

  void _pressedLogPresetEventsAndPurchasesButton() {
    var props = {"k1": "v1", "k2": 2, "k3": 3.5, "k4": false};
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
          style: Theme.of(context).textTheme.headline6.copyWith(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline),
        ),
      ),
    ]);
  }
}
