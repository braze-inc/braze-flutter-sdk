import 'dart:io' show Platform;

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/jwt_generator.dart';
import 'package:braze_plugin_example/screens/banners_screen.dart';
import 'package:braze_plugin_example/screens/content_cards_screen.dart';
import 'package:braze_plugin_example/screens/feature_flags_screen.dart';
import 'package:braze_plugin_example/constants/config.dart';
import 'package:braze_plugin_example/screens/user_management_screen.dart';
import 'package:braze_plugin_example/log_console.dart';
import 'package:braze_plugin_example/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared [BrazePlugin] for the sample app; assigned in [HomeScreen] `initState`.
late BrazePlugin braze;

/// Last known user id for SDK auth flows (updated from [HomeScreen] and user screens).
String currentUserId = '';

/// True when [BrazePlugin.getDeviceId] returns a non-empty value (SDK reachable).
/// Updated from [HomeScreen] and user management (e.g. enable/disable SDK).
bool brazeSdkEnabled = false;

/// Landing screen: initializes the SDK and lists feature areas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    braze = BrazePlugin(customConfigs: {replayCallbacksConfigKey: true});

    if (Platform.isAndroid) {
      braze.initialize(
        defaultAndroidApiKey,
        defaultEndpoint,
      );
    } else if (Platform.isIOS) {
      braze.initialize(
        defaultIOSApiKey,
        defaultEndpoint,
      );
    }

    braze.setBrazeSdkAuthenticationErrorCallback(
      (BrazeSdkAuthenticationError error) async {
        print('Received an SDK Auth error: $error');
        final String? newSignature = await JwtGenerator.create(currentUserId);
        print(
          'Setting new signature: $newSignature, userId: $currentUserId',
        );
        braze.setSdkAuthenticationSignature(newSignature);
      },
    );

    braze.getUserId().then((userId) {
      if (userId != null) {
        currentUserId = userId;
      }
    });

    braze.getDeviceId().then((result) {
      brazeSdkEnabled = result.isNotEmpty;
    });

    braze.requestBannersRefresh(['placement_1', 'placement_2', 'sdk-test-2']);

    MethodChannel('deepLinkChannel')
        .setMethodCallHandler((MethodCall call) async {
      if (mounted) {
        showDeepLinkAlert(context, call.arguments as String);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const features = [
      FeatureCardData(
        title: 'Content Cards',
        description: 'Launch, refresh, and interact with Content Cards',
        icon: '🎴',
        color: BrazeAppColors.orange,
        destination: SampleDestination.contentCards,
      ),
      FeatureCardData(
        title: 'Banners',
        description: 'Manage banner placements and properties',
        icon: '📢',
        color: BrazeAppColors.pink,
        destination: SampleDestination.banners,
      ),
      FeatureCardData(
        title: 'Feature Flags',
        description: 'Get and manage feature flags',
        icon: '🚩',
        color: BrazeAppColors.primary,
        destination: SampleDestination.featureFlags,
      ),
      FeatureCardData(
        title: 'User Management',
        description:
            'Events, user attributes, in-app messages, SDK controls, and more',
        icon: '⚙️',
        color: BrazeAppColors.primaryDark,
        destination: SampleDestination.userManagement,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Braze Flare'),
        actions: const [
          LogConsoleToggleButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                'Braze Flare 🔥',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: BrazeAppColors.textDark,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'feat. Braze Flutter SDK',
                style: TextStyle(
                  fontSize: 16,
                  color: BrazeAppColors.textGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              ...features.map(
                (f) => FeatureCard(
                  data: f,
                  onTap: () => _navigateTo(context, f.destination),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Select a category to test Braze SDK features',
                style: TextStyle(
                  fontSize: 14,
                  color: BrazeAppColors.textPlaceholder,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, SampleDestination destination) {
    final Widget dest;
    switch (destination) {
      case SampleDestination.contentCards:
        dest = const ContentCardsScreen();
        break;
      case SampleDestination.banners:
        dest = const BannersScreen();
        break;
      case SampleDestination.featureFlags:
        dest = const FeatureFlagsScreen();
        break;
      case SampleDestination.userManagement:
        dest = const UserManagementScreen();
        break;
    }
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => dest),
    );
  }
}
