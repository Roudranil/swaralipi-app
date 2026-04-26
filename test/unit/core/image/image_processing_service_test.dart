// Unit tests for ImageProcessingService.
//
// Covers the public [ImageProcessingService.applyFilter],
// [ImageProcessingService.applyCrop], [ImageProcessingService.applyRotation],
// and [ImageProcessingService.apply] methods.
//
// Tests verify:
//   - Return type is [Uint8List] (non-null, non-empty)
//   - Original bytes are never mutated (SHA-256 hash invariant)
//   - Each filter produces the expected pixel output
//   - Crop correctly extracts the expected sub-region
//   - Rotation produces correct dimensions for 90/180/270 degrees
//   - Rotation 0 is a no-op (bytes unchanged after decode/encode)
//   - Composite [apply] applies filter → crop → rotate in order
//   - Invalid input throws [ImageProcessingException]

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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

/// Returns the SHA-256 hex digest of [bytes].
String _sha256hex(Uint8List bytes) => sha256.convert(bytes).toString();

/// Creates a valid JPEG with a 2×2 color grid pattern.
///
/// Top-left quadrant is red, top-right green, bottom-left blue,
/// bottom-right white. [size] must be even.
///
/// Parameters:
/// - [size]: Width and height in pixels. Must be even. Defaults to `8`.
Uint8List _makeQuadrantJpeg({int size = 8}) {
  assert(size % 2 == 0, 'size must be even');
  final half = size ~/ 2;
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final isLeft = x < half;
      final isTop = y < half;
      final color = switch ((isTop, isLeft)) {
        (true, true) => img.ColorRgb8(255, 0, 0), // top-left: red
        (true, false) => img.ColorRgb8(0, 255, 0), // top-right: green
        (false, true) => img.ColorRgb8(0, 0, 255), // bottom-left: blue
        (false, false) => img.ColorRgb8(255, 255, 255), // bottom-right: white
      };
      image.setPixel(x, y, color);
    }
  }
  return img.encodeJpg(image, quality: 100);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

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
    // applyFilter — error handling
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

    // -----------------------------------------------------------------------
    // applyCrop
    // -----------------------------------------------------------------------

    group('applyCrop', () {
      test('returns non-empty Uint8List', () async {
        // Arrange — 8×8 image, crop the top-left quarter
        final bytes = _makeJpeg(width: 8, height: 8);
        const cropRect = CropRect(
          left: 0.0,
          top: 0.0,
          right: 0.5,
          bottom: 0.5,
        );

        // Act
        final result = await service.applyCrop(bytes, cropRect);

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes', () async {
        // Arrange
        final original = _makeJpeg(width: 8, height: 8);
        final hashBefore = _sha256hex(original);
        const cropRect = CropRect(
          left: 0.0,
          top: 0.0,
          right: 0.5,
          bottom: 0.5,
        );

        // Act
        await service.applyCrop(original, cropRect);

        // Assert — SHA-256 hash is unchanged
        expect(_sha256hex(original), equals(hashBefore));
      });

      test('output has correct dimensions for half-width crop', () async {
        // Arrange — 8×8 image, crop left half (full height)
        final bytes = _makeJpeg(width: 8, height: 8);
        const cropRect = CropRect(
          left: 0.0,
          top: 0.0,
          right: 0.5,
          bottom: 1.0,
        );

        // Act
        final result = await service.applyCrop(bytes, cropRect);
        final decoded = img.decodeJpg(result)!;

        // Assert — width should be ~4, height ~8 (JPEG rounding)
        expect(decoded.width, lessThanOrEqualTo(4));
        expect(decoded.height, greaterThan(0));
      });

      test('output has correct dimensions for quarter-height crop', () async {
        // Arrange — 8×8 image, crop top quarter (full width)
        final bytes = _makeJpeg(width: 8, height: 8);
        const cropRect = CropRect(
          left: 0.0,
          top: 0.0,
          right: 1.0,
          bottom: 0.25,
        );

        // Act
        final result = await service.applyCrop(bytes, cropRect);
        final decoded = img.decodeJpg(result)!;

        // Assert — height should be ~2 (8 * 0.25), width ~8
        expect(decoded.height, lessThanOrEqualTo(2));
        expect(decoded.width, greaterThan(0));
      });

      test(
        'identity crop (full rect) returns image of same size',
        () async {
          // Arrange — full crop rect should return same dimensions
          final bytes = _makeJpeg(width: 8, height: 6);
          const cropRect = CropRect(
            left: 0.0,
            top: 0.0,
            right: 1.0,
            bottom: 1.0,
          );

          // Act
          final result = await service.applyCrop(bytes, cropRect);
          final decoded = img.decodeJpg(result)!;

          // Assert
          expect(decoded.width, equals(8));
          expect(decoded.height, equals(6));
        },
      );

      test(
        'crop preserves color of cropped region',
        () async {
          // Arrange — 8×8 quadrant image; crop top-left red quadrant
          final bytes = _makeQuadrantJpeg(size: 8);
          const cropRect = CropRect(
            left: 0.0,
            top: 0.0,
            right: 0.5,
            bottom: 0.5,
          );

          // Act
          final result = await service.applyCrop(bytes, cropRect);
          final avg = _averageRgb(result);

          // Assert — top-left quadrant is red; red should dominate
          expect(avg.r, greaterThan(avg.g + 0.2));
          expect(avg.r, greaterThan(avg.b + 0.2));
        },
      );

      test(
        'throws ImageProcessingException for invalid JPEG bytes',
        () async {
          // Arrange
          final invalidBytes = Uint8List.fromList([0x00, 0x01]);
          const cropRect = CropRect(
            left: 0.0,
            top: 0.0,
            right: 0.5,
            bottom: 0.5,
          );

          // Act & Assert
          expect(
            () => service.applyCrop(invalidBytes, cropRect),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );

      test('throws ImageProcessingException for empty bytes', () async {
        // Arrange
        final emptyBytes = Uint8List(0);
        const cropRect = CropRect(
          left: 0.0,
          top: 0.0,
          right: 0.5,
          bottom: 0.5,
        );

        // Act & Assert
        expect(
          () => service.applyCrop(emptyBytes, cropRect),
          throwsA(isA<ImageProcessingException>()),
        );
      });

      test(
        'throws ImageProcessingException when right exceeds image bounds',
        () async {
          // Arrange — right = 1.5 is out of [0, 1] range
          final bytes = _makeJpeg(width: 8, height: 8);
          const cropRect = CropRect(
            left: 0.0,
            top: 0.0,
            right: 1.5,
            bottom: 1.0,
          );

          // Act & Assert
          expect(
            () => service.applyCrop(bytes, cropRect),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );

      test(
        'throws ImageProcessingException when left >= right',
        () async {
          // Arrange — degenerate rect (left == right)
          final bytes = _makeJpeg(width: 8, height: 8);
          const cropRect = CropRect(
            left: 0.5,
            top: 0.0,
            right: 0.5,
            bottom: 1.0,
          );

          // Act & Assert
          expect(
            () => service.applyCrop(bytes, cropRect),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );
    });

    // -----------------------------------------------------------------------
    // applyRotation
    // -----------------------------------------------------------------------

    group('applyRotation', () {
      test('returns non-empty Uint8List', () async {
        // Arrange
        final bytes = _makeJpeg(width: 8, height: 6);

        // Act
        final result = await service.applyRotation(bytes, 90);

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('does not mutate the original bytes (SHA-256 invariant)', () async {
        // Arrange
        final original = _makeJpeg(width: 8, height: 6);
        final hashBefore = _sha256hex(original);

        // Act
        await service.applyRotation(original, 90);

        // Assert — hash must be unchanged
        expect(_sha256hex(original), equals(hashBefore));
      });

      test('rotation 0 is a no-op (same dimensions)', () async {
        // Arrange
        final bytes = _makeJpeg(width: 8, height: 6);

        // Act
        final result = await service.applyRotation(bytes, 0);
        final decoded = img.decodeJpg(result)!;

        // Assert — dimensions unchanged
        expect(decoded.width, equals(8));
        expect(decoded.height, equals(6));
      });

      test('rotation 90 swaps width and height', () async {
        // Arrange — non-square so rotation is detectable
        final bytes = _makeJpeg(width: 8, height: 4);

        // Act
        final result = await service.applyRotation(bytes, 90);
        final decoded = img.decodeJpg(result)!;

        // Assert — width and height swapped
        expect(decoded.width, equals(4));
        expect(decoded.height, equals(8));
      });

      test('rotation 180 preserves dimensions', () async {
        // Arrange
        final bytes = _makeJpeg(width: 8, height: 4);

        // Act
        final result = await service.applyRotation(bytes, 180);
        final decoded = img.decodeJpg(result)!;

        // Assert — same dimensions after 180° rotation
        expect(decoded.width, equals(8));
        expect(decoded.height, equals(4));
      });

      test('rotation 270 swaps width and height', () async {
        // Arrange
        final bytes = _makeJpeg(width: 8, height: 4);

        // Act
        final result = await service.applyRotation(bytes, 270);
        final decoded = img.decodeJpg(result)!;

        // Assert — width and height swapped
        expect(decoded.width, equals(4));
        expect(decoded.height, equals(8));
      });

      test(
        'throws ImageProcessingException for unsupported degrees (45)',
        () async {
          // Arrange
          final bytes = _makeJpeg();

          // Act & Assert
          expect(
            () => service.applyRotation(bytes, 45),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );

      test(
        'throws ImageProcessingException for unsupported degrees (-90)',
        () async {
          // Arrange
          final bytes = _makeJpeg();

          // Act & Assert
          expect(
            () => service.applyRotation(bytes, -90),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );

      test(
        'throws ImageProcessingException for invalid JPEG bytes',
        () async {
          // Arrange
          final invalidBytes = Uint8List.fromList([0x00, 0x01]);

          // Act & Assert
          expect(
            () => service.applyRotation(invalidBytes, 90),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );

      test('throws ImageProcessingException for empty bytes', () async {
        // Arrange
        final emptyBytes = Uint8List(0);

        // Act & Assert
        expect(
          () => service.applyRotation(emptyBytes, 90),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });

    // -----------------------------------------------------------------------
    // apply — composite pipeline
    // -----------------------------------------------------------------------

    group('apply — composite pipeline', () {
      test('returns non-empty Uint8List for identity params', () async {
        // Arrange
        final bytes = _makeJpeg(width: 8, height: 8);

        // Act
        final result = await service.apply(bytes, RenderParams.identity);

        // Assert
        expect(result, isA<Uint8List>());
        expect(result, isNotEmpty);
      });

      test('original SHA-256 hash is unchanged after apply()', () async {
        // Arrange — capture hash before any transform
        final original = _makeJpeg(width: 8, height: 8);
        final hashBefore = _sha256hex(original);
        const params = RenderParams(
          filter: NotationFilter.grayscale,
          rotationDegrees: 90,
          cropRect: CropRect(
            left: 0.1,
            top: 0.1,
            right: 0.9,
            bottom: 0.9,
          ),
        );

        // Act
        await service.apply(original, params);

        // Assert — original bytes are absolutely unchanged
        expect(
          _sha256hex(original),
          equals(hashBefore),
          reason: 'apply() must never mutate the original bytes buffer',
        );
      });

      test(
        'original SHA-256 hash is unchanged after rotate-only apply()',
        () async {
          // Arrange
          final original = _makeJpeg(width: 8, height: 4);
          final hashBefore = _sha256hex(original);
          const params = RenderParams(rotationDegrees: 180);

          // Act
          await service.apply(original, params);

          // Assert
          expect(_sha256hex(original), equals(hashBefore));
        },
      );

      test(
        'original SHA-256 hash is unchanged after crop-only apply()',
        () async {
          // Arrange
          final original = _makeJpeg(width: 8, height: 8);
          final hashBefore = _sha256hex(original);
          const params = RenderParams(
            cropRect: CropRect(
              left: 0.0,
              top: 0.0,
              right: 0.5,
              bottom: 0.5,
            ),
          );

          // Act
          await service.apply(original, params);

          // Assert
          expect(_sha256hex(original), equals(hashBefore));
        },
      );

      test(
        'apply with rotation 90 swaps output dimensions',
        () async {
          // Arrange — 8×4 input; rotation 90 should produce 4×8 output
          final bytes = _makeJpeg(width: 8, height: 4);
          const params = RenderParams(rotationDegrees: 90);

          // Act
          final result = await service.apply(bytes, params);
          final decoded = img.decodeJpg(result)!;

          // Assert
          expect(decoded.width, equals(4));
          expect(decoded.height, equals(8));
        },
      );

      test('apply with crop reduces output dimensions', () async {
        // Arrange — 8×8 input; crop to top-left quarter
        final bytes = _makeJpeg(width: 8, height: 8);
        const params = RenderParams(
          cropRect: CropRect(
            left: 0.0,
            top: 0.0,
            right: 0.5,
            bottom: 0.5,
          ),
        );

        // Act
        final result = await service.apply(bytes, params);
        final decoded = img.decodeJpg(result)!;

        // Assert — output must be smaller than 8×8
        expect(decoded.width, lessThanOrEqualTo(4));
        expect(decoded.height, lessThanOrEqualTo(4));
      });

      test('apply with grayscale filter produces equal RGB channels', () async {
        // Arrange — colored image; grayscale should equalize channels
        final bytes = _makeJpeg(r: 200, g: 50, b: 10, width: 8, height: 8);
        const params = RenderParams(filter: NotationFilter.grayscale);

        // Act
        final result = await service.apply(bytes, params);
        final avg = _averageRgb(result);

        // Assert — all channels should be roughly equal
        expect(avg.r, closeTo(avg.g, 0.05));
        expect(avg.r, closeTo(avg.b, 0.05));
      });

      test(
        'apply with filter + crop + rotate produces non-empty result',
        () async {
          // Arrange — all three transforms combined
          final bytes = _makeJpeg(width: 8, height: 8);
          const params = RenderParams(
            filter: NotationFilter.tintWarm,
            rotationDegrees: 270,
            cropRect: CropRect(
              left: 0.0,
              top: 0.0,
              right: 0.75,
              bottom: 0.75,
            ),
          );

          // Act
          final result = await service.apply(bytes, params);

          // Assert
          expect(result, isA<Uint8List>());
          expect(result, isNotEmpty);
        },
      );

      test('apply with all NotationFilter values does not throw', () async {
        // Arrange
        final bytes = _makeJpeg(width: 8, height: 8);

        for (final filter in NotationFilter.values) {
          final params = RenderParams(filter: filter);

          // Act & Assert — no exception for any filter value
          await expectLater(
            service.apply(bytes, params),
            completes,
          );
        }
      });

      test(
        'throws ImageProcessingException for invalid JPEG bytes',
        () async {
          // Arrange
          final invalidBytes = Uint8List.fromList([0x00, 0x01]);

          // Act & Assert
          expect(
            () => service.apply(invalidBytes, RenderParams.identity),
            throwsA(isA<ImageProcessingException>()),
          );
        },
      );

      test('throws ImageProcessingException for empty bytes', () async {
        // Arrange
        final emptyBytes = Uint8List(0);

        // Act & Assert
        expect(
          () => service.apply(emptyBytes, RenderParams.identity),
          throwsA(isA<ImageProcessingException>()),
        );
      });
    });
  });
}
