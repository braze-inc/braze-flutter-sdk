import 'dart:async';

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/screens/home_screen.dart';
import 'package:braze_plugin_example/sdk_helpers.dart';
import 'package:braze_plugin_example/theme.dart';
import 'package:flutter/material.dart';

/// Banners API demos, [BrazeBannerView], and stream subscription.
class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  String _bannerStreamStatus = 'Disabled';
  StreamSubscription? _bannerSubscription;
  String _bannerPropertyType = 'Boolean';
  String? _displayedPlacement = 'sdk-test-2';

  final _bannerRefreshController =
      TextEditingController(text: 'placement_1, placement_2');
  final _bannerPlacementController = TextEditingController();
  final _bannerPropertyKeyController = TextEditingController();
  final _displayBannerController = TextEditingController();

  static const bool _automaticallyInteract = false;

  @override
  void dispose() {
    _bannerSubscription?.cancel();
    _bannerRefreshController.dispose();
    _bannerPlacementController.dispose();
    _bannerPropertyKeyController.dispose();
    _displayBannerController.dispose();
    super.dispose();
  }

  void _bannersReceived(List<BrazeBanner> banners) {
    if (!mounted || !brazeSdkEnabled) return;
    if (banners.isEmpty) {
      context.showBrazeAppSnackbar('Empty Banner update received.');
      return;
    }
    for (final banner in banners) {
      print('Received banner: ${banner.toString()}');
      context.showBrazeAppSnackbar('Received banner: ${banner.toString()}');
      if (_automaticallyInteract) {
        braze.logBannerImpression(banner.placementId);
        braze.logBannerClicked(banner.placementId, null);
        braze.logBannerClicked(banner.placementId, 'testId');
      }
    }
  }

  void _refreshBanners(String ids) {
    final placementIds = ids.isEmpty
        ? <String>[]
        : ids.split(',').map((e) => e.trim()).toList();
    braze.requestBannersRefresh(placementIds);
  }

  dynamic _readBannerProperty(BrazeBanner banner, String key, String type) {
    switch (type) {
      case 'Boolean':
        return banner.getBooleanProperty(key);
      case 'Number':
        return banner.getNumberProperty(key);
      case 'String':
        return banner.getStringProperty(key);
      case 'Timestamp':
        return banner.getTimestampProperty(key);
      case 'Json':
        return banner.getJSONProperty(key);
      case 'Image':
        return banner.getImageProperty(key);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrazeAppScreenLayout(
      title: 'Banners',
      subtitle: 'Manage banner placements and properties',
      children: [
        BrazeAppCard(
          title: 'Refresh Banners',
          children: [
            BrazeAppInput(
              label: 'Placement IDs (comma-separated)',
              hint: 'placement_1, placement_2',
              controller: _bannerRefreshController,
            ),
            BrazeAppButton(
              title: 'Request Banners Refresh',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                _refreshBanners(_bannerRefreshController.text);
                context.showBrazeAppSnackbar('Banner refresh requested');
              },
            ),
          ],
        ),
        BrazeAppCard(
          title: 'Get Banner by ID',
          children: [
            BrazeAppInput(
              label: 'Placement ID',
              hint: 'Enter placement ID',
              controller: _bannerPlacementController,
            ),
            BrazeAppButton(
              title: 'Get Banner by Placement ID',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _bannerPlacementController.text;
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a placement ID');
                  return;
                }
                braze.getBanner(id).then((banner) {
                  if (!mounted) return;
                  if (banner == null) {
                    context.showBrazeAppSnackbar('No Banner found for: $id');
                  } else {
                    context.showBrazeAppSnackbar(
                      'Found Banner: ${banner.placementId}',
                    );
                    print('Banner: ${banner.toString()}');
                  }
                });
              },
            ),
            BrazeAppButton(
              title: 'Log Impression',
              variant: BrazeButtonVariant.secondary,
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _bannerPlacementController.text;
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a placement ID');
                  return;
                }
                braze.logBannerImpression(id);
                context.showBrazeAppSnackbar('Banner impression logged for: $id');
              },
            ),
            BrazeAppButton(
              title: 'Log Click',
              variant: BrazeButtonVariant.secondary,
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _bannerPlacementController.text;
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a placement ID');
                  return;
                }
                braze.logBannerClicked(id, null);
                context.showBrazeAppSnackbar('Banner click logged for: $id');
              },
            ),
            BrazeAppCard(
              title: 'Get Banner Property',
              children: [
                PropertyTypeDropdown(
                  value: _bannerPropertyType,
                  onChanged: (v) => setState(() => _bannerPropertyType = v!),
                ),
                BrazeAppInput(
                  label: 'Property Key',
                  hint: 'Enter property key',
                  controller: _bannerPropertyKeyController,
                ),
                BrazeAppButton(
                  title: 'Get Banner Property',
                  onPressed: () {
                    if (!validateBrazeSdkEnabled(context)) return;
                    final id = _bannerPlacementController.text;
                    final key = _bannerPropertyKeyController.text;
                    if (id.isEmpty || key.isEmpty) {
                      context.showBrazeAppSnackbar(
                        'Please enter placement ID and property key',
                      );
                      return;
                    }
                    braze.getBanner(id).then((banner) {
                      if (!mounted) return;
                      if (banner == null) {
                        context.showBrazeAppSnackbar('No Banner found for: $id');
                        return;
                      }
                      final property =
                          _readBannerProperty(banner, key, _bannerPropertyType);
                      print('Property found: $property');
                      context.showBrazeAppSnackbar('Property ($key): $property');
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        BrazeAppCard(
          title: 'Display Banner',
          children: [
            BrazeAppInput(
              label: 'Banner Placement ID',
              hint: 'Enter placement ID to display',
              controller: _displayBannerController,
            ),
            BrazeAppButton(
              title: 'Change Displayed Banner',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _displayBannerController.text.trim();
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a placement ID');
                  return;
                }
                braze.getBanner(id).then((banner) {
                  if (!mounted) return;
                  if (banner == null) {
                    context.showBrazeAppSnackbar('No Banner found for: $id');
                    return;
                  }
                  setState(() => _displayedPlacement = id);
                });
              },
            ),
            if (_displayedPlacement != null &&
                _displayedPlacement!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrazeAppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Banner: $_displayedPlacement',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BrazeAppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BrazeBannerView(placementId: _displayedPlacement),
                  ],
                ),
              ),
            ],
          ],
        ),
        BrazeAppCard(
          title: 'Streams',
          children: [
            StatusRow(label: 'Banner Stream', value: _bannerStreamStatus),
            const SizedBox(height: 8),
            BrazeAppButton(
              title: 'Subscribe to Banner Stream',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                setState(() => _bannerStreamStatus = 'Enabled');
                _bannerSubscription =
                    braze.subscribeToBanners(_bannersReceived);
                context.showBrazeAppSnackbar('Listening to banner stream.');
              },
            ),
          ],
        ),
      ],
    );
  }
}
