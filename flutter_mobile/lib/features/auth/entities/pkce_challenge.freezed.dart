// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pkce_challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PkceChallenge {
  /// 43-128 char unreserved-character string (`[A-Z][a-z][0-9]-._~`).
  String get verifier => throw _privateConstructorUsedError;

  /// `BASE64URL(SHA-256(verifier))` with `=` padding stripped, per
  /// RFC 7636 §4.2 when `method == 'S256'`.
  String get challenge => throw _privateConstructorUsedError;

  /// Always `'S256'` for new flows; the spec also allows `'plain'`
  /// for legacy clients but we never emit that.
  String get method => throw _privateConstructorUsedError;

  /// Create a copy of PkceChallenge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PkceChallengeCopyWith<PkceChallenge> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PkceChallengeCopyWith<$Res> {
  factory $PkceChallengeCopyWith(
    PkceChallenge value,
    $Res Function(PkceChallenge) then,
  ) = _$PkceChallengeCopyWithImpl<$Res, PkceChallenge>;
  @useResult
  $Res call({String verifier, String challenge, String method});
}

/// @nodoc
class _$PkceChallengeCopyWithImpl<$Res, $Val extends PkceChallenge>
    implements $PkceChallengeCopyWith<$Res> {
  _$PkceChallengeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PkceChallenge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? verifier = null,
    Object? challenge = null,
    Object? method = null,
  }) {
    return _then(
      _value.copyWith(
            verifier: null == verifier
                ? _value.verifier
                : verifier // ignore: cast_nullable_to_non_nullable
                      as String,
            challenge: null == challenge
                ? _value.challenge
                : challenge // ignore: cast_nullable_to_non_nullable
                      as String,
            method: null == method
                ? _value.method
                : method // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PkceChallengeImplCopyWith<$Res>
    implements $PkceChallengeCopyWith<$Res> {
  factory _$$PkceChallengeImplCopyWith(
    _$PkceChallengeImpl value,
    $Res Function(_$PkceChallengeImpl) then,
  ) = __$$PkceChallengeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String verifier, String challenge, String method});
}

/// @nodoc
class __$$PkceChallengeImplCopyWithImpl<$Res>
    extends _$PkceChallengeCopyWithImpl<$Res, _$PkceChallengeImpl>
    implements _$$PkceChallengeImplCopyWith<$Res> {
  __$$PkceChallengeImplCopyWithImpl(
    _$PkceChallengeImpl _value,
    $Res Function(_$PkceChallengeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PkceChallenge
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? verifier = null,
    Object? challenge = null,
    Object? method = null,
  }) {
    return _then(
      _$PkceChallengeImpl(
        verifier: null == verifier
            ? _value.verifier
            : verifier // ignore: cast_nullable_to_non_nullable
                  as String,
        challenge: null == challenge
            ? _value.challenge
            : challenge // ignore: cast_nullable_to_non_nullable
                  as String,
        method: null == method
            ? _value.method
            : method // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PkceChallengeImpl implements _PkceChallenge {
  const _$PkceChallengeImpl({
    required this.verifier,
    required this.challenge,
    this.method = 'S256',
  });

  /// 43-128 char unreserved-character string (`[A-Z][a-z][0-9]-._~`).
  @override
  final String verifier;

  /// `BASE64URL(SHA-256(verifier))` with `=` padding stripped, per
  /// RFC 7636 §4.2 when `method == 'S256'`.
  @override
  final String challenge;

  /// Always `'S256'` for new flows; the spec also allows `'plain'`
  /// for legacy clients but we never emit that.
  @override
  @JsonKey()
  final String method;

  @override
  String toString() {
    return 'PkceChallenge(verifier: $verifier, challenge: $challenge, method: $method)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PkceChallengeImpl &&
            (identical(other.verifier, verifier) ||
                other.verifier == verifier) &&
            (identical(other.challenge, challenge) ||
                other.challenge == challenge) &&
            (identical(other.method, method) || other.method == method));
  }

  @override
  int get hashCode => Object.hash(runtimeType, verifier, challenge, method);

  /// Create a copy of PkceChallenge
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PkceChallengeImplCopyWith<_$PkceChallengeImpl> get copyWith =>
      __$$PkceChallengeImplCopyWithImpl<_$PkceChallengeImpl>(this, _$identity);
}

abstract class _PkceChallenge implements PkceChallenge {
  const factory _PkceChallenge({
    required final String verifier,
    required final String challenge,
    final String method,
  }) = _$PkceChallengeImpl;

  /// 43-128 char unreserved-character string (`[A-Z][a-z][0-9]-._~`).
  @override
  String get verifier;

  /// `BASE64URL(SHA-256(verifier))` with `=` padding stripped, per
  /// RFC 7636 §4.2 when `method == 'S256'`.
  @override
  String get challenge;

  /// Always `'S256'` for new flows; the spec also allows `'plain'`
  /// for legacy clients but we never emit that.
  @override
  String get method;

  /// Create a copy of PkceChallenge
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PkceChallengeImplCopyWith<_$PkceChallengeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
