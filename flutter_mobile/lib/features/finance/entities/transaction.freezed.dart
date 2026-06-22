// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LedgerTransaction {
  /// Server / drift PK. Stable across re-fetches.
  String get id => throw _privateConstructorUsedError;

  /// FK to [`Account.id`]. Drives the per-account watch query.
  String get accountId => throw _privateConstructorUsedError;

  /// Posting timestamp. Newest-first ordering in the detail view.
  DateTime get postedAt => throw _privateConstructorUsedError;

  /// Human-readable line description (e.g. "Invoice #INV-001 paid").
  String get description => throw _privateConstructorUsedError;

  /// Pre-formatted debit amount or `null` when this line is a credit.
  String? get debit => throw _privateConstructorUsedError;

  /// Pre-formatted credit amount or `null` when this line is a debit.
  String? get credit => throw _privateConstructorUsedError;

  /// Pre-formatted running balance after the line posted. Server-
  /// computed; we never derive client-side (sign + ordering rules
  /// vary by account type).
  String get runningBalance => throw _privateConstructorUsedError;

  /// Optional source-document handle (journal entry number, invoice
  /// id, etc.) — drives the "View source" deep link in a later slice.
  String? get reference => throw _privateConstructorUsedError;

  /// Create a copy of LedgerTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LedgerTransactionCopyWith<LedgerTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LedgerTransactionCopyWith<$Res> {
  factory $LedgerTransactionCopyWith(
    LedgerTransaction value,
    $Res Function(LedgerTransaction) then,
  ) = _$LedgerTransactionCopyWithImpl<$Res, LedgerTransaction>;
  @useResult
  $Res call({
    String id,
    String accountId,
    DateTime postedAt,
    String description,
    String? debit,
    String? credit,
    String runningBalance,
    String? reference,
  });
}

/// @nodoc
class _$LedgerTransactionCopyWithImpl<$Res, $Val extends LedgerTransaction>
    implements $LedgerTransactionCopyWith<$Res> {
  _$LedgerTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LedgerTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? postedAt = null,
    Object? description = null,
    Object? debit = freezed,
    Object? credit = freezed,
    Object? runningBalance = null,
    Object? reference = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            accountId: null == accountId
                ? _value.accountId
                : accountId // ignore: cast_nullable_to_non_nullable
                      as String,
            postedAt: null == postedAt
                ? _value.postedAt
                : postedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            debit: freezed == debit
                ? _value.debit
                : debit // ignore: cast_nullable_to_non_nullable
                      as String?,
            credit: freezed == credit
                ? _value.credit
                : credit // ignore: cast_nullable_to_non_nullable
                      as String?,
            runningBalance: null == runningBalance
                ? _value.runningBalance
                : runningBalance // ignore: cast_nullable_to_non_nullable
                      as String,
            reference: freezed == reference
                ? _value.reference
                : reference // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LedgerTransactionImplCopyWith<$Res>
    implements $LedgerTransactionCopyWith<$Res> {
  factory _$$LedgerTransactionImplCopyWith(
    _$LedgerTransactionImpl value,
    $Res Function(_$LedgerTransactionImpl) then,
  ) = __$$LedgerTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String accountId,
    DateTime postedAt,
    String description,
    String? debit,
    String? credit,
    String runningBalance,
    String? reference,
  });
}

