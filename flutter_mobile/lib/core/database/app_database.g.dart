// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppMetadataTable extends AppMetadata
    with TableInfo<$AppMetadataTable, AppMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetadataRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppMetadataTable createAlias(String alias) {
    return $AppMetadataTable(attachedDatabase, alias);
  }
}

class AppMetadataRow extends DataClass implements Insertable<AppMetadataRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppMetadataRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppMetadataCompanion toCompanion(bool nullToAbsent) {
    return AppMetadataCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetadataRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppMetadataRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppMetadataRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppMetadataRow copyWithCompanion(AppMetadataCompanion data) {
    return AppMetadataRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetadataRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetadataRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppMetadataCompanion extends UpdateCompanion<AppMetadataRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetadataCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetadataRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheFreshnessTable extends CacheFreshness
    with TableInfo<$CacheFreshnessTable, CacheFreshnessRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheFreshnessTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _ttlSecondsMeta = const VerificationMeta(
    'ttlSeconds',
  );
  @override
  late final GeneratedColumn<int> ttlSeconds = GeneratedColumn<int>(
    'ttl_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [cacheKey, fetchedAt, ttlSeconds];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_freshness';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheFreshnessRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    if (data.containsKey('ttl_seconds')) {
      context.handle(
        _ttlSecondsMeta,
        ttlSeconds.isAcceptableOrUnknown(data['ttl_seconds']!, _ttlSecondsMeta),
      );
    } else if (isInserting) {
      context.missing(_ttlSecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CacheFreshnessRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheFreshnessRow(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      ttlSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ttl_seconds'],
      )!,
    );
  }

  @override
  $CacheFreshnessTable createAlias(String alias) {
    return $CacheFreshnessTable(attachedDatabase, alias);
  }
}

class CacheFreshnessRow extends DataClass
    implements Insertable<CacheFreshnessRow> {
  final String cacheKey;
  final DateTime fetchedAt;
  final int ttlSeconds;
  const CacheFreshnessRow({
    required this.cacheKey,
    required this.fetchedAt,
    required this.ttlSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['ttl_seconds'] = Variable<int>(ttlSeconds);
    return map;
  }

  CacheFreshnessCompanion toCompanion(bool nullToAbsent) {
    return CacheFreshnessCompanion(
      cacheKey: Value(cacheKey),
      fetchedAt: Value(fetchedAt),
      ttlSeconds: Value(ttlSeconds),
    );
  }

  factory CacheFreshnessRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheFreshnessRow(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      ttlSeconds: serializer.fromJson<int>(json['ttlSeconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'ttlSeconds': serializer.toJson<int>(ttlSeconds),
    };
  }

  CacheFreshnessRow copyWith({
    String? cacheKey,
    DateTime? fetchedAt,
    int? ttlSeconds,
  }) => CacheFreshnessRow(
    cacheKey: cacheKey ?? this.cacheKey,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    ttlSeconds: ttlSeconds ?? this.ttlSeconds,
  );
  CacheFreshnessRow copyWithCompanion(CacheFreshnessCompanion data) {
    return CacheFreshnessRow(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      ttlSeconds: data.ttlSeconds.present
          ? data.ttlSeconds.value
          : this.ttlSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheFreshnessRow(')
          ..write('cacheKey: $cacheKey, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('ttlSeconds: $ttlSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, fetchedAt, ttlSeconds);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheFreshnessRow &&
          other.cacheKey == this.cacheKey &&
          other.fetchedAt == this.fetchedAt &&
          other.ttlSeconds == this.ttlSeconds);
}

class CacheFreshnessCompanion extends UpdateCompanion<CacheFreshnessRow> {
  final Value<String> cacheKey;
  final Value<DateTime> fetchedAt;
  final Value<int> ttlSeconds;
  final Value<int> rowid;
  const CacheFreshnessCompanion({
    this.cacheKey = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.ttlSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheFreshnessCompanion.insert({
    required String cacheKey,
    this.fetchedAt = const Value.absent(),
    required int ttlSeconds,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       ttlSeconds = Value(ttlSeconds);
  static Insertable<CacheFreshnessRow> custom({
    Expression<String>? cacheKey,
    Expression<DateTime>? fetchedAt,
    Expression<int>? ttlSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (ttlSeconds != null) 'ttl_seconds': ttlSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheFreshnessCompanion copyWith({
    Value<String>? cacheKey,
    Value<DateTime>? fetchedAt,
    Value<int>? ttlSeconds,
    Value<int>? rowid,
  }) {
    return CacheFreshnessCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (ttlSeconds.present) {
      map['ttl_seconds'] = Variable<int>(ttlSeconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheFreshnessCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('ttlSeconds: $ttlSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => newUuid(),
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncOpType, String> operation =
      GeneratedColumn<String>(
        'operation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncOpType>($SyncQueueTable.$converteroperation);
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMethodMeta = const VerificationMeta(
    'endpointMethod',
  );
  @override
  late final GeneratedColumn<String> endpointMethod = GeneratedColumn<String>(
    'endpoint_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointPathMeta = const VerificationMeta(
    'endpointPath',
  );
  @override
  late final GeneratedColumn<String> endpointPath = GeneratedColumn<String>(
    'endpoint_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => newUuid(),
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncOpStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        clientDefault: () => SyncOpStatus.pending.name,
      ).withConverter<SyncOpStatus>($SyncQueueTable.$converterstatus);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    endpointMethod,
    endpointPath,
    idempotencyKey,
    status,
    attempts,
    createdAt,
    lastAttemptAt,
    nextAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('endpoint_method')) {
      context.handle(
        _endpointMethodMeta,
        endpointMethod.isAcceptableOrUnknown(
          data['endpoint_method']!,
          _endpointMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endpointMethodMeta);
    }
    if (data.containsKey('endpoint_path')) {
      context.handle(
        _endpointPathMeta,
        endpointPath.isAcceptableOrUnknown(
          data['endpoint_path']!,
          _endpointPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endpointPathMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: $SyncQueueTable.$converteroperation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}operation'],
        )!,
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      endpointMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint_method'],
      )!,
      endpointPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint_path'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      status: $SyncQueueTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncOpType, String, String> $converteroperation =
      const EnumNameConverter<SyncOpType>(SyncOpType.values);
  static JsonTypeConverter2<SyncOpStatus, String, String> $converterstatus =
      const EnumNameConverter<SyncOpStatus>(SyncOpStatus.values);
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  /// Stable id; used as both primary key and audit reference.
  final String id;

  /// Domain entity name — e.g. `'invoice'`, `'customer'`. The sync engine
  /// uses it to dispatch to the right serialiser / endpoint.
  final String entityType;

  /// The id of the affected entity. May be a client-generated UUID before
  /// the server has assigned a permanent id; the id-mapping rewrite is a
  /// future-slice concern.
  final String entityId;
  final SyncOpType operation;

  /// JSON body sent to the server, pre-serialised so the queue is opaque
  /// to the sync engine (no per-entity schema knowledge needed here).
  final String payloadJson;

  /// HTTP verb (`'POST'`, `'PUT'`, `'PATCH'`, `'DELETE'`).
  final String endpointMethod;

  /// Resolved request path including any path params — already templated.
  final String endpointPath;

  /// Sent as `Idempotency-Key` request header. Lets the server collapse
  /// duplicate replays into a single side-effect when retries fire.
  final String idempotencyKey;
  final SyncOpStatus status;

  /// Number of times the op has been attempted *and failed*. Bumped only on
  /// failure; successful ops are deleted instead.
  final int attempts;
  final DateTime createdAt;

  /// Timestamp of the most recent attempt (success or failure). Null until
  /// the first claim.
  final DateTime? lastAttemptAt;

  /// Earliest moment a retry should fire — populated by the backoff
  /// strategy in Slice 0.4.3. Null means "ready immediately".
  final DateTime? nextAttemptAt;

  /// Last error message as a debugging aid; not consulted for retry
  /// decisions.
  final String? lastError;
  const SyncQueueRow({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.endpointMethod,
    required this.endpointPath,
    required this.idempotencyKey,
    required this.status,
    required this.attempts,
    required this.createdAt,
    this.lastAttemptAt,
    this.nextAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    {
      map['operation'] = Variable<String>(
        $SyncQueueTable.$converteroperation.toSql(operation),
      );
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['endpoint_method'] = Variable<String>(endpointMethod);
    map['endpoint_path'] = Variable<String>(endpointPath);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    {
      map['status'] = Variable<String>(
        $SyncQueueTable.$converterstatus.toSql(status),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      endpointMethod: Value(endpointMethod),
      endpointPath: Value(endpointPath),
      idempotencyKey: Value(idempotencyKey),
      status: Value(status),
      attempts: Value(attempts),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: $SyncQueueTable.$converteroperation.fromJson(
        serializer.fromJson<String>(json['operation']),
      ),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      endpointMethod: serializer.fromJson<String>(json['endpointMethod']),
      endpointPath: serializer.fromJson<String>(json['endpointPath']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      status: $SyncQueueTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(
        $SyncQueueTable.$converteroperation.toJson(operation),
      ),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'endpointMethod': serializer.toJson<String>(endpointMethod),
      'endpointPath': serializer.toJson<String>(endpointPath),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'status': serializer.toJson<String>(
        $SyncQueueTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueRow copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOpType? operation,
    String? payloadJson,
    String? endpointMethod,
    String? endpointPath,
    String? idempotencyKey,
    SyncOpStatus? status,
    int? attempts,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueRow(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    endpointMethod: endpointMethod ?? this.endpointMethod,
    endpointPath: endpointPath ?? this.endpointPath,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueRow copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueRow(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      endpointMethod: data.endpointMethod.present
          ? data.endpointMethod.value
          : this.endpointMethod,
      endpointPath: data.endpointPath.present
          ? data.endpointPath.value
          : this.endpointPath,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('endpointMethod: $endpointMethod, ')
          ..write('endpointPath: $endpointPath, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    operation,
    payloadJson,
    endpointMethod,
    endpointPath,
    idempotencyKey,
    status,
    attempts,
    createdAt,
    lastAttemptAt,
    nextAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.endpointMethod == this.endpointMethod &&
          other.endpointPath == this.endpointPath &&
          other.idempotencyKey == this.idempotencyKey &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<SyncOpType> operation;
  final Value<String> payloadJson;
  final Value<String> endpointMethod;
  final Value<String> endpointPath;
  final Value<String> idempotencyKey;
  final Value<SyncOpStatus> status;
  final Value<int> attempts;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.endpointMethod = const Value.absent(),
    this.endpointPath = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required SyncOpType operation,
    required String payloadJson,
    required String endpointMethod,
    required String endpointPath,
    this.idempotencyKey = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityType = Value(entityType),
       entityId = Value(entityId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       endpointMethod = Value(endpointMethod),
       endpointPath = Value(endpointPath);
  static Insertable<SyncQueueRow> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? endpointMethod,
    Expression<String>? endpointPath,
    Expression<String>? idempotencyKey,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (endpointMethod != null) 'endpoint_method': endpointMethod,
      if (endpointPath != null) 'endpoint_path': endpointPath,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<SyncOpType>? operation,
    Value<String>? payloadJson,
    Value<String>? endpointMethod,
    Value<String>? endpointPath,
    Value<String>? idempotencyKey,
    Value<SyncOpStatus>? status,
    Value<int>? attempts,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      endpointMethod: endpointMethod ?? this.endpointMethod,
      endpointPath: endpointPath ?? this.endpointPath,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(
        $SyncQueueTable.$converteroperation.toSql(operation.value),
      );
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (endpointMethod.present) {
      map['endpoint_method'] = Variable<String>(endpointMethod.value);
    }
    if (endpointPath.present) {
      map['endpoint_path'] = Variable<String>(endpointPath.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $SyncQueueTable.$converterstatus.toSql(status.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('endpointMethod: $endpointMethod, ')
          ..write('endpointPath: $endpointPath, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedUserTable extends CachedUser
    with TableInfo<$CachedUserTable, CachedUserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedUserTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, email, displayName, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_user';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedUserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedUserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedUserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedUserTable createAlias(String alias) {
    return $CachedUserTable(attachedDatabase, alias);
  }
}

class CachedUserRow extends DataClass implements Insertable<CachedUserRow> {
  /// Server-assigned user id. Used as FK target by `user_permissions`.
  final String id;
  final String email;
  final String displayName;

  /// When this row was last refreshed from the server. Lets the splash
  /// probe pick the most recently signed-in user when the device has
  /// multi-account history.
  final DateTime cachedAt;
  const CachedUserRow({
    required this.id,
    required this.email,
    required this.displayName,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedUserCompanion toCompanion(bool nullToAbsent) {
    return CachedUserCompanion(
      id: Value(id),
      email: Value(email),
      displayName: Value(displayName),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedUserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedUserRow(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedUserRow copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? cachedAt,
  }) => CachedUserRow(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedUserRow copyWithCompanion(CachedUserCompanion data) {
    return CachedUserRow(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedUserRow(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, email, displayName, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedUserRow &&
          other.id == this.id &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.cachedAt == this.cachedAt);
}

class CachedUserCompanion extends UpdateCompanion<CachedUserRow> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> displayName;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedUserCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedUserCompanion.insert({
    required String id,
    required String email,
    required String displayName,
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       displayName = Value(displayName);
  static Insertable<CachedUserRow> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedUserCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? displayName,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedUserCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedUserCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPermissionsTable extends UserPermissions
    with TableInfo<$UserPermissionsTable, UserPermissionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPermissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_user (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _permissionMeta = const VerificationMeta(
    'permission',
  );
  @override
  late final GeneratedColumn<String> permission = GeneratedColumn<String>(
    'permission',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, permission];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_permissions';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPermissionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('permission')) {
      context.handle(
        _permissionMeta,
        permission.isAcceptableOrUnknown(data['permission']!, _permissionMeta),
      );
    } else if (isInserting) {
      context.missing(_permissionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, permission};
  @override
  UserPermissionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPermissionRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      permission: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permission'],
      )!,
    );
  }

  @override
  $UserPermissionsTable createAlias(String alias) {
    return $UserPermissionsTable(attachedDatabase, alias);
  }
}

class UserPermissionRow extends DataClass
    implements Insertable<UserPermissionRow> {
  final String userId;

  /// Opaque permission token — e.g. `'finance.invoice.create'`,
  /// `'admin'`. Treated as a stable string, not parsed locally.
  final String permission;
  const UserPermissionRow({required this.userId, required this.permission});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['permission'] = Variable<String>(permission);
    return map;
  }

  UserPermissionsCompanion toCompanion(bool nullToAbsent) {
    return UserPermissionsCompanion(
      userId: Value(userId),
      permission: Value(permission),
    );
  }

  factory UserPermissionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPermissionRow(
      userId: serializer.fromJson<String>(json['userId']),
      permission: serializer.fromJson<String>(json['permission']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'permission': serializer.toJson<String>(permission),
    };
  }

  UserPermissionRow copyWith({String? userId, String? permission}) =>
      UserPermissionRow(
        userId: userId ?? this.userId,
        permission: permission ?? this.permission,
      );
  UserPermissionRow copyWithCompanion(UserPermissionsCompanion data) {
    return UserPermissionRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      permission: data.permission.present
          ? data.permission.value
          : this.permission,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPermissionRow(')
          ..write('userId: $userId, ')
          ..write('permission: $permission')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, permission);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPermissionRow &&
          other.userId == this.userId &&
          other.permission == this.permission);
}

class UserPermissionsCompanion extends UpdateCompanion<UserPermissionRow> {
  final Value<String> userId;
  final Value<String> permission;
  final Value<int> rowid;
  const UserPermissionsCompanion({
    this.userId = const Value.absent(),
    this.permission = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserPermissionsCompanion.insert({
    required String userId,
    required String permission,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       permission = Value(permission);
  static Insertable<UserPermissionRow> custom({
    Expression<String>? userId,
    Expression<String>? permission,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (permission != null) 'permission': permission,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserPermissionsCompanion copyWith({
    Value<String>? userId,
    Value<String>? permission,
    Value<int>? rowid,
  }) {
    return UserPermissionsCompanion(
      userId: userId ?? this.userId,
      permission: permission ?? this.permission,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (permission.present) {
      map['permission'] = Variable<String>(permission.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPermissionsCompanion(')
          ..write('userId: $userId, ')
          ..write('permission: $permission, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BiometricSettingsTable extends BiometricSettings
    with TableInfo<$BiometricSettingsTable, BiometricSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BiometricSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_user (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _enrolledAtMeta = const VerificationMeta(
    'enrolledAt',
  );
  @override
  late final GeneratedColumn<DateTime> enrolledAt = GeneratedColumn<DateTime>(
    'enrolled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    enabled,
    enrolledAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'biometric_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BiometricSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('enrolled_at')) {
      context.handle(
        _enrolledAtMeta,
        enrolledAt.isAcceptableOrUnknown(data['enrolled_at']!, _enrolledAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  BiometricSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BiometricSettingRow(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      enrolledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}enrolled_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BiometricSettingsTable createAlias(String alias) {
    return $BiometricSettingsTable(attachedDatabase, alias);
  }
}

class BiometricSettingRow extends DataClass
    implements Insertable<BiometricSettingRow> {
  final String userId;

  /// `true` once the user has explicitly opted in (typically via the
  /// Settings screen — Module 9). Defaults to `false` so cold installs
  /// don't surprise users with a biometric prompt before they've
  /// granted the permission.
  final bool enabled;

  /// When the user opted in, captured for audit / "biometrics enrolled
  /// 3 days ago" UX. Null when disabled.
  final DateTime? enrolledAt;
  final DateTime updatedAt;
  const BiometricSettingRow({
    required this.userId,
    required this.enabled,
    this.enrolledAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || enrolledAt != null) {
      map['enrolled_at'] = Variable<DateTime>(enrolledAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BiometricSettingsCompanion toCompanion(bool nullToAbsent) {
    return BiometricSettingsCompanion(
      userId: Value(userId),
      enabled: Value(enabled),
      enrolledAt: enrolledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(enrolledAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BiometricSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BiometricSettingRow(
      userId: serializer.fromJson<String>(json['userId']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      enrolledAt: serializer.fromJson<DateTime?>(json['enrolledAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'enabled': serializer.toJson<bool>(enabled),
      'enrolledAt': serializer.toJson<DateTime?>(enrolledAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BiometricSettingRow copyWith({
    String? userId,
    bool? enabled,
    Value<DateTime?> enrolledAt = const Value.absent(),
    DateTime? updatedAt,
  }) => BiometricSettingRow(
    userId: userId ?? this.userId,
    enabled: enabled ?? this.enabled,
    enrolledAt: enrolledAt.present ? enrolledAt.value : this.enrolledAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BiometricSettingRow copyWithCompanion(BiometricSettingsCompanion data) {
    return BiometricSettingRow(
      userId: data.userId.present ? data.userId.value : this.userId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      enrolledAt: data.enrolledAt.present
          ? data.enrolledAt.value
          : this.enrolledAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BiometricSettingRow(')
          ..write('userId: $userId, ')
          ..write('enabled: $enabled, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, enabled, enrolledAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiometricSettingRow &&
          other.userId == this.userId &&
          other.enabled == this.enabled &&
          other.enrolledAt == this.enrolledAt &&
          other.updatedAt == this.updatedAt);
}

class BiometricSettingsCompanion extends UpdateCompanion<BiometricSettingRow> {
  final Value<String> userId;
  final Value<bool> enabled;
  final Value<DateTime?> enrolledAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BiometricSettingsCompanion({
    this.userId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BiometricSettingsCompanion.insert({
    required String userId,
    this.enabled = const Value.absent(),
    this.enrolledAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<BiometricSettingRow> custom({
    Expression<String>? userId,
    Expression<bool>? enabled,
    Expression<DateTime>? enrolledAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (enabled != null) 'enabled': enabled,
      if (enrolledAt != null) 'enrolled_at': enrolledAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BiometricSettingsCompanion copyWith({
    Value<String>? userId,
    Value<bool>? enabled,
    Value<DateTime?>? enrolledAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BiometricSettingsCompanion(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (enrolledAt.present) {
      map['enrolled_at'] = Variable<DateTime>(enrolledAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BiometricSettingsCompanion(')
          ..write('userId: $userId, ')
          ..write('enabled: $enabled, ')
          ..write('enrolledAt: $enrolledAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedNotificationsTable extends CachedNotifications
    with TableInfo<$CachedNotificationsTable, CachedNotificationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newUuid,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _routeNameMeta = const VerificationMeta(
    'routeName',
  );
  @override
  late final GeneratedColumn<String> routeName = GeneratedColumn<String>(
    'route_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _routeParamsJsonMeta = const VerificationMeta(
    'routeParamsJson',
  );
  @override
  late final GeneratedColumn<String> routeParamsJson = GeneratedColumn<String>(
    'route_params_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _readAtMeta = const VerificationMeta('readAt');
  @override
  late final GeneratedColumn<DateTime> readAt = GeneratedColumn<DateTime>(
    'read_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dismissedMeta = const VerificationMeta(
    'dismissed',
  );
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
    'dismissed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dismissed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    category,
    routeName,
    routeParamsJson,
    receivedAt,
    readAt,
    dismissed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedNotificationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('route_name')) {
      context.handle(
        _routeNameMeta,
        routeName.isAcceptableOrUnknown(data['route_name']!, _routeNameMeta),
      );
    }
    if (data.containsKey('route_params_json')) {
      context.handle(
        _routeParamsJsonMeta,
        routeParamsJson.isAcceptableOrUnknown(
          data['route_params_json']!,
          _routeParamsJsonMeta,
        ),
      );
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    }
    if (data.containsKey('read_at')) {
      context.handle(
        _readAtMeta,
        readAt.isAcceptableOrUnknown(data['read_at']!, _readAtMeta),
      );
    }
    if (data.containsKey('dismissed')) {
      context.handle(
        _dismissedMeta,
        dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNotificationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNotificationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      routeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_name'],
      ),
      routeParamsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}route_params_json'],
      ),
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      readAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}read_at'],
      ),
      dismissed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dismissed'],
      )!,
    );
  }

  @override
  $CachedNotificationsTable createAlias(String alias) {
    return $CachedNotificationsTable(attachedDatabase, alias);
  }
}

class CachedNotificationRow extends DataClass
    implements Insertable<CachedNotificationRow> {
  /// UUIDv4 — generated client-side at insert time when the source
  /// (server / push) didn't provide one. Server-issued ids round-trip
  /// unchanged so dedupe works.
  final String id;
  final String title;
  final String body;

  /// Category discriminator — see file-level docs.
  final String category;

  /// Optional deep-link target: a `go_router` named route. `null` means
  /// "this notification is informational, no navigation".
  final String? routeName;

  /// JSON-encoded `Map<String, String>` of path parameters for the
  /// deep link. Empty / null when [routeName] is null or paramless.
  final String? routeParamsJson;

  /// When the server / device first emitted the notification.
  /// Newest-first ordering in the inbox is `ORDER BY received_at DESC`.
  final DateTime receivedAt;

  /// Null = unread. Set to `now()` when the user opens the row.
  final DateTime? readAt;

  /// Tombstone — `true` when the user swiped to dismiss. The row is
  /// kept to support an undo window / dismissed view; the inbox
  /// query filters them out.
  final bool dismissed;
  const CachedNotificationRow({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.routeName,
    this.routeParamsJson,
    required this.receivedAt,
    this.readAt,
    required this.dismissed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || routeName != null) {
      map['route_name'] = Variable<String>(routeName);
    }
    if (!nullToAbsent || routeParamsJson != null) {
      map['route_params_json'] = Variable<String>(routeParamsJson);
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || readAt != null) {
      map['read_at'] = Variable<DateTime>(readAt);
    }
    map['dismissed'] = Variable<bool>(dismissed);
    return map;
  }

  CachedNotificationsCompanion toCompanion(bool nullToAbsent) {
    return CachedNotificationsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      category: Value(category),
      routeName: routeName == null && nullToAbsent
          ? const Value.absent()
          : Value(routeName),
      routeParamsJson: routeParamsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(routeParamsJson),
      receivedAt: Value(receivedAt),
      readAt: readAt == null && nullToAbsent
          ? const Value.absent()
          : Value(readAt),
      dismissed: Value(dismissed),
    );
  }

  factory CachedNotificationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNotificationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      category: serializer.fromJson<String>(json['category']),
      routeName: serializer.fromJson<String?>(json['routeName']),
      routeParamsJson: serializer.fromJson<String?>(json['routeParamsJson']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      readAt: serializer.fromJson<DateTime?>(json['readAt']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'category': serializer.toJson<String>(category),
      'routeName': serializer.toJson<String?>(routeName),
      'routeParamsJson': serializer.toJson<String?>(routeParamsJson),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'readAt': serializer.toJson<DateTime?>(readAt),
      'dismissed': serializer.toJson<bool>(dismissed),
    };
  }

  CachedNotificationRow copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    Value<String?> routeName = const Value.absent(),
    Value<String?> routeParamsJson = const Value.absent(),
    DateTime? receivedAt,
    Value<DateTime?> readAt = const Value.absent(),
    bool? dismissed,
  }) => CachedNotificationRow(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    category: category ?? this.category,
    routeName: routeName.present ? routeName.value : this.routeName,
    routeParamsJson: routeParamsJson.present
        ? routeParamsJson.value
        : this.routeParamsJson,
    receivedAt: receivedAt ?? this.receivedAt,
    readAt: readAt.present ? readAt.value : this.readAt,
    dismissed: dismissed ?? this.dismissed,
  );
  CachedNotificationRow copyWithCompanion(CachedNotificationsCompanion data) {
    return CachedNotificationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      category: data.category.present ? data.category.value : this.category,
      routeName: data.routeName.present ? data.routeName.value : this.routeName,
      routeParamsJson: data.routeParamsJson.present
          ? data.routeParamsJson.value
          : this.routeParamsJson,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      readAt: data.readAt.present ? data.readAt.value : this.readAt,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotificationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('routeName: $routeName, ')
          ..write('routeParamsJson: $routeParamsJson, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('readAt: $readAt, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    body,
    category,
    routeName,
    routeParamsJson,
    receivedAt,
    readAt,
    dismissed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNotificationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.category == this.category &&
          other.routeName == this.routeName &&
          other.routeParamsJson == this.routeParamsJson &&
          other.receivedAt == this.receivedAt &&
          other.readAt == this.readAt &&
          other.dismissed == this.dismissed);
}

class CachedNotificationsCompanion
    extends UpdateCompanion<CachedNotificationRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String> category;
  final Value<String?> routeName;
  final Value<String?> routeParamsJson;
  final Value<DateTime> receivedAt;
  final Value<DateTime?> readAt;
  final Value<bool> dismissed;
  final Value<int> rowid;
  const CachedNotificationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.category = const Value.absent(),
    this.routeName = const Value.absent(),
    this.routeParamsJson = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedNotificationsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String body,
    required String category,
    this.routeName = const Value.absent(),
    this.routeParamsJson = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.readAt = const Value.absent(),
    this.dismissed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : title = Value(title),
       body = Value(body),
       category = Value(category);
  static Insertable<CachedNotificationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? category,
    Expression<String>? routeName,
    Expression<String>? routeParamsJson,
    Expression<DateTime>? receivedAt,
    Expression<DateTime>? readAt,
    Expression<bool>? dismissed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (category != null) 'category': category,
      if (routeName != null) 'route_name': routeName,
      if (routeParamsJson != null) 'route_params_json': routeParamsJson,
      if (receivedAt != null) 'received_at': receivedAt,
      if (readAt != null) 'read_at': readAt,
      if (dismissed != null) 'dismissed': dismissed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? body,
    Value<String>? category,
    Value<String?>? routeName,
    Value<String?>? routeParamsJson,
    Value<DateTime>? receivedAt,
    Value<DateTime?>? readAt,
    Value<bool>? dismissed,
    Value<int>? rowid,
  }) {
    return CachedNotificationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      routeName: routeName ?? this.routeName,
      routeParamsJson: routeParamsJson ?? this.routeParamsJson,
      receivedAt: receivedAt ?? this.receivedAt,
      readAt: readAt ?? this.readAt,
      dismissed: dismissed ?? this.dismissed,
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
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (routeName.present) {
      map['route_name'] = Variable<String>(routeName.value);
    }
    if (routeParamsJson.present) {
      map['route_params_json'] = Variable<String>(routeParamsJson.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (readAt.present) {
      map['read_at'] = Variable<DateTime>(readAt.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('category: $category, ')
          ..write('routeName: $routeName, ')
          ..write('routeParamsJson: $routeParamsJson, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('readAt: $readAt, ')
          ..write('dismissed: $dismissed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAccountsTable extends CachedAccounts
    with TableInfo<$CachedAccountsTable, CachedAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formattedBalanceMeta = const VerificationMeta(
    'formattedBalance',
  );
  @override
  late final GeneratedColumn<String> formattedBalance = GeneratedColumn<String>(
    'formatted_balance',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    type,
    parentId,
    formattedBalance,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('formatted_balance')) {
      context.handle(
        _formattedBalanceMeta,
        formattedBalance.isAcceptableOrUnknown(
          data['formatted_balance']!,
          _formattedBalanceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      formattedBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}formatted_balance'],
      ),
    );
  }

  @override
  $CachedAccountsTable createAlias(String alias) {
    return $CachedAccountsTable(attachedDatabase, alias);
  }
}

class CachedAccountRow extends DataClass
    implements Insertable<CachedAccountRow> {
  final String id;
  final String code;
  final String name;
  final String type;
  final String? parentId;
  final String? formattedBalance;
  const CachedAccountRow({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.formattedBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || formattedBalance != null) {
      map['formatted_balance'] = Variable<String>(formattedBalance);
    }
    return map;
  }

  CachedAccountsCompanion toCompanion(bool nullToAbsent) {
    return CachedAccountsCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      type: Value(type),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      formattedBalance: formattedBalance == null && nullToAbsent
          ? const Value.absent()
          : Value(formattedBalance),
    );
  }

  factory CachedAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAccountRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      formattedBalance: serializer.fromJson<String?>(json['formattedBalance']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'parentId': serializer.toJson<String?>(parentId),
      'formattedBalance': serializer.toJson<String?>(formattedBalance),
    };
  }

  CachedAccountRow copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
    Value<String?> parentId = const Value.absent(),
    Value<String?> formattedBalance = const Value.absent(),
  }) => CachedAccountRow(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    type: type ?? this.type,
    parentId: parentId.present ? parentId.value : this.parentId,
    formattedBalance: formattedBalance.present
        ? formattedBalance.value
        : this.formattedBalance,
  );
  CachedAccountRow copyWithCompanion(CachedAccountsCompanion data) {
    return CachedAccountRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      formattedBalance: data.formattedBalance.present
          ? data.formattedBalance.value
          : this.formattedBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAccountRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('formattedBalance: $formattedBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, type, parentId, formattedBalance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAccountRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.type == this.type &&
          other.parentId == this.parentId &&
          other.formattedBalance == this.formattedBalance);
}

class CachedAccountsCompanion extends UpdateCompanion<CachedAccountRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> parentId;
  final Value<String?> formattedBalance;
  final Value<int> rowid;
  const CachedAccountsCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.parentId = const Value.absent(),
    this.formattedBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAccountsCompanion.insert({
    required String id,
    required String code,
    required String name,
    required String type,
    this.parentId = const Value.absent(),
    this.formattedBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       name = Value(name),
       type = Value(type);
  static Insertable<CachedAccountRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? parentId,
    Expression<String>? formattedBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (parentId != null) 'parent_id': parentId,
      if (formattedBalance != null) 'formatted_balance': formattedBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? parentId,
    Value<String?>? formattedBalance,
    Value<int>? rowid,
  }) {
    return CachedAccountsCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      parentId: parentId ?? this.parentId,
      formattedBalance: formattedBalance ?? this.formattedBalance,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (formattedBalance.present) {
      map['formatted_balance'] = Variable<String>(formattedBalance.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAccountsCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('parentId: $parentId, ')
          ..write('formattedBalance: $formattedBalance, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedTransactionsTable extends CachedTransactions
    with TableInfo<$CachedTransactionsTable, CachedTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_accounts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
    'posted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debitMeta = const VerificationMeta('debit');
  @override
  late final GeneratedColumn<String> debit = GeneratedColumn<String>(
    'debit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creditMeta = const VerificationMeta('credit');
  @override
  late final GeneratedColumn<String> credit = GeneratedColumn<String>(
    'credit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runningBalanceMeta = const VerificationMeta(
    'runningBalance',
  );
  @override
  late final GeneratedColumn<String> runningBalance = GeneratedColumn<String>(
    'running_balance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    postedAt,
    description,
    debit,
    credit,
    runningBalance,
    reference,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_postedAtMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('debit')) {
      context.handle(
        _debitMeta,
        debit.isAcceptableOrUnknown(data['debit']!, _debitMeta),
      );
    }
    if (data.containsKey('credit')) {
      context.handle(
        _creditMeta,
        credit.isAcceptableOrUnknown(data['credit']!, _creditMeta),
      );
    }
    if (data.containsKey('running_balance')) {
      context.handle(
        _runningBalanceMeta,
        runningBalance.isAcceptableOrUnknown(
          data['running_balance']!,
          _runningBalanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_runningBalanceMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}posted_at'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      debit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debit'],
      ),
      credit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credit'],
      ),
      runningBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}running_balance'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
    );
  }

  @override
  $CachedTransactionsTable createAlias(String alias) {
    return $CachedTransactionsTable(attachedDatabase, alias);
  }
}

class CachedTransactionRow extends DataClass
    implements Insertable<CachedTransactionRow> {
  final String id;
  final String accountId;
  final DateTime postedAt;
  final String description;
  final String? debit;
  final String? credit;
  final String runningBalance;
  final String? reference;
  const CachedTransactionRow({
    required this.id,
    required this.accountId,
    required this.postedAt,
    required this.description,
    this.debit,
    this.credit,
    required this.runningBalance,
    this.reference,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['posted_at'] = Variable<DateTime>(postedAt);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || debit != null) {
      map['debit'] = Variable<String>(debit);
    }
    if (!nullToAbsent || credit != null) {
      map['credit'] = Variable<String>(credit);
    }
    map['running_balance'] = Variable<String>(runningBalance);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    return map;
  }

  CachedTransactionsCompanion toCompanion(bool nullToAbsent) {
    return CachedTransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      postedAt: Value(postedAt),
      description: Value(description),
      debit: debit == null && nullToAbsent
          ? const Value.absent()
          : Value(debit),
      credit: credit == null && nullToAbsent
          ? const Value.absent()
          : Value(credit),
      runningBalance: Value(runningBalance),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
    );
  }

  factory CachedTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      postedAt: serializer.fromJson<DateTime>(json['postedAt']),
      description: serializer.fromJson<String>(json['description']),
      debit: serializer.fromJson<String?>(json['debit']),
      credit: serializer.fromJson<String?>(json['credit']),
      runningBalance: serializer.fromJson<String>(json['runningBalance']),
      reference: serializer.fromJson<String?>(json['reference']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'postedAt': serializer.toJson<DateTime>(postedAt),
      'description': serializer.toJson<String>(description),
      'debit': serializer.toJson<String?>(debit),
      'credit': serializer.toJson<String?>(credit),
      'runningBalance': serializer.toJson<String>(runningBalance),
      'reference': serializer.toJson<String?>(reference),
    };
  }

  CachedTransactionRow copyWith({
    String? id,
    String? accountId,
    DateTime? postedAt,
    String? description,
    Value<String?> debit = const Value.absent(),
    Value<String?> credit = const Value.absent(),
    String? runningBalance,
    Value<String?> reference = const Value.absent(),
  }) => CachedTransactionRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    postedAt: postedAt ?? this.postedAt,
    description: description ?? this.description,
    debit: debit.present ? debit.value : this.debit,
    credit: credit.present ? credit.value : this.credit,
    runningBalance: runningBalance ?? this.runningBalance,
    reference: reference.present ? reference.value : this.reference,
  );
  CachedTransactionRow copyWithCompanion(CachedTransactionsCompanion data) {
    return CachedTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      description: data.description.present
          ? data.description.value
          : this.description,
      debit: data.debit.present ? data.debit.value : this.debit,
      credit: data.credit.present ? data.credit.value : this.credit,
      runningBalance: data.runningBalance.present
          ? data.runningBalance.value
          : this.runningBalance,
      reference: data.reference.present ? data.reference.value : this.reference,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTransactionRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('postedAt: $postedAt, ')
          ..write('description: $description, ')
          ..write('debit: $debit, ')
          ..write('credit: $credit, ')
          ..write('runningBalance: $runningBalance, ')
          ..write('reference: $reference')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    postedAt,
    description,
    debit,
    credit,
    runningBalance,
    reference,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTransactionRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.postedAt == this.postedAt &&
          other.description == this.description &&
          other.debit == this.debit &&
          other.credit == this.credit &&
          other.runningBalance == this.runningBalance &&
          other.reference == this.reference);
}

class CachedTransactionsCompanion
    extends UpdateCompanion<CachedTransactionRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<DateTime> postedAt;
  final Value<String> description;
  final Value<String?> debit;
  final Value<String?> credit;
  final Value<String> runningBalance;
  final Value<String?> reference;
  final Value<int> rowid;
  const CachedTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.description = const Value.absent(),
    this.debit = const Value.absent(),
    this.credit = const Value.absent(),
    this.runningBalance = const Value.absent(),
    this.reference = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedTransactionsCompanion.insert({
    required String id,
    required String accountId,
    required DateTime postedAt,
    required String description,
    this.debit = const Value.absent(),
    this.credit = const Value.absent(),
    required String runningBalance,
    this.reference = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       postedAt = Value(postedAt),
       description = Value(description),
       runningBalance = Value(runningBalance);
  static Insertable<CachedTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<DateTime>? postedAt,
    Expression<String>? description,
    Expression<String>? debit,
    Expression<String>? credit,
    Expression<String>? runningBalance,
    Expression<String>? reference,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (postedAt != null) 'posted_at': postedAt,
      if (description != null) 'description': description,
      if (debit != null) 'debit': debit,
      if (credit != null) 'credit': credit,
      if (runningBalance != null) 'running_balance': runningBalance,
      if (reference != null) 'reference': reference,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<DateTime>? postedAt,
    Value<String>? description,
    Value<String?>? debit,
    Value<String?>? credit,
    Value<String>? runningBalance,
    Value<String?>? reference,
    Value<int>? rowid,
  }) {
    return CachedTransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      postedAt: postedAt ?? this.postedAt,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      runningBalance: runningBalance ?? this.runningBalance,
      reference: reference ?? this.reference,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (debit.present) {
      map['debit'] = Variable<String>(debit.value);
    }
    if (credit.present) {
      map['credit'] = Variable<String>(credit.value);
    }
    if (runningBalance.present) {
      map['running_balance'] = Variable<String>(runningBalance.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('postedAt: $postedAt, ')
          ..write('description: $description, ')
          ..write('debit: $debit, ')
          ..write('credit: $credit, ')
          ..write('runningBalance: $runningBalance, ')
          ..write('reference: $reference, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedInvoicesTable extends CachedInvoices
    with TableInfo<$CachedInvoicesTable, CachedInvoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedInvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _issuedAtMeta = const VerificationMeta(
    'issuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
    'issued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<String> totalAmount = GeneratedColumn<String>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<String> subtotal = GeneratedColumn<String>(
    'subtotal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxMeta = const VerificationMeta('tax');
  @override
  late final GeneratedColumn<String> tax = GeneratedColumn<String>(
    'tax',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvedByMeta = const VerificationMeta(
    'approvedBy',
  );
  @override
  late final GeneratedColumn<String> approvedBy = GeneratedColumn<String>(
    'approved_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectedByMeta = const VerificationMeta(
    'rejectedBy',
  );
  @override
  late final GeneratedColumn<String> rejectedBy = GeneratedColumn<String>(
    'rejected_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectedReasonMeta = const VerificationMeta(
    'rejectedReason',
  );
  @override
  late final GeneratedColumn<String> rejectedReason = GeneratedColumn<String>(
    'rejected_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionedAtMeta = const VerificationMeta(
    'actionedAt',
  );
  @override
  late final GeneratedColumn<DateTime> actionedAt = GeneratedColumn<DateTime>(
    'actioned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceNumber,
    customerName,
    issuedAt,
    dueAt,
    status,
    totalAmount,
    currency,
    subtotal,
    tax,
    notes,
    approvedBy,
    rejectedBy,
    rejectedReason,
    actionedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_invoices';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedInvoiceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_invoiceNumberMeta);
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(
        _issuedAtMeta,
        issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('tax')) {
      context.handle(
        _taxMeta,
        tax.isAcceptableOrUnknown(data['tax']!, _taxMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('approved_by')) {
      context.handle(
        _approvedByMeta,
        approvedBy.isAcceptableOrUnknown(data['approved_by']!, _approvedByMeta),
      );
    }
    if (data.containsKey('rejected_by')) {
      context.handle(
        _rejectedByMeta,
        rejectedBy.isAcceptableOrUnknown(data['rejected_by']!, _rejectedByMeta),
      );
    }
    if (data.containsKey('rejected_reason')) {
      context.handle(
        _rejectedReasonMeta,
        rejectedReason.isAcceptableOrUnknown(
          data['rejected_reason']!,
          _rejectedReasonMeta,
        ),
      );
    }
    if (data.containsKey('actioned_at')) {
      context.handle(
        _actionedAtMeta,
        actionedAt.isAcceptableOrUnknown(data['actioned_at']!, _actionedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedInvoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedInvoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      )!,
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      issuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}issued_at'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}total_amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtotal'],
      ),
      tax: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      approvedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approved_by'],
      ),
      rejectedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_by'],
      ),
      rejectedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_reason'],
      ),
      actionedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}actioned_at'],
      ),
    );
  }

  @override
  $CachedInvoicesTable createAlias(String alias) {
    return $CachedInvoicesTable(attachedDatabase, alias);
  }
}

class CachedInvoiceRow extends DataClass
    implements Insertable<CachedInvoiceRow> {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final DateTime issuedAt;
  final DateTime dueAt;

  /// Approval workflow status — see [`InvoiceStatus`].
  final String status;

  /// Pre-formatted total (e.g. `r'$1,234.56'`).
  final String totalAmount;
  final String currency;
  final String? subtotal;
  final String? tax;
  final String? notes;
  final String? approvedBy;
  final String? rejectedBy;
  final String? rejectedReason;
  final DateTime? actionedAt;
  const CachedInvoiceRow({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.issuedAt,
    required this.dueAt,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.subtotal,
    this.tax,
    this.notes,
    this.approvedBy,
    this.rejectedBy,
    this.rejectedReason,
    this.actionedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_number'] = Variable<String>(invoiceNumber);
    map['customer_name'] = Variable<String>(customerName);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    map['due_at'] = Variable<DateTime>(dueAt);
    map['status'] = Variable<String>(status);
    map['total_amount'] = Variable<String>(totalAmount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || subtotal != null) {
      map['subtotal'] = Variable<String>(subtotal);
    }
    if (!nullToAbsent || tax != null) {
      map['tax'] = Variable<String>(tax);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || approvedBy != null) {
      map['approved_by'] = Variable<String>(approvedBy);
    }
    if (!nullToAbsent || rejectedBy != null) {
      map['rejected_by'] = Variable<String>(rejectedBy);
    }
    if (!nullToAbsent || rejectedReason != null) {
      map['rejected_reason'] = Variable<String>(rejectedReason);
    }
    if (!nullToAbsent || actionedAt != null) {
      map['actioned_at'] = Variable<DateTime>(actionedAt);
    }
    return map;
  }

  CachedInvoicesCompanion toCompanion(bool nullToAbsent) {
    return CachedInvoicesCompanion(
      id: Value(id),
      invoiceNumber: Value(invoiceNumber),
      customerName: Value(customerName),
      issuedAt: Value(issuedAt),
      dueAt: Value(dueAt),
      status: Value(status),
      totalAmount: Value(totalAmount),
      currency: Value(currency),
      subtotal: subtotal == null && nullToAbsent
          ? const Value.absent()
          : Value(subtotal),
      tax: tax == null && nullToAbsent ? const Value.absent() : Value(tax),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      approvedBy: approvedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(approvedBy),
      rejectedBy: rejectedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedBy),
      rejectedReason: rejectedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedReason),
      actionedAt: actionedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(actionedAt),
    );
  }

  factory CachedInvoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedInvoiceRow(
      id: serializer.fromJson<String>(json['id']),
      invoiceNumber: serializer.fromJson<String>(json['invoiceNumber']),
      customerName: serializer.fromJson<String>(json['customerName']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      status: serializer.fromJson<String>(json['status']),
      totalAmount: serializer.fromJson<String>(json['totalAmount']),
      currency: serializer.fromJson<String>(json['currency']),
      subtotal: serializer.fromJson<String?>(json['subtotal']),
      tax: serializer.fromJson<String?>(json['tax']),
      notes: serializer.fromJson<String?>(json['notes']),
      approvedBy: serializer.fromJson<String?>(json['approvedBy']),
      rejectedBy: serializer.fromJson<String?>(json['rejectedBy']),
      rejectedReason: serializer.fromJson<String?>(json['rejectedReason']),
      actionedAt: serializer.fromJson<DateTime?>(json['actionedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceNumber': serializer.toJson<String>(invoiceNumber),
      'customerName': serializer.toJson<String>(customerName),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'status': serializer.toJson<String>(status),
      'totalAmount': serializer.toJson<String>(totalAmount),
      'currency': serializer.toJson<String>(currency),
      'subtotal': serializer.toJson<String?>(subtotal),
      'tax': serializer.toJson<String?>(tax),
      'notes': serializer.toJson<String?>(notes),
      'approvedBy': serializer.toJson<String?>(approvedBy),
      'rejectedBy': serializer.toJson<String?>(rejectedBy),
      'rejectedReason': serializer.toJson<String?>(rejectedReason),
      'actionedAt': serializer.toJson<DateTime?>(actionedAt),
    };
  }

  CachedInvoiceRow copyWith({
    String? id,
    String? invoiceNumber,
    String? customerName,
    DateTime? issuedAt,
    DateTime? dueAt,
    String? status,
    String? totalAmount,
    String? currency,
    Value<String?> subtotal = const Value.absent(),
    Value<String?> tax = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> approvedBy = const Value.absent(),
    Value<String?> rejectedBy = const Value.absent(),
    Value<String?> rejectedReason = const Value.absent(),
    Value<DateTime?> actionedAt = const Value.absent(),
  }) => CachedInvoiceRow(
    id: id ?? this.id,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    customerName: customerName ?? this.customerName,
    issuedAt: issuedAt ?? this.issuedAt,
    dueAt: dueAt ?? this.dueAt,
    status: status ?? this.status,
    totalAmount: totalAmount ?? this.totalAmount,
    currency: currency ?? this.currency,
    subtotal: subtotal.present ? subtotal.value : this.subtotal,
    tax: tax.present ? tax.value : this.tax,
    notes: notes.present ? notes.value : this.notes,
    approvedBy: approvedBy.present ? approvedBy.value : this.approvedBy,
    rejectedBy: rejectedBy.present ? rejectedBy.value : this.rejectedBy,
    rejectedReason: rejectedReason.present
        ? rejectedReason.value
        : this.rejectedReason,
    actionedAt: actionedAt.present ? actionedAt.value : this.actionedAt,
  );
  CachedInvoiceRow copyWithCompanion(CachedInvoicesCompanion data) {
    return CachedInvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      status: data.status.present ? data.status.value : this.status,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      currency: data.currency.present ? data.currency.value : this.currency,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      tax: data.tax.present ? data.tax.value : this.tax,
      notes: data.notes.present ? data.notes.value : this.notes,
      approvedBy: data.approvedBy.present
          ? data.approvedBy.value
          : this.approvedBy,
      rejectedBy: data.rejectedBy.present
          ? data.rejectedBy.value
          : this.rejectedBy,
      rejectedReason: data.rejectedReason.present
          ? data.rejectedReason.value
          : this.rejectedReason,
      actionedAt: data.actionedAt.present
          ? data.actionedAt.value
          : this.actionedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedInvoiceRow(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('customerName: $customerName, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('notes: $notes, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('rejectedBy: $rejectedBy, ')
          ..write('rejectedReason: $rejectedReason, ')
          ..write('actionedAt: $actionedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceNumber,
    customerName,
    issuedAt,
    dueAt,
    status,
    totalAmount,
    currency,
    subtotal,
    tax,
    notes,
    approvedBy,
    rejectedBy,
    rejectedReason,
    actionedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedInvoiceRow &&
          other.id == this.id &&
          other.invoiceNumber == this.invoiceNumber &&
          other.customerName == this.customerName &&
          other.issuedAt == this.issuedAt &&
          other.dueAt == this.dueAt &&
          other.status == this.status &&
          other.totalAmount == this.totalAmount &&
          other.currency == this.currency &&
          other.subtotal == this.subtotal &&
          other.tax == this.tax &&
          other.notes == this.notes &&
          other.approvedBy == this.approvedBy &&
          other.rejectedBy == this.rejectedBy &&
          other.rejectedReason == this.rejectedReason &&
          other.actionedAt == this.actionedAt);
}

class CachedInvoicesCompanion extends UpdateCompanion<CachedInvoiceRow> {
  final Value<String> id;
  final Value<String> invoiceNumber;
  final Value<String> customerName;
  final Value<DateTime> issuedAt;
  final Value<DateTime> dueAt;
  final Value<String> status;
  final Value<String> totalAmount;
  final Value<String> currency;
  final Value<String?> subtotal;
  final Value<String?> tax;
  final Value<String?> notes;
  final Value<String?> approvedBy;
  final Value<String?> rejectedBy;
  final Value<String?> rejectedReason;
  final Value<DateTime?> actionedAt;
  final Value<int> rowid;
  const CachedInvoicesCompanion({
    this.id = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.customerName = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.status = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.currency = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.tax = const Value.absent(),
    this.notes = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.rejectedBy = const Value.absent(),
    this.rejectedReason = const Value.absent(),
    this.actionedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedInvoicesCompanion.insert({
    required String id,
    required String invoiceNumber,
    required String customerName,
    required DateTime issuedAt,
    required DateTime dueAt,
    required String status,
    required String totalAmount,
    this.currency = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.tax = const Value.absent(),
    this.notes = const Value.absent(),
    this.approvedBy = const Value.absent(),
    this.rejectedBy = const Value.absent(),
    this.rejectedReason = const Value.absent(),
    this.actionedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceNumber = Value(invoiceNumber),
       customerName = Value(customerName),
       issuedAt = Value(issuedAt),
       dueAt = Value(dueAt),
       status = Value(status),
       totalAmount = Value(totalAmount);
  static Insertable<CachedInvoiceRow> custom({
    Expression<String>? id,
    Expression<String>? invoiceNumber,
    Expression<String>? customerName,
    Expression<DateTime>? issuedAt,
    Expression<DateTime>? dueAt,
    Expression<String>? status,
    Expression<String>? totalAmount,
    Expression<String>? currency,
    Expression<String>? subtotal,
    Expression<String>? tax,
    Expression<String>? notes,
    Expression<String>? approvedBy,
    Expression<String>? rejectedBy,
    Expression<String>? rejectedReason,
    Expression<DateTime>? actionedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (customerName != null) 'customer_name': customerName,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (dueAt != null) 'due_at': dueAt,
      if (status != null) 'status': status,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (currency != null) 'currency': currency,
      if (subtotal != null) 'subtotal': subtotal,
      if (tax != null) 'tax': tax,
      if (notes != null) 'notes': notes,
      if (approvedBy != null) 'approved_by': approvedBy,
      if (rejectedBy != null) 'rejected_by': rejectedBy,
      if (rejectedReason != null) 'rejected_reason': rejectedReason,
      if (actionedAt != null) 'actioned_at': actionedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedInvoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceNumber,
    Value<String>? customerName,
    Value<DateTime>? issuedAt,
    Value<DateTime>? dueAt,
    Value<String>? status,
    Value<String>? totalAmount,
    Value<String>? currency,
    Value<String?>? subtotal,
    Value<String?>? tax,
    Value<String?>? notes,
    Value<String?>? approvedBy,
    Value<String?>? rejectedBy,
    Value<String?>? rejectedReason,
    Value<DateTime?>? actionedAt,
    Value<int>? rowid,
  }) {
    return CachedInvoicesCompanion(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerName: customerName ?? this.customerName,
      issuedAt: issuedAt ?? this.issuedAt,
      dueAt: dueAt ?? this.dueAt,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      notes: notes ?? this.notes,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      actionedAt: actionedAt ?? this.actionedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<String>(totalAmount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<String>(subtotal.value);
    }
    if (tax.present) {
      map['tax'] = Variable<String>(tax.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (approvedBy.present) {
      map['approved_by'] = Variable<String>(approvedBy.value);
    }
    if (rejectedBy.present) {
      map['rejected_by'] = Variable<String>(rejectedBy.value);
    }
    if (rejectedReason.present) {
      map['rejected_reason'] = Variable<String>(rejectedReason.value);
    }
    if (actionedAt.present) {
      map['actioned_at'] = Variable<DateTime>(actionedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedInvoicesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('customerName: $customerName, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('status: $status, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('currency: $currency, ')
          ..write('subtotal: $subtotal, ')
          ..write('tax: $tax, ')
          ..write('notes: $notes, ')
          ..write('approvedBy: $approvedBy, ')
          ..write('rejectedBy: $rejectedBy, ')
          ..write('rejectedReason: $rejectedReason, ')
          ..write('actionedAt: $actionedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedInvoiceLinesTable extends CachedInvoiceLines
    with TableInfo<$CachedInvoiceLinesTable, CachedInvoiceLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedInvoiceLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceIdMeta = const VerificationMeta(
    'invoiceId',
  );
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
    'invoice_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_invoices (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<String> unitPrice = GeneratedColumn<String>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<String> lineTotal = GeneratedColumn<String>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    invoiceId,
    position,
    description,
    sku,
    quantity,
    unitPrice,
    lineTotal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_invoice_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedInvoiceLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(
        _invoiceIdMeta,
        invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_lineTotalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedInvoiceLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedInvoiceLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      invoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_price'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_total'],
      )!,
    );
  }

  @override
  $CachedInvoiceLinesTable createAlias(String alias) {
    return $CachedInvoiceLinesTable(attachedDatabase, alias);
  }
}

class CachedInvoiceLineRow extends DataClass
    implements Insertable<CachedInvoiceLineRow> {
  final String id;
  final String invoiceId;
  final int position;
  final String description;
  final String? sku;
  final double quantity;
  final String unitPrice;
  final String lineTotal;
  const CachedInvoiceLineRow({
    required this.id,
    required this.invoiceId,
    required this.position,
    required this.description,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['position'] = Variable<int>(position);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<String>(unitPrice);
    map['line_total'] = Variable<String>(lineTotal);
    return map;
  }

  CachedInvoiceLinesCompanion toCompanion(bool nullToAbsent) {
    return CachedInvoiceLinesCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      position: Value(position),
      description: Value(description),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      lineTotal: Value(lineTotal),
    );
  }

  factory CachedInvoiceLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedInvoiceLineRow(
      id: serializer.fromJson<String>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      position: serializer.fromJson<int>(json['position']),
      description: serializer.fromJson<String>(json['description']),
      sku: serializer.fromJson<String?>(json['sku']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<String>(json['unitPrice']),
      lineTotal: serializer.fromJson<String>(json['lineTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'position': serializer.toJson<int>(position),
      'description': serializer.toJson<String>(description),
      'sku': serializer.toJson<String?>(sku),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<String>(unitPrice),
      'lineTotal': serializer.toJson<String>(lineTotal),
    };
  }

  CachedInvoiceLineRow copyWith({
    String? id,
    String? invoiceId,
    int? position,
    String? description,
    Value<String?> sku = const Value.absent(),
    double? quantity,
    String? unitPrice,
    String? lineTotal,
  }) => CachedInvoiceLineRow(
    id: id ?? this.id,
    invoiceId: invoiceId ?? this.invoiceId,
    position: position ?? this.position,
    description: description ?? this.description,
    sku: sku.present ? sku.value : this.sku,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    lineTotal: lineTotal ?? this.lineTotal,
  );
  CachedInvoiceLineRow copyWithCompanion(CachedInvoiceLinesCompanion data) {
    return CachedInvoiceLineRow(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      position: data.position.present ? data.position.value : this.position,
      description: data.description.present
          ? data.description.value
          : this.description,
      sku: data.sku.present ? data.sku.value : this.sku,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedInvoiceLineRow(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('position: $position, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('lineTotal: $lineTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    invoiceId,
    position,
    description,
    sku,
    quantity,
    unitPrice,
    lineTotal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedInvoiceLineRow &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.position == this.position &&
          other.description == this.description &&
          other.sku == this.sku &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.lineTotal == this.lineTotal);
}

class CachedInvoiceLinesCompanion
    extends UpdateCompanion<CachedInvoiceLineRow> {
  final Value<String> id;
  final Value<String> invoiceId;
  final Value<int> position;
  final Value<String> description;
  final Value<String?> sku;
  final Value<double> quantity;
  final Value<String> unitPrice;
  final Value<String> lineTotal;
  final Value<int> rowid;
  const CachedInvoiceLinesCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.position = const Value.absent(),
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedInvoiceLinesCompanion.insert({
    required String id,
    required String invoiceId,
    required int position,
    required String description,
    this.sku = const Value.absent(),
    required double quantity,
    required String unitPrice,
    required String lineTotal,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       invoiceId = Value(invoiceId),
       position = Value(position),
       description = Value(description),
       quantity = Value(quantity),
       unitPrice = Value(unitPrice),
       lineTotal = Value(lineTotal);
  static Insertable<CachedInvoiceLineRow> custom({
    Expression<String>? id,
    Expression<String>? invoiceId,
    Expression<int>? position,
    Expression<String>? description,
    Expression<String>? sku,
    Expression<double>? quantity,
    Expression<String>? unitPrice,
    Expression<String>? lineTotal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (position != null) 'position': position,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (lineTotal != null) 'line_total': lineTotal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedInvoiceLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? invoiceId,
    Value<int>? position,
    Value<String>? description,
    Value<String?>? sku,
    Value<double>? quantity,
    Value<String>? unitPrice,
    Value<String>? lineTotal,
    Value<int>? rowid,
  }) {
    return CachedInvoiceLinesCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      position: position ?? this.position,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      lineTotal: lineTotal ?? this.lineTotal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<String>(unitPrice.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<String>(lineTotal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedInvoiceLinesCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('position: $position, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedInventoryItemsTable extends CachedInventoryItems
    with TableInfo<$CachedInventoryItemsTable, CachedInventoryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedInventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warehouseCodeMeta = const VerificationMeta(
    'warehouseCode',
  );
  @override
  late final GeneratedColumn<String> warehouseCode = GeneratedColumn<String>(
    'warehouse_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationCodeMeta = const VerificationMeta(
    'locationCode',
  );
  @override
  late final GeneratedColumn<String> locationCode = GeneratedColumn<String>(
    'location_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _onHandQtyMeta = const VerificationMeta(
    'onHandQty',
  );
  @override
  late final GeneratedColumn<double> onHandQty = GeneratedColumn<double>(
    'on_hand_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reorderPointMeta = const VerificationMeta(
    'reorderPoint',
  );
  @override
  late final GeneratedColumn<double> reorderPoint = GeneratedColumn<double>(
    'reorder_point',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitCostMeta = const VerificationMeta(
    'unitCost',
  );
  @override
  late final GeneratedColumn<String> unitCost = GeneratedColumn<String>(
    'unit_cost',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sku,
    name,
    warehouseCode,
    locationCode,
    onHandQty,
    reorderPoint,
    unitCost,
    barcode,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedInventoryItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('warehouse_code')) {
      context.handle(
        _warehouseCodeMeta,
        warehouseCode.isAcceptableOrUnknown(
          data['warehouse_code']!,
          _warehouseCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warehouseCodeMeta);
    }
    if (data.containsKey('location_code')) {
      context.handle(
        _locationCodeMeta,
        locationCode.isAcceptableOrUnknown(
          data['location_code']!,
          _locationCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationCodeMeta);
    }
    if (data.containsKey('on_hand_qty')) {
      context.handle(
        _onHandQtyMeta,
        onHandQty.isAcceptableOrUnknown(data['on_hand_qty']!, _onHandQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_onHandQtyMeta);
    }
    if (data.containsKey('reorder_point')) {
      context.handle(
        _reorderPointMeta,
        reorderPoint.isAcceptableOrUnknown(
          data['reorder_point']!,
          _reorderPointMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reorderPointMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(
        _unitCostMeta,
        unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta),
      );
    } else if (isInserting) {
      context.missing(_unitCostMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedInventoryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedInventoryItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      warehouseCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warehouse_code'],
      )!,
      locationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_code'],
      )!,
      onHandQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}on_hand_qty'],
      )!,
      reorderPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reorder_point'],
      )!,
      unitCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_cost'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $CachedInventoryItemsTable createAlias(String alias) {
    return $CachedInventoryItemsTable(attachedDatabase, alias);
  }
}

class CachedInventoryItemRow extends DataClass
    implements Insertable<CachedInventoryItemRow> {
  final String id;
  final String sku;
  final String name;
  final String warehouseCode;
  final String locationCode;
  final double onHandQty;
  final double reorderPoint;
  final String unitCost;
  final String? barcode;
  final String status;
  const CachedInventoryItemRow({
    required this.id,
    required this.sku,
    required this.name,
    required this.warehouseCode,
    required this.locationCode,
    required this.onHandQty,
    required this.reorderPoint,
    required this.unitCost,
    this.barcode,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    map['warehouse_code'] = Variable<String>(warehouseCode);
    map['location_code'] = Variable<String>(locationCode);
    map['on_hand_qty'] = Variable<double>(onHandQty);
    map['reorder_point'] = Variable<double>(reorderPoint);
    map['unit_cost'] = Variable<String>(unitCost);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  CachedInventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedInventoryItemsCompanion(
      id: Value(id),
      sku: Value(sku),
      name: Value(name),
      warehouseCode: Value(warehouseCode),
      locationCode: Value(locationCode),
      onHandQty: Value(onHandQty),
      reorderPoint: Value(reorderPoint),
      unitCost: Value(unitCost),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      status: Value(status),
    );
  }

  factory CachedInventoryItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedInventoryItemRow(
      id: serializer.fromJson<String>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      warehouseCode: serializer.fromJson<String>(json['warehouseCode']),
      locationCode: serializer.fromJson<String>(json['locationCode']),
      onHandQty: serializer.fromJson<double>(json['onHandQty']),
      reorderPoint: serializer.fromJson<double>(json['reorderPoint']),
      unitCost: serializer.fromJson<String>(json['unitCost']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'warehouseCode': serializer.toJson<String>(warehouseCode),
      'locationCode': serializer.toJson<String>(locationCode),
      'onHandQty': serializer.toJson<double>(onHandQty),
      'reorderPoint': serializer.toJson<double>(reorderPoint),
      'unitCost': serializer.toJson<String>(unitCost),
      'barcode': serializer.toJson<String?>(barcode),
      'status': serializer.toJson<String>(status),
    };
  }

  CachedInventoryItemRow copyWith({
    String? id,
    String? sku,
    String? name,
    String? warehouseCode,
    String? locationCode,
    double? onHandQty,
    double? reorderPoint,
    String? unitCost,
    Value<String?> barcode = const Value.absent(),
    String? status,
  }) => CachedInventoryItemRow(
    id: id ?? this.id,
    sku: sku ?? this.sku,
    name: name ?? this.name,
    warehouseCode: warehouseCode ?? this.warehouseCode,
    locationCode: locationCode ?? this.locationCode,
    onHandQty: onHandQty ?? this.onHandQty,
    reorderPoint: reorderPoint ?? this.reorderPoint,
    unitCost: unitCost ?? this.unitCost,
    barcode: barcode.present ? barcode.value : this.barcode,
    status: status ?? this.status,
  );
  CachedInventoryItemRow copyWithCompanion(CachedInventoryItemsCompanion data) {
    return CachedInventoryItemRow(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      warehouseCode: data.warehouseCode.present
          ? data.warehouseCode.value
          : this.warehouseCode,
      locationCode: data.locationCode.present
          ? data.locationCode.value
          : this.locationCode,
      onHandQty: data.onHandQty.present ? data.onHandQty.value : this.onHandQty,
      reorderPoint: data.reorderPoint.present
          ? data.reorderPoint.value
          : this.reorderPoint,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedInventoryItemRow(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('warehouseCode: $warehouseCode, ')
          ..write('locationCode: $locationCode, ')
          ..write('onHandQty: $onHandQty, ')
          ..write('reorderPoint: $reorderPoint, ')
          ..write('unitCost: $unitCost, ')
          ..write('barcode: $barcode, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sku,
    name,
    warehouseCode,
    locationCode,
    onHandQty,
    reorderPoint,
    unitCost,
    barcode,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedInventoryItemRow &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.warehouseCode == this.warehouseCode &&
          other.locationCode == this.locationCode &&
          other.onHandQty == this.onHandQty &&
          other.reorderPoint == this.reorderPoint &&
          other.unitCost == this.unitCost &&
          other.barcode == this.barcode &&
          other.status == this.status);
}

class CachedInventoryItemsCompanion
    extends UpdateCompanion<CachedInventoryItemRow> {
  final Value<String> id;
  final Value<String> sku;
  final Value<String> name;
  final Value<String> warehouseCode;
  final Value<String> locationCode;
  final Value<double> onHandQty;
  final Value<double> reorderPoint;
  final Value<String> unitCost;
  final Value<String?> barcode;
  final Value<String> status;
  final Value<int> rowid;
  const CachedInventoryItemsCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.warehouseCode = const Value.absent(),
    this.locationCode = const Value.absent(),
    this.onHandQty = const Value.absent(),
    this.reorderPoint = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.barcode = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedInventoryItemsCompanion.insert({
    required String id,
    required String sku,
    required String name,
    required String warehouseCode,
    required String locationCode,
    required double onHandQty,
    required double reorderPoint,
    required String unitCost,
    this.barcode = const Value.absent(),
    required String status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sku = Value(sku),
       name = Value(name),
       warehouseCode = Value(warehouseCode),
       locationCode = Value(locationCode),
       onHandQty = Value(onHandQty),
       reorderPoint = Value(reorderPoint),
       unitCost = Value(unitCost),
       status = Value(status);
  static Insertable<CachedInventoryItemRow> custom({
    Expression<String>? id,
    Expression<String>? sku,
    Expression<String>? name,
    Expression<String>? warehouseCode,
    Expression<String>? locationCode,
    Expression<double>? onHandQty,
    Expression<double>? reorderPoint,
    Expression<String>? unitCost,
    Expression<String>? barcode,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (warehouseCode != null) 'warehouse_code': warehouseCode,
      if (locationCode != null) 'location_code': locationCode,
      if (onHandQty != null) 'on_hand_qty': onHandQty,
      if (reorderPoint != null) 'reorder_point': reorderPoint,
      if (unitCost != null) 'unit_cost': unitCost,
      if (barcode != null) 'barcode': barcode,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedInventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? sku,
    Value<String>? name,
    Value<String>? warehouseCode,
    Value<String>? locationCode,
    Value<double>? onHandQty,
    Value<double>? reorderPoint,
    Value<String>? unitCost,
    Value<String?>? barcode,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return CachedInventoryItemsCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      warehouseCode: warehouseCode ?? this.warehouseCode,
      locationCode: locationCode ?? this.locationCode,
      onHandQty: onHandQty ?? this.onHandQty,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      unitCost: unitCost ?? this.unitCost,
      barcode: barcode ?? this.barcode,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (warehouseCode.present) {
      map['warehouse_code'] = Variable<String>(warehouseCode.value);
    }
    if (locationCode.present) {
      map['location_code'] = Variable<String>(locationCode.value);
    }
    if (onHandQty.present) {
      map['on_hand_qty'] = Variable<double>(onHandQty.value);
    }
    if (reorderPoint.present) {
      map['reorder_point'] = Variable<double>(reorderPoint.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<String>(unitCost.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedInventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('warehouseCode: $warehouseCode, ')
          ..write('locationCode: $locationCode, ')
          ..write('onHandQty: $onHandQty, ')
          ..write('reorderPoint: $reorderPoint, ')
          ..write('unitCost: $unitCost, ')
          ..write('barcode: $barcode, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedStockMovementsTable extends CachedStockMovements
    with TableInfo<$CachedStockMovementsTable, CachedStockMovementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStockMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_inventory_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _postedAtMeta = const VerificationMeta(
    'postedAt',
  );
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
    'posted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runningQtyMeta = const VerificationMeta(
    'runningQty',
  );
  @override
  late final GeneratedColumn<double> runningQty = GeneratedColumn<double>(
    'running_qty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    postedAt,
    type,
    quantity,
    runningQty,
    reference,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_stock_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStockMovementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('posted_at')) {
      context.handle(
        _postedAtMeta,
        postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_postedAtMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('running_qty')) {
      context.handle(
        _runningQtyMeta,
        runningQty.isAcceptableOrUnknown(data['running_qty']!, _runningQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_runningQtyMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedStockMovementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStockMovementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      postedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}posted_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      runningQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}running_qty'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CachedStockMovementsTable createAlias(String alias) {
    return $CachedStockMovementsTable(attachedDatabase, alias);
  }
}

class CachedStockMovementRow extends DataClass
    implements Insertable<CachedStockMovementRow> {
  final String id;
  final String itemId;
  final DateTime postedAt;
  final String type;
  final double quantity;
  final double runningQty;
  final String? reference;
  final String? note;
  const CachedStockMovementRow({
    required this.id,
    required this.itemId,
    required this.postedAt,
    required this.type,
    required this.quantity,
    required this.runningQty,
    this.reference,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['posted_at'] = Variable<DateTime>(postedAt);
    map['type'] = Variable<String>(type);
    map['quantity'] = Variable<double>(quantity);
    map['running_qty'] = Variable<double>(runningQty);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CachedStockMovementsCompanion toCompanion(bool nullToAbsent) {
    return CachedStockMovementsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      postedAt: Value(postedAt),
      type: Value(type),
      quantity: Value(quantity),
      runningQty: Value(runningQty),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CachedStockMovementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStockMovementRow(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      postedAt: serializer.fromJson<DateTime>(json['postedAt']),
      type: serializer.fromJson<String>(json['type']),
      quantity: serializer.fromJson<double>(json['quantity']),
      runningQty: serializer.fromJson<double>(json['runningQty']),
      reference: serializer.fromJson<String?>(json['reference']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'postedAt': serializer.toJson<DateTime>(postedAt),
      'type': serializer.toJson<String>(type),
      'quantity': serializer.toJson<double>(quantity),
      'runningQty': serializer.toJson<double>(runningQty),
      'reference': serializer.toJson<String?>(reference),
      'note': serializer.toJson<String?>(note),
    };
  }

  CachedStockMovementRow copyWith({
    String? id,
    String? itemId,
    DateTime? postedAt,
    String? type,
    double? quantity,
    double? runningQty,
    Value<String?> reference = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => CachedStockMovementRow(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    postedAt: postedAt ?? this.postedAt,
    type: type ?? this.type,
    quantity: quantity ?? this.quantity,
    runningQty: runningQty ?? this.runningQty,
    reference: reference.present ? reference.value : this.reference,
    note: note.present ? note.value : this.note,
  );
  CachedStockMovementRow copyWithCompanion(CachedStockMovementsCompanion data) {
    return CachedStockMovementRow(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      type: data.type.present ? data.type.value : this.type,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      runningQty: data.runningQty.present
          ? data.runningQty.value
          : this.runningQty,
      reference: data.reference.present ? data.reference.value : this.reference,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStockMovementRow(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('postedAt: $postedAt, ')
          ..write('type: $type, ')
          ..write('quantity: $quantity, ')
          ..write('runningQty: $runningQty, ')
          ..write('reference: $reference, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    postedAt,
    type,
    quantity,
    runningQty,
    reference,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStockMovementRow &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.postedAt == this.postedAt &&
          other.type == this.type &&
          other.quantity == this.quantity &&
          other.runningQty == this.runningQty &&
          other.reference == this.reference &&
          other.note == this.note);
}

class CachedStockMovementsCompanion
    extends UpdateCompanion<CachedStockMovementRow> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<DateTime> postedAt;
  final Value<String> type;
  final Value<double> quantity;
  final Value<double> runningQty;
  final Value<String?> reference;
  final Value<String?> note;
  final Value<int> rowid;
  const CachedStockMovementsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.quantity = const Value.absent(),
    this.runningQty = const Value.absent(),
    this.reference = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedStockMovementsCompanion.insert({
    required String id,
    required String itemId,
    required DateTime postedAt,
    required String type,
    required double quantity,
    required double runningQty,
    this.reference = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       postedAt = Value(postedAt),
       type = Value(type),
       quantity = Value(quantity),
       runningQty = Value(runningQty);
  static Insertable<CachedStockMovementRow> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<DateTime>? postedAt,
    Expression<String>? type,
    Expression<double>? quantity,
    Expression<double>? runningQty,
    Expression<String>? reference,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (postedAt != null) 'posted_at': postedAt,
      if (type != null) 'type': type,
      if (quantity != null) 'quantity': quantity,
      if (runningQty != null) 'running_qty': runningQty,
      if (reference != null) 'reference': reference,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedStockMovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<DateTime>? postedAt,
    Value<String>? type,
    Value<double>? quantity,
    Value<double>? runningQty,
    Value<String?>? reference,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return CachedStockMovementsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      postedAt: postedAt ?? this.postedAt,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      runningQty: runningQty ?? this.runningQty,
      reference: reference ?? this.reference,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (runningQty.present) {
      map['running_qty'] = Variable<double>(runningQty.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStockMovementsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('postedAt: $postedAt, ')
          ..write('type: $type, ')
          ..write('quantity: $quantity, ')
          ..write('runningQty: $runningQty, ')
          ..write('reference: $reference, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppMetadataTable appMetadata = $AppMetadataTable(this);
  late final $CacheFreshnessTable cacheFreshness = $CacheFreshnessTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $CachedUserTable cachedUser = $CachedUserTable(this);
  late final $UserPermissionsTable userPermissions = $UserPermissionsTable(
    this,
  );
  late final $BiometricSettingsTable biometricSettings =
      $BiometricSettingsTable(this);
  late final $CachedNotificationsTable cachedNotifications =
      $CachedNotificationsTable(this);
  late final $CachedAccountsTable cachedAccounts = $CachedAccountsTable(this);
  late final $CachedTransactionsTable cachedTransactions =
      $CachedTransactionsTable(this);
  late final $CachedInvoicesTable cachedInvoices = $CachedInvoicesTable(this);
  late final $CachedInvoiceLinesTable cachedInvoiceLines =
      $CachedInvoiceLinesTable(this);
  late final $CachedInventoryItemsTable cachedInventoryItems =
      $CachedInventoryItemsTable(this);
  late final $CachedStockMovementsTable cachedStockMovements =
      $CachedStockMovementsTable(this);
  late final AppMetadataDao appMetadataDao = AppMetadataDao(
    this as AppDatabase,
  );
  late final CacheFreshnessDao cacheFreshnessDao = CacheFreshnessDao(
    this as AppDatabase,
  );
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final CachedUserDao cachedUserDao = CachedUserDao(this as AppDatabase);
  late final BiometricSettingsDao biometricSettingsDao = BiometricSettingsDao(
    this as AppDatabase,
  );
  late final NotificationsDao notificationsDao = NotificationsDao(
    this as AppDatabase,
  );
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final InvoicesDao invoicesDao = InvoicesDao(this as AppDatabase);
  late final ItemsDao itemsDao = ItemsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMetadata,
    cacheFreshness,
    syncQueue,
    cachedUser,
    userPermissions,
    biometricSettings,
    cachedNotifications,
    cachedAccounts,
    cachedTransactions,
    cachedInvoices,
    cachedInvoiceLines,
    cachedInventoryItems,
    cachedStockMovements,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cached_user',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_permissions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cached_user',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('biometric_settings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cached_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cached_transactions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cached_invoices',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cached_invoice_lines', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cached_inventory_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cached_stock_movements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AppMetadataTableCreateCompanionBuilder =
    AppMetadataCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AppMetadataTableUpdateCompanionBuilder =
    AppMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetadataTable,
          AppMetadataRow,
          $$AppMetadataTableFilterComposer,
          $$AppMetadataTableOrderingComposer,
          $$AppMetadataTableAnnotationComposer,
          $$AppMetadataTableCreateCompanionBuilder,
          $$AppMetadataTableUpdateCompanionBuilder,
          (
            AppMetadataRow,
            BaseReferences<_$AppDatabase, $AppMetadataTable, AppMetadataRow>,
          ),
          AppMetadataRow,
          PrefetchHooks Function()
        > {
  $$AppMetadataTableTableManager(_$AppDatabase db, $AppMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetadataCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetadataCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetadataTable,
      AppMetadataRow,
      $$AppMetadataTableFilterComposer,
      $$AppMetadataTableOrderingComposer,
      $$AppMetadataTableAnnotationComposer,
      $$AppMetadataTableCreateCompanionBuilder,
      $$AppMetadataTableUpdateCompanionBuilder,
      (
        AppMetadataRow,
        BaseReferences<_$AppDatabase, $AppMetadataTable, AppMetadataRow>,
      ),
      AppMetadataRow,
      PrefetchHooks Function()
    >;
typedef $$CacheFreshnessTableCreateCompanionBuilder =
    CacheFreshnessCompanion Function({
      required String cacheKey,
      Value<DateTime> fetchedAt,
      required int ttlSeconds,
      Value<int> rowid,
    });
typedef $$CacheFreshnessTableUpdateCompanionBuilder =
    CacheFreshnessCompanion Function({
      Value<String> cacheKey,
      Value<DateTime> fetchedAt,
      Value<int> ttlSeconds,
      Value<int> rowid,
    });

class $$CacheFreshnessTableFilterComposer
    extends Composer<_$AppDatabase, $CacheFreshnessTable> {
  $$CacheFreshnessTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheFreshnessTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheFreshnessTable> {
  $$CacheFreshnessTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheFreshnessTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheFreshnessTable> {
  $$CacheFreshnessTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get ttlSeconds => $composableBuilder(
    column: $table.ttlSeconds,
    builder: (column) => column,
  );
}

class $$CacheFreshnessTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheFreshnessTable,
          CacheFreshnessRow,
          $$CacheFreshnessTableFilterComposer,
          $$CacheFreshnessTableOrderingComposer,
          $$CacheFreshnessTableAnnotationComposer,
          $$CacheFreshnessTableCreateCompanionBuilder,
          $$CacheFreshnessTableUpdateCompanionBuilder,
          (
            CacheFreshnessRow,
            BaseReferences<
              _$AppDatabase,
              $CacheFreshnessTable,
              CacheFreshnessRow
            >,
          ),
          CacheFreshnessRow,
          PrefetchHooks Function()
        > {
  $$CacheFreshnessTableTableManager(
    _$AppDatabase db,
    $CacheFreshnessTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheFreshnessTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheFreshnessTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheFreshnessTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> ttlSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheFreshnessCompanion(
                cacheKey: cacheKey,
                fetchedAt: fetchedAt,
                ttlSeconds: ttlSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                Value<DateTime> fetchedAt = const Value.absent(),
                required int ttlSeconds,
                Value<int> rowid = const Value.absent(),
              }) => CacheFreshnessCompanion.insert(
                cacheKey: cacheKey,
                fetchedAt: fetchedAt,
                ttlSeconds: ttlSeconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheFreshnessTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheFreshnessTable,
      CacheFreshnessRow,
      $$CacheFreshnessTableFilterComposer,
      $$CacheFreshnessTableOrderingComposer,
      $$CacheFreshnessTableAnnotationComposer,
      $$CacheFreshnessTableCreateCompanionBuilder,
      $$CacheFreshnessTableUpdateCompanionBuilder,
      (
        CacheFreshnessRow,
        BaseReferences<_$AppDatabase, $CacheFreshnessTable, CacheFreshnessRow>,
      ),
      CacheFreshnessRow,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      required String entityType,
      required String entityId,
      required SyncOpType operation,
      required String payloadJson,
      required String endpointMethod,
      required String endpointPath,
      Value<String> idempotencyKey,
      Value<SyncOpStatus> status,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<SyncOpType> operation,
      Value<String> payloadJson,
      Value<String> endpointMethod,
      Value<String> endpointPath,
      Value<String> idempotencyKey,
      Value<SyncOpStatus> status,
      Value<int> attempts,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncOpType, SyncOpType, String>
  get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpointMethod => $composableBuilder(
    column: $table.endpointMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpointPath => $composableBuilder(
    column: $table.endpointPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncOpStatus, SyncOpStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpointMethod => $composableBuilder(
    column: $table.endpointMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpointPath => $composableBuilder(
    column: $table.endpointPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncOpType, String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpointMethod => $composableBuilder(
    column: $table.endpointMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpointPath => $composableBuilder(
    column: $table.endpointPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncOpStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueRow,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<SyncOpType> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> endpointMethod = const Value.absent(),
                Value<String> endpointPath = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<SyncOpStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                endpointMethod: endpointMethod,
                endpointPath: endpointPath,
                idempotencyKey: idempotencyKey,
                status: status,
                attempts: attempts,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String entityType,
                required String entityId,
                required SyncOpType operation,
                required String payloadJson,
                required String endpointMethod,
                required String endpointPath,
                Value<String> idempotencyKey = const Value.absent(),
                Value<SyncOpStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                endpointMethod: endpointMethod,
                endpointPath: endpointPath,
                idempotencyKey: idempotencyKey,
                status: status,
                attempts: attempts,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueRow,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
    >;
typedef $$CachedUserTableCreateCompanionBuilder =
    CachedUserCompanion Function({
      required String id,
      required String email,
      required String displayName,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedUserTableUpdateCompanionBuilder =
    CachedUserCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> displayName,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

final class $$CachedUserTableReferences
    extends BaseReferences<_$AppDatabase, $CachedUserTable, CachedUserRow> {
  $$CachedUserTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserPermissionsTable, List<UserPermissionRow>>
  _userPermissionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userPermissions,
    aliasName: $_aliasNameGenerator(
      db.cachedUser.id,
      db.userPermissions.userId,
    ),
  );

  $$UserPermissionsTableProcessedTableManager get userPermissionsRefs {
    final manager = $$UserPermissionsTableTableManager(
      $_db,
      $_db.userPermissions,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userPermissionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BiometricSettingsTable, List<BiometricSettingRow>>
  _biometricSettingsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.biometricSettings,
        aliasName: $_aliasNameGenerator(
          db.cachedUser.id,
          db.biometricSettings.userId,
        ),
      );

  $$BiometricSettingsTableProcessedTableManager get biometricSettingsRefs {
    final manager = $$BiometricSettingsTableTableManager(
      $_db,
      $_db.biometricSettings,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _biometricSettingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedUserTableFilterComposer
    extends Composer<_$AppDatabase, $CachedUserTable> {
  $$CachedUserTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userPermissionsRefs(
    Expression<bool> Function($$UserPermissionsTableFilterComposer f) f,
  ) {
    final $$UserPermissionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPermissions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPermissionsTableFilterComposer(
            $db: $db,
            $table: $db.userPermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> biometricSettingsRefs(
    Expression<bool> Function($$BiometricSettingsTableFilterComposer f) f,
  ) {
    final $$BiometricSettingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.biometricSettings,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiometricSettingsTableFilterComposer(
            $db: $db,
            $table: $db.biometricSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedUserTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedUserTable> {
  $$CachedUserTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedUserTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedUserTable> {
  $$CachedUserTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  Expression<T> userPermissionsRefs<T extends Object>(
    Expression<T> Function($$UserPermissionsTableAnnotationComposer a) f,
  ) {
    final $$UserPermissionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userPermissions,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPermissionsTableAnnotationComposer(
            $db: $db,
            $table: $db.userPermissions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> biometricSettingsRefs<T extends Object>(
    Expression<T> Function($$BiometricSettingsTableAnnotationComposer a) f,
  ) {
    final $$BiometricSettingsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.biometricSettings,
          getReferencedColumn: (t) => t.userId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiometricSettingsTableAnnotationComposer(
                $db: $db,
                $table: $db.biometricSettings,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedUserTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedUserTable,
          CachedUserRow,
          $$CachedUserTableFilterComposer,
          $$CachedUserTableOrderingComposer,
          $$CachedUserTableAnnotationComposer,
          $$CachedUserTableCreateCompanionBuilder,
          $$CachedUserTableUpdateCompanionBuilder,
          (CachedUserRow, $$CachedUserTableReferences),
          CachedUserRow,
          PrefetchHooks Function({
            bool userPermissionsRefs,
            bool biometricSettingsRefs,
          })
        > {
  $$CachedUserTableTableManager(_$AppDatabase db, $CachedUserTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedUserTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedUserTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedUserTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUserCompanion(
                id: id,
                email: email,
                displayName: displayName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String displayName,
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedUserCompanion.insert(
                id: id,
                email: email,
                displayName: displayName,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedUserTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userPermissionsRefs = false, biometricSettingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (userPermissionsRefs) db.userPermissions,
                    if (biometricSettingsRefs) db.biometricSettings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (userPermissionsRefs)
                        await $_getPrefetchedData<
                          CachedUserRow,
                          $CachedUserTable,
                          UserPermissionRow
                        >(
                          currentTable: table,
                          referencedTable: $$CachedUserTableReferences
                              ._userPermissionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedUserTableReferences(
                                db,
                                table,
                                p0,
                              ).userPermissionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (biometricSettingsRefs)
                        await $_getPrefetchedData<
                          CachedUserRow,
                          $CachedUserTable,
                          BiometricSettingRow
                        >(
                          currentTable: table,
                          referencedTable: $$CachedUserTableReferences
                              ._biometricSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedUserTableReferences(
                                db,
                                table,
                                p0,
                              ).biometricSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CachedUserTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedUserTable,
      CachedUserRow,
      $$CachedUserTableFilterComposer,
      $$CachedUserTableOrderingComposer,
      $$CachedUserTableAnnotationComposer,
      $$CachedUserTableCreateCompanionBuilder,
      $$CachedUserTableUpdateCompanionBuilder,
      (CachedUserRow, $$CachedUserTableReferences),
      CachedUserRow,
      PrefetchHooks Function({
        bool userPermissionsRefs,
        bool biometricSettingsRefs,
      })
    >;
typedef $$UserPermissionsTableCreateCompanionBuilder =
    UserPermissionsCompanion Function({
      required String userId,
      required String permission,
      Value<int> rowid,
    });
typedef $$UserPermissionsTableUpdateCompanionBuilder =
    UserPermissionsCompanion Function({
      Value<String> userId,
      Value<String> permission,
      Value<int> rowid,
    });

final class $$UserPermissionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserPermissionsTable,
          UserPermissionRow
        > {
  $$UserPermissionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedUserTable _userIdTable(_$AppDatabase db) =>
      db.cachedUser.createAlias(
        $_aliasNameGenerator(db.userPermissions.userId, db.cachedUser.id),
      );

  $$CachedUserTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$CachedUserTableTableManager(
      $_db,
      $_db.cachedUser,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserPermissionsTableFilterComposer
    extends Composer<_$AppDatabase, $UserPermissionsTable> {
  $$UserPermissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedUserTableFilterComposer get userId {
    final $$CachedUserTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.cachedUser,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUserTableFilterComposer(
            $db: $db,
            $table: $db.cachedUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPermissionsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPermissionsTable> {
  $$UserPermissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedUserTableOrderingComposer get userId {
    final $$CachedUserTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.cachedUser,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUserTableOrderingComposer(
            $db: $db,
            $table: $db.cachedUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPermissionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPermissionsTable> {
  $$UserPermissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get permission => $composableBuilder(
    column: $table.permission,
    builder: (column) => column,
  );

  $$CachedUserTableAnnotationComposer get userId {
    final $$CachedUserTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.cachedUser,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUserTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserPermissionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPermissionsTable,
          UserPermissionRow,
          $$UserPermissionsTableFilterComposer,
          $$UserPermissionsTableOrderingComposer,
          $$UserPermissionsTableAnnotationComposer,
          $$UserPermissionsTableCreateCompanionBuilder,
          $$UserPermissionsTableUpdateCompanionBuilder,
          (UserPermissionRow, $$UserPermissionsTableReferences),
          UserPermissionRow,
          PrefetchHooks Function({bool userId})
        > {
  $$UserPermissionsTableTableManager(
    _$AppDatabase db,
    $UserPermissionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPermissionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPermissionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPermissionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> permission = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserPermissionsCompanion(
                userId: userId,
                permission: permission,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String permission,
                Value<int> rowid = const Value.absent(),
              }) => UserPermissionsCompanion.insert(
                userId: userId,
                permission: permission,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserPermissionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$UserPermissionsTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$UserPermissionsTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserPermissionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPermissionsTable,
      UserPermissionRow,
      $$UserPermissionsTableFilterComposer,
      $$UserPermissionsTableOrderingComposer,
      $$UserPermissionsTableAnnotationComposer,
      $$UserPermissionsTableCreateCompanionBuilder,
      $$UserPermissionsTableUpdateCompanionBuilder,
      (UserPermissionRow, $$UserPermissionsTableReferences),
      UserPermissionRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$BiometricSettingsTableCreateCompanionBuilder =
    BiometricSettingsCompanion Function({
      required String userId,
      Value<bool> enabled,
      Value<DateTime?> enrolledAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BiometricSettingsTableUpdateCompanionBuilder =
    BiometricSettingsCompanion Function({
      Value<String> userId,
      Value<bool> enabled,
      Value<DateTime?> enrolledAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BiometricSettingsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BiometricSettingsTable,
          BiometricSettingRow
        > {
  $$BiometricSettingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedUserTable _userIdTable(_$AppDatabase db) =>
      db.cachedUser.createAlias(
        $_aliasNameGenerator(db.biometricSettings.userId, db.cachedUser.id),
      );

  $$CachedUserTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $$CachedUserTableTableManager(
      $_db,
      $_db.cachedUser,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BiometricSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BiometricSettingsTable> {
  $$BiometricSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedUserTableFilterComposer get userId {
    final $$CachedUserTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.cachedUser,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUserTableFilterComposer(
            $db: $db,
            $table: $db.cachedUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiometricSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BiometricSettingsTable> {
  $$BiometricSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedUserTableOrderingComposer get userId {
    final $$CachedUserTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.cachedUser,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUserTableOrderingComposer(
            $db: $db,
            $table: $db.cachedUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiometricSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BiometricSettingsTable> {
  $$BiometricSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get enrolledAt => $composableBuilder(
    column: $table.enrolledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CachedUserTableAnnotationComposer get userId {
    final $$CachedUserTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.cachedUser,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedUserTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiometricSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BiometricSettingsTable,
          BiometricSettingRow,
          $$BiometricSettingsTableFilterComposer,
          $$BiometricSettingsTableOrderingComposer,
          $$BiometricSettingsTableAnnotationComposer,
          $$BiometricSettingsTableCreateCompanionBuilder,
          $$BiometricSettingsTableUpdateCompanionBuilder,
          (BiometricSettingRow, $$BiometricSettingsTableReferences),
          BiometricSettingRow,
          PrefetchHooks Function({bool userId})
        > {
  $$BiometricSettingsTableTableManager(
    _$AppDatabase db,
    $BiometricSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BiometricSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BiometricSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BiometricSettingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> enrolledAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiometricSettingsCompanion(
                userId: userId,
                enabled: enabled,
                enrolledAt: enrolledAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<bool> enabled = const Value.absent(),
                Value<DateTime?> enrolledAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiometricSettingsCompanion.insert(
                userId: userId,
                enabled: enabled,
                enrolledAt: enrolledAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BiometricSettingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable:
                                    $$BiometricSettingsTableReferences
                                        ._userIdTable(db),
                                referencedColumn:
                                    $$BiometricSettingsTableReferences
                                        ._userIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BiometricSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BiometricSettingsTable,
      BiometricSettingRow,
      $$BiometricSettingsTableFilterComposer,
      $$BiometricSettingsTableOrderingComposer,
      $$BiometricSettingsTableAnnotationComposer,
      $$BiometricSettingsTableCreateCompanionBuilder,
      $$BiometricSettingsTableUpdateCompanionBuilder,
      (BiometricSettingRow, $$BiometricSettingsTableReferences),
      BiometricSettingRow,
      PrefetchHooks Function({bool userId})
    >;
typedef $$CachedNotificationsTableCreateCompanionBuilder =
    CachedNotificationsCompanion Function({
      Value<String> id,
      required String title,
      required String body,
      required String category,
      Value<String?> routeName,
      Value<String?> routeParamsJson,
      Value<DateTime> receivedAt,
      Value<DateTime?> readAt,
      Value<bool> dismissed,
      Value<int> rowid,
    });
typedef $$CachedNotificationsTableUpdateCompanionBuilder =
    CachedNotificationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> body,
      Value<String> category,
      Value<String?> routeName,
      Value<String?> routeParamsJson,
      Value<DateTime> receivedAt,
      Value<DateTime?> readAt,
      Value<bool> dismissed,
      Value<int> rowid,
    });

class $$CachedNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeName => $composableBuilder(
    column: $table.routeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get routeParamsJson => $composableBuilder(
    column: $table.routeParamsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeName => $composableBuilder(
    column: $table.routeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get routeParamsJson => $composableBuilder(
    column: $table.routeParamsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get readAt => $composableBuilder(
    column: $table.readAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dismissed => $composableBuilder(
    column: $table.dismissed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotificationsTable> {
  $$CachedNotificationsTableAnnotationComposer({
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

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get routeName =>
      $composableBuilder(column: $table.routeName, builder: (column) => column);

  GeneratedColumn<String> get routeParamsJson => $composableBuilder(
    column: $table.routeParamsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get readAt =>
      $composableBuilder(column: $table.readAt, builder: (column) => column);

  GeneratedColumn<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => column);
}

class $$CachedNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedNotificationsTable,
          CachedNotificationRow,
          $$CachedNotificationsTableFilterComposer,
          $$CachedNotificationsTableOrderingComposer,
          $$CachedNotificationsTableAnnotationComposer,
          $$CachedNotificationsTableCreateCompanionBuilder,
          $$CachedNotificationsTableUpdateCompanionBuilder,
          (
            CachedNotificationRow,
            BaseReferences<
              _$AppDatabase,
              $CachedNotificationsTable,
              CachedNotificationRow
            >,
          ),
          CachedNotificationRow,
          PrefetchHooks Function()
        > {
  $$CachedNotificationsTableTableManager(
    _$AppDatabase db,
    $CachedNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotificationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedNotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> routeName = const Value.absent(),
                Value<String?> routeParamsJson = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedNotificationsCompanion(
                id: id,
                title: title,
                body: body,
                category: category,
                routeName: routeName,
                routeParamsJson: routeParamsJson,
                receivedAt: receivedAt,
                readAt: readAt,
                dismissed: dismissed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String title,
                required String body,
                required String category,
                Value<String?> routeName = const Value.absent(),
                Value<String?> routeParamsJson = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<DateTime?> readAt = const Value.absent(),
                Value<bool> dismissed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedNotificationsCompanion.insert(
                id: id,
                title: title,
                body: body,
                category: category,
                routeName: routeName,
                routeParamsJson: routeParamsJson,
                receivedAt: receivedAt,
                readAt: readAt,
                dismissed: dismissed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedNotificationsTable,
      CachedNotificationRow,
      $$CachedNotificationsTableFilterComposer,
      $$CachedNotificationsTableOrderingComposer,
      $$CachedNotificationsTableAnnotationComposer,
      $$CachedNotificationsTableCreateCompanionBuilder,
      $$CachedNotificationsTableUpdateCompanionBuilder,
      (
        CachedNotificationRow,
        BaseReferences<
          _$AppDatabase,
          $CachedNotificationsTable,
          CachedNotificationRow
        >,
      ),
      CachedNotificationRow,
      PrefetchHooks Function()
    >;
typedef $$CachedAccountsTableCreateCompanionBuilder =
    CachedAccountsCompanion Function({
      required String id,
      required String code,
      required String name,
      required String type,
      Value<String?> parentId,
      Value<String?> formattedBalance,
      Value<int> rowid,
    });
typedef $$CachedAccountsTableUpdateCompanionBuilder =
    CachedAccountsCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> name,
      Value<String> type,
      Value<String?> parentId,
      Value<String?> formattedBalance,
      Value<int> rowid,
    });

final class $$CachedAccountsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CachedAccountsTable, CachedAccountRow> {
  $$CachedAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CachedTransactionsTable,
    List<CachedTransactionRow>
  >
  _cachedTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedTransactions,
        aliasName: $_aliasNameGenerator(
          db.cachedAccounts.id,
          db.cachedTransactions.accountId,
        ),
      );

  $$CachedTransactionsTableProcessedTableManager get cachedTransactionsRefs {
    final manager = $$CachedTransactionsTableTableManager(
      $_db,
      $_db.cachedTransactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formattedBalance => $composableBuilder(
    column: $table.formattedBalance,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedTransactionsRefs(
    Expression<bool> Function($$CachedTransactionsTableFilterComposer f) f,
  ) {
    final $$CachedTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedTransactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.cachedTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formattedBalance => $composableBuilder(
    column: $table.formattedBalance,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAccountsTable> {
  $$CachedAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get formattedBalance => $composableBuilder(
    column: $table.formattedBalance,
    builder: (column) => column,
  );

  Expression<T> cachedTransactionsRefs<T extends Object>(
    Expression<T> Function($$CachedTransactionsTableAnnotationComposer a) f,
  ) {
    final $$CachedTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedTransactions,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAccountsTable,
          CachedAccountRow,
          $$CachedAccountsTableFilterComposer,
          $$CachedAccountsTableOrderingComposer,
          $$CachedAccountsTableAnnotationComposer,
          $$CachedAccountsTableCreateCompanionBuilder,
          $$CachedAccountsTableUpdateCompanionBuilder,
          (CachedAccountRow, $$CachedAccountsTableReferences),
          CachedAccountRow,
          PrefetchHooks Function({bool cachedTransactionsRefs})
        > {
  $$CachedAccountsTableTableManager(
    _$AppDatabase db,
    $CachedAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> formattedBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAccountsCompanion(
                id: id,
                code: code,
                name: name,
                type: type,
                parentId: parentId,
                formattedBalance: formattedBalance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String name,
                required String type,
                Value<String?> parentId = const Value.absent(),
                Value<String?> formattedBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAccountsCompanion.insert(
                id: id,
                code: code,
                name: name,
                type: type,
                parentId: parentId,
                formattedBalance: formattedBalance,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedTransactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedTransactionsRefs) db.cachedTransactions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedTransactionsRefs)
                    await $_getPrefetchedData<
                      CachedAccountRow,
                      $CachedAccountsTable,
                      CachedTransactionRow
                    >(
                      currentTable: table,
                      referencedTable: $$CachedAccountsTableReferences
                          ._cachedTransactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedAccountsTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedTransactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAccountsTable,
      CachedAccountRow,
      $$CachedAccountsTableFilterComposer,
      $$CachedAccountsTableOrderingComposer,
      $$CachedAccountsTableAnnotationComposer,
      $$CachedAccountsTableCreateCompanionBuilder,
      $$CachedAccountsTableUpdateCompanionBuilder,
      (CachedAccountRow, $$CachedAccountsTableReferences),
      CachedAccountRow,
      PrefetchHooks Function({bool cachedTransactionsRefs})
    >;
typedef $$CachedTransactionsTableCreateCompanionBuilder =
    CachedTransactionsCompanion Function({
      required String id,
      required String accountId,
      required DateTime postedAt,
      required String description,
      Value<String?> debit,
      Value<String?> credit,
      required String runningBalance,
      Value<String?> reference,
      Value<int> rowid,
    });
typedef $$CachedTransactionsTableUpdateCompanionBuilder =
    CachedTransactionsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<DateTime> postedAt,
      Value<String> description,
      Value<String?> debit,
      Value<String?> credit,
      Value<String> runningBalance,
      Value<String?> reference,
      Value<int> rowid,
    });

final class $$CachedTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedTransactionsTable,
          CachedTransactionRow
        > {
  $$CachedTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedAccountsTable _accountIdTable(_$AppDatabase db) =>
      db.cachedAccounts.createAlias(
        $_aliasNameGenerator(
          db.cachedTransactions.accountId,
          db.cachedAccounts.id,
        ),
      );

  $$CachedAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$CachedAccountsTableTableManager(
      $_db,
      $_db.cachedAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedTransactionsTable> {
  $$CachedTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get debit => $composableBuilder(
    column: $table.debit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credit => $composableBuilder(
    column: $table.credit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get runningBalance => $composableBuilder(
    column: $table.runningBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedAccountsTableFilterComposer get accountId {
    final $$CachedAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.cachedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAccountsTableFilterComposer(
            $db: $db,
            $table: $db.cachedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedTransactionsTable> {
  $$CachedTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get debit => $composableBuilder(
    column: $table.debit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credit => $composableBuilder(
    column: $table.credit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get runningBalance => $composableBuilder(
    column: $table.runningBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedAccountsTableOrderingComposer get accountId {
    final $$CachedAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.cachedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedTransactionsTable> {
  $$CachedTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get debit =>
      $composableBuilder(column: $table.debit, builder: (column) => column);

  GeneratedColumn<String> get credit =>
      $composableBuilder(column: $table.credit, builder: (column) => column);

  GeneratedColumn<String> get runningBalance => $composableBuilder(
    column: $table.runningBalance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  $$CachedAccountsTableAnnotationComposer get accountId {
    final $$CachedAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.cachedAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedTransactionsTable,
          CachedTransactionRow,
          $$CachedTransactionsTableFilterComposer,
          $$CachedTransactionsTableOrderingComposer,
          $$CachedTransactionsTableAnnotationComposer,
          $$CachedTransactionsTableCreateCompanionBuilder,
          $$CachedTransactionsTableUpdateCompanionBuilder,
          (CachedTransactionRow, $$CachedTransactionsTableReferences),
          CachedTransactionRow,
          PrefetchHooks Function({bool accountId})
        > {
  $$CachedTransactionsTableTableManager(
    _$AppDatabase db,
    $CachedTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<DateTime> postedAt = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> debit = const Value.absent(),
                Value<String?> credit = const Value.absent(),
                Value<String> runningBalance = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTransactionsCompanion(
                id: id,
                accountId: accountId,
                postedAt: postedAt,
                description: description,
                debit: debit,
                credit: credit,
                runningBalance: runningBalance,
                reference: reference,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required DateTime postedAt,
                required String description,
                Value<String?> debit = const Value.absent(),
                Value<String?> credit = const Value.absent(),
                required String runningBalance,
                Value<String?> reference = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedTransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                postedAt: postedAt,
                description: description,
                debit: debit,
                credit: credit,
                runningBalance: runningBalance,
                reference: reference,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$CachedTransactionsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$CachedTransactionsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedTransactionsTable,
      CachedTransactionRow,
      $$CachedTransactionsTableFilterComposer,
      $$CachedTransactionsTableOrderingComposer,
      $$CachedTransactionsTableAnnotationComposer,
      $$CachedTransactionsTableCreateCompanionBuilder,
      $$CachedTransactionsTableUpdateCompanionBuilder,
      (CachedTransactionRow, $$CachedTransactionsTableReferences),
      CachedTransactionRow,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$CachedInvoicesTableCreateCompanionBuilder =
    CachedInvoicesCompanion Function({
      required String id,
      required String invoiceNumber,
      required String customerName,
      required DateTime issuedAt,
      required DateTime dueAt,
      required String status,
      required String totalAmount,
      Value<String> currency,
      Value<String?> subtotal,
      Value<String?> tax,
      Value<String?> notes,
      Value<String?> approvedBy,
      Value<String?> rejectedBy,
      Value<String?> rejectedReason,
      Value<DateTime?> actionedAt,
      Value<int> rowid,
    });
typedef $$CachedInvoicesTableUpdateCompanionBuilder =
    CachedInvoicesCompanion Function({
      Value<String> id,
      Value<String> invoiceNumber,
      Value<String> customerName,
      Value<DateTime> issuedAt,
      Value<DateTime> dueAt,
      Value<String> status,
      Value<String> totalAmount,
      Value<String> currency,
      Value<String?> subtotal,
      Value<String?> tax,
      Value<String?> notes,
      Value<String?> approvedBy,
      Value<String?> rejectedBy,
      Value<String?> rejectedReason,
      Value<DateTime?> actionedAt,
      Value<int> rowid,
    });

final class $$CachedInvoicesTableReferences
    extends
        BaseReferences<_$AppDatabase, $CachedInvoicesTable, CachedInvoiceRow> {
  $$CachedInvoicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CachedInvoiceLinesTable,
    List<CachedInvoiceLineRow>
  >
  _cachedInvoiceLinesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedInvoiceLines,
        aliasName: $_aliasNameGenerator(
          db.cachedInvoices.id,
          db.cachedInvoiceLines.invoiceId,
        ),
      );

  $$CachedInvoiceLinesTableProcessedTableManager get cachedInvoiceLinesRefs {
    final manager = $$CachedInvoiceLinesTableTableManager(
      $_db,
      $_db.cachedInvoiceLines,
    ).filter((f) => f.invoiceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedInvoiceLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedInvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedInvoicesTable> {
  $$CachedInvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedBy => $composableBuilder(
    column: $table.rejectedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedReason => $composableBuilder(
    column: $table.rejectedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actionedAt => $composableBuilder(
    column: $table.actionedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedInvoiceLinesRefs(
    Expression<bool> Function($$CachedInvoiceLinesTableFilterComposer f) f,
  ) {
    final $$CachedInvoiceLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedInvoiceLines,
      getReferencedColumn: (t) => t.invoiceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedInvoiceLinesTableFilterComposer(
            $db: $db,
            $table: $db.cachedInvoiceLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedInvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedInvoicesTable> {
  $$CachedInvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tax => $composableBuilder(
    column: $table.tax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedBy => $composableBuilder(
    column: $table.rejectedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedReason => $composableBuilder(
    column: $table.rejectedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actionedAt => $composableBuilder(
    column: $table.actionedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedInvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedInvoicesTable> {
  $$CachedInvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<String> get tax =>
      $composableBuilder(column: $table.tax, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get approvedBy => $composableBuilder(
    column: $table.approvedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rejectedBy => $composableBuilder(
    column: $table.rejectedBy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rejectedReason => $composableBuilder(
    column: $table.rejectedReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actionedAt => $composableBuilder(
    column: $table.actionedAt,
    builder: (column) => column,
  );

  Expression<T> cachedInvoiceLinesRefs<T extends Object>(
    Expression<T> Function($$CachedInvoiceLinesTableAnnotationComposer a) f,
  ) {
    final $$CachedInvoiceLinesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedInvoiceLines,
          getReferencedColumn: (t) => t.invoiceId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedInvoiceLinesTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedInvoiceLines,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedInvoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedInvoicesTable,
          CachedInvoiceRow,
          $$CachedInvoicesTableFilterComposer,
          $$CachedInvoicesTableOrderingComposer,
          $$CachedInvoicesTableAnnotationComposer,
          $$CachedInvoicesTableCreateCompanionBuilder,
          $$CachedInvoicesTableUpdateCompanionBuilder,
          (CachedInvoiceRow, $$CachedInvoicesTableReferences),
          CachedInvoiceRow,
          PrefetchHooks Function({bool cachedInvoiceLinesRefs})
        > {
  $$CachedInvoicesTableTableManager(
    _$AppDatabase db,
    $CachedInvoicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedInvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedInvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedInvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceNumber = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> totalAmount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> subtotal = const Value.absent(),
                Value<String?> tax = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String?> rejectedBy = const Value.absent(),
                Value<String?> rejectedReason = const Value.absent(),
                Value<DateTime?> actionedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedInvoicesCompanion(
                id: id,
                invoiceNumber: invoiceNumber,
                customerName: customerName,
                issuedAt: issuedAt,
                dueAt: dueAt,
                status: status,
                totalAmount: totalAmount,
                currency: currency,
                subtotal: subtotal,
                tax: tax,
                notes: notes,
                approvedBy: approvedBy,
                rejectedBy: rejectedBy,
                rejectedReason: rejectedReason,
                actionedAt: actionedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceNumber,
                required String customerName,
                required DateTime issuedAt,
                required DateTime dueAt,
                required String status,
                required String totalAmount,
                Value<String> currency = const Value.absent(),
                Value<String?> subtotal = const Value.absent(),
                Value<String?> tax = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> approvedBy = const Value.absent(),
                Value<String?> rejectedBy = const Value.absent(),
                Value<String?> rejectedReason = const Value.absent(),
                Value<DateTime?> actionedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedInvoicesCompanion.insert(
                id: id,
                invoiceNumber: invoiceNumber,
                customerName: customerName,
                issuedAt: issuedAt,
                dueAt: dueAt,
                status: status,
                totalAmount: totalAmount,
                currency: currency,
                subtotal: subtotal,
                tax: tax,
                notes: notes,
                approvedBy: approvedBy,
                rejectedBy: rejectedBy,
                rejectedReason: rejectedReason,
                actionedAt: actionedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedInvoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedInvoiceLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedInvoiceLinesRefs) db.cachedInvoiceLines,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedInvoiceLinesRefs)
                    await $_getPrefetchedData<
                      CachedInvoiceRow,
                      $CachedInvoicesTable,
                      CachedInvoiceLineRow
                    >(
                      currentTable: table,
                      referencedTable: $$CachedInvoicesTableReferences
                          ._cachedInvoiceLinesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedInvoicesTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedInvoiceLinesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.invoiceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedInvoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedInvoicesTable,
      CachedInvoiceRow,
      $$CachedInvoicesTableFilterComposer,
      $$CachedInvoicesTableOrderingComposer,
      $$CachedInvoicesTableAnnotationComposer,
      $$CachedInvoicesTableCreateCompanionBuilder,
      $$CachedInvoicesTableUpdateCompanionBuilder,
      (CachedInvoiceRow, $$CachedInvoicesTableReferences),
      CachedInvoiceRow,
      PrefetchHooks Function({bool cachedInvoiceLinesRefs})
    >;
typedef $$CachedInvoiceLinesTableCreateCompanionBuilder =
    CachedInvoiceLinesCompanion Function({
      required String id,
      required String invoiceId,
      required int position,
      required String description,
      Value<String?> sku,
      required double quantity,
      required String unitPrice,
      required String lineTotal,
      Value<int> rowid,
    });
typedef $$CachedInvoiceLinesTableUpdateCompanionBuilder =
    CachedInvoiceLinesCompanion Function({
      Value<String> id,
      Value<String> invoiceId,
      Value<int> position,
      Value<String> description,
      Value<String?> sku,
      Value<double> quantity,
      Value<String> unitPrice,
      Value<String> lineTotal,
      Value<int> rowid,
    });

final class $$CachedInvoiceLinesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedInvoiceLinesTable,
          CachedInvoiceLineRow
        > {
  $$CachedInvoiceLinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedInvoicesTable _invoiceIdTable(_$AppDatabase db) =>
      db.cachedInvoices.createAlias(
        $_aliasNameGenerator(
          db.cachedInvoiceLines.invoiceId,
          db.cachedInvoices.id,
        ),
      );

  $$CachedInvoicesTableProcessedTableManager get invoiceId {
    final $_column = $_itemColumn<String>('invoice_id')!;

    final manager = $$CachedInvoicesTableTableManager(
      $_db,
      $_db.cachedInvoices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_invoiceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedInvoiceLinesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedInvoiceLinesTable> {
  $$CachedInvoiceLinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedInvoicesTableFilterComposer get invoiceId {
    final $$CachedInvoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.cachedInvoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedInvoicesTableFilterComposer(
            $db: $db,
            $table: $db.cachedInvoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedInvoiceLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedInvoiceLinesTable> {
  $$CachedInvoiceLinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedInvoicesTableOrderingComposer get invoiceId {
    final $$CachedInvoicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.cachedInvoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedInvoicesTableOrderingComposer(
            $db: $db,
            $table: $db.cachedInvoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedInvoiceLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedInvoiceLinesTable> {
  $$CachedInvoiceLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  $$CachedInvoicesTableAnnotationComposer get invoiceId {
    final $$CachedInvoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.invoiceId,
      referencedTable: $db.cachedInvoices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedInvoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedInvoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedInvoiceLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedInvoiceLinesTable,
          CachedInvoiceLineRow,
          $$CachedInvoiceLinesTableFilterComposer,
          $$CachedInvoiceLinesTableOrderingComposer,
          $$CachedInvoiceLinesTableAnnotationComposer,
          $$CachedInvoiceLinesTableCreateCompanionBuilder,
          $$CachedInvoiceLinesTableUpdateCompanionBuilder,
          (CachedInvoiceLineRow, $$CachedInvoiceLinesTableReferences),
          CachedInvoiceLineRow,
          PrefetchHooks Function({bool invoiceId})
        > {
  $$CachedInvoiceLinesTableTableManager(
    _$AppDatabase db,
    $CachedInvoiceLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedInvoiceLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedInvoiceLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedInvoiceLinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> invoiceId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String> unitPrice = const Value.absent(),
                Value<String> lineTotal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedInvoiceLinesCompanion(
                id: id,
                invoiceId: invoiceId,
                position: position,
                description: description,
                sku: sku,
                quantity: quantity,
                unitPrice: unitPrice,
                lineTotal: lineTotal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String invoiceId,
                required int position,
                required String description,
                Value<String?> sku = const Value.absent(),
                required double quantity,
                required String unitPrice,
                required String lineTotal,
                Value<int> rowid = const Value.absent(),
              }) => CachedInvoiceLinesCompanion.insert(
                id: id,
                invoiceId: invoiceId,
                position: position,
                description: description,
                sku: sku,
                quantity: quantity,
                unitPrice: unitPrice,
                lineTotal: lineTotal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedInvoiceLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({invoiceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (invoiceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.invoiceId,
                                referencedTable:
                                    $$CachedInvoiceLinesTableReferences
                                        ._invoiceIdTable(db),
                                referencedColumn:
                                    $$CachedInvoiceLinesTableReferences
                                        ._invoiceIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedInvoiceLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedInvoiceLinesTable,
      CachedInvoiceLineRow,
      $$CachedInvoiceLinesTableFilterComposer,
      $$CachedInvoiceLinesTableOrderingComposer,
      $$CachedInvoiceLinesTableAnnotationComposer,
      $$CachedInvoiceLinesTableCreateCompanionBuilder,
      $$CachedInvoiceLinesTableUpdateCompanionBuilder,
      (CachedInvoiceLineRow, $$CachedInvoiceLinesTableReferences),
      CachedInvoiceLineRow,
      PrefetchHooks Function({bool invoiceId})
    >;
typedef $$CachedInventoryItemsTableCreateCompanionBuilder =
    CachedInventoryItemsCompanion Function({
      required String id,
      required String sku,
      required String name,
      required String warehouseCode,
      required String locationCode,
      required double onHandQty,
      required double reorderPoint,
      required String unitCost,
      Value<String?> barcode,
      required String status,
      Value<int> rowid,
    });
typedef $$CachedInventoryItemsTableUpdateCompanionBuilder =
    CachedInventoryItemsCompanion Function({
      Value<String> id,
      Value<String> sku,
      Value<String> name,
      Value<String> warehouseCode,
      Value<String> locationCode,
      Value<double> onHandQty,
      Value<double> reorderPoint,
      Value<String> unitCost,
      Value<String?> barcode,
      Value<String> status,
      Value<int> rowid,
    });

final class $$CachedInventoryItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedInventoryItemsTable,
          CachedInventoryItemRow
        > {
  $$CachedInventoryItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $CachedStockMovementsTable,
    List<CachedStockMovementRow>
  >
  _cachedStockMovementsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cachedStockMovements,
        aliasName: $_aliasNameGenerator(
          db.cachedInventoryItems.id,
          db.cachedStockMovements.itemId,
        ),
      );

  $$CachedStockMovementsTableProcessedTableManager
  get cachedStockMovementsRefs {
    final manager = $$CachedStockMovementsTableTableManager(
      $_db,
      $_db.cachedStockMovements,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cachedStockMovementsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedInventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedInventoryItemsTable> {
  $$CachedInventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warehouseCode => $composableBuilder(
    column: $table.warehouseCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationCode => $composableBuilder(
    column: $table.locationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get onHandQty => $composableBuilder(
    column: $table.onHandQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reorderPoint => $composableBuilder(
    column: $table.reorderPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cachedStockMovementsRefs(
    Expression<bool> Function($$CachedStockMovementsTableFilterComposer f) f,
  ) {
    final $$CachedStockMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cachedStockMovements,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedStockMovementsTableFilterComposer(
            $db: $db,
            $table: $db.cachedStockMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedInventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedInventoryItemsTable> {
  $$CachedInventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warehouseCode => $composableBuilder(
    column: $table.warehouseCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationCode => $composableBuilder(
    column: $table.locationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get onHandQty => $composableBuilder(
    column: $table.onHandQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reorderPoint => $composableBuilder(
    column: $table.reorderPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitCost => $composableBuilder(
    column: $table.unitCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedInventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedInventoryItemsTable> {
  $$CachedInventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get warehouseCode => $composableBuilder(
    column: $table.warehouseCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationCode => $composableBuilder(
    column: $table.locationCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get onHandQty =>
      $composableBuilder(column: $table.onHandQty, builder: (column) => column);

  GeneratedColumn<double> get reorderPoint => $composableBuilder(
    column: $table.reorderPoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> cachedStockMovementsRefs<T extends Object>(
    Expression<T> Function($$CachedStockMovementsTableAnnotationComposer a) f,
  ) {
    final $$CachedStockMovementsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cachedStockMovements,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedStockMovementsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedStockMovements,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CachedInventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedInventoryItemsTable,
          CachedInventoryItemRow,
          $$CachedInventoryItemsTableFilterComposer,
          $$CachedInventoryItemsTableOrderingComposer,
          $$CachedInventoryItemsTableAnnotationComposer,
          $$CachedInventoryItemsTableCreateCompanionBuilder,
          $$CachedInventoryItemsTableUpdateCompanionBuilder,
          (CachedInventoryItemRow, $$CachedInventoryItemsTableReferences),
          CachedInventoryItemRow,
          PrefetchHooks Function({bool cachedStockMovementsRefs})
        > {
  $$CachedInventoryItemsTableTableManager(
    _$AppDatabase db,
    $CachedInventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedInventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedInventoryItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedInventoryItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> warehouseCode = const Value.absent(),
                Value<String> locationCode = const Value.absent(),
                Value<double> onHandQty = const Value.absent(),
                Value<double> reorderPoint = const Value.absent(),
                Value<String> unitCost = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedInventoryItemsCompanion(
                id: id,
                sku: sku,
                name: name,
                warehouseCode: warehouseCode,
                locationCode: locationCode,
                onHandQty: onHandQty,
                reorderPoint: reorderPoint,
                unitCost: unitCost,
                barcode: barcode,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sku,
                required String name,
                required String warehouseCode,
                required String locationCode,
                required double onHandQty,
                required double reorderPoint,
                required String unitCost,
                Value<String?> barcode = const Value.absent(),
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => CachedInventoryItemsCompanion.insert(
                id: id,
                sku: sku,
                name: name,
                warehouseCode: warehouseCode,
                locationCode: locationCode,
                onHandQty: onHandQty,
                reorderPoint: reorderPoint,
                unitCost: unitCost,
                barcode: barcode,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedInventoryItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cachedStockMovementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cachedStockMovementsRefs) db.cachedStockMovements,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cachedStockMovementsRefs)
                    await $_getPrefetchedData<
                      CachedInventoryItemRow,
                      $CachedInventoryItemsTable,
                      CachedStockMovementRow
                    >(
                      currentTable: table,
                      referencedTable: $$CachedInventoryItemsTableReferences
                          ._cachedStockMovementsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedInventoryItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).cachedStockMovementsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedInventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedInventoryItemsTable,
      CachedInventoryItemRow,
      $$CachedInventoryItemsTableFilterComposer,
      $$CachedInventoryItemsTableOrderingComposer,
      $$CachedInventoryItemsTableAnnotationComposer,
      $$CachedInventoryItemsTableCreateCompanionBuilder,
      $$CachedInventoryItemsTableUpdateCompanionBuilder,
      (CachedInventoryItemRow, $$CachedInventoryItemsTableReferences),
      CachedInventoryItemRow,
      PrefetchHooks Function({bool cachedStockMovementsRefs})
    >;
typedef $$CachedStockMovementsTableCreateCompanionBuilder =
    CachedStockMovementsCompanion Function({
      required String id,
      required String itemId,
      required DateTime postedAt,
      required String type,
      required double quantity,
      required double runningQty,
      Value<String?> reference,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$CachedStockMovementsTableUpdateCompanionBuilder =
    CachedStockMovementsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<DateTime> postedAt,
      Value<String> type,
      Value<double> quantity,
      Value<double> runningQty,
      Value<String?> reference,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$CachedStockMovementsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CachedStockMovementsTable,
          CachedStockMovementRow
        > {
  $$CachedStockMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedInventoryItemsTable _itemIdTable(_$AppDatabase db) =>
      db.cachedInventoryItems.createAlias(
        $_aliasNameGenerator(
          db.cachedStockMovements.itemId,
          db.cachedInventoryItems.id,
        ),
      );

  $$CachedInventoryItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$CachedInventoryItemsTableTableManager(
      $_db,
      $_db.cachedInventoryItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CachedStockMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStockMovementsTable> {
  $$CachedStockMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get runningQty => $composableBuilder(
    column: $table.runningQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedInventoryItemsTableFilterComposer get itemId {
    final $$CachedInventoryItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.cachedInventoryItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedInventoryItemsTableFilterComposer(
            $db: $db,
            $table: $db.cachedInventoryItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CachedStockMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStockMovementsTable> {
  $$CachedStockMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
    column: $table.postedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get runningQty => $composableBuilder(
    column: $table.runningQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedInventoryItemsTableOrderingComposer get itemId {
    final $$CachedInventoryItemsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemId,
          referencedTable: $db.cachedInventoryItems,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedInventoryItemsTableOrderingComposer(
                $db: $db,
                $table: $db.cachedInventoryItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CachedStockMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStockMovementsTable> {
  $$CachedStockMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get runningQty => $composableBuilder(
    column: $table.runningQty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$CachedInventoryItemsTableAnnotationComposer get itemId {
    final $$CachedInventoryItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemId,
          referencedTable: $db.cachedInventoryItems,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedInventoryItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedInventoryItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$CachedStockMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStockMovementsTable,
          CachedStockMovementRow,
          $$CachedStockMovementsTableFilterComposer,
          $$CachedStockMovementsTableOrderingComposer,
          $$CachedStockMovementsTableAnnotationComposer,
          $$CachedStockMovementsTableCreateCompanionBuilder,
          $$CachedStockMovementsTableUpdateCompanionBuilder,
          (CachedStockMovementRow, $$CachedStockMovementsTableReferences),
          CachedStockMovementRow,
          PrefetchHooks Function({bool itemId})
        > {
  $$CachedStockMovementsTableTableManager(
    _$AppDatabase db,
    $CachedStockMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStockMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStockMovementsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedStockMovementsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<DateTime> postedAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> runningQty = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStockMovementsCompanion(
                id: id,
                itemId: itemId,
                postedAt: postedAt,
                type: type,
                quantity: quantity,
                runningQty: runningQty,
                reference: reference,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required DateTime postedAt,
                required String type,
                required double quantity,
                required double runningQty,
                Value<String?> reference = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedStockMovementsCompanion.insert(
                id: id,
                itemId: itemId,
                postedAt: postedAt,
                type: type,
                quantity: quantity,
                runningQty: runningQty,
                reference: reference,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CachedStockMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$CachedStockMovementsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$CachedStockMovementsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CachedStockMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStockMovementsTable,
      CachedStockMovementRow,
      $$CachedStockMovementsTableFilterComposer,
      $$CachedStockMovementsTableOrderingComposer,
      $$CachedStockMovementsTableAnnotationComposer,
      $$CachedStockMovementsTableCreateCompanionBuilder,
      $$CachedStockMovementsTableUpdateCompanionBuilder,
      (CachedStockMovementRow, $$CachedStockMovementsTableReferences),
      CachedStockMovementRow,
      PrefetchHooks Function({bool itemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppMetadataTableTableManager get appMetadata =>
      $$AppMetadataTableTableManager(_db, _db.appMetadata);
  $$CacheFreshnessTableTableManager get cacheFreshness =>
      $$CacheFreshnessTableTableManager(_db, _db.cacheFreshness);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$CachedUserTableTableManager get cachedUser =>
      $$CachedUserTableTableManager(_db, _db.cachedUser);
  $$UserPermissionsTableTableManager get userPermissions =>
      $$UserPermissionsTableTableManager(_db, _db.userPermissions);
  $$BiometricSettingsTableTableManager get biometricSettings =>
      $$BiometricSettingsTableTableManager(_db, _db.biometricSettings);
  $$CachedNotificationsTableTableManager get cachedNotifications =>
      $$CachedNotificationsTableTableManager(_db, _db.cachedNotifications);
  $$CachedAccountsTableTableManager get cachedAccounts =>
      $$CachedAccountsTableTableManager(_db, _db.cachedAccounts);
  $$CachedTransactionsTableTableManager get cachedTransactions =>
      $$CachedTransactionsTableTableManager(_db, _db.cachedTransactions);
  $$CachedInvoicesTableTableManager get cachedInvoices =>
      $$CachedInvoicesTableTableManager(_db, _db.cachedInvoices);
  $$CachedInvoiceLinesTableTableManager get cachedInvoiceLines =>
      $$CachedInvoiceLinesTableTableManager(_db, _db.cachedInvoiceLines);
  $$CachedInventoryItemsTableTableManager get cachedInventoryItems =>
      $$CachedInventoryItemsTableTableManager(_db, _db.cachedInventoryItems);
  $$CachedStockMovementsTableTableManager get cachedStockMovements =>
      $$CachedStockMovementsTableTableManager(_db, _db.cachedStockMovements);
}
