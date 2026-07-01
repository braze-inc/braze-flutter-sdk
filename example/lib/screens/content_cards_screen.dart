import 'dart:async';

import 'package:braze_plugin/braze_plugin.dart';
import 'package:braze_plugin_example/components.dart';
import 'package:braze_plugin_example/log_console.dart';
import 'package:braze_plugin_example/screens/home_screen.dart';
import 'package:braze_plugin_example/sdk_helpers.dart';
import 'package:braze_plugin_example/theme.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Change to `true` to automatically log clicks and dismissals for all
// content cards as soon as they appear in the feed.
const bool _automaticallyInteract = false;

// 50% visible logs a single impression per card, matching the native feed.
const double _impressionVisibleFraction = 0.5;

/// Entry screen for Content Cards. Shows the Default UI and Custom UI options.
class ContentCardsScreen extends StatefulWidget {
  const ContentCardsScreen({super.key});

  @override
  State<ContentCardsScreen> createState() => _ContentCardsScreenState();
}

class _ContentCardsScreenState extends State<ContentCardsScreen> {
  bool _isLoading = false;

  void _handleRefresh() {
    if (!validateBrazeSdkEnabled(context)) return;
    setState(() => _isLoading = true);
    braze.requestContentCardsRefresh();
    context.showBrazeAppSnackbar('Refreshing Content Cards...');
    // Clear loading indicator after a short delay since we have no subscription
    // on this screen.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Cards'),
        actions: const [LogConsoleToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Content Cards',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: BrazeAppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Launch the native UI or explore the custom feed.',
            style: TextStyle(fontSize: 16, color: BrazeAppColors.textGray),
          ),
          const SizedBox(height: 16),
          BrazeAppCard(
            title: 'Default UI',
            children: [
              BrazeAppButton(
                title: 'Launch Content Cards',
                onPressed: () {
                  if (!validateBrazeSdkEnabled(context)) return;
                  braze.launchContentCards();
                },
              ),
              BrazeAppButton(
                title: 'Request Refresh',
                variant: BrazeButtonVariant.secondary,
                onPressed: _handleRefresh,
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BrazeAppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          BrazeAppCard(
            title: 'Custom UI',
            children: [
              BrazeAppButton(
                title: 'View Custom Feed',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const _CustomContentCardsFeedScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen custom Content Cards feed backed by
/// [BrazePlugin.getCachedContentCards] and the content cards stream.
class _CustomContentCardsFeedScreen extends StatefulWidget {
  const _CustomContentCardsFeedScreen();

  @override
  State<_CustomContentCardsFeedScreen> createState() =>
      _CustomContentCardsFeedScreenState();
}

class _CustomContentCardsFeedScreenState
    extends State<_CustomContentCardsFeedScreen> with WidgetsBindingObserver {
  List<BrazeContentCard> _cards = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;

  final Set<String> _impressedCardIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = braze.subscribeToContentCards(_updateCards);
    if (brazeSdkEnabled) {
      braze.getCachedContentCards().then(_updateCards);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && brazeSdkEnabled) {
      braze.requestContentCardsRefresh();
    }
  }

  void _updateCards(List<BrazeContentCard> incoming) {
    if (!mounted) return;
    final visible = incoming
        .where((c) => !c.isControl && !c.removed && c.type.isNotEmpty)
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.created - a.created;
      });
    setState(() {
      _cards = visible;
      _isLoading = false;
    });
  }

  void _handleRefresh() {
    if (!validateBrazeSdkEnabled(context)) return;
    setState(() => _isLoading = true);
    braze.requestContentCardsRefresh();
    context.showBrazeAppSnackbar('Refreshing Content Cards...');
  }

  void _handlePress(BrazeContentCard card) {
    braze.logContentCardClicked(card);
    print('Content card clicked: ${card.id}');
    context.showBrazeAppSnackbar(
      card.url.isEmpty ? 'Card clicked' : 'Card clicked: ${card.url}',
    );
  }

  void _handleDismiss(BrazeContentCard card) {
    braze.logContentCardDismissed(card);
    print('Content card dismissed: ${card.id}');
    setState(() => _cards = _cards.where((c) => c.id != card.id).toList());
    context.showBrazeAppSnackbar('Card dismissed');
  }

  void _logImpression(BrazeContentCard card) {
    if (_impressedCardIds.contains(card.id)) return;
    _impressedCardIds.add(card.id);
    braze.logContentCardImpression(card);
    print('Content card impression logged: ${card.id}');
    if (_automaticallyInteract) {
      braze.logContentCardClicked(card);
      braze.logContentCardDismissed(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: 'Request Refresh',
          ),
          const LogConsoleToggleButton(),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: BrazeAppColors.primary),
            )
          : _cards.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return _ContentCardItem(
                      key: ValueKey('cc-${card.id}'),
                      card: card,
                      onPressed: () => _handlePress(card),
                      onDismiss: () => _handleDismiss(card),
                      onImpression: () => _logImpression(card),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No Content Cards',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BrazeAppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the refresh icon to load cards from Braze.',
            style: TextStyle(fontSize: 14, color: BrazeAppColors.textGray),
          ),
        ],
      ),
    );
  }
}

/// Single Content Card row. Renders by [BrazeContentCard.type] and reports
/// impressions once it becomes [_impressionVisibleFraction] visible.
class _ContentCardItem extends StatelessWidget {
  const _ContentCardItem({
    super.key,
    required this.card,
    required this.onPressed,
    required this.onDismiss,
    required this.onImpression,
  });

  final BrazeContentCard card;
  final VoidCallback onPressed;
  final VoidCallback onDismiss;
  final VoidCallback onImpression;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('cc-visibility-${card.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= _impressionVisibleFraction) onImpression();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: BrazeAppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          border: card.viewed
              ? null
              : const Border(
                  left: BorderSide(color: BrazeAppColors.primary, width: 4),
                ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: onPressed, child: _buildContent()),
            ),
            if (card.pinned)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: BrazeAppColors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PINNED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (card.dismissable)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x66000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '\u2715',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (card.type) {
      case 'image_only':
        return _fullWidthImage();
      case 'captioned_image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _fullWidthImage(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _textContent(),
            ),
          ],
        );
      default:
        // Classic / short_news: optional thumbnail beside the text.
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.image.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    card.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: _textContent()),
            ],
          ),
        );
    }
  }

  Widget _fullWidthImage() {
    if (card.image.isEmpty) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio:
          card.imageAspectRatio > 0 ? card.imageAspectRatio.toDouble() : 16 / 9,
      child: Image.network(
        card.image,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _textContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (card.title.isNotEmpty)
          Text(
            card.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrazeAppColors.textDark,
            ),
          ),
        if (card.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            card.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: BrazeAppColors.textMedium,
            ),
          ),
        ],
        if (card.linkText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            card.linkText,
            style: const TextStyle(
              fontSize: 12,
              color: BrazeAppColors.textGray,
            ),
          ),
        ],
      ],
    );
  }
}
