// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_inbox_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NotificationInboxState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AppNotification> notifications,
      int unreadCount,
    )
    loaded,
    required TResult Function(String message) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AppNotification> notifications, int unreadCount)?
    loaded,
    TResult? Function(String message)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AppNotification> notifications, int unreadCount)?
    loaded,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxInitial value) initial,
    required TResult Function(NotificationInboxLoading value) loading,
    required TResult Function(NotificationInboxLoaded value) loaded,
    required TResult Function(NotificationInboxFailure value) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxInitial value)? initial,
    TResult? Function(NotificationInboxLoading value)? loading,
    TResult? Function(NotificationInboxLoaded value)? loaded,
    TResult? Function(NotificationInboxFailure value)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxInitial value)? initial,
    TResult Function(NotificationInboxLoading value)? loading,
    TResult Function(NotificationInboxLoaded value)? loaded,
    TResult Function(NotificationInboxFailure value)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationInboxStateCopyWith<$Res> {
  factory $NotificationInboxStateCopyWith(
    NotificationInboxState value,
    $Res Function(NotificationInboxState) then,
  ) = _$NotificationInboxStateCopyWithImpl<$Res, NotificationInboxState>;
}

/// @nodoc
class _$NotificationInboxStateCopyWithImpl<
  $Res,
  $Val extends NotificationInboxState
