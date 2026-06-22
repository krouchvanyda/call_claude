// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realtime_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RealtimeMessage {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )
    kpiUpdate,
    required TResult Function(
      String id,
      List<RealtimeChartSeriesPayload> series,
    )
    chartUpdate,
    required TResult Function() pong,
    required TResult Function(String raw, String? reason) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )?
    kpiUpdate,
    TResult? Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult? Function()? pong,
    TResult? Function(String raw, String? reason)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String value, String trend, String? trendDelta)?
    kpiUpdate,
    TResult Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult Function()? pong,
    TResult Function(String raw, String? reason)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RealtimeKpiUpdate value) kpiUpdate,
    required TResult Function(RealtimeChartUpdate value) chartUpdate,
    required TResult Function(RealtimePong value) pong,
    required TResult Function(RealtimeUnknown value) unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult? Function(RealtimeChartUpdate value)? chartUpdate,
    TResult? Function(RealtimePong value)? pong,
    TResult? Function(RealtimeUnknown value)? unknown,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult Function(RealtimeChartUpdate value)? chartUpdate,
    TResult Function(RealtimePong value)? pong,
    TResult Function(RealtimeUnknown value)? unknown,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RealtimeMessageCopyWith<$Res> {
  factory $RealtimeMessageCopyWith(
    RealtimeMessage value,
    $Res Function(RealtimeMessage) then,
  ) = _$RealtimeMessageCopyWithImpl<$Res, RealtimeMessage>;
}

/// @nodoc
class _$RealtimeMessageCopyWithImpl<$Res, $Val extends RealtimeMessage>
    implements $RealtimeMessageCopyWith<$Res> {
  _$RealtimeMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$RealtimeKpiUpdateImplCopyWith<$Res> {
  factory _$$RealtimeKpiUpdateImplCopyWith(
    _$RealtimeKpiUpdateImpl value,
    $Res Function(_$RealtimeKpiUpdateImpl) then,
  ) = __$$RealtimeKpiUpdateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, String value, String trend, String? trendDelta});
}

/// @nodoc
class __$$RealtimeKpiUpdateImplCopyWithImpl<$Res>
    extends _$RealtimeMessageCopyWithImpl<$Res, _$RealtimeKpiUpdateImpl>
    implements _$$RealtimeKpiUpdateImplCopyWith<$Res> {
  __$$RealtimeKpiUpdateImplCopyWithImpl(
    _$RealtimeKpiUpdateImpl _value,
    $Res Function(_$RealtimeKpiUpdateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? value = null,
    Object? trend = null,
    Object? trendDelta = freezed,
  }) {
    return _then(
      _$RealtimeKpiUpdateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        trend: null == trend
            ? _value.trend
            : trend // ignore: cast_nullable_to_non_nullable
                  as String,
        trendDelta: freezed == trendDelta
            ? _value.trendDelta
            : trendDelta // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$RealtimeKpiUpdateImpl implements RealtimeKpiUpdate {
  const _$RealtimeKpiUpdateImpl({
    required this.id,
    required this.value,
    required this.trend,
    this.trendDelta,
  });

  @override
  final String id;
  @override
  final String value;
  @override
  final String trend;
  @override
  final String? trendDelta;

  @override
  String toString() {
    return 'RealtimeMessage.kpiUpdate(id: $id, value: $value, trend: $trend, trendDelta: $trendDelta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RealtimeKpiUpdateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.trend, trend) || other.trend == trend) &&
            (identical(other.trendDelta, trendDelta) ||
                other.trendDelta == trendDelta));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, value, trend, trendDelta);

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RealtimeKpiUpdateImplCopyWith<_$RealtimeKpiUpdateImpl> get copyWith =>
      __$$RealtimeKpiUpdateImplCopyWithImpl<_$RealtimeKpiUpdateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )
    kpiUpdate,
    required TResult Function(
      String id,
      List<RealtimeChartSeriesPayload> series,
    )
    chartUpdate,
    required TResult Function() pong,
    required TResult Function(String raw, String? reason) unknown,
  }) {
    return kpiUpdate(id, value, trend, trendDelta);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )?
    kpiUpdate,
    TResult? Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult? Function()? pong,
    TResult? Function(String raw, String? reason)? unknown,
  }) {
    return kpiUpdate?.call(id, value, trend, trendDelta);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String value, String trend, String? trendDelta)?
    kpiUpdate,
    TResult Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult Function()? pong,
    TResult Function(String raw, String? reason)? unknown,
    required TResult orElse(),
  }) {
    if (kpiUpdate != null) {
      return kpiUpdate(id, value, trend, trendDelta);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RealtimeKpiUpdate value) kpiUpdate,
    required TResult Function(RealtimeChartUpdate value) chartUpdate,
    required TResult Function(RealtimePong value) pong,
    required TResult Function(RealtimeUnknown value) unknown,
  }) {
    return kpiUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult? Function(RealtimeChartUpdate value)? chartUpdate,
    TResult? Function(RealtimePong value)? pong,
    TResult? Function(RealtimeUnknown value)? unknown,
  }) {
    return kpiUpdate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult Function(RealtimeChartUpdate value)? chartUpdate,
    TResult Function(RealtimePong value)? pong,
    TResult Function(RealtimeUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (kpiUpdate != null) {
      return kpiUpdate(this);
    }
    return orElse();
  }
}

