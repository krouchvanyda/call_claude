import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../data/repositories/projects_repository.dart';
import '../../entities/project.dart';
import 'project_list_event.dart';
import 'project_list_state.dart';

class ProjectListBloc extends Bloc<ProjectListEvent, ProjectListState> {
  ProjectListBloc({required ProjectsRepository repository})
      : _repository = repository,
        super(const ProjectListState()) {
    on<ProjectListStarted>(_onStarted);
    on<ProjectListSearchChanged>(_onSearchChanged);
    on<ProjectListStatusToggled>(_onStatusToggled);
    on<ProjectListSortChanged>(_onSortChanged);
    on<ProjectListFeedUpdated>(_onFeedUpdated);
    on<ProjectListFeedFailed>(_onFeedFailed);
  }

  final ProjectsRepository _repository;
  StreamSubscription<List<Project>>? _sub;

  Future<void> _onStarted(
    ProjectListStarted event,
    Emitter<ProjectListState> emit,
  ) async {
    if (_sub != null) return;
    _sub = _repository.watchAll().listen(
          (list) => add(ProjectListFeedUpdated(list)),
          onError: (Object e) =>
              add(ProjectListFeedFailed(e.toString())),
        );
  }

  void _onFeedUpdated(
    ProjectListFeedUpdated event,
    Emitter<ProjectListState> emit,
  ) {
    emit(_recompute(state.copyWith(
      source: event.all,
      isLoading: false,
      errorMessage: null,
    )));
  }

  void _onFeedFailed(
    ProjectListFeedFailed event,
    Emitter<ProjectListState> emit,
  ) {
    emit(state.copyWith(isLoading: false, errorMessage: event.message));
  }

  void _onSearchChanged(
    ProjectListSearchChanged event,
    Emitter<ProjectListState> emit,
  ) {
    emit(_recompute(state.copyWith(searchQuery: event.query)));
  }

  void _onStatusToggled(
    ProjectListStatusToggled event,
    Emitter<ProjectListState> emit,
  ) {
    final next = Set<ProjectStatus>.of(state.statusFilter);
    if (!next.remove(event.status)) next.add(event.status);
    emit(_recompute(state.copyWith(statusFilter: next)));
  }

  void _onSortChanged(
    ProjectListSortChanged event,
    Emitter<ProjectListState> emit,
  ) {
    emit(_recompute(state.copyWith(sort: event.sort)));
  }

  ProjectListState _recompute(ProjectListState s) {
    return s.copyWith(
      visible: applyProjectQuery(
        s.source,
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