>
    implements $NotificationInboxStateCopyWith<$Res> {
  _$NotificationInboxStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NotificationInboxInitialImplCopyWith<$Res> {
  factory _$$NotificationInboxInitialImplCopyWith(
    _$NotificationInboxInitialImpl value,
    $Res Function(_$NotificationInboxInitialImpl) then,
  ) = __$$NotificationInboxInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NotificationInboxInitialImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxStateCopyWithImpl<
          $Res,
          _$NotificationInboxInitialImpl
        >
    implements _$$NotificationInboxInitialImplCopyWith<$Res> {
  __$$NotificationInboxInitialImplCopyWithImpl(
    _$NotificationInboxInitialImpl _value,
    $Res Function(_$NotificationInboxInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NotificationInboxInitialImpl implements NotificationInboxInitial {
  const _$NotificationInboxInitialImpl();

  @override
  String toString() {
    return 'NotificationInboxState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AppNotification> notifications,
      int unreadCount,
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
    TResult? Function(List<AppNotification> notifications, int unreadCount)?
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
    TResult Function(List<AppNotification> notifications, int unreadCount)?
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
    required TResult Function(NotificationInboxInitial value) initial,
    required TResult Function(NotificationInboxLoading value) loading,
    required TResult Function(NotificationInboxLoaded value) loaded,
    required TResult Function(NotificationInboxFailure value) failure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxInitial value)? initial,
    TResult? Function(NotificationInboxLoading value)? loading,
    TResult? Function(NotificationInboxLoaded value)? loaded,
    TResult? Function(NotificationInboxFailure value)? failure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxInitial value)? initial,
    TResult Function(NotificationInboxLoading value)? loading,
    TResult Function(NotificationInboxLoaded value)? loaded,
    TResult Function(NotificationInboxFailure value)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxInitial implements NotificationInboxState {
  const factory NotificationInboxInitial() = _$NotificationInboxInitialImpl;
}

/// @nodoc
abstract class _$$NotificationInboxLoadingImplCopyWith<$Res> {
  factory _$$NotificationInboxLoadingImplCopyWith(
    _$NotificationInboxLoadingImpl value,
    $Res Function(_$NotificationInboxLoadingImpl) then,
  ) = __$$NotificationInboxLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NotificationInboxLoadingImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxStateCopyWithImpl<
          $Res,
          _$NotificationInboxLoadingImpl
        >
    implements _$$NotificationInboxLoadingImplCopyWith<$Res> {
  __$$NotificationInboxLoadingImplCopyWithImpl(
    _$NotificationInboxLoadingImpl _value,
    $Res Function(_$NotificationInboxLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NotificationInboxLoadingImpl implements NotificationInboxLoading {
  const _$NotificationInboxLoadingImpl();

  @override
  String toString() {
    return 'NotificationInboxState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AppNotification> notifications,
      int unreadCount,
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
    TResult? Function(List<AppNotification> notifications, int unreadCount)?
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
    TResult Function(List<AppNotification> notifications, int unreadCount)?
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
    required TResult Function(NotificationInboxInitial value) initial,
    required TResult Function(NotificationInboxLoading value) loading,
    required TResult Function(NotificationInboxLoaded value) loaded,
    required TResult Function(NotificationInboxFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxInitial value)? initial,
    TResult? Function(NotificationInboxLoading value)? loading,
    TResult? Function(NotificationInboxLoaded value)? loaded,
    TResult? Function(NotificationInboxFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxInitial value)? initial,
    TResult Function(NotificationInboxLoading value)? loading,
    TResult Function(NotificationInboxLoaded value)? loaded,
    TResult Function(NotificationInboxFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxLoading implements NotificationInboxState {
  const factory NotificationInboxLoading() = _$NotificationInboxLoadingImpl;
}

/// @nodoc
abstract class _$$NotificationInboxLoadedImplCopyWith<$Res> {
  factory _$$NotificationInboxLoadedImplCopyWith(
    _$NotificationInboxLoadedImpl value,
    $Res Function(_$NotificationInboxLoadedImpl) then,
  ) = __$$NotificationInboxLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<AppNotification> notifications, int unreadCount});
}

/// @nodoc
class __$$NotificationInboxLoadedImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxStateCopyWithImpl<
          $Res,
          _$NotificationInboxLoadedImpl
        >
    implements _$$NotificationInboxLoadedImplCopyWith<$Res> {
  __$$NotificationInboxLoadedImplCopyWithImpl(
    _$NotificationInboxLoadedImpl _value,
    $Res Function(_$NotificationInboxLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? notifications = null, Object? unreadCount = null}) {
    return _then(
      _$NotificationInboxLoadedImpl(
        notifications: null == notifications
            ? _value._notifications
            : notifications // ignore: cast_nullable_to_non_nullable
                  as List<AppNotification>,
        unreadCount: null == unreadCount
            ? _value.unreadCount
            : unreadCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$NotificationInboxLoadedImpl implements NotificationInboxLoaded {
  const _$NotificationInboxLoadedImpl({
    required final List<AppNotification> notifications,
    required this.unreadCount,
  }) : _notifications = notifications;

  final List<AppNotification> _notifications;
  @override
  List<AppNotification> get notifications {
    if (_notifications is EqualUnmodifiableListView) return _notifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notifications);
  }

  @override
  final int unreadCount;

  @override
  String toString() {
    return 'NotificationInboxState.loaded(notifications: $notifications, unreadCount: $unreadCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxLoadedImpl &&
            const DeepCollectionEquality().equals(
              other._notifications,
              _notifications,
            ) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_notifications),
    unreadCount,
  );

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInboxLoadedImplCopyWith<_$NotificationInboxLoadedImpl>
  get copyWith =>
      __$$NotificationInboxLoadedImplCopyWithImpl<
        _$NotificationInboxLoadedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AppNotification> notifications,
      int unreadCount,
    )
    loaded,
    required TResult Function(String message) failure,
  }) {
    return loaded(notifications, unreadCount);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<AppNotification> notifications, int unreadCount)?
    loaded,
    TResult? Function(String message)? failure,
  }) {
    return loaded?.call(notifications, unreadCount);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<AppNotification> notifications, int unreadCount)?
    loaded,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(notifications, unreadCount);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NotificationInboxInitial value) initial,
    required TResult Function(NotificationInboxLoading value) loading,
    required TResult Function(NotificationInboxLoaded value) loaded,
    required TResult Function(NotificationInboxFailure value) failure,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxInitial value)? initial,
    TResult? Function(NotificationInboxLoading value)? loading,
    TResult? Function(NotificationInboxLoaded value)? loaded,
    TResult? Function(NotificationInboxFailure value)? failure,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxInitial value)? initial,
    TResult Function(NotificationInboxLoading value)? loading,
    TResult Function(NotificationInboxLoaded value)? loaded,
    TResult Function(NotificationInboxFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxLoaded implements NotificationInboxState {
  const factory NotificationInboxLoaded({
    required final List<AppNotification> notifications,
    required final int unreadCount,
  }) = _$NotificationInboxLoadedImpl;

  List<AppNotification> get notifications;
  int get unreadCount;

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInboxLoadedImplCopyWith<_$NotificationInboxLoadedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NotificationInboxFailureImplCopyWith<$Res> {
  factory _$$NotificationInboxFailureImplCopyWith(
    _$NotificationInboxFailureImpl value,
    $Res Function(_$NotificationInboxFailureImpl) then,
  ) = __$$NotificationInboxFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NotificationInboxFailureImplCopyWithImpl<$Res>
    extends
        _$NotificationInboxStateCopyWithImpl<
          $Res,
          _$NotificationInboxFailureImpl
        >
    implements _$$NotificationInboxFailureImplCopyWith<$Res> {
  __$$NotificationInboxFailureImplCopyWithImpl(
    _$NotificationInboxFailureImpl _value,
    $Res Function(_$NotificationInboxFailureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$NotificationInboxFailureImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NotificationInboxFailureImpl implements NotificationInboxFailure {
  const _$NotificationInboxFailureImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'NotificationInboxState.failure(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationInboxFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationInboxFailureImplCopyWith<_$NotificationInboxFailureImpl>
  get copyWith =>
      __$$NotificationInboxFailureImplCopyWithImpl<
        _$NotificationInboxFailureImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<AppNotification> notifications,
      int unreadCount,
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
    TResult? Function(List<AppNotification> notifications, int unreadCount)?
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
    TResult Function(List<AppNotification> notifications, int unreadCount)?
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
    required TResult Function(NotificationInboxInitial value) initial,
    required TResult Function(NotificationInboxLoading value) loading,
    required TResult Function(NotificationInboxLoaded value) loaded,
    required TResult Function(NotificationInboxFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NotificationInboxInitial value)? initial,
    TResult? Function(NotificationInboxLoading value)? loading,
    TResult? Function(NotificationInboxLoaded value)? loaded,
    TResult? Function(NotificationInboxFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NotificationInboxInitial value)? initial,
    TResult Function(NotificationInboxLoading value)? loading,
    TResult Function(NotificationInboxLoaded value)? loaded,
    TResult Function(NotificationInboxFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class NotificationInboxFailure implements NotificationInboxState {
  const factory NotificationInboxFailure(final String message) =
      _$NotificationInboxFailureImpl;

  String get message;

  /// Create a copy of NotificationInboxState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationInboxFailureImplCopyWith<_$NotificationInboxFailureImpl>
  get copyWith => throw _privateConstructorUsedError;
}
