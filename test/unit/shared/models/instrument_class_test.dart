// Tests for the InstrumentClass domain model.
//
// Covers: immutability, copyWith, equality, hashCode, JSON round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';

void main() {
  const defaultId = 'class-uuid-1';
  const defaultName = 'String';
  const defaultCreatedAt = '2024-01-15T10:00:00.000Z';
  const defaultUpdatedAt = '2024-01-16T10:00:00.000Z';

  InstrumentClass makeClass({
    String id = defaultId,
    String name = defaultName,
    String createdAt = defaultCreatedAt,
    String updatedAt = defaultUpdatedAt,
  }) =>
      InstrumentClass(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  group('InstrumentClass', () {
    group('construction', () {
      test('creates instance with all fields', () {
        final c = makeClass();

        expect(c.id, defaultId);
        expect(c.name, defaultName);
        expect(c.createdAt, defaultCreatedAt);
        expect(c.updatedAt, defaultUpdatedAt);
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        expect(makeClass().copyWith(), equals(makeClass()));
      });

      test('copies and overrides name', () {
        final original = makeClass();
        final copy = original.copyWith(name: 'Wind');

        expect(copy.name, 'Wind');
        expect(copy.id, original.id);
        expect(original.name, defaultName);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        expect(makeClass(), equals(makeClass()));
      });

      test('different ids are not equal', () {
        expect(
          makeClass(id: 'class-1'),
          isNot(equals(makeClass(id: 'class-2'))),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        expect(makeClass().hashCode, equals(makeClass().hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys', () {
        final json = makeClass().toJson();

        expect(json['id'], defaultId);
        expect(json['name'], defaultName);
        expect(json['created_at'], defaultCreatedAt);
        expect(json['updated_at'], defaultUpdatedAt);
      });

      test('fromJson round-trips correctly', () {
        final original = makeClass();
        expect(InstrumentClass.fromJson(original.toJson()), equals(original));
      });
    });
  });
}
