// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$InvoiceDetail {
  Invoice get header => throw _privateConstructorUsedError;
  List<InvoiceLineItem> get lineItems => throw _privateConstructorUsedError;

  /// Pre-formatted subtotal / tax / total strings (server-computed).
  String get subtotal => throw _privateConstructorUsedError;
  String get tax => throw _privateConstructorUsedError;

  /// Optional notes / terms.
  String? get notes => throw _privateConstructorUsedError;

  /// Create a copy of InvoiceDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceDetailCopyWith<InvoiceDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceDetailCopyWith<$Res> {
  factory $InvoiceDetailCopyWith(
    InvoiceDetail value,
    $Res Function(InvoiceDetail) then,
  ) = _$InvoiceDetailCopyWithImpl<$Res, InvoiceDetail>;
  @useResult
  $Res call({
    Invoice header,
    List<InvoiceLineItem> lineItems,
    String subtotal,
    String tax,
    String? notes,
  });

  $InvoiceCopyWith<$Res> get header;
}

/// @nodoc
class _$InvoiceDetailCopyWithImpl<$Res, $Val extends InvoiceDetail>
    implements $InvoiceDetailCopyWith<$Res> {
  _$InvoiceDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InvoiceDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = null,
    Object? lineItems = null,
    Object? subtotal = null,
    Object? tax = null,
    Object? notes = freezed,
  }) {
    return _then(
      _value.copyWith(
            header: null == header
                ? _value.header
                : header // ignore: cast_nullable_to_non_nullable
                      as Invoice,
            lineItems: null == lineItems
                ? _value.lineItems
                : lineItems // ignore: cast_nullable_to_non_nullable
                      as List<InvoiceLineItem>,
            subtotal: null == subtotal
                ? _value.subtotal
                : subtotal // ignore: cast_nullable_to_non_nullable
                      as String,
            tax: null == tax
                ? _value.tax
                : tax // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of InvoiceDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $InvoiceCopyWith<$Res> get header {
    return $InvoiceCopyWith<$Res>(_value.header, (value) {
      return _then(_value.copyWith(header: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InvoiceDetailImplCopyWith<$Res>
    implements $InvoiceDetailCopyWith<$Res> {
  factory _$$InvoiceDetailImplCopyWith(
    _$InvoiceDetailImpl value,
    $Res Function(_$InvoiceDetailImpl) then,
  ) = __$$InvoiceDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Invoice header,
    List<InvoiceLineItem> lineItems,
    String subtotal,
    String tax,
    String? notes,
  });

  @override
  $InvoiceCopyWith<$Res> get header;
}

/// @nodoc
class __$$InvoiceDetailImplCopyWithImpl<$Res>
    extends _$InvoiceDetailCopyWithImpl<$Res, _$InvoiceDetailImpl>
    implements _$$InvoiceDetailImplCopyWith<$Res> {
  __$$InvoiceDetailImplCopyWithImpl(
    _$InvoiceDetailImpl _value,
    $Res Function(_$InvoiceDetailImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InvoiceDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = null,
    Object? lineItems = null,
    Object? subtotal = null,
    Object? tax = null,
    Object? notes = freezed,
  }) {
    return _then(
      _$InvoiceDetailImpl(
        header: null == header
            ? _value.header
            : header // ignore: cast_nullable_to_non_nullable
                  as Invoice,
        lineItems: null == lineItems
            ? _value._lineItems
            : lineItems // ignore: cast_nullable_to_non_nullable
                  as List<InvoiceLineItem>,
        subtotal: null == subtotal
            ? _value.subtotal
            : subtotal // ignore: cast_nullable_to_non_nullable
                  as String,
        tax: null == tax
            ? _value.tax
            : tax // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceDetailImpl implements _InvoiceDetail {
  const _$InvoiceDetailImpl({
    required this.header,
    required final List<InvoiceLineItem> lineItems,
    required this.subtotal,
    required this.tax,
    this.notes,
  }) : _lineItems = lineItems;

  @override
  final Invoice header;
  final List<InvoiceLineItem> _lineItems;
  @override
  List<InvoiceLineItem> get lineItems {
    if (_lineItems is EqualUnmodifiableListView) return _lineItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lineItems);
  }

  /// Pre-formatted subtotal / tax / total strings (server-computed).
  @override
  final String subtotal;
  @override
  final String tax;

  /// Optional notes / terms.
  @override
  final String? notes;

  @override
  String toString() {
    return 'InvoiceDetail(header: $header, lineItems: $lineItems, subtotal: $subtotal, tax: $tax, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceDetailImpl &&
            (identical(other.header, header) || other.header == header) &&
            const DeepCollectionEquality().equals(
              other._lineItems,
              _lineItems,
            ) &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.tax, tax) || other.tax == tax) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    header,
    const DeepCollectionEquality().hash(_lineItems),
    subtotal,
    tax,
    notes,
  );

  /// Create a copy of InvoiceDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceDetailImplCopyWith<_$InvoiceDetailImpl> get copyWith =>
      __$$InvoiceDetailImplCopyWithImpl<_$InvoiceDetailImpl>(this, _$identity);
}

abstract class _InvoiceDetail implements InvoiceDetail {
  const factory _InvoiceDetail({
    required final Invoice header,
    required final List<InvoiceLineItem> lineItems,
    required final String subtotal,
    required final String tax,
    final String? notes,
  }) = _$InvoiceDetailImpl;

  @override
  Invoice get header;
  @override
  List<InvoiceLineItem> get lineItems;

  /// Pre-formatted subtotal / tax / total strings (server-computed).
  @override
  String get subtotal;
  @override
  String get tax;

  /// Optional notes / terms.
  @override
  String? get notes;

  /// Create a copy of InvoiceDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceDetailImplCopyWith<_$InvoiceDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
