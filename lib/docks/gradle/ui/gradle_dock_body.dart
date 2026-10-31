// Gradle Runner 칸의 내용: 프로젝트 머리 → 안내 줄 → 탭(Run · Devices · Log). Doctor 탭은 이어지는 단계에서 붙는다.

import 'package:flutter/material.dart';

import '../../../core/ui/device_list.dart';
import '../../../core/ui/info_chip.dart';
import '../../../core/ui/log_tab.dart';
import '../../../core/ui/notice_banner.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../workspace/workspace.dart';
import '../gradle_dock.dart';
import 'gradle_doctor_tab.dart';
import 'gradle_run_tab.dart';

class GradleDockBody extends StatefulWidget {
  const GradleDockBody({super.key, required this.dock, required this.workspace});

  final GradleDock dock;
  final Workspace workspace;

  @override
  State<GradleDockBody> createState() => _GradleDockBodyState();
}

class _GradleDockBodyState extends State<GradleDockBody> with TickerProviderStateMixin {
  TabController? _tabs;

  @override
  void initState() {
    super.initState();
    // 칸이 처음 펼쳐질 때에야 기기 목록을 읽는다 (프로세스를 띄우는 일은 여기서부터).
    widget.dock.ensureStarted();
  }

  /// 탭 개수는 프로젝트 모양에 따라 다르다 (Android 앱: Run·Devices·Doctor·Log, JVM: Run·Doctor·Log).
  TabController _controllerFor(int length, int initial) {
    final t = _tabs;
    if (t != null && t.length == length) return t;
    t?.dispose();
    return _tabs = TabController(length: length, vsync: this, initialIndex: initial.clamp(0, length - 1));
  }

  @override
  void dispose() {
    _tabs?.dispose();
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
        final android = c.isAndroid;
        final tabs = _controllerFor(android ? 4 : 3, 0);
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
                      InfoChip(android ? l10n.grShapeAndroid : l10n.grShapeJvm),
                      if (selected.version != null) InfoChip(selected.version!),
                      InfoChip(project.hasWrapper ? l10n.grWrapperFound : l10n.grWrapperMissing),
                    ]),
                  if (project?.readError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(l10n.grReadFailed(project!.readError!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
                    ),
                ],
              ),
            ),
            if (dock.operationInProgress(w)) NoticeBanner(text: l10n.fdOperationInProgress),
            if (dock.branchChangedWhileRunning != null)
              NoticeBanner(text: l10n.grBranchChangedWhileRunning(dock.branchChangedWhileRunning!), onClose: dock.dismissBranchBanner),
            TabBar(
              controller: tabs,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              tabs: [
                _tab(Icons.play_circle_outline_rounded, l10n.grTabRun),
                if (android) _tab(Icons.smartphone_rounded, l10n.grTabDevices),
                _tab(Icons.health_and_safety_outlined, l10n.grTabDoctor),
                _tab(Icons.history_rounded, l10n.grTabLog),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: tabs,
                children: [
                  GradleRunTab(controller: c, log: w.runner.log, onOpenDoctor: () => tabs.animateTo(android ? 2 : 1)),
                  if (android)
                    ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        DeviceListSection(
                          devices: c.devices,
                          selectedId: c.selectedId,
                          loading: c.loadingDevices,
                          onRefresh: c.refreshDevices,
                          onSelect: c.selectDevice,
                        ),
                      ],
                    ),
                  GradleDoctorTab(controller: c),
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
