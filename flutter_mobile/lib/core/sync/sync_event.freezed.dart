// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SyncEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() drainStarted,
    required TResult Function(String id) opSucceeded,
    required TResult Function(String id, Failure failure, bool willRetry)
    opFailed,
    required TResult Function(int processed, int failed) drainCompleted,
    required TResult Function(String reason) drainAborted,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? drainStarted,
    TResult? Function(String id)? opSucceeded,
    TResult? Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult? Function(int processed, int failed)? drainCompleted,
    TResult? Function(String reason)? drainAborted,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? drainStarted,
    TResult Function(String id)? opSucceeded,
    TResult Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult Function(int processed, int failed)? drainCompleted,
    TResult Function(String reason)? drainAborted,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncEventDrainStarted value) drainStarted,
    required TResult Function(SyncEventOpSucceeded value) opSucceeded,
    required TResult Function(SyncEventOpFailed value) opFailed,
    required TResult Function(SyncEventDrainCompleted value) drainCompleted,
    required TResult Function(SyncEventDrainAborted value) drainAborted,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncEventDrainStarted value)? drainStarted,
    TResult? Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult? Function(SyncEventOpFailed value)? opFailed,
    TResult? Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult? Function(SyncEventDrainAborted value)? drainAborted,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncEventDrainStarted value)? drainStarted,
    TResult Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult Function(SyncEventOpFailed value)? opFailed,
    TResult Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult Function(SyncEventDrainAborted value)? drainAborted,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncEventCopyWith<$Res> {
  factory $SyncEventCopyWith(SyncEvent value, $Res Function(SyncEvent) then) =
      _$SyncEventCopyWithImpl<$Res, SyncEvent>;
}

/// @nodoc
class _$SyncEventCopyWithImpl<$Res, $Val extends SyncEvent>
    implements $SyncEventCopyWith<$Res> {
  _$SyncEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SyncEventDrainStartedImplCopyWith<$Res> {
  factory _$$SyncEventDrainStartedImplCopyWith(
    _$SyncEventDrainStartedImpl value,
    $Res Function(_$SyncEventDrainStartedImpl) then,
  ) = __$$SyncEventDrainStartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncEventDrainStartedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncEventDrainStartedImpl>
    implements _$$SyncEventDrainStartedImplCopyWith<$Res> {
  __$$SyncEventDrainStartedImplCopyWithImpl(
    _$SyncEventDrainStartedImpl _value,
    $Res Function(_$SyncEventDrainStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncEventDrainStartedImpl implements SyncEventDrainStarted {
  const _$SyncEventDrainStartedImpl();

  @override
  String toString() {
    return 'SyncEvent.drainStarted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncEventDrainStartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() drainStarted,
    required TResult Function(String id) opSucceeded,
    required TResult Function(String id, Failure failure, bool willRetry)
    opFailed,
    required TResult Function(int processed, int failed) drainCompleted,
    required TResult Function(String reason) drainAborted,
  }) {
    return drainStarted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? drainStarted,
    TResult? Function(String id)? opSucceeded,
    TResult? Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult? Function(int processed, int failed)? drainCompleted,
    TResult? Function(String reason)? drainAborted,
  }) {
    return drainStarted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? drainStarted,
    TResult Function(String id)? opSucceeded,
    TResult Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult Function(int processed, int failed)? drainCompleted,
    TResult Function(String reason)? drainAborted,
    required TResult orElse(),
  }) {
    if (drainStarted != null) {
      return drainStarted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncEventDrainStarted value) drainStarted,
    required TResult Function(SyncEventOpSucceeded value) opSucceeded,
    required TResult Function(SyncEventOpFailed value) opFailed,
    required TResult Function(SyncEventDrainCompleted value) drainCompleted,
    required TResult Function(SyncEventDrainAborted value) drainAborted,
  }) {
    return drainStarted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncEventDrainStarted value)? drainStarted,
    TResult? Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult? Function(SyncEventOpFailed value)? opFailed,
    TResult? Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult? Function(SyncEventDrainAborted value)? drainAborted,
  }) {
    return drainStarted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncEventDrainStarted value)? drainStarted,
    TResult Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult Function(SyncEventOpFailed value)? opFailed,
    TResult Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult Function(SyncEventDrainAborted value)? drainAborted,
    required TResult orElse(),
  }) {
    if (drainStarted != null) {
      return drainStarted(this);
    }
    return orElse();
  }
}

