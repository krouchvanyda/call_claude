// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_tree_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountTreeState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AccountTreeNode> roots,
      Set<String> expandedIds,
    )
    loaded,
    required TResult Function(String message) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult? Function(String message)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeInitial value) initial,
    required TResult Function(AccountTreeLoading value) loading,
    required TResult Function(AccountTreeLoaded value) loaded,
    required TResult Function(AccountTreeFailure value) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeInitial value)? initial,
    TResult? Function(AccountTreeLoading value)? loading,
    TResult? Function(AccountTreeLoaded value)? loaded,
    TResult? Function(AccountTreeFailure value)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeInitial value)? initial,
    TResult Function(AccountTreeLoading value)? loading,
    TResult Function(AccountTreeLoaded value)? loaded,
    TResult Function(AccountTreeFailure value)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountTreeStateCopyWith<$Res> {
  factory $AccountTreeStateCopyWith(
    AccountTreeState value,
    $Res Function(AccountTreeState) then,
  ) = _$AccountTreeStateCopyWithImpl<$Res, AccountTreeState>;
}

/// @nodoc
class _$AccountTreeStateCopyWithImpl<$Res, $Val extends AccountTreeState>
    implements $AccountTreeStateCopyWith<$Res> {
  _$AccountTreeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AccountTreeInitialImplCopyWith<$Res> {
  factory _$$AccountTreeInitialImplCopyWith(
    _$AccountTreeInitialImpl value,
    $Res Function(_$AccountTreeInitialImpl) then,
  ) = __$$AccountTreeInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountTreeInitialImplCopyWithImpl<$Res>
    extends _$AccountTreeStateCopyWithImpl<$Res, _$AccountTreeInitialImpl>
    implements _$$AccountTreeInitialImplCopyWith<$Res> {
  __$$AccountTreeInitialImplCopyWithImpl(
    _$AccountTreeInitialImpl _value,
    $Res Function(_$AccountTreeInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountTreeInitialImpl implements AccountTreeInitial {
  const _$AccountTreeInitialImpl();

  @override
  String toString() {
    return 'AccountTreeState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AccountTreeInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AccountTreeNode> roots,
      Set<String> expandedIds,
    )
    loaded,
    required TResult Function(String message) failure,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult? Function(String message)? failure,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
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
    required TResult Function(AccountTreeInitial value) initial,
    required TResult Function(AccountTreeLoading value) loading,
    required TResult Function(AccountTreeLoaded value) loaded,
    required TResult Function(AccountTreeFailure value) failure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeInitial value)? initial,
    TResult? Function(AccountTreeLoading value)? loading,
    TResult? Function(AccountTreeLoaded value)? loaded,
    TResult? Function(AccountTreeFailure value)? failure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeInitial value)? initial,
    TResult Function(AccountTreeLoading value)? loading,
    TResult Function(AccountTreeLoaded value)? loaded,
    TResult Function(AccountTreeFailure value)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class AccountTreeInitial implements AccountTreeState {
  const factory AccountTreeInitial() = _$AccountTreeInitialImpl;
}

/// @nodoc
abstract class _$$AccountTreeLoadingImplCopyWith<$Res> {
  factory _$$AccountTreeLoadingImplCopyWith(
    _$AccountTreeLoadingImpl value,
    $Res Function(_$AccountTreeLoadingImpl) then,
  ) = __$$AccountTreeLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AccountTreeLoadingImplCopyWithImpl<$Res>
    extends _$AccountTreeStateCopyWithImpl<$Res, _$AccountTreeLoadingImpl>
    implements _$$AccountTreeLoadingImplCopyWith<$Res> {
  __$$AccountTreeLoadingImplCopyWithImpl(
    _$AccountTreeLoadingImpl _value,
    $Res Function(_$AccountTreeLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$AccountTreeLoadingImpl implements AccountTreeLoading {
  const _$AccountTreeLoadingImpl();

  @override
  String toString() {
    return 'AccountTreeState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AccountTreeLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AccountTreeNode> roots,
      Set<String> expandedIds,
    )
    loaded,
    required TResult Function(String message) failure,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult? Function(String message)? failure,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
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
    required TResult Function(AccountTreeInitial value) initial,
    required TResult Function(AccountTreeLoading value) loading,
    required TResult Function(AccountTreeLoaded value) loaded,
    required TResult Function(AccountTreeFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeInitial value)? initial,
    TResult? Function(AccountTreeLoading value)? loading,
    TResult? Function(AccountTreeLoaded value)? loaded,
    TResult? Function(AccountTreeFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeInitial value)? initial,
    TResult Function(AccountTreeLoading value)? loading,
    TResult Function(AccountTreeLoaded value)? loaded,
    TResult Function(AccountTreeFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class AccountTreeLoading implements AccountTreeState {
  const factory AccountTreeLoading() = _$AccountTreeLoadingImpl;
}

/// @nodoc
abstract class _$$AccountTreeLoadedImplCopyWith<$Res> {
  factory _$$AccountTreeLoadedImplCopyWith(
    _$AccountTreeLoadedImpl value,
    $Res Function(_$AccountTreeLoadedImpl) then,
  ) = __$$AccountTreeLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AccountTreeNode> roots, Set<String> expandedIds});
}

/// @nodoc
class __$$AccountTreeLoadedImplCopyWithImpl<$Res>
    extends _$AccountTreeStateCopyWithImpl<$Res, _$AccountTreeLoadedImpl>
    implements _$$AccountTreeLoadedImplCopyWith<$Res> {
  __$$AccountTreeLoadedImplCopyWithImpl(
    _$AccountTreeLoadedImpl _value,
    $Res Function(_$AccountTreeLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? roots = null, Object? expandedIds = null}) {
    return _then(
      _$AccountTreeLoadedImpl(
        roots: null == roots
            ? _value._roots
            : roots // ignore: cast_nullable_to_non_nullable
                  as List<AccountTreeNode>,
        expandedIds: null == expandedIds
            ? _value._expandedIds
            : expandedIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

/// @nodoc

class _$AccountTreeLoadedImpl implements AccountTreeLoaded {
  const _$AccountTreeLoadedImpl({
    required final List<AccountTreeNode> roots,
    required final Set<String> expandedIds,
  }) : _roots = roots,
       _expandedIds = expandedIds;

  /// Pre-built roots (sorted, depth-tagged).
  final List<AccountTreeNode> _roots;

  /// Pre-built roots (sorted, depth-tagged).
  @override
  List<AccountTreeNode> get roots {
    if (_roots is EqualUnmodifiableListView) return _roots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_roots);
  }

  /// Set of account ids whose children are visible. Lookups are
  /// O(1) via Set<String>.
  final Set<String> _expandedIds;

  /// Set of account ids whose children are visible. Lookups are
  /// O(1) via Set<String>.
  @override
  Set<String> get expandedIds {
    if (_expandedIds is EqualUnmodifiableSetView) return _expandedIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_expandedIds);
  }

  @override
  String toString() {
    return 'AccountTreeState.loaded(roots: $roots, expandedIds: $expandedIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeLoadedImpl &&
            const DeepCollectionEquality().equals(other._roots, _roots) &&
            const DeepCollectionEquality().equals(
              other._expandedIds,
              _expandedIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_roots),
    const DeepCollectionEquality().hash(_expandedIds),
  );

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTreeLoadedImplCopyWith<_$AccountTreeLoadedImpl> get copyWith =>
      __$$AccountTreeLoadedImplCopyWithImpl<_$AccountTreeLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AccountTreeNode> roots,
      Set<String> expandedIds,
    )
    loaded,
    required TResult Function(String message) failure,
  }) {
    return loaded(roots, expandedIds);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult? Function(String message)? failure,
  }) {
    return loaded?.call(roots, expandedIds);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(roots, expandedIds);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AccountTreeInitial value) initial,
    required TResult Function(AccountTreeLoading value) loading,
    required TResult Function(AccountTreeLoaded value) loaded,
    required TResult Function(AccountTreeFailure value) failure,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeInitial value)? initial,
    TResult? Function(AccountTreeLoading value)? loading,
    TResult? Function(AccountTreeLoaded value)? loaded,
    TResult? Function(AccountTreeFailure value)? failure,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeInitial value)? initial,
    TResult Function(AccountTreeLoading value)? loading,
    TResult Function(AccountTreeLoaded value)? loaded,
    TResult Function(AccountTreeFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class AccountTreeLoaded implements AccountTreeState {
  const factory AccountTreeLoaded({
    required final List<AccountTreeNode> roots,
    required final Set<String> expandedIds,
  }) = _$AccountTreeLoadedImpl;

  /// Pre-built roots (sorted, depth-tagged).
  List<AccountTreeNode> get roots;

  /// Set of account ids whose children are visible. Lookups are
  /// O(1) via Set<String>.
  Set<String> get expandedIds;

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTreeLoadedImplCopyWith<_$AccountTreeLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AccountTreeFailureImplCopyWith<$Res> {
  factory _$$AccountTreeFailureImplCopyWith(
    _$AccountTreeFailureImpl value,
    $Res Function(_$AccountTreeFailureImpl) then,
  ) = __$$AccountTreeFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AccountTreeFailureImplCopyWithImpl<$Res>
    extends _$AccountTreeStateCopyWithImpl<$Res, _$AccountTreeFailureImpl>
    implements _$$AccountTreeFailureImplCopyWith<$Res> {
  __$$AccountTreeFailureImplCopyWithImpl(
    _$AccountTreeFailureImpl _value,
    $Res Function(_$AccountTreeFailureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$AccountTreeFailureImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AccountTreeFailureImpl implements AccountTreeFailure {
  const _$AccountTreeFailureImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'AccountTreeState.failure(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountTreeFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountTreeFailureImplCopyWith<_$AccountTreeFailureImpl> get copyWith =>
      __$$AccountTreeFailureImplCopyWithImpl<_$AccountTreeFailureImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AccountTreeNode> roots,
      Set<String> expandedIds,
    )
    loaded,
    required TResult Function(String message) failure,
  }) {
    return failure(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
    TResult? Function(String message)? failure,
  }) {
    return failure?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AccountTreeNode> roots, Set<String> expandedIds)?
    loaded,
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
    required TResult Function(AccountTreeInitial value) initial,
    required TResult Function(AccountTreeLoading value) loading,
    required TResult Function(AccountTreeLoaded value) loaded,
    required TResult Function(AccountTreeFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AccountTreeInitial value)? initial,
    TResult? Function(AccountTreeLoading value)? loading,
    TResult? Function(AccountTreeLoaded value)? loaded,
    TResult? Function(AccountTreeFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AccountTreeInitial value)? initial,
    TResult Function(AccountTreeLoading value)? loading,
    TResult Function(AccountTreeLoaded value)? loaded,
    TResult Function(AccountTreeFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class AccountTreeFailure implements AccountTreeState {
  const factory AccountTreeFailure(final String message) =
      _$AccountTreeFailureImpl;

  String get message;

  /// Create a copy of AccountTreeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountTreeFailureImplCopyWith<_$AccountTreeFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
