// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_bloc_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SyncBlocEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() triggerRequested,
    required TResult Function(SyncEvent event) engineEventReceived,
    required TResult Function(int count) pendingCountChanged,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? triggerRequested,
    TResult? Function(SyncEvent event)? engineEventReceived,
    TResult? Function(int count)? pendingCountChanged,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? triggerRequested,
    TResult Function(SyncEvent event)? engineEventReceived,
    TResult Function(int count)? pendingCountChanged,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncTriggerRequested value) triggerRequested,
    required TResult Function(SyncEngineEventReceived value)
    engineEventReceived,
    required TResult Function(SyncPendingCountChanged value)
    pendingCountChanged,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncTriggerRequested value)? triggerRequested,
    TResult? Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult? Function(SyncPendingCountChanged value)? pendingCountChanged,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncTriggerRequested value)? triggerRequested,
    TResult Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult Function(SyncPendingCountChanged value)? pendingCountChanged,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncBlocEventCopyWith<$Res> {
  factory $SyncBlocEventCopyWith(
    SyncBlocEvent value,
    $Res Function(SyncBlocEvent) then,
  ) = _$SyncBlocEventCopyWithImpl<$Res, SyncBlocEvent>;
}

/// @nodoc
class _$SyncBlocEventCopyWithImpl<$Res, $Val extends SyncBlocEvent>
    implements $SyncBlocEventCopyWith<$Res> {
  _$SyncBlocEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SyncTriggerRequestedImplCopyWith<$Res> {
  factory _$$SyncTriggerRequestedImplCopyWith(
    _$SyncTriggerRequestedImpl value,
    $Res Function(_$SyncTriggerRequestedImpl) then,
  ) = __$$SyncTriggerRequestedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SyncTriggerRequestedImplCopyWithImpl<$Res>
    extends _$SyncBlocEventCopyWithImpl<$Res, _$SyncTriggerRequestedImpl>
    implements _$$SyncTriggerRequestedImplCopyWith<$Res> {
  __$$SyncTriggerRequestedImplCopyWithImpl(
    _$SyncTriggerRequestedImpl _value,
    $Res Function(_$SyncTriggerRequestedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SyncTriggerRequestedImpl implements SyncTriggerRequested {
  const _$SyncTriggerRequestedImpl();

  @override
  String toString() {
    return 'SyncBlocEvent.triggerRequested()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncTriggerRequestedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() triggerRequested,
    required TResult Function(SyncEvent event) engineEventReceived,
    required TResult Function(int count) pendingCountChanged,
  }) {
    return triggerRequested();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? triggerRequested,
    TResult? Function(SyncEvent event)? engineEventReceived,
    TResult? Function(int count)? pendingCountChanged,
  }) {
    return triggerRequested?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? triggerRequested,
    TResult Function(SyncEvent event)? engineEventReceived,
    TResult Function(int count)? pendingCountChanged,
    required TResult orElse(),
  }) {
    if (triggerRequested != null) {
      return triggerRequested();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncTriggerRequested value) triggerRequested,
    required TResult Function(SyncEngineEventReceived value)
    engineEventReceived,
    required TResult Function(SyncPendingCountChanged value)
    pendingCountChanged,
  }) {
    return triggerRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncTriggerRequested value)? triggerRequested,
    TResult? Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult? Function(SyncPendingCountChanged value)? pendingCountChanged,
  }) {
    return triggerRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncTriggerRequested value)? triggerRequested,
    TResult Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult Function(SyncPendingCountChanged value)? pendingCountChanged,
    required TResult orElse(),
  }) {
    if (triggerRequested != null) {
      return triggerRequested(this);
    }
    return orElse();
  }
}

abstract class SyncTriggerRequested implements SyncBlocEvent {
  const factory SyncTriggerRequested() = _$SyncTriggerRequestedImpl;
}

/// @nodoc
abstract class _$$SyncEngineEventReceivedImplCopyWith<$Res> {
  factory _$$SyncEngineEventReceivedImplCopyWith(
    _$SyncEngineEventReceivedImpl value,
    $Res Function(_$SyncEngineEventReceivedImpl) then,
  ) = __$$SyncEngineEventReceivedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({SyncEvent event});

  $SyncEventCopyWith<$Res> get event;
}

/// @nodoc
class __$$SyncEngineEventReceivedImplCopyWithImpl<$Res>
    extends _$SyncBlocEventCopyWithImpl<$Res, _$SyncEngineEventReceivedImpl>
    implements _$$SyncEngineEventReceivedImplCopyWith<$Res> {
  __$$SyncEngineEventReceivedImplCopyWithImpl(
    _$SyncEngineEventReceivedImpl _value,
    $Res Function(_$SyncEngineEventReceivedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? event = null}) {
    return _then(
      _$SyncEngineEventReceivedImpl(
        null == event
            ? _value.event
            : event // ignore: cast_nullable_to_non_nullable
                  as SyncEvent,
      ),
    );
  }

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $SyncEventCopyWith<$Res> get event {
    return $SyncEventCopyWith<$Res>(_value.event, (value) {
      return _then(_value.copyWith(event: value));
    });
  }
}

/// @nodoc

class _$SyncEngineEventReceivedImpl implements SyncEngineEventReceived {
  const _$SyncEngineEventReceivedImpl(this.event);

  @override
  final SyncEvent event;