abstract class SyncEventDrainStarted implements SyncEvent {
  const factory SyncEventDrainStarted() = _$SyncEventDrainStartedImpl;
}

/// @nodoc
abstract class _$$SyncEventOpSucceededImplCopyWith<$Res> {
  factory _$$SyncEventOpSucceededImplCopyWith(
    _$SyncEventOpSucceededImpl value,
    $Res Function(_$SyncEventOpSucceededImpl) then,
  ) = __$$SyncEventOpSucceededImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$SyncEventOpSucceededImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncEventOpSucceededImpl>
    implements _$$SyncEventOpSucceededImplCopyWith<$Res> {
  __$$SyncEventOpSucceededImplCopyWithImpl(
    _$SyncEventOpSucceededImpl _value,
    $Res Function(_$SyncEventOpSucceededImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null}) {
    return _then(
      _$SyncEventOpSucceededImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SyncEventOpSucceededImpl implements SyncEventOpSucceeded {
  const _$SyncEventOpSucceededImpl({required this.id});

  @override
  final String id;

  @override
  String toString() {
    return 'SyncEvent.opSucceeded(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncEventOpSucceededImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncEventOpSucceededImplCopyWith<_$SyncEventOpSucceededImpl>
  get copyWith =>
      __$$SyncEventOpSucceededImplCopyWithImpl<_$SyncEventOpSucceededImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() drainStarted,
    required TResult Function(String id) opSucceeded,
    required TResult Function(String id, Failure failure, bool willRetry)
    opFailed,
    required TResult Function(int processed, int failed) drainCompleted,
    required TResult Function(String reason) drainAborted,
  }) {
    return opSucceeded(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? drainStarted,
    TResult? Function(String id)? opSucceeded,
    TResult? Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult? Function(int processed, int failed)? drainCompleted,
    TResult? Function(String reason)? drainAborted,
  }) {
    return opSucceeded?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? drainStarted,
    TResult Function(String id)? opSucceeded,
    TResult Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult Function(int processed, int failed)? drainCompleted,
    TResult Function(String reason)? drainAborted,
    required TResult orElse(),
  }) {
    if (opSucceeded != null) {
      return opSucceeded(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncEventDrainStarted value) drainStarted,
    required TResult Function(SyncEventOpSucceeded value) opSucceeded,
    required TResult Function(SyncEventOpFailed value) opFailed,
    required TResult Function(SyncEventDrainCompleted value) drainCompleted,
    required TResult Function(SyncEventDrainAborted value) drainAborted,
  }) {
    return opSucceeded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncEventDrainStarted value)? drainStarted,
    TResult? Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult? Function(SyncEventOpFailed value)? opFailed,
    TResult? Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult? Function(SyncEventDrainAborted value)? drainAborted,
  }) {
    return opSucceeded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncEventDrainStarted value)? drainStarted,
    TResult Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult Function(SyncEventOpFailed value)? opFailed,
    TResult Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult Function(SyncEventDrainAborted value)? drainAborted,
    required TResult orElse(),
  }) {
    if (opSucceeded != null) {
      return opSucceeded(this);
    }
    return orElse();
  }
}

abstract class SyncEventOpSucceeded implements SyncEvent {
  const factory SyncEventOpSucceeded({required final String id}) =
      _$SyncEventOpSucceededImpl;

