// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_detail_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountDetailState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Account account,
      List<LedgerTransaction> transactions,
    )
    loaded,
    required TResult Function(String accountId) notFound,
    required TResult Function(String message) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult? Function(String accountId)? notFound,
    TResult? Function(String message)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult Function(String accountId)? notFound,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailInitial value) initial,
    required TResult Function(AccountDetailLoading value) loading,
    required TResult Function(AccountDetailLoaded value) loaded,
    required TResult Function(AccountDetailNotFound value) notFound,
    required TResult Function(AccountDetailFailure value) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailInitial value)? initial,
    TResult? Function(AccountDetailLoading value)? loading,
    TResult? Function(AccountDetailLoaded value)? loaded,
    TResult? Function(AccountDetailNotFound value)? notFound,
    TResult? Function(AccountDetailFailure value)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailInitial value)? initial,
    TResult Function(AccountDetailLoading value)? loading,
    TResult Function(AccountDetailLoaded value)? loaded,
    TResult Function(AccountDetailNotFound value)? notFound,
    TResult Function(AccountDetailFailure value)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountDetailStateCopyWith<$Res> {
  factory $AccountDetailStateCopyWith(
    AccountDetailState value,
    $Res Function(AccountDetailState) then,
  ) = _$AccountDetailStateCopyWithImpl<$Res, AccountDetailState>;
}

