// Tests for the InstrumentInstance domain model.
//
// Covers: immutability, copyWith, equality, hashCode, JSON round-trip,
// nullable field handling.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';

void main() {
  const defaultId = 'instance-uuid-1';
  const defaultClassId = 'class-uuid-1';
  const defaultColorHex = '#cba6f7';
  const defaultCreatedAt = '2024-01-15T10:00:00.000Z';
  const defaultUpdatedAt = '2024-01-16T10:00:00.000Z';

  InstrumentInstance makeInstance({
    String id = defaultId,
    String classId = defaultClassId,
    String? brand,
    String? model,
    String colorHex = defaultColorHex,
    int? priceInr,
    String? photoPath,
    String notes = '',
    String createdAt = defaultCreatedAt,
    String updatedAt = defaultUpdatedAt,
    String? deletedAt,
  }) =>
      InstrumentInstance(
        id: id,
        classId: classId,
        brand: brand,
        model: model,
        colorHex: colorHex,
        priceInr: priceInr,
        photoPath: photoPath,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );

  group('InstrumentInstance', () {
    group('construction', () {
      test('creates instance with required fields', () {
        final inst = makeInstance();

        expect(inst.id, defaultId);
        expect(inst.classId, defaultClassId);
        expect(inst.colorHex, defaultColorHex);
        expect(inst.notes, '');
        expect(inst.createdAt, defaultCreatedAt);
        expect(inst.updatedAt, defaultUpdatedAt);
      });

      test('nullable fields default to null', () {
        final inst = makeInstance();

        expect(inst.brand, isNull);
        expect(inst.model, isNull);
        expect(inst.priceInr, isNull);
        expect(inst.photoPath, isNull);
        expect(inst.deletedAt, isNull);
      });

      test('stores optional fields when provided', () {
        final inst = makeInstance(
          brand: 'Yamaha',
          model: 'C40',
          priceInr: 15000,
          photoPath: 'instruments/photo.jpg',
          deletedAt: '2024-06-01T00:00:00.000Z',
        );

        expect(inst.brand, 'Yamaha');
        expect(inst.model, 'C40');
        expect(inst.priceInr, 15000);
        expect(inst.photoPath, 'instruments/photo.jpg');
        expect(inst.deletedAt, '2024-06-01T00:00:00.000Z');
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        expect(makeInstance().copyWith(), equals(makeInstance()));
      });

      test('copies and overrides brand', () {
        final original = makeInstance();
        final copy = original.copyWith(brand: 'Fender');

        expect(copy.brand, 'Fender');
        expect(original.brand, isNull);
      });

      test('copies and overrides notes', () {
        final original = makeInstance();
        final copy = original.copyWith(notes: 'My favorite guitar');

        expect(copy.notes, 'My favorite guitar');
        expect(original.notes, '');
      });

      test('copies and sets deletedAt for archival', () {
        final original = makeInstance();
        const archiveTime = '2024-06-01T00:00:00.000Z';
        final copy = original.copyWith(deletedAt: archiveTime);

        expect(copy.deletedAt, archiveTime);
        expect(original.deletedAt, isNull);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        expect(makeInstance(), equals(makeInstance()));
      });

      test('different ids are not equal', () {
        expect(
          makeInstance(id: 'inst-1'),
          isNot(equals(makeInstance(id: 'inst-2'))),
        );
      });

      test('different nullable fields produce inequality', () {
        expect(
          makeInstance(brand: 'Yamaha'),
          isNot(equals(makeInstance())),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        expect(makeInstance().hashCode, equals(makeInstance().hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys', () {
        final json = makeInstance().toJson();

        expect(json['id'], defaultId);
        expect(json['class_id'], defaultClassId);
        expect(json['color_hex'], defaultColorHex);
        expect(json['notes'], '');
        expect(json['brand'], isNull);
        expect(json['deleted_at'], isNull);
      });

      test('fromJson round-trips correctly', () {
        final original = makeInstance(
          brand: 'Yamaha',
          model: 'C40',
          priceInr: 15000,
        );
        expect(
          InstrumentInstance.fromJson(original.toJson()),
          equals(original),
        );
      });

      test('fromJson handles all null nullable fields', () {
        final original = makeInstance();
        final restored = InstrumentInstance.fromJson(original.toJson());

        expect(restored.brand, isNull);
        expect(restored.model, isNull);
        expect(restored.priceInr, isNull);
        expect(restored.photoPath, isNull);
        expect(restored.deletedAt, isNull);
      });
    });
  });
}
