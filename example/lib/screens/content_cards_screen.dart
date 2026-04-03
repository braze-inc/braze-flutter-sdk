import 'dart:async';

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/screens/home_screen.dart';
import 'package:braze_plugin_example/sdk_helpers.dart';
import 'package:flutter/material.dart';

/// Content Cards API demos and stream subscriptions.
class ContentCardsScreen extends StatefulWidget {
  const ContentCardsScreen({super.key});

  @override
  State<ContentCardsScreen> createState() => _ContentCardsScreenState();
}

class _ContentCardsScreenState extends State<ContentCardsScreen> {
  String _ccStreamStatus = 'Disabled';
  StreamSubscription? _contentCardsSubscription;

  static const bool _automaticallyInteract = false;

  @override
  void dispose() {
    _contentCardsSubscription?.cancel();
    super.dispose();
  }

  void _contentCardsReceived(List<BrazeContentCard> contentCards) {
    if (!mounted || !brazeSdkEnabled) return;
    if (contentCards.isEmpty) {
      context.showBrazeAppSnackbar('Empty Content Cards update received.');
      return;
    }
    for (final card in contentCards) {
      print('Received content card: ${card.toString()}');
      context.showBrazeAppSnackbar('Content card: ${card.toString()}');
      if (_automaticallyInteract) {
        braze.logContentCardImpression(card);
        braze.logContentCardClicked(card);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrazeAppScreenLayout(
      title: 'Content Cards',
      subtitle: 'Manage and interact with Braze Content Cards',
      children: [
        BrazeAppCard(
          title: 'Launch & Refresh',
          children: [
            BrazeAppButton(
              title: 'Launch Content Cards',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                braze.launchContentCards();
              },
            ),
            BrazeAppButton(
              title: 'Refresh Content Cards',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                braze.requestContentCardsRefresh();
                context.showBrazeAppSnackbar('Content Cards refresh requested');
              },
            ),
          ],
        ),
        BrazeAppCard(
          title: 'Get Content Cards',
          children: [
            BrazeAppButton(
              title: 'Get Cached Content Cards',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                braze.getCachedContentCards().then((cards) {
                  if (!mounted) return;
                  print('${cards.length} cached Content Cards found.');
                  if (cards.isEmpty) {
                    context.showBrazeAppSnackbar('No cached Content Cards found.');
                    return;
                  }
                  for (final card in cards) {
                    final str = card.toString();
                    print(str);
                    context.showBrazeAppSnackbar('Cached card: $str');
                  }
                });
              },
            ),
          ],
        ),
        BrazeAppCard(
          title: 'Streams',
          children: [
            StatusRow(label: 'CC Stream', value: _ccStreamStatus),
            const SizedBox(height: 8),
            BrazeAppButton(
              title: 'Subscribe to Content Cards Stream',
              onPressed: () {
                if (!validateBrazeSdkEnabled(context)) return;
                setState(() => _ccStreamStatus = 'Enabled');
                _contentCardsSubscription =
                    braze.subscribeToContentCards(_contentCardsReceived);
                context.showBrazeAppSnackbar('Listening to content cards stream.');
              },
            ),
          ],
        ),
        const BrazeAppInfoBox(
          text:
              'Content Cards will be logged to the console. Subscribe to the stream to receive updates in snackbars.',
        ),
      ],
    );
  }
}
