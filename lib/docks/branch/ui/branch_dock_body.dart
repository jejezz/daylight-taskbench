// Branch Dock 칸의 내용 — branch-dock-flutter 의 main_screen.dart 에서 옮겼다 (PLAN.md 단계 3).
//
// [Taskbench에서 달라진 곳]
//   - 앱 바·시작 화면·끌어놓기·저장소 열기·항상 위·창 붙이기는 셸(lib/ui/shell/)이 맡는다.
//   - 열린 저장소(RepoController)는 Workspace 가 소유한다 — 이 위젯은 만들지도 닫지도 않고, 저장소가
//     바뀌면 ReleaseFlow 와 탭 상태만 새로 한다.
//   - 상태 헤더의 브랜치 칩·pill·편집기 단추는 공유 영역으로 올라갔다 (status_header.dart 참고).
//   - 칸이 접혀 있어도 이 위젯은 살아 있어 자동 fetch·릴리스 진행 감시가 이어진다.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import '../branch_dock.dart';
import '../git/commands.dart';
import '../github/models.dart';
import '../release/release_flow.dart';
import '../release/repo_release_info.dart';
import '../repo/next_action.dart';
import '../repo/repo_controller.dart';
import '../repo/repo_prefs.dart';
import 'command_bar.dart';
import 'command_palette.dart';
import 'recovery_sheet.dart';
import 'repo_actions.dart';
import 'repo_scope.dart';
import 'services.dart';
import 'shortcut_label.dart';
import 'status_header.dart';
import 'tabs/actions_tab.dart';
import 'tabs/branches_tab.dart';
import 'tabs/changes_tab.dart';
import 'tabs/history_tab.dart';
import 'tabs/pr_tab.dart';
import 'tabs/release_tab.dart';
import 'tabs/remotes_tab.dart';
import 'tabs/tags_tab.dart';

/// 변경 · 브랜치 · 태그 · 원격 · 릴리스 · PR · CI · 기록 (UI_UX.md §3 D).
/// 기록은 v0.4.0에 더해 맨 뒤에 둔다 — 기존 ⌘1–7이 바뀌지 않게.
const branchTabCount = 8;
const branchTabChanges = 0, branchTabBranches = 1, branchTabTags = 2, branchTabRemotes = 3, branchTabRelease = 4;

/// 이 너비 이상이면 넓은 창 배치 (왼쪽 레일 + 오른쪽 내용).
const wideLayoutWidth = 840.0;

class BranchDockBody extends StatefulWidget {
  const BranchDockBody({super.key, required this.workspace, required this.dock});

  final Workspace workspace;
  final BranchDock dock;

  @override
  State<BranchDockBody> createState() => _BranchDockBodyState();
}

class _BranchDockBodyState extends State<BranchDockBody> with TickerProviderStateMixin, WindowListener {
  late final AppServices _services = AppServices(runner: ws.runner, prefs: RepoPrefs(ws.prefs));
  RepoController? _repo;
  ReleaseFlow? _flow;
  bool _logExpanded = false;
  final _dismissed = <String>{};
  int _epoch = 0;
  final _commitFocus = FocusNode();
  late final TabController _tabs = TabController(length: branchTabCount, vsync: this);

  /// 자동 fetch (PLAN.md 3.3 P1): 5분마다, 그리고 창으로 돌아올 때.
  Timer? _autoFetch;

