import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  const ContentCard({
    super.key,
    required this.contentCard,
    this.cardPressedUrl,
  });

  final BrazeContentCard contentCard;
  final ValueChanged<String>? cardPressedUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: contentCard.url.isNotEmpty && cardPressedUrl != null
            ? () => cardPressedUrl!(contentCard.url)
            : null,
        child: Stack(
          children: [
            Builder(
              builder: (context) {
                switch (contentCard.type) {
                  case ContentCardType.bannerImage:
                    return BannerImage(
                      contentCard: contentCard,
                    );
                  case ContentCardType.shortNews:
                    return ShortNews(
                      contentCard: contentCard,
                    );
                  case ContentCardType.captionedImage:
                    return CaptionedImage(
                      contentCard: contentCard,
                    );
                }
              },
            ),
            Visibility(
              visible: contentCard.pinned,
              child: const Align(
                alignment: Alignment.topRight,
                child: StarTriangleBackground(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class StarTriangleBackground extends StatelessWidget {
  const StarTriangleBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 27,
      width: 27,
      padding: const EdgeInsets.all(1),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          stops: [.5, .5],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue,
            Colors.transparent, // top Right part
          ],
        ),
      ),
      child: const Align(
        alignment: Alignment.topRight,
        child: Icon(
          Icons.star,
          color: Colors.white,
          size: 13,
        ),
      ),
    );
  }
}

@visibleForTesting
class CaptionedImage extends StatelessWidget {
  const CaptionedImage({
    super.key,
    required this.contentCard,
  });

  final BrazeContentCard contentCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.network(
          contentCard.image,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        const SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            contentCard.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            contentCard.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(
          height: 16,
        ),
      ],
    );
  }
}

@visibleForTesting
class ShortNews extends StatelessWidget {
  const ShortNews({
    super.key,
    required this.contentCard,
  });

  final BrazeContentCard contentCard;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: contentCard.image.isNotEmpty
          ? Image.network(
              contentCard.image,
              width: 60,
            )
          : null,
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        contentCard.title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      subtitle: Text(
        contentCard.description,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

@visibleForTesting
class BannerImage extends StatelessWidget {
  const BannerImage({
    super.key,
    required this.contentCard,
  });

  final BrazeContentCard contentCard;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.network(
        contentCard.image,
      ),
    );
  }
}
