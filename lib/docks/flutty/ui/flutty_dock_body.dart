// Flutty Dock 칸의 내용: 프로젝트 머리 → 다음 단계 배너 → 탭(실행 · 기기 · 서명 · 점검 · 기록).
// flutty-dock-flutter 의 home_screen.dart 에서 옮겼다.
//
// [Taskbench에서 달라진 곳]
//   - 앱 바·폴더 열기·끌어놓기·창 붙이기는 셸이 맡는다. Git 탭과 git 구역은 Branch Dock 과 공유 영역으로 갔다.
//   - 마지막으로 본 탭은 `flutty.last_tab_id` 로 저장한다 (탭 5개).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../workspace/workspace.dart';
import '../flutty_dock.dart';
import '../install/flutty_controller.dart';
import 'banner.dart';
import 'devices_tab.dart';
import 'doctor_tab.dart';
import '../../../core/ui/notice_banner.dart';
import 'log_tab.dart';
import 'run_tab.dart';
import 'signing_tab.dart';
import 'widgets.dart';

class FluttyDockBody extends StatefulWidget {
  const FluttyDockBody({super.key, required this.dock, required this.workspace});

  final FluttyDock dock;
  final Workspace workspace;

  @override
  State<FluttyDockBody> createState() => _FluttyDockBodyState();
}

class _FluttyDockBodyState extends State<FluttyDockBody> with SingleTickerProviderStateMixin {
  FluttyController get c => widget.dock.controller!;

  late final TabController _tabs = TabController(length: FluttyController.tabIds.length, vsync: this, initialIndex: c.tabIndex);
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    widget.dock.ensureStarted();
    // 마지막으로 보던 탭: 저장된 값은 비동기로 읽히므로 도착하면 한 번 옮기고, 이후 바뀔 때마다 저장한다.
    c.addListener(_restoreTab);
    _restored = c.tabLoaded;
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) c.setTab(_tabs.index);
    });
  }

  void _restoreTab() {
    if (_restored || !c.tabLoaded) return;
    _restored = true;
    if (_tabs.index != c.tabIndex) _tabs.index = c.tabIndex;
  }

  @override
  void dispose() {
    c.removeListener(_restoreTab);
    _tabs.dispose();
    super.dispose();
  }

  Tab _tab(IconData icon, String text) =>
      Tab(height: 54, iconMargin: const EdgeInsets.only(bottom: 2), icon: Icon(icon, size: 20), text: text);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.dock, c, widget.workspace]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FluttyProjectHeader(dock: widget.dock, workspace: widget.workspace),
          if (widget.dock.operationInProgress(widget.workspace)) NoticeBanner(text: l10n.fdOperationInProgress),
          if (widget.dock.branchChangedWhileRunning != null) _BranchChangedBanner(dock: widget.dock),
          NextStepBanner(controller: c),
          TabBar(
            controller: _tabs,
            // 도킹 폭(380~440)에서 다섯 탭이 한 줄에 균등하게 들어간다. 아이콘 위에 글자를 얹어 폭을 아낀다.
            labelPadding: EdgeInsets.zero,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            tabs: [
              _tab(Icons.play_circle_outline_rounded, l10n.fdTabInstall),
              _tab(Icons.smartphone_rounded, l10n.fdTabDevices),
              _tab(Icons.verified_outlined, l10n.fdTabSigning),
              _tab(Icons.health_and_safety_outlined, l10n.fdTabDoctor),
              _tab(Icons.history_rounded, l10n.fdTabLog),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    BuildSection(controller: c),
                    const SizedBox(height: AppSpacing.lg),
                    OutputSection(log: widget.workspace.runner.log),
                  ],
                ),
                DevicesTab(controller: c),
                SigningTab(controller: c),
                DoctorTab(controller: c),
                LogTab(log: widget.workspace.runner.log),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 위쪽 한 줄: 프로젝트 이름(여럿이면 고르기)·버전·플랫폼 칩. 브랜치·git 상태는 공유 영역에 있다.
class FluttyProjectHeader extends StatelessWidget {
  const FluttyProjectHeader({super.key, required this.dock, required this.workspace});

  final FluttyDock dock;
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = dock.selected(workspace);
    final project = dock.controller?.project;
    if (selected == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (dock.projects.length > 1)
            DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: selected.path,
              items: [
                for (final p in dock.projects)
                  DropdownMenuItem(value: p.path, child: Text(p.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (path) {
                final chosen = dock.projects.where((e) => e.path == path).firstOrNull;
                if (chosen != null) dock.choose(workspace, chosen);
              },
            )
          else
            Text(selected.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (selected.version != null) InfoChip(selected.version!),
              if (project != null) ...[
                if (project.hasIos) const InfoChip('iOS'),
                if (project.hasAndroid) const InfoChip('Android'),
                if (project.hasMacos) const InfoChip('macOS'),
                if (project.hasWindows) const InfoChip('Windows'),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchChangedBanner extends StatelessWidget {
  const _BranchChangedBanner({required this.dock});

  final FluttyDock dock;

  @override
  Widget build(BuildContext context) => NoticeBanner(
    text: AppLocalizations.of(context).fdBranchChangedWhileRunning(dock.branchChangedWhileRunning!),
    onClose: dock.dismissBranchBanner,
  );
}
