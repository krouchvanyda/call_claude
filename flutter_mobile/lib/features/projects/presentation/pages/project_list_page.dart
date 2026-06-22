import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/config_router.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/dynamic_app_bar.dart';
import '../../../../core/widgets/dynamic_status_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_background_gradient.dart';
import '../../data/repositories/projects_repository.dart';
import '../../entities/project.dart';
import '../bloc/project_list_bloc.dart';
import '../bloc/project_list_event.dart';
import '../bloc/project_list_state.dart';
import '../widgets/gantt_chart.dart';
import 'project_detail_page.dart';
import 'project_form_page.dart';
import 'timesheets_list_page.dart';

/// Slice 8.1.1 — project list with toggleable Gantt timeline.
class ProjectListPage extends StatelessWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectListBloc>(
      create: (_) =>
          GetIt.I<ProjectListBloc>()..add(const ProjectListStarted()),
      child: const _ProjectListView(),
    );
  }
}

enum _Mode { list, gantt }

class _ProjectListView extends StatefulWidget {
  const _ProjectListView();

  @override
  State<_ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState extends State<_ProjectListView> {
  _Mode _mode = _Mode.list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: DynamicAppBar(
        title: l10n.projectListPageTitle,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.projectListTimesheetsTooltip,
            icon: const Icon(Icons.schedule),
            onPressed: () =>
                ConfigRouter.pushPageAnimation(context, const TimesheetsListPage()),
          ),
          PopupMenuButton<ProjectSort>(
            tooltip: l10n.projectListSortTooltip,
            icon: const Icon(Icons.sort),
            onSelected: (s) => context
                .read<ProjectListBloc>()
                .add(ProjectListSortChanged(s)),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: ProjectSort.nameAsc,
                child: AppLabel(
                  text: l10n.projectListSortNameAz,
                  fontSize: AppFontSize.value14,
                ),
              ),
              PopupMenuItem(
                value: ProjectSort.recentlyStarted,
                child: AppLabel(
                  text: l10n.projectListSortRecentlyStarted,
                  fontSize: AppFontSize.value14,
                ),
              ),
              PopupMenuItem(
                value: ProjectSort.dueSoonest,
                child: AppLabel(
                  text: l10n.projectListSortDueSoonest,
                  fontSize: AppFontSize.value14,
                ),
              ),
            ],
          ),
        ],
      ),
      body: DynamicStatusBar(
        child: Stack(
          children: [
            const AppBackgroundGradient(),
            BlocBuilder<ProjectListBloc, ProjectListState>(
              builder: (context, state) {
                if (state.isLoading && state.source.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.errorMessage != null) {
                  return Center(
                    child: AppLabel(
                      text: l10n.projectListErrorMessage(state.errorMessage!),
                      fontSize: AppFontSize.value14,
                      color: theme.colorScheme.error,
                    ),
                  );
                }
                return Column(
                  children: [
                    SizedBox(height: context.dynamicAppBarPadding),
                    // Search & View Mode Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SegmentedButton<_Mode>(
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                              segments: [
                                ButtonSegment(
                                  value: _Mode.list,
                                  icon: const Icon(Icons.list_rounded),
                                  label: AppLabel(
                                    text: l10n.projectListViewListAction,
                                    fontSize: AppFontSize.value13,
                                  ),
                                ),
                                ButtonSegment(
                                  value: _Mode.gantt,
                                  icon: const Icon(Icons.analytics_outlined),
                                  label: AppLabel(
                                    text: l10n.projectListViewGanttAction,
                                    fontSize: AppFontSize.value13,
                                  ),
                                ),
                              ],
                              selected: {_mode},
                              onSelectionChanged: (s) =>
                                  setState(() => _mode = s.first),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              onChanged: (q) => context
                                  .read<ProjectListBloc>()
                                  .add(ProjectListSearchChanged(q)),
                              decoration: InputDecoration(
                                hintText: l10n.projectListSearchHint,
                                prefixIcon: const Icon(Icons.search_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                ),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.05, end: 0, duration: 250.ms),
                    ),
                    const SizedBox(height: 12),
                    // Status Filter Chips
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: ProjectStatus.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final s = ProjectStatus.values[idx];
                          final isSelected = state.statusFilter.contains(s);
                          return FilterChip(
                            label: AppLabel(
                              text: s.name.toUpperCase(),
                              fontSize: AppFontSize.value11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              letterSpacing: 0.5,
                            ),
                            selected: isSelected,
                            onSelected: (_) => context
                                .read<ProjectListBloc>()
                                .add(ProjectListStatusToggled(s)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                          );
                        },
                      ),
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: 12),
                    if (state.visible.isEmpty)
                      Expanded(
                        child: Center(
                          child: AppLabel(
                            text: l10n.projectListEmpty,
                            fontSize: AppFontSize.value14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: _mode == _Mode.list
                            ? _buildList(state.visible)
                            : _buildGantt(state.visible),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ConfigRouter.pushPageAnimation(
          context,
          const ProjectFormPage(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: AppLabel(
          text: l10n.projectListNewProjectAction,
          fontSize: AppFontSize.value14,
          fontWeight: FontWeight.w600,
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildList(List<Project> projects) {
    return ListView.builder(
      // Extra bottom padding so the last tile isn't covered by the FAB.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: projects.length,
      itemBuilder: (_, idx) => _ProjectRow(project: projects[idx])
          .animate()
          .fadeIn(delay: (idx * 50).ms)
          .slideY(begin: 0.05, end: 0, duration: 300.ms),
    );
  }

  Widget _buildGantt(List<Project> projects) {
    final now = DateTime.now();
    final windowStart = DateTime.utc(now.year, now.month, 1)
        .subtract(const Duration(days: 30));
    final windowEnd = windowStart.add(const Duration(days: 180));
    final rows = computeGanttLayout(
      projects: projects,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    return GanttChart(
      rows: rows,
      windowStart: windowStart,
      windowEnd: windowEnd,
      onTap: (project) => ConfigRouter.pushPageAnimation(
        context,
        ProjectDetailPage(projectId: project.id),
      ),
    ).animate().fadeIn();
  }
}

class _ProjectRow extends StatelessWidget {
  const _ProjectRow({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(project.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ConfigRouter.pushPageAnimation(
              context,
              ProjectDetailPage(projectId: project.id),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          color: _projectColor(project.color).withValues(alpha: 0.1),
                          border: Border.all(
                            color: _projectColor(project.color).withValues(alpha: 0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: AppLabel(
                          text: project.code.split('-').first.substring(
                              0, project.code.split('-').first.length.clamp(0, 3)),
                          fontSize: AppFontSize.value12,
                          color: _projectColor(project.color),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppLabel(
                              text: project.name,
                              fontSize: AppFontSize.value16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            const SizedBox(height: 2),
                            AppLabel(
                              text: l10n.projectListCodeOwnerSubtitle(project.code, project.ownerName),
                              fontSize: AppFontSize.value12,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          border: Border.all(color: statusColor.withValues(alpha: 0.15)),
                        ),
                        child: AppLabel(
                          text: project.status.name.toUpperCase(),
                          fontSize: AppFontSize.value10,
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 6),
                          AppLabel(
                            text:
                                '${project.startDate.toIso8601String().split('T').first} to ${project.endDate.toIso8601String().split('T').first}',
                            fontSize: AppFontSize.value12,
                            color: theme.colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AppLabel(
                          text: '${project.totalDays} Days',
                          fontSize: AppFontSize.value11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _projectColor(String? hex) {
    if (hex == null || hex.length != 6) return Colors.indigo;
    return Color(int.parse('FF$hex', radix: 16));
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.planning:
        return Colors.blue;
      case ProjectStatus.active:
        return Colors.green;
      case ProjectStatus.onHold:
        return Colors.orange;
      case ProjectStatus.completed:
        return Colors.teal;
      case ProjectStatus.archived:
        return Colors.grey;
    }
  }
}
