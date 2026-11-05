// Avalonia Runner 칸의 내용: 프로젝트 머리 → 안내 줄 → 탭(실행 · 점검 · 기록).

import 'package:flutter/material.dart';

import '../../../core/ui/info_chip.dart';
import '../../../core/ui/log_tab.dart';
import '../../../core/ui/notice_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../workspace/workspace.dart';
import '../avalonia_dock.dart';
import 'avalonia_doctor_tab.dart';
import 'avalonia_run_tab.dart';

class AvaloniaDockBody extends StatefulWidget {
  const AvaloniaDockBody({super.key, required this.dock, required this.workspace});

  final AvaloniaDock dock;
  final Workspace workspace;

  @override
  State<AvaloniaDockBody> createState() => _AvaloniaDockBodyState();
}

class _AvaloniaDockBodyState extends State<AvaloniaDockBody> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // 칸이 처음 펼쳐질 때에야 환경 점검을 한다 (프로세스를 띄우는 일은 여기서부터).
    widget.dock.ensureStarted();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Tab _tab(IconData icon, String text) => Tab(height: 54, iconMargin: const EdgeInsets.only(bottom: 2), icon: Icon(icon, size: 20), text: text);

  @override
  Widget build(BuildContext context) {
    final dock = widget.dock;
    final w = widget.workspace;
    final c = dock.controller;
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([dock, ?c, w]),
      builder: (context, _) {
        final selected = dock.selected(w);
        final project = dock.project;
        if (selected == null || c == null) return const SizedBox.shrink();
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dock.projects.length > 1)
                    DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      value: selected.path,
                      items: [for (final p in dock.projects) DropdownMenuItem(value: p.path, child: Text(p.name, overflow: TextOverflow.ellipsis))],
                      onChanged: (path) {
                        final chosen = dock.projects.where((e) => e.path == path).firstOrNull;
                        if (chosen != null) dock.choose(w, chosen);
                      },
                    )
                  else
                    Text(selected.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  if (project != null)
                    Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                      InfoChip(l10n.avShape),
                      if (selected.version != null) InfoChip(selected.version!),
                      InfoChip(project.solution ?? l10n.avNoSolution),
                    ]),
                  if (project?.readError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(l10n.avReadFailed(project!.readError!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                ],
              ),
            ),
            if (dock.operationInProgress(w)) NoticeBanner(text: l10n.fdOperationInProgress),
            if (dock.branchChangedWhileRunning != null)
              NoticeBanner(text: l10n.grBranchChangedWhileRunning(dock.branchChangedWhileRunning!), onClose: dock.dismissBranchBanner),
            TabBar(
              controller: _tabs,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: [
                _tab(Icons.play_circle_outline_rounded, l10n.avTabRun),
                _tab(Icons.health_and_safety_outlined, l10n.grTabDoctor),
                _tab(Icons.history_rounded, l10n.avTabLog),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  AvaloniaRunTab(controller: c, log: w.runner.log),
                  AvaloniaDoctorTab(controller: c),
                  LogTab(log: w.runner.log),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