/// @nodoc
class _$AccountDetailStateCopyWithImpl<$Res, $Val extends AccountDetailState>
    implements $AccountDetailStateCopyWith<$Res> {
  _$AccountDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AccountDetailInitialImplCopyWith<$Res> {
  factory _$$AccountDetailInitialImplCopyWith(
    _$AccountDetailInitialImpl value,
    $Res Function(_$AccountDetailInitialImpl) then,
  ) = __$$AccountDetailInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountDetailInitialImplCopyWithImpl<$Res>
    extends _$AccountDetailStateCopyWithImpl<$Res, _$AccountDetailInitialImpl>
    implements _$$AccountDetailInitialImplCopyWith<$Res> {
  __$$AccountDetailInitialImplCopyWithImpl(
    _$AccountDetailInitialImpl _value,
    $Res Function(_$AccountDetailInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountDetailInitialImpl implements AccountDetailInitial {
  const _$AccountDetailInitialImpl();

  @override
  String toString() {
    return 'AccountDetailState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Account account,
      List<LedgerTransaction> transactions,
    )
    loaded,
    required TResult Function(String accountId) notFound,
    required TResult Function(String message) failure,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult? Function(String accountId)? notFound,
    TResult? Function(String message)? failure,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult Function(String accountId)? notFound,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailInitial value) initial,
    required TResult Function(AccountDetailLoading value) loading,
    required TResult Function(AccountDetailLoaded value) loaded,
    required TResult Function(AccountDetailNotFound value) notFound,
    required TResult Function(AccountDetailFailure value) failure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailInitial value)? initial,
    TResult? Function(AccountDetailLoading value)? loading,
    TResult? Function(AccountDetailLoaded value)? loaded,
    TResult? Function(AccountDetailNotFound value)? notFound,
    TResult? Function(AccountDetailFailure value)? failure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailInitial value)? initial,
    TResult Function(AccountDetailLoading value)? loading,
    TResult Function(AccountDetailLoaded value)? loaded,
    TResult Function(AccountDetailNotFound value)? notFound,
    TResult Function(AccountDetailFailure value)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class AccountDetailInitial implements AccountDetailState {
  const factory AccountDetailInitial() = _$AccountDetailInitialImpl;
}

/// @nodoc
abstract class _$$AccountDetailLoadingImplCopyWith<$Res> {
  factory _$$AccountDetailLoadingImplCopyWith(
    _$AccountDetailLoadingImpl value,
    $Res Function(_$AccountDetailLoadingImpl) then,
  ) = __$$AccountDetailLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountDetailLoadingImplCopyWithImpl<$Res>
    extends _$AccountDetailStateCopyWithImpl<$Res, _$AccountDetailLoadingImpl>
    implements _$$AccountDetailLoadingImplCopyWith<$Res> {
  __$$AccountDetailLoadingImplCopyWithImpl(
    _$AccountDetailLoadingImpl _value,
    $Res Function(_$AccountDetailLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountDetailLoadingImpl implements AccountDetailLoading {
  const _$AccountDetailLoadingImpl();

  @override
  String toString() {
    return 'AccountDetailState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Account account,
      List<LedgerTransaction> transactions,
    )
    loaded,
    required TResult Function(String accountId) notFound,
    required TResult Function(String message) failure,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult? Function(String accountId)? notFound,
    TResult? Function(String message)? failure,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult Function(String accountId)? notFound,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailInitial value) initial,
    required TResult Function(AccountDetailLoading value) loading,
    required TResult Function(AccountDetailLoaded value) loaded,
    required TResult Function(AccountDetailNotFound value) notFound,
    required TResult Function(AccountDetailFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailInitial value)? initial,
    TResult? Function(AccountDetailLoading value)? loading,
    TResult? Function(AccountDetailLoaded value)? loaded,
    TResult? Function(AccountDetailNotFound value)? notFound,
    TResult? Function(AccountDetailFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailInitial value)? initial,
    TResult Function(AccountDetailLoading value)? loading,
    TResult Function(AccountDetailLoaded value)? loaded,
    TResult Function(AccountDetailNotFound value)? notFound,
    TResult Function(AccountDetailFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AccountDetailLoading implements AccountDetailState {
  const factory AccountDetailLoading() = _$AccountDetailLoadingImpl;
}

/// @nodoc
abstract class _$$AccountDetailLoadedImplCopyWith<$Res> {
  factory _$$AccountDetailLoadedImplCopyWith(
    _$AccountDetailLoadedImpl value,
    $Res Function(_$AccountDetailLoadedImpl) then,
  ) = __$$AccountDetailLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Account account, List<LedgerTransaction> transactions});

  $AccountCopyWith<$Res> get account;
}

/// @nodoc
class __$$AccountDetailLoadedImplCopyWithImpl<$Res>
    extends _$AccountDetailStateCopyWithImpl<$Res, _$AccountDetailLoadedImpl>
    implements _$$AccountDetailLoadedImplCopyWith<$Res> {
  __$$AccountDetailLoadedImplCopyWithImpl(
    _$AccountDetailLoadedImpl _value,
    $Res Function(_$AccountDetailLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? account = null, Object? transactions = null}) {
    return _then(
      _$AccountDetailLoadedImpl(
        account: null == account
            ? _value.account
            : account // ignore: cast_nullable_to_non_nullable
                  as Account,
        transactions: null == transactions
            ? _value._transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<LedgerTransaction>,
      ),
    );
  }

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AccountCopyWith<$Res> get account {
    return $AccountCopyWith<$Res>(_value.account, (value) {
      return _then(_value.copyWith(account: value));
    });
  }
}

/// @nodoc

class _$AccountDetailLoadedImpl implements AccountDetailLoaded {
  const _$AccountDetailLoadedImpl({
    required this.account,
    required final List<LedgerTransaction> transactions,
  }) : _transactions = transactions;

  @override
  final Account account;
  final List<LedgerTransaction> _transactions;
  @override
  List<LedgerTransaction> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  @override
  String toString() {
    return 'AccountDetailState.loaded(account: $account, transactions: $transactions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailLoadedImpl &&
            (identical(other.account, account) || other.account == account) &&
            const DeepCollectionEquality().equals(
              other._transactions,
              _transactions,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    account,
    const DeepCollectionEquality().hash(_transactions),
  );

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailLoadedImplCopyWith<_$AccountDetailLoadedImpl> get copyWith =>
      __$$AccountDetailLoadedImplCopyWithImpl<_$AccountDetailLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Account account,
      List<LedgerTransaction> transactions,
    )
    loaded,
    required TResult Function(String accountId) notFound,
    required TResult Function(String message) failure,
  }) {
    return loaded(account, transactions);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult? Function(String accountId)? notFound,
    TResult? Function(String message)? failure,
  }) {
    return loaded?.call(account, transactions);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult Function(String accountId)? notFound,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(account, transactions);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailInitial value) initial,
    required TResult Function(AccountDetailLoading value) loading,
    required TResult Function(AccountDetailLoaded value) loaded,
    required TResult Function(AccountDetailNotFound value) notFound,
    required TResult Function(AccountDetailFailure value) failure,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailInitial value)? initial,
    TResult? Function(AccountDetailLoading value)? loading,
    TResult? Function(AccountDetailLoaded value)? loaded,
    TResult? Function(AccountDetailNotFound value)? notFound,
    TResult? Function(AccountDetailFailure value)? failure,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailInitial value)? initial,
    TResult Function(AccountDetailLoading value)? loading,
    TResult Function(AccountDetailLoaded value)? loaded,
    TResult Function(AccountDetailNotFound value)? notFound,
    TResult Function(AccountDetailFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class AccountDetailLoaded implements AccountDetailState {
  const factory AccountDetailLoaded({
    required final Account account,
    required final List<LedgerTransaction> transactions,
  }) = _$AccountDetailLoadedImpl;

  Account get account;
  List<LedgerTransaction> get transactions;

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailLoadedImplCopyWith<_$AccountDetailLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountDetailNotFoundImplCopyWith<$Res> {
  factory _$$AccountDetailNotFoundImplCopyWith(
    _$AccountDetailNotFoundImpl value,
    $Res Function(_$AccountDetailNotFoundImpl) then,
  ) = __$$AccountDetailNotFoundImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String accountId});
}

/// @nodoc
class __$$AccountDetailNotFoundImplCopyWithImpl<$Res>
    extends _$AccountDetailStateCopyWithImpl<$Res, _$AccountDetailNotFoundImpl>
    implements _$$AccountDetailNotFoundImplCopyWith<$Res> {
  __$$AccountDetailNotFoundImplCopyWithImpl(
    _$AccountDetailNotFoundImpl _value,
    $Res Function(_$AccountDetailNotFoundImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? accountId = null}) {
    return _then(
      _$AccountDetailNotFoundImpl(
        null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountDetailNotFoundImpl implements AccountDetailNotFound {
  const _$AccountDetailNotFoundImpl(this.accountId);

  @override
  final String accountId;

  @override
  String toString() {
    return 'AccountDetailState.notFound(accountId: $accountId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailNotFoundImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, accountId);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailNotFoundImplCopyWith<_$AccountDetailNotFoundImpl>
  get copyWith =>
      __$$AccountDetailNotFoundImplCopyWithImpl<_$AccountDetailNotFoundImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Account account,
      List<LedgerTransaction> transactions,
    )
    loaded,
    required TResult Function(String accountId) notFound,
    required TResult Function(String message) failure,
  }) {
    return notFound(accountId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult? Function(String accountId)? notFound,
    TResult? Function(String message)? failure,
  }) {
    return notFound?.call(accountId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult Function(String accountId)? notFound,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(accountId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailInitial value) initial,
    required TResult Function(AccountDetailLoading value) loading,
    required TResult Function(AccountDetailLoaded value) loaded,
    required TResult Function(AccountDetailNotFound value) notFound,
    required TResult Function(AccountDetailFailure value) failure,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailInitial value)? initial,
    TResult? Function(AccountDetailLoading value)? loading,
    TResult? Function(AccountDetailLoaded value)? loaded,
    TResult? Function(AccountDetailNotFound value)? notFound,
    TResult? Function(AccountDetailFailure value)? failure,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailInitial value)? initial,
    TResult Function(AccountDetailLoading value)? loading,
    TResult Function(AccountDetailLoaded value)? loaded,
    TResult Function(AccountDetailNotFound value)? notFound,
    TResult Function(AccountDetailFailure value)? failure,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class AccountDetailNotFound implements AccountDetailState {
  const factory AccountDetailNotFound(final String accountId) =
      _$AccountDetailNotFoundImpl;

  String get accountId;

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailNotFoundImplCopyWith<_$AccountDetailNotFoundImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountDetailFailureImplCopyWith<$Res> {
  factory _$$AccountDetailFailureImplCopyWith(
    _$AccountDetailFailureImpl value,
    $Res Function(_$AccountDetailFailureImpl) then,
  ) = __$$AccountDetailFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AccountDetailFailureImplCopyWithImpl<$Res>
    extends _$AccountDetailStateCopyWithImpl<$Res, _$AccountDetailFailureImpl>
    implements _$$AccountDetailFailureImplCopyWith<$Res> {
  __$$AccountDetailFailureImplCopyWithImpl(
    _$AccountDetailFailureImpl _value,
    $Res Function(_$AccountDetailFailureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$AccountDetailFailureImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountDetailFailureImpl implements AccountDetailFailure {
  const _$AccountDetailFailureImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AccountDetailState.failure(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountDetailFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountDetailFailureImplCopyWith<_$AccountDetailFailureImpl>
  get copyWith =>
      __$$AccountDetailFailureImplCopyWithImpl<_$AccountDetailFailureImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      Account account,
      List<LedgerTransaction> transactions,
    )
    loaded,
    required TResult Function(String accountId) notFound,
    required TResult Function(String message) failure,
  }) {
    return failure(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult? Function(String accountId)? notFound,
    TResult? Function(String message)? failure,
  }) {
    return failure?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Account account, List<LedgerTransaction> transactions)?
    loaded,
    TResult Function(String accountId)? notFound,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountDetailInitial value) initial,
    required TResult Function(AccountDetailLoading value) loading,
    required TResult Function(AccountDetailLoaded value) loaded,
    required TResult Function(AccountDetailNotFound value) notFound,
    required TResult Function(AccountDetailFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountDetailInitial value)? initial,
    TResult? Function(AccountDetailLoading value)? loading,
    TResult? Function(AccountDetailLoaded value)? loaded,
    TResult? Function(AccountDetailNotFound value)? notFound,
    TResult? Function(AccountDetailFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountDetailInitial value)? initial,
    TResult Function(AccountDetailLoading value)? loading,
    TResult Function(AccountDetailLoaded value)? loaded,
    TResult Function(AccountDetailNotFound value)? notFound,
    TResult Function(AccountDetailFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class AccountDetailFailure implements AccountDetailState {
  const factory AccountDetailFailure(final String message) =
      _$AccountDetailFailureImpl;

  String get message;

  /// Create a copy of AccountDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountDetailFailureImplCopyWith<_$AccountDetailFailureImpl>
  get copyWith => throw _privateConstructorUsedError;
}
