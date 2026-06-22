import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/repositories/invoices_repository.dart';
import '../../entities/invoice.dart';

part 'invoice_list_event.freezed.dart';

/// Inputs to [InvoiceListBloc] (Slice 3.2.1).
@freezed
sealed class InvoiceListEvent with _$InvoiceListEvent {
  /// Subscribe to the repo's watch stream.
  const factory InvoiceListEvent.started() = InvoiceListStarted;

  /// User typed in the search field.
  const factory InvoiceListEvent.searchChanged(String query) =
      InvoiceListSearchChanged;

  /// User toggled a status chip — adds or removes from the active set.
  /// An empty set means "show every status" (no filter).
  const factory InvoiceListEvent.statusToggled(InvoiceStatus status) =
      InvoiceListStatusToggled;

  /// User picked a sort axis from the toolbar.
  const factory InvoiceListEvent.sortChanged(InvoiceSort sort) =
      InvoiceListSortChanged;

  /// Internal — repo emitted a fresh snapshot.
  const factory InvoiceListEvent.feedUpdated(List<Invoice> all) =
      InvoiceListFeedUpdated;

  const factory InvoiceListEvent.feedFailed(String message) =
      InvoiceListFeedFailed;
}
