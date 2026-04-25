// Tests for the Tag domain model.
//
// Covers: immutability, copyWith, equality, hashCode, JSON round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/tag.dart';

void main() {
  const defaultId = 'tag-uuid-1';
  const defaultName = 'Raag';
  const defaultColorHex = '#f38ba8';
  const defaultCreatedAt = '2024-01-15T10:00:00.000Z';
  const defaultUpdatedAt = '2024-01-16T10:00:00.000Z';

  Tag makeTag({
    String id = defaultId,
    String name = defaultName,
    String colorHex = defaultColorHex,
    String createdAt = defaultCreatedAt,
    String updatedAt = defaultUpdatedAt,
  }) =>
      Tag(
        id: id,
        name: name,
        colorHex: colorHex,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  group('Tag', () {
    group('construction', () {
      test('creates instance with all fields', () {
        final t = makeTag();

        expect(t.id, defaultId);
        expect(t.name, defaultName);
        expect(t.colorHex, defaultColorHex);
        expect(t.createdAt, defaultCreatedAt);
        expect(t.updatedAt, defaultUpdatedAt);
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        expect(makeTag().copyWith(), equals(makeTag()));
      });

      test('copies and overrides name', () {
        final original = makeTag();
        final copy = original.copyWith(name: 'Bhajan');

        expect(copy.name, 'Bhajan');
        expect(copy.id, original.id);
      });

      test('copies and overrides colorHex', () {
        final original = makeTag();
        final copy = original.copyWith(colorHex: '#a6e3a1');

        expect(copy.colorHex, '#a6e3a1');
        expect(original.colorHex, defaultColorHex);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        expect(makeTag(), equals(makeTag()));
      });

      test('different name produces inequality', () {
        expect(
          makeTag(name: 'Raag'),
          isNot(equals(makeTag(name: 'Bhajan'))),
        );
      });

      test('different colorHex produces inequality', () {
        expect(
          makeTag(colorHex: '#f38ba8'),
          isNot(equals(makeTag(colorHex: '#a6e3a1'))),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        expect(makeTag().hashCode, equals(makeTag().hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys', () {
        final json = makeTag().toJson();

        expect(json['id'], defaultId);
        expect(json['name'], defaultName);
        expect(json['color_hex'], defaultColorHex);
        expect(json['created_at'], defaultCreatedAt);
        expect(json['updated_at'], defaultUpdatedAt);
      });

      test('fromJson round-trips correctly', () {
        final original = makeTag();
        expect(Tag.fromJson(original.toJson()), equals(original));
      });
    });
  });
}
