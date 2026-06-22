// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trial_balance_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$TrialBalanceRow {
  String get accountId => throw _privateConstructorUsedError;
  String get accountCode => throw _privateConstructorUsedError;
  String get accountName => throw _privateConstructorUsedError;
  AccountType get accountType => throw _privateConstructorUsedError;
  String get debit => throw _privateConstructorUsedError;
  String get credit => throw _privateConstructorUsedError;

  /// Create a copy of TrialBalanceRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrialBalanceRowCopyWith<TrialBalanceRow> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrialBalanceRowCopyWith<$Res> {
  factory $TrialBalanceRowCopyWith(
    TrialBalanceRow value,
    $Res Function(TrialBalanceRow) then,
  ) = _$TrialBalanceRowCopyWithImpl<$Res, TrialBalanceRow>;
  @useResult
  $Res call({
    String accountId,
    String accountCode,
    String accountName,
    AccountType accountType,
    String debit,
    String credit,
  });
}

/// @nodoc
class _$TrialBalanceRowCopyWithImpl<$Res, $Val extends TrialBalanceRow>
    implements $TrialBalanceRowCopyWith<$Res> {
  _$TrialBalanceRowCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrialBalanceRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? accountCode = null,
    Object? accountName = null,
    Object? accountType = null,
    Object? debit = null,
    Object? credit = null,
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
            accountType: null == accountType
                ? _value.accountType
                : accountType // ignore: cast_nullable_to_non_nullable
                      as AccountType,
            debit: null == debit
                ? _value.debit
                : debit // ignore: cast_nullable_to_non_nullable
                      as String,
            credit: null == credit
                ? _value.credit
                : credit // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TrialBalanceRowImplCopyWith<$Res>
    implements $TrialBalanceRowCopyWith<$Res> {
  factory _$$TrialBalanceRowImplCopyWith(
    _$TrialBalanceRowImpl value,
    $Res Function(_$TrialBalanceRowImpl) then,
  ) = __$$TrialBalanceRowImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accountId,
    String accountCode,
    String accountName,
    AccountType accountType,
    String debit,
    String credit,
  });
}

/// @nodoc
class __$$TrialBalanceRowImplCopyWithImpl<$Res>
    extends _$TrialBalanceRowCopyWithImpl<$Res, _$TrialBalanceRowImpl>
    implements _$$TrialBalanceRowImplCopyWith<$Res> {
  __$$TrialBalanceRowImplCopyWithImpl(
    _$TrialBalanceRowImpl _value,
    $Res Function(_$TrialBalanceRowImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TrialBalanceRow
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountId = null,
    Object? accountCode = null,
    Object? accountName = null,
    Object? accountType = null,
    Object? debit = null,
    Object? credit = null,
  }) {
    return _then(
      _$TrialBalanceRowImpl(
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
        accountType: null == accountType
            ? _value.accountType
            : accountType // ignore: cast_nullable_to_non_nullable
                  as AccountType,
        debit: null == debit
            ? _value.debit
            : debit // ignore: cast_nullable_to_non_nullable
                  as String,
        credit: null == credit
            ? _value.credit
            : credit // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$TrialBalanceRowImpl implements _TrialBalanceRow {
  const _$TrialBalanceRowImpl({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.accountType,
    required this.debit,
    required this.credit,
  });

  @override
  final String accountId;
  @override
  final String accountCode;
  @override
  final String accountName;
  @override
  final AccountType accountType;
  @override
  final String debit;
  @override
  final String credit;

  @override
  String toString() {
    return 'TrialBalanceRow(accountId: $accountId, accountCode: $accountCode, accountName: $accountName, accountType: $accountType, debit: $debit, credit: $credit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrialBalanceRowImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId) &&
            (identical(other.accountCode, accountCode) ||
                other.accountCode == accountCode) &&
            (identical(other.accountName, accountName) ||
                other.accountName == accountName) &&
            (identical(other.accountType, accountType) ||
                other.accountType == accountType) &&
            (identical(other.debit, debit) || other.debit == debit) &&
            (identical(other.credit, credit) || other.credit == credit));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    accountId,
    accountCode,
    accountName,
    accountType,
    debit,
    credit,
  );

  /// Create a copy of TrialBalanceRow
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrialBalanceRowImplCopyWith<_$TrialBalanceRowImpl> get copyWith =>
      __$$TrialBalanceRowImplCopyWithImpl<_$TrialBalanceRowImpl>(
        this,
        _$identity,
      );
}

abstract class _TrialBalanceRow implements TrialBalanceRow {
  const factory _TrialBalanceRow({
    required final String accountId,
    required final String accountCode,
    required final String accountName,
    required final AccountType accountType,
    required final String debit,
    required final String credit,
  }) = _$TrialBalanceRowImpl;

  @override
  String get accountId;
  @override
  String get accountCode;
  @override
  String get accountName;
  @override
  AccountType get accountType;
  @override
  String get debit;
  @override
  String get credit;

  /// Create a copy of TrialBalanceRow
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrialBalanceRowImplCopyWith<_$TrialBalanceRowImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
