// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_search_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$GlobalSearchEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String query) queryChanged,
    required TResult Function() cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String query)? queryChanged,
    TResult? Function()? cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String query)? queryChanged,
    TResult Function()? cleared,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchQueryChanged value) queryChanged,
    required TResult Function(GlobalSearchCleared value) cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchQueryChanged value)? queryChanged,
    TResult? Function(GlobalSearchCleared value)? cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchQueryChanged value)? queryChanged,
    TResult Function(GlobalSearchCleared value)? cleared,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GlobalSearchEventCopyWith<$Res> {
  factory $GlobalSearchEventCopyWith(
    GlobalSearchEvent value,
    $Res Function(GlobalSearchEvent) then,
  ) = _$GlobalSearchEventCopyWithImpl<$Res, GlobalSearchEvent>;
}

/// @nodoc
class _$GlobalSearchEventCopyWithImpl<$Res, $Val extends GlobalSearchEvent>
    implements $GlobalSearchEventCopyWith<$Res> {
  _$GlobalSearchEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GlobalSearchEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$GlobalSearchQueryChangedImplCopyWith<$Res> {
  factory _$$GlobalSearchQueryChangedImplCopyWith(
    _$GlobalSearchQueryChangedImpl value,
    $Res Function(_$GlobalSearchQueryChangedImpl) then,
  ) = __$$GlobalSearchQueryChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String query});
}

/// @nodoc
class __$$GlobalSearchQueryChangedImplCopyWithImpl<$Res>
    extends
        _$GlobalSearchEventCopyWithImpl<$Res, _$GlobalSearchQueryChangedImpl>
    implements _$$GlobalSearchQueryChangedImplCopyWith<$Res> {
  __$$GlobalSearchQueryChangedImplCopyWithImpl(
    _$GlobalSearchQueryChangedImpl _value,
    $Res Function(_$GlobalSearchQueryChangedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GlobalSearchEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? query = null}) {
    return _then(
      _$GlobalSearchQueryChangedImpl(
        null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$GlobalSearchQueryChangedImpl implements GlobalSearchQueryChanged {
  const _$GlobalSearchQueryChangedImpl(this.query);

  @override
  final String query;

  @override
  String toString() {
    return 'GlobalSearchEvent.queryChanged(query: $query)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalSearchQueryChangedImpl &&
            (identical(other.query, query) || other.query == query));
  }

  @override
  int get hashCode => Object.hash(runtimeType, query);

  /// Create a copy of GlobalSearchEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GlobalSearchQueryChangedImplCopyWith<_$GlobalSearchQueryChangedImpl>
  get copyWith =>
      __$$GlobalSearchQueryChangedImplCopyWithImpl<
        _$GlobalSearchQueryChangedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String query) queryChanged,
    required TResult Function() cleared,
  }) {
    return queryChanged(query);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String query)? queryChanged,
    TResult? Function()? cleared,
  }) {
    return queryChanged?.call(query);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String query)? queryChanged,
    TResult Function()? cleared,
    required TResult orElse(),
  }) {
    if (queryChanged != null) {
      return queryChanged(query);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchQueryChanged value) queryChanged,
    required TResult Function(GlobalSearchCleared value) cleared,
  }) {
    return queryChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchQueryChanged value)? queryChanged,
    TResult? Function(GlobalSearchCleared value)? cleared,
  }) {
    return queryChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchQueryChanged value)? queryChanged,
    TResult Function(GlobalSearchCleared value)? cleared,
    required TResult orElse(),
  }) {
    if (queryChanged != null) {
      return queryChanged(this);
    }
    return orElse();
  }
}

abstract class GlobalSearchQueryChanged implements GlobalSearchEvent {
  const factory GlobalSearchQueryChanged(final String query) =
      _$GlobalSearchQueryChangedImpl;

  String get query;

  /// Create a copy of GlobalSearchEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GlobalSearchQueryChangedImplCopyWith<_$GlobalSearchQueryChangedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$GlobalSearchClearedImplCopyWith<$Res> {
  factory _$$GlobalSearchClearedImplCopyWith(
    _$GlobalSearchClearedImpl value,
    $Res Function(_$GlobalSearchClearedImpl) then,
  ) = __$$GlobalSearchClearedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GlobalSearchClearedImplCopyWithImpl<$Res>
    extends _$GlobalSearchEventCopyWithImpl<$Res, _$GlobalSearchClearedImpl>
    implements _$$GlobalSearchClearedImplCopyWith<$Res> {
  __$$GlobalSearchClearedImplCopyWithImpl(
    _$GlobalSearchClearedImpl _value,
    $Res Function(_$GlobalSearchClearedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GlobalSearchEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$GlobalSearchClearedImpl implements GlobalSearchCleared {
  const _$GlobalSearchClearedImpl();

  @override
  String toString() {
    return 'GlobalSearchEvent.cleared()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GlobalSearchClearedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String query) queryChanged,
    required TResult Function() cleared,
  }) {
    return cleared();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String query)? queryChanged,
    TResult? Function()? cleared,
  }) {
    return cleared?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String query)? queryChanged,
    TResult Function()? cleared,
    required TResult orElse(),
  }) {
    if (cleared != null) {
      return cleared();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(GlobalSearchQueryChanged value) queryChanged,
    required TResult Function(GlobalSearchCleared value) cleared,
  }) {
    return cleared(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(GlobalSearchQueryChanged value)? queryChanged,
    TResult? Function(GlobalSearchCleared value)? cleared,
  }) {
    return cleared?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(GlobalSearchQueryChanged value)? queryChanged,
    TResult Function(GlobalSearchCleared value)? cleared,
    required TResult orElse(),
  }) {
    if (cleared != null) {
      return cleared(this);
    }
    return orElse();
  }
}

abstract class GlobalSearchCleared implements GlobalSearchEvent {
  const factory GlobalSearchCleared() = _$GlobalSearchClearedImpl;
}
