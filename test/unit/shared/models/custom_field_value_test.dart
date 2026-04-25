// Tests for the CustomFieldValue domain model.
//
// Covers: sparse column handling (only the relevant value field is set),
// copyWith, equality, hashCode, and JSON round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';

void main() {
  const defaultNotationId = 'notation-uuid-1';
  const defaultDefinitionId = 'cfd-uuid-1';

  CustomFieldValue makeValue({
    String notationId = defaultNotationId,
    String definitionId = defaultDefinitionId,
    String? valueText,
    double? valueNumber,
    String? valueDate,
    bool? valueBoolean,
  }) =>
      CustomFieldValue(
        notationId: notationId,
        definitionId: definitionId,
        valueText: valueText,
        valueNumber: valueNumber,
        valueDate: valueDate,
        valueBoolean: valueBoolean,
      );

  group('CustomFieldValue', () {
    group('construction', () {
      test('creates text value', () {
        final v = makeValue(valueText: 'Yaman');

        expect(v.notationId, defaultNotationId);
        expect(v.definitionId, defaultDefinitionId);
        expect(v.valueText, 'Yaman');
        expect(v.valueNumber, isNull);
        expect(v.valueDate, isNull);
        expect(v.valueBoolean, isNull);
      });

      test('creates number value', () {
        final v = makeValue(valueNumber: 3.14);

        expect(v.valueNumber, 3.14);
        expect(v.valueText, isNull);
        expect(v.valueDate, isNull);
        expect(v.valueBoolean, isNull);
      });

      test('creates date value', () {
        final v = makeValue(valueDate: '2024-01-15');

        expect(v.valueDate, '2024-01-15');
        expect(v.valueText, isNull);
        expect(v.valueNumber, isNull);
        expect(v.valueBoolean, isNull);
      });

      test('creates boolean value', () {
        final vTrue = makeValue(valueBoolean: true);
        final vFalse = makeValue(valueBoolean: false);

        expect(vTrue.valueBoolean, isTrue);
        expect(vFalse.valueBoolean, isFalse);
        expect(vTrue.valueText, isNull);
      });

      test('all value columns can be null (unset)', () {
        final v = makeValue();

        expect(v.valueText, isNull);
        expect(v.valueNumber, isNull);
        expect(v.valueDate, isNull);
        expect(v.valueBoolean, isNull);
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        final v = makeValue(valueText: 'Test');
        expect(v.copyWith(), equals(v));
      });

      test('copies and overrides valueText', () {
        final original = makeValue(valueText: 'Original');
        final copy = original.copyWith(valueText: 'Updated');

        expect(copy.valueText, 'Updated');
        expect(original.valueText, 'Original');
      });

      test('copies and overrides valueNumber', () {
        final original = makeValue(valueNumber: 1.0);
        final copy = original.copyWith(valueNumber: 2.5);

        expect(copy.valueNumber, 2.5);
        expect(original.valueNumber, 1.0);
      });

      test('copies and overrides valueBoolean', () {
        final original = makeValue(valueBoolean: false);
        final copy = original.copyWith(valueBoolean: true);

        expect(copy.valueBoolean, isTrue);
        expect(original.valueBoolean, isFalse);
      });
    });

    group('equality', () {
      test('equal text values are equal', () {
        expect(
          makeValue(valueText: 'Yaman'),
          equals(makeValue(valueText: 'Yaman')),
        );
      });

      test('different text values are not equal', () {
        expect(
          makeValue(valueText: 'Yaman'),
          isNot(equals(makeValue(valueText: 'Bhairavi'))),
        );
      });

      test('different notationIds produce inequality', () {
        expect(
          makeValue(notationId: 'n-1'),
          isNot(equals(makeValue(notationId: 'n-2'))),
        );
      });

      test('true and false boolean values are not equal', () {
        expect(
          makeValue(valueBoolean: true),
          isNot(equals(makeValue(valueBoolean: false))),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        final a = makeValue(valueText: 'Yaman');
        final b = makeValue(valueText: 'Yaman');
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson for text value', () {
        final json = makeValue(valueText: 'Yaman').toJson();

        expect(json['notation_id'], defaultNotationId);
        expect(json['definition_id'], defaultDefinitionId);
        expect(json['value_text'], 'Yaman');
        expect(json['value_number'], isNull);
        expect(json['value_date'], isNull);
        expect(json['value_boolean'], isNull);
      });

      test('toJson for boolean value', () {
        final json = makeValue(valueBoolean: true).toJson();
        expect(json['value_boolean'], true);
        expect(json['value_text'], isNull);
      });

      test('fromJson round-trips text value', () {
        final original = makeValue(valueText: 'Yaman');
        expect(CustomFieldValue.fromJson(original.toJson()), equals(original));
      });

      test('fromJson round-trips number value', () {
        final original = makeValue(valueNumber: 42.0);
        expect(CustomFieldValue.fromJson(original.toJson()), equals(original));
      });

      test('fromJson round-trips boolean value', () {
        final original = makeValue(valueBoolean: true);
        expect(CustomFieldValue.fromJson(original.toJson()), equals(original));
      });

      test('fromJson round-trips date value', () {
        final original = makeValue(valueDate: '2024-03-21');
        expect(CustomFieldValue.fromJson(original.toJson()), equals(original));
      });

      test('fromJson round-trips null value', () {
        final original = makeValue();
        expect(CustomFieldValue.fromJson(original.toJson()), equals(original));
      });
    });
  });
}
