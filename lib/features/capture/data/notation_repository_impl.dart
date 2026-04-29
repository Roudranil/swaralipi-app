// NotationRepositoryImpl — concrete implementation of NotationRepository.
//
// Translates between Drift row types and domain models at the repository
// boundary. All multi-table writes (saveNotation, updateNotation) are
// executed inside a single Drift transaction to guarantee atomicity across
// notations, notation_pages, notation_tags, and notation_custom_fields.
//
// Construct by injecting the four DAOs:
//   NotationRepositoryImpl(
//     db.notationDao,
//     db.notationPageDao,
//     db.notationTagDao,
//     db.customFieldDao,
//   )

import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/custom_field_dao.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/core/database/daos/notation_page_dao.dart';
import 'package:swaralipi/core/database/daos/notation_tag_dao.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Shared [Uuid] generator instance used by [NotationRepositoryImpl].
const _kUuid = Uuid();

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [NotationRepository] backed by Drift DAOs.
///
/// All multi-table write operations run in a single [AppDatabase.transaction]
/// to guarantee atomicity. Domain-model translation (row → model) is
/// performed at the repository boundary; DAOs are responsible only for typed
/// SQL.
final class NotationRepositoryImpl implements NotationRepository {
  /// Creates a [NotationRepositoryImpl] with the given DAOs.
  ///
  /// Parameters:
  /// - [_notationDao]: DAO for the `notations_table`.
  /// - [_pageDao]: DAO for the `notation_pages_table`.
  /// - [_tagDao]: DAO for the `notation_tags_table` join.
  /// - [_customFieldDao]: DAO for the `notation_custom_fields_table`.
  const NotationRepositoryImpl(
    this._notationDao,
    this._pageDao,
    this._tagDao,
    this._customFieldDao,
  );

  final NotationDao _notationDao;
  final NotationPageDao _pageDao;
  final NotationTagDao _tagDao;
  final CustomFieldDao _customFieldDao;

