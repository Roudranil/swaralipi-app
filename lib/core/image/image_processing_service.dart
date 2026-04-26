// ImageProcessingService — non-destructive filter rendering pipeline.
//
// Applies colour filters to notation page images at render time without
// mutating the original image bytes. All pixel-level work runs on an isolate
// via [compute()] so the UI thread is never blocked.
//
// Supported filters: none, grayscale, black-and-white (threshold), warm tint
// (colour matrix), cool tint (colour matrix).
//
// For Page Editor preview, callers should prefer the [ColorFiltered] widget
// for simple filter-only previews (zero decode cost). Call [applyFilter] only
// when exporting or compositing with crop/rotation transforms.

import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Luminance threshold used for the black-and-white filter.
///
/// Pixels whose luminance (Y = 0.299R + 0.587G + 0.114B) is at or above this
/// value are mapped to white; below it are mapped to black.
const double _kBwThreshold = 0.5;

/// Red channel scale factor for the warm tint.
///
/// Slightly boosts red to create an amber/warm feel.
const double _kWarmRedScale = 1.10;

/// Green channel scale factor for the warm tint.
///
/// Keeps green roughly neutral.
const double _kWarmGreenScale = 0.95;

/// Blue channel scale factor for the warm tint.
///
/// Reduces blue to reinforce warmth.
const double _kWarmBlueScale = 0.80;

/// Red channel scale factor for the cool tint.
///
/// Reduces red to reinforce coolness.
const double _kCoolRedScale = 0.85;

/// Green channel scale factor for the cool tint.
///
/// Keeps green roughly neutral.
const double _kCoolGreenScale = 0.95;

/// Blue channel scale factor for the cool tint.
///
/// Boosts blue to create a cool/icy feel.
const double _kCoolBlueScale = 1.15;

/// JPEG encode quality used when re-encoding filtered output.
///
/// 92 is a good balance between file size and visible quality for
/// notation page images.
const int _kJpegQuality = 92;

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown by [ImageProcessingService.applyFilter] when the input bytes cannot
/// be decoded as a valid JPEG image.
class ImageProcessingException implements Exception {
  /// Creates an [ImageProcessingException] with the given [message].
  ///
  /// Parameters:
  /// - [message]: A human-readable description of the decoding failure.
  const ImageProcessingException(this.message);

  /// A human-readable description of the decoding failure.
  final String message;

  @override
  String toString() => 'ImageProcessingException: $message';
}

// ---------------------------------------------------------------------------
// Isolate message types
// ---------------------------------------------------------------------------

/// Payload sent to the isolate function [_applyFilterIsolate].
///
/// Groups together all data needed to decode, filter, and re-encode the image
/// in a single isolate invocation.
class _FilterPayload {
  /// Creates a [_FilterPayload].
  ///
  /// Parameters:
  /// - [bytes]: Raw JPEG image bytes to transform.
  /// - [filter]: The [NotationFilter] to apply.
  const _FilterPayload({required this.bytes, required this.filter});

  /// Raw JPEG bytes of the source image.
  final Uint8List bytes;

  /// The filter to apply.
  final NotationFilter filter;
}

// ---------------------------------------------------------------------------
// Top-level isolate function (must be top-level for compute())
// ---------------------------------------------------------------------------

/// Decode–filter–encode pipeline executed on an isolate.
///
/// Returns the JPEG-encoded [Uint8List] with [payload.filter] applied.
/// Throws [ImageProcessingException] if the bytes cannot be decoded.
///
/// Parameters:
/// - [payload]: The [_FilterPayload] containing the bytes and filter enum.
Uint8List _applyFilterIsolate(_FilterPayload payload) {
  // Decode
  final decoded = img.decodeJpg(payload.bytes);
  if (decoded == null) {
    throw ImageProcessingException(
      'Failed to decode image: not a valid JPEG or unsupported format.',
    );
  }

  // Apply filter — each helper operates on the decoded image; original bytes
  // are already safely separated at this point (isolate memory boundary).
  final filtered = switch (payload.filter) {
    NotationFilter.none => decoded,
    NotationFilter.grayscale => _applyGrayscale(decoded),
    NotationFilter.blackAndWhite => _applyBlackAndWhite(decoded),
    NotationFilter.tintWarm => _applyTint(
        decoded,
        redScale: _kWarmRedScale,
        greenScale: _kWarmGreenScale,
        blueScale: _kWarmBlueScale,
      ),
    NotationFilter.tintCool => _applyTint(
        decoded,
        redScale: _kCoolRedScale,
        greenScale: _kCoolGreenScale,
        blueScale: _kCoolBlueScale,
      ),
  };

  // Re-encode and return
  return img.encodeJpg(filtered, quality: _kJpegQuality);
}

