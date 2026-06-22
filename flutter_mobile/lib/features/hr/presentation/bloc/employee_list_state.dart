import '../../entities/employee.dart';

class EmployeeListState {
  const EmployeeListState({
    this.isLoading = true,
    this.errorMessage,
    this.source = const [],
    this.visible = const [],
    this.departments = const [],
    this.searchQuery = '',
    this.departmentFilter = const {},
    this.statusFilter = const {},
    this.sort = EmployeeSort.nameAsc,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Employee> source;
  final List<Employee> visible;
  final List<String> departments;
  final String searchQuery;
  final Set<String> departmentFilter;
  final Set<EmploymentStatus> statusFilter;
  final EmployeeSort sort;

  EmployeeListState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<Employee>? source,
    List<Employee>? visible,
    List<String>? departments,
    String? searchQuery,
    Set<String>? departmentFilter,
    Set<EmploymentStatus>? statusFilter,
    EmployeeSort? sort,
  }) =>
      EmployeeListState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
        source: source ?? this.source,
        visible: visible ?? this.visible,
        departments: departments ?? this.departments,
        searchQuery: searchQuery ?? this.searchQuery,
        departmentFilter: departmentFilter ?? this.departmentFilter,
        statusFilter: statusFilter ?? this.statusFilter,
        sort: sort ?? this.sort,
      );

  static const _sentinel = Object();
}
