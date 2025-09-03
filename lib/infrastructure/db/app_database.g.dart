// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DailyCharacterRecordsTable extends DailyCharacterRecords
    with TableInfo<$DailyCharacterRecordsTable, DailyCharacterRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCharacterRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _characterIdMeta = const VerificationMeta(
    'characterId',
  );
  @override
  late final GeneratedColumn<String> characterId = GeneratedColumn<String>(
    'character_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yyyymmddMeta = const VerificationMeta(
    'yyyymmdd',
  );
  @override
  late final GeneratedColumn<int> yyyymmdd = GeneratedColumn<int>(
    'yyyymmdd',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _winsMeta = const VerificationMeta('wins');
  @override
  late final GeneratedColumn<int> wins = GeneratedColumn<int>(
    'wins',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lossesMeta = const VerificationMeta('losses');
  @override
  late final GeneratedColumn<int> losses = GeneratedColumn<int>(
    'losses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    gameId,
    characterId,
    yyyymmdd,
    wins,
    losses,
    memo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_character_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyCharacterRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('character_id')) {
      context.handle(
        _characterIdMeta,
        characterId.isAcceptableOrUnknown(
          data['character_id']!,
          _characterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_characterIdMeta);
    }
    if (data.containsKey('yyyymmdd')) {
      context.handle(
        _yyyymmddMeta,
        yyyymmdd.isAcceptableOrUnknown(data['yyyymmdd']!, _yyyymmddMeta),
      );
    } else if (isInserting) {
      context.missing(_yyyymmddMeta);
    }
    if (data.containsKey('wins')) {
      context.handle(
        _winsMeta,
        wins.isAcceptableOrUnknown(data['wins']!, _winsMeta),
      );
    }
    if (data.containsKey('losses')) {
      context.handle(
        _lossesMeta,
        losses.isAcceptableOrUnknown(data['losses']!, _lossesMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameId, characterId, yyyymmdd};
  @override
  DailyCharacterRecordRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCharacterRecordRow(
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      characterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_id'],
      )!,
      yyyymmdd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yyyymmdd'],
      )!,
      wins: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wins'],
      )!,
      losses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}losses'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
    );
  }

  @override
  $DailyCharacterRecordsTable createAlias(String alias) {
    return $DailyCharacterRecordsTable(attachedDatabase, alias);
  }
}

