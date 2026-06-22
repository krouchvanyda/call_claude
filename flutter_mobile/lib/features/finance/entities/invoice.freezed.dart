// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'invoice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Invoice {
  String get id => throw _privateConstructorUsedError;
  String get invoiceNumber => throw _privateConstructorUsedError;
  String get customerName => throw _privateConstructorUsedError;
  DateTime get issuedAt => throw _privateConstructorUsedError;
  DateTime get dueAt => throw _privateConstructorUsedError;
  InvoiceStatus get status => throw _privateConstructorUsedError;

  /// Pre-formatted (e.g. `r'$1,234.56'`).
  String get totalAmount => throw _privateConstructorUsedError;

  /// ISO 4217 — exposed to the detail page for formatting consistency.
  String get currency => throw _privateConstructorUsedError;

  /// `User.id` of the approver. Set only when [status] is `approved`.
  String? get approvedBy => throw _privateConstructorUsedError;

  /// `User.id` of the rejector. Set only when [status] is `rejected`.
  String? get rejectedBy => throw _privateConstructorUsedError;

  /// Free-text rationale captured at reject time. Mandatory at the
  /// UseCase layer — never `null` once a reject has fired.
  String? get rejectedReason => throw _privateConstructorUsedError;

  /// Timestamp of the latest approve/reject/reopen transition. Used
  /// by the audit log viewer.
  DateTime? get actionedAt => throw _privateConstructorUsedError;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InvoiceCopyWith<Invoice> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InvoiceCopyWith<$Res> {
  factory $InvoiceCopyWith(Invoice value, $Res Function(Invoice) then) =
      _$InvoiceCopyWithImpl<$Res, Invoice>;
  @useResult
  $Res call({
    String id,
    String invoiceNumber,
    String customerName,
    DateTime issuedAt,
    DateTime dueAt,
    InvoiceStatus status,
    String totalAmount,
    String currency,
    String? approvedBy,
    String? rejectedBy,
    String? rejectedReason,
    DateTime? actionedAt,
  });
}

/// @nodoc
class _$InvoiceCopyWithImpl<$Res, $Val extends Invoice>
    implements $InvoiceCopyWith<$Res> {
  _$InvoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? invoiceNumber = null,
    Object? customerName = null,
    Object? issuedAt = null,
    Object? dueAt = null,
    Object? status = null,
    Object? totalAmount = null,
    Object? currency = null,
    Object? approvedBy = freezed,
    Object? rejectedBy = freezed,
    Object? rejectedReason = freezed,
    Object? actionedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            invoiceNumber: null == invoiceNumber
                ? _value.invoiceNumber
                : invoiceNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            customerName: null == customerName
                ? _value.customerName
                : customerName // ignore: cast_nullable_to_non_nullable
                      as String,
            issuedAt: null == issuedAt
                ? _value.issuedAt
                : issuedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            dueAt: null == dueAt
                ? _value.dueAt
                : dueAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as InvoiceStatus,
            totalAmount: null == totalAmount
                ? _value.totalAmount
                : totalAmount // ignore: cast_nullable_to_non_nullable
                      as String,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            approvedBy: freezed == approvedBy
                ? _value.approvedBy
                : approvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejectedBy: freezed == rejectedBy
                ? _value.rejectedBy
                : rejectedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
            rejectedReason: freezed == rejectedReason
                ? _value.rejectedReason
                : rejectedReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            actionedAt: freezed == actionedAt
                ? _value.actionedAt
                : actionedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InvoiceImplCopyWith<$Res> implements $InvoiceCopyWith<$Res> {
  factory _$$InvoiceImplCopyWith(
    _$InvoiceImpl value,
    $Res Function(_$InvoiceImpl) then,
  ) = __$$InvoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String invoiceNumber,
    String customerName,
    DateTime issuedAt,
    DateTime dueAt,
    InvoiceStatus status,
    String totalAmount,
    String currency,
    String? approvedBy,
    String? rejectedBy,
    String? rejectedReason,
    DateTime? actionedAt,
  });
}

