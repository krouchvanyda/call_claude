// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_tree_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountTreeEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountTreeEventCopyWith<$Res> {
  factory $AccountTreeEventCopyWith(
    AccountTreeEvent value,
    $Res Function(AccountTreeEvent) then,
  ) = _$AccountTreeEventCopyWithImpl<$Res, AccountTreeEvent>;
}

/// @nodoc
class _$AccountTreeEventCopyWithImpl<$Res, $Val extends AccountTreeEvent>
    implements $AccountTreeEventCopyWith<$Res> {
  _$AccountTreeEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AccountTreeStartedImplCopyWith<$Res> {
  factory _$$AccountTreeStartedImplCopyWith(
    _$AccountTreeStartedImpl value,
    $Res Function(_$AccountTreeStartedImpl) then,
  ) = __$$AccountTreeStartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountTreeStartedImplCopyWithImpl<$Res>
    extends _$AccountTreeEventCopyWithImpl<$Res, _$AccountTreeStartedImpl>
    implements _$$AccountTreeStartedImplCopyWith<$Res> {
  __$$AccountTreeStartedImplCopyWithImpl(
    _$AccountTreeStartedImpl _value,
    $Res Function(_$AccountTreeStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountTreeStartedImpl implements AccountTreeStarted {
  const _$AccountTreeStartedImpl();

  @override
  String toString() {
    return 'AccountTreeEvent.started()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AccountTreeStartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return started?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class AccountTreeStarted implements AccountTreeEvent {
  const factory AccountTreeStarted() = _$AccountTreeStartedImpl;
}

/// @nodoc
abstract class _$$AccountTreeNodeToggledImplCopyWith<$Res> {
  factory _$$AccountTreeNodeToggledImplCopyWith(
    _$AccountTreeNodeToggledImpl value,
    $Res Function(_$AccountTreeNodeToggledImpl) then,
  ) = __$$AccountTreeNodeToggledImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String accountId});
}

/// @nodoc
class __$$AccountTreeNodeToggledImplCopyWithImpl<$Res>
    extends _$AccountTreeEventCopyWithImpl<$Res, _$AccountTreeNodeToggledImpl>
    implements _$$AccountTreeNodeToggledImplCopyWith<$Res> {
  __$$AccountTreeNodeToggledImplCopyWithImpl(
    _$AccountTreeNodeToggledImpl _value,
    $Res Function(_$AccountTreeNodeToggledImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? accountId = null}) {
    return _then(
      _$AccountTreeNodeToggledImpl(
        null == accountId
            ? _value.accountId
            : accountId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountTreeNodeToggledImpl implements AccountTreeNodeToggled {
  const _$AccountTreeNodeToggledImpl(this.accountId);

  @override
  final String accountId;

  @override
  String toString() {
    return 'AccountTreeEvent.nodeToggled(accountId: $accountId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeNodeToggledImpl &&
            (identical(other.accountId, accountId) ||
                other.accountId == accountId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, accountId);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTreeNodeToggledImplCopyWith<_$AccountTreeNodeToggledImpl>
  get copyWith =>
      __$$AccountTreeNodeToggledImplCopyWithImpl<_$AccountTreeNodeToggledImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return nodeToggled(accountId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return nodeToggled?.call(accountId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (nodeToggled != null) {
      return nodeToggled(accountId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) {
    return nodeToggled(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) {
    return nodeToggled?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (nodeToggled != null) {
      return nodeToggled(this);
    }
    return orElse();
  }
}

abstract class AccountTreeNodeToggled implements AccountTreeEvent {
  const factory AccountTreeNodeToggled(final String accountId) =
      _$AccountTreeNodeToggledImpl;

  String get accountId;

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTreeNodeToggledImplCopyWith<_$AccountTreeNodeToggledImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountTreeExpandedAllImplCopyWith<$Res> {
  factory _$$AccountTreeExpandedAllImplCopyWith(
    _$AccountTreeExpandedAllImpl value,
    $Res Function(_$AccountTreeExpandedAllImpl) then,
  ) = __$$AccountTreeExpandedAllImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountTreeExpandedAllImplCopyWithImpl<$Res>
    extends _$AccountTreeEventCopyWithImpl<$Res, _$AccountTreeExpandedAllImpl>
    implements _$$AccountTreeExpandedAllImplCopyWith<$Res> {
  __$$AccountTreeExpandedAllImplCopyWithImpl(
    _$AccountTreeExpandedAllImpl _value,
    $Res Function(_$AccountTreeExpandedAllImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountTreeExpandedAllImpl implements AccountTreeExpandedAll {
  const _$AccountTreeExpandedAllImpl();

  @override
  String toString() {
    return 'AccountTreeEvent.expandedAll()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeExpandedAllImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return expandedAll();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return expandedAll?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (expandedAll != null) {
      return expandedAll();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) {
    return expandedAll(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) {
    return expandedAll?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (expandedAll != null) {
      return expandedAll(this);
    }
    return orElse();
  }
}

abstract class AccountTreeExpandedAll implements AccountTreeEvent {
  const factory AccountTreeExpandedAll() = _$AccountTreeExpandedAllImpl;
}

/// @nodoc
abstract class _$$AccountTreeCollapsedAllImplCopyWith<$Res> {
  factory _$$AccountTreeCollapsedAllImplCopyWith(
    _$AccountTreeCollapsedAllImpl value,
    $Res Function(_$AccountTreeCollapsedAllImpl) then,
  ) = __$$AccountTreeCollapsedAllImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountTreeCollapsedAllImplCopyWithImpl<$Res>
    extends _$AccountTreeEventCopyWithImpl<$Res, _$AccountTreeCollapsedAllImpl>
    implements _$$AccountTreeCollapsedAllImplCopyWith<$Res> {
  __$$AccountTreeCollapsedAllImplCopyWithImpl(
    _$AccountTreeCollapsedAllImpl _value,
    $Res Function(_$AccountTreeCollapsedAllImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountTreeCollapsedAllImpl implements AccountTreeCollapsedAll {
  const _$AccountTreeCollapsedAllImpl();

  @override
  String toString() {
    return 'AccountTreeEvent.collapsedAll()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeCollapsedAllImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return collapsedAll();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return collapsedAll?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (collapsedAll != null) {
      return collapsedAll();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) {
    return collapsedAll(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) {
    return collapsedAll?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (collapsedAll != null) {
      return collapsedAll(this);
    }
    return orElse();
  }
}

abstract class AccountTreeCollapsedAll implements AccountTreeEvent {
  const factory AccountTreeCollapsedAll() = _$AccountTreeCollapsedAllImpl;
}

/// @nodoc
abstract class _$$AccountTreeFeedUpdatedImplCopyWith<$Res> {
  factory _$$AccountTreeFeedUpdatedImplCopyWith(
    _$AccountTreeFeedUpdatedImpl value,
    $Res Function(_$AccountTreeFeedUpdatedImpl) then,
  ) = __$$AccountTreeFeedUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Account> accounts});
}

/// @nodoc
class __$$AccountTreeFeedUpdatedImplCopyWithImpl<$Res>
    extends _$AccountTreeEventCopyWithImpl<$Res, _$AccountTreeFeedUpdatedImpl>
    implements _$$AccountTreeFeedUpdatedImplCopyWith<$Res> {
  __$$AccountTreeFeedUpdatedImplCopyWithImpl(
    _$AccountTreeFeedUpdatedImpl _value,
    $Res Function(_$AccountTreeFeedUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? accounts = null}) {
    return _then(
      _$AccountTreeFeedUpdatedImpl(
        null == accounts
            ? _value._accounts
            : accounts // ignore: cast_nullable_to_non_nullable
                  as List<Account>,
      ),
    );
  }
}

/// @nodoc

class _$AccountTreeFeedUpdatedImpl implements AccountTreeFeedUpdated {
  const _$AccountTreeFeedUpdatedImpl(final List<Account> accounts)
    : _accounts = accounts;

  final List<Account> _accounts;
  @override
  List<Account> get accounts {
    if (_accounts is EqualUnmodifiableListView) return _accounts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_accounts);
  }

  @override
  String toString() {
    return 'AccountTreeEvent.feedUpdated(accounts: $accounts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeFeedUpdatedImpl &&
            const DeepCollectionEquality().equals(other._accounts, _accounts));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_accounts));

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTreeFeedUpdatedImplCopyWith<_$AccountTreeFeedUpdatedImpl>
  get copyWith =>
      __$$AccountTreeFeedUpdatedImplCopyWithImpl<_$AccountTreeFeedUpdatedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return feedUpdated(accounts);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return feedUpdated?.call(accounts);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedUpdated != null) {
      return feedUpdated(accounts);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) {
    return feedUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) {
    return feedUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedUpdated != null) {
      return feedUpdated(this);
    }
    return orElse();
  }
}

abstract class AccountTreeFeedUpdated implements AccountTreeEvent {
  const factory AccountTreeFeedUpdated(final List<Account> accounts) =
      _$AccountTreeFeedUpdatedImpl;

  List<Account> get accounts;

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTreeFeedUpdatedImplCopyWith<_$AccountTreeFeedUpdatedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountTreeFeedFailedImplCopyWith<$Res> {
  factory _$$AccountTreeFeedFailedImplCopyWith(
    _$AccountTreeFeedFailedImpl value,
    $Res Function(_$AccountTreeFeedFailedImpl) then,
  ) = __$$AccountTreeFeedFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AccountTreeFeedFailedImplCopyWithImpl<$Res>
    extends _$AccountTreeEventCopyWithImpl<$Res, _$AccountTreeFeedFailedImpl>
    implements _$$AccountTreeFeedFailedImplCopyWith<$Res> {
  __$$AccountTreeFeedFailedImplCopyWithImpl(
    _$AccountTreeFeedFailedImpl _value,
    $Res Function(_$AccountTreeFeedFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$AccountTreeFeedFailedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountTreeFeedFailedImpl implements AccountTreeFeedFailed {
  const _$AccountTreeFeedFailedImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AccountTreeEvent.feedFailed(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeFeedFailedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTreeFeedFailedImplCopyWith<_$AccountTreeFeedFailedImpl>
  get copyWith =>
      __$$AccountTreeFeedFailedImplCopyWithImpl<_$AccountTreeFeedFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String accountId) nodeToggled,
    required TResult Function() expandedAll,
    required TResult Function() collapsedAll,
    required TResult Function(List<Account> accounts) feedUpdated,
    required TResult Function(String message) feedFailed,
  }) {
    return feedFailed(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String accountId)? nodeToggled,
    TResult? Function()? expandedAll,
    TResult? Function()? collapsedAll,
    TResult? Function(List<Account> accounts)? feedUpdated,
    TResult? Function(String message)? feedFailed,
  }) {
    return feedFailed?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String accountId)? nodeToggled,
    TResult Function()? expandedAll,
    TResult Function()? collapsedAll,
    TResult Function(List<Account> accounts)? feedUpdated,
    TResult Function(String message)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedFailed != null) {
      return feedFailed(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeStarted value) started,
    required TResult Function(AccountTreeNodeToggled value) nodeToggled,
    required TResult Function(AccountTreeExpandedAll value) expandedAll,
    required TResult Function(AccountTreeCollapsedAll value) collapsedAll,
    required TResult Function(AccountTreeFeedUpdated value) feedUpdated,
    required TResult Function(AccountTreeFeedFailed value) feedFailed,
  }) {
    return feedFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeStarted value)? started,
    TResult? Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult? Function(AccountTreeExpandedAll value)? expandedAll,
    TResult? Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult? Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult? Function(AccountTreeFeedFailed value)? feedFailed,
  }) {
    return feedFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeStarted value)? started,
    TResult Function(AccountTreeNodeToggled value)? nodeToggled,
    TResult Function(AccountTreeExpandedAll value)? expandedAll,
    TResult Function(AccountTreeCollapsedAll value)? collapsedAll,
    TResult Function(AccountTreeFeedUpdated value)? feedUpdated,
    TResult Function(AccountTreeFeedFailed value)? feedFailed,
    required TResult orElse(),
  }) {
    if (feedFailed != null) {
      return feedFailed(this);
    }
    return orElse();
  }
}

abstract class AccountTreeFeedFailed implements AccountTreeEvent {
  const factory AccountTreeFeedFailed(final String message) =
      _$AccountTreeFeedFailedImpl;

  String get message;

  /// Create a copy of AccountTreeEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTreeFeedFailedImplCopyWith<_$AccountTreeFeedFailedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
