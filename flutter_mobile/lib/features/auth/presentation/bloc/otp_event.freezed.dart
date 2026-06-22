// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$OtpEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String code) codeChanged,
    required TResult Function() submitted,
    required TResult Function() cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String code)? codeChanged,
    TResult? Function()? submitted,
    TResult? Function()? cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String code)? codeChanged,
    TResult Function()? submitted,
    TResult Function()? cleared,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpCodeChanged value) codeChanged,
    required TResult Function(OtpSubmitted value) submitted,
    required TResult Function(OtpCleared value) cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpCodeChanged value)? codeChanged,
    TResult? Function(OtpSubmitted value)? submitted,
    TResult? Function(OtpCleared value)? cleared,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpCodeChanged value)? codeChanged,
    TResult Function(OtpSubmitted value)? submitted,
    TResult Function(OtpCleared value)? cleared,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OtpEventCopyWith<$Res> {
  factory $OtpEventCopyWith(OtpEvent value, $Res Function(OtpEvent) then) =
      _$OtpEventCopyWithImpl<$Res, OtpEvent>;
}

/// @nodoc
class _$OtpEventCopyWithImpl<$Res, $Val extends OtpEvent>
    implements $OtpEventCopyWith<$Res> {
  _$OtpEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OtpEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$OtpCodeChangedImplCopyWith<$Res> {
  factory _$$OtpCodeChangedImplCopyWith(
    _$OtpCodeChangedImpl value,
    $Res Function(_$OtpCodeChangedImpl) then,
  ) = __$$OtpCodeChangedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String code});
}

/// @nodoc
class __$$OtpCodeChangedImplCopyWithImpl<$Res>
    extends _$OtpEventCopyWithImpl<$Res, _$OtpCodeChangedImpl>
    implements _$$OtpCodeChangedImplCopyWith<$Res> {
  __$$OtpCodeChangedImplCopyWithImpl(
    _$OtpCodeChangedImpl _value,
    $Res Function(_$OtpCodeChangedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? code = null}) {
    return _then(
      _$OtpCodeChangedImpl(
        null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$OtpCodeChangedImpl implements OtpCodeChanged {
  const _$OtpCodeChangedImpl(this.code);

  @override
  final String code;

  @override
  String toString() {
    return 'OtpEvent.codeChanged(code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OtpCodeChangedImpl &&
            (identical(other.code, code) || other.code == code));
  }

  @override
  int get hashCode => Object.hash(runtimeType, code);

  /// Create a copy of OtpEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OtpCodeChangedImplCopyWith<_$OtpCodeChangedImpl> get copyWith =>
      __$$OtpCodeChangedImplCopyWithImpl<_$OtpCodeChangedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String code) codeChanged,
    required TResult Function() submitted,
    required TResult Function() cleared,
  }) {
    return codeChanged(code);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String code)? codeChanged,
    TResult? Function()? submitted,
    TResult? Function()? cleared,
  }) {
    return codeChanged?.call(code);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String code)? codeChanged,
    TResult Function()? submitted,
    TResult Function()? cleared,
    required TResult orElse(),
  }) {
    if (codeChanged != null) {
      return codeChanged(code);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpCodeChanged value) codeChanged,
    required TResult Function(OtpSubmitted value) submitted,
    required TResult Function(OtpCleared value) cleared,
  }) {
    return codeChanged(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpCodeChanged value)? codeChanged,
    TResult? Function(OtpSubmitted value)? submitted,
    TResult? Function(OtpCleared value)? cleared,
  }) {
    return codeChanged?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpCodeChanged value)? codeChanged,
    TResult Function(OtpSubmitted value)? submitted,
    TResult Function(OtpCleared value)? cleared,
    required TResult orElse(),
  }) {
    if (codeChanged != null) {
      return codeChanged(this);
    }
    return orElse();
  }
}

abstract class OtpCodeChanged implements OtpEvent {
  const factory OtpCodeChanged(final String code) = _$OtpCodeChangedImpl;

  String get code;