/// Converts [src] to grayscale using the `image` package's [img.grayscale].
///
/// Desaturates all channels to the luminance value. Modifies [src] in-place
/// and returns it (the `image` package mutates the passed image).
img.Image _applyGrayscale(img.Image src) => img.grayscale(src);

/// Converts [src] to pure black-and-white using a luminance threshold.
///
/// Pixels with luminance ≥ [_kBwThreshold] become white; others become black.
/// Modifies [src] in-place and returns it.
img.Image _applyBlackAndWhite(img.Image src) =>
    img.luminanceThreshold(src, threshold: _kBwThreshold);

/// Applies a warm or cool colour tint to [src] by scaling each RGB channel.
///
/// Uses [img.scaleRgba] which multiplies each channel by the normalized value
/// of the corresponding channel in the scale colour. A uint8 scale value of
/// 255 = 1.0× (no change); values above boost the channel; below attenuate.
///
/// Parameters:
/// - [src]: The source image to tint.
/// - [redScale]: Multiplier for the red channel (e.g. 1.10 = +10%).
/// - [greenScale]: Multiplier for the green channel.
/// - [blueScale]: Multiplier for the blue channel.
img.Image _applyTint(
  img.Image src, {
  required double redScale,
  required double greenScale,
  required double blueScale,
}) {
  // img.scaleRgba normalizes the scale color: uint8 255 ≡ 1.0×.
  // Clamp to [0, 255] to stay within the valid uint8 range.
  final scaleColor = img.ColorRgb8(
    (redScale * 255).clamp(0, 255).round(),
    (greenScale * 255).clamp(0, 255).round(),
    (blueScale * 255).clamp(0, 255).round(),
  );
  return img.scaleRgba(src, scale: scaleColor);
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Applies non-destructive colour filters to notation page images.
///
/// All transforms run on a background isolate via [compute()] so the UI
/// thread is never blocked. The original [Uint8List] is never written to;
/// a new [Uint8List] is always returned.
///
/// Usage in Page Editor preview:
/// Prefer the [ColorFiltered] widget for simple filter-only previews (no
/// decode overhead). Call [applyFilter] only when exporting the page or
/// compositing with crop/rotation transforms.
///
/// Usage in Notation Player:
/// Always call [applyFilter] to obtain the final pixel-accurate output with
/// all [RenderParams] applied.
class ImageProcessingService {
  /// Creates an [ImageProcessingService].
  const ImageProcessingService();

  /// Applies [filter] to [originalBytes] and returns the transformed image.
  ///
  /// Decodes the JPEG, applies the pixel transformation for [filter], and
  /// re-encodes as JPEG at [_kJpegQuality]. The entire pipeline runs on a
  /// background isolate via [compute()] to avoid UI jank.
  ///
  /// The [originalBytes] buffer is never mutated. All operations work on a
  /// decoded copy inside the isolate.
  ///
  /// Returns a new [Uint8List] containing the JPEG-encoded filtered image.
  ///
  /// Throws [ImageProcessingException] if [originalBytes] is not a valid
  /// JPEG.
  ///
  /// Parameters:
  /// - [originalBytes]: The raw JPEG bytes of the original page image.
  /// - [filter]: The [NotationFilter] to apply.
  Future<Uint8List> applyFilter(
    Uint8List originalBytes,
    NotationFilter filter,
  ) async {
    if (originalBytes.isEmpty) {
      throw const ImageProcessingException(
        'originalBytes must not be empty.',
      );
    }

    log(
      'ImageProcessingService.applyFilter: filter=$filter, '
      'inputSize=${originalBytes.length}',
      name: 'ImageProcessingService',
    );

    final payload = _FilterPayload(bytes: originalBytes, filter: filter);

    try {
      final result = await compute(_applyFilterIsolate, payload);

      log(
        'ImageProcessingService.applyFilter: done, outputSize=${result.length}',
        name: 'ImageProcessingService',
      );

      return result;
    } on ImageProcessingException {
      rethrow;
    } on Exception catch (e) {
      throw ImageProcessingException(
        'Unexpected error while applying filter $filter: $e',
      );
    }
  }
}
