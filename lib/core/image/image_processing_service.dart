// ImageProcessingService — non-destructive filter, crop, and rotate pipeline.
//
// Applies colour filters, crop, and rotation transforms to notation page
// images at render time without mutating the original image bytes. All
// pixel-level work runs on an isolate via [compute()] so the UI thread is
// never blocked.
//
// Supported filters: none, grayscale, black-and-white (threshold), warm tint
// (colour matrix), cool tint (colour matrix).
//
// Composite pipeline order: filter → crop → rotate.
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

/// The set of rotation values accepted by [ImageProcessingService.applyRotation].
const List<int> _kValidRotationDegrees = <int>[0, 90, 180, 270];

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown by [ImageProcessingService] methods when input is invalid or a
/// transform cannot be applied.
class ImageProcessingException implements Exception {
  /// Creates an [ImageProcessingException] with the given [message].
  ///
  /// Parameters:
  /// - [message]: A human-readable description of the failure.
  const ImageProcessingException(this.message);

  /// A human-readable description of the failure.
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

/// Payload sent to the isolate function [_applyCropIsolate].
///
/// Groups together all data needed to decode, crop, and re-encode the image
/// in a single isolate invocation.
class _CropPayload {
  /// Creates a [_CropPayload].
  ///
  /// Parameters:
  /// - [bytes]: Raw JPEG image bytes to crop.
  /// - [cropRect]: Normalized crop region expressed as fractions of the
  ///   original image dimensions.
  const _CropPayload({required this.bytes, required this.cropRect});

  /// Raw JPEG bytes of the source image.
  final Uint8List bytes;

  /// Normalized crop region.
  final CropRect cropRect;
}

/// Payload sent to the isolate function [_applyRotationIsolate].
///
/// Groups together all data needed to decode, rotate, and re-encode the image
/// in a single isolate invocation.
class _RotationPayload {
  /// Creates a [_RotationPayload].
  ///
  /// Parameters:
  /// - [bytes]: Raw JPEG image bytes to rotate.
  /// - [degrees]: Clockwise rotation in degrees. Must be 0, 90, 180, or 270.
  const _RotationPayload({required this.bytes, required this.degrees});

  /// Raw JPEG bytes of the source image.
  final Uint8List bytes;

  /// Clockwise rotation in degrees.
  final int degrees;
}

/// Payload sent to the isolate function [_applyCompositeIsolate].
///
/// Groups together all data needed to run the full filter → crop → rotate
/// pipeline in a single isolate invocation.
class _CompositePayload {
  /// Creates a [_CompositePayload].
  ///
  /// Parameters:
  /// - [bytes]: Raw JPEG image bytes to transform.
  /// - [params]: The [RenderParams] describing filter, crop, and rotation.
  const _CompositePayload({required this.bytes, required this.params});

  /// Raw JPEG bytes of the source image.
  final Uint8List bytes;

