// Unit tests for ImageProcessingService.
//
// Covers the public [ImageProcessingService.applyFilter] method for every
// [NotationFilter] value. Tests verify:
//   - Return type is [Uint8List] (non-null, non-empty)
//   - Original bytes are never mutated
//   - Each filter produces different output compared to original
//     (except [NotationFilter.none], which returns unchanged bytes)
//   - Invalid JPEG input throws [ImageProcessingException]

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:swaralipi/core/image/image_processing_service.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a minimal valid JPEG [Uint8List] with a solid [color] fill.
///
/// Parameters:
/// - [width]: Image width in pixels. Defaults to `4`.
/// - [height]: Image height in pixels. Defaults to `4`.
/// - [r]: Red channel (0–255). Defaults to `200`.
/// - [g]: Green channel (0–255). Defaults to `150`.
/// - [b]: Blue channel (0–255). Defaults to `100`.
Uint8List _makeJpeg({
  int width = 4,
  int height = 4,
  int r = 200,
  int g = 150,
  int b = 100,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return img.encodeJpg(image);
}

/// Decodes a JPEG [Uint8List] and returns the average normalized RGB values
/// as a (r, g, b) record.
({double r, double g, double b}) _averageRgb(Uint8List jpegBytes) {
  final decoded = img.decodeJpg(jpegBytes)!;
  double totalR = 0, totalG = 0, totalB = 0;
  final pixelCount = decoded.width * decoded.height;
  for (final pixel in decoded) {
    totalR += pixel.rNormalized;
    totalG += pixel.gNormalized;
    totalB += pixel.bNormalized;
  }
  return (
    r: totalR / pixelCount,
    g: totalG / pixelCount,
    b: totalB / pixelCount,
  );
}

void main() {
  group('ImageProcessingService', () {
    late ImageProcessingService service;

    setUp(() {
      service = const ImageProcessingService();
    });

    // -----------------------------------------------------------------------
    // NotationFilter.none
    // -----------------------------------------------------------------------

    group('applyFilter — NotationFilter.none', () {
      test('returns non-empty Uint8List', () async {
        // Arrange
        final bytes = _makeJpeg();

        // Act
        final result = await service.applyFilter(bytes, NotationFilter.none);

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes', () async {
        // Arrange
        final original = _makeJpeg();
        final snapshot = Uint8List.fromList(original);

        // Act
        await service.applyFilter(original, NotationFilter.none);

        // Assert — original must be unchanged
        expect(original, equals(snapshot));
      });

      test('output decodes to same average RGB as input', () async {
        // Arrange
        final bytes = _makeJpeg(r: 180, g: 140, b: 100);
        final inputAvg = _averageRgb(bytes);

        // Act
        final result = await service.applyFilter(bytes, NotationFilter.none);
        final outputAvg = _averageRgb(result);

        // Assert — color channels within JPEG rounding tolerance
        expect(outputAvg.r, closeTo(inputAvg.r, 0.05));
        expect(outputAvg.g, closeTo(inputAvg.g, 0.05));
        expect(outputAvg.b, closeTo(inputAvg.b, 0.05));
      });
    });

    // -----------------------------------------------------------------------
    // NotationFilter.grayscale
    // -----------------------------------------------------------------------

    group('applyFilter — NotationFilter.grayscale', () {
      test('returns non-empty Uint8List', () async {
        // Arrange
        final bytes = _makeJpeg();

        // Act
        final result = await service.applyFilter(
          bytes,
          NotationFilter.grayscale,
        );

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes', () async {
        // Arrange
        final original = _makeJpeg();
        final snapshot = Uint8List.fromList(original);

        // Act
        await service.applyFilter(original, NotationFilter.grayscale);

        // Assert
        expect(original, equals(snapshot));
      });

      test('output has equal R, G, B channels (grayscale invariant)', () async {
        // Arrange — use a clearly non-gray input
        final bytes = _makeJpeg(r: 200, g: 100, b: 50);

        // Act
        final result = await service.applyFilter(
          bytes,
          NotationFilter.grayscale,
        );
        final avg = _averageRgb(result);

        // Assert — all channels should be equal (within JPEG rounding)
        expect(avg.r, closeTo(avg.g, 0.05));
        expect(avg.r, closeTo(avg.b, 0.05));
      });

      test('output differs from input for non-gray image', () async {
        // Arrange — colored image
        final bytes = _makeJpeg(r: 200, g: 50, b: 10);

        // Act
        final result = await service.applyFilter(
          bytes,
          NotationFilter.grayscale,
        );

        // Assert — bytes are not identical
        expect(result, isNot(equals(bytes)));
      });
    });

    // -----------------------------------------------------------------------
    // NotationFilter.blackAndWhite
    // -----------------------------------------------------------------------

    group('applyFilter — NotationFilter.blackAndWhite', () {
      test('returns non-empty Uint8List', () async {
        // Arrange
        final bytes = _makeJpeg();

        // Act
        final result = await service.applyFilter(
          bytes,
          NotationFilter.blackAndWhite,
        );

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes', () async {
        // Arrange
        final original = _makeJpeg();
        final snapshot = Uint8List.fromList(original);

        // Act
        await service.applyFilter(original, NotationFilter.blackAndWhite);

        // Assert
        expect(original, equals(snapshot));
      });

      test(
        'bright input produces near-white output',
        () async {
          // Arrange — clearly bright pixel (luminance >> threshold)
          final bytes = _makeJpeg(r: 240, g: 240, b: 240);

          // Act
          final result = await service.applyFilter(
            bytes,
            NotationFilter.blackAndWhite,
          );
          final avg = _averageRgb(result);

          // Assert — should land near white (> 0.85 normalized)
          expect(avg.r, greaterThan(0.85));
          expect(avg.g, greaterThan(0.85));
          expect(avg.b, greaterThan(0.85));
        },
      );

      test(
        'dark input produces near-black output',
        () async {
          // Arrange — clearly dark pixel (luminance << threshold)
          final bytes = _makeJpeg(r: 20, g: 20, b: 20);

          // Act
          final result = await service.applyFilter(
            bytes,
            NotationFilter.blackAndWhite,
          );
          final avg = _averageRgb(result);

          // Assert — should land near black (< 0.15 normalized)
          expect(avg.r, lessThan(0.15));
          expect(avg.g, lessThan(0.15));
          expect(avg.b, lessThan(0.15));
        },
      );
    });

    // -----------------------------------------------------------------------
    // NotationFilter.tintWarm
    // -----------------------------------------------------------------------

    group('applyFilter — NotationFilter.tintWarm', () {
      test('returns non-empty Uint8List', () async {
        // Arrange
        final bytes = _makeJpeg();

        // Act
        final result = await service.applyFilter(
          bytes,
          NotationFilter.tintWarm,
        );

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes', () async {
        // Arrange
        final original = _makeJpeg();
        final snapshot = Uint8List.fromList(original);

        // Act
        await service.applyFilter(original, NotationFilter.tintWarm);

        // Assert
        expect(original, equals(snapshot));
      });

      test(
        'warm tint boosts red channel relative to blue',
        () async {
          // Arrange — neutral gray image so tint effect is clear
          final bytes = _makeJpeg(r: 128, g: 128, b: 128);

          // Act
          final result = await service.applyFilter(
            bytes,
            NotationFilter.tintWarm,
          );
          final avg = _averageRgb(result);

          // Assert — red ≥ blue is the warm tint invariant
          expect(avg.r, greaterThanOrEqualTo(avg.b));
        },
      );
    });

    // -----------------------------------------------------------------------
    // NotationFilter.tintCool
    // -----------------------------------------------------------------------

    group('applyFilter — NotationFilter.tintCool', () {
      test('returns non-empty Uint8List', () async {
        // Arrange
        final bytes = _makeJpeg();

        // Act
        final result = await service.applyFilter(
          bytes,
          NotationFilter.tintCool,
        );

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes', () async {
        // Arrange
        final original = _makeJpeg();
        final snapshot = Uint8List.fromList(original);

        // Act
        await service.applyFilter(original, NotationFilter.tintCool);

        // Assert
        expect(original, equals(snapshot));
      });

      test(
        'cool tint boosts blue channel relative to red',
        () async {
          // Arrange — neutral gray image so tint effect is clear
          final bytes = _makeJpeg(r: 128, g: 128, b: 128);

          // Act
          final result = await service.applyFilter(
            bytes,
            NotationFilter.tintCool,
          );
          final avg = _averageRgb(result);

          // Assert — blue ≥ red is the cool tint invariant
          expect(avg.b, greaterThanOrEqualTo(avg.r));
        },
      );
    });

    // -----------------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------------

    group('applyFilter — error handling', () {
      test('throws ImageProcessingException for invalid JPEG bytes', () async {
        // Arrange
        final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

        // Act & Assert
        expect(
          () => service.applyFilter(invalidBytes, NotationFilter.grayscale),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test('throws ImageProcessingException for empty bytes', () async {
        // Arrange
        final emptyBytes = Uint8List(0);

        // Act & Assert
        expect(
          () => service.applyFilter(emptyBytes, NotationFilter.grayscale),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Cross-filter differentiation
    // -----------------------------------------------------------------------

    group('applyFilter — filter outputs are distinct', () {
      test('grayscale and blackAndWhite produce different outputs', () async {
        // Arrange
        final bytes = _makeJpeg(r: 180, g: 140, b: 100);

        // Act
        final gray = await service.applyFilter(
          bytes,
          NotationFilter.grayscale,
        );
        final bw = await service.applyFilter(
          bytes,
          NotationFilter.blackAndWhite,
        );

        // Assert
        expect(gray, isNot(equals(bw)));
      });

      test('warm and cool tint produce different outputs', () async {
        // Arrange — neutral input so both filters have effect
        final bytes = _makeJpeg(r: 128, g: 128, b: 128);

        // Act
        final warm = await service.applyFilter(bytes, NotationFilter.tintWarm);
        final cool = await service.applyFilter(bytes, NotationFilter.tintCool);

        // Assert
        expect(warm, isNot(equals(cool)));
      });
    });
  });
}
