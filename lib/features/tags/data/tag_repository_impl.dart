// TagRepositoryImpl — concrete implementation of TagRepository.
//
// Translates between [TagRow] (Drift) and [Tag] (domain model). All write
// operations return the persisted domain model.
//
// Construct by injecting a [TagDao] and a [UserPreferencesRepository]:
//   TagRepositoryImpl(db.tagDao, preferencesRepository)

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/tag_dao.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [TagRepository] backed by a Drift [TagDao].
///
/// Translates [TagRow] database rows to [Tag] domain models at the repository
/// boundary. All business logic (UUID generation, timestamp stamping) lives
/// here; the [TagDao] is responsible only for typed SQL.
final class TagRepositoryImpl implements TagRepository {
  /// Creates a [TagRepositoryImpl] with the given [_tagDao] and
  /// [_prefsRepository].
  ///
  /// Parameters:
  /// - [_tagDao]: The Drift DAO for the `tags_table`.
  /// - [_prefsRepository]: Used to read and write user preferences.
  const TagRepositoryImpl(this._tagDao, this._prefsRepository);

  final TagDao _tagDao;
  final UserPreferencesRepository _prefsRepository;

  // -------------------------------------------------------------------------
  // TagRepository interface
  // -------------------------------------------------------------------------

  @override
  Stream<List<Tag>> watchAllTags() {
    return _tagDao.watchAllTags().map(
          (rows) => rows.map(_rowToTag).toList(),
        );
  }

  @override
  Future<Tag> createTag(String name, String colorHex) async {
    final id = _kUuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await _tagDao.insertTag(
      TagsTableCompanion.insert(
        id: id,
        name: name,
        colorHex: colorHex,
        createdAt: now,
        updatedAt: now,
      ),
    );

    log('TagRepositoryImpl: created tag "$name" ($id)', name: 'TagRepository');

    return Tag(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Tag> updateTag(
    String id, {
    String? name,
    String? colorHex,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final companion = TagsTableCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
      updatedAt: Value(now),
    );

    final updated = await _tagDao.updateTag(companion);
    if (!updated) {
      throw TagNotFoundException(id);
    }

    final row = await _tagDao.getTagById(id);
    // row cannot be null here: updateTag returned true → row exists.
    return _rowToTag(row!);
  }

  @override
  Future<void> deleteTag(String id) async {
    await _tagDao.deleteTag(id);
    log('TagRepositoryImpl: deleted tag $id', name: 'TagRepository');
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Converts a [TagRow] to a [Tag] domain model.
  Tag _rowToTag(TagRow row) => Tag(
        id: row.id,
        name: row.name,
        colorHex: row.colorHex,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Shared [Uuid] generator instance used by [TagRepositoryImpl].
const _kUuid = Uuid();