  String get id;

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncEventOpSucceededImplCopyWith<_$SyncEventOpSucceededImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncEventOpFailedImplCopyWith<$Res> {
  factory _$$SyncEventOpFailedImplCopyWith(
    _$SyncEventOpFailedImpl value,
    $Res Function(_$SyncEventOpFailedImpl) then,
  ) = __$$SyncEventOpFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, Failure failure, bool willRetry});

  $FailureCopyWith<$Res> get failure;
}

/// @nodoc
class __$$SyncEventOpFailedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncEventOpFailedImpl>
    implements _$$SyncEventOpFailedImplCopyWith<$Res> {
  __$$SyncEventOpFailedImplCopyWithImpl(
    _$SyncEventOpFailedImpl _value,
    $Res Function(_$SyncEventOpFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? failure = null,
    Object? willRetry = null,
  }) {
    return _then(
      _$SyncEventOpFailedImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        failure: null == failure
            ? _value.failure
            : failure // ignore: cast_nullable_to_non_nullable
                  as Failure,
        willRetry: null == willRetry
            ? _value.willRetry
            : willRetry // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FailureCopyWith<$Res> get failure {
    return $FailureCopyWith<$Res>(_value.failure, (value) {
      return _then(_value.copyWith(failure: value));
    });
  }
}

/// @nodoc

class _$SyncEventOpFailedImpl implements SyncEventOpFailed {
  const _$SyncEventOpFailedImpl({
    required this.id,
    required this.failure,
    required this.willRetry,
  });

  @override
  final String id;
  @override
  final Failure failure;
  @override
  final bool willRetry;

  @override
  String toString() {
    return 'SyncEvent.opFailed(id: $id, failure: $failure, willRetry: $willRetry)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncEventOpFailedImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.failure, failure) || other.failure == failure) &&
            (identical(other.willRetry, willRetry) ||
                other.willRetry == willRetry));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, failure, willRetry);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncEventOpFailedImplCopyWith<_$SyncEventOpFailedImpl> get copyWith =>
      __$$SyncEventOpFailedImplCopyWithImpl<_$SyncEventOpFailedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() drainStarted,
    required TResult Function(String id) opSucceeded,
    required TResult Function(String id, Failure failure, bool willRetry)
    opFailed,
    required TResult Function(int processed, int failed) drainCompleted,
    required TResult Function(String reason) drainAborted,
  }) {
    return opFailed(id, failure, willRetry);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? drainStarted,
    TResult? Function(String id)? opSucceeded,
    TResult? Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult? Function(int processed, int failed)? drainCompleted,
    TResult? Function(String reason)? drainAborted,
  }) {
    return opFailed?.call(id, failure, willRetry);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? drainStarted,
    TResult Function(String id)? opSucceeded,
    TResult Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult Function(int processed, int failed)? drainCompleted,
    TResult Function(String reason)? drainAborted,
    required TResult orElse(),
  }) {
    if (opFailed != null) {
      return opFailed(id, failure, willRetry);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncEventDrainStarted value) drainStarted,
    required TResult Function(SyncEventOpSucceeded value) opSucceeded,
    required TResult Function(SyncEventOpFailed value) opFailed,
    required TResult Function(SyncEventDrainCompleted value) drainCompleted,
    required TResult Function(SyncEventDrainAborted value) drainAborted,
  }) {
    return opFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncEventDrainStarted value)? drainStarted,
    TResult? Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult? Function(SyncEventOpFailed value)? opFailed,
    TResult? Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult? Function(SyncEventDrainAborted value)? drainAborted,
  }) {
    return opFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncEventDrainStarted value)? drainStarted,
    TResult Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult Function(SyncEventOpFailed value)? opFailed,
    TResult Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult Function(SyncEventDrainAborted value)? drainAborted,
    required TResult orElse(),
  }) {
    if (opFailed != null) {
      return opFailed(this);
    }
    return orElse();
  }
}

