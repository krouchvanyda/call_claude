import 'package:freezed_annotation/freezed_annotation.dart';

import 'invoice.dart';
import 'invoice_line_item.dart';

part 'invoice_detail.freezed.dart';

/// Full invoice record — header + line items + totals (Slice 3.2.2).
///
/// Distinct from [Invoice] (the list-view header) so the detail
/// payload's heavier shape doesn't burden the list query.
@freezed
class InvoiceDetail with _$InvoiceDetail {
  const factory InvoiceDetail({
    required Invoice header,
    required List<InvoiceLineItem> lineItems,

    /// Pre-formatted subtotal / tax / total strings (server-computed).
    required String subtotal,
    required String tax,

    /// Optional notes / terms.
    String? notes,
  }) = _InvoiceDetail;
}
