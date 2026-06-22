// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_detail_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountDetailEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String accountId) started,
    required TResult Function(Account? account) accountUpdated,
    required TResult Function(List<LedgerTransaction> transactions)
    transactionsUpdated,
    required TResult Function(String message) failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String accountId)? started,
    TResult? Function(Account? account)? accountUpdated,
    TResult? Function(List<LedgerTransaction> transactions)?
    transactionsUpdated,
    TResult? Function(String message)? failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String accountId)? started,
    TResult Function(Account? account)? accountUpdated,
    TResult Function(List<LedgerTransaction> transactions)? transactionsUpdated,
    TResult Function(String message)? failed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailStarted value) started,
    required TResult Function(AccountDetailAccountUpdated value) accountUpdated,
    required TResult Function(AccountDetailTransactionsUpdated value)
    transactionsUpdated,
    required TResult Function(AccountDetailFailed value) failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailStarted value)? started,
    TResult? Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult? Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult? Function(AccountDetailFailed value)? failed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailStarted value)? started,
    TResult Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult Function(AccountDetailFailed value)? failed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountDetailEventCopyWith<$Res> {
  factory $AccountDetailEventCopyWith(
    AccountDetailEvent value,
    $Res Function(AccountDetailEvent) then,
  ) = _$AccountDetailEventCopyWithImpl<$Res, AccountDetailEvent>;
}

/// @nodoc
class _$AccountDetailEventCopyWithImpl<$Res, $Val extends AccountDetailEvent>
    implements $AccountDetailEventCopyWith<$Res> {
  _$AccountDetailEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AccountDetailStartedImplCopyWith<$Res> {
  factory _$$AccountDetailStartedImplCopyWith(
    _$AccountDetailStartedImpl value,
    $Res Function(_$AccountDetailStartedImpl) then,
  ) = __$$AccountDetailStartedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String accountId});
}

/// @nodoc
class __$$AccountDetailStartedImplCopyWithImpl<$Res>
    extends _$AccountDetailEventCopyWithImpl<$Res, _$AccountDetailStartedImpl>
    implements _$$AccountDetailStartedImplCopyWith<$Res> {
  __$$AccountDetailStartedImplCopyWithImpl(
    _$AccountDetailStartedImpl _value,
    $Res Function(_$AccountDetailStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? accountId = null}) {
    return _then(
      _$AccountDetailStartedImpl(
        null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountDetailStartedImpl implements AccountDetailStarted {
  const _$AccountDetailStartedImpl(this.accountId);

  @override
  final String accountId;

  @override
  String toString() {
    return 'AccountDetailEvent.started(accountId: $accountId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailStartedImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, accountId);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailStartedImplCopyWith<_$AccountDetailStartedImpl>
  get copyWith =>
      __$$AccountDetailStartedImplCopyWithImpl<_$AccountDetailStartedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String accountId) started,
    required TResult Function(Account? account) accountUpdated,
    required TResult Function(List<LedgerTransaction> transactions)
    transactionsUpdated,
    required TResult Function(String message) failed,
  }) {
    return started(accountId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String accountId)? started,
    TResult? Function(Account? account)? accountUpdated,
    TResult? Function(List<LedgerTransaction> transactions)?
    transactionsUpdated,
    TResult? Function(String message)? failed,
  }) {
    return started?.call(accountId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String accountId)? started,
    TResult Function(Account? account)? accountUpdated,
    TResult Function(List<LedgerTransaction> transactions)? transactionsUpdated,
    TResult Function(String message)? failed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(accountId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailStarted value) started,
    required TResult Function(AccountDetailAccountUpdated value) accountUpdated,
    required TResult Function(AccountDetailTransactionsUpdated value)
    transactionsUpdated,
    required TResult Function(AccountDetailFailed value) failed,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailStarted value)? started,
    TResult? Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult? Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult? Function(AccountDetailFailed value)? failed,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailStarted value)? started,
    TResult Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult Function(AccountDetailFailed value)? failed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class AccountDetailStarted implements AccountDetailEvent {
  const factory AccountDetailStarted(final String accountId) =
      _$AccountDetailStartedImpl;

  String get accountId;

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailStartedImplCopyWith<_$AccountDetailStartedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountDetailAccountUpdatedImplCopyWith<$Res> {
  factory _$$AccountDetailAccountUpdatedImplCopyWith(
    _$AccountDetailAccountUpdatedImpl value,
    $Res Function(_$AccountDetailAccountUpdatedImpl) then,
  ) = __$$AccountDetailAccountUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Account? account});

  $AccountCopyWith<$Res>? get account;
}