  @override
  String toString() {
    return 'SyncBlocEvent.engineEventReceived(event: $event)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncEngineEventReceivedImpl &&
            (identical(other.event, event) || other.event == event));
  }

  @override
  int get hashCode => Object.hash(runtimeType, event);

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncEngineEventReceivedImplCopyWith<_$SyncEngineEventReceivedImpl>
  get copyWith =>
      __$$SyncEngineEventReceivedImplCopyWithImpl<
        _$SyncEngineEventReceivedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() triggerRequested,
    required TResult Function(SyncEvent event) engineEventReceived,
    required TResult Function(int count) pendingCountChanged,
  }) {
    return engineEventReceived(event);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? triggerRequested,
    TResult? Function(SyncEvent event)? engineEventReceived,
    TResult? Function(int count)? pendingCountChanged,
  }) {
    return engineEventReceived?.call(event);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? triggerRequested,
    TResult Function(SyncEvent event)? engineEventReceived,
    TResult Function(int count)? pendingCountChanged,
    required TResult orElse(),
  }) {
    if (engineEventReceived != null) {
      return engineEventReceived(event);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncTriggerRequested value) triggerRequested,
    required TResult Function(SyncEngineEventReceived value)
    engineEventReceived,
    required TResult Function(SyncPendingCountChanged value)
    pendingCountChanged,
  }) {
    return engineEventReceived(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncTriggerRequested value)? triggerRequested,
    TResult? Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult? Function(SyncPendingCountChanged value)? pendingCountChanged,
  }) {
    return engineEventReceived?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncTriggerRequested value)? triggerRequested,
    TResult Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult Function(SyncPendingCountChanged value)? pendingCountChanged,
    required TResult orElse(),
  }) {
    if (engineEventReceived != null) {
      return engineEventReceived(this);
    }
    return orElse();
  }
}

abstract class SyncEngineEventReceived implements SyncBlocEvent {
  const factory SyncEngineEventReceived(final SyncEvent event) =
      _$SyncEngineEventReceivedImpl;

  SyncEvent get event;

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncEngineEventReceivedImplCopyWith<_$SyncEngineEventReceivedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SyncPendingCountChangedImplCopyWith<$Res> {
  factory _$$SyncPendingCountChangedImplCopyWith(
    _$SyncPendingCountChangedImpl value,
    $Res Function(_$SyncPendingCountChangedImpl) then,
  ) = __$$SyncPendingCountChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int count});
}

/// @nodoc
class __$$SyncPendingCountChangedImplCopyWithImpl<$Res>
    extends _$SyncBlocEventCopyWithImpl<$Res, _$SyncPendingCountChangedImpl>
    implements _$$SyncPendingCountChangedImplCopyWith<$Res> {
  __$$SyncPendingCountChangedImplCopyWithImpl(
    _$SyncPendingCountChangedImpl _value,
    $Res Function(_$SyncPendingCountChangedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? count = null}) {
    return _then(
      _$SyncPendingCountChangedImpl(
        null == count
            ? _value.count
            : count // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$SyncPendingCountChangedImpl implements SyncPendingCountChanged {
  const _$SyncPendingCountChangedImpl(this.count);

  @override
  final int count;

  @override
  String toString() {
    return 'SyncBlocEvent.pendingCountChanged(count: $count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SyncPendingCountChangedImpl &&
            (identical(other.count, count) || other.count == count));
  }

  @override
  int get hashCode => Object.hash(runtimeType, count);

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SyncPendingCountChangedImplCopyWith<_$SyncPendingCountChangedImpl>
  get copyWith =>
      __$$SyncPendingCountChangedImplCopyWithImpl<
        _$SyncPendingCountChangedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() triggerRequested,
    required TResult Function(SyncEvent event) engineEventReceived,
    required TResult Function(int count) pendingCountChanged,
  }) {
    return pendingCountChanged(count);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? triggerRequested,
    TResult? Function(SyncEvent event)? engineEventReceived,
    TResult? Function(int count)? pendingCountChanged,
  }) {
    return pendingCountChanged?.call(count);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? triggerRequested,
    TResult Function(SyncEvent event)? engineEventReceived,
    TResult Function(int count)? pendingCountChanged,
    required TResult orElse(),
  }) {
    if (pendingCountChanged != null) {
      return pendingCountChanged(count);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SyncTriggerRequested value) triggerRequested,
    required TResult Function(SyncEngineEventReceived value)
    engineEventReceived,
    required TResult Function(SyncPendingCountChanged value)
    pendingCountChanged,
  }) {
    return pendingCountChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SyncTriggerRequested value)? triggerRequested,
    TResult? Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult? Function(SyncPendingCountChanged value)? pendingCountChanged,
  }) {
    return pendingCountChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SyncTriggerRequested value)? triggerRequested,
    TResult Function(SyncEngineEventReceived value)? engineEventReceived,
    TResult Function(SyncPendingCountChanged value)? pendingCountChanged,
    required TResult orElse(),
  }) {
    if (pendingCountChanged != null) {
      return pendingCountChanged(this);
    }
    return orElse();
  }
}

abstract class SyncPendingCountChanged implements SyncBlocEvent {
  const factory SyncPendingCountChanged(final int count) =
      _$SyncPendingCountChangedImpl;

  int get count;

  /// Create a copy of SyncBlocEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SyncPendingCountChangedImplCopyWith<_$SyncPendingCountChangedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
