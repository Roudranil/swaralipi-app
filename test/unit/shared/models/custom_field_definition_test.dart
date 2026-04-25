// Tests for the CustomFieldDefinition domain model.
//
// Covers: immutability, copyWith, equality, hashCode, JSON round-trip,
// and the CustomFieldType enum.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';

void main() {
  const defaultId = 'cfd-uuid-1';
  const defaultKeyName = 'raga_name';
  const defaultCreatedAt = '2024-01-15T10:00:00.000Z';
  const defaultUpdatedAt = '2024-01-16T10:00:00.000Z';

  CustomFieldDefinition makeDefinition({
    String id = defaultId,
    String keyName = defaultKeyName,
    CustomFieldType fieldType = CustomFieldType.text,
    String createdAt = defaultCreatedAt,
    String updatedAt = defaultUpdatedAt,
  }) =>
      CustomFieldDefinition(
        id: id,
        keyName: keyName,
        fieldType: fieldType,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  group('CustomFieldType', () {
    test('has all four valid variants', () {
      expect(CustomFieldType.values, hasLength(4));
      expect(
        CustomFieldType.values,
        containsAll([
          CustomFieldType.text,
          CustomFieldType.number,
          CustomFieldType.date,
          CustomFieldType.boolean,
        ]),
      );
    });
  });

  group('CustomFieldDefinition', () {
    group('construction', () {
      test('creates instance with text field type', () {
        final d = makeDefinition();

        expect(d.id, defaultId);
        expect(d.keyName, defaultKeyName);
        expect(d.fieldType, CustomFieldType.text);
        expect(d.createdAt, defaultCreatedAt);
        expect(d.updatedAt, defaultUpdatedAt);
      });

      test('creates instance with number field type', () {
        final d = makeDefinition(fieldType: CustomFieldType.number);
        expect(d.fieldType, CustomFieldType.number);
      });

      test('creates instance with date field type', () {
        final d = makeDefinition(fieldType: CustomFieldType.date);
        expect(d.fieldType, CustomFieldType.date);
      });

      test('creates instance with boolean field type', () {
        final d = makeDefinition(fieldType: CustomFieldType.boolean);
        expect(d.fieldType, CustomFieldType.boolean);
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        expect(makeDefinition().copyWith(), equals(makeDefinition()));
      });

      test('copies and overrides keyName', () {
        final original = makeDefinition();
        final copy = original.copyWith(keyName: 'tala');

        expect(copy.keyName, 'tala');
        expect(original.keyName, defaultKeyName);
      });

      test('copies and overrides fieldType', () {
        final original = makeDefinition();
        final copy = original.copyWith(fieldType: CustomFieldType.boolean);

        expect(copy.fieldType, CustomFieldType.boolean);
        expect(original.fieldType, CustomFieldType.text);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        expect(makeDefinition(), equals(makeDefinition()));
      });

      test('different fieldType produces inequality', () {
        expect(
          makeDefinition(fieldType: CustomFieldType.text),
          isNot(equals(makeDefinition(fieldType: CustomFieldType.number))),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        expect(makeDefinition().hashCode, equals(makeDefinition().hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys', () {
        final json = makeDefinition().toJson();

        expect(json['id'], defaultId);
        expect(json['key_name'], defaultKeyName);
        expect(json['field_type'], 'text');
        expect(json['created_at'], defaultCreatedAt);
        expect(json['updated_at'], defaultUpdatedAt);
      });

      test('toJson serializes all field types correctly', () {
        expect(
          makeDefinition(fieldType: CustomFieldType.text)
              .toJson()['field_type'],
          'text',
        );
        expect(
          makeDefinition(fieldType: CustomFieldType.number)
              .toJson()['field_type'],
          'number',
        );
        expect(
          makeDefinition(fieldType: CustomFieldType.date)
              .toJson()['field_type'],
          'date',
        );
        expect(
          makeDefinition(fieldType: CustomFieldType.boolean)
              .toJson()['field_type'],
          'boolean',
        );
      });

      test('fromJson round-trips for all field types', () {
        for (final type in CustomFieldType.values) {
          final original = makeDefinition(fieldType: type);
          expect(
            CustomFieldDefinition.fromJson(original.toJson()),
            equals(original),
          );
        }
      });
    });
  });
}