  // -------------------------------------------------------------------------
  // NotationRepository interface
  // -------------------------------------------------------------------------

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async {
    final id = notationId ?? _kUuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    final notationCompanion = NotationsTableCompanion.insert(
      id: id,
      title: draft.title,
      artists: Value(jsonEncode(draft.artists)),
      languages: Value(jsonEncode(draft.languages)),
      notes: Value(draft.notes),
      createdAt: now,
      updatedAt: now,
      dateWritten: Value(draft.dateWritten),
      timeSig: Value(draft.timeSig),
      keySig: Value(draft.keySig),
    );

    await _notationDao.db.transaction(() async {
      await _notationDao.insertNotation(notationCompanion);
      await _writePages(id, pages, now);
      await _writeTags(id, draft.tagIds);
      await _writeCustomFields(id, draft.customFields);
    });

    log(
      'NotationRepositoryImpl: saved notation "$id" title="${draft.title}"',
      name: 'NotationRepository',
    );

    return Notation(
      id: id,
      title: draft.title,
      artists: draft.artists,
      dateWritten: draft.dateWritten,
      timeSig: draft.timeSig,
      keySig: draft.keySig,
      languages: draft.languages,
      notes: draft.notes,
      playCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final companion = NotationsTableCompanion(
      id: Value(id),
      title: Value(draft.title),
      artists: Value(jsonEncode(draft.artists)),
      languages: Value(jsonEncode(draft.languages)),
      notes: Value(draft.notes),
      updatedAt: Value(now),
      dateWritten: Value(draft.dateWritten),
      timeSig: Value(draft.timeSig),
      keySig: Value(draft.keySig),
    );

    await _notationDao.db.transaction(() async {
      final updated = await _notationDao.updateNotation(companion);
      if (!updated) {
        throw NotationNotFoundException(id);
      }
      await _replaceTagAssociations(id, draft.tagIds);
      await _writeCustomFields(id, draft.customFields);
    });

    final row = await _notationDao.getNotationById(id);
    // row cannot be null: updateNotation returned true → row exists.
    return _rowToDomain(row!);
  }

  @override
  Future<NotationDetail?> loadNotation(String id) async {
    final row = await _notationDao.getNotationById(id);
    if (row == null || row.deletedAt != null) return null;

    final (pageRows, tagRows, cfRows) = await (
      _pageDao.getPagesByNotationId(id),
      _tagDao.getTagsForNotation(id),
      _customFieldDao.getValuesForNotation(id),
    ).wait;

    return NotationDetail(
      notation: _rowToDomain(row),
      pages: pageRows.map(_pageRowToDomain).toList(),
      tags: tagRows.map(_tagRowToDomain).toList(),
      customFieldValues: cfRows.map(_cfRowToDomain).toList(),
    );
  }

  @override
  Stream<List<Notation>> watchAllActive() {
    return _notationDao
        .watchAllActive()
        .map((rows) => rows.map(_rowToDomain).toList());
  }

  @override
  Future<void> softDelete(String id) async {
    await _notationDao.softDelete(id);
    log(
      'NotationRepositoryImpl: soft-deleted notation $id',
      name: 'NotationRepository',
    );
  }

  @override
  Future<void> updatePlayCount(String id) async {
    await _notationDao.updatePlayCount(id);
    log(
      'NotationRepositoryImpl: incremented play count for $id',
      name: 'NotationRepository',
    );
  }

  // -------------------------------------------------------------------------
  // Private write helpers
  // -------------------------------------------------------------------------

  /// Inserts a [NotationPagesTable] row for each [SavedPage].
  Future<void> _writePages(
    String notationId,
    List<SavedPage> pages,
    String createdAt,
  ) async {
    for (final page in pages) {
      await _pageDao.insertPage(
        NotationPagesTableCompanion.insert(
          id: page.id,
          notationId: notationId,
          pageOrder: page.pageOrder,
          imagePath: page.imagePath,
          renderParams: Value(page.renderParams),
          createdAt: createdAt,
        ),
      );
    }
  }

  /// Inserts [NotationTagsTable] join rows for each tag id.
  Future<void> _writeTags(
    String notationId,
    List<String> tagIds,
  ) async {
    for (final tagId in tagIds) {
      await _tagDao.assignTag(notationId: notationId, tagId: tagId);
    }
  }

  /// Removes all existing tag associations for [notationId] and re-assigns
  /// [tagIds].
  Future<void> _replaceTagAssociations(
    String notationId,
    List<String> tagIds,
  ) async {
    final existing = await _tagDao.getTagsForNotation(notationId);
    for (final tag in existing) {
      await _tagDao.removeTag(notationId: notationId, tagId: tag.id);
    }
    await _writeTags(notationId, tagIds);
  }

  /// Upserts custom field value rows for each [CustomFieldValueInput].
  Future<void> _writeCustomFields(
    String notationId,
    List<CustomFieldValueInput> inputs,
  ) async {
    for (final input in inputs) {
      await _customFieldDao.setCustomFieldValue(
        notationId: notationId,
        definitionId: input.definitionId,
        fieldType: input.fieldType,
        textValue: input.textValue,
        numberValue: input.numberValue,
        dateValue: input.dateValue,
        booleanValue: input.booleanValue,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Row → domain model translators
  // -------------------------------------------------------------------------

  /// Converts a [NotationRow] to a [Notation] domain model.
  Notation _rowToDomain(NotationRow row) => Notation(
        id: row.id,
        title: row.title,
        artists: _decodeStringList(row.artists),
        dateWritten: row.dateWritten,
        timeSig: row.timeSig,
        keySig: row.keySig,
        languages: _decodeStringList(row.languages),
        notes: row.notes,
        playCount: row.playCount,
        lastPlayedAt: row.lastPlayedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  /// Converts a [NotationPageRow] to a [NotationPage] domain model.
  NotationPage _pageRowToDomain(NotationPageRow row) => NotationPage(
        id: row.id,
        notationId: row.notationId,
        pageOrder: row.pageOrder,
        imagePath: row.imagePath,
        renderParams: row.renderParams,
        createdAt: row.createdAt,
      );

  /// Converts a [TagRow] to a [Tag] domain model.
  Tag _tagRowToDomain(TagRow row) => Tag(
        id: row.id,
        name: row.name,
        colorHex: row.colorHex,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Converts a [NotationCustomFieldRow] to a [CustomFieldValue] domain model.
  CustomFieldValue _cfRowToDomain(NotationCustomFieldRow row) =>
      CustomFieldValue(
        notationId: row.notationId,
        definitionId: row.definitionId,
        valueText: row.valueText,
        valueNumber: row.valueNumber,
        valueDate: row.valueDate,
        valueBoolean: row.valueBoolean == null ? null : row.valueBoolean == 1,
      );

  // -------------------------------------------------------------------------
  // Private utilities
  // -------------------------------------------------------------------------

  /// Decodes a JSON-encoded string array from the database.
  ///
  /// Returns an empty list when [raw] is `'[]'` or cannot be decoded.
  List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } on FormatException catch (e) {
      log(
        'NotationRepositoryImpl: failed to decode list "$raw": $e',
        name: 'NotationRepository',
      );
    }
    return [];
  }
}
