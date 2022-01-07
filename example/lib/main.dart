import 'dart:io' show Platform;
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
  String _ccCallbackEnabled = "DISABLED";
  String _iamCallbackEnabled = "DISABLED";
  BrazePlugin _braze;
  final userIdController = TextEditingController();
  final customEventNameController = TextEditingController();
  final customEventPropertyKeyController = TextEditingController();
  final customEventPropertyValueController = TextEditingController();

  void initState() {
    _braze = new BrazePlugin(customConfigs: {replayCallbacksConfigKey: true});
    super.initState();
  }

  @override
  void dispose() {
    userIdController.dispose();
    customEventNameController.dispose();
    customEventPropertyKeyController.dispose();
    customEventPropertyValueController.dispose();
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
            Center(child: Text("IAM Callback Status: $_iamCallbackEnabled")),
            Center(child: Text("CC Callback Status: $_ccCallbackEnabled")),
            Center(child: Text("User Id: $_userId")),
            TextField(
              autocorrect: false,
              controller: userIdController,
              decoration: InputDecoration(
                  hintText: 'Please enter a user id', labelText: 'User Id'),
            ),
            TextButton(
              child: const Text('CHANGE USER'),
              onPressed: () {
                String userId = userIdController.text;
                _braze.changeUser(userId);
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
                _braze.setAvatarImageUrl("https://raw.githubusercontent.com/"
                    "Appboy/appboy-react-sdk/master/braze-logo.png");
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
            TextButton(
              child: const Text('REQUEST LOCATION INITIALIZATION'),
              onPressed: () {
                _braze.requestLocationInitialization();
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
              child: const Text('SET IN-APP MESSAGE CALLBACK'),
              onPressed: () {
                this.setState(() {
                  _iamCallbackEnabled = 'ENABLED';
                });
                _braze.setBrazeInAppMessageCallback(
                    (BrazeInAppMessage inAppMessage) {
                  print("Received message: " + inAppMessage.toString());
                  _braze.logInAppMessageImpression(inAppMessage);
                  ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                    content: new Text("Received message and logging clicks: " +
                        inAppMessage.toString()),
                  ));
                  _braze.logInAppMessageClicked(inAppMessage);
                  inAppMessage.buttons.forEach((button) {
                    _braze.logInAppMessageButtonClicked(
                        inAppMessage, button.id);
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("In-app message callback set. "
                      "In-app message data will appear in snackbars."),
                ));
              },
            ),
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
                this.setState(() {
                  _ccCallbackEnabled = 'ENABLED';
                });
                _braze.setBrazeContentCardsCallback(
                    (List<BrazeContentCard> contentCards) {
                  if (contentCards.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content: new Text("Empty Content Cards update received."),
                    ));
                  }
                  _braze.logContentCardsDisplayed();
                  contentCards.forEach((contentCard) {
                    print("Received card: " + contentCard.toString());
                    _braze.logContentCardClicked(contentCard);
                    _braze.logContentCardImpression(contentCard);
                    // _braze.logContentCardDismissed(contentCard);
                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                      content:
                          new Text("Received card: " + contentCard.toString()),
                    ));
                  });
                });
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(
                  content: new Text("Content Cards callback set. "
                      "Content Card data will appear in snackbars."),
                ));
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