/// @nodoc
class __$$LedgerTransactionImplCopyWithImpl<$Res>
    extends _$LedgerTransactionCopyWithImpl<$Res, _$LedgerTransactionImpl>
    implements _$$LedgerTransactionImplCopyWith<$Res> {
  __$$LedgerTransactionImplCopyWithImpl(
    _$LedgerTransactionImpl _value,
    $Res Function(_$LedgerTransactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LedgerTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? accountId = null,
    Object? postedAt = null,
    Object? description = null,
    Object? debit = freezed,
    Object? credit = freezed,
    Object? runningBalance = null,
    Object? reference = freezed,
  }) {
    return _then(
      _$LedgerTransactionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        accountId: null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
        postedAt: null == postedAt
            ? _value.postedAt
            : postedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        debit: freezed == debit
            ? _value.debit
            : debit // ignore: cast_nullable_to_non_nullable
                  as String?,
        credit: freezed == credit
            ? _value.credit
            : credit // ignore: cast_nullable_to_non_nullable
                  as String?,
        runningBalance: null == runningBalance
            ? _value.runningBalance
            : runningBalance // ignore: cast_nullable_to_non_nullable
                  as String,
        reference: freezed == reference
            ? _value.reference
            : reference // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LedgerTransactionImpl implements _LedgerTransaction {
  const _$LedgerTransactionImpl({
    required this.id,
    required this.accountId,
    required this.postedAt,
    required this.description,
    this.debit,
    this.credit,
    required this.runningBalance,
    this.reference,
  });

  /// Server / drift PK. Stable across re-fetches.
  @override
  final String id;

  /// FK to [`Account.id`]. Drives the per-account watch query.
  @override
  final String accountId;

  /// Posting timestamp. Newest-first ordering in the detail view.
  @override
  final DateTime postedAt;

  /// Human-readable line description (e.g. "Invoice #INV-001 paid").
  @override
  final String description;

  /// Pre-formatted debit amount or `null` when this line is a credit.
  @override
  final String? debit;

  /// Pre-formatted credit amount or `null` when this line is a debit.
  @override
  final String? credit;

  /// Pre-formatted running balance after the line posted. Server-
  /// computed; we never derive client-side (sign + ordering rules
  /// vary by account type).
  @override
  final String runningBalance;

  /// Optional source-document handle (journal entry number, invoice
  /// id, etc.) — drives the "View source" deep link in a later slice.
  @override
  final String? reference;

  @override
  String toString() {
    return 'LedgerTransaction(id: $id, accountId: $accountId, postedAt: $postedAt, description: $description, debit: $debit, credit: $credit, runningBalance: $runningBalance, reference: $reference)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LedgerTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.postedAt, postedAt) ||
                other.postedAt == postedAt) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.debit, debit) || other.debit == debit) &&
            (identical(other.credit, credit) || other.credit == credit) &&
            (identical(other.runningBalance, runningBalance) ||
                other.runningBalance == runningBalance) &&
            (identical(other.reference, reference) ||
                other.reference == reference));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    accountId,
    postedAt,
    description,
    debit,
    credit,
    runningBalance,
    reference,
  );

  /// Create a copy of LedgerTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LedgerTransactionImplCopyWith<_$LedgerTransactionImpl> get copyWith =>
      __$$LedgerTransactionImplCopyWithImpl<_$LedgerTransactionImpl>(
        this,
        _$identity,
      );
}

abstract class _LedgerTransaction implements LedgerTransaction {
  const factory _LedgerTransaction({
    required final String id,
    required final String accountId,
    required final DateTime postedAt,
    required final String description,
    final String? debit,
    final String? credit,
    required final String runningBalance,
    final String? reference,
  }) = _$LedgerTransactionImpl;

  /// Server / drift PK. Stable across re-fetches.
  @override
  String get id;

  /// FK to [`Account.id`]. Drives the per-account watch query.
  @override
  String get accountId;

  /// Posting timestamp. Newest-first ordering in the detail view.
  @override
  DateTime get postedAt;

  /// Human-readable line description (e.g. "Invoice #INV-001 paid").
  @override
  String get description;

  /// Pre-formatted debit amount or `null` when this line is a credit.
  @override
  String? get debit;

  /// Pre-formatted credit amount or `null` when this line is a debit.
  @override
  String? get credit;

  /// Pre-formatted running balance after the line posted. Server-
  /// computed; we never derive client-side (sign + ordering rules
  /// vary by account type).
  @override
  String get runningBalance;

  /// Optional source-document handle (journal entry number, invoice
  /// id, etc.) — drives the "View source" deep link in a later slice.
  @override
  String? get reference;

  /// Create a copy of LedgerTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LedgerTransactionImplCopyWith<_$LedgerTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