  /// The rendering parameters to apply.
  final RenderParams params;
}

// ---------------------------------------------------------------------------
// Top-level isolate functions (must be top-level for compute())
// ---------------------------------------------------------------------------

/// Decode–filter–encode pipeline executed on an isolate.
///
/// Returns the JPEG-encoded [Uint8List] with [payload.filter] applied.
/// Throws [ImageProcessingException] if the bytes cannot be decoded.
///
/// Parameters:
/// - [payload]: The [_FilterPayload] containing the bytes and filter enum.
Uint8List _applyFilterIsolate(_FilterPayload payload) {
  final decoded = img.decodeJpg(payload.bytes);
  if (decoded == null) {
    throw ImageProcessingException(
      'Failed to decode image: not a valid JPEG or unsupported format.',
    );
  }

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

  return img.encodeJpg(filtered, quality: _kJpegQuality);
}

/// Decode–crop–encode pipeline executed on an isolate.
///
/// Validates that [payload.cropRect] is within bounds (all fractions in
/// [0.0, 1.0] and left < right, top < bottom). Throws
/// [ImageProcessingException] on decoding failure or invalid rect.
///
/// Parameters:
/// - [payload]: The [_CropPayload] containing bytes and the normalized rect.
Uint8List _applyCropIsolate(_CropPayload payload) {
  final rect = payload.cropRect;

  // Validate bounds before decoding to fail fast.
  if (rect.left < 0.0 ||
      rect.top < 0.0 ||
      rect.right > 1.0 ||
      rect.bottom > 1.0) {
    throw ImageProcessingException(
      'cropRect values must be in [0.0, 1.0]; '
      'got left=${rect.left}, top=${rect.top}, '
      'right=${rect.right}, bottom=${rect.bottom}.',
    );
  }
  if (rect.left >= rect.right) {
    throw ImageProcessingException(
      'cropRect.left (${rect.left}) must be less than '
      'cropRect.right (${rect.right}).',
    );
  }
  if (rect.top >= rect.bottom) {
    throw ImageProcessingException(
      'cropRect.top (${rect.top}) must be less than '
      'cropRect.bottom (${rect.bottom}).',
    );
  }

  final decoded = img.decodeJpg(payload.bytes);
  if (decoded == null) {
    throw ImageProcessingException(
      'Failed to decode image: not a valid JPEG or unsupported format.',
    );
  }

  final w = decoded.width;
  final h = decoded.height;

  final x = (rect.left * w).round();
  final y = (rect.top * h).round();
  final cropW = ((rect.right - rect.left) * w).round().clamp(1, w - x);
  final cropH = ((rect.bottom - rect.top) * h).round().clamp(1, h - y);

  final cropped =
      img.copyCrop(decoded, x: x, y: y, width: cropW, height: cropH);
  return img.encodeJpg(cropped, quality: _kJpegQuality);
}

/// Decode–rotate–encode pipeline executed on an isolate.
///
/// [payload.degrees] must be 0, 90, 180, or 270. Throws
/// [ImageProcessingException] on decoding failure or invalid degrees.
///
/// Parameters:
/// - [payload]: The [_RotationPayload] containing bytes and degrees.
Uint8List _applyRotationIsolate(_RotationPayload payload) {
  if (!_kValidRotationDegrees.contains(payload.degrees)) {
    throw ImageProcessingException(
      'Unsupported rotation degrees: ${payload.degrees}. '
      'Valid values: ${_kValidRotationDegrees.join(', ')}.',
    );
  }

  final decoded = img.decodeJpg(payload.bytes);
  if (decoded == null) {
    throw ImageProcessingException(
      'Failed to decode image: not a valid JPEG or unsupported format.',
    );
  }

  if (payload.degrees == 0) {
    return img.encodeJpg(decoded, quality: _kJpegQuality);
  }

  final rotated = img.copyRotate(decoded, angle: payload.degrees.toDouble());
  return img.encodeJpg(rotated, quality: _kJpegQuality);
}

/// Full composite pipeline (filter → crop → rotate) executed on an isolate.
///
/// Runs all three transforms sequentially in a single isolate invocation to
/// avoid multiple decode/encode round-trips. Throws [ImageProcessingException]
/// on decoding failure, invalid crop rect, or unsupported rotation degrees.
///
/// Parameters:
/// - [payload]: The [_CompositePayload] containing bytes and [RenderParams].
Uint8List _applyCompositeIsolate(_CompositePayload payload) {
  final params = payload.params;

  final decoded = img.decodeJpg(payload.bytes);
  if (decoded == null) {
    throw ImageProcessingException(
      'Failed to decode image: not a valid JPEG or unsupported format.',
    );
  }

  // Step 1: Filter
  img.Image current = switch (params.filter) {
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

  // Step 2: Crop (if cropRect is set)
  if (params.cropRect case final rect?) {
    if (rect.left < 0.0 ||
        rect.top < 0.0 ||
        rect.right > 1.0 ||
        rect.bottom > 1.0) {
      throw ImageProcessingException(
        'cropRect values must be in [0.0, 1.0]; '
        'got left=${rect.left}, top=${rect.top}, '
        'right=${rect.right}, bottom=${rect.bottom}.',
      );
    }
    if (rect.left >= rect.right) {
      throw ImageProcessingException(
        'cropRect.left (${rect.left}) must be less than '
        'cropRect.right (${rect.right}).',
      );
    }
    if (rect.top >= rect.bottom) {
      throw ImageProcessingException(
        'cropRect.top (${rect.top}) must be less than '
        'cropRect.bottom (${rect.bottom}).',
      );
    }

    final w = current.width;
    final h = current.height;
    final x = (rect.left * w).round();
    final y = (rect.top * h).round();
    final cropW = ((rect.right - rect.left) * w).round().clamp(1, w - x);
    final cropH = ((rect.bottom - rect.top) * h).round().clamp(1, h - y);

    current = img.copyCrop(
      current,
      x: x,
      y: y,
      width: cropW,
      height: cropH,
    );
  }

  // Step 3: Rotate
  if (!_kValidRotationDegrees.contains(params.rotationDegrees)) {
    throw ImageProcessingException(
      'Unsupported rotation degrees: ${params.rotationDegrees}. '
      'Valid values: ${_kValidRotationDegrees.join(', ')}.',
    );
  }
  if (params.rotationDegrees != 0) {
    current = img.copyRotate(
      current,
      angle: params.rotationDegrees.toDouble(),
    );
  }

  return img.encodeJpg(current, quality: _kJpegQuality);
}

// ---------------------------------------------------------------------------
// Pixel-level transform helpers
// ---------------------------------------------------------------------------

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

/// Applies non-destructive colour filters, crop, and rotation transforms to
/// notation page images.
///
/// All transforms run on a background isolate via [compute()] so the UI
/// thread is never blocked. The original [Uint8List] passed to any method is
/// never mutated; a new [Uint8List] is always returned.
///
/// Usage in Page Editor preview:
/// Prefer the [ColorFiltered] widget for simple filter-only previews (no
/// decode overhead). Call [applyFilter] only when exporting the page or
/// compositing with crop/rotation transforms.
///
/// Usage in Notation Player:
/// Always call [apply] to obtain the final pixel-accurate output with
/// all [RenderParams] applied in a single isolate invocation.
class ImageProcessingService {
  /// Creates an [ImageProcessingService].
  const ImageProcessingService();

  /// Applies [filter] to [originalBytes] and returns the transformed image.
  ///
  /// Decodes the JPEG, applies the pixel transformation for [filter], and
  /// re-encodes as JPEG at [_kJpegQuality]. The entire pipeline runs on a
  /// background isolate via [compute()] to avoid UI jank.
  ///
  /// The [originalBytes] buffer is never mutated.
  ///
  /// Returns a new [Uint8List] containing the JPEG-encoded filtered image.
  ///
  /// Throws [ImageProcessingException] if [originalBytes] is not a valid JPEG
  /// or is empty.
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
        'ImageProcessingService.applyFilter: done, '
        'outputSize=${result.length}',
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

  /// Crops [originalBytes] to the normalized region specified by [cropRect].
  ///
  /// [cropRect] values are fractions of the image dimensions in [0.0, 1.0].
  /// The constraint [left < right] and [top < bottom] must hold.
  ///
  /// Runs on a background isolate via [compute()] to avoid UI jank.
  ///
  /// The [originalBytes] buffer is never mutated.
  ///
  /// Returns a new [Uint8List] containing the JPEG-encoded cropped image.
  ///
  /// Throws [ImageProcessingException] if [originalBytes] is not a valid JPEG,
  /// is empty, or if [cropRect] contains out-of-range or degenerate values.
  ///
  /// Parameters:
  /// - [originalBytes]: The raw JPEG bytes of the original page image.
  /// - [cropRect]: Normalized crop region with fractions in [0.0, 1.0].
  Future<Uint8List> applyCrop(
    Uint8List originalBytes,
    CropRect cropRect,
  ) async {
    if (originalBytes.isEmpty) {
      throw const ImageProcessingException(
        'originalBytes must not be empty.',
      );
    }

    log(
      'ImageProcessingService.applyCrop: '
      'cropRect=$cropRect, inputSize=${originalBytes.length}',
      name: 'ImageProcessingService',
    );

    final payload = _CropPayload(bytes: originalBytes, cropRect: cropRect);

    try {
      final result = await compute(_applyCropIsolate, payload);

      log(
        'ImageProcessingService.applyCrop: done, '
        'outputSize=${result.length}',
        name: 'ImageProcessingService',
      );

      return result;
    } on ImageProcessingException {
      rethrow;
    } on Exception catch (e) {
      throw ImageProcessingException(
        'Unexpected error while applying crop $cropRect: $e',
      );
    }
  }

  /// Rotates [originalBytes] clockwise by [degrees].
  ///
  /// [degrees] must be one of 0, 90, 180, or 270. A value of 0 is a no-op
  /// that still re-encodes the image at [_kJpegQuality].
  ///
  /// Runs on a background isolate via [compute()] to avoid UI jank.
  ///
  /// The [originalBytes] buffer is never mutated.
  ///
  /// Returns a new [Uint8List] containing the JPEG-encoded rotated image.
  ///
  /// Throws [ImageProcessingException] if [originalBytes] is not a valid JPEG,
  /// is empty, or if [degrees] is not 0, 90, 180, or 270.
  ///
  /// Parameters:
  /// - [originalBytes]: The raw JPEG bytes of the original page image.
  /// - [degrees]: Clockwise rotation in degrees. Valid values: 0, 90, 180, 270.
  Future<Uint8List> applyRotation(
    Uint8List originalBytes,
    int degrees,
  ) async {
    if (originalBytes.isEmpty) {
      throw const ImageProcessingException(
        'originalBytes must not be empty.',
      );
    }

    log(
      'ImageProcessingService.applyRotation: '
      'degrees=$degrees, inputSize=${originalBytes.length}',
      name: 'ImageProcessingService',
    );

    final payload = _RotationPayload(bytes: originalBytes, degrees: degrees);

    try {
      final result = await compute(_applyRotationIsolate, payload);

      log(
        'ImageProcessingService.applyRotation: done, '
        'outputSize=${result.length}',
        name: 'ImageProcessingService',
      );

      return result;
    } on ImageProcessingException {
      rethrow;
    } on Exception catch (e) {
      throw ImageProcessingException(
        'Unexpected error while applying rotation $degrees°: $e',
      );
    }
  }

  /// Applies the full composite pipeline (filter → crop → rotate) described
  /// by [params] to [originalBytes], in a single [compute()] call.
  ///
  /// Pipeline order:
  /// 1. Apply [RenderParams.filter] (colour transform)
  /// 2. Apply [RenderParams.cropRect] if non-null (spatial crop)
  /// 3. Apply [RenderParams.rotationDegrees] if non-zero (clockwise rotation)
  ///
  /// This is the method to use in the Notation Player, where the final
  /// pixel-accurate composite output is required before display.
  ///
  /// Runs entirely on a background isolate via [compute()] — the image is
  /// decoded and re-encoded exactly once regardless of how many transforms
  /// are applied.
  ///
  /// The [originalBytes] buffer is never mutated.
  ///
  /// Returns a new [Uint8List] containing the JPEG-encoded composite image.
  ///
  /// Throws [ImageProcessingException] if [originalBytes] is not a valid JPEG,
  /// is empty, if [params.cropRect] is invalid, or if
  /// [params.rotationDegrees] is not 0, 90, 180, or 270.
  ///
  /// Parameters:
  /// - [originalBytes]: The raw JPEG bytes of the original page image.
  /// - [params]: The [RenderParams] describing all transforms to apply.
  Future<Uint8List> apply(
    Uint8List originalBytes,
    RenderParams params,
  ) async {
    if (originalBytes.isEmpty) {
      throw const ImageProcessingException(
        'originalBytes must not be empty.',
      );
    }

    log(
      'ImageProcessingService.apply: params=$params, '
      'inputSize=${originalBytes.length}',
      name: 'ImageProcessingService',
    );

    final payload = _CompositePayload(bytes: originalBytes, params: params);

    try {
      final result = await compute(_applyCompositeIsolate, payload);

      log(
        'ImageProcessingService.apply: done, outputSize=${result.length}',
        name: 'ImageProcessingService',
      );

      return result;
    } on ImageProcessingException {
      rethrow;
    } on Exception catch (e) {
      throw ImageProcessingException(
        'Unexpected error while applying composite pipeline '
        '(params=$params): $e',
      );
    }
  }
}
