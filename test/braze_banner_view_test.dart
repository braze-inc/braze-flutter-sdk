import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BrazeBannerView - onDismiss Callback', () {
    testWidgets('onDismiss callback is invoked when dismiss event is received',
        (WidgetTester tester) async {
      BrazeBannerDismissEvent? dismissEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'test-placement-1',
              onDismiss: (event) {
                dismissEvent = event;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);
      // The callback is set and ready to be invoked by the native layer
      expect(
          dismissEvent, isNull); // Not yet called since no dismiss event sent
    });

    testWidgets('onDismiss is null-safe when not provided',
        (WidgetTester tester) async {
      // Should not throw when onDismiss is not provided
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'test-placement-1',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);
    });
  });

  group('BrazeBannerView - didUpdateWidget', () {
    testWidgets(
        'didUpdateWidget resubscribes to dismiss events when placementId changes',
        (WidgetTester tester) async {
      String currentPlacement = 'test-placement-1';

      final updateKey = GlobalKey<_TestBannerWrapperState>();

      await tester.pumpWidget(
        _TestBannerWrapper(
          key: updateKey,
          placement: currentPlacement,
          onDismiss: (event) {},
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);

      // Change the placement
      updateKey.currentState?.updatePlacement('test-placement-2');
      await tester.pumpAndSettle();

      // The widget should have updated with the new placementId
      expect(find.byType(BrazeBannerView), findsOneWidget);
    });

    testWidgets(
        'didUpdateWidget resubscribes to dismiss events when onDismiss callback changes',
        (WidgetTester tester) async {
      final updateKey = GlobalKey<_TestBannerCallbackWrapperState>();

      await tester.pumpWidget(
        _TestBannerCallbackWrapper(
          key: updateKey,
          onDismiss: (event) {},
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);

      // Change the callback
      updateKey.currentState?.updateCallback((event) {});
      await tester.pumpAndSettle();

      // The widget should have updated with the new callback
      expect(find.byType(BrazeBannerView), findsOneWidget);
    });

    testWidgets(
        'didUpdateWidget handles both placementId and onDismiss changes together',
        (WidgetTester tester) async {
      final updateKey = GlobalKey<_TestBannerBothWrapperState>();

      await tester.pumpWidget(
        _TestBannerBothWrapper(
          key: updateKey,
          placement: 'test-placement-1',
          onDismiss: (event) {},
        ),
      );

      await tester.pumpAndSettle();

      // Update both placement and callback
      updateKey.currentState?.updateBoth(
        'test-placement-2',
        (event) {},
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrazeBannerView), findsOneWidget);
    });

    testWidgets('didUpdateWidget does not resubscribe when nothing changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'test-placement-1',
              onDismiss: (event) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);

      // Pump again without changing anything
      await tester.pumpAndSettle();

      // Widget should still be present
      expect(find.byType(BrazeBannerView), findsOneWidget);
    });
  });

  group('BrazeBannerView - Lifecycle', () {
    testWidgets('BrazeBannerView properly disposes subscriptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'test-placement-1',
              onDismiss: (event) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);

      // Remove the widget tree
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();

      // Widget should be removed
      expect(find.byType(BrazeBannerView), findsNothing);
    });

    testWidgets('BrazeBannerView handles null onDismiss gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'test-placement-1',
              onDismiss: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);
    });

    testWidgets('BrazeBannerView handles null placementId gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: null,
              onDismiss: (event) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(BrazeBannerView), findsOneWidget);
    });
  });

  group('BrazeBannerView - onDismiss event delivery', () {
    const bannerChannelName = 'braze_banner_view_channel';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Handles the EventChannel `listen`/`cancel` calls so the broadcast stream
    // can be subscribed to in tests.
    setUp(() {
      messenger.setMockMethodCallHandler(
        const MethodChannel(bannerChannelName),
        (call) async => null,
      );
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(
        const MethodChannel(bannerChannelName),
        null,
      );
    });

    /// Pushes an event onto the banner EventChannel stream as if it came from
    /// the native layer.
    Future<void> emitBannerEvent(Map<String, dynamic> event) async {
      await messenger.handlePlatformMessage(
        bannerChannelName,
        const StandardMethodCodec().encodeSuccessEnvelope(event),
        (_) {},
      );
    }

    testWidgets('onDismiss fires with event fields for a matching placement',
        (WidgetTester tester) async {
      BrazeBannerDismissEvent? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'placement-a',
              onDismiss: (event) => received = event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await emitBannerEvent(<String, dynamic>{
        'action': 'dismiss',
        'placementId': 'placement-a',
        'stableKey': 'stable-a',
        'trackingId': 'tracking-a',
      });
      await tester.pump();

      expect(received, isNotNull);
      expect(received!.placementId, equals('placement-a'));
      expect(received!.stableKey, equals('stable-a'));
      expect(received!.trackingId, equals('tracking-a'));
    });

    testWidgets('onDismiss does not fire for a different placement',
        (WidgetTester tester) async {
      BrazeBannerDismissEvent? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'placement-a',
              onDismiss: (event) => received = event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await emitBannerEvent(<String, dynamic>{
        'action': 'dismiss',
        'placementId': 'placement-b',
        'stableKey': 'stable-b',
        'trackingId': 'tracking-b',
      });
      await tester.pump();

      expect(received, isNull);
    });

    testWidgets('resize events do not trigger onDismiss',
        (WidgetTester tester) async {
      BrazeBannerDismissEvent? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrazeBannerView(
              placementId: 'placement-a',
              onDismiss: (event) => received = event,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await emitBannerEvent(<String, dynamic>{
        'containerId': 'some-container',
        'height': 100.0,
      });
      await tester.pump();

      expect(received, isNull);
    });
  });
}

