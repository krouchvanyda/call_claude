// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_verification_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OtpVerificationResult {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() accepted,
    required TResult Function(OtpRejectionReason reason) rejected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? accepted,
    TResult? Function(OtpRejectionReason reason)? rejected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? accepted,
    TResult Function(OtpRejectionReason reason)? rejected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpAccepted value) accepted,
    required TResult Function(OtpRejected value) rejected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpAccepted value)? accepted,
    TResult? Function(OtpRejected value)? rejected,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpAccepted value)? accepted,
    TResult Function(OtpRejected value)? rejected,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpVerificationResultCopyWith<$Res> {
  factory $OtpVerificationResultCopyWith(
    OtpVerificationResult value,
    $Res Function(OtpVerificationResult) then,
  ) = _$OtpVerificationResultCopyWithImpl<$Res, OtpVerificationResult>;
}

/// @nodoc
class _$OtpVerificationResultCopyWithImpl<
  $Res,
  $Val extends OtpVerificationResult
>
    implements $OtpVerificationResultCopyWith<$Res> {
  _$OtpVerificationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtpVerificationResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OtpAcceptedImplCopyWith<$Res> {
  factory _$$OtpAcceptedImplCopyWith(
    _$OtpAcceptedImpl value,
    $Res Function(_$OtpAcceptedImpl) then,
  ) = __$$OtpAcceptedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OtpAcceptedImplCopyWithImpl<$Res>
    extends _$OtpVerificationResultCopyWithImpl<$Res, _$OtpAcceptedImpl>
    implements _$$OtpAcceptedImplCopyWith<$Res> {
  __$$OtpAcceptedImplCopyWithImpl(
    _$OtpAcceptedImpl _value,
    $Res Function(_$OtpAcceptedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpVerificationResult
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OtpAcceptedImpl implements OtpAccepted {
  const _$OtpAcceptedImpl();

  @override
  String toString() {
    return 'OtpVerificationResult.accepted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$OtpAcceptedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() accepted,
    required TResult Function(OtpRejectionReason reason) rejected,
  }) {
    return accepted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? accepted,
    TResult? Function(OtpRejectionReason reason)? rejected,
  }) {
    return accepted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? accepted,
    TResult Function(OtpRejectionReason reason)? rejected,
    required TResult orElse(),
  }) {
    if (accepted != null) {
      return accepted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpAccepted value) accepted,
    required TResult Function(OtpRejected value) rejected,
  }) {
    return accepted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpAccepted value)? accepted,
    TResult? Function(OtpRejected value)? rejected,
  }) {
    return accepted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpAccepted value)? accepted,
    TResult Function(OtpRejected value)? rejected,
    required TResult orElse(),
  }) {
    if (accepted != null) {
      return accepted(this);
    }
    return orElse();
  }
}

abstract class OtpAccepted implements OtpVerificationResult {
  const factory OtpAccepted() = _$OtpAcceptedImpl;
}

/// @nodoc
abstract class _$$OtpRejectedImplCopyWith<$Res> {
  factory _$$OtpRejectedImplCopyWith(
    _$OtpRejectedImpl value,
    $Res Function(_$OtpRejectedImpl) then,
  ) = __$$OtpRejectedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({OtpRejectionReason reason});
}

/// @nodoc
class __$$OtpRejectedImplCopyWithImpl<$Res>
    extends _$OtpVerificationResultCopyWithImpl<$Res, _$OtpRejectedImpl>
    implements _$$OtpRejectedImplCopyWith<$Res> {
  __$$OtpRejectedImplCopyWithImpl(
    _$OtpRejectedImpl _value,
    $Res Function(_$OtpRejectedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? reason = null}) {
    return _then(
      _$OtpRejectedImpl(
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as OtpRejectionReason,
      ),
    );
  }
}

/// @nodoc

class _$OtpRejectedImpl implements OtpRejected {
  const _$OtpRejectedImpl({required this.reason});

  @override
  final OtpRejectionReason reason;

  @override
  String toString() {
    return 'OtpVerificationResult.rejected(reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpRejectedImpl &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);

  /// Create a copy of OtpVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtpRejectedImplCopyWith<_$OtpRejectedImpl> get copyWith =>
      __$$OtpRejectedImplCopyWithImpl<_$OtpRejectedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() accepted,
    required TResult Function(OtpRejectionReason reason) rejected,
  }) {
    return rejected(reason);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? accepted,
    TResult? Function(OtpRejectionReason reason)? rejected,
  }) {
    return rejected?.call(reason);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? accepted,
    TResult Function(OtpRejectionReason reason)? rejected,
    required TResult orElse(),
  }) {
    if (rejected != null) {
      return rejected(reason);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpAccepted value) accepted,
    required TResult Function(OtpRejected value) rejected,
  }) {
    return rejected(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpAccepted value)? accepted,
    TResult? Function(OtpRejected value)? rejected,
  }) {
    return rejected?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpAccepted value)? accepted,
    TResult Function(OtpRejected value)? rejected,
    required TResult orElse(),
  }) {
    if (rejected != null) {
      return rejected(this);
    }
    return orElse();
  }
}

abstract class OtpRejected implements OtpVerificationResult {
  const factory OtpRejected({required final OtpRejectionReason reason}) =
      _$OtpRejectedImpl;

  OtpRejectionReason get reason;

  /// Create a copy of OtpVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtpRejectedImplCopyWith<_$OtpRejectedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
