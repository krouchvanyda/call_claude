// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GlobalSearchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String query) loading,
    required TResult Function(String query, List<SearchResultGroup> groups)
    success,
    required TResult Function(String query, String message) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String query)? loading,
    TResult? Function(String query, List<SearchResultGroup> groups)? success,
    TResult? Function(String query, String message)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String query)? loading,
    TResult Function(String query, List<SearchResultGroup> groups)? success,
    TResult Function(String query, String message)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchIdle value) idle,
    required TResult Function(GlobalSearchLoading value) loading,
    required TResult Function(GlobalSearchSuccess value) success,
    required TResult Function(GlobalSearchFailure value) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchIdle value)? idle,
    TResult? Function(GlobalSearchLoading value)? loading,
    TResult? Function(GlobalSearchSuccess value)? success,
    TResult? Function(GlobalSearchFailure value)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchIdle value)? idle,
    TResult Function(GlobalSearchLoading value)? loading,
    TResult Function(GlobalSearchSuccess value)? success,
    TResult Function(GlobalSearchFailure value)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GlobalSearchStateCopyWith<$Res> {
  factory $GlobalSearchStateCopyWith(
    GlobalSearchState value,
    $Res Function(GlobalSearchState) then,
  ) = _$GlobalSearchStateCopyWithImpl<$Res, GlobalSearchState>;
}

