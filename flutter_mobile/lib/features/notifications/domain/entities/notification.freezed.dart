// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppNotification {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;

  /// Discriminator like `'invoice'`, `'leave-request'`, `'system'` —
  /// drives icon / colour selection in the inbox UI.
  String get category => throw _privateConstructorUsedError;

  /// Optional `go_router` named route for the deep-link target.
  /// `null` means the notification is informational only.
  String? get routeName => throw _privateConstructorUsedError;

  /// Path parameters for the deep-link target. Empty when the route
  /// has no params (or [routeName] is null).
  Map<String, String> get pathParameters => throw _privateConstructorUsedError;

  /// When the notification was first emitted (server / push timestamp).
  DateTime get receivedAt => throw _privateConstructorUsedError;

  /// `null` when unread. Set the first time the user opens the row.
  DateTime? get readAt => throw _privateConstructorUsedError;

  /// Tombstone — true when the user swiped to dismiss. Kept (not
  /// deleted) so a future "show dismissed" toggle can restore.
  bool get dismissed => throw _privateConstructorUsedError;

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppNotificationCopyWith<AppNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppNotificationCopyWith<$Res> {
  factory $AppNotificationCopyWith(
    AppNotification value,
    $Res Function(AppNotification) then,
  ) = _$AppNotificationCopyWithImpl<$Res, AppNotification>;
  @useResult
  $Res call({
    String id,
    String title,
    String body,
    String category,
    String? routeName,
    Map<String, String> pathParameters,
    DateTime receivedAt,
    DateTime? readAt,
    bool dismissed,
  });
}

/// @nodoc
class _$AppNotificationCopyWithImpl<$Res, $Val extends AppNotification>
    implements $AppNotificationCopyWith<$Res> {
  _$AppNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? category = null,
    Object? routeName = freezed,
    Object? pathParameters = null,
    Object? receivedAt = null,
    Object? readAt = freezed,
    Object? dismissed = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            routeName: freezed == routeName
                ? _value.routeName
                : routeName // ignore: cast_nullable_to_non_nullable
                      as String?,
            pathParameters: null == pathParameters
                ? _value.pathParameters
                : pathParameters // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            receivedAt: null == receivedAt
                ? _value.receivedAt
                : receivedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            readAt: freezed == readAt
                ? _value.readAt
                : readAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            dismissed: null == dismissed
                ? _value.dismissed
                : dismissed // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppNotificationImplCopyWith<$Res>
    implements $AppNotificationCopyWith<$Res> {
  factory _$$AppNotificationImplCopyWith(
    _$AppNotificationImpl value,
    $Res Function(_$AppNotificationImpl) then,
  ) = __$$AppNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String body,
    String category,
    String? routeName,
    Map<String, String> pathParameters,
    DateTime receivedAt,
    DateTime? readAt,
    bool dismissed,
  });
}

/// @nodoc
class __$$AppNotificationImplCopyWithImpl<$Res>
    extends _$AppNotificationCopyWithImpl<$Res, _$AppNotificationImpl>
    implements _$$AppNotificationImplCopyWith<$Res> {
  __$$AppNotificationImplCopyWithImpl(
    _$AppNotificationImpl _value,
    $Res Function(_$AppNotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? category = null,
    Object? routeName = freezed,
    Object? pathParameters = null,
    Object? receivedAt = null,
    Object? readAt = freezed,
    Object? dismissed = null,
  }) {
    return _then(
      _$AppNotificationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        routeName: freezed == routeName
            ? _value.routeName
            : routeName // ignore: cast_nullable_to_non_nullable
                  as String?,
        pathParameters: null == pathParameters
            ? _value._pathParameters
            : pathParameters // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        receivedAt: null == receivedAt
            ? _value.receivedAt
            : receivedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        readAt: freezed == readAt
            ? _value.readAt
            : readAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        dismissed: null == dismissed
            ? _value.dismissed
            : dismissed // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$AppNotificationImpl extends _AppNotification {
  const _$AppNotificationImpl({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.routeName,
    final Map<String, String> pathParameters = const <String, String>{},
    required this.receivedAt,
    this.readAt,
    this.dismissed = false,
  }) : _pathParameters = pathParameters,
       super._();

  @override
  final String id;
  @override
  final String title;
  @override
  final String body;

  /// Discriminator like `'invoice'`, `'leave-request'`, `'system'` —
  /// drives icon / colour selection in the inbox UI.
  @override
  final String category;

  /// Optional `go_router` named route for the deep-link target.
  /// `null` means the notification is informational only.
  @override
  final String? routeName;

  /// Path parameters for the deep-link target. Empty when the route
  /// has no params (or [routeName] is null).
  final Map<String, String> _pathParameters;

  /// Path parameters for the deep-link target. Empty when the route
  /// has no params (or [routeName] is null).
  @override
  @JsonKey()
  Map<String, String> get pathParameters {
    if (_pathParameters is EqualUnmodifiableMapView) return _pathParameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_pathParameters);
  }

  /// When the notification was first emitted (server / push timestamp).
  @override
  final DateTime receivedAt;

  /// `null` when unread. Set the first time the user opens the row.
  @override
  final DateTime? readAt;

  /// Tombstone — true when the user swiped to dismiss. Kept (not
  /// deleted) so a future "show dismissed" toggle can restore.
  @override
  @JsonKey()
  final bool dismissed;

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, body: $body, category: $category, routeName: $routeName, pathParameters: $pathParameters, receivedAt: $receivedAt, readAt: $readAt, dismissed: $dismissed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppNotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.routeName, routeName) ||
                other.routeName == routeName) &&
            const DeepCollectionEquality().equals(
              other._pathParameters,
              _pathParameters,
            ) &&
            (identical(other.receivedAt, receivedAt) ||
                other.receivedAt == receivedAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.dismissed, dismissed) ||
                other.dismissed == dismissed));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    body,
    category,
    routeName,
    const DeepCollectionEquality().hash(_pathParameters),
    receivedAt,
    readAt,
    dismissed,
  );

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppNotificationImplCopyWith<_$AppNotificationImpl> get copyWith =>
      __$$AppNotificationImplCopyWithImpl<_$AppNotificationImpl>(
        this,
        _$identity,
      );
}

abstract class _AppNotification extends AppNotification {
  const factory _AppNotification({
    required final String id,
    required final String title,
    required final String body,
    required final String category,
    final String? routeName,
    final Map<String, String> pathParameters,
    required final DateTime receivedAt,
    final DateTime? readAt,
    final bool dismissed,
  }) = _$AppNotificationImpl;
  const _AppNotification._() : super._();

  @override
  String get id;
  @override
  String get title;
  @override
  String get body;

  /// Discriminator like `'invoice'`, `'leave-request'`, `'system'` —
  /// drives icon / colour selection in the inbox UI.
  @override
  String get category;

  /// Optional `go_router` named route for the deep-link target.
  /// `null` means the notification is informational only.
  @override
  String? get routeName;

  /// Path parameters for the deep-link target. Empty when the route
  /// has no params (or [routeName] is null).
  @override
  Map<String, String> get pathParameters;

  /// When the notification was first emitted (server / push timestamp).
  @override
  DateTime get receivedAt;

  /// `null` when unread. Set the first time the user opens the row.
  @override
  DateTime? get readAt;

  /// Tombstone — true when the user swiped to dismiss. Kept (not
  /// deleted) so a future "show dismissed" toggle can restore.
  @override
  bool get dismissed;

  /// Create a copy of AppNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppNotificationImplCopyWith<_$AppNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