/// @nodoc
class __$$AccountDetailAccountUpdatedImplCopyWithImpl<$Res>
    extends
        _$AccountDetailEventCopyWithImpl<
          $Res,
          _$AccountDetailAccountUpdatedImpl
        >
    implements _$$AccountDetailAccountUpdatedImplCopyWith<$Res> {
  __$$AccountDetailAccountUpdatedImplCopyWithImpl(
    _$AccountDetailAccountUpdatedImpl _value,
    $Res Function(_$AccountDetailAccountUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? account = freezed}) {
    return _then(
      _$AccountDetailAccountUpdatedImpl(
        freezed == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as Account?,
      ),
    );
  }

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountCopyWith<$Res>? get account {
    if (_value.account == null) {
      return null;
    }

    return $AccountCopyWith<$Res>(_value.account!, (value) {
      return _then(_value.copyWith(account: value));
    });
  }
}

/// @nodoc

class _$AccountDetailAccountUpdatedImpl implements AccountDetailAccountUpdated {
  const _$AccountDetailAccountUpdatedImpl(this.account);

  @override
  final Account? account;

  @override
  String toString() {
    return 'AccountDetailEvent.accountUpdated(account: $account)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailAccountUpdatedImpl &&
            (identical(other.account, account) || other.account == account));
  }

  @override
  int get hashCode => Object.hash(runtimeType, account);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailAccountUpdatedImplCopyWith<_$AccountDetailAccountUpdatedImpl>
  get copyWith =>
      __$$AccountDetailAccountUpdatedImplCopyWithImpl<
        _$AccountDetailAccountUpdatedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String accountId) started,
    required TResult Function(Account? account) accountUpdated,
    required TResult Function(List<LedgerTransaction> transactions)
    transactionsUpdated,
    required TResult Function(String message) failed,
  }) {
    return accountUpdated(account);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String accountId)? started,
    TResult? Function(Account? account)? accountUpdated,
    TResult? Function(List<LedgerTransaction> transactions)?
    transactionsUpdated,
    TResult? Function(String message)? failed,
  }) {
    return accountUpdated?.call(account);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String accountId)? started,
    TResult Function(Account? account)? accountUpdated,
    TResult Function(List<LedgerTransaction> transactions)? transactionsUpdated,
    TResult Function(String message)? failed,
    required TResult orElse(),
  }) {
    if (accountUpdated != null) {
      return accountUpdated(account);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailStarted value) started,
    required TResult Function(AccountDetailAccountUpdated value) accountUpdated,
    required TResult Function(AccountDetailTransactionsUpdated value)
    transactionsUpdated,
    required TResult Function(AccountDetailFailed value) failed,
  }) {
    return accountUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailStarted value)? started,
    TResult? Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult? Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult? Function(AccountDetailFailed value)? failed,
  }) {
    return accountUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailStarted value)? started,
    TResult Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult Function(AccountDetailFailed value)? failed,
    required TResult orElse(),
  }) {
    if (accountUpdated != null) {
      return accountUpdated(this);
    }
    return orElse();
  }
}

abstract class AccountDetailAccountUpdated implements AccountDetailEvent {
  const factory AccountDetailAccountUpdated(final Account? account) =
      _$AccountDetailAccountUpdatedImpl;

  Account? get account;

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailAccountUpdatedImplCopyWith<_$AccountDetailAccountUpdatedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountDetailTransactionsUpdatedImplCopyWith<$Res> {
  factory _$$AccountDetailTransactionsUpdatedImplCopyWith(
    _$AccountDetailTransactionsUpdatedImpl value,
    $Res Function(_$AccountDetailTransactionsUpdatedImpl) then,
  ) = __$$AccountDetailTransactionsUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<LedgerTransaction> transactions});
}

/// @nodoc
class __$$AccountDetailTransactionsUpdatedImplCopyWithImpl<$Res>
    extends
        _$AccountDetailEventCopyWithImpl<
          $Res,
          _$AccountDetailTransactionsUpdatedImpl
        >
    implements _$$AccountDetailTransactionsUpdatedImplCopyWith<$Res> {
  __$$AccountDetailTransactionsUpdatedImplCopyWithImpl(
    _$AccountDetailTransactionsUpdatedImpl _value,
    $Res Function(_$AccountDetailTransactionsUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? transactions = null}) {
    return _then(
      _$AccountDetailTransactionsUpdatedImpl(
        null == transactions
            ? _value._transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<LedgerTransaction>,
      ),
    );
  }
}

/// @nodoc

