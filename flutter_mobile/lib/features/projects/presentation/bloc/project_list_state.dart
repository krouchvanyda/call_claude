import '../../entities/project.dart';

class ProjectListState {
  const ProjectListState({
    this.isLoading = true,
    this.errorMessage,
    this.source = const [],
    this.visible = const [],
    this.searchQuery = '',
    this.statusFilter = const {},
    this.sort = ProjectSort.nameAsc,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Project> source;
  final List<Project> visible;
  final String searchQuery;
  final Set<ProjectStatus> statusFilter;
  final ProjectSort sort;

  ProjectListState copyWith({
    bool? isLoading,
    Object? errorMessage = _sentinel,
    List<Project>? source,
    List<Project>? visible,
    String? searchQuery,
    Set<ProjectStatus>? statusFilter,
    ProjectSort? sort,
  }) =>
      ProjectListState(
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

  static const _sentinel = Object();
}
