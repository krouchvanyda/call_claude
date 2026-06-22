// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_inbox_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NotificationInboxEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationInboxEventCopyWith<$Res> {
  factory $NotificationInboxEventCopyWith(
    NotificationInboxEvent value,
    $Res Function(NotificationInboxEvent) then,
  ) = _$NotificationInboxEventCopyWithImpl<$Res, NotificationInboxEvent>;
}

/// @nodoc
class _$NotificationInboxEventCopyWithImpl<
  $Res,
  $Val extends NotificationInboxEvent
>
    implements $NotificationInboxEventCopyWith<$Res> {
  _$NotificationInboxEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NotificationInboxStartedImplCopyWith<$Res> {
  factory _$$NotificationInboxStartedImplCopyWith(
    _$NotificationInboxStartedImpl value,
    $Res Function(_$NotificationInboxStartedImpl) then,
  ) = __$$NotificationInboxStartedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NotificationInboxStartedImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxEventCopyWithImpl<
          $Res,
          _$NotificationInboxStartedImpl
        >
    implements _$$NotificationInboxStartedImplCopyWith<$Res> {
  __$$NotificationInboxStartedImplCopyWithImpl(
    _$NotificationInboxStartedImpl _value,
    $Res Function(_$NotificationInboxStartedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NotificationInboxStartedImpl implements NotificationInboxStarted {
  const _$NotificationInboxStartedImpl();

  @override
  String toString() {
    return 'NotificationInboxEvent.started()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxStartedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) {
    return started();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) {
    return started?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
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
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) {
    return started(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) {
    return started?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) {
    if (started != null) {
      return started(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxStarted implements NotificationInboxEvent {
  const factory NotificationInboxStarted() = _$NotificationInboxStartedImpl;
}

/// @nodoc
abstract class _$$NotificationInboxMarkedReadImplCopyWith<$Res> {
  factory _$$NotificationInboxMarkedReadImplCopyWith(
    _$NotificationInboxMarkedReadImpl value,
    $Res Function(_$NotificationInboxMarkedReadImpl) then,
  ) = __$$NotificationInboxMarkedReadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$NotificationInboxMarkedReadImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxEventCopyWithImpl<
          $Res,
          _$NotificationInboxMarkedReadImpl
        >
    implements _$$NotificationInboxMarkedReadImplCopyWith<$Res> {
  __$$NotificationInboxMarkedReadImplCopyWithImpl(
    _$NotificationInboxMarkedReadImpl _value,
    $Res Function(_$NotificationInboxMarkedReadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null}) {
    return _then(
      _$NotificationInboxMarkedReadImpl(
        null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NotificationInboxMarkedReadImpl implements NotificationInboxMarkedRead {
  const _$NotificationInboxMarkedReadImpl(this.id);

  @override
  final String id;

  @override
  String toString() {
    return 'NotificationInboxEvent.markedRead(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxMarkedReadImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInboxMarkedReadImplCopyWith<_$NotificationInboxMarkedReadImpl>
  get copyWith =>
      __$$NotificationInboxMarkedReadImplCopyWithImpl<
        _$NotificationInboxMarkedReadImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) {
    return markedRead(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) {
    return markedRead?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
    required TResult orElse(),
  }) {
    if (markedRead != null) {
      return markedRead(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) {
    return markedRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) {
    return markedRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) {
    if (markedRead != null) {
      return markedRead(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxMarkedRead implements NotificationInboxEvent {
  const factory NotificationInboxMarkedRead(final String id) =
      _$NotificationInboxMarkedReadImpl;

  String get id;

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInboxMarkedReadImplCopyWith<_$NotificationInboxMarkedReadImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotificationInboxMarkedAllReadImplCopyWith<$Res> {
  factory _$$NotificationInboxMarkedAllReadImplCopyWith(
    _$NotificationInboxMarkedAllReadImpl value,
    $Res Function(_$NotificationInboxMarkedAllReadImpl) then,
  ) = __$$NotificationInboxMarkedAllReadImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NotificationInboxMarkedAllReadImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxEventCopyWithImpl<
          $Res,
          _$NotificationInboxMarkedAllReadImpl
        >
    implements _$$NotificationInboxMarkedAllReadImplCopyWith<$Res> {
  __$$NotificationInboxMarkedAllReadImplCopyWithImpl(
    _$NotificationInboxMarkedAllReadImpl _value,
    $Res Function(_$NotificationInboxMarkedAllReadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NotificationInboxMarkedAllReadImpl
    implements NotificationInboxMarkedAllRead {
  const _$NotificationInboxMarkedAllReadImpl();

  @override
  String toString() {
    return 'NotificationInboxEvent.markedAllRead()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxMarkedAllReadImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) {
    return markedAllRead();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) {
    return markedAllRead?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
    required TResult orElse(),
  }) {
    if (markedAllRead != null) {
      return markedAllRead();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) {
    return markedAllRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) {
    return markedAllRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) {
    if (markedAllRead != null) {
      return markedAllRead(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxMarkedAllRead
    implements NotificationInboxEvent {
  const factory NotificationInboxMarkedAllRead() =
      _$NotificationInboxMarkedAllReadImpl;
}

/// @nodoc
abstract class _$$NotificationInboxDismissedImplCopyWith<$Res> {
  factory _$$NotificationInboxDismissedImplCopyWith(
    _$NotificationInboxDismissedImpl value,
    $Res Function(_$NotificationInboxDismissedImpl) then,
  ) = __$$NotificationInboxDismissedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$NotificationInboxDismissedImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxEventCopyWithImpl<
          $Res,
          _$NotificationInboxDismissedImpl
        >
    implements _$$NotificationInboxDismissedImplCopyWith<$Res> {
  __$$NotificationInboxDismissedImplCopyWithImpl(
    _$NotificationInboxDismissedImpl _value,
    $Res Function(_$NotificationInboxDismissedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null}) {
    return _then(
      _$NotificationInboxDismissedImpl(
        null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NotificationInboxDismissedImpl implements NotificationInboxDismissed {
  const _$NotificationInboxDismissedImpl(this.id);

  @override
  final String id;

  @override
  String toString() {
    return 'NotificationInboxEvent.dismissed(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxDismissedImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInboxDismissedImplCopyWith<_$NotificationInboxDismissedImpl>
  get copyWith =>
      __$$NotificationInboxDismissedImplCopyWithImpl<
        _$NotificationInboxDismissedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) {
    return dismissed(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) {
    return dismissed?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
    required TResult orElse(),
  }) {
    if (dismissed != null) {
      return dismissed(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) {
    return dismissed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) {
    return dismissed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) {
    if (dismissed != null) {
      return dismissed(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxDismissed implements NotificationInboxEvent {
  const factory NotificationInboxDismissed(final String id) =
      _$NotificationInboxDismissedImpl;

  String get id;

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInboxDismissedImplCopyWith<_$NotificationInboxDismissedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotificationInboxUpdatedImplCopyWith<$Res> {
  factory _$$NotificationInboxUpdatedImplCopyWith(
    _$NotificationInboxUpdatedImpl value,
    $Res Function(_$NotificationInboxUpdatedImpl) then,
  ) = __$$NotificationInboxUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AppNotification> notifications});
}

/// @nodoc
class __$$NotificationInboxUpdatedImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxEventCopyWithImpl<
          $Res,
          _$NotificationInboxUpdatedImpl
        >
    implements _$$NotificationInboxUpdatedImplCopyWith<$Res> {
  __$$NotificationInboxUpdatedImplCopyWithImpl(
    _$NotificationInboxUpdatedImpl _value,
    $Res Function(_$NotificationInboxUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notifications = null}) {
    return _then(
      _$NotificationInboxUpdatedImpl(
        null == notifications
            ? _value._notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as List<AppNotification>,
      ),
    );
  }
}

/// @nodoc

class _$NotificationInboxUpdatedImpl implements NotificationInboxUpdated {
  const _$NotificationInboxUpdatedImpl(
    final List<AppNotification> notifications,
  ) : _notifications = notifications;

  final List<AppNotification> _notifications;
  @override
  List<AppNotification> get notifications {
    if (_notifications is EqualUnmodifiableListView) return _notifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifications);
  }

  @override
  String toString() {
    return 'NotificationInboxEvent.inboxUpdated(notifications: $notifications)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxUpdatedImpl &&
            const DeepCollectionEquality().equals(
              other._notifications,
              _notifications,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_notifications),
  );

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInboxUpdatedImplCopyWith<_$NotificationInboxUpdatedImpl>
  get copyWith =>
      __$$NotificationInboxUpdatedImplCopyWithImpl<
        _$NotificationInboxUpdatedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) {
    return inboxUpdated(notifications);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) {
    return inboxUpdated?.call(notifications);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
    required TResult orElse(),
  }) {
    if (inboxUpdated != null) {
      return inboxUpdated(notifications);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) {
    return inboxUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) {
    return inboxUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) {
    if (inboxUpdated != null) {
      return inboxUpdated(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxUpdated implements NotificationInboxEvent {
  const factory NotificationInboxUpdated(
    final List<AppNotification> notifications,
  ) = _$NotificationInboxUpdatedImpl;

  List<AppNotification> get notifications;

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInboxUpdatedImplCopyWith<_$NotificationInboxUpdatedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotificationInboxFailedImplCopyWith<$Res> {
  factory _$$NotificationInboxFailedImplCopyWith(
    _$NotificationInboxFailedImpl value,
    $Res Function(_$NotificationInboxFailedImpl) then,
  ) = __$$NotificationInboxFailedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NotificationInboxFailedImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxEventCopyWithImpl<
          $Res,
          _$NotificationInboxFailedImpl
        >
    implements _$$NotificationInboxFailedImplCopyWith<$Res> {
  __$$NotificationInboxFailedImplCopyWithImpl(
    _$NotificationInboxFailedImpl _value,
    $Res Function(_$NotificationInboxFailedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$NotificationInboxFailedImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NotificationInboxFailedImpl implements NotificationInboxFailed {
  const _$NotificationInboxFailedImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'NotificationInboxEvent.inboxFailed(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxFailedImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInboxFailedImplCopyWith<_$NotificationInboxFailedImpl>
  get copyWith =>
      __$$NotificationInboxFailedImplCopyWithImpl<
        _$NotificationInboxFailedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() started,
    required TResult Function(String id) markedRead,
    required TResult Function() markedAllRead,
    required TResult Function(String id) dismissed,
    required TResult Function(List<AppNotification> notifications) inboxUpdated,
    required TResult Function(String message) inboxFailed,
  }) {
    return inboxFailed(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? started,
    TResult? Function(String id)? markedRead,
    TResult? Function()? markedAllRead,
    TResult? Function(String id)? dismissed,
    TResult? Function(List<AppNotification> notifications)? inboxUpdated,
    TResult? Function(String message)? inboxFailed,
  }) {
    return inboxFailed?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? started,
    TResult Function(String id)? markedRead,
    TResult Function()? markedAllRead,
    TResult Function(String id)? dismissed,
    TResult Function(List<AppNotification> notifications)? inboxUpdated,
    TResult Function(String message)? inboxFailed,
    required TResult orElse(),
  }) {
    if (inboxFailed != null) {
      return inboxFailed(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxStarted value) started,
    required TResult Function(NotificationInboxMarkedRead value) markedRead,
    required TResult Function(NotificationInboxMarkedAllRead value)
    markedAllRead,
    required TResult Function(NotificationInboxDismissed value) dismissed,
    required TResult Function(NotificationInboxUpdated value) inboxUpdated,
    required TResult Function(NotificationInboxFailed value) inboxFailed,
  }) {
    return inboxFailed(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxStarted value)? started,
    TResult? Function(NotificationInboxMarkedRead value)? markedRead,
    TResult? Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult? Function(NotificationInboxDismissed value)? dismissed,
    TResult? Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult? Function(NotificationInboxFailed value)? inboxFailed,
  }) {
    return inboxFailed?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxStarted value)? started,
    TResult Function(NotificationInboxMarkedRead value)? markedRead,
    TResult Function(NotificationInboxMarkedAllRead value)? markedAllRead,
    TResult Function(NotificationInboxDismissed value)? dismissed,
    TResult Function(NotificationInboxUpdated value)? inboxUpdated,
    TResult Function(NotificationInboxFailed value)? inboxFailed,
    required TResult orElse(),
  }) {
    if (inboxFailed != null) {
      return inboxFailed(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxFailed implements NotificationInboxEvent {
  const factory NotificationInboxFailed(final String message) =
      _$NotificationInboxFailedImpl;

  String get message;

  /// Create a copy of NotificationInboxEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInboxFailedImplCopyWith<_$NotificationInboxFailedImpl>
  get copyWith => throw _privateConstructorUsedError;
}
