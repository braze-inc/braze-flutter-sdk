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

  /// Placements the user has requested a refresh for, used to populate the
  /// "Requested Banners" card.
  List<String> _knownPlacements = [];

  /// Maps a placement ID to whether a banner is locally available for it.
  /// A missing entry means availability is unknown.
  final Map<String, bool> _availability = {};

  /// Placements currently displayed in the "Display Multiple Banners" card.
  List<String> _multiBannerPlacements = [];

  final _bannerRefreshController =
      TextEditingController(text: 'placement_1, placement_2');
  final _bannerPlacementController = TextEditingController();
  final _bannerPropertyKeyController = TextEditingController();
  final _displayBannerController = TextEditingController();
  final _multiBannerController = TextEditingController(
      text: 'banner-dismissal-2, banner-dismissal-3, banner-dismissal-4');

  static const bool _automaticallyInteract = false;

  @override
  void dispose() {
    _bannerSubscription?.cancel();
    _bannerRefreshController.dispose();
    _bannerPlacementController.dispose();
    _bannerPropertyKeyController.dispose();
    _displayBannerController.dispose();
    _multiBannerController.dispose();
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

  List<String> _parsePlacements(String ids) => ids
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  void _requestBannersRefresh() {
    final placementIds = _parsePlacements(_bannerRefreshController.text);
    if (placementIds.isEmpty) {
      context.showBrazeAppSnackbar('Please enter placement IDs');
      return;
    }
    braze.requestBannersRefresh(placementIds);
    setState(() {
      _knownPlacements = {..._knownPlacements, ...placementIds}.toList();
    });
    context.showBrazeAppSnackbar('Banner refresh requested');
    // Refresh is async over the network; re-check availability shortly after.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _checkAvailability(placementIds);
    });
  }

  Future<void> _checkAvailability(List<String> placements) async {
    final entries = await Future.wait(placements.map((placementId) async {
      final banner = await braze.getBanner(placementId);
      return MapEntry(placementId, banner != null);
    }));
    if (!mounted) return;
    setState(() {
      for (final entry in entries) {
        _availability[entry.key] = entry.value;
      }
    });
  }

  void _displaySinglePlacement(String placementId) {
    setState(() {
      _displayedPlacement = placementId;
      _displayBannerController.text = placementId;
    });
  }

  void _displayAllAvailable() {
    final placements =
        _knownPlacements.where((id) => _availability[id] == true).toList();
    if (placements.isEmpty) {
      context.showBrazeAppSnackbar(
        'No locally available banners. Try "Check Availability" after a refresh.',
      );
      return;
    }
    setState(() => _multiBannerPlacements = placements);
    context.showBrazeAppSnackbar('Displaying ${placements.length} banners');
  }

  void _displayMultiBanners() {
    final placements = _parsePlacements(_multiBannerController.text);
    if (placements.isEmpty) {
      context.showBrazeAppSnackbar('Please enter at least one placement ID');
      return;
    }
    setState(() => _multiBannerPlacements = placements);
    context.showBrazeAppSnackbar('Displaying ${placements.length} banners');
  }

  void _onBannerDismissed(BrazeBannerDismissEvent event) {
    if (!mounted) return;
    context.showBrazeAppSnackbar(
      'Banner dismissed: ${event.placementId}, stable key: ${event.stableKey}, tracking ID: ${event.trackingId}',
    );
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

  /// A tappable chip for a known placement, with a dot indicating local
  /// availability (green = available, red = unavailable, gray = unknown).
  Widget _buildPlacementChip(String placementId) {
    final isAvailable = _availability[placementId];
    final dotColor = isAvailable == null
        ? BrazeAppColors.textLight
        : isAvailable
            ? BrazeAppColors.success
            : BrazeAppColors.danger;
    return InkWell(
      onTap: () => _displaySinglePlacement(placementId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: BrazeAppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrazeAppColors.borderGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              placementId,
              style: const TextStyle(
                fontSize: 14,
                color: BrazeAppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A labeled container hosting a [BrazeBannerView] for [placementId].
  Widget _buildBannerContainer(String placementId, String label) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrazeAppColors.backgroundGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BrazeAppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          BrazeBannerView(
            placementId: placementId,
            onDismiss: _onBannerDismissed,
          ),
        ],
      ),
    );
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
                _requestBannersRefresh();
              },
            ),
          ],
        ),
        if (_knownPlacements.isNotEmpty)
          BrazeAppCard(
            title: 'Requested Banners',
            children: [
              const Text(
                'Tap a placement to display it below. Dot shows whether the '
                'banner is available locally.',
                style: TextStyle(fontSize: 13, color: BrazeAppColors.textGray),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _knownPlacements.map(_buildPlacementChip).toList(),
              ),
              const SizedBox(height: 8),
              BrazeAppButton(
                title: 'Check Availability',
                variant: BrazeButtonVariant.secondary,
                onPressed: () {
                  if (!validateBrazeSdkEnabled(context)) return;
                  _checkAvailability(_knownPlacements);
                },
              ),
              BrazeAppButton(
                title: 'Display All Available',
                variant: BrazeButtonVariant.secondary,
                onPressed: () {
                  if (!validateBrazeSdkEnabled(context)) return;
                  _displayAllAvailable();
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
            BrazeAppButton(
              title: 'Dismiss Banner',
              variant: BrazeButtonVariant.secondary,
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                final id = _bannerPlacementController.text;
                if (id.isEmpty) {
                  context.showBrazeAppSnackbar('Please enter a placement ID');
                  return;
                }
                braze.dismissBanner(id);
                context.showBrazeAppSnackbar('Banner dismissed for: $id');
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
            if (_displayedPlacement != null && _displayedPlacement!.isNotEmpty)
              _buildBannerContainer(
                _displayedPlacement!,
                'Current Banner: $_displayedPlacement',
              ),
          ],
        ),
        BrazeAppCard(
          title: 'Display Multiple Banners',
          children: [
            BrazeAppInput(
              label: 'Placement IDs (comma-separated)',
              hint: 'banner-dismissal-2, banner-dismissal-3, banner-dismissal-4',
              controller: _multiBannerController,
            ),
            BrazeAppButton(
              title: 'Display Multiple Banners',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                _displayMultiBanners();
              },
            ),
            for (final placementId in _multiBannerPlacements)
              _buildBannerContainer(placementId, 'Banner: $placementId'),
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
