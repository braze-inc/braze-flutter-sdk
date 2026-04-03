import 'dart:async';

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/screens/home_screen.dart';
import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/sdk_helpers.dart';
import 'package:flutter/material.dart';

/// Feature Flags API demos and stream subscription.
class FeatureFlagsScreen extends StatefulWidget {
  const FeatureFlagsScreen({super.key});

  @override
  State<FeatureFlagsScreen> createState() => _FeatureFlagsScreenState();
}

class _FeatureFlagsScreenState extends State<FeatureFlagsScreen> {
  String _ffStreamStatus = 'Disabled';
  StreamSubscription? _featureFlagsSubscription;
  String _ffPropertyType = 'Boolean';
  final _ffIdController = TextEditingController();
  final _ffPropertyKeyController = TextEditingController();

  @override
  void dispose() {
    _featureFlagsSubscription?.cancel();
    _ffIdController.dispose();
    _ffPropertyKeyController.dispose();
    super.dispose();
  }

  void _featureFlagsReceived(List<BrazeFeatureFlag> featureFlags) {
    if (!mounted || !brazeSdkEnabled) return;
    if (featureFlags.isEmpty) {
      context.showBrazeAppSnackbar('Empty Feature Flags update received.');
      return;
    }
    for (final ff in featureFlags) {
      print('Received feature flag: ${ff.id}');
      context.showBrazeAppSnackbar('Received feature flag: ${ff.id}');
    }
  }

  dynamic _readFeatureFlagProperty(
    BrazeFeatureFlag ff,
    String key,
    String type,
  ) {
    switch (type) {
      case 'Boolean':
        return ff.getBooleanProperty(key);
      case 'Number':
        return ff.getNumberProperty(key);
      case 'String':
        return ff.getStringProperty(key);
      case 'Timestamp':
        return ff.getTimestampProperty(key);
      case 'Json':
        return ff.getJSONProperty(key);
      case 'Image':
        return ff.getImageProperty(key);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrazeAppScreenLayout(
      title: 'Feature Flags',
      subtitle: 'Get and manage Braze feature flags',
      children: [
        BrazeAppCard(
          title: 'All Feature Flags',
          children: [
            BrazeAppButton(
              title: 'Refresh Feature Flags',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                braze.refreshFeatureFlags();
                context.showBrazeAppSnackbar('Feature Flags refresh requested');
              },
            ),
            BrazeAppButton(
              title: 'Get All Feature Flags',
              variant: BrazeButtonVariant.secondary,
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                braze.getAllFeatureFlags().then((ffs) {
                  if (!mounted) return;
                  if (ffs.isEmpty) {
                    context.showBrazeAppSnackbar('No Feature Flags found.');
                    return;
                  }
                  for (final ff in ffs) {
                    final str = formatFeatureFlag(ff);
                    print(str);
                    context.showBrazeAppSnackbar(str);
                  }
                });
              },
            ),
          ],
        ),
        BrazeAppCard(
          title: 'Get a Feature Flag',
          children: [
            BrazeAppInput(
              label: 'Feature Flag ID',
              hint: 'Enter flag ID',
              controller: _ffIdController,
            ),
            BrazeAppButton(
              title: 'Get Feature Flag by ID',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _ffIdController.text;
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a feature flag ID');
                  return;
                }
                braze.getFeatureFlagByID(id).then((ff) {
                  if (!mounted) return;
                  if (ff == null) {
                    context.showBrazeAppSnackbar('No Feature Flag found with ID: $id');
                  } else {
                    final str = formatFeatureFlag(ff);
                    print(str);
                    context.showBrazeAppSnackbar(str);
                  }
                });
              },
            ),
            BrazeAppButton(
              title: 'Log Feature Flag Impression',
              variant: BrazeButtonVariant.secondary,
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _ffIdController.text;
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a feature flag ID');
                  return;
                }
                braze.logFeatureFlagImpression(id);
                context.showBrazeAppSnackbar('Impression logged for: $id');
              },
            ),
            BrazeAppCard(
              title: 'Get Feature Flag Property',
              children: [
                BrazeAppInput(
                  label: 'Property Key',
                  hint: 'Enter property key',
                  controller: _ffPropertyKeyController,
                ),
                PropertyTypeDropdown(
                  value: _ffPropertyType,
                  onChanged: (v) => setState(() => _ffPropertyType = v!),
                ),
                BrazeAppButton(
                  title: 'Get Feature Flag Property',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final id = _ffIdController.text;
                    final key = _ffPropertyKeyController.text;
                    if (id.isEmpty || key.isEmpty) {
                      context.showBrazeAppSnackbar(
                        'Please enter flag ID and property key',
                      );
                      return;
                    }
                    braze.getFeatureFlagByID(id).then((ff) {
                      if (!mounted) return;
                      if (ff == null) {
                        context.showBrazeAppSnackbar(
                          'No Feature Flag found with ID: $id',
                        );
                        return;
                      }
                      final property =
                          _readFeatureFlagProperty(ff, key, _ffPropertyType);
                      print('FF Property ($key): $property');
                      context.showBrazeAppSnackbar('Property ($key): $property');
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        BrazeAppCard(
          title: 'Streams',
          children: [
            StatusRow(label: 'FF Stream', value: _ffStreamStatus),
            const SizedBox(height: 8),
            BrazeAppButton(
              title: 'Subscribe to Feature Flag Stream',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                setState(() => _ffStreamStatus = 'Enabled');
                _featureFlagsSubscription =
                    braze.subscribeToFeatureFlags(_featureFlagsReceived);
                context.showBrazeAppSnackbar('Listening to feature flag stream.');
              },
            ),
          ],
        ),
        const BrazeAppInfoBox(
          text:
              'Feature flag details will be logged to the console. Use the ID field above for impression logging and property queries.',
        ),
      ],
    );
  }
}