class _$AccountDetailTransactionsUpdatedImpl
    implements AccountDetailTransactionsUpdated {
  const _$AccountDetailTransactionsUpdatedImpl(
    final List<LedgerTransaction> transactions,
  ) : _transactions = transactions;

  final List<LedgerTransaction> _transactions;
  @override
  List<LedgerTransaction> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  @override
  String toString() {
    return 'AccountDetailEvent.transactionsUpdated(transactions: $transactions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailTransactionsUpdatedImpl &&
            const DeepCollectionEquality().equals(
              other._transactions,
              _transactions,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_transactions),
  );

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailTransactionsUpdatedImplCopyWith<
    _$AccountDetailTransactionsUpdatedImpl
  >
  get copyWith =>
      __$$AccountDetailTransactionsUpdatedImplCopyWithImpl<
        _$AccountDetailTransactionsUpdatedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String accountId) started,
    required TResult Function(Account? account) accountUpdated,
    required TResult Function(List<LedgerTransaction> transactions)
    transactionsUpdated,
    required TResult Function(String message) failed,
  }) {
    return transactionsUpdated(transactions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String accountId)? started,
    TResult? Function(Account? account)? accountUpdated,
    TResult? Function(List<LedgerTransaction> transactions)?
    transactionsUpdated,
    TResult? Function(String message)? failed,
  }) {
    return transactionsUpdated?.call(transactions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String accountId)? started,
    TResult Function(Account? account)? accountUpdated,
    TResult Function(List<LedgerTransaction> transactions)? transactionsUpdated,
    TResult Function(String message)? failed,
    required TResult orElse(),
  }) {
    if (transactionsUpdated != null) {
      return transactionsUpdated(transactions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailStarted value) started,
    required TResult Function(AccountDetailAccountUpdated value) accountUpdated,
    required TResult Function(AccountDetailTransactionsUpdated value)
    transactionsUpdated,
    required TResult Function(AccountDetailFailed value) failed,
  }) {
    return transactionsUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailStarted value)? started,
    TResult? Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult? Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult? Function(AccountDetailFailed value)? failed,
  }) {
    return transactionsUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailStarted value)? started,
    TResult Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult Function(AccountDetailFailed value)? failed,
    required TResult orElse(),
  }) {
    if (transactionsUpdated != null) {
      return transactionsUpdated(this);
    }
    return orElse();
  }
}

abstract class AccountDetailTransactionsUpdated implements AccountDetailEvent {
  const factory AccountDetailTransactionsUpdated(
    final List<LedgerTransaction> transactions,
  ) = _$AccountDetailTransactionsUpdatedImpl;

  List<LedgerTransaction> get transactions;

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailTransactionsUpdatedImplCopyWith<
    _$AccountDetailTransactionsUpdatedImpl
  >
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountDetailFailedImplCopyWith<$Res> {
  factory _$$AccountDetailFailedImplCopyWith(
    _$AccountDetailFailedImpl value,
    $Res Function(_$AccountDetailFailedImpl) then,
  ) = __$$AccountDetailFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AccountDetailFailedImplCopyWithImpl<$Res>
    extends _$AccountDetailEventCopyWithImpl<$Res, _$AccountDetailFailedImpl>
    implements _$$AccountDetailFailedImplCopyWith<$Res> {
  __$$AccountDetailFailedImplCopyWithImpl(
    _$AccountDetailFailedImpl _value,
    $Res Function(_$AccountDetailFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$AccountDetailFailedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountDetailFailedImpl implements AccountDetailFailed {
  const _$AccountDetailFailedImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AccountDetailEvent.failed(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailFailedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailFailedImplCopyWith<_$AccountDetailFailedImpl> get copyWith =>
      __$$AccountDetailFailedImplCopyWithImpl<_$AccountDetailFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String accountId) started,
    required TResult Function(Account? account) accountUpdated,
    required TResult Function(List<LedgerTransaction> transactions)
    transactionsUpdated,
    required TResult Function(String message) failed,
  }) {
    return failed(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String accountId)? started,
    TResult? Function(Account? account)? accountUpdated,
    TResult? Function(List<LedgerTransaction> transactions)?
    transactionsUpdated,
    TResult? Function(String message)? failed,
  }) {
    return failed?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String accountId)? started,
    TResult Function(Account? account)? accountUpdated,
    TResult Function(List<LedgerTransaction> transactions)? transactionsUpdated,
    TResult Function(String message)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailStarted value) started,
    required TResult Function(AccountDetailAccountUpdated value) accountUpdated,
    required TResult Function(AccountDetailTransactionsUpdated value)
    transactionsUpdated,
    required TResult Function(AccountDetailFailed value) failed,
  }) {
    return failed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailStarted value)? started,
    TResult? Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult? Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult? Function(AccountDetailFailed value)? failed,
  }) {
    return failed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailStarted value)? started,
    TResult Function(AccountDetailAccountUpdated value)? accountUpdated,
    TResult Function(AccountDetailTransactionsUpdated value)?
    transactionsUpdated,
    TResult Function(AccountDetailFailed value)? failed,
    required TResult orElse(),
  }) {
    if (failed != null) {
      return failed(this);
    }
    return orElse();
  }
}

abstract class AccountDetailFailed implements AccountDetailEvent {
  const factory AccountDetailFailed(final String message) =
      _$AccountDetailFailedImpl;

  String get message;

  /// Create a copy of AccountDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailFailedImplCopyWith<_$AccountDetailFailedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