  /// Create a copy of OtpEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OtpCodeChangedImplCopyWith<_$OtpCodeChangedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$OtpSubmittedImplCopyWith<$Res> {
  factory _$$OtpSubmittedImplCopyWith(
    _$OtpSubmittedImpl value,
    $Res Function(_$OtpSubmittedImpl) then,
  ) = __$$OtpSubmittedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OtpSubmittedImplCopyWithImpl<$Res>
    extends _$OtpEventCopyWithImpl<$Res, _$OtpSubmittedImpl>
    implements _$$OtpSubmittedImplCopyWith<$Res> {
  __$$OtpSubmittedImplCopyWithImpl(
    _$OtpSubmittedImpl _value,
    $Res Function(_$OtpSubmittedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OtpSubmittedImpl implements OtpSubmitted {
  const _$OtpSubmittedImpl();

  @override
  String toString() {
    return 'OtpEvent.submitted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$OtpSubmittedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String code) codeChanged,
    required TResult Function() submitted,
    required TResult Function() cleared,
  }) {
    return submitted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String code)? codeChanged,
    TResult? Function()? submitted,
    TResult? Function()? cleared,
  }) {
    return submitted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String code)? codeChanged,
    TResult Function()? submitted,
    TResult Function()? cleared,
    required TResult orElse(),
  }) {
    if (submitted != null) {
      return submitted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpCodeChanged value) codeChanged,
    required TResult Function(OtpSubmitted value) submitted,
    required TResult Function(OtpCleared value) cleared,
  }) {
    return submitted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpCodeChanged value)? codeChanged,
    TResult? Function(OtpSubmitted value)? submitted,
    TResult? Function(OtpCleared value)? cleared,
  }) {
    return submitted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpCodeChanged value)? codeChanged,
    TResult Function(OtpSubmitted value)? submitted,
    TResult Function(OtpCleared value)? cleared,
    required TResult orElse(),
  }) {
    if (submitted != null) {
      return submitted(this);
    }
    return orElse();
  }
}

abstract class OtpSubmitted implements OtpEvent {
  const factory OtpSubmitted() = _$OtpSubmittedImpl;
}

/// @nodoc
abstract class _$$OtpClearedImplCopyWith<$Res> {
  factory _$$OtpClearedImplCopyWith(
    _$OtpClearedImpl value,
    $Res Function(_$OtpClearedImpl) then,
  ) = __$$OtpClearedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$OtpClearedImplCopyWithImpl<$Res>
    extends _$OtpEventCopyWithImpl<$Res, _$OtpClearedImpl>
    implements _$$OtpClearedImplCopyWith<$Res> {
  __$$OtpClearedImplCopyWithImpl(
    _$OtpClearedImpl _value,
    $Res Function(_$OtpClearedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of OtpEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$OtpClearedImpl implements OtpCleared {
  const _$OtpClearedImpl();

  @override
  String toString() {
    return 'OtpEvent.cleared()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$OtpClearedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String code) codeChanged,
    required TResult Function() submitted,
    required TResult Function() cleared,
  }) {
    return cleared();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String code)? codeChanged,
    TResult? Function()? submitted,
    TResult? Function()? cleared,
  }) {
    return cleared?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String code)? codeChanged,
    TResult Function()? submitted,
    TResult Function()? cleared,
    required TResult orElse(),
  }) {
    if (cleared != null) {
      return cleared();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(OtpCodeChanged value) codeChanged,
    required TResult Function(OtpSubmitted value) submitted,
    required TResult Function(OtpCleared value) cleared,
  }) {
    return cleared(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(OtpCodeChanged value)? codeChanged,
    TResult? Function(OtpSubmitted value)? submitted,
    TResult? Function(OtpCleared value)? cleared,
  }) {
    return cleared?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(OtpCodeChanged value)? codeChanged,
    TResult Function(OtpSubmitted value)? submitted,
    TResult Function(OtpCleared value)? cleared,
    required TResult orElse(),
  }) {
    if (cleared != null) {
      return cleared(this);
    }
    return orElse();
  }
}

abstract class OtpCleared implements OtpEvent {
  const factory OtpCleared() = _$OtpClearedImpl;
}