  Workspace get ws => widget.workspace;
  BranchDock get dock => widget.dock;
  bool get _isDesktop => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) windowManager.addListener(this);
    _tabs.addListener(() {
      final repo = _repo;
      if (repo != null && !_tabs.indexIsChanging) _services.prefs.setLastTab(repo.root, _tabs.index);
    });
    ws.addListener(_sync);
    dock.addListener(_onDock);
    _epoch = dock.epoch;
    _autoFetch = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_services.prefs.autoFetch) _repo?.backgroundFetch();
    });
    _sync();
  }

  /// [Taskbench에서 달라진 곳] 본문이 저장소(RepoController)를 직접 듣는다. Workspace 는 GitState 가 바뀔 때만
  /// 알리므로(branch·ahead·changed …) 진행 표시줄(busy)이나 태그·원격·PR 같은 값만 바뀌면 본문이 다시 그려지지
  /// 않아, 이미 최신인 `git pull` 처럼 상태가 그대로인 작업이 끝나도 진행 표시줄이 남았다.
  void _onRepo() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repo?.removeListener(_onRepo);
    if (_isDesktop) windowManager.removeListener(this);
    _autoFetch?.cancel();
    ws.removeListener(_sync);
    dock.removeListener(_onDock);
    _flow?.dispose();
    _tabs.dispose();
    _commitFocus.dispose();
    super.dispose();
  }

  /// 공유 영역 등 바깥에서 온 요청: 탭으로 가기, 브랜치 전환 뒤 안내 초기화.
  void _onDock() {
    final t = dock.takeTabRequest();
    if (t != null && _repo != null) _tabs.animateTo(t.clamp(0, branchTabCount - 1));
    if (dock.epoch != _epoch) {
      _epoch = dock.epoch;
      setState(_dismissed.clear); // 브랜치가 바뀌면 닫아 둔 안내를 다시 보인다
    }
  }

  /// Workspace 의 저장소가 바뀌었으면 ReleaseFlow·탭을 새로 한다.
  void _sync() {
    final repo = ws.repo;
    if (repo == _repo) {
      if (mounted) setState(() {});
      return;
    }
    _flow?.dispose();
    _flow = null;
    _repo?.removeListener(_onRepo);
    _repo = repo;
    repo?.addListener(_onRepo);
    if (repo != null) {
      final flow = ReleaseFlow(repo, ghReady: ws.environment.ghReady)
        ..onRunFinished = _onReleaseRunFinished
        ..customVersionFile = _services.prefs.customVersionFile(repo.root);
      repo.ghReady = ws.environment.ghReady;
      unawaited(repo.loadHeadPr());
      _flow = flow;
      _dismissed.clear();
      _tabs.index = _services.prefs.lastTab(repo.root).clamp(0, branchTabCount - 1);
      // 진행 중이던 릴리스가 있으면 이어서 연다 (UI_UX.md §4.5).
      flow.resume().then((resumed) {
        if (resumed && mounted && _flow == flow) _tabs.index = branchTabRelease;
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void onWindowFocus() {
    // 다른 앱(편집기, 터미널, 브라우저)에서 돌아오면 상태를 다시 읽는다.
    _repo?.refresh();
    _repo?.loadHeadPr();
    if (_services.prefs.autoFetch) _repo?.backgroundFetch();
    _flow?.poll();
  }

  /// 릴리스 CI·수동 빌드가 끝나면 창이 뒤에 있을 때 OS 알림 (PLAN.md 3.8.5).
  void _onReleaseRunFinished(WorkflowRun run, {required bool manualBuild}) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final state = runStateLabel(l10n, run.state);
    _services.notifyIfAway(
      manualBuild ? l10n.bdNotifyManualBuild(state) : l10n.bdNotifyReleaseRun(_flow?.tag ?? '', state),
      _repo?.name ?? '',
    );
  }

  Future<void> _openPath(String path) => ws.requestOpen(path);

  /// 릴리스 탭으로 가서 마법사를 시작한다 (⌘⇧R, 태그 탭의 버전 불일치 안내).
  void _openReleaseWizard() {
    final repo = _repo;
    final flow = _flow;
    if (repo == null || flow == null) return;
    _tabs.animateTo(branchTabRelease);
    if (flow.checks.isEmpty &&
        flow.step == ReleaseStep.check &&
        repo.githubRemote != null &&
        ws.environment.ghReady &&
        missingReleaseFiles(repo.root).isEmpty) {
      flow.ghReady = ws.environment.ghReady;
      flow.runChecks();
    }
  }

  void _dismiss(String key) => setState(() => _dismissed.add(key));

  /// 명령 팔레트 (⌘K, PLAN.md 3.12 P2): 동작·탭·브랜치 전환·최근 저장소.
  void _openPalette(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = _repo;
    final actions = l10n.bdPaletteGroupActions;
    final env = ws.environment;
    final items = <PaletteItem>[
      PaletteItem(title: l10n.bdMenuOpenFolder, icon: Icons.folder_open_rounded, group: actions, shortcut: shortcutLabel('O'), onRun: ws.requestPickFolder, keywords: 'open'),
      if (repo != null) ...[
        PaletteItem(title: l10n.bdAppBarRefresh, icon: Icons.refresh_rounded, group: actions, shortcut: shortcutLabel('R'), onRun: repo.refresh, keywords: 'refresh reload'),
        PaletteItem(title: l10n.bdHeaderFetch, icon: Icons.sync_rounded, group: actions, shortcut: shortcutLabel('F', shift: true), onRun: () => RepoActions.fetch(context, repo), enabled: repo.remotes.isNotEmpty, keywords: 'fetch'),
        PaletteItem(title: l10n.bdHeaderPull, icon: Icons.south_rounded, group: actions, shortcut: shortcutLabel('P', shift: true), onRun: () => RepoActions.pull(context, repo), enabled: repo.status.hasUpstream, keywords: 'pull'),
        PaletteItem(title: repo.needsPublish ? l10n.bdHeaderPublish : l10n.bdHeaderPush, icon: Icons.north_rounded, group: actions, shortcut: shortcutLabel('P'), onRun: () => RepoActions.push(context, repo), enabled: repo.remotes.isNotEmpty && !repo.status.detached, keywords: 'push publish'),
        PaletteItem(title: l10n.bdPushOptionsTitle, icon: Icons.tune_rounded, group: actions, onRun: () => showPushOptionsSheet(context, repo), keywords: 'push force tags'),
        PaletteItem(title: l10n.bdBranchesNew, icon: Icons.add_rounded, group: actions, shortcut: shortcutLabel('B'), onRun: () => showCreateBranchSheet(context, repo), enabled: !repo.status.unborn, keywords: 'branch create'),
        PaletteItem(title: l10n.bdTagsNew, icon: Icons.sell_outlined, group: actions, shortcut: shortcutLabel('T'), onRun: () => showCreateTagSheet(context, repo, onOpenReleaseWizard: _openReleaseWizard), enabled: !repo.status.unborn, keywords: 'tag create'),
        PaletteItem(title: l10n.bdReleaseStart, icon: Icons.rocket_launch_outlined, group: actions, shortcut: shortcutLabel('R', shift: true), onRun: _openReleaseWizard, keywords: 'release'),
        PaletteItem(title: l10n.bdStashSave, icon: Icons.inventory_2_outlined, group: actions, onRun: () => showStashSheet(context, repo), enabled: !repo.status.clean, keywords: 'stash'),
        PaletteItem(title: l10n.bdRecoveryTitle, icon: Icons.restore_rounded, group: actions, onRun: () => showRecoverySheet(context, repo), enabled: !repo.status.unborn, keywords: 'undo reset reflog recover mistake'),
        PaletteItem(title: l10n.bdBranchesCleanup, icon: Icons.cleaning_services_outlined, group: actions, onRun: () => showCleanupSheet(context, repo), keywords: 'cleanup prune'),
        if (repo.githubRemote != null && env.ghReady && !repo.status.detached && repo.status.head != repo.defaultBranch)
          PaletteItem(title: l10n.bdPrCreate, icon: Icons.merge_rounded, group: actions, onRun: () => showCreatePrSheet(context, repo), keywords: 'pr pull request'),
        if (repo.githubRemote != null && env.ghReady)
          PaletteItem(title: l10n.bdMenuBrowse, icon: Icons.open_in_new_rounded, group: actions, onRun: () => _services.runner.run(GhCommands.browse, workingDirectory: repo.root), keywords: 'browse github web'),
      ],
      PaletteItem(title: l10n.bdLogToggleTooltip, icon: Icons.terminal_rounded, group: actions, shortcut: shortcutLabel('J'), onRun: () => setState(() => _logExpanded = !_logExpanded), keywords: 'log'),
      if (repo != null) ...[
        for (final (i, name) in [
          l10n.bdTabChanges, l10n.bdTabBranches, l10n.bdTabTags, l10n.bdTabRemotes, l10n.bdTabRelease, l10n.bdTabPr, l10n.bdTabCi, l10n.bdTabHistory,
        ].indexed)
          PaletteItem(
            title: l10n.bdPaletteGoToTab(name),
            icon: Icons.tab_rounded,
            group: l10n.bdPaletteGroupTabs,
            shortcut: shortcutLabel('${i + 1}'),
            onRun: () => _tabs.animateTo(i),
          ),
        for (final b in repo.localBranches.where((b) => !b.current))
          PaletteItem(
            title: l10n.bdPaletteSwitchTo(b.name),
            icon: Icons.call_split_rounded,
            group: l10n.bdPaletteGroupBranches,
            keywords: 'switch checkout',
            onRun: () => RepoActions.withStashRetry(context, repo, () => repo.switchTo(b), done: l10n.bdDoneSwitch(b.name), openRepo: _openPath),
          ),
      ],
      for (final path in ws.recent.where((p) => p != repo?.root))
        PaletteItem(
          title: path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last,
          icon: Icons.folder_outlined,
          group: l10n.bdPaletteGroupRepos,
          keywords: path,
          onRun: () => _openPath(path),
        ),
    ];
    showCommandPalette(context, items);
  }

  // --- 단축키 (UI_UX.md §7) — 칸 안에 포커스가 있을 때만. ⌘O·⌘R 은 셸이 맡는다. -----------

  Map<ShortcutActivator, VoidCallback> _shortcuts(BuildContext context) {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    SingleActivator key(LogicalKeyboardKey k, {bool shift = false, bool alt = false}) =>
        SingleActivator(k, meta: mac, control: !mac, shift: shift, alt: alt);
    final repo = _repo;
    return {
      key(LogicalKeyboardKey.keyK): () => _openPalette(context),
      key(LogicalKeyboardKey.keyJ): () => setState(() => _logExpanded = !_logExpanded),
      if (repo != null) ...{
        const SingleActivator(LogicalKeyboardKey.f5): repo.refresh,
        for (var i = 0; i < branchTabCount; i++) key(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () => _tabs.animateTo(i),
        key(LogicalKeyboardKey.keyT): () {
          if (repo.status.unborn) return;
          _tabs.animateTo(branchTabTags);
          showCreateTagSheet(context, repo, onOpenReleaseWizard: _openReleaseWizard);
        },
        key(LogicalKeyboardKey.keyR, shift: true): _openReleaseWizard,
        key(LogicalKeyboardKey.keyP): () => RepoActions.push(context, repo),
        key(LogicalKeyboardKey.keyP, shift: true): () => RepoActions.pull(context, repo),
        key(LogicalKeyboardKey.keyF, shift: true): () => RepoActions.fetch(context, repo),
        key(LogicalKeyboardKey.keyB): () {
          if (!repo.status.unborn) showCreateBranchSheet(context, repo);
        },
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final repo = _repo;
    return ServicesScope(
      services: _services,
      child: CallbackShortcuts(
        bindings: _shortcuts(context),
        child: Column(children: [
          Expanded(
            child: repo == null
                ? const SizedBox.shrink() // 저장소가 닫히는 순간(또는 테스트의 가짜 원본)
                : RepoScope(
                    repo: repo,
                    environment: ws.environment,
                    openRepo: _openPath,
                    child: _repoView(context, repo),
                  ),
          ),
          CommandBar(
            log: _services.log,
            expanded: _logExpanded,
            onToggle: () => setState(() => _logExpanded = !_logExpanded),
            onCancel: repo?.cancel,
          ),
        ]),
      ),
    );
  }

  Widget _repoView(BuildContext context, RepoController repo) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final flow = _flow;
    if (!repo.loaded || flow == null) return const Center(child: CircularProgressIndicator());

    final next = suggestNextAction(
      status: repo.status,
      remotes: repo.remotes,
      headMergedAndGone: repo.headMergedAndGone,
      suggestPr: repo.shouldSuggestPr,
    );
    final showNext = next != null && !_dismissed.contains(next.key);
    final host = repo.primaryHost;
    final notGitHub = host != null && repo.githubRemote == null;
    final notGitHubKey = 'host:${repo.root}';

    // 840px 이상이면 탭 막대 대신 왼쪽 섹션 레일 (UI_UX.md §2 넓은 창).
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= wideLayoutWidth;
    final labels = [
      l10n.bdTabChanges,
      l10n.bdTabBranches,
      l10n.bdTabTags,
      l10n.bdTabRemotes,
      l10n.bdTabRelease,
      l10n.bdTabPr,
      l10n.bdTabCi,
      l10n.bdTabHistory,
    ];
    Widget icon(int i) => switch (i) {
          0 => Badge(
              isLabelVisible: repo.status.changedCount > 0,
              label: Text('${repo.status.changedCount}'),
              child: const Icon(Icons.edit_note_rounded, size: 20),
            ),
          1 => const Icon(Icons.call_split_rounded, size: 20),
          2 => const Icon(Icons.sell_outlined, size: 20),
          3 => const Icon(Icons.cloud_outlined, size: 20),
          4 => ListenableBuilder(
              listenable: flow,
              builder: (context, _) {
                // 진행 중인 릴리스가 있으면 점으로 알린다 (UI_UX.md §3 D).
                final active = flow.step != ReleaseStep.check && flow.step != ReleaseStep.done;
                return Badge(isLabelVisible: active, smallSize: 8, child: const Icon(Icons.rocket_launch_outlined, size: 20));
              },
            ),
          5 => const Icon(Icons.merge_rounded, size: 20),
          6 => const Icon(Icons.bolt_rounded, size: 20),
          _ => const Icon(Icons.history_rounded, size: 20),
        };
    final content = TabBarView(
      controller: _tabs,
      children: [
        ChangesTab(commitFocus: _commitFocus),
        const BranchesTab(),
        TagsTab(onOpenReleaseWizard: _openReleaseWizard),
        const RemotesTab(),
        ReleaseTab(flow: flow, onShowChanges: () => _tabs.animateTo(branchTabChanges)),
        const PrTab(),
        const ActionsTab(),
        const HistoryTab(),
      ],
    );

    // 스크롤 모드에서 모든 탭을 가장 긴 라벨에 맞춘 같은 폭으로 (언어마다 길이가 다르다).
    final labelStyle = theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700);
    final tabWidth = labels
            .map((t) => (TextPainter(
                  text: TextSpan(text: t, style: labelStyle),
                  textDirection: TextDirection.ltr,
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout())
                    .width)
            .reduce((a, b) => a > b ? a : b)
            .ceilToDouble() +
        2;

    return Column(children: [
      const StatusHeader(),
      _DelayedProgress(visible: repo.busy),
      if (notGitHub && !_dismissed.contains(notGitHubKey))
        _InfoBanner(text: l10n.bdBannerNotGitHub(hostLabel(l10n, host)), onDismiss: () => _dismiss(notGitHubKey)),
      if (showNext)
        NextActionBanner(
          action: next,
          onDismiss: () => _dismiss(next.key),
          onShowChanges: () => _tabs.animateTo(branchTabChanges),
          onShowRemotes: () => _tabs.animateTo(branchTabRemotes),
        ),
      if (!wide)
        TabBar(
          controller: _tabs,
          // 탭이 8개라 좁은 창(560px 미만)에서는 가로로 스크롤한다 (UI_UX.md §2).
          isScrollable: width < 560,
          tabAlignment: width < 560 ? TabAlignment.center : TabAlignment.fill,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: theme.textTheme.labelMedium,
          tabs: [
            for (var i = 0; i < labels.length; i++)
              // 스크롤 모드에서는 글자 수대로 폭이 달라지므로 같은 폭으로 맞춘다.
              SizedBox(width: width < 560 ? tabWidth : null, child: Tab(height: 48, icon: icon(i), text: labels[i])),
          ],
        ),
      Expanded(
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _SectionRail(tabs: _tabs, labels: labels, icon: icon),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ])
            : content,
      ),
    ]);
  }
}

/// 넓은 창의 왼쪽 섹션 레일. 탭 컨트롤러를 그대로 따르므로 단축키·마지막 탭 기억이 같다.
/// 창이 낮으면 레일만 세로로 스크롤한다.
class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.tabs, required this.labels, required this.icon});

  final TabController tabs;
  final List<String> labels;
  final Widget Function(int) icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: ListenableBuilder(
              listenable: tabs,
              builder: (context, _) => NavigationRail(
                selectedIndex: tabs.index,
                onDestinationSelected: tabs.animateTo,
                labelType: NavigationRailLabelType.all,
                minWidth: 76,
                groupAlignment: -1,
                destinations: [for (var i = 0; i < labels.length; i++) NavigationRailDestination(icon: icon(i), label: Text(labels[i]))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 0.5초 이상 걸리는 작업만 진행 표시 (ui-ux.md §6).
class _DelayedProgress extends StatefulWidget {
  const _DelayedProgress({required this.visible});

  final bool visible;

  @override
  State<_DelayedProgress> createState() => _DelayedProgressState();
}

class _DelayedProgressState extends State<_DelayedProgress> {
  Timer? _timer;
  bool _show = false;

  @override
  void didUpdateWidget(_DelayedProgress old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) {
      _timer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _show = true);
      });
    } else if (!widget.visible) {
      _timer?.cancel();
      _show = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(height: 2, child: _show ? const LinearProgressIndicator(minHeight: 2) : null);
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 4, 6),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppRadius.button)),
      child: Row(children: [
        Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        IconButton(
          tooltip: AppLocalizations.of(context).commonClose,
          visualDensity: VisualDensity.compact,
          iconSize: 16,
          icon: const Icon(Icons.close_rounded),
          onPressed: onDismiss,
        ),
      ]),
    );
  }
}