/// @nodoc
class _$GlobalSearchStateCopyWithImpl<$Res, $Val extends GlobalSearchState>
    implements $GlobalSearchStateCopyWith<$Res> {
  _$GlobalSearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$GlobalSearchIdleImplCopyWith<$Res> {
  factory _$$GlobalSearchIdleImplCopyWith(
    _$GlobalSearchIdleImpl value,
    $Res Function(_$GlobalSearchIdleImpl) then,
  ) = __$$GlobalSearchIdleImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GlobalSearchIdleImplCopyWithImpl<$Res>
    extends _$GlobalSearchStateCopyWithImpl<$Res, _$GlobalSearchIdleImpl>
    implements _$$GlobalSearchIdleImplCopyWith<$Res> {
  __$$GlobalSearchIdleImplCopyWithImpl(
    _$GlobalSearchIdleImpl _value,
    $Res Function(_$GlobalSearchIdleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$GlobalSearchIdleImpl implements GlobalSearchIdle {
  const _$GlobalSearchIdleImpl();

  @override
  String toString() {
    return 'GlobalSearchState.idle()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$GlobalSearchIdleImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String query) loading,
    required TResult Function(String query, List<SearchResultGroup> groups)
    success,
    required TResult Function(String query, String message) failure,
  }) {
    return idle();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String query)? loading,
    TResult? Function(String query, List<SearchResultGroup> groups)? success,
    TResult? Function(String query, String message)? failure,
  }) {
    return idle?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String query)? loading,
    TResult Function(String query, List<SearchResultGroup> groups)? success,
    TResult Function(String query, String message)? failure,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchIdle value) idle,
    required TResult Function(GlobalSearchLoading value) loading,
    required TResult Function(GlobalSearchSuccess value) success,
    required TResult Function(GlobalSearchFailure value) failure,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchIdle value)? idle,
    TResult? Function(GlobalSearchLoading value)? loading,
    TResult? Function(GlobalSearchSuccess value)? success,
    TResult? Function(GlobalSearchFailure value)? failure,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchIdle value)? idle,
    TResult Function(GlobalSearchLoading value)? loading,
    TResult Function(GlobalSearchSuccess value)? success,
    TResult Function(GlobalSearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class GlobalSearchIdle implements GlobalSearchState {
  const factory GlobalSearchIdle() = _$GlobalSearchIdleImpl;
}

/// @nodoc
abstract class _$$GlobalSearchLoadingImplCopyWith<$Res> {
  factory _$$GlobalSearchLoadingImplCopyWith(
    _$GlobalSearchLoadingImpl value,
    $Res Function(_$GlobalSearchLoadingImpl) then,
  ) = __$$GlobalSearchLoadingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$$GlobalSearchLoadingImplCopyWithImpl<$Res>
    extends _$GlobalSearchStateCopyWithImpl<$Res, _$GlobalSearchLoadingImpl>
    implements _$$GlobalSearchLoadingImplCopyWith<$Res> {
  __$$GlobalSearchLoadingImplCopyWithImpl(
    _$GlobalSearchLoadingImpl _value,
    $Res Function(_$GlobalSearchLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null}) {
    return _then(
      _$GlobalSearchLoadingImpl(
        null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GlobalSearchLoadingImpl implements GlobalSearchLoading {
  const _$GlobalSearchLoadingImpl(this.query);

  @override
  final String query;

  @override
  String toString() {
    return 'GlobalSearchState.loading(query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalSearchLoadingImpl &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalSearchLoadingImplCopyWith<_$GlobalSearchLoadingImpl> get copyWith =>
      __$$GlobalSearchLoadingImplCopyWithImpl<_$GlobalSearchLoadingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String query) loading,
    required TResult Function(String query, List<SearchResultGroup> groups)
    success,
    required TResult Function(String query, String message) failure,
  }) {
    return loading(query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String query)? loading,
    TResult? Function(String query, List<SearchResultGroup> groups)? success,
    TResult? Function(String query, String message)? failure,
  }) {
    return loading?.call(query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String query)? loading,
    TResult Function(String query, List<SearchResultGroup> groups)? success,
    TResult Function(String query, String message)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchIdle value) idle,
    required TResult Function(GlobalSearchLoading value) loading,
    required TResult Function(GlobalSearchSuccess value) success,
    required TResult Function(GlobalSearchFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchIdle value)? idle,
    TResult? Function(GlobalSearchLoading value)? loading,
    TResult? Function(GlobalSearchSuccess value)? success,
    TResult? Function(GlobalSearchFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchIdle value)? idle,
    TResult Function(GlobalSearchLoading value)? loading,
    TResult Function(GlobalSearchSuccess value)? success,
    TResult Function(GlobalSearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class GlobalSearchLoading implements GlobalSearchState {
  const factory GlobalSearchLoading(final String query) =
      _$GlobalSearchLoadingImpl;

  String get query;

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalSearchLoadingImplCopyWith<_$GlobalSearchLoadingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GlobalSearchSuccessImplCopyWith<$Res> {
  factory _$$GlobalSearchSuccessImplCopyWith(
    _$GlobalSearchSuccessImpl value,
    $Res Function(_$GlobalSearchSuccessImpl) then,
  ) = __$$GlobalSearchSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query, List<SearchResultGroup> groups});
}

/// @nodoc
class __$$GlobalSearchSuccessImplCopyWithImpl<$Res>
    extends _$GlobalSearchStateCopyWithImpl<$Res, _$GlobalSearchSuccessImpl>
    implements _$$GlobalSearchSuccessImplCopyWith<$Res> {
  __$$GlobalSearchSuccessImplCopyWithImpl(
    _$GlobalSearchSuccessImpl _value,
    $Res Function(_$GlobalSearchSuccessImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? groups = null}) {
    return _then(
      _$GlobalSearchSuccessImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        groups: null == groups
            ? _value._groups
            : groups // ignore: cast_nullable_to_non_nullable
                  as List<SearchResultGroup>,
      ),
    );
  }
}

/// @nodoc

class _$GlobalSearchSuccessImpl implements GlobalSearchSuccess {
  const _$GlobalSearchSuccessImpl({
    required this.query,
    required final List<SearchResultGroup> groups,
  }) : _groups = groups;

  @override
  final String query;
  final List<SearchResultGroup> _groups;
  @override
  List<SearchResultGroup> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  @override
  String toString() {
    return 'GlobalSearchState.success(query: $query, groups: $groups)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalSearchSuccessImpl &&
            (identical(other.query, query) || other.query == query) &&
            const DeepCollectionEquality().equals(other._groups, _groups));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    query,
    const DeepCollectionEquality().hash(_groups),
  );

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalSearchSuccessImplCopyWith<_$GlobalSearchSuccessImpl> get copyWith =>
      __$$GlobalSearchSuccessImplCopyWithImpl<_$GlobalSearchSuccessImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String query) loading,
    required TResult Function(String query, List<SearchResultGroup> groups)
    success,
    required TResult Function(String query, String message) failure,
  }) {
    return success(query, groups);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String query)? loading,
    TResult? Function(String query, List<SearchResultGroup> groups)? success,
    TResult? Function(String query, String message)? failure,
  }) {
    return success?.call(query, groups);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String query)? loading,
    TResult Function(String query, List<SearchResultGroup> groups)? success,
    TResult Function(String query, String message)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(query, groups);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchIdle value) idle,
    required TResult Function(GlobalSearchLoading value) loading,
    required TResult Function(GlobalSearchSuccess value) success,
    required TResult Function(GlobalSearchFailure value) failure,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchIdle value)? idle,
    TResult? Function(GlobalSearchLoading value)? loading,
    TResult? Function(GlobalSearchSuccess value)? success,
    TResult? Function(GlobalSearchFailure value)? failure,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchIdle value)? idle,
    TResult Function(GlobalSearchLoading value)? loading,
    TResult Function(GlobalSearchSuccess value)? success,
    TResult Function(GlobalSearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class GlobalSearchSuccess implements GlobalSearchState {
  const factory GlobalSearchSuccess({
    required final String query,
    required final List<SearchResultGroup> groups,
  }) = _$GlobalSearchSuccessImpl;

  String get query;
  List<SearchResultGroup> get groups;

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalSearchSuccessImplCopyWith<_$GlobalSearchSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GlobalSearchFailureImplCopyWith<$Res> {
  factory _$$GlobalSearchFailureImplCopyWith(
    _$GlobalSearchFailureImpl value,
    $Res Function(_$GlobalSearchFailureImpl) then,
  ) = __$$GlobalSearchFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query, String message});
}