/// @nodoc
class __$$InvoiceImplCopyWithImpl<$Res>
    extends _$InvoiceCopyWithImpl<$Res, _$InvoiceImpl>
    implements _$$InvoiceImplCopyWith<$Res> {
  __$$InvoiceImplCopyWithImpl(
    _$InvoiceImpl _value,
    $Res Function(_$InvoiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? invoiceNumber = null,
    Object? customerName = null,
    Object? issuedAt = null,
    Object? dueAt = null,
    Object? status = null,
    Object? totalAmount = null,
    Object? currency = null,
    Object? approvedBy = freezed,
    Object? rejectedBy = freezed,
    Object? rejectedReason = freezed,
    Object? actionedAt = freezed,
  }) {
    return _then(
      _$InvoiceImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        invoiceNumber: null == invoiceNumber
            ? _value.invoiceNumber
            : invoiceNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        customerName: null == customerName
            ? _value.customerName
            : customerName // ignore: cast_nullable_to_non_nullable
                  as String,
        issuedAt: null == issuedAt
            ? _value.issuedAt
            : issuedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        dueAt: null == dueAt
            ? _value.dueAt
            : dueAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as InvoiceStatus,
        totalAmount: null == totalAmount
            ? _value.totalAmount
            : totalAmount // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        approvedBy: freezed == approvedBy
            ? _value.approvedBy
            : approvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejectedBy: freezed == rejectedBy
            ? _value.rejectedBy
            : rejectedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
        rejectedReason: freezed == rejectedReason
            ? _value.rejectedReason
            : rejectedReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        actionedAt: freezed == actionedAt
            ? _value.actionedAt
            : actionedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc

class _$InvoiceImpl implements _Invoice {
  const _$InvoiceImpl({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.issuedAt,
    required this.dueAt,
    required this.status,
    required this.totalAmount,
    this.currency = 'USD',
    this.approvedBy,
    this.rejectedBy,
    this.rejectedReason,
    this.actionedAt,
  });

  @override
  final String id;
  @override
  final String invoiceNumber;
  @override
  final String customerName;
  @override
  final DateTime issuedAt;
  @override
  final DateTime dueAt;
  @override
  final InvoiceStatus status;

  /// Pre-formatted (e.g. `r'$1,234.56'`).
  @override
  final String totalAmount;

  /// ISO 4217 — exposed to the detail page for formatting consistency.
  @override
  @JsonKey()
  final String currency;

  /// `User.id` of the approver. Set only when [status] is `approved`.
  @override
  final String? approvedBy;

  /// `User.id` of the rejector. Set only when [status] is `rejected`.
  @override
  final String? rejectedBy;

  /// Free-text rationale captured at reject time. Mandatory at the
  /// UseCase layer — never `null` once a reject has fired.
  @override
  final String? rejectedReason;

  /// Timestamp of the latest approve/reject/reopen transition. Used
  /// by the audit log viewer.
  @override
  final DateTime? actionedAt;

  @override
  String toString() {
    return 'Invoice(id: $id, invoiceNumber: $invoiceNumber, customerName: $customerName, issuedAt: $issuedAt, dueAt: $dueAt, status: $status, totalAmount: $totalAmount, currency: $currency, approvedBy: $approvedBy, rejectedBy: $rejectedBy, rejectedReason: $rejectedReason, actionedAt: $actionedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InvoiceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.invoiceNumber, invoiceNumber) ||
                other.invoiceNumber == invoiceNumber) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.issuedAt, issuedAt) ||
                other.issuedAt == issuedAt) &&
            (identical(other.dueAt, dueAt) || other.dueAt == dueAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.approvedBy, approvedBy) ||
                other.approvedBy == approvedBy) &&
            (identical(other.rejectedBy, rejectedBy) ||
                other.rejectedBy == rejectedBy) &&
            (identical(other.rejectedReason, rejectedReason) ||
                other.rejectedReason == rejectedReason) &&
            (identical(other.actionedAt, actionedAt) ||
                other.actionedAt == actionedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    invoiceNumber,
    customerName,
    issuedAt,
    dueAt,
    status,
    totalAmount,
    currency,
    approvedBy,
    rejectedBy,
    rejectedReason,
    actionedAt,
  );

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      __$$InvoiceImplCopyWithImpl<_$InvoiceImpl>(this, _$identity);
}

abstract class _Invoice implements Invoice {
  const factory _Invoice({
    required final String id,
    required final String invoiceNumber,
    required final String customerName,
    required final DateTime issuedAt,
    required final DateTime dueAt,
    required final InvoiceStatus status,
    required final String totalAmount,
    final String currency,
    final String? approvedBy,
    final String? rejectedBy,
    final String? rejectedReason,
    final DateTime? actionedAt,
  }) = _$InvoiceImpl;

  @override
  String get id;
  @override
  String get invoiceNumber;
  @override
  String get customerName;
  @override
  DateTime get issuedAt;
  @override
  DateTime get dueAt;
  @override
  InvoiceStatus get status;

  /// Pre-formatted (e.g. `r'$1,234.56'`).
  @override
  String get totalAmount;

  /// ISO 4217 — exposed to the detail page for formatting consistency.
  @override
  String get currency;

  /// `User.id` of the approver. Set only when [status] is `approved`.
  @override
  String? get approvedBy;

  /// `User.id` of the rejector. Set only when [status] is `rejected`.
  @override
  String? get rejectedBy;

  /// Free-text rationale captured at reject time. Mandatory at the
  /// UseCase layer — never `null` once a reject has fired.
  @override
  String? get rejectedReason;

  /// Timestamp of the latest approve/reject/reopen transition. Used
  /// by the audit log viewer.
  @override
  DateTime? get actionedAt;

  /// Create a copy of Invoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InvoiceImplCopyWith<_$InvoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
