// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PushMessage {
  /// Server-assigned message id. Used for dedupe — the same payload
  /// arriving via foreground + background isolate must collapse to
  /// one inbox row. Null when the source didn't supply one (the
  /// router falls back to a generated id).
  String? get id => throw _privateConstructorUsedError;

  /// Display title — comes from FCM's `notification.title`.
  String get title => throw _privateConstructorUsedError;

  /// Display body — FCM's `notification.body`.
  String get body => throw _privateConstructorUsedError;

  /// App-specific routing data — FCM's `data` map. Convention:
  /// - `'category'` discriminates icon / colour in the inbox UI
  ///   (defaults to `'system'` when absent).
  /// - `'route'` is a `go_router` named route for the deep link.
  /// - `'route.<key>'` entries become `go_router` path parameters.
  Map<String, String> get data => throw _privateConstructorUsedError;

  /// When the server / push transport says the message was emitted.
  /// `null` falls back to "now" at the router boundary so inbox
  /// ordering still works.
  DateTime? get sentAt => throw _privateConstructorUsedError;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PushMessageCopyWith<PushMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PushMessageCopyWith<$Res> {
  factory $PushMessageCopyWith(
    PushMessage value,
    $Res Function(PushMessage) then,
  ) = _$PushMessageCopyWithImpl<$Res, PushMessage>;
  @useResult
  $Res call({
    String? id,
    String title,
    String body,
    Map<String, String> data,
    DateTime? sentAt,
  });
}

/// @nodoc
class _$PushMessageCopyWithImpl<$Res, $Val extends PushMessage>
    implements $PushMessageCopyWith<$Res> {
  _$PushMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? body = null,
    Object? data = null,
    Object? sentAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
            sentAt: freezed == sentAt
                ? _value.sentAt
                : sentAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PushMessageImplCopyWith<$Res>
    implements $PushMessageCopyWith<$Res> {
  factory _$$PushMessageImplCopyWith(
    _$PushMessageImpl value,
    $Res Function(_$PushMessageImpl) then,
  ) = __$$PushMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    String title,
    String body,
    Map<String, String> data,
    DateTime? sentAt,
  });
}

/// @nodoc
class __$$PushMessageImplCopyWithImpl<$Res>
    extends _$PushMessageCopyWithImpl<$Res, _$PushMessageImpl>
    implements _$$PushMessageImplCopyWith<$Res> {
  __$$PushMessageImplCopyWithImpl(
    _$PushMessageImpl _value,
    $Res Function(_$PushMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? title = null,
    Object? body = null,
    Object? data = null,
    Object? sentAt = freezed,
  }) {
    return _then(
      _$PushMessageImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
        sentAt: freezed == sentAt
            ? _value.sentAt
            : sentAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$PushMessageImpl implements _PushMessage {
  const _$PushMessageImpl({
    this.id,
    required this.title,
    required this.body,
    final Map<String, String> data = const <String, String>{},
    this.sentAt,
  }) : _data = data;

  /// Server-assigned message id. Used for dedupe — the same payload
  /// arriving via foreground + background isolate must collapse to
  /// one inbox row. Null when the source didn't supply one (the
  /// router falls back to a generated id).
  @override
  final String? id;

  /// Display title — comes from FCM's `notification.title`.
  @override
  final String title;

  /// Display body — FCM's `notification.body`.
  @override
  final String body;

  /// App-specific routing data — FCM's `data` map. Convention:
  /// - `'category'` discriminates icon / colour in the inbox UI
  ///   (defaults to `'system'` when absent).
  /// - `'route'` is a `go_router` named route for the deep link.
  /// - `'route.<key>'` entries become `go_router` path parameters.
  final Map<String, String> _data;

  /// App-specific routing data — FCM's `data` map. Convention:
  /// - `'category'` discriminates icon / colour in the inbox UI
  ///   (defaults to `'system'` when absent).
  /// - `'route'` is a `go_router` named route for the deep link.
  /// - `'route.<key>'` entries become `go_router` path parameters.
  @override
  @JsonKey()
  Map<String, String> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  /// When the server / push transport says the message was emitted.
  /// `null` falls back to "now" at the router boundary so inbox
  /// ordering still works.
  @override
  final DateTime? sentAt;

  @override
  String toString() {
    return 'PushMessage(id: $id, title: $title, body: $body, data: $data, sentAt: $sentAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PushMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.sentAt, sentAt) || other.sentAt == sentAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    body,
    const DeepCollectionEquality().hash(_data),
    sentAt,
  );

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PushMessageImplCopyWith<_$PushMessageImpl> get copyWith =>
      __$$PushMessageImplCopyWithImpl<_$PushMessageImpl>(this, _$identity);
}

abstract class _PushMessage implements PushMessage {
  const factory _PushMessage({
    final String? id,
    required final String title,
    required final String body,
    final Map<String, String> data,
    final DateTime? sentAt,
  }) = _$PushMessageImpl;

  /// Server-assigned message id. Used for dedupe — the same payload
  /// arriving via foreground + background isolate must collapse to
  /// one inbox row. Null when the source didn't supply one (the
  /// router falls back to a generated id).
  @override
  String? get id;

  /// Display title — comes from FCM's `notification.title`.
  @override
  String get title;

  /// Display body — FCM's `notification.body`.
  @override
  String get body;

  /// App-specific routing data — FCM's `data` map. Convention:
  /// - `'category'` discriminates icon / colour in the inbox UI
  ///   (defaults to `'system'` when absent).
  /// - `'route'` is a `go_router` named route for the deep link.
  /// - `'route.<key>'` entries become `go_router` path parameters.
  @override
  Map<String, String> get data;

  /// When the server / push transport says the message was emitted.
  /// `null` falls back to "now" at the router boundary so inbox
  /// ordering still works.
  @override
  DateTime? get sentAt;

  /// Create a copy of PushMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PushMessageImplCopyWith<_$PushMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