abstract class RealtimeKpiUpdate implements RealtimeMessage {
  const factory RealtimeKpiUpdate({
    required final String id,
    required final String value,
    required final String trend,
    final String? trendDelta,
  }) = _$RealtimeKpiUpdateImpl;

  String get id;
  String get value;
  String get trend;
  String? get trendDelta;

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RealtimeKpiUpdateImplCopyWith<_$RealtimeKpiUpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RealtimeChartUpdateImplCopyWith<$Res> {
  factory _$$RealtimeChartUpdateImplCopyWith(
    _$RealtimeChartUpdateImpl value,
    $Res Function(_$RealtimeChartUpdateImpl) then,
  ) = __$$RealtimeChartUpdateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String id, List<RealtimeChartSeriesPayload> series});
}

/// @nodoc
class __$$RealtimeChartUpdateImplCopyWithImpl<$Res>
    extends _$RealtimeMessageCopyWithImpl<$Res, _$RealtimeChartUpdateImpl>
    implements _$$RealtimeChartUpdateImplCopyWith<$Res> {
  __$$RealtimeChartUpdateImplCopyWithImpl(
    _$RealtimeChartUpdateImpl _value,
    $Res Function(_$RealtimeChartUpdateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? series = null}) {
    return _then(
      _$RealtimeChartUpdateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        series: null == series
            ? _value._series
            : series // ignore: cast_nullable_to_non_nullable
                  as List<RealtimeChartSeriesPayload>,
      ),
    );
  }
}

/// @nodoc

class _$RealtimeChartUpdateImpl implements RealtimeChartUpdate {
  const _$RealtimeChartUpdateImpl({
    required this.id,
    required final List<RealtimeChartSeriesPayload> series,
  }) : _series = series;

