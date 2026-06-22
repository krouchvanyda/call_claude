// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$JournalEntryLine {
  String get accountId => throw _privateConstructorUsedError;
  String get accountCode => throw _privateConstructorUsedError;
  String get accountName => throw _privateConstructorUsedError;

  /// Pre-formatted; exactly one side is non-null per line.
  String? get debit => throw _privateConstructorUsedError;
  String? get credit => throw _privateConstructorUsedError;

  /// Create a copy of JournalEntryLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JournalEntryLineCopyWith<JournalEntryLine> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JournalEntryLineCopyWith<$Res> {
  factory $JournalEntryLineCopyWith(
    JournalEntryLine value,
    $Res Function(JournalEntryLine) then,
  ) = _$JournalEntryLineCopyWithImpl<$Res, JournalEntryLine>;
  @useResult
  $Res call({
    String accountId,
    String accountCode,
    String accountName,
    String? debit,
    String? credit,
  });
}

/// @nodoc
class _$JournalEntryLineCopyWithImpl<$Res, $Val extends JournalEntryLine>
    implements $JournalEntryLineCopyWith<$Res> {
  _$JournalEntryLineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JournalEntryLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? accountCode = null,
    Object? accountName = null,
    Object? debit = freezed,
    Object? credit = freezed,
  }) {
    return _then(
      _value.copyWith(
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            accountCode: null == accountCode
                ? _value.accountCode
                : accountCode // ignore: cast_nullable_to_non_nullable
                      as String,
            accountName: null == accountName
                ? _value.accountName
                : accountName // ignore: cast_nullable_to_non_nullable
                      as String,
            debit: freezed == debit
                ? _value.debit
                : debit // ignore: cast_nullable_to_non_nullable
                      as String?,
            credit: freezed == credit
                ? _value.credit
                : credit // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JournalEntryLineImplCopyWith<$Res>
    implements $JournalEntryLineCopyWith<$Res> {
  factory _$$JournalEntryLineImplCopyWith(
    _$JournalEntryLineImpl value,
    $Res Function(_$JournalEntryLineImpl) then,
  ) = __$$JournalEntryLineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accountId,
    String accountCode,
    String accountName,
    String? debit,
    String? credit,
  });
}

/// @nodoc
class __$$JournalEntryLineImplCopyWithImpl<$Res>
    extends _$JournalEntryLineCopyWithImpl<$Res, _$JournalEntryLineImpl>
    implements _$$JournalEntryLineImplCopyWith<$Res> {
  __$$JournalEntryLineImplCopyWithImpl(
    _$JournalEntryLineImpl _value,
    $Res Function(_$JournalEntryLineImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JournalEntryLine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? accountCode = null,
    Object? accountName = null,
    Object? debit = freezed,
    Object? credit = freezed,
  }) {
    return _then(
      _$JournalEntryLineImpl(
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        accountCode: null == accountCode
            ? _value.accountCode
            : accountCode // ignore: cast_nullable_to_non_nullable
                  as String,
        accountName: null == accountName
            ? _value.accountName
            : accountName // ignore: cast_nullable_to_non_nullable
                  as String,
        debit: freezed == debit
            ? _value.debit
            : debit // ignore: cast_nullable_to_non_nullable
                  as String?,
        credit: freezed == credit
            ? _value.credit
            : credit // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$JournalEntryLineImpl implements _JournalEntryLine {
  const _$JournalEntryLineImpl({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    this.debit,
    this.credit,
  });

  @override
  final String accountId;
  @override
  final String accountCode;
  @override
  final String accountName;

  /// Pre-formatted; exactly one side is non-null per line.
  @override
  final String? debit;
  @override
  final String? credit;

  @override
  String toString() {
    return 'JournalEntryLine(accountId: $accountId, accountCode: $accountCode, accountName: $accountName, debit: $debit, credit: $credit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JournalEntryLineImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.accountCode, accountCode) ||
                other.accountCode == accountCode) &&
            (identical(other.accountName, accountName) ||
                other.accountName == accountName) &&
            (identical(other.debit, debit) || other.debit == debit) &&
            (identical(other.credit, credit) || other.credit == credit));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    accountId,
    accountCode,
    accountName,
    debit,
    credit,
  );

  /// Create a copy of JournalEntryLine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JournalEntryLineImplCopyWith<_$JournalEntryLineImpl> get copyWith =>
      __$$JournalEntryLineImplCopyWithImpl<_$JournalEntryLineImpl>(
        this,
        _$identity,
      );
}

abstract class _JournalEntryLine implements JournalEntryLine {
  const factory _JournalEntryLine({
    required final String accountId,
    required final String accountCode,
    required final String accountName,
    final String? debit,
    final String? credit,
  }) = _$JournalEntryLineImpl;

  @override
  String get accountId;
  @override
  String get accountCode;
  @override
  String get accountName;

  /// Pre-formatted; exactly one side is non-null per line.
  @override
  String? get debit;
  @override
  String? get credit;

  /// Create a copy of JournalEntryLine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JournalEntryLineImplCopyWith<_$JournalEntryLineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$JournalEntry {
  String get id => throw _privateConstructorUsedError;
  String get reference => throw _privateConstructorUsedError;
  DateTime get postedAt => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<JournalEntryLine> get lines => throw _privateConstructorUsedError;

  /// Pre-formatted total — string at the boundary, same locale-stable
  /// pattern as the rest of the finance entities.
  String get formattedTotal => throw _privateConstructorUsedError;

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $JournalEntryCopyWith<JournalEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JournalEntryCopyWith<$Res> {
  factory $JournalEntryCopyWith(
    JournalEntry value,
    $Res Function(JournalEntry) then,
  ) = _$JournalEntryCopyWithImpl<$Res, JournalEntry>;
  @useResult
  $Res call({
    String id,
    String reference,
    DateTime postedAt,
    String description,
    List<JournalEntryLine> lines,
    String formattedTotal,
  });
}

/// @nodoc
class _$JournalEntryCopyWithImpl<$Res, $Val extends JournalEntry>
    implements $JournalEntryCopyWith<$Res> {
  _$JournalEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reference = null,
    Object? postedAt = null,
    Object? description = null,
    Object? lines = null,
    Object? formattedTotal = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            reference: null == reference
                ? _value.reference
                : reference // ignore: cast_nullable_to_non_nullable
                      as String,
            postedAt: null == postedAt
                ? _value.postedAt
                : postedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            lines: null == lines
                ? _value.lines
                : lines // ignore: cast_nullable_to_non_nullable
                      as List<JournalEntryLine>,
            formattedTotal: null == formattedTotal
                ? _value.formattedTotal
                : formattedTotal // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$JournalEntryImplCopyWith<$Res>
    implements $JournalEntryCopyWith<$Res> {
  factory _$$JournalEntryImplCopyWith(
    _$JournalEntryImpl value,
    $Res Function(_$JournalEntryImpl) then,
  ) = __$$JournalEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String reference,
    DateTime postedAt,
    String description,
    List<JournalEntryLine> lines,
    String formattedTotal,
  });
}

/// @nodoc
class __$$JournalEntryImplCopyWithImpl<$Res>
    extends _$JournalEntryCopyWithImpl<$Res, _$JournalEntryImpl>
    implements _$$JournalEntryImplCopyWith<$Res> {
  __$$JournalEntryImplCopyWithImpl(
    _$JournalEntryImpl _value,
    $Res Function(_$JournalEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? reference = null,
    Object? postedAt = null,
    Object? description = null,
    Object? lines = null,
    Object? formattedTotal = null,
  }) {
    return _then(
      _$JournalEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        reference: null == reference
            ? _value.reference
            : reference // ignore: cast_nullable_to_non_nullable
                  as String,
        postedAt: null == postedAt
            ? _value.postedAt
            : postedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        lines: null == lines
            ? _value._lines
            : lines // ignore: cast_nullable_to_non_nullable
                  as List<JournalEntryLine>,
        formattedTotal: null == formattedTotal
            ? _value.formattedTotal
            : formattedTotal // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$JournalEntryImpl implements _JournalEntry {
  const _$JournalEntryImpl({
    required this.id,
    required this.reference,
    required this.postedAt,
    required this.description,
    required final List<JournalEntryLine> lines,
    required this.formattedTotal,
  }) : _lines = lines;

  @override
  final String id;
  @override
  final String reference;
  @override
  final DateTime postedAt;
  @override
  final String description;
  final List<JournalEntryLine> _lines;
  @override
  List<JournalEntryLine> get lines {
    if (_lines is EqualUnmodifiableListView) return _lines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lines);
  }

  /// Pre-formatted total — string at the boundary, same locale-stable
  /// pattern as the rest of the finance entities.
  @override
  final String formattedTotal;

  @override
  String toString() {
    return 'JournalEntry(id: $id, reference: $reference, postedAt: $postedAt, description: $description, lines: $lines, formattedTotal: $formattedTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$JournalEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.postedAt, postedAt) ||
                other.postedAt == postedAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._lines, _lines) &&
            (identical(other.formattedTotal, formattedTotal) ||
                other.formattedTotal == formattedTotal));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    reference,
    postedAt,
    description,
    const DeepCollectionEquality().hash(_lines),
    formattedTotal,
  );

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$JournalEntryImplCopyWith<_$JournalEntryImpl> get copyWith =>
      __$$JournalEntryImplCopyWithImpl<_$JournalEntryImpl>(this, _$identity);
}

abstract class _JournalEntry implements JournalEntry {
  const factory _JournalEntry({
    required final String id,
    required final String reference,
    required final DateTime postedAt,
    required final String description,
    required final List<JournalEntryLine> lines,
    required final String formattedTotal,
  }) = _$JournalEntryImpl;

  @override
  String get id;
  @override
  String get reference;
  @override
  DateTime get postedAt;
  @override
  String get description;
  @override
  List<JournalEntryLine> get lines;

  /// Pre-formatted total — string at the boundary, same locale-stable
  /// pattern as the rest of the finance entities.
  @override
  String get formattedTotal;

  /// Create a copy of JournalEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$JournalEntryImplCopyWith<_$JournalEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
