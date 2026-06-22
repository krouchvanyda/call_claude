import '../../entities/project.dart';

sealed class ProjectListEvent {
  const ProjectListEvent();
}

class ProjectListStarted extends ProjectListEvent {
  const ProjectListStarted();
}

class ProjectListSearchChanged extends ProjectListEvent {
  const ProjectListSearchChanged(this.query);
  final String query;
}

class ProjectListStatusToggled extends ProjectListEvent {
  const ProjectListStatusToggled(this.status);
  final ProjectStatus status;
}

class ProjectListSortChanged extends ProjectListEvent {
  const ProjectListSortChanged(this.sort);
  final ProjectSort sort;
}

class ProjectListFeedUpdated extends ProjectListEvent {
  const ProjectListFeedUpdated(this.all);
  final List<Project> all;
}

class ProjectListFeedFailed extends ProjectListEvent {
  const ProjectListFeedFailed(this.message);
  final String message;
}