abstract class SyncEventOpFailed implements SyncEvent {
  const factory SyncEventOpFailed({
    required final String id,
    required final Failure failure,
    required final bool willRetry,
  }) = _$SyncEventOpFailedImpl;

  String get id;
  Failure get failure;
  bool get willRetry;

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncEventOpFailedImplCopyWith<_$SyncEventOpFailedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncEventDrainCompletedImplCopyWith<$Res> {
  factory _$$SyncEventDrainCompletedImplCopyWith(
    _$SyncEventDrainCompletedImpl value,
    $Res Function(_$SyncEventDrainCompletedImpl) then,
  ) = __$$SyncEventDrainCompletedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int processed, int failed});
}

/// @nodoc
class __$$SyncEventDrainCompletedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncEventDrainCompletedImpl>
    implements _$$SyncEventDrainCompletedImplCopyWith<$Res> {
  __$$SyncEventDrainCompletedImplCopyWithImpl(
    _$SyncEventDrainCompletedImpl _value,
    $Res Function(_$SyncEventDrainCompletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? processed = null, Object? failed = null}) {
    return _then(
      _$SyncEventDrainCompletedImpl(
        processed: null == processed
            ? _value.processed
            : processed // ignore: cast_nullable_to_non_nullable
                  as int,
        failed: null == failed
            ? _value.failed
            : failed // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SyncEventDrainCompletedImpl implements SyncEventDrainCompleted {
  const _$SyncEventDrainCompletedImpl({
    required this.processed,
    required this.failed,
  });

  @override
  final int processed;
  @override
  final int failed;

  @override
  String toString() {
    return 'SyncEvent.drainCompleted(processed: $processed, failed: $failed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncEventDrainCompletedImpl &&
            (identical(other.processed, processed) ||
                other.processed == processed) &&
            (identical(other.failed, failed) || other.failed == failed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, processed, failed);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncEventDrainCompletedImplCopyWith<_$SyncEventDrainCompletedImpl>
  get copyWith =>
      __$$SyncEventDrainCompletedImplCopyWithImpl<
        _$SyncEventDrainCompletedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() drainStarted,
    required TResult Function(String id) opSucceeded,
    required TResult Function(String id, Failure failure, bool willRetry)
    opFailed,
    required TResult Function(int processed, int failed) drainCompleted,
    required TResult Function(String reason) drainAborted,
  }) {
    return drainCompleted(processed, failed);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? drainStarted,
    TResult? Function(String id)? opSucceeded,
    TResult? Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult? Function(int processed, int failed)? drainCompleted,
    TResult? Function(String reason)? drainAborted,
  }) {
    return drainCompleted?.call(processed, failed);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? drainStarted,
    TResult Function(String id)? opSucceeded,
    TResult Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult Function(int processed, int failed)? drainCompleted,
    TResult Function(String reason)? drainAborted,
    required TResult orElse(),
  }) {
    if (drainCompleted != null) {
      return drainCompleted(processed, failed);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncEventDrainStarted value) drainStarted,
    required TResult Function(SyncEventOpSucceeded value) opSucceeded,
    required TResult Function(SyncEventOpFailed value) opFailed,
    required TResult Function(SyncEventDrainCompleted value) drainCompleted,
    required TResult Function(SyncEventDrainAborted value) drainAborted,
  }) {
    return drainCompleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncEventDrainStarted value)? drainStarted,
    TResult? Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult? Function(SyncEventOpFailed value)? opFailed,
    TResult? Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult? Function(SyncEventDrainAborted value)? drainAborted,
  }) {
    return drainCompleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncEventDrainStarted value)? drainStarted,
    TResult Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult Function(SyncEventOpFailed value)? opFailed,
    TResult Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult Function(SyncEventDrainAborted value)? drainAborted,
    required TResult orElse(),
  }) {
    if (drainCompleted != null) {
      return drainCompleted(this);
    }
    return orElse();
  }
}

