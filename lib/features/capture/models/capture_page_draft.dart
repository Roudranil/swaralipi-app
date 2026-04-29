// capture_page_draft.dart — in-memory draft for a single capture page.
//
// A [CapturePageDraft] holds the raw bytes and non-destructive render
// parameters for one page during an active capture session. Drafts live only
// in memory and are never persisted until the user confirms the session.
//
// Created by [CaptureSessionViewModel.loadFromPaths] or
// [CaptureSessionViewModel.addPage].

import 'dart:typed_data';

import 'package:swaralipi/shared/models/render_params.dart';

/// Immutable in-memory draft for a single notation page in a capture session.
///
/// Holds the original image bytes alongside non-destructive render parameters.
/// The original bytes are never mutated; [renderParams] is applied at render
/// time by [ImageProcessingService].
class CapturePageDraft {
  /// Creates an immutable [CapturePageDraft].
  ///
  /// Parameters:
  /// - [originalPath]: Absolute path on device from which bytes were read.
  /// - [originalBytes]: Raw JPEG/PNG bytes of the original image.
  /// - [renderParams]: Non-destructive render settings; defaults to
  ///   [RenderParams.identity].
  const CapturePageDraft({
    required this.originalPath,
    required this.originalBytes,
    required this.renderParams,
  });

  /// Absolute file path from which [originalBytes] were read.
  final String originalPath;

  /// Raw image bytes of the original file.
  final Uint8List originalBytes;

  /// Non-destructive render parameters applied at display time.
  final RenderParams renderParams;

  /// Returns a copy of this draft with the specified fields replaced.
  ///
  /// Parameters:
  /// - [originalPath]: Replacement path.
  /// - [originalBytes]: Replacement bytes.
  /// - [renderParams]: Replacement render params.
  CapturePageDraft copyWith({
    String? originalPath,
    Uint8List? originalBytes,
    RenderParams? renderParams,
  }) =>
      CapturePageDraft(
        originalPath: originalPath ?? this.originalPath,
        originalBytes: originalBytes ?? this.originalBytes,
        renderParams: renderParams ?? this.renderParams,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapturePageDraft &&
          runtimeType == other.runtimeType &&
          originalPath == other.originalPath &&
          renderParams == other.renderParams;

  @override
  int get hashCode => Object.hash(originalPath, renderParams);

  @override
  String toString() => 'CapturePageDraft(originalPath: $originalPath, '
      'renderParams: $renderParams)';
}
