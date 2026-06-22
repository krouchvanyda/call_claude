// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conflict.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Conflict<T> {
  T get local => throw _privateConstructorUsedError;
  T get server => throw _privateConstructorUsedError;

  /// Last local mutation time (the optimistic update). Optional because
  /// not every table carries an `updatedAt` column — without it the
  /// last-write-wins policy falls back to its configured tiebreaker.
  DateTime? get localUpdatedAt => throw _privateConstructorUsedError;
  DateTime? get serverUpdatedAt => throw _privateConstructorUsedError;

  /// Create a copy of Conflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConflictCopyWith<T, Conflict<T>> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConflictCopyWith<T, $Res> {
  factory $ConflictCopyWith(
    Conflict<T> value,
    $Res Function(Conflict<T>) then,
  ) = _$ConflictCopyWithImpl<T, $Res, Conflict<T>>;
  @useResult
  $Res call({
    T local,
    T server,
    DateTime? localUpdatedAt,
    DateTime? serverUpdatedAt,
  });
}

/// @nodoc
class _$ConflictCopyWithImpl<T, $Res, $Val extends Conflict<T>>
    implements $ConflictCopyWith<T, $Res> {
  _$ConflictCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? local = freezed,
    Object? server = freezed,
    Object? localUpdatedAt = freezed,
    Object? serverUpdatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            local: freezed == local
                ? _value.local
                : local // ignore: cast_nullable_to_non_nullable
                      as T,
            server: freezed == server
                ? _value.server
                : server // ignore: cast_nullable_to_non_nullable
                      as T,
            localUpdatedAt: freezed == localUpdatedAt
                ? _value.localUpdatedAt
                : localUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            serverUpdatedAt: freezed == serverUpdatedAt
                ? _value.serverUpdatedAt
                : serverUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConflictImplCopyWith<T, $Res>
    implements $ConflictCopyWith<T, $Res> {
  factory _$$ConflictImplCopyWith(
    _$ConflictImpl<T> value,
    $Res Function(_$ConflictImpl<T>) then,
  ) = __$$ConflictImplCopyWithImpl<T, $Res>;
  @override
  @useResult
  $Res call({
    T local,
    T server,
    DateTime? localUpdatedAt,
    DateTime? serverUpdatedAt,
  });
}

/// @nodoc
class __$$ConflictImplCopyWithImpl<T, $Res>
    extends _$ConflictCopyWithImpl<T, $Res, _$ConflictImpl<T>>
    implements _$$ConflictImplCopyWith<T, $Res> {
  __$$ConflictImplCopyWithImpl(
    _$ConflictImpl<T> _value,
    $Res Function(_$ConflictImpl<T>) _then,
  ) : super(_value, _then);

  /// Create a copy of Conflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? local = freezed,
    Object? server = freezed,
    Object? localUpdatedAt = freezed,
    Object? serverUpdatedAt = freezed,
  }) {
    return _then(
      _$ConflictImpl<T>(
        local: freezed == local
            ? _value.local
            : local // ignore: cast_nullable_to_non_nullable
                  as T,
        server: freezed == server
            ? _value.server
            : server // ignore: cast_nullable_to_non_nullable
                  as T,
        localUpdatedAt: freezed == localUpdatedAt
            ? _value.localUpdatedAt
            : localUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        serverUpdatedAt: freezed == serverUpdatedAt
            ? _value.serverUpdatedAt
            : serverUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$ConflictImpl<T> implements _Conflict<T> {
  const _$ConflictImpl({
    required this.local,
    required this.server,
    this.localUpdatedAt,
    this.serverUpdatedAt,
  });

  @override
  final T local;
  @override
  final T server;

  /// Last local mutation time (the optimistic update). Optional because
  /// not every table carries an `updatedAt` column — without it the
  /// last-write-wins policy falls back to its configured tiebreaker.
  @override
  final DateTime? localUpdatedAt;
  @override
  final DateTime? serverUpdatedAt;

  @override
  String toString() {
    return 'Conflict<$T>(local: $local, server: $server, localUpdatedAt: $localUpdatedAt, serverUpdatedAt: $serverUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConflictImpl<T> &&
            const DeepCollectionEquality().equals(other.local, local) &&
            const DeepCollectionEquality().equals(other.server, server) &&
            (identical(other.localUpdatedAt, localUpdatedAt) ||
                other.localUpdatedAt == localUpdatedAt) &&
            (identical(other.serverUpdatedAt, serverUpdatedAt) ||
                other.serverUpdatedAt == serverUpdatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(local),
    const DeepCollectionEquality().hash(server),
    localUpdatedAt,
    serverUpdatedAt,
  );

  /// Create a copy of Conflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConflictImplCopyWith<T, _$ConflictImpl<T>> get copyWith =>
      __$$ConflictImplCopyWithImpl<T, _$ConflictImpl<T>>(this, _$identity);
}

abstract class _Conflict<T> implements Conflict<T> {
  const factory _Conflict({
    required final T local,
    required final T server,
    final DateTime? localUpdatedAt,
    final DateTime? serverUpdatedAt,
  }) = _$ConflictImpl<T>;

  @override
  T get local;
  @override
  T get server;

  /// Last local mutation time (the optimistic update). Optional because
  /// not every table carries an `updatedAt` column — without it the
  /// last-write-wins policy falls back to its configured tiebreaker.
  @override
  DateTime? get localUpdatedAt;
  @override
  DateTime? get serverUpdatedAt;

  /// Create a copy of Conflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConflictImplCopyWith<T, _$ConflictImpl<T>> get copyWith =>
      throw _privateConstructorUsedError;
}
