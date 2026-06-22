import '../../entities/customer.dart';

/// Inputs to [CustomerListBloc] (Slice 6.1.1).
sealed class CustomerListEvent {
  const CustomerListEvent();
}

class CustomerListStarted extends CustomerListEvent {
  const CustomerListStarted();
}

class CustomerListSearchChanged extends CustomerListEvent {
  const CustomerListSearchChanged(this.query);
  final String query;
}

class CustomerListStatusToggled extends CustomerListEvent {
  const CustomerListStatusToggled(this.status);
  final CustomerStatus status;
}

class CustomerListSegmentToggled extends CustomerListEvent {
  const CustomerListSegmentToggled(this.segment);
  final CustomerSegment segment;
}

class CustomerListSortChanged extends CustomerListEvent {
  const CustomerListSortChanged(this.sort);
  final CustomerSort sort;
}

class CustomerListFeedUpdated extends CustomerListEvent {
  const CustomerListFeedUpdated(this.all);
  final List<Customer> all;
}

class CustomerListFeedFailed extends CustomerListEvent {
  const CustomerListFeedFailed(this.message);
  final String message;
}
