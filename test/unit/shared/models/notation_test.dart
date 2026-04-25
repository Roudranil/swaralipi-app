// Tests for the Notation domain model.
//
// Covers: immutability, copyWith, equality, hashCode, JSON round-trip,
// and edge cases for nullable fields and list fields.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/notation.dart';

void main() {
  const defaultId = 'notation-uuid-1';
  const defaultTitle = 'Yaman Kalyan';
  const defaultArtists = ['Ravi Shankar'];
  const defaultLanguages = ['Hindi'];
  const defaultCreatedAt = '2024-01-15T10:00:00.000Z';
  const defaultUpdatedAt = '2024-01-16T10:00:00.000Z';

  Notation makeNotation({
    String id = defaultId,
    String title = defaultTitle,
    List<String> artists = defaultArtists,
    String? dateWritten,
    String? timeSig,
    String? keySig,
    List<String> languages = defaultLanguages,
    String notes = '',
    int playCount = 0,
    String? lastPlayedAt,
    String createdAt = defaultCreatedAt,
    String updatedAt = defaultUpdatedAt,
    String? deletedAt,
  }) =>
      Notation(
        id: id,
        title: title,
        artists: artists,
        dateWritten: dateWritten,
        timeSig: timeSig,
        keySig: keySig,
        languages: languages,
        notes: notes,
        playCount: playCount,
        lastPlayedAt: lastPlayedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  group('Notation', () {
    group('construction', () {
      test('creates instance with required fields', () {
        final n = makeNotation();

        expect(n.id, defaultId);
        expect(n.title, defaultTitle);
        expect(n.artists, defaultArtists);
        expect(n.languages, defaultLanguages);
        expect(n.notes, '');
        expect(n.playCount, 0);
        expect(n.createdAt, defaultCreatedAt);
        expect(n.updatedAt, defaultUpdatedAt);
      });

      test('nullable fields default to null', () {
        final n = makeNotation();

        expect(n.dateWritten, isNull);
        expect(n.timeSig, isNull);
        expect(n.keySig, isNull);
        expect(n.lastPlayedAt, isNull);
        expect(n.deletedAt, isNull);
      });

      test('stores optional fields when provided', () {
        final n = makeNotation(
          dateWritten: '2024-01-10',
          timeSig: '4/4',
          keySig: 'C',
          lastPlayedAt: '2024-01-16T10:00:00.000Z',
          deletedAt: '2024-01-17T10:00:00.000Z',
        );

        expect(n.dateWritten, '2024-01-10');
        expect(n.timeSig, '4/4');
        expect(n.keySig, 'C');
        expect(n.lastPlayedAt, '2024-01-16T10:00:00.000Z');
        expect(n.deletedAt, '2024-01-17T10:00:00.000Z');
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        final n = makeNotation();
        expect(n.copyWith(), equals(n));
      });

      test('copies and overrides title', () {
        final original = makeNotation();
        final copy = original.copyWith(title: 'Bhairavi');

        expect(copy.title, 'Bhairavi');
        expect(copy.id, original.id);
        expect(copy.artists, original.artists);
        expect(copy.createdAt, original.createdAt);
      });

      test('copies and overrides playCount', () {
        final original = makeNotation();
        final copy = original.copyWith(playCount: 5);

        expect(copy.playCount, 5);
        expect(copy.id, original.id);
      });

      test('copies and sets nullable field to non-null', () {
        final original = makeNotation();
        final copy = original.copyWith(timeSig: '3/4');

        expect(copy.timeSig, '3/4');
      });

      test('does not mutate original', () {
        final original = makeNotation();
        original.copyWith(title: 'Changed');

        expect(original.title, defaultTitle);
      });

      test('copies and overrides artists list', () {
        final original = makeNotation();
        final copy = original.copyWith(
          artists: ['Zakir Hussain', 'Hariprasad'],
        );

        expect(copy.artists, ['Zakir Hussain', 'Hariprasad']);
        expect(original.artists, defaultArtists);
      });
    });

    group('equality', () {
      test('two instances with same fields are equal', () {
        final a = makeNotation();
        final b = makeNotation();

        expect(a, equals(b));
      });

      test('instances with different ids are not equal', () {
        final a = makeNotation(id: 'id-1');
        final b = makeNotation(id: 'id-2');

        expect(a, isNot(equals(b)));
      });

      test('instances with different titles are not equal', () {
        final a = makeNotation(title: 'Yaman');
        final b = makeNotation(title: 'Bhairavi');

        expect(a, isNot(equals(b)));
      });

      test('instances with different nullable fields are not equal', () {
        final a = makeNotation(timeSig: '4/4');
        final b = makeNotation();

        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal instances have equal hashCodes', () {
        final a = makeNotation();
        final b = makeNotation();

        expect(a.hashCode, equals(b.hashCode));
      });

      test('different instances typically have different hashCodes', () {
        final a = makeNotation(id: 'id-1');
        final b = makeNotation(id: 'id-2');

        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys', () {
        final n = makeNotation();
        final json = n.toJson();

        expect(json['id'], defaultId);
        expect(json['title'], defaultTitle);
        expect(json['play_count'], 0);
        expect(json['created_at'], defaultCreatedAt);
        expect(json['updated_at'], defaultUpdatedAt);
        expect(json['deleted_at'], isNull);
      });

      test('fromJson round-trips correctly', () {
        final original = makeNotation(
          timeSig: '6/8',
          dateWritten: '2024-01-01',
          playCount: 3,
        );
        final restored = Notation.fromJson(original.toJson());

        expect(restored, equals(original));
      });

      test('fromJson handles null nullable fields', () {
        final n = makeNotation();
        final restored = Notation.fromJson(n.toJson());

        expect(restored.timeSig, isNull);
        expect(restored.dateWritten, isNull);
        expect(restored.deletedAt, isNull);
      });

      test('toJson serializes artists as a list', () {
        final n = makeNotation(
          artists: ['Ravi Shankar', 'Zakir Hussain'],
        );
        final json = n.toJson();

        expect(json['artists'], isA<List>());
        expect(json['artists'], ['Ravi Shankar', 'Zakir Hussain']);
      });
    });
  });
}