/// @nodoc
class __$$GlobalSearchFailureImplCopyWithImpl<$Res>
    extends _$GlobalSearchStateCopyWithImpl<$Res, _$GlobalSearchFailureImpl>
    implements _$$GlobalSearchFailureImplCopyWith<$Res> {
  __$$GlobalSearchFailureImplCopyWithImpl(
    _$GlobalSearchFailureImpl _value,
    $Res Function(_$GlobalSearchFailureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null, Object? message = null}) {
    return _then(
      _$GlobalSearchFailureImpl(
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GlobalSearchFailureImpl implements GlobalSearchFailure {
  const _$GlobalSearchFailureImpl({required this.query, required this.message});

  @override
  final String query;
  @override
  final String message;

  @override
  String toString() {
    return 'GlobalSearchState.failure(query: $query, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalSearchFailureImpl &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query, message);

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalSearchFailureImplCopyWith<_$GlobalSearchFailureImpl> get copyWith =>
      __$$GlobalSearchFailureImplCopyWithImpl<_$GlobalSearchFailureImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String query) loading,
    required TResult Function(String query, List<SearchResultGroup> groups)
    success,
    required TResult Function(String query, String message) failure,
  }) {
    return failure(query, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String query)? loading,
    TResult? Function(String query, List<SearchResultGroup> groups)? success,
    TResult? Function(String query, String message)? failure,
  }) {
    return failure?.call(query, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String query)? loading,
    TResult Function(String query, List<SearchResultGroup> groups)? success,
    TResult Function(String query, String message)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(query, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchIdle value) idle,
    required TResult Function(GlobalSearchLoading value) loading,
    required TResult Function(GlobalSearchSuccess value) success,
    required TResult Function(GlobalSearchFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchIdle value)? idle,
    TResult? Function(GlobalSearchLoading value)? loading,
    TResult? Function(GlobalSearchSuccess value)? success,
    TResult? Function(GlobalSearchFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchIdle value)? idle,
    TResult Function(GlobalSearchLoading value)? loading,
    TResult Function(GlobalSearchSuccess value)? success,
    TResult Function(GlobalSearchFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class GlobalSearchFailure implements GlobalSearchState {
  const factory GlobalSearchFailure({
    required final String query,
    required final String message,
  }) = _$GlobalSearchFailureImpl;

  String get query;
  String get message;

  /// Create a copy of GlobalSearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalSearchFailureImplCopyWith<_$GlobalSearchFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
