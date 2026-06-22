// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kpi_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$KpiData {
  /// Short label (e.g. "Revenue", "AR aging > 30d").
  String get label => throw _privateConstructorUsedError;

  /// Pre-formatted primary value (e.g. "$12,400", "82 %").
  String get value => throw _privateConstructorUsedError;

  /// Direction marker — drives icon + colour. Use [KpiTrend.fromDelta]
  /// at the data source if you only have a numeric change.
  KpiTrend get trend => throw _privateConstructorUsedError;

  /// Pre-formatted change label (e.g. "+12.4 %", "-3 d"). `null`
  /// suppresses the chip; use this for KPIs without comparison data.
  String? get trendDelta => throw _privateConstructorUsedError;

  /// Newest-last numeric series for the sparkline. Empty list = no
  /// sparkline drawn. Single point is allowed and rendered as a dot.
  List<double> get sparkline => throw _privateConstructorUsedError;

  /// Create a copy of KpiData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KpiDataCopyWith<KpiData> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KpiDataCopyWith<$Res> {
  factory $KpiDataCopyWith(KpiData value, $Res Function(KpiData) then) =
      _$KpiDataCopyWithImpl<$Res, KpiData>;
  @useResult
  $Res call({
    String label,
    String value,
    KpiTrend trend,
    String? trendDelta,
    List<double> sparkline,
  });
}

/// @nodoc
class _$KpiDataCopyWithImpl<$Res, $Val extends KpiData>
    implements $KpiDataCopyWith<$Res> {
  _$KpiDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KpiData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? trend = null,
    Object? trendDelta = freezed,
    Object? sparkline = null,
  }) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
            trend: null == trend
                ? _value.trend
                : trend // ignore: cast_nullable_to_non_nullable
                      as KpiTrend,
            trendDelta: freezed == trendDelta
                ? _value.trendDelta
                : trendDelta // ignore: cast_nullable_to_non_nullable
                      as String?,
            sparkline: null == sparkline
                ? _value.sparkline
                : sparkline // ignore: cast_nullable_to_non_nullable
                      as List<double>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$KpiDataImplCopyWith<$Res> implements $KpiDataCopyWith<$Res> {
  factory _$$KpiDataImplCopyWith(
    _$KpiDataImpl value,
    $Res Function(_$KpiDataImpl) then,
  ) = __$$KpiDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String label,
    String value,
    KpiTrend trend,
    String? trendDelta,
    List<double> sparkline,
  });
}

/// @nodoc
class __$$KpiDataImplCopyWithImpl<$Res>
    extends _$KpiDataCopyWithImpl<$Res, _$KpiDataImpl>
    implements _$$KpiDataImplCopyWith<$Res> {
  __$$KpiDataImplCopyWithImpl(
    _$KpiDataImpl _value,
    $Res Function(_$KpiDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of KpiData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? value = null,
    Object? trend = null,
    Object? trendDelta = freezed,
    Object? sparkline = null,
  }) {
    return _then(
      _$KpiDataImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
        trend: null == trend
            ? _value.trend
            : trend // ignore: cast_nullable_to_non_nullable
                  as KpiTrend,
        trendDelta: freezed == trendDelta
            ? _value.trendDelta
            : trendDelta // ignore: cast_nullable_to_non_nullable
                  as String?,
        sparkline: null == sparkline
            ? _value._sparkline
            : sparkline // ignore: cast_nullable_to_non_nullable
                  as List<double>,
      ),
    );
  }
}

/// @nodoc

class _$KpiDataImpl implements _KpiData {
  const _$KpiDataImpl({
    required this.label,
    required this.value,
    required this.trend,
    this.trendDelta,
    final List<double> sparkline = const <double>[],
  }) : _sparkline = sparkline;

  /// Short label (e.g. "Revenue", "AR aging > 30d").
  @override
  final String label;

  /// Pre-formatted primary value (e.g. "$12,400", "82 %").
  @override
  final String value;

  /// Direction marker — drives icon + colour. Use [KpiTrend.fromDelta]
  /// at the data source if you only have a numeric change.
  @override
  final KpiTrend trend;

  /// Pre-formatted change label (e.g. "+12.4 %", "-3 d"). `null`
  /// suppresses the chip; use this for KPIs without comparison data.
  @override
  final String? trendDelta;

  /// Newest-last numeric series for the sparkline. Empty list = no
  /// sparkline drawn. Single point is allowed and rendered as a dot.
  final List<double> _sparkline;

  /// Newest-last numeric series for the sparkline. Empty list = no
  /// sparkline drawn. Single point is allowed and rendered as a dot.
  @override
  @JsonKey()
  List<double> get sparkline {
    if (_sparkline is EqualUnmodifiableListView) return _sparkline;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sparkline);
  }

  @override
  String toString() {
    return 'KpiData(label: $label, value: $value, trend: $trend, trendDelta: $trendDelta, sparkline: $sparkline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KpiDataImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.trend, trend) || other.trend == trend) &&
            (identical(other.trendDelta, trendDelta) ||
                other.trendDelta == trendDelta) &&
            const DeepCollectionEquality().equals(
              other._sparkline,
              _sparkline,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    label,
    value,
    trend,
    trendDelta,
    const DeepCollectionEquality().hash(_sparkline),
  );

  /// Create a copy of KpiData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KpiDataImplCopyWith<_$KpiDataImpl> get copyWith =>
      __$$KpiDataImplCopyWithImpl<_$KpiDataImpl>(this, _$identity);
}

abstract class _KpiData implements KpiData {
  const factory _KpiData({
    required final String label,
    required final String value,
    required final KpiTrend trend,
    final String? trendDelta,
    final List<double> sparkline,
  }) = _$KpiDataImpl;

  /// Short label (e.g. "Revenue", "AR aging > 30d").
  @override
  String get label;

  /// Pre-formatted primary value (e.g. "$12,400", "82 %").
  @override
  String get value;

  /// Direction marker — drives icon + colour. Use [KpiTrend.fromDelta]
  /// at the data source if you only have a numeric change.
  @override
  KpiTrend get trend;

  /// Pre-formatted change label (e.g. "+12.4 %", "-3 d"). `null`
  /// suppresses the chip; use this for KPIs without comparison data.
  @override
  String? get trendDelta;

  /// Newest-last numeric series for the sparkline. Empty list = no
  /// sparkline drawn. Single point is allowed and rendered as a dot.
  @override
  List<double> get sparkline;

  /// Create a copy of KpiData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KpiDataImplCopyWith<_$KpiDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
