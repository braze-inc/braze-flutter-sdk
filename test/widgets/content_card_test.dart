import 'package:braze_plugin/braze_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

class MockBrazeContentCard extends Mock implements BrazeContentCard {}

void main() {
  group('ContentCard', () {
    late MockBrazeContentCard mockBrazeContentCard;
    late Widget widget;

    setUp(() {
      mockBrazeContentCard = MockBrazeContentCard();
      widget = MaterialApp(
        home: ListView(
          children: [
            ContentCard(
              contentCard: mockBrazeContentCard,
            ),
          ],
        ),
      );

      when(() => mockBrazeContentCard.image).thenReturn('');
      when(() => mockBrazeContentCard.url).thenReturn('');
    });

    group('StarTriangleBackground', () {
      setUp(() {
        when(() => mockBrazeContentCard.title).thenReturn('Title');
        when(() => mockBrazeContentCard.description).thenReturn('Description');
      });

      testWidgets('displays StarTriangleBackground when pinned is active',
          (WidgetTester tester) async {
        when(() => mockBrazeContentCard.pinned).thenReturn(true);
        when(() => mockBrazeContentCard.type)
            .thenReturn(ContentCardType.shortNews);
        await tester.pumpWidget(widget);

        expect(find.byType(StarTriangleBackground), findsOneWidget);
      });

      testWidgets('displays StarTriangleBackground when pinned is not active',
          (WidgetTester tester) async {
        when(() => mockBrazeContentCard.pinned).thenReturn(false);
        when(() => mockBrazeContentCard.type)
            .thenReturn(ContentCardType.shortNews);
        await tester.pumpWidget(widget);

        expect(find.byType(StarTriangleBackground), findsNothing);
      });
    });

    group('ShortNews', () {
      setUp(() {
        when(() => mockBrazeContentCard.title).thenReturn('Title');
        when(() => mockBrazeContentCard.description).thenReturn('Description');
        when(() => mockBrazeContentCard.type)
            .thenReturn(ContentCardType.shortNews);
        when(() => mockBrazeContentCard.pinned).thenReturn(false);
      });

      testWidgets('displays ShortNews when ContentCardType is shortNews',
          (WidgetTester tester) async {
        await tester.pumpWidget(widget);

        expect(find.byType(ShortNews), findsOneWidget);
      });

      testWidgets('displays title and description',
          (WidgetTester tester) async {
        when(() => mockBrazeContentCard.image).thenReturn('');
        await tester.pumpWidget(widget);

        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
      });

      testWidgets('does not display Image when image is empty',
          (WidgetTester tester) async {
        when(() => mockBrazeContentCard.image).thenReturn('');
        await tester.pumpWidget(widget);

        expect(find.byType(Image), findsNothing);
      });

      testWidgets('displays Image when image is not empty',
          (WidgetTester tester) async {
        when(() => mockBrazeContentCard.image).thenReturn('image');

        await mockNetworkImages(() async {
          await tester.pumpWidget(widget);
          expect(find.byType(Image), findsOneWidget);
        });
      });
    });

    group('CaptionedImage', () {
      setUp(() {
        when(() => mockBrazeContentCard.title).thenReturn('Title');
        when(() => mockBrazeContentCard.description).thenReturn('Description');
        when(() => mockBrazeContentCard.type)
            .thenReturn(ContentCardType.captionedImage);
        when(() => mockBrazeContentCard.pinned).thenReturn(false);
      });

      testWidgets('displays title, description and image',
          (WidgetTester tester) async {
        when(() => mockBrazeContentCard.image).thenReturn('image');

        await mockNetworkImages(() async {
          await tester.pumpWidget(widget);

          expect(find.text('Title'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);
          expect(find.byType(Image), findsOneWidget);
        });
      });
    });

    group('BannerImage', () {
      testWidgets('displays image', (WidgetTester tester) async {
        when(() => mockBrazeContentCard.image).thenReturn('image');
        when(() => mockBrazeContentCard.type)
            .thenReturn(ContentCardType.bannerImage);
        when(() => mockBrazeContentCard.pinned).thenReturn(false);

        await mockNetworkImages(() async {
          await tester.pumpWidget(widget);

          expect(find.byType(Image), findsOneWidget);
        });
      });
    });

    group('onTappedCard', () {
      late String url;
      late Widget widgetWithOnChanged;

      void onChanged(String cardPressedUrl) {
        url = cardPressedUrl;
      }

      setUp(() {
        url = '';

        widgetWithOnChanged = MaterialApp(
          home: ListView(
            children: [
              ContentCard(
                contentCard: mockBrazeContentCard,
                cardPressedUrl: onChanged,
              ),
            ],
          ),
        );

        when(() => mockBrazeContentCard.title).thenReturn('Title');
        when(() => mockBrazeContentCard.description).thenReturn('Description');
        when(() => mockBrazeContentCard.type)
            .thenReturn(ContentCardType.shortNews);
        when(() => mockBrazeContentCard.pinned).thenReturn(false);
      });

      testWidgets('when url is empty does not call cardPressedUrl on tap',
          (WidgetTester tester) async {
        await tester.pumpWidget(widget);

        await tester.tap(find.byType(ContentCard));

        expect(url, isEmpty);
      });

      testWidgets(
          'when url is empty and onChanged is empty '
          'does not call cardPressedUrl on tap', (WidgetTester tester) async {
        await tester.pumpWidget(widgetWithOnChanged);

        await tester.tap(find.byType(ContentCard));

        expect(url, isEmpty);
      });

      testWidgets(
          'when onChanged is empty '
          'does not call cardPressedUrl on tap', (WidgetTester tester) async {
        when(() => mockBrazeContentCard.url).thenReturn('link');
        await tester.pumpWidget(widget);

        await tester.tap(find.byType(ContentCard));

        expect(url, isEmpty);
      });

      testWidgets(
          'when url is not empty and onChanged is not empty '
          'calls cardPressedUrl on tap', (WidgetTester tester) async {
        when(() => mockBrazeContentCard.url).thenReturn('link');
        await tester.pumpWidget(widgetWithOnChanged);

        await tester.tap(find.byType(ContentCard));

        expect(url, 'link');
      });
    });
  });
}
