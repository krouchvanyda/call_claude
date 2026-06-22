// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SyncState {
  SyncStatus get status => throw _privateConstructorUsedError;
  int get pendingCount => throw _privateConstructorUsedError;

  /// When the most recent drain completed with at least one successful op.
  /// Null until the first such drain.
  DateTime? get lastSucceededAt => throw _privateConstructorUsedError;

  /// The last failure surfaced by the engine in the current "attention
  /// window" — populated by `opFailed` / `drainAborted` events and
  /// cleared at the start of a new drain or after a fully-successful one.
  Failure? get lastError => throw _privateConstructorUsedError;

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncStateCopyWith<SyncState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStateCopyWith<$Res> {
  factory $SyncStateCopyWith(SyncState value, $Res Function(SyncState) then) =
      _$SyncStateCopyWithImpl<$Res, SyncState>;
  @useResult
  $Res call({
    SyncStatus status,
    int pendingCount,
    DateTime? lastSucceededAt,
    Failure? lastError,
  });

  $FailureCopyWith<$Res>? get lastError;
}

/// @nodoc
class _$SyncStateCopyWithImpl<$Res, $Val extends SyncState>
    implements $SyncStateCopyWith<$Res> {
  _$SyncStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? pendingCount = null,
    Object? lastSucceededAt = freezed,
    Object? lastError = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as SyncStatus,
            pendingCount: null == pendingCount
                ? _value.pendingCount
                : pendingCount // ignore: cast_nullable_to_non_nullable
                      as int,
            lastSucceededAt: freezed == lastSucceededAt
                ? _value.lastSucceededAt
                : lastSucceededAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            lastError: freezed == lastError
                ? _value.lastError
                : lastError // ignore: cast_nullable_to_non_nullable
                      as Failure?,
          )
          as $Val,
    );
  }

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res>? get lastError {
    if (_value.lastError == null) {
      return null;
    }

    return $FailureCopyWith<$Res>(_value.lastError!, (value) {
      return _then(_value.copyWith(lastError: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SyncStateImplCopyWith<$Res>
    implements $SyncStateCopyWith<$Res> {
  factory _$$SyncStateImplCopyWith(
    _$SyncStateImpl value,
    $Res Function(_$SyncStateImpl) then,
  ) = __$$SyncStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    SyncStatus status,
    int pendingCount,
    DateTime? lastSucceededAt,
    Failure? lastError,
  });

  @override
  $FailureCopyWith<$Res>? get lastError;
}

/// @nodoc
class __$$SyncStateImplCopyWithImpl<$Res>
    extends _$SyncStateCopyWithImpl<$Res, _$SyncStateImpl>
    implements _$$SyncStateImplCopyWith<$Res> {
  __$$SyncStateImplCopyWithImpl(
    _$SyncStateImpl _value,
    $Res Function(_$SyncStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? pendingCount = null,
    Object? lastSucceededAt = freezed,
    Object? lastError = freezed,
  }) {
    return _then(
      _$SyncStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SyncStatus,
        pendingCount: null == pendingCount
            ? _value.pendingCount
            : pendingCount // ignore: cast_nullable_to_non_nullable
                  as int,
        lastSucceededAt: freezed == lastSucceededAt
            ? _value.lastSucceededAt
            : lastSucceededAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastError: freezed == lastError
            ? _value.lastError
            : lastError // ignore: cast_nullable_to_non_nullable
                  as Failure?,
      ),
    );
  }
}

/// @nodoc

class _$SyncStateImpl extends _SyncState {
  const _$SyncStateImpl({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSucceededAt,
    this.lastError,
  }) : super._();

  @override
  @JsonKey()
  final SyncStatus status;
  @override
  @JsonKey()
  final int pendingCount;

  /// When the most recent drain completed with at least one successful op.
  /// Null until the first such drain.
  @override
  final DateTime? lastSucceededAt;

  /// The last failure surfaced by the engine in the current "attention
  /// window" — populated by `opFailed` / `drainAborted` events and
  /// cleared at the start of a new drain or after a fully-successful one.
  @override
  final Failure? lastError;

  @override
  String toString() {
    return 'SyncState(status: $status, pendingCount: $pendingCount, lastSucceededAt: $lastSucceededAt, lastError: $lastError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pendingCount, pendingCount) ||
                other.pendingCount == pendingCount) &&
            (identical(other.lastSucceededAt, lastSucceededAt) ||
                other.lastSucceededAt == lastSucceededAt) &&
            (identical(other.lastError, lastError) ||
                other.lastError == lastError));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    status,
    pendingCount,
    lastSucceededAt,
    lastError,
  );

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncStateImplCopyWith<_$SyncStateImpl> get copyWith =>
      __$$SyncStateImplCopyWithImpl<_$SyncStateImpl>(this, _$identity);
}

abstract class _SyncState extends SyncState {
  const factory _SyncState({
    final SyncStatus status,
    final int pendingCount,
    final DateTime? lastSucceededAt,
    final Failure? lastError,
  }) = _$SyncStateImpl;
  const _SyncState._() : super._();

  @override
  SyncStatus get status;
  @override
  int get pendingCount;

  /// When the most recent drain completed with at least one successful op.
  /// Null until the first such drain.
  @override
  DateTime? get lastSucceededAt;

  /// The last failure surfaced by the engine in the current "attention
  /// window" — populated by `opFailed` / `drainAborted` events and
  /// cleared at the start of a new drain or after a fully-successful one.
  @override
  Failure? get lastError;

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncStateImplCopyWith<_$SyncStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
