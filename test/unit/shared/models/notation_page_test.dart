// Tests for the NotationPage domain model.
//
// Covers: immutability, copyWith, equality, hashCode, JSON round-trip.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/notation_page.dart';

void main() {
  const defaultId = 'page-uuid-1';
  const defaultNotationId = 'notation-uuid-1';
  const defaultPageOrder = 0;
  const defaultImagePath =
      'notations/notation-uuid-1/page_page-uuid-1_original.jpg';
  const defaultCreatedAt = '2024-01-15T10:00:00.000Z';

  NotationPage makePage({
    String id = defaultId,
    String notationId = defaultNotationId,
    int pageOrder = defaultPageOrder,
    String imagePath = defaultImagePath,
    String renderParams = '{}',
    String createdAt = defaultCreatedAt,
  }) =>
      NotationPage(
        id: id,
        notationId: notationId,
        pageOrder: pageOrder,
        imagePath: imagePath,
        renderParams: renderParams,
        createdAt: createdAt,
      );

  group('NotationPage', () {
    group('construction', () {
      test('creates instance with required fields', () {
        final p = makePage();

        expect(p.id, defaultId);
        expect(p.notationId, defaultNotationId);
        expect(p.pageOrder, defaultPageOrder);
        expect(p.imagePath, defaultImagePath);
        expect(p.renderParams, '{}');
        expect(p.createdAt, defaultCreatedAt);
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        final p = makePage();
        expect(p.copyWith(), equals(p));
      });

      test('copies and overrides pageOrder', () {
        final original = makePage();
        final copy = original.copyWith(pageOrder: 2);

        expect(copy.pageOrder, 2);
        expect(copy.id, original.id);
      });

      test('copies and overrides imagePath', () {
        final original = makePage();
        final copy = original.copyWith(imagePath: 'new/path.jpg');

        expect(copy.imagePath, 'new/path.jpg');
        expect(original.imagePath, defaultImagePath);
      });

      test('copies and overrides renderParams', () {
        const params = '{"rotation":90}';
        final original = makePage();
        final copy = original.copyWith(renderParams: params);

        expect(copy.renderParams, params);
      });
    });

    group('equality', () {
      test('two instances with same fields are equal', () {
        expect(makePage(), equals(makePage()));
      });

      test('instances with different ids are not equal', () {
        expect(
          makePage(id: 'page-1'),
          isNot(equals(makePage(id: 'page-2'))),
        );
      });

      test('instances with different pageOrder are not equal', () {
        expect(
          makePage(pageOrder: 0),
          isNot(equals(makePage(pageOrder: 1))),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have equal hashCodes', () {
        expect(makePage().hashCode, equals(makePage().hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys', () {
        final json = makePage().toJson();

        expect(json['id'], defaultId);
        expect(json['notation_id'], defaultNotationId);
        expect(json['page_order'], defaultPageOrder);
        expect(json['image_path'], defaultImagePath);
        expect(json['render_params'], '{}');
        expect(json['created_at'], defaultCreatedAt);
      });

      test('fromJson round-trips correctly', () {
        final original = makePage(renderParams: '{"crop":{"x":10}}');
        expect(NotationPage.fromJson(original.toJson()), equals(original));
      });
    });
  });
}