  @override
  final String id;
  final List<RealtimeChartSeriesPayload> _series;
  @override
  List<RealtimeChartSeriesPayload> get series {
    if (_series is EqualUnmodifiableListView) return _series;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_series);
  }

  @override
  String toString() {
    return 'RealtimeMessage.chartUpdate(id: $id, series: $series)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RealtimeChartUpdateImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._series, _series));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_series),
  );

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RealtimeChartUpdateImplCopyWith<_$RealtimeChartUpdateImpl> get copyWith =>
      __$$RealtimeChartUpdateImplCopyWithImpl<_$RealtimeChartUpdateImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )
    kpiUpdate,
    required TResult Function(
      String id,
      List<RealtimeChartSeriesPayload> series,
    )
    chartUpdate,
    required TResult Function() pong,
    required TResult Function(String raw, String? reason) unknown,
  }) {
    return chartUpdate(id, series);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )?
    kpiUpdate,
    TResult? Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult? Function()? pong,
    TResult? Function(String raw, String? reason)? unknown,
  }) {
    return chartUpdate?.call(id, series);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String value, String trend, String? trendDelta)?
    kpiUpdate,
    TResult Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult Function()? pong,
    TResult Function(String raw, String? reason)? unknown,
    required TResult orElse(),
  }) {
    if (chartUpdate != null) {
      return chartUpdate(id, series);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RealtimeKpiUpdate value) kpiUpdate,
    required TResult Function(RealtimeChartUpdate value) chartUpdate,
    required TResult Function(RealtimePong value) pong,
    required TResult Function(RealtimeUnknown value) unknown,
  }) {
    return chartUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult? Function(RealtimeChartUpdate value)? chartUpdate,
    TResult? Function(RealtimePong value)? pong,
    TResult? Function(RealtimeUnknown value)? unknown,
  }) {
    return chartUpdate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult Function(RealtimeChartUpdate value)? chartUpdate,
    TResult Function(RealtimePong value)? pong,
    TResult Function(RealtimeUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (chartUpdate != null) {
      return chartUpdate(this);
    }
    return orElse();
  }
}

abstract class RealtimeChartUpdate implements RealtimeMessage {
  const factory RealtimeChartUpdate({
    required final String id,
    required final List<RealtimeChartSeriesPayload> series,
  }) = _$RealtimeChartUpdateImpl;

  String get id;
  List<RealtimeChartSeriesPayload> get series;

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RealtimeChartUpdateImplCopyWith<_$RealtimeChartUpdateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RealtimePongImplCopyWith<$Res> {
  factory _$$RealtimePongImplCopyWith(
    _$RealtimePongImpl value,
    $Res Function(_$RealtimePongImpl) then,
  ) = __$$RealtimePongImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RealtimePongImplCopyWithImpl<$Res>
    extends _$RealtimeMessageCopyWithImpl<$Res, _$RealtimePongImpl>
    implements _$$RealtimePongImplCopyWith<$Res> {
  __$$RealtimePongImplCopyWithImpl(
    _$RealtimePongImpl _value,
    $Res Function(_$RealtimePongImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$RealtimePongImpl implements RealtimePong {
  const _$RealtimePongImpl();

  @override
  String toString() {
    return 'RealtimeMessage.pong()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RealtimePongImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )
    kpiUpdate,
    required TResult Function(
      String id,
      List<RealtimeChartSeriesPayload> series,
    )
    chartUpdate,
    required TResult Function() pong,
    required TResult Function(String raw, String? reason) unknown,
  }) {
    return pong();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )?
    kpiUpdate,
    TResult? Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult? Function()? pong,
    TResult? Function(String raw, String? reason)? unknown,
  }) {
    return pong?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String value, String trend, String? trendDelta)?
    kpiUpdate,
    TResult Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult Function()? pong,
    TResult Function(String raw, String? reason)? unknown,
    required TResult orElse(),
  }) {
    if (pong != null) {
      return pong();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RealtimeKpiUpdate value) kpiUpdate,
    required TResult Function(RealtimeChartUpdate value) chartUpdate,
    required TResult Function(RealtimePong value) pong,
    required TResult Function(RealtimeUnknown value) unknown,
  }) {
    return pong(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult? Function(RealtimeChartUpdate value)? chartUpdate,
    TResult? Function(RealtimePong value)? pong,
    TResult? Function(RealtimeUnknown value)? unknown,
  }) {
    return pong?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult Function(RealtimeChartUpdate value)? chartUpdate,
    TResult Function(RealtimePong value)? pong,
    TResult Function(RealtimeUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (pong != null) {
      return pong(this);
    }
    return orElse();
  }
}

abstract class RealtimePong implements RealtimeMessage {
  const factory RealtimePong() = _$RealtimePongImpl;
}

/// @nodoc
abstract class _$$RealtimeUnknownImplCopyWith<$Res> {
  factory _$$RealtimeUnknownImplCopyWith(
    _$RealtimeUnknownImpl value,
    $Res Function(_$RealtimeUnknownImpl) then,
  ) = __$$RealtimeUnknownImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String raw, String? reason});
}

