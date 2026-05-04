// Widget tests for NotationCard.
//
// Covers:
//   - Title is rendered
//   - Artists are rendered when non-empty; hidden when empty
//   - dateWritten is rendered when non-null; hidden when null
//   - Tag chips are rendered (up to 3)
//   - More than 3 tags: only first 3 shown
//   - Placeholder shown when thumbnailPath is null
//   - onTap callback is called when card is tapped
//   - No onTap: card renders without error

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/library/widgets/notation_card.dart';
import 'package:swaralipi/shared/models/notation.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation({
  String id = '1',
  String title = 'Test Notation',
  List<String> artists = const [],
  String? dateWritten,
}) =>
    Notation(
      id: id,
      title: title,
      artists: artists,
      languages: const [],
      notes: '',
      playCount: 0,
      dateWritten: dateWritten,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotationCard — title', () {
    testWidgets('renders the notation title', (tester) async {
      await tester.pumpWidget(
        _wrap(NotationCard(notation: _makeNotation(title: 'Bhairavi'))),
      );
      expect(find.text('Bhairavi'), findsOneWidget);
    });
  });

  group('NotationCard — artists', () {
    testWidgets('renders artists when list is non-empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          NotationCard(
            notation: _makeNotation(artists: ['Ravi Shankar', 'Ali Khan']),
          ),
        ),
      );
      expect(find.text('Ravi Shankar, Ali Khan'), findsOneWidget);
    });

    testWidgets('does not render artist row when list is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrap(NotationCard(notation: _makeNotation(artists: const []))),
      );
      // Should only find the title text; no comma-separated artist string.
      expect(find.textContaining(','), findsNothing);
    });
  });

  group('NotationCard — dateWritten', () {
    testWidgets('renders dateWritten when non-null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          NotationCard(
            notation: _makeNotation(dateWritten: '2023-11-01'),
          ),
        ),
      );
      expect(find.text('2023-11-01'), findsOneWidget);
    });

    testWidgets('does not render date when null', (tester) async {
      await tester.pumpWidget(
        _wrap(NotationCard(notation: _makeNotation())),
      );
      expect(find.textContaining(RegExp(r'\d{4}-\d{2}-\d{2}')), findsNothing);
    });
  });

  group('NotationCard — tag chips', () {
    testWidgets('renders tag chip labels', (tester) async {
      await tester.pumpWidget(
        _wrap(
          NotationCard(
            notation: _makeNotation(),
            tags: const [
              NotationTagChip(label: 'bhajan'),
              NotationTagChip(label: 'folk'),
            ],
          ),
        ),
      );
      expect(find.text('bhajan'), findsOneWidget);
      expect(find.text('folk'), findsOneWidget);
    });

    testWidgets('shows at most 3 tag chips', (tester) async {
      await tester.pumpWidget(
        _wrap(
          NotationCard(
            notation: _makeNotation(),
            tags: const [
              NotationTagChip(label: 'a'),
              NotationTagChip(label: 'b'),
              NotationTagChip(label: 'c'),
              NotationTagChip(label: 'd'),
              NotationTagChip(label: 'e'),
            ],
          ),
        ),
      );
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
      expect(find.text('d'), findsNothing);
      expect(find.text('e'), findsNothing);
    });

    testWidgets('renders no chips when tags list is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(NotationCard(notation: _makeNotation(), tags: const [])),
      );
      // The row should not appear; we just check nothing crashes.
      expect(tester.takeException(), isNull);
    });
  });

  group('NotationCard — thumbnail placeholder', () {
    testWidgets('shows placeholder when thumbnailPath is null', (tester) async {
      await tester.pumpWidget(
        _wrap(NotationCard(notation: _makeNotation())),
      );
      expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
    });
  });

  group('NotationCard — tap', () {
    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          NotationCard(
            notation: _makeNotation(title: 'Tapable'),
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(NotationCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders without error when onTap is null', (tester) async {
      await tester.pumpWidget(
        _wrap(NotationCard(notation: _makeNotation())),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
