// Tests for the RenderParams domain model and NotationFilter enum.
//
// Covers: enum values, construction defaults, identity constant, copyWith,
// equality, hashCode, JSON round-trip (all filter variants and crop/rotation).

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/render_params.dart';

void main() {
  group('NotationFilter', () {
    test('has exactly five values', () {
      expect(NotationFilter.values.length, 5);
    });

    test('values are none, grayscale, blackAndWhite, tintWarm, tintCool', () {
      expect(
        NotationFilter.values,
        containsAllInOrder([
          NotationFilter.none,
          NotationFilter.grayscale,
          NotationFilter.blackAndWhite,
          NotationFilter.tintWarm,
          NotationFilter.tintCool,
        ]),
      );
    });

    group('JSON serialization', () {
      const cases = <NotationFilter, String>{
        NotationFilter.none: 'none',
        NotationFilter.grayscale: 'grayscale',
        NotationFilter.blackAndWhite: 'black_and_white',
        NotationFilter.tintWarm: 'tint_warm',
        NotationFilter.tintCool: 'tint_cool',
      };

      for (final entry in cases.entries) {
        final filter = entry.key;
        final jsonValue = entry.value;

        test('${filter.name} serialises to "$jsonValue"', () {
          final params = RenderParams(filter: filter);
          final json = params.toJson();
          expect(json['filter'], jsonValue);
        });

        test('"$jsonValue" deserialises to ${filter.name}', () {
          final json = <String, dynamic>{
            'filter': jsonValue,
            'rotation_degrees': 0,
            'crop_rect': null,
          };
          expect(RenderParams.fromJson(json).filter, filter);
        });
      }
    });
  });

  group('RenderParams', () {
    group('construction', () {
      test('creates with default filter=none and rotationDegrees=0', () {
        const params = RenderParams();

        expect(params.filter, NotationFilter.none);
        expect(params.rotationDegrees, 0);
        expect(params.cropRect, isNull);
      });

      test('creates with explicit filter', () {
        const params = RenderParams(filter: NotationFilter.grayscale);
        expect(params.filter, NotationFilter.grayscale);
      });

      test('creates with explicit rotationDegrees=90', () {
        const params = RenderParams(rotationDegrees: 90);
        expect(params.rotationDegrees, 90);
      });

      test('creates with explicit rotationDegrees=180', () {
        const params = RenderParams(rotationDegrees: 180);
        expect(params.rotationDegrees, 180);
      });

      test('creates with explicit rotationDegrees=270', () {
        const params = RenderParams(rotationDegrees: 270);
        expect(params.rotationDegrees, 270);
      });

      test('creates with non-null cropRect', () {
        const cropRect = CropRect(
          left: 0.1,
          top: 0.2,
          right: 0.9,
          bottom: 0.8,
        );
        const params = RenderParams(cropRect: cropRect);
        expect(params.cropRect, cropRect);
      });
    });

    group('identity constant', () {
      test('identity has filter=none', () {
        expect(RenderParams.identity.filter, NotationFilter.none);
      });

      test('identity has rotationDegrees=0', () {
        expect(RenderParams.identity.rotationDegrees, 0);
      });

      test('identity has null cropRect', () {
        expect(RenderParams.identity.cropRect, isNull);
      });

      test('identity is const-equal to default constructor', () {
        expect(RenderParams.identity, const RenderParams());
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        const original = RenderParams(
          filter: NotationFilter.tintWarm,
          rotationDegrees: 90,
        );
        expect(original.copyWith(), equals(original));
      });

      test('overrides filter only', () {
        const original = RenderParams(filter: NotationFilter.none);
        final copy = original.copyWith(filter: NotationFilter.blackAndWhite);

        expect(copy.filter, NotationFilter.blackAndWhite);
        expect(copy.rotationDegrees, original.rotationDegrees);
        expect(copy.cropRect, original.cropRect);
      });

      test('overrides rotationDegrees only', () {
        const original = RenderParams(rotationDegrees: 0);
        final copy = original.copyWith(rotationDegrees: 270);

        expect(copy.rotationDegrees, 270);
        expect(copy.filter, original.filter);
        expect(copy.cropRect, original.cropRect);
      });

      test('overrides cropRect only', () {
        const original = RenderParams();
        const newCrop = CropRect(
          left: 0.0,
          top: 0.0,
          right: 0.5,
          bottom: 0.5,
        );
        final copy = original.copyWith(cropRect: newCrop);

        expect(copy.cropRect, newCrop);
        expect(copy.filter, original.filter);
      });

      test('can clear cropRect to null via copyWith', () {
        const withCrop = RenderParams(
          cropRect: CropRect(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9),
        );
        final copy = withCrop.copyWith(clearCropRect: true);
        expect(copy.cropRect, isNull);
      });

      test('does not mutate the original', () {
        const original = RenderParams(filter: NotationFilter.none);
        original.copyWith(filter: NotationFilter.grayscale);
        expect(original.filter, NotationFilter.none);
      });
    });

    group('equality', () {
      test('two instances with same fields are equal', () {
        const a = RenderParams(
          filter: NotationFilter.tintCool,
          rotationDegrees: 180,
        );
        const b = RenderParams(
          filter: NotationFilter.tintCool,
          rotationDegrees: 180,
        );
        expect(a, equals(b));
      });

      test('instances with different filter are not equal', () {
        const a = RenderParams(filter: NotationFilter.none);
        const b = RenderParams(filter: NotationFilter.grayscale);
        expect(a, isNot(equals(b)));
      });

      test('instances with different rotationDegrees are not equal', () {
        const a = RenderParams(rotationDegrees: 0);
        const b = RenderParams(rotationDegrees: 90);
        expect(a, isNot(equals(b)));
      });

      test('instances with different cropRect are not equal', () {
        const a = RenderParams(
          cropRect: CropRect(left: 0.0, top: 0.0, right: 1.0, bottom: 1.0),
        );
        const b = RenderParams(
          cropRect: CropRect(left: 0.1, top: 0.0, right: 1.0, bottom: 1.0),
        );
        expect(a, isNot(equals(b)));
      });

      test('instance with cropRect is not equal to one without', () {
        const a = RenderParams();
        const b = RenderParams(
          cropRect: CropRect(left: 0.0, top: 0.0, right: 1.0, bottom: 1.0),
        );
        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal instances have equal hashCodes', () {
        const a = RenderParams(
          filter: NotationFilter.tintWarm,
          rotationDegrees: 90,
        );
        const b = RenderParams(
          filter: NotationFilter.tintWarm,
          rotationDegrees: 90,
        );
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson has null cropRect when not set', () {
        const params = RenderParams();
        final json = params.toJson();

        expect(json['filter'], 'none');
        expect(json['rotation_degrees'], 0);
        expect(json['crop_rect'], isNull);
      });

      test('toJson includes cropRect when present', () {
        const params = RenderParams(
          cropRect: CropRect(
            left: 0.1,
            top: 0.2,
            right: 0.9,
            bottom: 0.8,
          ),
        );
        final json = params.toJson();
        final crop = json['crop_rect'] as Map<String, dynamic>;

        expect(crop['left'], closeTo(0.1, 1e-9));
        expect(crop['top'], closeTo(0.2, 1e-9));
        expect(crop['right'], closeTo(0.9, 1e-9));
        expect(crop['bottom'], closeTo(0.8, 1e-9));
      });

      test('fromJson round-trips identity', () {
        expect(
          RenderParams.fromJson(RenderParams.identity.toJson()),
          equals(RenderParams.identity),
        );
      });

      test('fromJson round-trips with all fields populated', () {
        const original = RenderParams(
          filter: NotationFilter.blackAndWhite,
          rotationDegrees: 270,
          cropRect: CropRect(
            left: 0.05,
            top: 0.1,
            right: 0.95,
            bottom: 0.9,
          ),
        );
        expect(RenderParams.fromJson(original.toJson()), equals(original));
      });

      test('fromJson handles empty map as identity', () {
        final params = RenderParams.fromJson({});
        expect(params, equals(RenderParams.identity));
      });

      test('fromJson handles explicit null cropRect', () {
        final params = RenderParams.fromJson({
          'filter': 'none',
          'rotation_degrees': 0,
          'crop_rect': null,
        });
        expect(params.cropRect, isNull);
      });
    });
  });

  group('CropRect', () {
    group('construction', () {
      test('stores normalized fractions', () {
        const crop = CropRect(
          left: 0.0,
          top: 0.0,
          right: 1.0,
          bottom: 1.0,
        );
        expect(crop.left, 0.0);
        expect(crop.top, 0.0);
        expect(crop.right, 1.0);
        expect(crop.bottom, 1.0);
      });
    });

    group('equality', () {
      test('equal CropRects are equal', () {
        const a = CropRect(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8);
        const b = CropRect(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8);
        expect(a, equals(b));
      });

      test('different CropRects are not equal', () {
        const a = CropRect(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8);
        const b = CropRect(left: 0.2, top: 0.2, right: 0.9, bottom: 0.8);
        expect(a, isNot(equals(b)));
      });
    });

    group('hashCode', () {
      test('equal CropRects have equal hashCodes', () {
        const a = CropRect(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8);
        const b = CropRect(left: 0.1, top: 0.2, right: 0.9, bottom: 0.8);
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('JSON serialization', () {
      test('round-trips correctly', () {
        const original =
            CropRect(left: 0.05, top: 0.1, right: 0.95, bottom: 0.9);
        expect(
          CropRect.fromJson(original.toJson()),
          equals(original),
        );
      });
    });
  });
}