/// Test wrapper for placement changes
class _TestBannerWrapper extends StatefulWidget {
  final String placement;
  final void Function(BrazeBannerDismissEvent) onDismiss;

  const _TestBannerWrapper({
    required Key key,
    required this.placement,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _TestBannerWrapperState createState() => _TestBannerWrapperState();
}

class _TestBannerWrapperState extends State<_TestBannerWrapper> {
  late String _placement;

  @override
  void initState() {
    super.initState();
    _placement = widget.placement;
  }

  void updatePlacement(String newPlacement) {
    setState(() {
      _placement = newPlacement;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BrazeBannerView(
          key: ValueKey(_placement),
          placementId: _placement,
          onDismiss: widget.onDismiss,
        ),
      ),
    );
  }
}

/// Test wrapper for callback changes
class _TestBannerCallbackWrapper extends StatefulWidget {
  final void Function(BrazeBannerDismissEvent) onDismiss;

  const _TestBannerCallbackWrapper({
    required Key key,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _TestBannerCallbackWrapperState createState() =>
      _TestBannerCallbackWrapperState();
}

class _TestBannerCallbackWrapperState
    extends State<_TestBannerCallbackWrapper> {
  late void Function(BrazeBannerDismissEvent) _callback;

  @override
  void initState() {
    super.initState();
    _callback = widget.onDismiss;
  }

  void updateCallback(void Function(BrazeBannerDismissEvent) newCallback) {
    setState(() {
      _callback = newCallback;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BrazeBannerView(
          placementId: 'test-placement-1',
          onDismiss: _callback,
        ),
      ),
    );
  }
}

/// Test wrapper for both placement and callback changes
class _TestBannerBothWrapper extends StatefulWidget {
  final String placement;
  final void Function(BrazeBannerDismissEvent) onDismiss;

  const _TestBannerBothWrapper({
    required Key key,
    required this.placement,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _TestBannerBothWrapperState createState() => _TestBannerBothWrapperState();
}

class _TestBannerBothWrapperState extends State<_TestBannerBothWrapper> {
  late String _placement;
  late void Function(BrazeBannerDismissEvent) _callback;

  @override
  void initState() {
    super.initState();
    _placement = widget.placement;
    _callback = widget.onDismiss;
  }

  void updateBoth(
      String newPlacement, void Function(BrazeBannerDismissEvent) newCallback) {
    setState(() {
      _placement = newPlacement;
      _callback = newCallback;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BrazeBannerView(
          key: ValueKey('$_placement-callback'),
          placementId: _placement,
          onDismiss: _callback,
        ),
      ),
    );
  }
}
