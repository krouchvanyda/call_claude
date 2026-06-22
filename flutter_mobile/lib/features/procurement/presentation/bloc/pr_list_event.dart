import '../../entities/purchase_request.dart';

/// Inputs to [PurchaseRequestListBloc] (Slice 4.1.1).
sealed class PurchaseRequestListEvent {
  const PurchaseRequestListEvent();
}

class PurchaseRequestListStarted extends PurchaseRequestListEvent {
  const PurchaseRequestListStarted();
}

class PurchaseRequestListSearchChanged extends PurchaseRequestListEvent {
  const PurchaseRequestListSearchChanged(this.query);
  final String query;
}

class PurchaseRequestListStatusToggled extends PurchaseRequestListEvent {
  const PurchaseRequestListStatusToggled(this.status);
  final PurchaseRequestStatus status;
}

class PurchaseRequestListSortChanged extends PurchaseRequestListEvent {
  const PurchaseRequestListSortChanged(this.sort);
  final PurchaseRequestSort sort;
}

class PurchaseRequestListFeedUpdated extends PurchaseRequestListEvent {
  const PurchaseRequestListFeedUpdated(this.all);
  final List<PurchaseRequest> all;
}

class PurchaseRequestListFeedFailed extends PurchaseRequestListEvent {
  const PurchaseRequestListFeedFailed(this.message);
  final String message;
}
