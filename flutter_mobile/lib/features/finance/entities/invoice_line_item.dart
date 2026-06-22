import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice_line_item.freezed.dart';

/// One line on an invoice (Slice 3.2.2).
///
/// Pre-formatted [unitPrice] / [lineTotal] strings — same locale-stable
/// pattern as the rest of the finance entities. Server pre-computes
/// `lineTotal = quantity * unitPrice`; the client never multiplies.
@freezed
class InvoiceLineItem with _$InvoiceLineItem {
  const factory InvoiceLineItem({
    required String id,
    required String description,

    /// Decimal — kept as `num` so a half-hour line entry (`0.5`) round-
    /// trips without losing precision to int truncation.
    required num quantity,

    required String unitPrice,
    required String lineTotal,

    /// Optional SKU / catalog reference.
    String? sku,
  }) = _InvoiceLineItem;
}
