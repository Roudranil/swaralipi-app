// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotationsTableTable extends NotationsTable
    with TableInfo<$NotationsTableTable, NotationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _artistsMeta =
      const VerificationMeta('artists');
  @override
  late final GeneratedColumn<String> artists = GeneratedColumn<String>(
      'artists', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _dateWrittenMeta =
      const VerificationMeta('dateWritten');
  @override
  late final GeneratedColumn<String> dateWritten = GeneratedColumn<String>(
      'date_written', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _timeSigMeta =
      const VerificationMeta('timeSig');
  @override
  late final GeneratedColumn<String> timeSig = GeneratedColumn<String>(
      'time_sig', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _keySigMeta = const VerificationMeta('keySig');
  @override
  late final GeneratedColumn<String> keySig = GeneratedColumn<String>(
      'key_sig', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _languagesMeta =
      const VerificationMeta('languages');
  @override
  late final GeneratedColumn<String> languages = GeneratedColumn<String>(
      'languages', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _playCountMeta =
      const VerificationMeta('playCount');
  @override
  late final GeneratedColumn<int> playCount = GeneratedColumn<int>(
      'play_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastPlayedAtMeta =
      const VerificationMeta('lastPlayedAt');
  @override
  late final GeneratedColumn<String> lastPlayedAt = GeneratedColumn<String>(
      'last_played_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        artists,
        dateWritten,
        timeSig,
        keySig,
        languages,
        notes,
        playCount,
        lastPlayedAt,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notations_table';
  @override
  VerificationContext validateIntegrity(Insertable<NotationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artists')) {
      context.handle(_artistsMeta,
          artists.isAcceptableOrUnknown(data['artists']!, _artistsMeta));
    }
    if (data.containsKey('date_written')) {
      context.handle(
          _dateWrittenMeta,
          dateWritten.isAcceptableOrUnknown(
              data['date_written']!, _dateWrittenMeta));
    }
    if (data.containsKey('time_sig')) {
      context.handle(_timeSigMeta,
          timeSig.isAcceptableOrUnknown(data['time_sig']!, _timeSigMeta));
    }
    if (data.containsKey('key_sig')) {
      context.handle(_keySigMeta,
          keySig.isAcceptableOrUnknown(data['key_sig']!, _keySigMeta));
    }
    if (data.containsKey('languages')) {
      context.handle(_languagesMeta,
          languages.isAcceptableOrUnknown(data['languages']!, _languagesMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('play_count')) {
      context.handle(_playCountMeta,
          playCount.isAcceptableOrUnknown(data['play_count']!, _playCountMeta));
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
          _lastPlayedAtMeta,
          lastPlayedAt.isAcceptableOrUnknown(
              data['last_played_at']!, _lastPlayedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotationRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      artists: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}artists'])!,
      dateWritten: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_written']),
      timeSig: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_sig']),
      keySig: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_sig']),
      languages: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}languages'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      playCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}play_count'])!,
      lastPlayedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_played_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $NotationsTableTable createAlias(String alias) {
    return $NotationsTableTable(attachedDatabase, alias);
  }
}

class NotationRow extends DataClass implements Insertable<NotationRow> {
  /// UUIDv4 generated at the app layer.
  final String id;

  /// Human-readable title for the notation piece.
  final String title;

  /// JSON array of artist name strings, e.g. `["Ravi Shankar"]`.
  final String artists;

  /// ISO 8601 date (YYYY-MM-DD); nullable.
  final String? dateWritten;

  /// Time signature string, e.g. `'4/4'`; nullable.
  final String? timeSig;

  /// Key signature string, e.g. `'C'` or `'Bb minor'`; nullable.
  final String? keySig;

  /// JSON array of language strings, e.g. `["Hindi"]`.
  final String languages;

  /// Free-form personal notes about the notation.
  final String notes;

  /// Number of times the notation has been played.
  final int playCount;

  /// ISO 8601 datetime of last play; nullable.
  final String? lastPlayedAt;

  /// ISO 8601 datetime when the row was created.
  final String createdAt;

  /// ISO 8601 datetime of last update.
  final String updatedAt;

  /// Soft-delete timestamp. NULL means active; non-NULL means deleted.
  final String? deletedAt;
  const NotationRow(
      {required this.id,
      required this.title,
      required this.artists,
      this.dateWritten,
      this.timeSig,
      this.keySig,
      required this.languages,
      required this.notes,
      required this.playCount,
      this.lastPlayedAt,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['artists'] = Variable<String>(artists);
    if (!nullToAbsent || dateWritten != null) {
      map['date_written'] = Variable<String>(dateWritten);
    }
    if (!nullToAbsent || timeSig != null) {
      map['time_sig'] = Variable<String>(timeSig);
    }
    if (!nullToAbsent || keySig != null) {
      map['key_sig'] = Variable<String>(keySig);
    }
    map['languages'] = Variable<String>(languages);
    map['notes'] = Variable<String>(notes);
    map['play_count'] = Variable<int>(playCount);
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<String>(lastPlayedAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  NotationsTableCompanion toCompanion(bool nullToAbsent) {
    return NotationsTableCompanion(
      id: Value(id),
      title: Value(title),
      artists: Value(artists),
      dateWritten: dateWritten == null && nullToAbsent
          ? const Value.absent()
          : Value(dateWritten),
      timeSig: timeSig == null && nullToAbsent
          ? const Value.absent()
          : Value(timeSig),
      keySig:
          keySig == null && nullToAbsent ? const Value.absent() : Value(keySig),
      languages: Value(languages),
      notes: Value(notes),
      playCount: Value(playCount),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory NotationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artists: serializer.fromJson<String>(json['artists']),
      dateWritten: serializer.fromJson<String?>(json['dateWritten']),
      timeSig: serializer.fromJson<String?>(json['timeSig']),
      keySig: serializer.fromJson<String?>(json['keySig']),
      languages: serializer.fromJson<String>(json['languages']),
      notes: serializer.fromJson<String>(json['notes']),
      playCount: serializer.fromJson<int>(json['playCount']),
      lastPlayedAt: serializer.fromJson<String?>(json['lastPlayedAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artists': serializer.toJson<String>(artists),
      'dateWritten': serializer.toJson<String?>(dateWritten),
      'timeSig': serializer.toJson<String?>(timeSig),
      'keySig': serializer.toJson<String?>(keySig),
      'languages': serializer.toJson<String>(languages),
      'notes': serializer.toJson<String>(notes),
      'playCount': serializer.toJson<int>(playCount),
      'lastPlayedAt': serializer.toJson<String?>(lastPlayedAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  NotationRow copyWith(
          {String? id,
          String? title,
          String? artists,
          Value<String?> dateWritten = const Value.absent(),
          Value<String?> timeSig = const Value.absent(),
          Value<String?> keySig = const Value.absent(),
          String? languages,
          String? notes,
          int? playCount,
          Value<String?> lastPlayedAt = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          Value<String?> deletedAt = const Value.absent()}) =>
      NotationRow(
        id: id ?? this.id,
        title: title ?? this.title,
        artists: artists ?? this.artists,
        dateWritten: dateWritten.present ? dateWritten.value : this.dateWritten,
        timeSig: timeSig.present ? timeSig.value : this.timeSig,
        keySig: keySig.present ? keySig.value : this.keySig,
        languages: languages ?? this.languages,
        notes: notes ?? this.notes,
        playCount: playCount ?? this.playCount,
        lastPlayedAt:
            lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  NotationRow copyWithCompanion(NotationsTableCompanion data) {
    return NotationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artists: data.artists.present ? data.artists.value : this.artists,
      dateWritten:
          data.dateWritten.present ? data.dateWritten.value : this.dateWritten,
      timeSig: data.timeSig.present ? data.timeSig.value : this.timeSig,
      keySig: data.keySig.present ? data.keySig.value : this.keySig,
      languages: data.languages.present ? data.languages.value : this.languages,
      notes: data.notes.present ? data.notes.value : this.notes,
      playCount: data.playCount.present ? data.playCount.value : this.playCount,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('dateWritten: $dateWritten, ')
          ..write('timeSig: $timeSig, ')
          ..write('keySig: $keySig, ')
          ..write('languages: $languages, ')
          ..write('notes: $notes, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      artists,
      dateWritten,
      timeSig,
      keySig,
      languages,
      notes,
      playCount,
      lastPlayedAt,
      createdAt,
      updatedAt,
      deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.artists == this.artists &&
          other.dateWritten == this.dateWritten &&
          other.timeSig == this.timeSig &&
          other.keySig == this.keySig &&
          other.languages == this.languages &&
          other.notes == this.notes &&
          other.playCount == this.playCount &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class NotationsTableCompanion extends UpdateCompanion<NotationRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artists;
  final Value<String?> dateWritten;
  final Value<String?> timeSig;
  final Value<String?> keySig;
  final Value<String> languages;
  final Value<String> notes;
  final Value<int> playCount;
  final Value<String?> lastPlayedAt;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const NotationsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artists = const Value.absent(),
    this.dateWritten = const Value.absent(),
    this.timeSig = const Value.absent(),
    this.keySig = const Value.absent(),
    this.languages = const Value.absent(),
    this.notes = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotationsTableCompanion.insert({
    required String id,
    required String title,
    this.artists = const Value.absent(),
    this.dateWritten = const Value.absent(),
    this.timeSig = const Value.absent(),
    this.keySig = const Value.absent(),
    this.languages = const Value.absent(),
    this.notes = const Value.absent(),
    this.playCount = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<NotationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artists,
    Expression<String>? dateWritten,
    Expression<String>? timeSig,
    Expression<String>? keySig,
    Expression<String>? languages,
    Expression<String>? notes,
    Expression<int>? playCount,
    Expression<String>? lastPlayedAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artists != null) 'artists': artists,
      if (dateWritten != null) 'date_written': dateWritten,
      if (timeSig != null) 'time_sig': timeSig,
      if (keySig != null) 'key_sig': keySig,
      if (languages != null) 'languages': languages,
      if (notes != null) 'notes': notes,
      if (playCount != null) 'play_count': playCount,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotationsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? artists,
      Value<String?>? dateWritten,
      Value<String?>? timeSig,
      Value<String?>? keySig,
      Value<String>? languages,
      Value<String>? notes,
      Value<int>? playCount,
      Value<String?>? lastPlayedAt,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? deletedAt,
      Value<int>? rowid}) {
    return NotationsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      dateWritten: dateWritten ?? this.dateWritten,
      timeSig: timeSig ?? this.timeSig,
      keySig: keySig ?? this.keySig,
      languages: languages ?? this.languages,
      notes: notes ?? this.notes,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artists.present) {
      map['artists'] = Variable<String>(artists.value);
    }
    if (dateWritten.present) {
      map['date_written'] = Variable<String>(dateWritten.value);
    }
    if (timeSig.present) {
      map['time_sig'] = Variable<String>(timeSig.value);
    }
    if (keySig.present) {
      map['key_sig'] = Variable<String>(keySig.value);
    }
    if (languages.present) {
      map['languages'] = Variable<String>(languages.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (playCount.present) {
      map['play_count'] = Variable<int>(playCount.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<String>(lastPlayedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotationsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artists: $artists, ')
          ..write('dateWritten: $dateWritten, ')
          ..write('timeSig: $timeSig, ')
          ..write('keySig: $keySig, ')
          ..write('languages: $languages, ')
          ..write('notes: $notes, ')
          ..write('playCount: $playCount, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotationPagesTableTable extends NotationPagesTable
    with TableInfo<$NotationPagesTableTable, NotationPageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotationPagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notationIdMeta =
      const VerificationMeta('notationId');
  @override
  late final GeneratedColumn<String> notationId = GeneratedColumn<String>(
      'notation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notations_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _pageOrderMeta =
      const VerificationMeta('pageOrder');
  @override
  late final GeneratedColumn<int> pageOrder = GeneratedColumn<int>(
      'page_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _renderParamsMeta =
      const VerificationMeta('renderParams');
  @override
  late final GeneratedColumn<String> renderParams = GeneratedColumn<String>(
      'render_params', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, notationId, pageOrder, imagePath, renderParams, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notation_pages_table';
  @override
  VerificationContext validateIntegrity(Insertable<NotationPageRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('notation_id')) {
      context.handle(
          _notationIdMeta,
          notationId.isAcceptableOrUnknown(
              data['notation_id']!, _notationIdMeta));
    } else if (isInserting) {
      context.missing(_notationIdMeta);
    }
    if (data.containsKey('page_order')) {
      context.handle(_pageOrderMeta,
          pageOrder.isAcceptableOrUnknown(data['page_order']!, _pageOrderMeta));
    } else if (isInserting) {
      context.missing(_pageOrderMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('render_params')) {
      context.handle(
          _renderParamsMeta,
          renderParams.isAcceptableOrUnknown(
              data['render_params']!, _renderParamsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {notationId, pageOrder},
      ];
  @override
  NotationPageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotationPageRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      notationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notation_id'])!,
      pageOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_order'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path'])!,
      renderParams: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}render_params'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $NotationPagesTableTable createAlias(String alias) {
    return $NotationPagesTableTable(attachedDatabase, alias);
  }
}

class NotationPageRow extends DataClass implements Insertable<NotationPageRow> {
  /// UUIDv4 generated at the app layer.
  final String id;

  /// Foreign key to the parent [NotationsTable] row.
  final String notationId;

  /// 0-indexed position of this page within the notation.
  final int pageOrder;

  /// Path relative to `getApplicationDocumentsDirectory()`.
  final String imagePath;

  /// Serialised [RenderParams] JSON; non-destructive render settings.
  final String renderParams;

  /// ISO 8601 datetime when the row was created.
  final String createdAt;
  const NotationPageRow(
      {required this.id,
      required this.notationId,
      required this.pageOrder,
      required this.imagePath,
      required this.renderParams,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['notation_id'] = Variable<String>(notationId);
    map['page_order'] = Variable<int>(pageOrder);
    map['image_path'] = Variable<String>(imagePath);
    map['render_params'] = Variable<String>(renderParams);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  NotationPagesTableCompanion toCompanion(bool nullToAbsent) {
    return NotationPagesTableCompanion(
      id: Value(id),
      notationId: Value(notationId),
      pageOrder: Value(pageOrder),
      imagePath: Value(imagePath),
      renderParams: Value(renderParams),
      createdAt: Value(createdAt),
    );
  }

  factory NotationPageRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotationPageRow(
      id: serializer.fromJson<String>(json['id']),
      notationId: serializer.fromJson<String>(json['notationId']),
      pageOrder: serializer.fromJson<int>(json['pageOrder']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      renderParams: serializer.fromJson<String>(json['renderParams']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'notationId': serializer.toJson<String>(notationId),
      'pageOrder': serializer.toJson<int>(pageOrder),
      'imagePath': serializer.toJson<String>(imagePath),
      'renderParams': serializer.toJson<String>(renderParams),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  NotationPageRow copyWith(
          {String? id,
          String? notationId,
          int? pageOrder,
          String? imagePath,
          String? renderParams,
          String? createdAt}) =>
      NotationPageRow(
        id: id ?? this.id,
        notationId: notationId ?? this.notationId,
        pageOrder: pageOrder ?? this.pageOrder,
        imagePath: imagePath ?? this.imagePath,
        renderParams: renderParams ?? this.renderParams,
        createdAt: createdAt ?? this.createdAt,
      );
  NotationPageRow copyWithCompanion(NotationPagesTableCompanion data) {
    return NotationPageRow(
      id: data.id.present ? data.id.value : this.id,
      notationId:
          data.notationId.present ? data.notationId.value : this.notationId,
      pageOrder: data.pageOrder.present ? data.pageOrder.value : this.pageOrder,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      renderParams: data.renderParams.present
          ? data.renderParams.value
          : this.renderParams,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotationPageRow(')
          ..write('id: $id, ')
          ..write('notationId: $notationId, ')
          ..write('pageOrder: $pageOrder, ')
          ..write('imagePath: $imagePath, ')
          ..write('renderParams: $renderParams, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, notationId, pageOrder, imagePath, renderParams, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotationPageRow &&
          other.id == this.id &&
          other.notationId == this.notationId &&
          other.pageOrder == this.pageOrder &&
          other.imagePath == this.imagePath &&
          other.renderParams == this.renderParams &&
          other.createdAt == this.createdAt);
}

class NotationPagesTableCompanion extends UpdateCompanion<NotationPageRow> {
  final Value<String> id;
  final Value<String> notationId;
  final Value<int> pageOrder;
  final Value<String> imagePath;
  final Value<String> renderParams;
  final Value<String> createdAt;
  final Value<int> rowid;
  const NotationPagesTableCompanion({
    this.id = const Value.absent(),
    this.notationId = const Value.absent(),
    this.pageOrder = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.renderParams = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotationPagesTableCompanion.insert({
    required String id,
    required String notationId,
    required int pageOrder,
    required String imagePath,
    this.renderParams = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        notationId = Value(notationId),
        pageOrder = Value(pageOrder),
        imagePath = Value(imagePath),
        createdAt = Value(createdAt);
  static Insertable<NotationPageRow> custom({
    Expression<String>? id,
    Expression<String>? notationId,
    Expression<int>? pageOrder,
    Expression<String>? imagePath,
    Expression<String>? renderParams,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (notationId != null) 'notation_id': notationId,
      if (pageOrder != null) 'page_order': pageOrder,
      if (imagePath != null) 'image_path': imagePath,
      if (renderParams != null) 'render_params': renderParams,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotationPagesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? notationId,
      Value<int>? pageOrder,
      Value<String>? imagePath,
      Value<String>? renderParams,
      Value<String>? createdAt,
      Value<int>? rowid}) {
    return NotationPagesTableCompanion(
      id: id ?? this.id,
      notationId: notationId ?? this.notationId,
      pageOrder: pageOrder ?? this.pageOrder,
      imagePath: imagePath ?? this.imagePath,
      renderParams: renderParams ?? this.renderParams,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (notationId.present) {
      map['notation_id'] = Variable<String>(notationId.value);
    }
    if (pageOrder.present) {
      map['page_order'] = Variable<int>(pageOrder.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (renderParams.present) {
      map['render_params'] = Variable<String>(renderParams.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotationPagesTableCompanion(')
          ..write('id: $id, ')
          ..write('notationId: $notationId, ')
          ..write('pageOrder: $pageOrder, ')
          ..write('imagePath: $imagePath, ')
          ..write('renderParams: $renderParams, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTableTable extends TagsTable
    with TableInfo<$TagsTableTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, colorHex, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags_table';
  @override
  VerificationContext validateIntegrity(Insertable<TagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TagsTableTable createAlias(String alias) {
    return $TagsTableTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  /// UUIDv4 generated at the app layer.
  final String id;

  /// Unique display name of the tag.
  final String name;

  /// Catppuccin hex color string, e.g. `'#f38ba8'`.
  final String colorHex;

  /// ISO 8601 datetime when the row was created.
  final String createdAt;

  /// ISO 8601 datetime of last update.
  final String updatedAt;
  const TagRow(
      {required this.id,
      required this.name,
      required this.colorHex,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  TagsTableCompanion toCompanion(bool nullToAbsent) {
    return TagsTableCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  TagRow copyWith(
          {String? id,
          String? name,
          String? colorHex,
          String? createdAt,
          String? updatedAt}) =>
      TagRow(
        id: id ?? this.id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TagRow copyWithCompanion(TagsTableCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TagsTableCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const TagsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsTableCompanion.insert({
    required String id,
    required String name,
    required String colorHex,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        colorHex = Value(colorHex),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? colorHex,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return TagsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotationTagsTableTable extends NotationTagsTable
    with TableInfo<$NotationTagsTableTable, NotationTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotationTagsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notationIdMeta =
      const VerificationMeta('notationId');
  @override
  late final GeneratedColumn<String> notationId = GeneratedColumn<String>(
      'notation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notations_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
      'tag_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tags_table (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [notationId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notation_tags_table';
  @override
  VerificationContext validateIntegrity(Insertable<NotationTagRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('notation_id')) {
      context.handle(
          _notationIdMeta,
          notationId.isAcceptableOrUnknown(
              data['notation_id']!, _notationIdMeta));
    } else if (isInserting) {
      context.missing(_notationIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
          _tagIdMeta, tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta));
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {notationId, tagId};
  @override
  NotationTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotationTagRow(
      notationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notation_id'])!,
      tagId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_id'])!,
    );
  }

  @override
  $NotationTagsTableTable createAlias(String alias) {
    return $NotationTagsTableTable(attachedDatabase, alias);
  }
}

class NotationTagRow extends DataClass implements Insertable<NotationTagRow> {
  /// Foreign key to [NotationsTable].
  final String notationId;

  /// Foreign key to [TagsTable].
  final String tagId;
  const NotationTagRow({required this.notationId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['notation_id'] = Variable<String>(notationId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  NotationTagsTableCompanion toCompanion(bool nullToAbsent) {
    return NotationTagsTableCompanion(
      notationId: Value(notationId),
      tagId: Value(tagId),
    );
  }

  factory NotationTagRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotationTagRow(
      notationId: serializer.fromJson<String>(json['notationId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notationId': serializer.toJson<String>(notationId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  NotationTagRow copyWith({String? notationId, String? tagId}) =>
      NotationTagRow(
        notationId: notationId ?? this.notationId,
        tagId: tagId ?? this.tagId,
      );
  NotationTagRow copyWithCompanion(NotationTagsTableCompanion data) {
    return NotationTagRow(
      notationId:
          data.notationId.present ? data.notationId.value : this.notationId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotationTagRow(')
          ..write('notationId: $notationId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(notationId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotationTagRow &&
          other.notationId == this.notationId &&
          other.tagId == this.tagId);
}

class NotationTagsTableCompanion extends UpdateCompanion<NotationTagRow> {
  final Value<String> notationId;
  final Value<String> tagId;
  final Value<int> rowid;
  const NotationTagsTableCompanion({
    this.notationId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotationTagsTableCompanion.insert({
    required String notationId,
    required String tagId,
    this.rowid = const Value.absent(),
  })  : notationId = Value(notationId),
        tagId = Value(tagId);
  static Insertable<NotationTagRow> custom({
    Expression<String>? notationId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (notationId != null) 'notation_id': notationId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotationTagsTableCompanion copyWith(
      {Value<String>? notationId, Value<String>? tagId, Value<int>? rowid}) {
    return NotationTagsTableCompanion(
      notationId: notationId ?? this.notationId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notationId.present) {
      map['notation_id'] = Variable<String>(notationId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotationTagsTableCompanion(')
          ..write('notationId: $notationId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstrumentClassesTableTable extends InstrumentClassesTable
    with TableInfo<$InstrumentClassesTableTable, InstrumentClassRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentClassesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instrument_classes_table';
  @override
  VerificationContext validateIntegrity(Insertable<InstrumentClassRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstrumentClassRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentClassRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $InstrumentClassesTableTable createAlias(String alias) {
    return $InstrumentClassesTableTable(attachedDatabase, alias);
  }
}

class InstrumentClassRow extends DataClass
    implements Insertable<InstrumentClassRow> {
  /// UUIDv4 generated at the app layer.
  final String id;

  /// Unique human-readable class name.
  final String name;

  /// ISO 8601 datetime when the row was created.
  final String createdAt;

  /// ISO 8601 datetime of last update.
  final String updatedAt;
  const InstrumentClassRow(
      {required this.id,
      required this.name,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  InstrumentClassesTableCompanion toCompanion(bool nullToAbsent) {
    return InstrumentClassesTableCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InstrumentClassRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentClassRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  InstrumentClassRow copyWith(
          {String? id, String? name, String? createdAt, String? updatedAt}) =>
      InstrumentClassRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  InstrumentClassRow copyWithCompanion(InstrumentClassesTableCompanion data) {
    return InstrumentClassRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentClassRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentClassRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InstrumentClassesTableCompanion
    extends UpdateCompanion<InstrumentClassRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const InstrumentClassesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentClassesTableCompanion.insert({
    required String id,
    required String name,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<InstrumentClassRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentClassesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return InstrumentClassesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentClassesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstrumentInstancesTableTable extends InstrumentInstancesTable
    with TableInfo<$InstrumentInstancesTableTable, InstrumentInstanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstrumentInstancesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _classIdMeta =
      const VerificationMeta('classId');
  @override
  late final GeneratedColumn<String> classId = GeneratedColumn<String>(
      'class_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES instrument_classes_table (id) ON DELETE RESTRICT'));
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
      'brand', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
      'model', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _colorHexMeta =
      const VerificationMeta('colorHex');
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
      'color_hex', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceInrMeta =
      const VerificationMeta('priceInr');
  @override
  late final GeneratedColumn<int> priceInr = GeneratedColumn<int>(
      'price_inr', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        classId,
        brand,
        model,
        colorHex,
        priceInr,
        photoPath,
        notes,
        createdAt,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instrument_instances_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<InstrumentInstanceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('class_id')) {
      context.handle(_classIdMeta,
          classId.isAcceptableOrUnknown(data['class_id']!, _classIdMeta));
    } else if (isInserting) {
      context.missing(_classIdMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
          _brandMeta, brand.isAcceptableOrUnknown(data['brand']!, _brandMeta));
    }
    if (data.containsKey('model')) {
      context.handle(
          _modelMeta, model.isAcceptableOrUnknown(data['model']!, _modelMeta));
    }
    if (data.containsKey('color_hex')) {
      context.handle(_colorHexMeta,
          colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta));
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('price_inr')) {
      context.handle(_priceInrMeta,
          priceInr.isAcceptableOrUnknown(data['price_inr']!, _priceInrMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstrumentInstanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstrumentInstanceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      classId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}class_id'])!,
      brand: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}brand']),
      model: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model']),
      colorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color_hex'])!,
      priceInr: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_inr']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $InstrumentInstancesTableTable createAlias(String alias) {
    return $InstrumentInstancesTableTable(attachedDatabase, alias);
  }
}

class InstrumentInstanceRow extends DataClass
    implements Insertable<InstrumentInstanceRow> {
  /// UUIDv4 generated at the app layer.
  final String id;

  /// Foreign key to [InstrumentClassesTable]. Deletion blocked (RESTRICT).
  final String classId;

  /// Optional brand name; nullable.
  final String? brand;

  /// Optional model name; nullable.
  final String? model;

  /// Catppuccin hex color string for UI display.
  final String colorHex;

  /// Purchase price in INR (integer paise); nullable.
  final int? priceInr;

  /// Relative path to a photo of the instrument; nullable.
  final String? photoPath;

  /// Free-form notes about this instance.
  final String notes;

  /// ISO 8601 datetime when the row was created.
  final String createdAt;

  /// ISO 8601 datetime of last update.
  final String updatedAt;

  /// Soft-delete / archive timestamp. NULL means active.
  final String? deletedAt;
  const InstrumentInstanceRow(
      {required this.id,
      required this.classId,
      this.brand,
      this.model,
      required this.colorHex,
      this.priceInr,
      this.photoPath,
      required this.notes,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['class_id'] = Variable<String>(classId);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['color_hex'] = Variable<String>(colorHex);
    if (!nullToAbsent || priceInr != null) {
      map['price_inr'] = Variable<int>(priceInr);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['notes'] = Variable<String>(notes);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  InstrumentInstancesTableCompanion toCompanion(bool nullToAbsent) {
    return InstrumentInstancesTableCompanion(
      id: Value(id),
      classId: Value(classId),
      brand:
          brand == null && nullToAbsent ? const Value.absent() : Value(brand),
      model:
          model == null && nullToAbsent ? const Value.absent() : Value(model),
      colorHex: Value(colorHex),
      priceInr: priceInr == null && nullToAbsent
          ? const Value.absent()
          : Value(priceInr),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory InstrumentInstanceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstrumentInstanceRow(
      id: serializer.fromJson<String>(json['id']),
      classId: serializer.fromJson<String>(json['classId']),
      brand: serializer.fromJson<String?>(json['brand']),
      model: serializer.fromJson<String?>(json['model']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      priceInr: serializer.fromJson<int?>(json['priceInr']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      notes: serializer.fromJson<String>(json['notes']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'classId': serializer.toJson<String>(classId),
      'brand': serializer.toJson<String?>(brand),
      'model': serializer.toJson<String?>(model),
      'colorHex': serializer.toJson<String>(colorHex),
      'priceInr': serializer.toJson<int?>(priceInr),
      'photoPath': serializer.toJson<String?>(photoPath),
      'notes': serializer.toJson<String>(notes),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  InstrumentInstanceRow copyWith(
          {String? id,
          String? classId,
          Value<String?> brand = const Value.absent(),
          Value<String?> model = const Value.absent(),
          String? colorHex,
          Value<int?> priceInr = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
          String? notes,
          String? createdAt,
          String? updatedAt,
          Value<String?> deletedAt = const Value.absent()}) =>
      InstrumentInstanceRow(
        id: id ?? this.id,
        classId: classId ?? this.classId,
        brand: brand.present ? brand.value : this.brand,
        model: model.present ? model.value : this.model,
        colorHex: colorHex ?? this.colorHex,
        priceInr: priceInr.present ? priceInr.value : this.priceInr,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  InstrumentInstanceRow copyWithCompanion(
      InstrumentInstancesTableCompanion data) {
    return InstrumentInstanceRow(
      id: data.id.present ? data.id.value : this.id,
      classId: data.classId.present ? data.classId.value : this.classId,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      priceInr: data.priceInr.present ? data.priceInr.value : this.priceInr,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentInstanceRow(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('colorHex: $colorHex, ')
          ..write('priceInr: $priceInr, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, classId, brand, model, colorHex, priceInr,
      photoPath, notes, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstrumentInstanceRow &&
          other.id == this.id &&
          other.classId == this.classId &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.colorHex == this.colorHex &&
          other.priceInr == this.priceInr &&
          other.photoPath == this.photoPath &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class InstrumentInstancesTableCompanion
    extends UpdateCompanion<InstrumentInstanceRow> {
  final Value<String> id;
  final Value<String> classId;
  final Value<String?> brand;
  final Value<String?> model;
  final Value<String> colorHex;
  final Value<int?> priceInr;
  final Value<String?> photoPath;
  final Value<String> notes;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const InstrumentInstancesTableCompanion({
    this.id = const Value.absent(),
    this.classId = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.priceInr = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstrumentInstancesTableCompanion.insert({
    required String id,
    required String classId,
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    required String colorHex,
    this.priceInr = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.notes = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        classId = Value(classId),
        colorHex = Value(colorHex),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<InstrumentInstanceRow> custom({
    Expression<String>? id,
    Expression<String>? classId,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<String>? colorHex,
    Expression<int>? priceInr,
    Expression<String>? photoPath,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (classId != null) 'class_id': classId,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (colorHex != null) 'color_hex': colorHex,
      if (priceInr != null) 'price_inr': priceInr,
      if (photoPath != null) 'photo_path': photoPath,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstrumentInstancesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? classId,
      Value<String?>? brand,
      Value<String?>? model,
      Value<String>? colorHex,
      Value<int?>? priceInr,
      Value<String?>? photoPath,
      Value<String>? notes,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String?>? deletedAt,
      Value<int>? rowid}) {
    return InstrumentInstancesTableCompanion(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      colorHex: colorHex ?? this.colorHex,
      priceInr: priceInr ?? this.priceInr,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (classId.present) {
      map['class_id'] = Variable<String>(classId.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (priceInr.present) {
      map['price_inr'] = Variable<int>(priceInr.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstrumentInstancesTableCompanion(')
          ..write('id: $id, ')
          ..write('classId: $classId, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('colorHex: $colorHex, ')
          ..write('priceInr: $priceInr, ')
          ..write('photoPath: $photoPath, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotationInstrumentsTableTable extends NotationInstrumentsTable
    with TableInfo<$NotationInstrumentsTableTable, NotationInstrumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotationInstrumentsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notationIdMeta =
      const VerificationMeta('notationId');
  @override
  late final GeneratedColumn<String> notationId = GeneratedColumn<String>(
      'notation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notations_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _instanceIdMeta =
      const VerificationMeta('instanceId');
  @override
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
      'instance_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES instrument_instances_table (id) ON DELETE RESTRICT'));
  @override
  List<GeneratedColumn> get $columns => [notationId, instanceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notation_instruments_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<NotationInstrumentRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('notation_id')) {
      context.handle(
          _notationIdMeta,
          notationId.isAcceptableOrUnknown(
              data['notation_id']!, _notationIdMeta));
    } else if (isInserting) {
      context.missing(_notationIdMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
          _instanceIdMeta,
          instanceId.isAcceptableOrUnknown(
              data['instance_id']!, _instanceIdMeta));
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {notationId, instanceId};
  @override
  NotationInstrumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotationInstrumentRow(
      notationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notation_id'])!,
      instanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}instance_id'])!,
    );
  }

  @override
  $NotationInstrumentsTableTable createAlias(String alias) {
    return $NotationInstrumentsTableTable(attachedDatabase, alias);
  }
}

class NotationInstrumentRow extends DataClass
    implements Insertable<NotationInstrumentRow> {
  /// Foreign key to [NotationsTable]. Cascade on notation delete.
  final String notationId;

  /// Foreign key to [InstrumentInstancesTable]. Restricted.
  final String instanceId;
  const NotationInstrumentRow(
      {required this.notationId, required this.instanceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['notation_id'] = Variable<String>(notationId);
    map['instance_id'] = Variable<String>(instanceId);
    return map;
  }

  NotationInstrumentsTableCompanion toCompanion(bool nullToAbsent) {
    return NotationInstrumentsTableCompanion(
      notationId: Value(notationId),
      instanceId: Value(instanceId),
    );
  }

  factory NotationInstrumentRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotationInstrumentRow(
      notationId: serializer.fromJson<String>(json['notationId']),
      instanceId: serializer.fromJson<String>(json['instanceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notationId': serializer.toJson<String>(notationId),
      'instanceId': serializer.toJson<String>(instanceId),
    };
  }

  NotationInstrumentRow copyWith({String? notationId, String? instanceId}) =>
      NotationInstrumentRow(
        notationId: notationId ?? this.notationId,
        instanceId: instanceId ?? this.instanceId,
      );
  NotationInstrumentRow copyWithCompanion(
      NotationInstrumentsTableCompanion data) {
    return NotationInstrumentRow(
      notationId:
          data.notationId.present ? data.notationId.value : this.notationId,
      instanceId:
          data.instanceId.present ? data.instanceId.value : this.instanceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotationInstrumentRow(')
          ..write('notationId: $notationId, ')
          ..write('instanceId: $instanceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(notationId, instanceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotationInstrumentRow &&
          other.notationId == this.notationId &&
          other.instanceId == this.instanceId);
}

class NotationInstrumentsTableCompanion
    extends UpdateCompanion<NotationInstrumentRow> {
  final Value<String> notationId;
  final Value<String> instanceId;
  final Value<int> rowid;
  const NotationInstrumentsTableCompanion({
    this.notationId = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotationInstrumentsTableCompanion.insert({
    required String notationId,
    required String instanceId,
    this.rowid = const Value.absent(),
  })  : notationId = Value(notationId),
        instanceId = Value(instanceId);
  static Insertable<NotationInstrumentRow> custom({
    Expression<String>? notationId,
    Expression<String>? instanceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (notationId != null) 'notation_id': notationId,
      if (instanceId != null) 'instance_id': instanceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotationInstrumentsTableCompanion copyWith(
      {Value<String>? notationId,
      Value<String>? instanceId,
      Value<int>? rowid}) {
    return NotationInstrumentsTableCompanion(
      notationId: notationId ?? this.notationId,
      instanceId: instanceId ?? this.instanceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notationId.present) {
      map['notation_id'] = Variable<String>(notationId.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotationInstrumentsTableCompanion(')
          ..write('notationId: $notationId, ')
          ..write('instanceId: $instanceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomFieldDefinitionsTableTable extends CustomFieldDefinitionsTable
    with
        TableInfo<$CustomFieldDefinitionsTableTable, CustomFieldDefinitionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomFieldDefinitionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _keyNameMeta =
      const VerificationMeta('keyName');
  @override
  late final GeneratedColumn<String> keyName = GeneratedColumn<String>(
      'key_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _fieldTypeMeta =
      const VerificationMeta('fieldType');
  @override
  late final GeneratedColumn<String> fieldType = GeneratedColumn<String>(
      'field_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, keyName, fieldType, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_field_definitions_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CustomFieldDefinitionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('key_name')) {
      context.handle(_keyNameMeta,
          keyName.isAcceptableOrUnknown(data['key_name']!, _keyNameMeta));
    } else if (isInserting) {
      context.missing(_keyNameMeta);
    }
    if (data.containsKey('field_type')) {
      context.handle(_fieldTypeMeta,
          fieldType.isAcceptableOrUnknown(data['field_type']!, _fieldTypeMeta));
    } else if (isInserting) {
      context.missing(_fieldTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFieldDefinitionRow map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFieldDefinitionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      keyName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key_name'])!,
      fieldType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_type'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CustomFieldDefinitionsTableTable createAlias(String alias) {
    return $CustomFieldDefinitionsTableTable(attachedDatabase, alias);
  }
}

class CustomFieldDefinitionRow extends DataClass
    implements Insertable<CustomFieldDefinitionRow> {
  /// UUIDv4 generated at the app layer.
  final String id;

  /// Unique machine-readable key for this field.
  final String keyName;

  /// Type of the field: one of `text`, `number`, `date`, `boolean`.
  final String fieldType;

  /// ISO 8601 datetime when the row was created.
  final String createdAt;

  /// ISO 8601 datetime of last update.
  final String updatedAt;
  const CustomFieldDefinitionRow(
      {required this.id,
      required this.keyName,
      required this.fieldType,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['key_name'] = Variable<String>(keyName);
    map['field_type'] = Variable<String>(fieldType);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CustomFieldDefinitionsTableCompanion toCompanion(bool nullToAbsent) {
    return CustomFieldDefinitionsTableCompanion(
      id: Value(id),
      keyName: Value(keyName),
      fieldType: Value(fieldType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CustomFieldDefinitionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFieldDefinitionRow(
      id: serializer.fromJson<String>(json['id']),
      keyName: serializer.fromJson<String>(json['keyName']),
      fieldType: serializer.fromJson<String>(json['fieldType']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'keyName': serializer.toJson<String>(keyName),
      'fieldType': serializer.toJson<String>(fieldType),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  CustomFieldDefinitionRow copyWith(
          {String? id,
          String? keyName,
          String? fieldType,
          String? createdAt,
          String? updatedAt}) =>
      CustomFieldDefinitionRow(
        id: id ?? this.id,
        keyName: keyName ?? this.keyName,
        fieldType: fieldType ?? this.fieldType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CustomFieldDefinitionRow copyWithCompanion(
      CustomFieldDefinitionsTableCompanion data) {
    return CustomFieldDefinitionRow(
      id: data.id.present ? data.id.value : this.id,
      keyName: data.keyName.present ? data.keyName.value : this.keyName,
      fieldType: data.fieldType.present ? data.fieldType.value : this.fieldType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldDefinitionRow(')
          ..write('id: $id, ')
          ..write('keyName: $keyName, ')
          ..write('fieldType: $fieldType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, keyName, fieldType, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFieldDefinitionRow &&
          other.id == this.id &&
          other.keyName == this.keyName &&
          other.fieldType == this.fieldType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CustomFieldDefinitionsTableCompanion
    extends UpdateCompanion<CustomFieldDefinitionRow> {
  final Value<String> id;
  final Value<String> keyName;
  final Value<String> fieldType;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CustomFieldDefinitionsTableCompanion({
    this.id = const Value.absent(),
    this.keyName = const Value.absent(),
    this.fieldType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomFieldDefinitionsTableCompanion.insert({
    required String id,
    required String keyName,
    required String fieldType,
    required String createdAt,
    required String updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        keyName = Value(keyName),
        fieldType = Value(fieldType),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CustomFieldDefinitionRow> custom({
    Expression<String>? id,
    Expression<String>? keyName,
    Expression<String>? fieldType,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (keyName != null) 'key_name': keyName,
      if (fieldType != null) 'field_type': fieldType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomFieldDefinitionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? keyName,
      Value<String>? fieldType,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<int>? rowid}) {
    return CustomFieldDefinitionsTableCompanion(
      id: id ?? this.id,
      keyName: keyName ?? this.keyName,
      fieldType: fieldType ?? this.fieldType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (keyName.present) {
      map['key_name'] = Variable<String>(keyName.value);
    }
    if (fieldType.present) {
      map['field_type'] = Variable<String>(fieldType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFieldDefinitionsTableCompanion(')
          ..write('id: $id, ')
          ..write('keyName: $keyName, ')
          ..write('fieldType: $fieldType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotationCustomFieldsTableTable extends NotationCustomFieldsTable
    with TableInfo<$NotationCustomFieldsTableTable, NotationCustomFieldRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotationCustomFieldsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _notationIdMeta =
      const VerificationMeta('notationId');
  @override
  late final GeneratedColumn<String> notationId = GeneratedColumn<String>(
      'notation_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES notations_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _definitionIdMeta =
      const VerificationMeta('definitionId');
  @override
  late final GeneratedColumn<String> definitionId = GeneratedColumn<String>(
      'definition_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES custom_field_definitions_table (id) ON DELETE CASCADE'));
  static const VerificationMeta _valueTextMeta =
      const VerificationMeta('valueText');
  @override
  late final GeneratedColumn<String> valueText = GeneratedColumn<String>(
      'value_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueNumberMeta =
      const VerificationMeta('valueNumber');
  @override
  late final GeneratedColumn<double> valueNumber = GeneratedColumn<double>(
      'value_number', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _valueDateMeta =
      const VerificationMeta('valueDate');
  @override
  late final GeneratedColumn<String> valueDate = GeneratedColumn<String>(
      'value_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _valueBooleanMeta =
      const VerificationMeta('valueBoolean');
  @override
  late final GeneratedColumn<int> valueBoolean = GeneratedColumn<int>(
      'value_boolean', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        notationId,
        definitionId,
        valueText,
        valueNumber,
        valueDate,
        valueBoolean
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notation_custom_fields_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<NotationCustomFieldRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('notation_id')) {
      context.handle(
          _notationIdMeta,
          notationId.isAcceptableOrUnknown(
              data['notation_id']!, _notationIdMeta));
    } else if (isInserting) {
      context.missing(_notationIdMeta);
    }
    if (data.containsKey('definition_id')) {
      context.handle(
          _definitionIdMeta,
          definitionId.isAcceptableOrUnknown(
              data['definition_id']!, _definitionIdMeta));
    } else if (isInserting) {
      context.missing(_definitionIdMeta);
    }
    if (data.containsKey('value_text')) {
      context.handle(_valueTextMeta,
          valueText.isAcceptableOrUnknown(data['value_text']!, _valueTextMeta));
    }
    if (data.containsKey('value_number')) {
      context.handle(
          _valueNumberMeta,
          valueNumber.isAcceptableOrUnknown(
              data['value_number']!, _valueNumberMeta));
    }
    if (data.containsKey('value_date')) {
      context.handle(_valueDateMeta,
          valueDate.isAcceptableOrUnknown(data['value_date']!, _valueDateMeta));
    }
    if (data.containsKey('value_boolean')) {
      context.handle(
          _valueBooleanMeta,
          valueBoolean.isAcceptableOrUnknown(
              data['value_boolean']!, _valueBooleanMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {notationId, definitionId};
  @override
  NotationCustomFieldRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotationCustomFieldRow(
      notationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notation_id'])!,
      definitionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}definition_id'])!,
      valueText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_text']),
      valueNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}value_number']),
      valueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value_date']),
      valueBoolean: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}value_boolean']),
    );
  }

  @override
  $NotationCustomFieldsTableTable createAlias(String alias) {
    return $NotationCustomFieldsTableTable(attachedDatabase, alias);
  }
}

class NotationCustomFieldRow extends DataClass
    implements Insertable<NotationCustomFieldRow> {
  /// Foreign key to [NotationsTable]. Cascade on notation delete.
  final String notationId;

  /// Foreign key to [CustomFieldDefinitionsTable]. Cascade on definition
  /// delete.
  final String definitionId;

  /// Value column for `field_type = 'text'`; nullable.
  final String? valueText;

  /// Value column for `field_type = 'number'`; nullable.
  final double? valueNumber;

  /// ISO 8601 date value for `field_type = 'date'`; nullable.
  final String? valueDate;

  /// 0 or 1 boolean value for `field_type = 'boolean'`; nullable.
  final int? valueBoolean;
  const NotationCustomFieldRow(
      {required this.notationId,
      required this.definitionId,
      this.valueText,
      this.valueNumber,
      this.valueDate,
      this.valueBoolean});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['notation_id'] = Variable<String>(notationId);
    map['definition_id'] = Variable<String>(definitionId);
    if (!nullToAbsent || valueText != null) {
      map['value_text'] = Variable<String>(valueText);
    }
    if (!nullToAbsent || valueNumber != null) {
      map['value_number'] = Variable<double>(valueNumber);
    }
    if (!nullToAbsent || valueDate != null) {
      map['value_date'] = Variable<String>(valueDate);
    }
    if (!nullToAbsent || valueBoolean != null) {
      map['value_boolean'] = Variable<int>(valueBoolean);
    }
    return map;
  }

  NotationCustomFieldsTableCompanion toCompanion(bool nullToAbsent) {
    return NotationCustomFieldsTableCompanion(
      notationId: Value(notationId),
      definitionId: Value(definitionId),
      valueText: valueText == null && nullToAbsent
          ? const Value.absent()
          : Value(valueText),
      valueNumber: valueNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(valueNumber),
      valueDate: valueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(valueDate),
      valueBoolean: valueBoolean == null && nullToAbsent
          ? const Value.absent()
          : Value(valueBoolean),
    );
  }

  factory NotationCustomFieldRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotationCustomFieldRow(
      notationId: serializer.fromJson<String>(json['notationId']),
      definitionId: serializer.fromJson<String>(json['definitionId']),
      valueText: serializer.fromJson<String?>(json['valueText']),
      valueNumber: serializer.fromJson<double?>(json['valueNumber']),
      valueDate: serializer.fromJson<String?>(json['valueDate']),
      valueBoolean: serializer.fromJson<int?>(json['valueBoolean']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'notationId': serializer.toJson<String>(notationId),
      'definitionId': serializer.toJson<String>(definitionId),
      'valueText': serializer.toJson<String?>(valueText),
      'valueNumber': serializer.toJson<double?>(valueNumber),
      'valueDate': serializer.toJson<String?>(valueDate),
      'valueBoolean': serializer.toJson<int?>(valueBoolean),
    };
  }

  NotationCustomFieldRow copyWith(
          {String? notationId,
          String? definitionId,
          Value<String?> valueText = const Value.absent(),
          Value<double?> valueNumber = const Value.absent(),
          Value<String?> valueDate = const Value.absent(),
          Value<int?> valueBoolean = const Value.absent()}) =>
      NotationCustomFieldRow(
        notationId: notationId ?? this.notationId,
        definitionId: definitionId ?? this.definitionId,
        valueText: valueText.present ? valueText.value : this.valueText,
        valueNumber: valueNumber.present ? valueNumber.value : this.valueNumber,
        valueDate: valueDate.present ? valueDate.value : this.valueDate,
        valueBoolean:
            valueBoolean.present ? valueBoolean.value : this.valueBoolean,
      );
  NotationCustomFieldRow copyWithCompanion(
      NotationCustomFieldsTableCompanion data) {
    return NotationCustomFieldRow(
      notationId:
          data.notationId.present ? data.notationId.value : this.notationId,
      definitionId: data.definitionId.present
          ? data.definitionId.value
          : this.definitionId,
      valueText: data.valueText.present ? data.valueText.value : this.valueText,
      valueNumber:
          data.valueNumber.present ? data.valueNumber.value : this.valueNumber,
      valueDate: data.valueDate.present ? data.valueDate.value : this.valueDate,
      valueBoolean: data.valueBoolean.present
          ? data.valueBoolean.value
          : this.valueBoolean,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotationCustomFieldRow(')
          ..write('notationId: $notationId, ')
          ..write('definitionId: $definitionId, ')
          ..write('valueText: $valueText, ')
          ..write('valueNumber: $valueNumber, ')
          ..write('valueDate: $valueDate, ')
          ..write('valueBoolean: $valueBoolean')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(notationId, definitionId, valueText,
      valueNumber, valueDate, valueBoolean);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotationCustomFieldRow &&
          other.notationId == this.notationId &&
          other.definitionId == this.definitionId &&
          other.valueText == this.valueText &&
          other.valueNumber == this.valueNumber &&
          other.valueDate == this.valueDate &&
          other.valueBoolean == this.valueBoolean);
}

class NotationCustomFieldsTableCompanion
    extends UpdateCompanion<NotationCustomFieldRow> {
  final Value<String> notationId;
  final Value<String> definitionId;
  final Value<String?> valueText;
  final Value<double?> valueNumber;
  final Value<String?> valueDate;
  final Value<int?> valueBoolean;
  final Value<int> rowid;
  const NotationCustomFieldsTableCompanion({
    this.notationId = const Value.absent(),
    this.definitionId = const Value.absent(),
    this.valueText = const Value.absent(),
    this.valueNumber = const Value.absent(),
    this.valueDate = const Value.absent(),
    this.valueBoolean = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotationCustomFieldsTableCompanion.insert({
    required String notationId,
    required String definitionId,
    this.valueText = const Value.absent(),
    this.valueNumber = const Value.absent(),
    this.valueDate = const Value.absent(),
    this.valueBoolean = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : notationId = Value(notationId),
        definitionId = Value(definitionId);
  static Insertable<NotationCustomFieldRow> custom({
    Expression<String>? notationId,
    Expression<String>? definitionId,
    Expression<String>? valueText,
    Expression<double>? valueNumber,
    Expression<String>? valueDate,
    Expression<int>? valueBoolean,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (notationId != null) 'notation_id': notationId,
      if (definitionId != null) 'definition_id': definitionId,
      if (valueText != null) 'value_text': valueText,
      if (valueNumber != null) 'value_number': valueNumber,
      if (valueDate != null) 'value_date': valueDate,
      if (valueBoolean != null) 'value_boolean': valueBoolean,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotationCustomFieldsTableCompanion copyWith(
      {Value<String>? notationId,
      Value<String>? definitionId,
      Value<String?>? valueText,
      Value<double?>? valueNumber,
      Value<String?>? valueDate,
      Value<int?>? valueBoolean,
      Value<int>? rowid}) {
    return NotationCustomFieldsTableCompanion(
      notationId: notationId ?? this.notationId,
      definitionId: definitionId ?? this.definitionId,
      valueText: valueText ?? this.valueText,
      valueNumber: valueNumber ?? this.valueNumber,
      valueDate: valueDate ?? this.valueDate,
      valueBoolean: valueBoolean ?? this.valueBoolean,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (notationId.present) {
      map['notation_id'] = Variable<String>(notationId.value);
    }
    if (definitionId.present) {
      map['definition_id'] = Variable<String>(definitionId.value);
    }
    if (valueText.present) {
      map['value_text'] = Variable<String>(valueText.value);
    }
    if (valueNumber.present) {
      map['value_number'] = Variable<double>(valueNumber.value);
    }
    if (valueDate.present) {
      map['value_date'] = Variable<String>(valueDate.value);
    }
    if (valueBoolean.present) {
      map['value_boolean'] = Variable<int>(valueBoolean.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotationCustomFieldsTableCompanion(')
          ..write('notationId: $notationId, ')
          ..write('definitionId: $definitionId, ')
          ..write('valueText: $valueText, ')
          ..write('valueNumber: $valueNumber, ')
          ..write('valueDate: $valueDate, ')
          ..write('valueBoolean: $valueBoolean, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('Musician'));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _colorSchemeModeMeta =
      const VerificationMeta('colorSchemeMode');
  @override
  late final GeneratedColumn<String> colorSchemeMode = GeneratedColumn<String>(
      'color_scheme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('catppuccin'));
  static const VerificationMeta _seedColorMeta =
      const VerificationMeta('seedColor');
  @override
  late final GeneratedColumn<String> seedColor = GeneratedColumn<String>(
      'seed_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _defaultSortMeta =
      const VerificationMeta('defaultSort');
  @override
  late final GeneratedColumn<String> defaultSort = GeneratedColumn<String>(
      'default_sort', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('created_at_desc'));
  static const VerificationMeta _defaultViewMeta =
      const VerificationMeta('defaultView');
  @override
  late final GeneratedColumn<String> defaultView = GeneratedColumn<String>(
      'default_view', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('list'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userName,
        themeMode,
        colorSchemeMode,
        seedColor,
        defaultSort,
        defaultView
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences_table';
  @override
  VerificationContext validateIntegrity(Insertable<UserPreferencesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('color_scheme_mode')) {
      context.handle(
          _colorSchemeModeMeta,
          colorSchemeMode.isAcceptableOrUnknown(
              data['color_scheme_mode']!, _colorSchemeModeMeta));
    }
    if (data.containsKey('seed_color')) {
      context.handle(_seedColorMeta,
          seedColor.isAcceptableOrUnknown(data['seed_color']!, _seedColorMeta));
    }
    if (data.containsKey('default_sort')) {
      context.handle(
          _defaultSortMeta,
          defaultSort.isAcceptableOrUnknown(
              data['default_sort']!, _defaultSortMeta));
    }
    if (data.containsKey('default_view')) {
      context.handle(
          _defaultViewMeta,
          defaultView.isAcceptableOrUnknown(
              data['default_view']!, _defaultViewMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPreferencesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      colorSchemeMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}color_scheme_mode'])!,
      seedColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seed_color']),
      defaultSort: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_sort'])!,
      defaultView: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_view'])!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesRow extends DataClass
    implements Insertable<UserPreferencesRow> {
  /// Always 1 — singleton enforced by CHECK constraint and PRIMARY KEY.
  ///
  /// [withDefault] of `1` means the column is optional in companions; callers
  /// that omit [id] automatically get the correct singleton value.
  final int id;

  /// Display name shown in the app.
  final String userName;

  /// Theme mode: `'light'`, `'dark'`, or `'system'`.
  final String themeMode;

  /// Color scheme source: `'catppuccin'` or `'monet'`.
  final String colorSchemeMode;

  /// Catppuccin hex used when [colorSchemeMode] is `'catppuccin'`; nullable.
  final String? seedColor;

  /// Default sort order for the notation library.
  final String defaultSort;

  /// Default library view: `'list'` (grid deferred to v2).
  final String defaultView;
  const UserPreferencesRow(
      {required this.id,
      required this.userName,
      required this.themeMode,
      required this.colorSchemeMode,
      this.seedColor,
      required this.defaultSort,
      required this.defaultView});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_name'] = Variable<String>(userName);
    map['theme_mode'] = Variable<String>(themeMode);
    map['color_scheme_mode'] = Variable<String>(colorSchemeMode);
    if (!nullToAbsent || seedColor != null) {
      map['seed_color'] = Variable<String>(seedColor);
    }
    map['default_sort'] = Variable<String>(defaultSort);
    map['default_view'] = Variable<String>(defaultView);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      id: Value(id),
      userName: Value(userName),
      themeMode: Value(themeMode),
      colorSchemeMode: Value(colorSchemeMode),
      seedColor: seedColor == null && nullToAbsent
          ? const Value.absent()
          : Value(seedColor),
      defaultSort: Value(defaultSort),
      defaultView: Value(defaultView),
    );
  }

  factory UserPreferencesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesRow(
      id: serializer.fromJson<int>(json['id']),
      userName: serializer.fromJson<String>(json['userName']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      colorSchemeMode: serializer.fromJson<String>(json['colorSchemeMode']),
      seedColor: serializer.fromJson<String?>(json['seedColor']),
      defaultSort: serializer.fromJson<String>(json['defaultSort']),
      defaultView: serializer.fromJson<String>(json['defaultView']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userName': serializer.toJson<String>(userName),
      'themeMode': serializer.toJson<String>(themeMode),
      'colorSchemeMode': serializer.toJson<String>(colorSchemeMode),
      'seedColor': serializer.toJson<String?>(seedColor),
      'defaultSort': serializer.toJson<String>(defaultSort),
      'defaultView': serializer.toJson<String>(defaultView),
    };
  }

  UserPreferencesRow copyWith(
          {int? id,
          String? userName,
          String? themeMode,
          String? colorSchemeMode,
          Value<String?> seedColor = const Value.absent(),
          String? defaultSort,
          String? defaultView}) =>
      UserPreferencesRow(
        id: id ?? this.id,
        userName: userName ?? this.userName,
        themeMode: themeMode ?? this.themeMode,
        colorSchemeMode: colorSchemeMode ?? this.colorSchemeMode,
        seedColor: seedColor.present ? seedColor.value : this.seedColor,
        defaultSort: defaultSort ?? this.defaultSort,
        defaultView: defaultView ?? this.defaultView,
      );
  UserPreferencesRow copyWithCompanion(UserPreferencesTableCompanion data) {
    return UserPreferencesRow(
      id: data.id.present ? data.id.value : this.id,
      userName: data.userName.present ? data.userName.value : this.userName,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      colorSchemeMode: data.colorSchemeMode.present
          ? data.colorSchemeMode.value
          : this.colorSchemeMode,
      seedColor: data.seedColor.present ? data.seedColor.value : this.seedColor,
      defaultSort:
          data.defaultSort.present ? data.defaultSort.value : this.defaultSort,
      defaultView:
          data.defaultView.present ? data.defaultView.value : this.defaultView,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesRow(')
          ..write('id: $id, ')
          ..write('userName: $userName, ')
          ..write('themeMode: $themeMode, ')
          ..write('colorSchemeMode: $colorSchemeMode, ')
          ..write('seedColor: $seedColor, ')
          ..write('defaultSort: $defaultSort, ')
          ..write('defaultView: $defaultView')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userName, themeMode, colorSchemeMode,
      seedColor, defaultSort, defaultView);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesRow &&
          other.id == this.id &&
          other.userName == this.userName &&
          other.themeMode == this.themeMode &&
          other.colorSchemeMode == this.colorSchemeMode &&
          other.seedColor == this.seedColor &&
          other.defaultSort == this.defaultSort &&
          other.defaultView == this.defaultView);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesRow> {
  final Value<int> id;
  final Value<String> userName;
  final Value<String> themeMode;
  final Value<String> colorSchemeMode;
  final Value<String?> seedColor;
  final Value<String> defaultSort;
  final Value<String> defaultView;
  const UserPreferencesTableCompanion({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.colorSchemeMode = const Value.absent(),
    this.seedColor = const Value.absent(),
    this.defaultSort = const Value.absent(),
    this.defaultView = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    this.id = const Value.absent(),
    this.userName = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.colorSchemeMode = const Value.absent(),
    this.seedColor = const Value.absent(),
    this.defaultSort = const Value.absent(),
    this.defaultView = const Value.absent(),
  });
  static Insertable<UserPreferencesRow> custom({
    Expression<int>? id,
    Expression<String>? userName,
    Expression<String>? themeMode,
    Expression<String>? colorSchemeMode,
    Expression<String>? seedColor,
    Expression<String>? defaultSort,
    Expression<String>? defaultView,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userName != null) 'user_name': userName,
      if (themeMode != null) 'theme_mode': themeMode,
      if (colorSchemeMode != null) 'color_scheme_mode': colorSchemeMode,
      if (seedColor != null) 'seed_color': seedColor,
      if (defaultSort != null) 'default_sort': defaultSort,
      if (defaultView != null) 'default_view': defaultView,
    });
  }

  UserPreferencesTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? userName,
      Value<String>? themeMode,
      Value<String>? colorSchemeMode,
      Value<String?>? seedColor,
      Value<String>? defaultSort,
      Value<String>? defaultView}) {
    return UserPreferencesTableCompanion(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      themeMode: themeMode ?? this.themeMode,
      colorSchemeMode: colorSchemeMode ?? this.colorSchemeMode,
      seedColor: seedColor ?? this.seedColor,
      defaultSort: defaultSort ?? this.defaultSort,
      defaultView: defaultView ?? this.defaultView,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (colorSchemeMode.present) {
      map['color_scheme_mode'] = Variable<String>(colorSchemeMode.value);
    }
    if (seedColor.present) {
      map['seed_color'] = Variable<String>(seedColor.value);
    }
    if (defaultSort.present) {
      map['default_sort'] = Variable<String>(defaultSort.value);
    }
    if (defaultView.present) {
      map['default_view'] = Variable<String>(defaultView.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('userName: $userName, ')
          ..write('themeMode: $themeMode, ')
          ..write('colorSchemeMode: $colorSchemeMode, ')
          ..write('seedColor: $seedColor, ')
          ..write('defaultSort: $defaultSort, ')
          ..write('defaultView: $defaultView')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotationsTableTable notationsTable = $NotationsTableTable(this);
  late final $NotationPagesTableTable notationPagesTable =
      $NotationPagesTableTable(this);
  late final $TagsTableTable tagsTable = $TagsTableTable(this);
  late final $NotationTagsTableTable notationTagsTable =
      $NotationTagsTableTable(this);
  late final $InstrumentClassesTableTable instrumentClassesTable =
      $InstrumentClassesTableTable(this);
  late final $InstrumentInstancesTableTable instrumentInstancesTable =
      $InstrumentInstancesTableTable(this);
  late final $NotationInstrumentsTableTable notationInstrumentsTable =
      $NotationInstrumentsTableTable(this);
  late final $CustomFieldDefinitionsTableTable customFieldDefinitionsTable =
      $CustomFieldDefinitionsTableTable(this);
  late final $NotationCustomFieldsTableTable notationCustomFieldsTable =
      $NotationCustomFieldsTableTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  late final NotationDao notationDao = NotationDao(this as AppDatabase);
  late final NotationPageDao notationPageDao =
      NotationPageDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final NotationTagDao notationTagDao =
      NotationTagDao(this as AppDatabase);
  late final InstrumentDao instrumentDao = InstrumentDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        notationsTable,
        notationPagesTable,
        tagsTable,
        notationTagsTable,
        instrumentClassesTable,
        instrumentInstancesTable,
        notationInstrumentsTable,
        customFieldDefinitionsTable,
        notationCustomFieldsTable,
        userPreferencesTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('notations_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('notation_pages_table', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('notations_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('notation_tags_table', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tags_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('notation_tags_table', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('notations_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('notation_instruments_table',
                  kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('notations_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('notation_custom_fields_table',
                  kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('custom_field_definitions_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('notation_custom_fields_table',
                  kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$NotationsTableTableCreateCompanionBuilder = NotationsTableCompanion
    Function({
  required String id,
  required String title,
  Value<String> artists,
  Value<String?> dateWritten,
  Value<String?> timeSig,
  Value<String?> keySig,
  Value<String> languages,
  Value<String> notes,
  Value<int> playCount,
  Value<String?> lastPlayedAt,
  required String createdAt,
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$NotationsTableTableUpdateCompanionBuilder = NotationsTableCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String> artists,
  Value<String?> dateWritten,
  Value<String?> timeSig,
  Value<String?> keySig,
  Value<String> languages,
  Value<String> notes,
  Value<int> playCount,
  Value<String?> lastPlayedAt,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$NotationsTableTableReferences
    extends BaseReferences<_$AppDatabase, $NotationsTableTable, NotationRow> {
  $$NotationsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotationPagesTableTable, List<NotationPageRow>>
      _notationPagesTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.notationPagesTable,
              aliasName: $_aliasNameGenerator(
                  db.notationsTable.id, db.notationPagesTable.notationId));

  $$NotationPagesTableTableProcessedTableManager get notationPagesTableRefs {
    final manager = $$NotationPagesTableTableTableManager(
            $_db, $_db.notationPagesTable)
        .filter((f) => f.notationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_notationPagesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NotationTagsTableTable, List<NotationTagRow>>
      _notationTagsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.notationTagsTable,
              aliasName: $_aliasNameGenerator(
                  db.notationsTable.id, db.notationTagsTable.notationId));

  $$NotationTagsTableTableProcessedTableManager get notationTagsTableRefs {
    final manager = $$NotationTagsTableTableTableManager(
            $_db, $_db.notationTagsTable)
        .filter((f) => f.notationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_notationTagsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NotationInstrumentsTableTable,
      List<NotationInstrumentRow>> _notationInstrumentsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.notationInstrumentsTable,
          aliasName: $_aliasNameGenerator(
              db.notationsTable.id, db.notationInstrumentsTable.notationId));

  $$NotationInstrumentsTableTableProcessedTableManager
      get notationInstrumentsTableRefs {
    final manager = $$NotationInstrumentsTableTableTableManager(
            $_db, $_db.notationInstrumentsTable)
        .filter((f) => f.notationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_notationInstrumentsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$NotationCustomFieldsTableTable,
      List<NotationCustomFieldRow>> _notationCustomFieldsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.notationCustomFieldsTable,
          aliasName: $_aliasNameGenerator(
              db.notationsTable.id, db.notationCustomFieldsTable.notationId));

  $$NotationCustomFieldsTableTableProcessedTableManager
      get notationCustomFieldsTableRefs {
    final manager = $$NotationCustomFieldsTableTableTableManager(
            $_db, $_db.notationCustomFieldsTable)
        .filter((f) => f.notationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult
        .readTableOrNull(_notationCustomFieldsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NotationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotationsTableTable> {
  $$NotationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get artists => $composableBuilder(
      column: $table.artists, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateWritten => $composableBuilder(
      column: $table.dateWritten, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeSig => $composableBuilder(
      column: $table.timeSig, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keySig => $composableBuilder(
      column: $table.keySig, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get languages => $composableBuilder(
      column: $table.languages, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> notationPagesTableRefs(
      Expression<bool> Function($$NotationPagesTableTableFilterComposer f) f) {
    final $$NotationPagesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.notationPagesTable,
        getReferencedColumn: (t) => t.notationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationPagesTableTableFilterComposer(
              $db: $db,
              $table: $db.notationPagesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> notationTagsTableRefs(
      Expression<bool> Function($$NotationTagsTableTableFilterComposer f) f) {
    final $$NotationTagsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.notationTagsTable,
        getReferencedColumn: (t) => t.notationId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationTagsTableTableFilterComposer(
              $db: $db,
              $table: $db.notationTagsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> notationInstrumentsTableRefs(
      Expression<bool> Function($$NotationInstrumentsTableTableFilterComposer f)
          f) {
    final $$NotationInstrumentsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationInstrumentsTable,
            getReferencedColumn: (t) => t.notationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationInstrumentsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.notationInstrumentsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> notationCustomFieldsTableRefs(
      Expression<bool> Function(
              $$NotationCustomFieldsTableTableFilterComposer f)
          f) {
    final $$NotationCustomFieldsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationCustomFieldsTable,
            getReferencedColumn: (t) => t.notationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationCustomFieldsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.notationCustomFieldsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$NotationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotationsTableTable> {
  $$NotationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get artists => $composableBuilder(
      column: $table.artists, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateWritten => $composableBuilder(
      column: $table.dateWritten, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeSig => $composableBuilder(
      column: $table.timeSig, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keySig => $composableBuilder(
      column: $table.keySig, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get languages => $composableBuilder(
      column: $table.languages, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get playCount => $composableBuilder(
      column: $table.playCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotationsTableTable> {
  $$NotationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artists =>
      $composableBuilder(column: $table.artists, builder: (column) => column);

  GeneratedColumn<String> get dateWritten => $composableBuilder(
      column: $table.dateWritten, builder: (column) => column);

  GeneratedColumn<String> get timeSig =>
      $composableBuilder(column: $table.timeSig, builder: (column) => column);

  GeneratedColumn<String> get keySig =>
      $composableBuilder(column: $table.keySig, builder: (column) => column);

  GeneratedColumn<String> get languages =>
      $composableBuilder(column: $table.languages, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get playCount =>
      $composableBuilder(column: $table.playCount, builder: (column) => column);

  GeneratedColumn<String> get lastPlayedAt => $composableBuilder(
      column: $table.lastPlayedAt, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> notationPagesTableRefs<T extends Object>(
      Expression<T> Function($$NotationPagesTableTableAnnotationComposer a) f) {
    final $$NotationPagesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationPagesTable,
            getReferencedColumn: (t) => t.notationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationPagesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationPagesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> notationTagsTableRefs<T extends Object>(
      Expression<T> Function($$NotationTagsTableTableAnnotationComposer a) f) {
    final $$NotationTagsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationTagsTable,
            getReferencedColumn: (t) => t.notationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationTagsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationTagsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> notationInstrumentsTableRefs<T extends Object>(
      Expression<T> Function(
              $$NotationInstrumentsTableTableAnnotationComposer a)
          f) {
    final $$NotationInstrumentsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationInstrumentsTable,
            getReferencedColumn: (t) => t.notationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationInstrumentsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationInstrumentsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> notationCustomFieldsTableRefs<T extends Object>(
      Expression<T> Function(
              $$NotationCustomFieldsTableTableAnnotationComposer a)
          f) {
    final $$NotationCustomFieldsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationCustomFieldsTable,
            getReferencedColumn: (t) => t.notationId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationCustomFieldsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationCustomFieldsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$NotationsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotationsTableTable,
    NotationRow,
    $$NotationsTableTableFilterComposer,
    $$NotationsTableTableOrderingComposer,
    $$NotationsTableTableAnnotationComposer,
    $$NotationsTableTableCreateCompanionBuilder,
    $$NotationsTableTableUpdateCompanionBuilder,
    (NotationRow, $$NotationsTableTableReferences),
    NotationRow,
    PrefetchHooks Function(
        {bool notationPagesTableRefs,
        bool notationTagsTableRefs,
        bool notationInstrumentsTableRefs,
        bool notationCustomFieldsTableRefs})> {
  $$NotationsTableTableTableManager(
      _$AppDatabase db, $NotationsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotationsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> artists = const Value.absent(),
            Value<String?> dateWritten = const Value.absent(),
            Value<String?> timeSig = const Value.absent(),
            Value<String?> keySig = const Value.absent(),
            Value<String> languages = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<String?> lastPlayedAt = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationsTableCompanion(
            id: id,
            title: title,
            artists: artists,
            dateWritten: dateWritten,
            timeSig: timeSig,
            keySig: keySig,
            languages: languages,
            notes: notes,
            playCount: playCount,
            lastPlayedAt: lastPlayedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String> artists = const Value.absent(),
            Value<String?> dateWritten = const Value.absent(),
            Value<String?> timeSig = const Value.absent(),
            Value<String?> keySig = const Value.absent(),
            Value<String> languages = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<int> playCount = const Value.absent(),
            Value<String?> lastPlayedAt = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationsTableCompanion.insert(
            id: id,
            title: title,
            artists: artists,
            dateWritten: dateWritten,
            timeSig: timeSig,
            keySig: keySig,
            languages: languages,
            notes: notes,
            playCount: playCount,
            lastPlayedAt: lastPlayedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotationsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {notationPagesTableRefs = false,
              notationTagsTableRefs = false,
              notationInstrumentsTableRefs = false,
              notationCustomFieldsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (notationPagesTableRefs) db.notationPagesTable,
                if (notationTagsTableRefs) db.notationTagsTable,
                if (notationInstrumentsTableRefs) db.notationInstrumentsTable,
                if (notationCustomFieldsTableRefs) db.notationCustomFieldsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notationPagesTableRefs)
                    await $_getPrefetchedData<NotationRow, $NotationsTableTable,
                            NotationPageRow>(
                        currentTable: table,
                        referencedTable: $$NotationsTableTableReferences
                            ._notationPagesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotationsTableTableReferences(db, table, p0)
                                .notationPagesTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.notationId == item.id),
                        typedResults: items),
                  if (notationTagsTableRefs)
                    await $_getPrefetchedData<NotationRow, $NotationsTableTable, NotationTagRow>(
                        currentTable: table,
                        referencedTable: $$NotationsTableTableReferences
                            ._notationTagsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotationsTableTableReferences(db, table, p0)
                                .notationTagsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.notationId == item.id),
                        typedResults: items),
                  if (notationInstrumentsTableRefs)
                    await $_getPrefetchedData<NotationRow, $NotationsTableTable,
                            NotationInstrumentRow>(
                        currentTable: table,
                        referencedTable: $$NotationsTableTableReferences
                            ._notationInstrumentsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotationsTableTableReferences(db, table, p0)
                                .notationInstrumentsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.notationId == item.id),
                        typedResults: items),
                  if (notationCustomFieldsTableRefs)
                    await $_getPrefetchedData<NotationRow, $NotationsTableTable,
                            NotationCustomFieldRow>(
                        currentTable: table,
                        referencedTable: $$NotationsTableTableReferences
                            ._notationCustomFieldsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotationsTableTableReferences(db, table, p0)
                                .notationCustomFieldsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.notationId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NotationsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotationsTableTable,
    NotationRow,
    $$NotationsTableTableFilterComposer,
    $$NotationsTableTableOrderingComposer,
    $$NotationsTableTableAnnotationComposer,
    $$NotationsTableTableCreateCompanionBuilder,
    $$NotationsTableTableUpdateCompanionBuilder,
    (NotationRow, $$NotationsTableTableReferences),
    NotationRow,
    PrefetchHooks Function(
        {bool notationPagesTableRefs,
        bool notationTagsTableRefs,
        bool notationInstrumentsTableRefs,
        bool notationCustomFieldsTableRefs})>;
typedef $$NotationPagesTableTableCreateCompanionBuilder
    = NotationPagesTableCompanion Function({
  required String id,
  required String notationId,
  required int pageOrder,
  required String imagePath,
  Value<String> renderParams,
  required String createdAt,
  Value<int> rowid,
});
typedef $$NotationPagesTableTableUpdateCompanionBuilder
    = NotationPagesTableCompanion Function({
  Value<String> id,
  Value<String> notationId,
  Value<int> pageOrder,
  Value<String> imagePath,
  Value<String> renderParams,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $$NotationPagesTableTableReferences extends BaseReferences<
    _$AppDatabase, $NotationPagesTableTable, NotationPageRow> {
  $$NotationPagesTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NotationsTableTable _notationIdTable(_$AppDatabase db) =>
      db.notationsTable.createAlias($_aliasNameGenerator(
          db.notationPagesTable.notationId, db.notationsTable.id));

  $$NotationsTableTableProcessedTableManager get notationId {
    final $_column = $_itemColumn<String>('notation_id')!;

    final manager = $$NotationsTableTableTableManager($_db, $_db.notationsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NotationPagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotationPagesTableTable> {
  $$NotationPagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageOrder => $composableBuilder(
      column: $table.pageOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get renderParams => $composableBuilder(
      column: $table.renderParams, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$NotationsTableTableFilterComposer get notationId {
    final $$NotationsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableFilterComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotationPagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotationPagesTableTable> {
  $$NotationPagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageOrder => $composableBuilder(
      column: $table.pageOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get renderParams => $composableBuilder(
      column: $table.renderParams,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$NotationsTableTableOrderingComposer get notationId {
    final $$NotationsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableOrderingComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotationPagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotationPagesTableTable> {
  $$NotationPagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageOrder =>
      $composableBuilder(column: $table.pageOrder, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get renderParams => $composableBuilder(
      column: $table.renderParams, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$NotationsTableTableAnnotationComposer get notationId {
    final $$NotationsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotationPagesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotationPagesTableTable,
    NotationPageRow,
    $$NotationPagesTableTableFilterComposer,
    $$NotationPagesTableTableOrderingComposer,
    $$NotationPagesTableTableAnnotationComposer,
    $$NotationPagesTableTableCreateCompanionBuilder,
    $$NotationPagesTableTableUpdateCompanionBuilder,
    (NotationPageRow, $$NotationPagesTableTableReferences),
    NotationPageRow,
    PrefetchHooks Function({bool notationId})> {
  $$NotationPagesTableTableTableManager(
      _$AppDatabase db, $NotationPagesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotationPagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotationPagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotationPagesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> notationId = const Value.absent(),
            Value<int> pageOrder = const Value.absent(),
            Value<String> imagePath = const Value.absent(),
            Value<String> renderParams = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationPagesTableCompanion(
            id: id,
            notationId: notationId,
            pageOrder: pageOrder,
            imagePath: imagePath,
            renderParams: renderParams,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String notationId,
            required int pageOrder,
            required String imagePath,
            Value<String> renderParams = const Value.absent(),
            required String createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationPagesTableCompanion.insert(
            id: id,
            notationId: notationId,
            pageOrder: pageOrder,
            imagePath: imagePath,
            renderParams: renderParams,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotationPagesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({notationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (notationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.notationId,
                    referencedTable: $$NotationPagesTableTableReferences
                        ._notationIdTable(db),
                    referencedColumn: $$NotationPagesTableTableReferences
                        ._notationIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NotationPagesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotationPagesTableTable,
    NotationPageRow,
    $$NotationPagesTableTableFilterComposer,
    $$NotationPagesTableTableOrderingComposer,
    $$NotationPagesTableTableAnnotationComposer,
    $$NotationPagesTableTableCreateCompanionBuilder,
    $$NotationPagesTableTableUpdateCompanionBuilder,
    (NotationPageRow, $$NotationPagesTableTableReferences),
    NotationPageRow,
    PrefetchHooks Function({bool notationId})>;
typedef $$TagsTableTableCreateCompanionBuilder = TagsTableCompanion Function({
  required String id,
  required String name,
  required String colorHex,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$TagsTableTableUpdateCompanionBuilder = TagsTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> colorHex,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$TagsTableTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTableTable, TagRow> {
  $$TagsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotationTagsTableTable, List<NotationTagRow>>
      _notationTagsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.notationTagsTable,
              aliasName: $_aliasNameGenerator(
                  db.tagsTable.id, db.notationTagsTable.tagId));

  $$NotationTagsTableTableProcessedTableManager get notationTagsTableRefs {
    final manager =
        $$NotationTagsTableTableTableManager($_db, $_db.notationTagsTable)
            .filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_notationTagsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TagsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TagsTableTable> {
  $$TagsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> notationTagsTableRefs(
      Expression<bool> Function($$NotationTagsTableTableFilterComposer f) f) {
    final $$NotationTagsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.notationTagsTable,
        getReferencedColumn: (t) => t.tagId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationTagsTableTableFilterComposer(
              $db: $db,
              $table: $db.notationTagsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TagsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TagsTableTable> {
  $$TagsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTableTable> {
  $$TagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> notationTagsTableRefs<T extends Object>(
      Expression<T> Function($$NotationTagsTableTableAnnotationComposer a) f) {
    final $$NotationTagsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationTagsTable,
            getReferencedColumn: (t) => t.tagId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationTagsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationTagsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$TagsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TagsTableTable,
    TagRow,
    $$TagsTableTableFilterComposer,
    $$TagsTableTableOrderingComposer,
    $$TagsTableTableAnnotationComposer,
    $$TagsTableTableCreateCompanionBuilder,
    $$TagsTableTableUpdateCompanionBuilder,
    (TagRow, $$TagsTableTableReferences),
    TagRow,
    PrefetchHooks Function({bool notationTagsTableRefs})> {
  $$TagsTableTableTableManager(_$AppDatabase db, $TagsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsTableCompanion(
            id: id,
            name: name,
            colorHex: colorHex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String colorHex,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsTableCompanion.insert(
            id: id,
            name: name,
            colorHex: colorHex,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TagsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({notationTagsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (notationTagsTableRefs) db.notationTagsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notationTagsTableRefs)
                    await $_getPrefetchedData<TagRow, $TagsTableTable,
                            NotationTagRow>(
                        currentTable: table,
                        referencedTable: $$TagsTableTableReferences
                            ._notationTagsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TagsTableTableReferences(db, table, p0)
                                .notationTagsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tagId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TagsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TagsTableTable,
    TagRow,
    $$TagsTableTableFilterComposer,
    $$TagsTableTableOrderingComposer,
    $$TagsTableTableAnnotationComposer,
    $$TagsTableTableCreateCompanionBuilder,
    $$TagsTableTableUpdateCompanionBuilder,
    (TagRow, $$TagsTableTableReferences),
    TagRow,
    PrefetchHooks Function({bool notationTagsTableRefs})>;
typedef $$NotationTagsTableTableCreateCompanionBuilder
    = NotationTagsTableCompanion Function({
  required String notationId,
  required String tagId,
  Value<int> rowid,
});
typedef $$NotationTagsTableTableUpdateCompanionBuilder
    = NotationTagsTableCompanion Function({
  Value<String> notationId,
  Value<String> tagId,
  Value<int> rowid,
});

final class $$NotationTagsTableTableReferences extends BaseReferences<
    _$AppDatabase, $NotationTagsTableTable, NotationTagRow> {
  $$NotationTagsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NotationsTableTable _notationIdTable(_$AppDatabase db) =>
      db.notationsTable.createAlias($_aliasNameGenerator(
          db.notationTagsTable.notationId, db.notationsTable.id));

  $$NotationsTableTableProcessedTableManager get notationId {
    final $_column = $_itemColumn<String>('notation_id')!;

    final manager = $$NotationsTableTableTableManager($_db, $_db.notationsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TagsTableTable _tagIdTable(_$AppDatabase db) =>
      db.tagsTable.createAlias(
          $_aliasNameGenerator(db.notationTagsTable.tagId, db.tagsTable.id));

  $$TagsTableTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableTableManager($_db, $_db.tagsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NotationTagsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotationTagsTableTable> {
  $$NotationTagsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotationsTableTableFilterComposer get notationId {
    final $$NotationsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableFilterComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableTableFilterComposer get tagId {
    final $$TagsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tagsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableTableFilterComposer(
              $db: $db,
              $table: $db.tagsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotationTagsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotationTagsTableTable> {
  $$NotationTagsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotationsTableTableOrderingComposer get notationId {
    final $$NotationsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableOrderingComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableTableOrderingComposer get tagId {
    final $$TagsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tagsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableTableOrderingComposer(
              $db: $db,
              $table: $db.tagsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotationTagsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotationTagsTableTable> {
  $$NotationTagsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotationsTableTableAnnotationComposer get notationId {
    final $$NotationsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$TagsTableTableAnnotationComposer get tagId {
    final $$TagsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tagId,
        referencedTable: $db.tagsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TagsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.tagsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NotationTagsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotationTagsTableTable,
    NotationTagRow,
    $$NotationTagsTableTableFilterComposer,
    $$NotationTagsTableTableOrderingComposer,
    $$NotationTagsTableTableAnnotationComposer,
    $$NotationTagsTableTableCreateCompanionBuilder,
    $$NotationTagsTableTableUpdateCompanionBuilder,
    (NotationTagRow, $$NotationTagsTableTableReferences),
    NotationTagRow,
    PrefetchHooks Function({bool notationId, bool tagId})> {
  $$NotationTagsTableTableTableManager(
      _$AppDatabase db, $NotationTagsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotationTagsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotationTagsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotationTagsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> notationId = const Value.absent(),
            Value<String> tagId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationTagsTableCompanion(
            notationId: notationId,
            tagId: tagId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String notationId,
            required String tagId,
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationTagsTableCompanion.insert(
            notationId: notationId,
            tagId: tagId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotationTagsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({notationId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (notationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.notationId,
                    referencedTable:
                        $$NotationTagsTableTableReferences._notationIdTable(db),
                    referencedColumn: $$NotationTagsTableTableReferences
                        ._notationIdTable(db)
                        .id,
                  ) as T;
                }
                if (tagId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tagId,
                    referencedTable:
                        $$NotationTagsTableTableReferences._tagIdTable(db),
                    referencedColumn:
                        $$NotationTagsTableTableReferences._tagIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NotationTagsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotationTagsTableTable,
    NotationTagRow,
    $$NotationTagsTableTableFilterComposer,
    $$NotationTagsTableTableOrderingComposer,
    $$NotationTagsTableTableAnnotationComposer,
    $$NotationTagsTableTableCreateCompanionBuilder,
    $$NotationTagsTableTableUpdateCompanionBuilder,
    (NotationTagRow, $$NotationTagsTableTableReferences),
    NotationTagRow,
    PrefetchHooks Function({bool notationId, bool tagId})>;
typedef $$InstrumentClassesTableTableCreateCompanionBuilder
    = InstrumentClassesTableCompanion Function({
  required String id,
  required String name,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$InstrumentClassesTableTableUpdateCompanionBuilder
    = InstrumentClassesTableCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$InstrumentClassesTableTableReferences extends BaseReferences<
    _$AppDatabase, $InstrumentClassesTableTable, InstrumentClassRow> {
  $$InstrumentClassesTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$InstrumentInstancesTableTable,
      List<InstrumentInstanceRow>> _instrumentInstancesTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.instrumentInstancesTable,
          aliasName: $_aliasNameGenerator(db.instrumentClassesTable.id,
              db.instrumentInstancesTable.classId));

  $$InstrumentInstancesTableTableProcessedTableManager
      get instrumentInstancesTableRefs {
    final manager = $$InstrumentInstancesTableTableTableManager(
            $_db, $_db.instrumentInstancesTable)
        .filter((f) => f.classId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_instrumentInstancesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InstrumentClassesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InstrumentClassesTableTable> {
  $$InstrumentClassesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> instrumentInstancesTableRefs(
      Expression<bool> Function($$InstrumentInstancesTableTableFilterComposer f)
          f) {
    final $$InstrumentInstancesTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.instrumentInstancesTable,
            getReferencedColumn: (t) => t.classId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentInstancesTableTableFilterComposer(
                  $db: $db,
                  $table: $db.instrumentInstancesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$InstrumentClassesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InstrumentClassesTableTable> {
  $$InstrumentClassesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InstrumentClassesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstrumentClassesTableTable> {
  $$InstrumentClassesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> instrumentInstancesTableRefs<T extends Object>(
      Expression<T> Function(
              $$InstrumentInstancesTableTableAnnotationComposer a)
          f) {
    final $$InstrumentInstancesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.instrumentInstancesTable,
            getReferencedColumn: (t) => t.classId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentInstancesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.instrumentInstancesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$InstrumentClassesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InstrumentClassesTableTable,
    InstrumentClassRow,
    $$InstrumentClassesTableTableFilterComposer,
    $$InstrumentClassesTableTableOrderingComposer,
    $$InstrumentClassesTableTableAnnotationComposer,
    $$InstrumentClassesTableTableCreateCompanionBuilder,
    $$InstrumentClassesTableTableUpdateCompanionBuilder,
    (InstrumentClassRow, $$InstrumentClassesTableTableReferences),
    InstrumentClassRow,
    PrefetchHooks Function({bool instrumentInstancesTableRefs})> {
  $$InstrumentClassesTableTableTableManager(
      _$AppDatabase db, $InstrumentClassesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentClassesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentClassesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentClassesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstrumentClassesTableCompanion(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              InstrumentClassesTableCompanion.insert(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InstrumentClassesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({instrumentInstancesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (instrumentInstancesTableRefs) db.instrumentInstancesTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (instrumentInstancesTableRefs)
                    await $_getPrefetchedData<
                            InstrumentClassRow,
                            $InstrumentClassesTableTable,
                            InstrumentInstanceRow>(
                        currentTable: table,
                        referencedTable: $$InstrumentClassesTableTableReferences
                            ._instrumentInstancesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InstrumentClassesTableTableReferences(
                                    db, table, p0)
                                .instrumentInstancesTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.classId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InstrumentClassesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $InstrumentClassesTableTable,
        InstrumentClassRow,
        $$InstrumentClassesTableTableFilterComposer,
        $$InstrumentClassesTableTableOrderingComposer,
        $$InstrumentClassesTableTableAnnotationComposer,
        $$InstrumentClassesTableTableCreateCompanionBuilder,
        $$InstrumentClassesTableTableUpdateCompanionBuilder,
        (InstrumentClassRow, $$InstrumentClassesTableTableReferences),
        InstrumentClassRow,
        PrefetchHooks Function({bool instrumentInstancesTableRefs})>;
typedef $$InstrumentInstancesTableTableCreateCompanionBuilder
    = InstrumentInstancesTableCompanion Function({
  required String id,
  required String classId,
  Value<String?> brand,
  Value<String?> model,
  required String colorHex,
  Value<int?> priceInr,
  Value<String?> photoPath,
  Value<String> notes,
  required String createdAt,
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$InstrumentInstancesTableTableUpdateCompanionBuilder
    = InstrumentInstancesTableCompanion Function({
  Value<String> id,
  Value<String> classId,
  Value<String?> brand,
  Value<String?> model,
  Value<String> colorHex,
  Value<int?> priceInr,
  Value<String?> photoPath,
  Value<String> notes,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$InstrumentInstancesTableTableReferences extends BaseReferences<
    _$AppDatabase, $InstrumentInstancesTableTable, InstrumentInstanceRow> {
  $$InstrumentInstancesTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $InstrumentClassesTableTable _classIdTable(_$AppDatabase db) =>
      db.instrumentClassesTable.createAlias($_aliasNameGenerator(
          db.instrumentInstancesTable.classId, db.instrumentClassesTable.id));

  $$InstrumentClassesTableTableProcessedTableManager get classId {
    final $_column = $_itemColumn<String>('class_id')!;

    final manager = $$InstrumentClassesTableTableTableManager(
            $_db, $_db.instrumentClassesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_classIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$NotationInstrumentsTableTable,
      List<NotationInstrumentRow>> _notationInstrumentsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.notationInstrumentsTable,
          aliasName: $_aliasNameGenerator(db.instrumentInstancesTable.id,
              db.notationInstrumentsTable.instanceId));

  $$NotationInstrumentsTableTableProcessedTableManager
      get notationInstrumentsTableRefs {
    final manager = $$NotationInstrumentsTableTableTableManager(
            $_db, $_db.notationInstrumentsTable)
        .filter((f) => f.instanceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_notationInstrumentsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$InstrumentInstancesTableTableFilterComposer
    extends Composer<_$AppDatabase, $InstrumentInstancesTableTable> {
  $$InstrumentInstancesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceInr => $composableBuilder(
      column: $table.priceInr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$InstrumentClassesTableTableFilterComposer get classId {
    final $$InstrumentClassesTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.classId,
            referencedTable: $db.instrumentClassesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentClassesTableTableFilterComposer(
                  $db: $db,
                  $table: $db.instrumentClassesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  Expression<bool> notationInstrumentsTableRefs(
      Expression<bool> Function($$NotationInstrumentsTableTableFilterComposer f)
          f) {
    final $$NotationInstrumentsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationInstrumentsTable,
            getReferencedColumn: (t) => t.instanceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationInstrumentsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.notationInstrumentsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$InstrumentInstancesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $InstrumentInstancesTableTable> {
  $$InstrumentInstancesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brand => $composableBuilder(
      column: $table.brand, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get model => $composableBuilder(
      column: $table.model, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorHex => $composableBuilder(
      column: $table.colorHex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceInr => $composableBuilder(
      column: $table.priceInr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$InstrumentClassesTableTableOrderingComposer get classId {
    final $$InstrumentClassesTableTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.classId,
            referencedTable: $db.instrumentClassesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentClassesTableTableOrderingComposer(
                  $db: $db,
                  $table: $db.instrumentClassesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$InstrumentInstancesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstrumentInstancesTableTable> {
  $$InstrumentInstancesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get priceInr =>
      $composableBuilder(column: $table.priceInr, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$InstrumentClassesTableTableAnnotationComposer get classId {
    final $$InstrumentClassesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.classId,
            referencedTable: $db.instrumentClassesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentClassesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.instrumentClassesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }

  Expression<T> notationInstrumentsTableRefs<T extends Object>(
      Expression<T> Function(
              $$NotationInstrumentsTableTableAnnotationComposer a)
          f) {
    final $$NotationInstrumentsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationInstrumentsTable,
            getReferencedColumn: (t) => t.instanceId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationInstrumentsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationInstrumentsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$InstrumentInstancesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InstrumentInstancesTableTable,
    InstrumentInstanceRow,
    $$InstrumentInstancesTableTableFilterComposer,
    $$InstrumentInstancesTableTableOrderingComposer,
    $$InstrumentInstancesTableTableAnnotationComposer,
    $$InstrumentInstancesTableTableCreateCompanionBuilder,
    $$InstrumentInstancesTableTableUpdateCompanionBuilder,
    (InstrumentInstanceRow, $$InstrumentInstancesTableTableReferences),
    InstrumentInstanceRow,
    PrefetchHooks Function({bool classId, bool notationInstrumentsTableRefs})> {
  $$InstrumentInstancesTableTableTableManager(
      _$AppDatabase db, $InstrumentInstancesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstrumentInstancesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$InstrumentInstancesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstrumentInstancesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> classId = const Value.absent(),
            Value<String?> brand = const Value.absent(),
            Value<String?> model = const Value.absent(),
            Value<String> colorHex = const Value.absent(),
            Value<int?> priceInr = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstrumentInstancesTableCompanion(
            id: id,
            classId: classId,
            brand: brand,
            model: model,
            colorHex: colorHex,
            priceInr: priceInr,
            photoPath: photoPath,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String classId,
            Value<String?> brand = const Value.absent(),
            Value<String?> model = const Value.absent(),
            required String colorHex,
            Value<int?> priceInr = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String> notes = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InstrumentInstancesTableCompanion.insert(
            id: id,
            classId: classId,
            brand: brand,
            model: model,
            colorHex: colorHex,
            priceInr: priceInr,
            photoPath: photoPath,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$InstrumentInstancesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {classId = false, notationInstrumentsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (notationInstrumentsTableRefs) db.notationInstrumentsTable
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (classId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.classId,
                    referencedTable: $$InstrumentInstancesTableTableReferences
                        ._classIdTable(db),
                    referencedColumn: $$InstrumentInstancesTableTableReferences
                        ._classIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notationInstrumentsTableRefs)
                    await $_getPrefetchedData<
                            InstrumentInstanceRow,
                            $InstrumentInstancesTableTable,
                            NotationInstrumentRow>(
                        currentTable: table,
                        referencedTable:
                            $$InstrumentInstancesTableTableReferences
                                ._notationInstrumentsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$InstrumentInstancesTableTableReferences(
                                    db, table, p0)
                                .notationInstrumentsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.instanceId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$InstrumentInstancesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $InstrumentInstancesTableTable,
        InstrumentInstanceRow,
        $$InstrumentInstancesTableTableFilterComposer,
        $$InstrumentInstancesTableTableOrderingComposer,
        $$InstrumentInstancesTableTableAnnotationComposer,
        $$InstrumentInstancesTableTableCreateCompanionBuilder,
        $$InstrumentInstancesTableTableUpdateCompanionBuilder,
        (InstrumentInstanceRow, $$InstrumentInstancesTableTableReferences),
        InstrumentInstanceRow,
        PrefetchHooks Function(
            {bool classId, bool notationInstrumentsTableRefs})>;
typedef $$NotationInstrumentsTableTableCreateCompanionBuilder
    = NotationInstrumentsTableCompanion Function({
  required String notationId,
  required String instanceId,
  Value<int> rowid,
});
typedef $$NotationInstrumentsTableTableUpdateCompanionBuilder
    = NotationInstrumentsTableCompanion Function({
  Value<String> notationId,
  Value<String> instanceId,
  Value<int> rowid,
});

final class $$NotationInstrumentsTableTableReferences extends BaseReferences<
    _$AppDatabase, $NotationInstrumentsTableTable, NotationInstrumentRow> {
  $$NotationInstrumentsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NotationsTableTable _notationIdTable(_$AppDatabase db) =>
      db.notationsTable.createAlias($_aliasNameGenerator(
          db.notationInstrumentsTable.notationId, db.notationsTable.id));

  $$NotationsTableTableProcessedTableManager get notationId {
    final $_column = $_itemColumn<String>('notation_id')!;

    final manager = $$NotationsTableTableTableManager($_db, $_db.notationsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $InstrumentInstancesTableTable _instanceIdTable(_$AppDatabase db) =>
      db.instrumentInstancesTable.createAlias($_aliasNameGenerator(
          db.notationInstrumentsTable.instanceId,
          db.instrumentInstancesTable.id));

  $$InstrumentInstancesTableTableProcessedTableManager get instanceId {
    final $_column = $_itemColumn<String>('instance_id')!;

    final manager = $$InstrumentInstancesTableTableTableManager(
            $_db, $_db.instrumentInstancesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_instanceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NotationInstrumentsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotationInstrumentsTableTable> {
  $$NotationInstrumentsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotationsTableTableFilterComposer get notationId {
    final $$NotationsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableFilterComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InstrumentInstancesTableTableFilterComposer get instanceId {
    final $$InstrumentInstancesTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.instanceId,
            referencedTable: $db.instrumentInstancesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentInstancesTableTableFilterComposer(
                  $db: $db,
                  $table: $db.instrumentInstancesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$NotationInstrumentsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotationInstrumentsTableTable> {
  $$NotationInstrumentsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotationsTableTableOrderingComposer get notationId {
    final $$NotationsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableOrderingComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InstrumentInstancesTableTableOrderingComposer get instanceId {
    final $$InstrumentInstancesTableTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.instanceId,
            referencedTable: $db.instrumentInstancesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentInstancesTableTableOrderingComposer(
                  $db: $db,
                  $table: $db.instrumentInstancesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$NotationInstrumentsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotationInstrumentsTableTable> {
  $$NotationInstrumentsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$NotationsTableTableAnnotationComposer get notationId {
    final $$NotationsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$InstrumentInstancesTableTableAnnotationComposer get instanceId {
    final $$InstrumentInstancesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.instanceId,
            referencedTable: $db.instrumentInstancesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$InstrumentInstancesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.instrumentInstancesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$NotationInstrumentsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotationInstrumentsTableTable,
    NotationInstrumentRow,
    $$NotationInstrumentsTableTableFilterComposer,
    $$NotationInstrumentsTableTableOrderingComposer,
    $$NotationInstrumentsTableTableAnnotationComposer,
    $$NotationInstrumentsTableTableCreateCompanionBuilder,
    $$NotationInstrumentsTableTableUpdateCompanionBuilder,
    (NotationInstrumentRow, $$NotationInstrumentsTableTableReferences),
    NotationInstrumentRow,
    PrefetchHooks Function({bool notationId, bool instanceId})> {
  $$NotationInstrumentsTableTableTableManager(
      _$AppDatabase db, $NotationInstrumentsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotationInstrumentsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$NotationInstrumentsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotationInstrumentsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> notationId = const Value.absent(),
            Value<String> instanceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationInstrumentsTableCompanion(
            notationId: notationId,
            instanceId: instanceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String notationId,
            required String instanceId,
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationInstrumentsTableCompanion.insert(
            notationId: notationId,
            instanceId: instanceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotationInstrumentsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({notationId = false, instanceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (notationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.notationId,
                    referencedTable: $$NotationInstrumentsTableTableReferences
                        ._notationIdTable(db),
                    referencedColumn: $$NotationInstrumentsTableTableReferences
                        ._notationIdTable(db)
                        .id,
                  ) as T;
                }
                if (instanceId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.instanceId,
                    referencedTable: $$NotationInstrumentsTableTableReferences
                        ._instanceIdTable(db),
                    referencedColumn: $$NotationInstrumentsTableTableReferences
                        ._instanceIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NotationInstrumentsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $NotationInstrumentsTableTable,
        NotationInstrumentRow,
        $$NotationInstrumentsTableTableFilterComposer,
        $$NotationInstrumentsTableTableOrderingComposer,
        $$NotationInstrumentsTableTableAnnotationComposer,
        $$NotationInstrumentsTableTableCreateCompanionBuilder,
        $$NotationInstrumentsTableTableUpdateCompanionBuilder,
        (NotationInstrumentRow, $$NotationInstrumentsTableTableReferences),
        NotationInstrumentRow,
        PrefetchHooks Function({bool notationId, bool instanceId})>;
typedef $$CustomFieldDefinitionsTableTableCreateCompanionBuilder
    = CustomFieldDefinitionsTableCompanion Function({
  required String id,
  required String keyName,
  required String fieldType,
  required String createdAt,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$CustomFieldDefinitionsTableTableUpdateCompanionBuilder
    = CustomFieldDefinitionsTableCompanion Function({
  Value<String> id,
  Value<String> keyName,
  Value<String> fieldType,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$CustomFieldDefinitionsTableTableReferences extends BaseReferences<
    _$AppDatabase,
    $CustomFieldDefinitionsTableTable,
    CustomFieldDefinitionRow> {
  $$CustomFieldDefinitionsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NotationCustomFieldsTableTable,
      List<NotationCustomFieldRow>> _notationCustomFieldsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.notationCustomFieldsTable,
          aliasName: $_aliasNameGenerator(db.customFieldDefinitionsTable.id,
              db.notationCustomFieldsTable.definitionId));

  $$NotationCustomFieldsTableTableProcessedTableManager
      get notationCustomFieldsTableRefs {
    final manager = $$NotationCustomFieldsTableTableTableManager(
            $_db, $_db.notationCustomFieldsTable)
        .filter(
            (f) => f.definitionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult
        .readTableOrNull(_notationCustomFieldsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CustomFieldDefinitionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $CustomFieldDefinitionsTableTable> {
  $$CustomFieldDefinitionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get keyName => $composableBuilder(
      column: $table.keyName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldType => $composableBuilder(
      column: $table.fieldType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> notationCustomFieldsTableRefs(
      Expression<bool> Function(
              $$NotationCustomFieldsTableTableFilterComposer f)
          f) {
    final $$NotationCustomFieldsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationCustomFieldsTable,
            getReferencedColumn: (t) => t.definitionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationCustomFieldsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.notationCustomFieldsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CustomFieldDefinitionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomFieldDefinitionsTableTable> {
  $$CustomFieldDefinitionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get keyName => $composableBuilder(
      column: $table.keyName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldType => $composableBuilder(
      column: $table.fieldType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomFieldDefinitionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomFieldDefinitionsTableTable> {
  $$CustomFieldDefinitionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get keyName =>
      $composableBuilder(column: $table.keyName, builder: (column) => column);

  GeneratedColumn<String> get fieldType =>
      $composableBuilder(column: $table.fieldType, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> notationCustomFieldsTableRefs<T extends Object>(
      Expression<T> Function(
              $$NotationCustomFieldsTableTableAnnotationComposer a)
          f) {
    final $$NotationCustomFieldsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.notationCustomFieldsTable,
            getReferencedColumn: (t) => t.definitionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$NotationCustomFieldsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.notationCustomFieldsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$CustomFieldDefinitionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomFieldDefinitionsTableTable,
    CustomFieldDefinitionRow,
    $$CustomFieldDefinitionsTableTableFilterComposer,
    $$CustomFieldDefinitionsTableTableOrderingComposer,
    $$CustomFieldDefinitionsTableTableAnnotationComposer,
    $$CustomFieldDefinitionsTableTableCreateCompanionBuilder,
    $$CustomFieldDefinitionsTableTableUpdateCompanionBuilder,
    (CustomFieldDefinitionRow, $$CustomFieldDefinitionsTableTableReferences),
    CustomFieldDefinitionRow,
    PrefetchHooks Function({bool notationCustomFieldsTableRefs})> {
  $$CustomFieldDefinitionsTableTableTableManager(
      _$AppDatabase db, $CustomFieldDefinitionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomFieldDefinitionsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomFieldDefinitionsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomFieldDefinitionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> keyName = const Value.absent(),
            Value<String> fieldType = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomFieldDefinitionsTableCompanion(
            id: id,
            keyName: keyName,
            fieldType: fieldType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String keyName,
            required String fieldType,
            required String createdAt,
            required String updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomFieldDefinitionsTableCompanion.insert(
            id: id,
            keyName: keyName,
            fieldType: fieldType,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CustomFieldDefinitionsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({notationCustomFieldsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (notationCustomFieldsTableRefs) db.notationCustomFieldsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notationCustomFieldsTableRefs)
                    await $_getPrefetchedData<
                            CustomFieldDefinitionRow,
                            $CustomFieldDefinitionsTableTable,
                            NotationCustomFieldRow>(
                        currentTable: table,
                        referencedTable:
                            $$CustomFieldDefinitionsTableTableReferences
                                ._notationCustomFieldsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CustomFieldDefinitionsTableTableReferences(
                                    db, table, p0)
                                .notationCustomFieldsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.definitionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CustomFieldDefinitionsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CustomFieldDefinitionsTableTable,
        CustomFieldDefinitionRow,
        $$CustomFieldDefinitionsTableTableFilterComposer,
        $$CustomFieldDefinitionsTableTableOrderingComposer,
        $$CustomFieldDefinitionsTableTableAnnotationComposer,
        $$CustomFieldDefinitionsTableTableCreateCompanionBuilder,
        $$CustomFieldDefinitionsTableTableUpdateCompanionBuilder,
        (
          CustomFieldDefinitionRow,
          $$CustomFieldDefinitionsTableTableReferences
        ),
        CustomFieldDefinitionRow,
        PrefetchHooks Function({bool notationCustomFieldsTableRefs})>;
typedef $$NotationCustomFieldsTableTableCreateCompanionBuilder
    = NotationCustomFieldsTableCompanion Function({
  required String notationId,
  required String definitionId,
  Value<String?> valueText,
  Value<double?> valueNumber,
  Value<String?> valueDate,
  Value<int?> valueBoolean,
  Value<int> rowid,
});
typedef $$NotationCustomFieldsTableTableUpdateCompanionBuilder
    = NotationCustomFieldsTableCompanion Function({
  Value<String> notationId,
  Value<String> definitionId,
  Value<String?> valueText,
  Value<double?> valueNumber,
  Value<String?> valueDate,
  Value<int?> valueBoolean,
  Value<int> rowid,
});

final class $$NotationCustomFieldsTableTableReferences extends BaseReferences<
    _$AppDatabase, $NotationCustomFieldsTableTable, NotationCustomFieldRow> {
  $$NotationCustomFieldsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NotationsTableTable _notationIdTable(_$AppDatabase db) =>
      db.notationsTable.createAlias($_aliasNameGenerator(
          db.notationCustomFieldsTable.notationId, db.notationsTable.id));

  $$NotationsTableTableProcessedTableManager get notationId {
    final $_column = $_itemColumn<String>('notation_id')!;

    final manager = $$NotationsTableTableTableManager($_db, $_db.notationsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CustomFieldDefinitionsTableTable _definitionIdTable(
          _$AppDatabase db) =>
      db.customFieldDefinitionsTable.createAlias($_aliasNameGenerator(
          db.notationCustomFieldsTable.definitionId,
          db.customFieldDefinitionsTable.id));

  $$CustomFieldDefinitionsTableTableProcessedTableManager get definitionId {
    final $_column = $_itemColumn<String>('definition_id')!;

    final manager = $$CustomFieldDefinitionsTableTableTableManager(
            $_db, $_db.customFieldDefinitionsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_definitionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NotationCustomFieldsTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotationCustomFieldsTableTable> {
  $$NotationCustomFieldsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get valueText => $composableBuilder(
      column: $table.valueText, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get valueNumber => $composableBuilder(
      column: $table.valueNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get valueDate => $composableBuilder(
      column: $table.valueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get valueBoolean => $composableBuilder(
      column: $table.valueBoolean, builder: (column) => ColumnFilters(column));

  $$NotationsTableTableFilterComposer get notationId {
    final $$NotationsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableFilterComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomFieldDefinitionsTableTableFilterComposer get definitionId {
    final $$CustomFieldDefinitionsTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.definitionId,
            referencedTable: $db.customFieldDefinitionsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CustomFieldDefinitionsTableTableFilterComposer(
                  $db: $db,
                  $table: $db.customFieldDefinitionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$NotationCustomFieldsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotationCustomFieldsTableTable> {
  $$NotationCustomFieldsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get valueText => $composableBuilder(
      column: $table.valueText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get valueNumber => $composableBuilder(
      column: $table.valueNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get valueDate => $composableBuilder(
      column: $table.valueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get valueBoolean => $composableBuilder(
      column: $table.valueBoolean,
      builder: (column) => ColumnOrderings(column));

  $$NotationsTableTableOrderingComposer get notationId {
    final $$NotationsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableOrderingComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomFieldDefinitionsTableTableOrderingComposer get definitionId {
    final $$CustomFieldDefinitionsTableTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.definitionId,
            referencedTable: $db.customFieldDefinitionsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CustomFieldDefinitionsTableTableOrderingComposer(
                  $db: $db,
                  $table: $db.customFieldDefinitionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$NotationCustomFieldsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotationCustomFieldsTableTable> {
  $$NotationCustomFieldsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get valueText =>
      $composableBuilder(column: $table.valueText, builder: (column) => column);

  GeneratedColumn<double> get valueNumber => $composableBuilder(
      column: $table.valueNumber, builder: (column) => column);

  GeneratedColumn<String> get valueDate =>
      $composableBuilder(column: $table.valueDate, builder: (column) => column);

  GeneratedColumn<int> get valueBoolean => $composableBuilder(
      column: $table.valueBoolean, builder: (column) => column);

  $$NotationsTableTableAnnotationComposer get notationId {
    final $$NotationsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.notationId,
        referencedTable: $db.notationsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotationsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.notationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CustomFieldDefinitionsTableTableAnnotationComposer get definitionId {
    final $$CustomFieldDefinitionsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.definitionId,
            referencedTable: $db.customFieldDefinitionsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$CustomFieldDefinitionsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.customFieldDefinitionsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$NotationCustomFieldsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotationCustomFieldsTableTable,
    NotationCustomFieldRow,
    $$NotationCustomFieldsTableTableFilterComposer,
    $$NotationCustomFieldsTableTableOrderingComposer,
    $$NotationCustomFieldsTableTableAnnotationComposer,
    $$NotationCustomFieldsTableTableCreateCompanionBuilder,
    $$NotationCustomFieldsTableTableUpdateCompanionBuilder,
    (NotationCustomFieldRow, $$NotationCustomFieldsTableTableReferences),
    NotationCustomFieldRow,
    PrefetchHooks Function({bool notationId, bool definitionId})> {
  $$NotationCustomFieldsTableTableTableManager(
      _$AppDatabase db, $NotationCustomFieldsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotationCustomFieldsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$NotationCustomFieldsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotationCustomFieldsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> notationId = const Value.absent(),
            Value<String> definitionId = const Value.absent(),
            Value<String?> valueText = const Value.absent(),
            Value<double?> valueNumber = const Value.absent(),
            Value<String?> valueDate = const Value.absent(),
            Value<int?> valueBoolean = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationCustomFieldsTableCompanion(
            notationId: notationId,
            definitionId: definitionId,
            valueText: valueText,
            valueNumber: valueNumber,
            valueDate: valueDate,
            valueBoolean: valueBoolean,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String notationId,
            required String definitionId,
            Value<String?> valueText = const Value.absent(),
            Value<double?> valueNumber = const Value.absent(),
            Value<String?> valueDate = const Value.absent(),
            Value<int?> valueBoolean = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotationCustomFieldsTableCompanion.insert(
            notationId: notationId,
            definitionId: definitionId,
            valueText: valueText,
            valueNumber: valueNumber,
            valueDate: valueDate,
            valueBoolean: valueBoolean,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotationCustomFieldsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({notationId = false, definitionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (notationId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.notationId,
                    referencedTable: $$NotationCustomFieldsTableTableReferences
                        ._notationIdTable(db),
                    referencedColumn: $$NotationCustomFieldsTableTableReferences
                        ._notationIdTable(db)
                        .id,
                  ) as T;
                }
                if (definitionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.definitionId,
                    referencedTable: $$NotationCustomFieldsTableTableReferences
                        ._definitionIdTable(db),
                    referencedColumn: $$NotationCustomFieldsTableTableReferences
                        ._definitionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NotationCustomFieldsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $NotationCustomFieldsTableTable,
        NotationCustomFieldRow,
        $$NotationCustomFieldsTableTableFilterComposer,
        $$NotationCustomFieldsTableTableOrderingComposer,
        $$NotationCustomFieldsTableTableAnnotationComposer,
        $$NotationCustomFieldsTableTableCreateCompanionBuilder,
        $$NotationCustomFieldsTableTableUpdateCompanionBuilder,
        (NotationCustomFieldRow, $$NotationCustomFieldsTableTableReferences),
        NotationCustomFieldRow,
        PrefetchHooks Function({bool notationId, bool definitionId})>;
typedef $$UserPreferencesTableTableCreateCompanionBuilder
    = UserPreferencesTableCompanion Function({
  Value<int> id,
  Value<String> userName,
  Value<String> themeMode,
  Value<String> colorSchemeMode,
  Value<String?> seedColor,
  Value<String> defaultSort,
  Value<String> defaultView,
});
typedef $$UserPreferencesTableTableUpdateCompanionBuilder
    = UserPreferencesTableCompanion Function({
  Value<int> id,
  Value<String> userName,
  Value<String> themeMode,
  Value<String> colorSchemeMode,
  Value<String?> seedColor,
  Value<String> defaultSort,
  Value<String> defaultView,
});

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get colorSchemeMode => $composableBuilder(
      column: $table.colorSchemeMode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seedColor => $composableBuilder(
      column: $table.seedColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultSort => $composableBuilder(
      column: $table.defaultSort, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get defaultView => $composableBuilder(
      column: $table.defaultView, builder: (column) => ColumnFilters(column));
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userName => $composableBuilder(
      column: $table.userName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get colorSchemeMode => $composableBuilder(
      column: $table.colorSchemeMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seedColor => $composableBuilder(
      column: $table.seedColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultSort => $composableBuilder(
      column: $table.defaultSort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get defaultView => $composableBuilder(
      column: $table.defaultView, builder: (column) => ColumnOrderings(column));
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userName =>
      $composableBuilder(column: $table.userName, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get colorSchemeMode => $composableBuilder(
      column: $table.colorSchemeMode, builder: (column) => column);

  GeneratedColumn<String> get seedColor =>
      $composableBuilder(column: $table.seedColor, builder: (column) => column);

  GeneratedColumn<String> get defaultSort => $composableBuilder(
      column: $table.defaultSort, builder: (column) => column);

  GeneratedColumn<String> get defaultView => $composableBuilder(
      column: $table.defaultView, builder: (column) => column);
}

class $$UserPreferencesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserPreferencesTableTable,
    UserPreferencesRow,
    $$UserPreferencesTableTableFilterComposer,
    $$UserPreferencesTableTableOrderingComposer,
    $$UserPreferencesTableTableAnnotationComposer,
    $$UserPreferencesTableTableCreateCompanionBuilder,
    $$UserPreferencesTableTableUpdateCompanionBuilder,
    (
      UserPreferencesRow,
      BaseReferences<_$AppDatabase, $UserPreferencesTableTable,
          UserPreferencesRow>
    ),
    UserPreferencesRow,
    PrefetchHooks Function()> {
  $$UserPreferencesTableTableTableManager(
      _$AppDatabase db, $UserPreferencesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userName = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> colorSchemeMode = const Value.absent(),
            Value<String?> seedColor = const Value.absent(),
            Value<String> defaultSort = const Value.absent(),
            Value<String> defaultView = const Value.absent(),
          }) =>
              UserPreferencesTableCompanion(
            id: id,
            userName: userName,
            themeMode: themeMode,
            colorSchemeMode: colorSchemeMode,
            seedColor: seedColor,
            defaultSort: defaultSort,
            defaultView: defaultView,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> userName = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> colorSchemeMode = const Value.absent(),
            Value<String?> seedColor = const Value.absent(),
            Value<String> defaultSort = const Value.absent(),
            Value<String> defaultView = const Value.absent(),
          }) =>
              UserPreferencesTableCompanion.insert(
            id: id,
            userName: userName,
            themeMode: themeMode,
            colorSchemeMode: colorSchemeMode,
            seedColor: seedColor,
            defaultSort: defaultSort,
            defaultView: defaultView,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserPreferencesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserPreferencesTableTable,
        UserPreferencesRow,
        $$UserPreferencesTableTableFilterComposer,
        $$UserPreferencesTableTableOrderingComposer,
        $$UserPreferencesTableTableAnnotationComposer,
        $$UserPreferencesTableTableCreateCompanionBuilder,
        $$UserPreferencesTableTableUpdateCompanionBuilder,
        (
          UserPreferencesRow,
          BaseReferences<_$AppDatabase, $UserPreferencesTableTable,
              UserPreferencesRow>
        ),
        UserPreferencesRow,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotationsTableTableTableManager get notationsTable =>
      $$NotationsTableTableTableManager(_db, _db.notationsTable);
  $$NotationPagesTableTableTableManager get notationPagesTable =>
      $$NotationPagesTableTableTableManager(_db, _db.notationPagesTable);
  $$TagsTableTableTableManager get tagsTable =>
      $$TagsTableTableTableManager(_db, _db.tagsTable);
  $$NotationTagsTableTableTableManager get notationTagsTable =>
      $$NotationTagsTableTableTableManager(_db, _db.notationTagsTable);
  $$InstrumentClassesTableTableTableManager get instrumentClassesTable =>
      $$InstrumentClassesTableTableTableManager(
          _db, _db.instrumentClassesTable);
  $$InstrumentInstancesTableTableTableManager get instrumentInstancesTable =>
      $$InstrumentInstancesTableTableTableManager(
          _db, _db.instrumentInstancesTable);
  $$NotationInstrumentsTableTableTableManager get notationInstrumentsTable =>
      $$NotationInstrumentsTableTableTableManager(
          _db, _db.notationInstrumentsTable);
  $$CustomFieldDefinitionsTableTableTableManager
      get customFieldDefinitionsTable =>
          $$CustomFieldDefinitionsTableTableTableManager(
              _db, _db.customFieldDefinitionsTable);
  $$NotationCustomFieldsTableTableTableManager get notationCustomFieldsTable =>
      $$NotationCustomFieldsTableTableTableManager(
          _db, _db.notationCustomFieldsTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
}
