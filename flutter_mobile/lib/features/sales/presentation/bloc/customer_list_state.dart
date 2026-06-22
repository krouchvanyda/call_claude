import '../../entities/customer.dart';

class CustomerListState {
  const CustomerListState({
    this.isLoading = true,
    this.errorMessage,
    this.source = const [],
    this.visible = const [],
    this.searchQuery = '',
    this.statusFilter = const {},
    this.segmentFilter = const {},
    this.sort = CustomerSort.nameAsc,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Customer> source;
  final List<Customer> visible;
  final String searchQuery;
  final Set<CustomerStatus> statusFilter;
  final Set<CustomerSegment> segmentFilter;
  final CustomerSort sort;

  CustomerListState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<Customer>? source,
    List<Customer>? visible,
    String? searchQuery,
    Set<CustomerStatus>? statusFilter,
    Set<CustomerSegment>? segmentFilter,
    CustomerSort? sort,
  }) {
    return CustomerListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      source: source ?? this.source,
      visible: visible ?? this.visible,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      segmentFilter: segmentFilter ?? this.segmentFilter,
      sort: sort ?? this.sort,
    );
  }

  static const _sentinel = Object();
}
