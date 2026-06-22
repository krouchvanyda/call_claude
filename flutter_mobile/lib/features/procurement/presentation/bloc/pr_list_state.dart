import '../../entities/purchase_request.dart';

/// One state shape for the PR list (Slice 4.1.1) — `source` is the raw
/// repo feed; `visible` is the filtered/sorted slice the UI renders.
class PurchaseRequestListState {
  const PurchaseRequestListState({
    this.isLoading = true,
    this.errorMessage,
    this.source = const [],
    this.visible = const [],
    this.searchQuery = '',
    this.statusFilter = const {},
    this.sort = PurchaseRequestSort.createdDesc,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<PurchaseRequest> source;
  final List<PurchaseRequest> visible;
  final String searchQuery;
  final Set<PurchaseRequestStatus> statusFilter;
  final PurchaseRequestSort sort;

  PurchaseRequestListState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<PurchaseRequest>? source,
    List<PurchaseRequest>? visible,
    String? searchQuery,
    Set<PurchaseRequestStatus>? statusFilter,
    PurchaseRequestSort? sort,
  }) {
    return PurchaseRequestListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      source: source ?? this.source,
      visible: visible ?? this.visible,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sort: sort ?? this.sort,
    );
  }

  static const _sentinel = Object();
}
