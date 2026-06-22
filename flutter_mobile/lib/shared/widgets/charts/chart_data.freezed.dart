// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chart_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChartPoint {
  /// X-axis position. For time-series this is typically a Unix-epoch
  /// millisecond or a day index; the widget layer formats the label.
  double get x => throw _privateConstructorUsedError;

  /// Y-axis value.
  double get y => throw _privateConstructorUsedError;

  /// Optional category / X-axis label override (e.g. "Q1", "Mon").
  /// `null` falls back to the widget's default formatter.
  String? get label => throw _privateConstructorUsedError;

  /// Create a copy of ChartPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChartPointCopyWith<ChartPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChartPointCopyWith<$Res> {
  factory $ChartPointCopyWith(
    ChartPoint value,
    $Res Function(ChartPoint) then,
  ) = _$ChartPointCopyWithImpl<$Res, ChartPoint>;
  @useResult
  $Res call({double x, double y, String? label});
}

/// @nodoc
class _$ChartPointCopyWithImpl<$Res, $Val extends ChartPoint>
    implements $ChartPointCopyWith<$Res> {
  _$ChartPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChartPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null, Object? label = freezed}) {
    return _then(
      _value.copyWith(
            x: null == x
                ? _value.x
                : x // ignore: cast_nullable_to_non_nullable
                      as double,
            y: null == y
                ? _value.y
                : y // ignore: cast_nullable_to_non_nullable
                      as double,
            label: freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChartPointImplCopyWith<$Res>
    implements $ChartPointCopyWith<$Res> {
  factory _$$ChartPointImplCopyWith(
    _$ChartPointImpl value,
    $Res Function(_$ChartPointImpl) then,
  ) = __$$ChartPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y, String? label});
}

/// @nodoc
class __$$ChartPointImplCopyWithImpl<$Res>
    extends _$ChartPointCopyWithImpl<$Res, _$ChartPointImpl>
    implements _$$ChartPointImplCopyWith<$Res> {
  __$$ChartPointImplCopyWithImpl(
    _$ChartPointImpl _value,
    $Res Function(_$ChartPointImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChartPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? x = null, Object? y = null, Object? label = freezed}) {
    return _then(
      _$ChartPointImpl(
        x: null == x
            ? _value.x
            : x // ignore: cast_nullable_to_non_nullable
                  as double,
        y: null == y
            ? _value.y
            : y // ignore: cast_nullable_to_non_nullable
                  as double,
        label: freezed == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ChartPointImpl implements _ChartPoint {
  const _$ChartPointImpl({required this.x, required this.y, this.label});

  /// X-axis position. For time-series this is typically a Unix-epoch
  /// millisecond or a day index; the widget layer formats the label.
  @override
  final double x;

  /// Y-axis value.
  @override
  final double y;

  /// Optional category / X-axis label override (e.g. "Q1", "Mon").
  /// `null` falls back to the widget's default formatter.
  @override
  final String? label;

  @override
  String toString() {
    return 'ChartPoint(x: $x, y: $y, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChartPointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.label, label) || other.label == label));
  }

  @override
  int get hashCode => Object.hash(runtimeType, x, y, label);

  /// Create a copy of ChartPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChartPointImplCopyWith<_$ChartPointImpl> get copyWith =>
      __$$ChartPointImplCopyWithImpl<_$ChartPointImpl>(this, _$identity);
}

abstract class _ChartPoint implements ChartPoint {
  const factory _ChartPoint({
    required final double x,
    required final double y,
    final String? label,
  }) = _$ChartPointImpl;

  /// X-axis position. For time-series this is typically a Unix-epoch
  /// millisecond or a day index; the widget layer formats the label.
  @override
  double get x;

  /// Y-axis value.
  @override
  double get y;

  /// Optional category / X-axis label override (e.g. "Q1", "Mon").
  /// `null` falls back to the widget's default formatter.
  @override
  String? get label;

  /// Create a copy of ChartPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChartPointImplCopyWith<_$ChartPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChartSeries {
  /// Stable id — used for keying widgets, not user-facing.
  String get id => throw _privateConstructorUsedError;

  /// Translated display label (used in legends / tooltips).
  String get label => throw _privateConstructorUsedError;

  /// Newest-last data points. Empty list = no series rendered.
  List<ChartPoint> get points => throw _privateConstructorUsedError;

  /// Create a copy of ChartSeries
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChartSeriesCopyWith<ChartSeries> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChartSeriesCopyWith<$Res> {
  factory $ChartSeriesCopyWith(
    ChartSeries value,
    $Res Function(ChartSeries) then,
  ) = _$ChartSeriesCopyWithImpl<$Res, ChartSeries>;
  @useResult
  $Res call({String id, String label, List<ChartPoint> points});
}

/// @nodoc
class _$ChartSeriesCopyWithImpl<$Res, $Val extends ChartSeries>
    implements $ChartSeriesCopyWith<$Res> {
  _$ChartSeriesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChartSeries
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? label = null, Object? points = null}) {
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
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as List<ChartPoint>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChartSeriesImplCopyWith<$Res>
    implements $ChartSeriesCopyWith<$Res> {
  factory _$$ChartSeriesImplCopyWith(
    _$ChartSeriesImpl value,
    $Res Function(_$ChartSeriesImpl) then,
  ) = __$$ChartSeriesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String label, List<ChartPoint> points});
}

/// @nodoc
class __$$ChartSeriesImplCopyWithImpl<$Res>
    extends _$ChartSeriesCopyWithImpl<$Res, _$ChartSeriesImpl>
    implements _$$ChartSeriesImplCopyWith<$Res> {
  __$$ChartSeriesImplCopyWithImpl(
    _$ChartSeriesImpl _value,
    $Res Function(_$ChartSeriesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChartSeries
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? label = null, Object? points = null}) {
    return _then(
      _$ChartSeriesImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        points: null == points
            ? _value._points
            : points // ignore: cast_nullable_to_non_nullable
                  as List<ChartPoint>,
      ),
    );
  }
}

/// @nodoc

class _$ChartSeriesImpl implements _ChartSeries {
  const _$ChartSeriesImpl({
    required this.id,
    required this.label,
    final List<ChartPoint> points = const <ChartPoint>[],
  }) : _points = points;

  /// Stable id — used for keying widgets, not user-facing.
  @override
  final String id;

  /// Translated display label (used in legends / tooltips).
  @override
  final String label;

  /// Newest-last data points. Empty list = no series rendered.
  final List<ChartPoint> _points;

  /// Newest-last data points. Empty list = no series rendered.
  @override
  @JsonKey()
  List<ChartPoint> get points {
    if (_points is EqualUnmodifiableListView) return _points;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_points);
  }

  @override
  String toString() {
    return 'ChartSeries(id: $id, label: $label, points: $points)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChartSeriesImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            const DeepCollectionEquality().equals(other._points, _points));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    label,
    const DeepCollectionEquality().hash(_points),
  );

  /// Create a copy of ChartSeries
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChartSeriesImplCopyWith<_$ChartSeriesImpl> get copyWith =>
      __$$ChartSeriesImplCopyWithImpl<_$ChartSeriesImpl>(this, _$identity);
}

abstract class _ChartSeries implements ChartSeries {
  const factory _ChartSeries({
    required final String id,
    required final String label,
    final List<ChartPoint> points,
  }) = _$ChartSeriesImpl;

  /// Stable id — used for keying widgets, not user-facing.
  @override
  String get id;

  /// Translated display label (used in legends / tooltips).
  @override
  String get label;

  /// Newest-last data points. Empty list = no series rendered.
  @override
  List<ChartPoint> get points;

  /// Create a copy of ChartSeries
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChartSeriesImplCopyWith<_$ChartSeriesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
