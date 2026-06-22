import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/employees_repository.dart';
import '../../entities/employee.dart';
import 'employee_list_event.dart';
import 'employee_list_state.dart';

/// Bloc for the employee directory (Slice 7.1.1). Mirrors
/// [CustomerListBloc] / [InvoiceListBloc] — events route inputs, the
/// pure [`applyEmployeeQuery`] computes visible rows.
class EmployeeListBloc extends Bloc<EmployeeListEvent, EmployeeListState> {
  EmployeeListBloc({required EmployeesRepository repository})
      : _repository = repository,
        super(const EmployeeListState()) {
    on<EmployeeListStarted>(_onStarted);
    on<EmployeeListSearchChanged>(_onSearchChanged);
    on<EmployeeListDepartmentToggled>(_onDepartmentToggled);
    on<EmployeeListStatusToggled>(_onStatusToggled);
    on<EmployeeListSortChanged>(_onSortChanged);
    on<EmployeeListFeedUpdated>(_onFeedUpdated);
    on<EmployeeListFeedFailed>(_onFeedFailed);
  }

  final EmployeesRepository _repository;
  StreamSubscription<List<Employee>>? _sub;

  Future<void> _onStarted(
    EmployeeListStarted event,
    Emitter<EmployeeListState> emit,
  ) async {
    if (_sub != null) return;
    _sub = _repository.watchAll().listen(
          (list) => add(EmployeeListFeedUpdated(list)),
          onError: (Object e) => add(EmployeeListFeedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    EmployeeListFeedUpdated event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(_recompute(state.copyWith(
      source: event.all,
      departments: extractDepartments(event.all),
      isLoading: false,
      errorMessage: null,
    )));
  }

  void _onFeedFailed(
    EmployeeListFeedFailed event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  void _onSearchChanged(
    EmployeeListSearchChanged event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(_recompute(state.copyWith(searchQuery: event.query)));
  }

  void _onDepartmentToggled(
    EmployeeListDepartmentToggled event,
    Emitter<EmployeeListState> emit,
  ) {
    final next = Set<String>.of(state.departmentFilter);
    if (!next.remove(event.department)) next.add(event.department);
    emit(_recompute(state.copyWith(departmentFilter: next)));
  }

  void _onStatusToggled(
    EmployeeListStatusToggled event,
    Emitter<EmployeeListState> emit,
  ) {
    final next = Set<EmploymentStatus>.of(state.statusFilter);
    if (!next.remove(event.status)) next.add(event.status);
    emit(_recompute(state.copyWith(statusFilter: next)));
  }

  void _onSortChanged(
    EmployeeListSortChanged event,
    Emitter<EmployeeListState> emit,
  ) {
    emit(_recompute(state.copyWith(sort: event.sort)));
  }

  EmployeeListState _recompute(EmployeeListState s) {
    return s.copyWith(
      visible: applyEmployeeQuery(
        s.source,
        departmentFilter: s.departmentFilter,
        statusFilter: s.statusFilter,
        searchQuery: s.searchQuery,
        sort: s.sort,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
