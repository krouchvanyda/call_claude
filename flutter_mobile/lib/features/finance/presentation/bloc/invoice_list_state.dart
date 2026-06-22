import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/repositories/invoices_repository.dart';
import '../../entities/invoice.dart';

part 'invoice_list_state.freezed.dart';

/// State for the invoice list (Slice 3.2.1).
///
/// **Single state shape** — no separate Loading / Loaded / Failure
/// classes. Loading and failure are surfaced via flags on the same
/// shape so the toolbar (search field + chips + sort dropdown) can
/// stay mounted while the underlying list refreshes — avoids the
/// "everything resets on every refresh" UX trap.
@freezed
class InvoiceListState with _$InvoiceListState {
  const factory InvoiceListState({
    /// Pre-filtered, pre-sorted view-ready list. Empty until the first
    /// feed emit lands.
    @Default(<Invoice>[]) List<Invoice> visible,

    /// Raw list off the repository — kept around so toolbar changes
    /// re-derive [visible] without a round-trip.
    @Default(<Invoice>[]) List<Invoice> source,

    @Default('') String searchQuery,

    /// Empty set = no filter (show every status).
    @Default(<InvoiceStatus>{}) Set<InvoiceStatus> statusFilter,

    @Default(InvoiceSort.issuedDateDesc) InvoiceSort sort,

    /// `true` from `Started` until the first feed emit. Distinct from
    /// `source.isEmpty` because a *successful* zero-row fetch is not
    /// loading.
    @Default(true) bool isLoading,

    /// Last watch-stream error message; `null` when healthy.
    String? errorMessage,
  }) = _InvoiceListState;
}