/// @nodoc
class __$$RealtimeUnknownImplCopyWithImpl<$Res>
    extends _$RealtimeMessageCopyWithImpl<$Res, _$RealtimeUnknownImpl>
    implements _$$RealtimeUnknownImplCopyWith<$Res> {
  __$$RealtimeUnknownImplCopyWithImpl(
    _$RealtimeUnknownImpl _value,
    $Res Function(_$RealtimeUnknownImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? raw = null, Object? reason = freezed}) {
    return _then(
      _$RealtimeUnknownImpl(
        raw: null == raw
            ? _value.raw
            : raw // ignore: cast_nullable_to_non_nullable
                  as String,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$RealtimeUnknownImpl implements RealtimeUnknown {
  const _$RealtimeUnknownImpl({required this.raw, this.reason});

  @override
  final String raw;
  @override
  final String? reason;

  @override
  String toString() {
    return 'RealtimeMessage.unknown(raw: $raw, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RealtimeUnknownImpl &&
            (identical(other.raw, raw) || other.raw == raw) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, raw, reason);

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RealtimeUnknownImplCopyWith<_$RealtimeUnknownImpl> get copyWith =>
      __$$RealtimeUnknownImplCopyWithImpl<_$RealtimeUnknownImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )
    kpiUpdate,
    required TResult Function(
      String id,
      List<RealtimeChartSeriesPayload> series,
    )
    chartUpdate,
    required TResult Function() pong,
    required TResult Function(String raw, String? reason) unknown,
  }) {
    return unknown(raw, reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String id,
      String value,
      String trend,
      String? trendDelta,
    )?
    kpiUpdate,
    TResult? Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult? Function()? pong,
    TResult? Function(String raw, String? reason)? unknown,
  }) {
    return unknown?.call(raw, reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String value, String trend, String? trendDelta)?
    kpiUpdate,
    TResult Function(String id, List<RealtimeChartSeriesPayload> series)?
    chartUpdate,
    TResult Function()? pong,
    TResult Function(String raw, String? reason)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(raw, reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(RealtimeKpiUpdate value) kpiUpdate,
    required TResult Function(RealtimeChartUpdate value) chartUpdate,
    required TResult Function(RealtimePong value) pong,
    required TResult Function(RealtimeUnknown value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult? Function(RealtimeChartUpdate value)? chartUpdate,
    TResult? Function(RealtimePong value)? pong,
    TResult? Function(RealtimeUnknown value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(RealtimeKpiUpdate value)? kpiUpdate,
    TResult Function(RealtimeChartUpdate value)? chartUpdate,
    TResult Function(RealtimePong value)? pong,
    TResult Function(RealtimeUnknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class RealtimeUnknown implements RealtimeMessage {
  const factory RealtimeUnknown({
    required final String raw,
    final String? reason,
  }) = _$RealtimeUnknownImpl;

  String get raw;
  String? get reason;

  /// Create a copy of RealtimeMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RealtimeUnknownImplCopyWith<_$RealtimeUnknownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RealtimeChartSeriesPayload _$RealtimeChartSeriesPayloadFromJson(
  Map<String, dynamic> json,
) {
  return _RealtimeChartSeriesPayload.fromJson(json);
}

/// @nodoc
mixin _$RealtimeChartSeriesPayload {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  List<double> get x => throw _privateConstructorUsedError;
  List<double> get y => throw _privateConstructorUsedError;

  /// Serializes this RealtimeChartSeriesPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RealtimeChartSeriesPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RealtimeChartSeriesPayloadCopyWith<RealtimeChartSeriesPayload>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RealtimeChartSeriesPayloadCopyWith<$Res> {
  factory $RealtimeChartSeriesPayloadCopyWith(
    RealtimeChartSeriesPayload value,
    $Res Function(RealtimeChartSeriesPayload) then,
  ) =
      _$RealtimeChartSeriesPayloadCopyWithImpl<
        $Res,
        RealtimeChartSeriesPayload
      >;
  @useResult
  $Res call({String id, String label, List<double> x, List<double> y});
}

/// @nodoc
class _$RealtimeChartSeriesPayloadCopyWithImpl<
  $Res,
  $Val extends RealtimeChartSeriesPayload
>
    implements $RealtimeChartSeriesPayloadCopyWith<$Res> {
  _$RealtimeChartSeriesPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RealtimeChartSeriesPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? x = null,
    Object? y = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as List<double>,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as List<double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RealtimeChartSeriesPayloadImplCopyWith<$Res>
    implements $RealtimeChartSeriesPayloadCopyWith<$Res> {
  factory _$$RealtimeChartSeriesPayloadImplCopyWith(
    _$RealtimeChartSeriesPayloadImpl value,
    $Res Function(_$RealtimeChartSeriesPayloadImpl) then,
  ) = __$$RealtimeChartSeriesPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String label, List<double> x, List<double> y});
}

/// @nodoc
class __$$RealtimeChartSeriesPayloadImplCopyWithImpl<$Res>
    extends
        _$RealtimeChartSeriesPayloadCopyWithImpl<
          $Res,
          _$RealtimeChartSeriesPayloadImpl
        >
    implements _$$RealtimeChartSeriesPayloadImplCopyWith<$Res> {
  __$$RealtimeChartSeriesPayloadImplCopyWithImpl(
    _$RealtimeChartSeriesPayloadImpl _value,
    $Res Function(_$RealtimeChartSeriesPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RealtimeChartSeriesPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? x = null,
    Object? y = null,
  }) {
    return _then(
      _$RealtimeChartSeriesPayloadImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        x: null == x
            ? _value._x
            : x // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        y: null == y
            ? _value._y
            : y // ignore: cast_nullable_to_non_nullable
                  as List<double>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RealtimeChartSeriesPayloadImpl implements _RealtimeChartSeriesPayload {
  const _$RealtimeChartSeriesPayloadImpl({
    required this.id,
    required this.label,
    required final List<double> x,
    required final List<double> y,
  }) : _x = x,
       _y = y;

  factory _$RealtimeChartSeriesPayloadImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$RealtimeChartSeriesPayloadImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  final List<double> _x;
  @override
  List<double> get x {
    if (_x is EqualUnmodifiableListView) return _x;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_x);
  }

  final List<double> _y;
  @override
  List<double> get y {
    if (_y is EqualUnmodifiableListView) return _y;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_y);
  }

  @override
  String toString() {
    return 'RealtimeChartSeriesPayload(id: $id, label: $label, x: $x, y: $y)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RealtimeChartSeriesPayloadImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality().equals(other._x, _x) &&
            const DeepCollectionEquality().equals(other._y, _y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    const DeepCollectionEquality().hash(_x),
    const DeepCollectionEquality().hash(_y),
  );

  /// Create a copy of RealtimeChartSeriesPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RealtimeChartSeriesPayloadImplCopyWith<_$RealtimeChartSeriesPayloadImpl>
  get copyWith =>
      __$$RealtimeChartSeriesPayloadImplCopyWithImpl<
        _$RealtimeChartSeriesPayloadImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RealtimeChartSeriesPayloadImplToJson(this);
  }
}

abstract class _RealtimeChartSeriesPayload
    implements RealtimeChartSeriesPayload {
  const factory _RealtimeChartSeriesPayload({
    required final String id,
    required final String label,
    required final List<double> x,
    required final List<double> y,
  }) = _$RealtimeChartSeriesPayloadImpl;

  factory _RealtimeChartSeriesPayload.fromJson(Map<String, dynamic> json) =
      _$RealtimeChartSeriesPayloadImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  List<double> get x;
  @override
  List<double> get y;

  /// Create a copy of RealtimeChartSeriesPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RealtimeChartSeriesPayloadImplCopyWith<_$RealtimeChartSeriesPayloadImpl>
  get copyWith => throw _privateConstructorUsedError;
}