class DailyCharacterRecordRow extends DataClass
    implements Insertable<DailyCharacterRecordRow> {
  final String gameId;
  final String characterId;
  final int yyyymmdd;
  final int wins;
  final int losses;
  final String? memo;
  const DailyCharacterRecordRow({
    required this.gameId,
    required this.characterId,
    required this.yyyymmdd,
    required this.wins,
    required this.losses,
    this.memo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_id'] = Variable<String>(gameId);
    map['character_id'] = Variable<String>(characterId);
    map['yyyymmdd'] = Variable<int>(yyyymmdd);
    map['wins'] = Variable<int>(wins);
    map['losses'] = Variable<int>(losses);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    return map;
  }

  DailyCharacterRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyCharacterRecordsCompanion(
      gameId: Value(gameId),
      characterId: Value(characterId),
      yyyymmdd: Value(yyyymmdd),
      wins: Value(wins),
      losses: Value(losses),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
    );
  }

  factory DailyCharacterRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCharacterRecordRow(
      gameId: serializer.fromJson<String>(json['gameId']),
      characterId: serializer.fromJson<String>(json['characterId']),
      yyyymmdd: serializer.fromJson<int>(json['yyyymmdd']),
      wins: serializer.fromJson<int>(json['wins']),
      losses: serializer.fromJson<int>(json['losses']),
      memo: serializer.fromJson<String?>(json['memo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameId': serializer.toJson<String>(gameId),
      'characterId': serializer.toJson<String>(characterId),
      'yyyymmdd': serializer.toJson<int>(yyyymmdd),
      'wins': serializer.toJson<int>(wins),
      'losses': serializer.toJson<int>(losses),
      'memo': serializer.toJson<String?>(memo),
    };
  }

  DailyCharacterRecordRow copyWith({
    String? gameId,
    String? characterId,
    int? yyyymmdd,
    int? wins,
    int? losses,
    Value<String?> memo = const Value.absent(),
  }) => DailyCharacterRecordRow(
    gameId: gameId ?? this.gameId,
    characterId: characterId ?? this.characterId,
    yyyymmdd: yyyymmdd ?? this.yyyymmdd,
    wins: wins ?? this.wins,
    losses: losses ?? this.losses,
    memo: memo.present ? memo.value : this.memo,
  );
  DailyCharacterRecordRow copyWithCompanion(
    DailyCharacterRecordsCompanion data,
  ) {
    return DailyCharacterRecordRow(
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      characterId: data.characterId.present
          ? data.characterId.value
          : this.characterId,
      yyyymmdd: data.yyyymmdd.present ? data.yyyymmdd.value : this.yyyymmdd,
      wins: data.wins.present ? data.wins.value : this.wins,
      losses: data.losses.present ? data.losses.value : this.losses,
      memo: data.memo.present ? data.memo.value : this.memo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCharacterRecordRow(')
          ..write('gameId: $gameId, ')
          ..write('characterId: $characterId, ')
          ..write('yyyymmdd: $yyyymmdd, ')
          ..write('wins: $wins, ')
          ..write('losses: $losses, ')
          ..write('memo: $memo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(gameId, characterId, yyyymmdd, wins, losses, memo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCharacterRecordRow &&
          other.gameId == this.gameId &&
          other.characterId == this.characterId &&
          other.yyyymmdd == this.yyyymmdd &&
          other.wins == this.wins &&
          other.losses == this.losses &&
          other.memo == this.memo);
}

class DailyCharacterRecordsCompanion
    extends UpdateCompanion<DailyCharacterRecordRow> {
  final Value<String> gameId;
  final Value<String> characterId;
  final Value<int> yyyymmdd;
  final Value<int> wins;
  final Value<int> losses;
  final Value<String?> memo;
  final Value<int> rowid;
  const DailyCharacterRecordsCompanion({
    this.gameId = const Value.absent(),
    this.characterId = const Value.absent(),
    this.yyyymmdd = const Value.absent(),
    this.wins = const Value.absent(),
    this.losses = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyCharacterRecordsCompanion.insert({
    required String gameId,
    required String characterId,
    required int yyyymmdd,
    this.wins = const Value.absent(),
    this.losses = const Value.absent(),
    this.memo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : gameId = Value(gameId),
       characterId = Value(characterId),
       yyyymmdd = Value(yyyymmdd);
  static Insertable<DailyCharacterRecordRow> custom({
    Expression<String>? gameId,
    Expression<String>? characterId,
    Expression<int>? yyyymmdd,
    Expression<int>? wins,
    Expression<int>? losses,
    Expression<String>? memo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gameId != null) 'game_id': gameId,
      if (characterId != null) 'character_id': characterId,
      if (yyyymmdd != null) 'yyyymmdd': yyyymmdd,
      if (wins != null) 'wins': wins,
      if (losses != null) 'losses': losses,
      if (memo != null) 'memo': memo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyCharacterRecordsCompanion copyWith({
    Value<String>? gameId,
    Value<String>? characterId,
    Value<int>? yyyymmdd,
    Value<int>? wins,
    Value<int>? losses,
    Value<String?>? memo,
    Value<int>? rowid,
  }) {
    return DailyCharacterRecordsCompanion(
      gameId: gameId ?? this.gameId,
      characterId: characterId ?? this.characterId,
      yyyymmdd: yyyymmdd ?? this.yyyymmdd,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      memo: memo ?? this.memo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (characterId.present) {
      map['character_id'] = Variable<String>(characterId.value);
    }
    if (yyyymmdd.present) {
      map['yyyymmdd'] = Variable<int>(yyyymmdd.value);
    }
    if (wins.present) {
      map['wins'] = Variable<int>(wins.value);
    }
    if (losses.present) {
      map['losses'] = Variable<int>(losses.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyCharacterRecordsCompanion(')
          ..write('gameId: $gameId, ')
          ..write('characterId: $characterId, ')
          ..write('yyyymmdd: $yyyymmdd, ')
          ..write('wins: $wins, ')
          ..write('losses: $losses, ')
          ..write('memo: $memo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DailyCharacterRecordsTable dailyCharacterRecords =
      $DailyCharacterRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [dailyCharacterRecords];
}

typedef $$DailyCharacterRecordsTableCreateCompanionBuilder =
    DailyCharacterRecordsCompanion Function({
      required String gameId,
      required String characterId,
      required int yyyymmdd,
      Value<int> wins,
      Value<int> losses,
      Value<String?> memo,
      Value<int> rowid,
    });
typedef $$DailyCharacterRecordsTableUpdateCompanionBuilder =
    DailyCharacterRecordsCompanion Function({
      Value<String> gameId,
      Value<String> characterId,
      Value<int> yyyymmdd,
      Value<int> wins,
      Value<int> losses,
      Value<String?> memo,
      Value<int> rowid,
    });

class $$DailyCharacterRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyCharacterRecordsTable> {
  $$DailyCharacterRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yyyymmdd => $composableBuilder(
    column: $table.yyyymmdd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wins => $composableBuilder(
    column: $table.wins,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get losses => $composableBuilder(
    column: $table.losses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyCharacterRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyCharacterRecordsTable> {
  $$DailyCharacterRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yyyymmdd => $composableBuilder(
    column: $table.yyyymmdd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wins => $composableBuilder(
    column: $table.wins,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get losses => $composableBuilder(
    column: $table.losses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyCharacterRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyCharacterRecordsTable> {
  $$DailyCharacterRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get characterId => $composableBuilder(
    column: $table.characterId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get yyyymmdd =>
      $composableBuilder(column: $table.yyyymmdd, builder: (column) => column);

  GeneratedColumn<int> get wins =>
      $composableBuilder(column: $table.wins, builder: (column) => column);

  GeneratedColumn<int> get losses =>
      $composableBuilder(column: $table.losses, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);
}

class $$DailyCharacterRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyCharacterRecordsTable,
          DailyCharacterRecordRow,
          $$DailyCharacterRecordsTableFilterComposer,
          $$DailyCharacterRecordsTableOrderingComposer,
          $$DailyCharacterRecordsTableAnnotationComposer,
          $$DailyCharacterRecordsTableCreateCompanionBuilder,
          $$DailyCharacterRecordsTableUpdateCompanionBuilder,
          (
            DailyCharacterRecordRow,
            BaseReferences<
              _$AppDatabase,
              $DailyCharacterRecordsTable,
              DailyCharacterRecordRow
            >,
          ),
          DailyCharacterRecordRow,
          PrefetchHooks Function()
        > {
  $$DailyCharacterRecordsTableTableManager(
    _$AppDatabase db,
    $DailyCharacterRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyCharacterRecordsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DailyCharacterRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DailyCharacterRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> gameId = const Value.absent(),
                Value<String> characterId = const Value.absent(),
                Value<int> yyyymmdd = const Value.absent(),
                Value<int> wins = const Value.absent(),
                Value<int> losses = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCharacterRecordsCompanion(
                gameId: gameId,
                characterId: characterId,
                yyyymmdd: yyyymmdd,
                wins: wins,
                losses: losses,
                memo: memo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String gameId,
                required String characterId,
                required int yyyymmdd,
                Value<int> wins = const Value.absent(),
                Value<int> losses = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCharacterRecordsCompanion.insert(
                gameId: gameId,
                characterId: characterId,
                yyyymmdd: yyyymmdd,
                wins: wins,
                losses: losses,
                memo: memo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyCharacterRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyCharacterRecordsTable,
      DailyCharacterRecordRow,
      $$DailyCharacterRecordsTableFilterComposer,
      $$DailyCharacterRecordsTableOrderingComposer,
      $$DailyCharacterRecordsTableAnnotationComposer,
      $$DailyCharacterRecordsTableCreateCompanionBuilder,
      $$DailyCharacterRecordsTableUpdateCompanionBuilder,
      (
        DailyCharacterRecordRow,
        BaseReferences<
          _$AppDatabase,
          $DailyCharacterRecordsTable,
          DailyCharacterRecordRow
        >,
      ),
      DailyCharacterRecordRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DailyCharacterRecordsTableTableManager get dailyCharacterRecords =>
      $$DailyCharacterRecordsTableTableManager(_db, _db.dailyCharacterRecords);
}
