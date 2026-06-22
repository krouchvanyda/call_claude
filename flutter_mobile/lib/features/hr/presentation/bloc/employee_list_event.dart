import '../../entities/employee.dart';

/// Inputs to [EmployeeListBloc] (Slice 7.1.1).
sealed class EmployeeListEvent {
  const EmployeeListEvent();
}

class EmployeeListStarted extends EmployeeListEvent {
  const EmployeeListStarted();
}

class EmployeeListSearchChanged extends EmployeeListEvent {
  const EmployeeListSearchChanged(this.query);
  final String query;
}

class EmployeeListDepartmentToggled extends EmployeeListEvent {
  const EmployeeListDepartmentToggled(this.department);
  final String department;
}

class EmployeeListStatusToggled extends EmployeeListEvent {
  const EmployeeListStatusToggled(this.status);
  final EmploymentStatus status;
}

class EmployeeListSortChanged extends EmployeeListEvent {
  const EmployeeListSortChanged(this.sort);
  final EmployeeSort sort;
}

class EmployeeListFeedUpdated extends EmployeeListEvent {
  const EmployeeListFeedUpdated(this.all);
  final List<Employee> all;
}

class EmployeeListFeedFailed extends EmployeeListEvent {
  const EmployeeListFeedFailed(this.message);
  final String message;
}
