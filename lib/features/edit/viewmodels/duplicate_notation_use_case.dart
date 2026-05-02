// DuplicateNotationUseCase — use case for duplicating a notation.
//
// Algorithm:
//   1. Load the source [NotationDetail] via [NotationRepository.loadNotation].
//   2. Generate a new UUID for the copy.
//   3. For each page, call [copyImage] to copy the JPEG file into the new
//      notation's directory.
//   4. On any copy failure, call [deleteNotationDirectory] to clean up partial
//      files, then re-throw the original error. No DB record is created.
//   5. Build a [NotationDraft] with the source metadata, title suffixed with
//      " (copy)", tag ids, and custom field values.
//   6. Call [NotationRepository.saveNotation] inside a single transaction
//      (handled by the repository).
//
// The [copyImage] and [deleteNotationDirectory] parameters are injected so
// callers can provide [FileStorageService] method references directly, keeping
// this class free of a dependency on [FileStorageService] at the type level
// and making it straightforward to test with fakes.
//
// Architecture note:
//   LibraryViewModel / NotationDetailViewModel → DuplicateNotationUseCase
//     → NotationRepository + FileStorageService (injected as function refs)
//
// Throws [DuplicateNotationSourceNotFound] if the source notation does not
// exist.

import 'dart:developer';

import 'package:uuid/uuid.dart';

import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Suffix appended to the title of a duplicated notation.
const String _kCopySuffix = ' (copy)';

/// Shared UUID generator.
const _kUuid = Uuid();

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

/// Thrown by [DuplicateNotationUseCase.execute] when the source notation
/// does not exist in the repository.
final class DuplicateNotationSourceNotFound implements Exception {
  /// Creates a [DuplicateNotationSourceNotFound] for [sourceId].
  ///
  /// Parameters:
  /// - [sourceId]: The notation id that was not found.
  const DuplicateNotationSourceNotFound(this.sourceId);

  /// The notation id that was not found.
  final String sourceId;

  @override
  String toString() => 'DuplicateNotationSourceNotFound: '
      'no notation with id "$sourceId"';
}

// ---------------------------------------------------------------------------
// Use case
// ---------------------------------------------------------------------------

/// Use case that creates a full copy of an existing notation.
///
/// Steps:
/// 1. Load source [NotationDetail] by [sourceId].
/// 2. Copy each page JPEG to the new notation's directory via [copyImage].
/// 3. On copy failure, call [deleteNotationDirectory] for cleanup and
///    re-throw.
/// 4. Save a new notation record (new UUID, title with [_kCopySuffix], all
///    other fields copied) via [NotationRepository.saveNotation].
///
/// Returns the new notation's UUID on success.
///
/// Throws [DuplicateNotationSourceNotFound] when the source does not exist.
/// Re-throws any [Exception] from [copyImage] after partial-file cleanup.
class DuplicateNotationUseCase {
  /// Creates a [DuplicateNotationUseCase].
  ///
  /// Parameters:
  /// - [notationRepository]: Used to load the source and save the copy.
  /// - [copyImage]: Copies a JPEG from [srcRelativePath] into the directory
  ///   for [newNotationId] and returns the new relative path.
  /// - [deleteNotationDirectory]: Deletes the directory for [notationId];
  ///   called on partial-copy failure to clean up.
  const DuplicateNotationUseCase({
    required NotationRepository notationRepository,
    required Future<String> Function(
      String srcRelativePath,
      String newNotationId,
    ) copyImage,
    required Future<void> Function(String notationId) deleteNotationDirectory,
  })  : _notationRepository = notationRepository,
        _copyImage = copyImage,
        _deleteNotationDirectory = deleteNotationDirectory;

  final NotationRepository _notationRepository;
  final Future<String> Function(String, String) _copyImage;
  final Future<void> Function(String) _deleteNotationDirectory;

  /// Duplicates the notation identified by [sourceId].
  ///
  /// Returns the UUID of the newly created notation.
  ///
  /// Throws [DuplicateNotationSourceNotFound] if [sourceId] is not found.
  /// Re-throws copy errors after cleaning up partial files.
  ///
  /// Parameters:
  /// - [sourceId]: UUIDv4 of the notation to duplicate.
  Future<String> execute(String sourceId) async {
    final detail = await _notationRepository.loadNotation(sourceId);
    if (detail == null) {
      throw DuplicateNotationSourceNotFound(sourceId);
    }

    final newId = _kUuid.v4();
    final copiedPages = <SavedPage>[];

    // ----- Copy all page files -----
    try {
      for (final page in detail.pages) {
        final newPath = await _copyImage(page.imagePath, newId);
        copiedPages.add(
          SavedPage(
            id: _kUuid.v4(),
            pageOrder: page.pageOrder,
            imagePath: newPath,
            renderParams: page.renderParams,
          ),
        );
      }
    } on Exception catch (e, st) {
      log(
        'DuplicateNotationUseCase: copy failed for source "$sourceId" — $e',
        name: 'DuplicateNotationUseCase',
        error: e,
        stackTrace: st,
      );

      // Clean up any partially copied files.
      try {
        await _deleteNotationDirectory(newId);
      } on Exception catch (cleanupError) {
        log(
          'DuplicateNotationUseCase: cleanup failed for "$newId" — '
          '$cleanupError',
          name: 'DuplicateNotationUseCase',
        );
        // Swallow cleanup error; original copy error is re-thrown below.
      }

      rethrow;
    }

    // ----- Build draft -----
    final source = detail.notation;
    final draft = NotationDraft(
      title: '${source.title}$_kCopySuffix',
      artists: List<String>.from(source.artists),
      dateWritten: source.dateWritten,
      timeSig: source.timeSig,
      keySig: source.keySig,
      languages: List<String>.from(source.languages),
      notes: source.notes,
      tagIds: detail.tags.map((t) => t.id).toList(),
      customFields: _buildCustomFieldInputs(detail.customFieldValues),
    );

    // ----- Persist -----
    await _notationRepository.saveNotation(
      draft,
      copiedPages,
      notationId: newId,
    );

    log(
      'DuplicateNotationUseCase: duplicated "$sourceId" → "$newId"',
      name: 'DuplicateNotationUseCase',
    );

    return newId;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Converts [CustomFieldValue] list to [CustomFieldValueInput] list.
  List<CustomFieldValueInput> _buildCustomFieldInputs(
    List<CustomFieldValue> values,
  ) =>
      values
          .map(
            (cfv) => CustomFieldValueInput(
              definitionId: cfv.definitionId,
              fieldType: _fieldTypeFor(cfv),
              textValue: cfv.valueText,
              numberValue: cfv.valueNumber,
              dateValue: cfv.valueDate,
              booleanValue: cfv.valueBoolean,
            ),
          )
          .toList();

  /// Infers the field type from the non-null column in [cfv].
  String _fieldTypeFor(CustomFieldValue cfv) {
    if (cfv.valueText != null) return 'text';
    if (cfv.valueNumber != null) return 'number';
    if (cfv.valueDate != null) return 'date';
    return 'boolean';
  }
}
