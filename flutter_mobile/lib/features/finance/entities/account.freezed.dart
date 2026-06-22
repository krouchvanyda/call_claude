// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Account {
  /// Server / drift PK. Stable across renames.
  String get id => throw _privateConstructorUsedError;

  /// Human-readable account code (e.g. `'1100'`, `'1100-01'`).
  /// Sort order within a level is by [code], not [name], so a typo
  /// in the localised name doesn't reshuffle the tree on locale change.
  String get code => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  AccountType get type => throw _privateConstructorUsedError;

  /// `null` for roots. Multiple roots per type are normal (one root
  /// per account category, sometimes more in deeply nested CoAs).
  String? get parentId => throw _privateConstructorUsedError;

  /// Pre-formatted current balance string with currency symbol +
  /// locale separators applied at the data layer. The widget never
  /// formats numbers — keeps the entity locale-stable.
  String? get formattedBalance => throw _privateConstructorUsedError;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountCopyWith<Account> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountCopyWith<$Res> {
  factory $AccountCopyWith(Account value, $Res Function(Account) then) =
      _$AccountCopyWithImpl<$Res, Account>;
  @useResult
  $Res call({
    String id,
    String code,
    String name,
    AccountType type,
    String? parentId,
    String? formattedBalance,
  });
}

/// @nodoc
class _$AccountCopyWithImpl<$Res, $Val extends Account>
    implements $AccountCopyWith<$Res> {
  _$AccountCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? type = null,
    Object? parentId = freezed,
    Object? formattedBalance = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as AccountType,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            formattedBalance: freezed == formattedBalance
                ? _value.formattedBalance
                : formattedBalance // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountImplCopyWith<$Res> implements $AccountCopyWith<$Res> {
  factory _$$AccountImplCopyWith(
    _$AccountImpl value,
    $Res Function(_$AccountImpl) then,
  ) = __$$AccountImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String code,
    String name,
    AccountType type,
    String? parentId,
    String? formattedBalance,
  });
}

/// @nodoc
class __$$AccountImplCopyWithImpl<$Res>
    extends _$AccountCopyWithImpl<$Res, _$AccountImpl>
    implements _$$AccountImplCopyWith<$Res> {
  __$$AccountImplCopyWithImpl(
    _$AccountImpl _value,
    $Res Function(_$AccountImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? code = null,
    Object? name = null,
    Object? type = null,
    Object? parentId = freezed,
    Object? formattedBalance = freezed,
  }) {
    return _then(
      _$AccountImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as AccountType,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        formattedBalance: freezed == formattedBalance
            ? _value.formattedBalance
            : formattedBalance // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AccountImpl implements _Account {
  const _$AccountImpl({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.parentId,
    this.formattedBalance,
  });

  /// Server / drift PK. Stable across renames.
  @override
  final String id;

  /// Human-readable account code (e.g. `'1100'`, `'1100-01'`).
  /// Sort order within a level is by [code], not [name], so a typo
  /// in the localised name doesn't reshuffle the tree on locale change.
  @override
  final String code;
  @override
  final String name;
  @override
  final AccountType type;

  /// `null` for roots. Multiple roots per type are normal (one root
  /// per account category, sometimes more in deeply nested CoAs).
  @override
  final String? parentId;

  /// Pre-formatted current balance string with currency symbol +
  /// locale separators applied at the data layer. The widget never
  /// formats numbers — keeps the entity locale-stable.
  @override
  final String? formattedBalance;

  @override
  String toString() {
    return 'Account(id: $id, code: $code, name: $name, type: $type, parentId: $parentId, formattedBalance: $formattedBalance)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.formattedBalance, formattedBalance) ||
                other.formattedBalance == formattedBalance));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    code,
    name,
    type,
    parentId,
    formattedBalance,
  );

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      __$$AccountImplCopyWithImpl<_$AccountImpl>(this, _$identity);
}

abstract class _Account implements Account {
  const factory _Account({
    required final String id,
    required final String code,
    required final String name,
    required final AccountType type,
    final String? parentId,
    final String? formattedBalance,
  }) = _$AccountImpl;

  /// Server / drift PK. Stable across renames.
  @override
  String get id;

  /// Human-readable account code (e.g. `'1100'`, `'1100-01'`).
  /// Sort order within a level is by [code], not [name], so a typo
  /// in the localised name doesn't reshuffle the tree on locale change.
  @override
  String get code;
  @override
  String get name;
  @override
  AccountType get type;

  /// `null` for roots. Multiple roots per type are normal (one root
  /// per account category, sometimes more in deeply nested CoAs).
  @override
  String? get parentId;

  /// Pre-formatted current balance string with currency symbol +
  /// locale separators applied at the data layer. The widget never
  /// formats numbers — keeps the entity locale-stable.
  @override
  String? get formattedBalance;

  /// Create a copy of Account
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountImplCopyWith<_$AccountImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
