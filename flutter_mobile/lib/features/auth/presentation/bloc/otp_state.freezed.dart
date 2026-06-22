// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OtpState {
  /// Required length the bloc validates against. Configurable so the
  /// same widget can drive 4-, 6-, or 8-digit codes.
  int get length => throw _privateConstructorUsedError;

  /// The digits the user has typed so far. Held **in memory only** —
  /// never persisted to drift / secure-storage / shared_preferences.
  String get code => throw _privateConstructorUsedError;
  OtpStatus get status => throw _privateConstructorUsedError;

  /// Populated when [status] is [OtpStatus.error]. Drives the
  /// per-reason localised error copy in the view.
  OtpRejectionReason? get rejectionReason => throw _privateConstructorUsedError;

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OtpStateCopyWith<OtpState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpStateCopyWith<$Res> {
  factory $OtpStateCopyWith(OtpState value, $Res Function(OtpState) then) =
      _$OtpStateCopyWithImpl<$Res, OtpState>;
  @useResult
  $Res call({
    int length,
    String code,
    OtpStatus status,
    OtpRejectionReason? rejectionReason,
  });
}

/// @nodoc
class _$OtpStateCopyWithImpl<$Res, $Val extends OtpState>
    implements $OtpStateCopyWith<$Res> {
  _$OtpStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
    Object? code = null,
    Object? status = null,
    Object? rejectionReason = freezed,
  }) {
    return _then(
      _value.copyWith(
            length: null == length
                ? _value.length
                : length // ignore: cast_nullable_to_non_nullable
                      as int,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as OtpStatus,
            rejectionReason: freezed == rejectionReason
                ? _value.rejectionReason
                : rejectionReason // ignore: cast_nullable_to_non_nullable
                      as OtpRejectionReason?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$OtpStateImplCopyWith<$Res>
    implements $OtpStateCopyWith<$Res> {
  factory _$$OtpStateImplCopyWith(
    _$OtpStateImpl value,
    $Res Function(_$OtpStateImpl) then,
  ) = __$$OtpStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int length,
    String code,
    OtpStatus status,
    OtpRejectionReason? rejectionReason,
  });
}

/// @nodoc
class __$$OtpStateImplCopyWithImpl<$Res>
    extends _$OtpStateCopyWithImpl<$Res, _$OtpStateImpl>
    implements _$$OtpStateImplCopyWith<$Res> {
  __$$OtpStateImplCopyWithImpl(
    _$OtpStateImpl _value,
    $Res Function(_$OtpStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? length = null,
    Object? code = null,
    Object? status = null,
    Object? rejectionReason = freezed,
  }) {
    return _then(
      _$OtpStateImpl(
        length: null == length
            ? _value.length
            : length // ignore: cast_nullable_to_non_nullable
                  as int,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as OtpStatus,
        rejectionReason: freezed == rejectionReason
            ? _value.rejectionReason
            : rejectionReason // ignore: cast_nullable_to_non_nullable
                  as OtpRejectionReason?,
      ),
    );
  }
}

/// @nodoc

class _$OtpStateImpl extends _OtpState {
  const _$OtpStateImpl({
    this.length = 6,
    this.code = '',
    this.status = OtpStatus.idle,
    this.rejectionReason,
  }) : super._();

  /// Required length the bloc validates against. Configurable so the
  /// same widget can drive 4-, 6-, or 8-digit codes.
  @override
  @JsonKey()
  final int length;

  /// The digits the user has typed so far. Held **in memory only** —
  /// never persisted to drift / secure-storage / shared_preferences.
  @override
  @JsonKey()
  final String code;
  @override
  @JsonKey()
  final OtpStatus status;

  /// Populated when [status] is [OtpStatus.error]. Drives the
  /// per-reason localised error copy in the view.
  @override
  final OtpRejectionReason? rejectionReason;

  @override
  String toString() {
    return 'OtpState(length: $length, code: $code, status: $status, rejectionReason: $rejectionReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpStateImpl &&
            (identical(other.length, length) || other.length == length) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.rejectionReason, rejectionReason) ||
                other.rejectionReason == rejectionReason));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, length, code, status, rejectionReason);

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtpStateImplCopyWith<_$OtpStateImpl> get copyWith =>
      __$$OtpStateImplCopyWithImpl<_$OtpStateImpl>(this, _$identity);
}

abstract class _OtpState extends OtpState {
  const factory _OtpState({
    final int length,
    final String code,
    final OtpStatus status,
    final OtpRejectionReason? rejectionReason,
  }) = _$OtpStateImpl;
  const _OtpState._() : super._();

  /// Required length the bloc validates against. Configurable so the
  /// same widget can drive 4-, 6-, or 8-digit codes.
  @override
  int get length;

  /// The digits the user has typed so far. Held **in memory only** —
  /// never persisted to drift / secure-storage / shared_preferences.
  @override
  String get code;
  @override
  OtpStatus get status;

  /// Populated when [status] is [OtpStatus.error]. Drives the
  /// per-reason localised error copy in the view.
  @override
  OtpRejectionReason? get rejectionReason;

  /// Create a copy of OtpState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtpStateImplCopyWith<_$OtpStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