abstract class SyncEventDrainCompleted implements SyncEvent {
  const factory SyncEventDrainCompleted({
    required final int processed,
    required final int failed,
  }) = _$SyncEventDrainCompletedImpl;

  int get processed;
  int get failed;

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncEventDrainCompletedImplCopyWith<_$SyncEventDrainCompletedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncEventDrainAbortedImplCopyWith<$Res> {
  factory _$$SyncEventDrainAbortedImplCopyWith(
    _$SyncEventDrainAbortedImpl value,
    $Res Function(_$SyncEventDrainAbortedImpl) then,
  ) = __$$SyncEventDrainAbortedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String reason});
}

/// @nodoc
class __$$SyncEventDrainAbortedImplCopyWithImpl<$Res>
    extends _$SyncEventCopyWithImpl<$Res, _$SyncEventDrainAbortedImpl>
    implements _$$SyncEventDrainAbortedImplCopyWith<$Res> {
  __$$SyncEventDrainAbortedImplCopyWithImpl(
    _$SyncEventDrainAbortedImpl _value,
    $Res Function(_$SyncEventDrainAbortedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reason = null}) {
    return _then(
      _$SyncEventDrainAbortedImpl(
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SyncEventDrainAbortedImpl implements SyncEventDrainAborted {
  const _$SyncEventDrainAbortedImpl({required this.reason});

  @override
  final String reason;

  @override
  String toString() {
    return 'SyncEvent.drainAborted(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncEventDrainAbortedImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncEventDrainAbortedImplCopyWith<_$SyncEventDrainAbortedImpl>
  get copyWith =>
      __$$SyncEventDrainAbortedImplCopyWithImpl<_$SyncEventDrainAbortedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() drainStarted,
    required TResult Function(String id) opSucceeded,
    required TResult Function(String id, Failure failure, bool willRetry)
    opFailed,
    required TResult Function(int processed, int failed) drainCompleted,
    required TResult Function(String reason) drainAborted,
  }) {
    return drainAborted(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? drainStarted,
    TResult? Function(String id)? opSucceeded,
    TResult? Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult? Function(int processed, int failed)? drainCompleted,
    TResult? Function(String reason)? drainAborted,
  }) {
    return drainAborted?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? drainStarted,
    TResult Function(String id)? opSucceeded,
    TResult Function(String id, Failure failure, bool willRetry)? opFailed,
    TResult Function(int processed, int failed)? drainCompleted,
    TResult Function(String reason)? drainAborted,
    required TResult orElse(),
  }) {
    if (drainAborted != null) {
      return drainAborted(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncEventDrainStarted value) drainStarted,
    required TResult Function(SyncEventOpSucceeded value) opSucceeded,
    required TResult Function(SyncEventOpFailed value) opFailed,
    required TResult Function(SyncEventDrainCompleted value) drainCompleted,
    required TResult Function(SyncEventDrainAborted value) drainAborted,
  }) {
    return drainAborted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncEventDrainStarted value)? drainStarted,
    TResult? Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult? Function(SyncEventOpFailed value)? opFailed,
    TResult? Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult? Function(SyncEventDrainAborted value)? drainAborted,
  }) {
    return drainAborted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncEventDrainStarted value)? drainStarted,
    TResult Function(SyncEventOpSucceeded value)? opSucceeded,
    TResult Function(SyncEventOpFailed value)? opFailed,
    TResult Function(SyncEventDrainCompleted value)? drainCompleted,
    TResult Function(SyncEventDrainAborted value)? drainAborted,
    required TResult orElse(),
  }) {
    if (drainAborted != null) {
      return drainAborted(this);
    }
    return orElse();
  }
}

abstract class SyncEventDrainAborted implements SyncEvent {
  const factory SyncEventDrainAborted({required final String reason}) =
      _$SyncEventDrainAbortedImpl;

  String get reason;

  /// Create a copy of SyncEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncEventDrainAbortedImplCopyWith<_$SyncEventDrainAbortedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
