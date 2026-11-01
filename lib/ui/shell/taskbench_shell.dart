// 앱의 한 화면: 저장소가 안 열렸으면 시작 화면, 열렸으면 공유 영역 두 줄 + 아코디언 (PLAN.md §1.0~1.2).
// 폴더 끌어다 놓기는 창 전체가 받고 공유 영역이 반응한다 (§1.11). Dock 은 자기 DropTarget 을 두지 않는다.

import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../app_identity.dart';
import '../../docks/branch/branch_dock.dart';
import '../../docks/dock_module.dart';
import '../../docks/registry.dart';
import '../../explorer/file_opener.dart';
import '../../explorer/project_files.dart';
import '../../explorer/quick_open.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../../settings/settings_dialog.dart';
import '../../theme/taskbench_style.dart';
import '../../window/focus_tint.dart';
import '../../workspace/git_state.dart';
import '../../workspace/workspace.dart';
import '../../docks/branch/ui/branch_dock_body.dart' show branchTabBranches;
import '../../docks/branch/ui/onboarding.dart';
import '../repo_choice.dart';
import '../start_screen.dart';
import '../../window/window_mode.dart';
import '../style/aurora_background.dart';
import 'dock_accordion.dart';
import 'panels/expanded_area.dart';
import 'panels/panel_layout.dart';
import 'shared_bar.dart';

class TaskbenchShell extends StatefulWidget {
  const TaskbenchShell({
    super.key,
    required this.workspace,
    required this.docks,
    required this.onAbout,
    required this.panels,
    this.windowMode,
    this.opener,
    this.pickFolder,
  });

  final Workspace workspace;
  final List<DockModule> docks;
  final VoidCallback onAbout;

  /// 확장 패널 켜짐 상태 — 모드(도킹/확장)는 여기서 파생된다 (§1.13).
  final PanelLayout panels;

  /// 모드가 바뀔 때 창 크기를 맞추는 쪽. 테스트에서는 null.
  final WindowModeController? windowMode;

  /// 탐색기에서 고른 파일을 여는 쪽. 테스트에서 바꾼다.
  final FileOpener? opener;

  /// 폴더 고르기 창. 테스트에서 바꾼다.
  final Future<String?> Function()? pickFolder;

  @override
  State<TaskbenchShell> createState() => _TaskbenchShellState();
}

class _TaskbenchShellState extends State<TaskbenchShell>
    with WidgetsBindingObserver {
  static const _expandedKey = 'dock_expanded';

  final _empty = RunEmptyDock();
  late final _opener = widget.opener ?? FileOpener(widget.workspace);
  StreamSubscription<HeadChange>? _heads;
  String? _expandedId;
  bool _dragging = false;
  bool _pinned = false;

  /// 도크 열은 도킹↔확장 전환에서 같은 State 를 유지한다 (펼친 칸·스크롤·실행 중 빌드가 그대로).
  final _dockColumnKey = GlobalKey(debugLabel: 'dockColumn');
  WindowMode? _lastWindowMode;

  Workspace get ws => widget.workspace;
  bool get _desktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _expandedId = ws.prefs.getString(_expandedKey);
    for (final d in widget.docks) {
      d.attach(ws);
    }
    // 접힌 칸에도 같은 신호가 간다 (§1.10).
    _heads = ws.headChanges.listen((c) {
      for (final d in widget.docks) {
        d.onHeadChange(ws, c);
      }
    });
    ws.registerBusyCheck(_anyBusy);
    ws.openHandler = _openPath;
    ws.pickFolderHandler = _pickAndOpen;
    ws.addListener(_syncTitle);
    _syncTitle();
    widget.panels.addListener(_syncWindowMode);
    _lastWindowMode = widget.panels.windowMode;
  }

  /// 패널이 켜지거나 꺼져 모드가 바뀌면 창 크기를 그 모드의 크기로 바꾼다 (모드별로 기억).
  void _syncWindowMode() {
    final mode = widget.panels.windowMode;
    if (mode == _lastWindowMode) return;
    _lastWindowMode = mode;
    widget.windowMode?.switchTo(mode);
  }

  String? _title;

  /// 창 제목에 저장소와 브랜치를 보인다 (PLAN.md §1.10).
  void _syncTitle() {
    if (!_desktop) return;
    final root = ws.root;
    final name = root
        ?.split(RegExp(r'[\\/]'))
        .where((e) => e.isNotEmpty)
        .lastOrNull;
    final branch = ws.git?.branch;
    final title = name == null
        ? AppIdentity.displayName
        : '${AppIdentity.displayName} — $name${branch == null ? '' : ' ($branch)'}';
    if (title == _title) return;
    _title = title;
    windowManager.setTitle(title).catchError((Object _) {});
  }

  bool _anyBusy() => widget.docks.any((d) => d.busy(ws));

  @override
  void dispose() {
    ws.removeListener(_syncTitle);
    widget.panels.removeListener(_syncWindowMode);
    if (ws.openHandler == _openPath) ws.openHandler = null;
    if (ws.pickFolderHandler == _pickAndOpen) ws.pickFolderHandler = null;
    ws.unregisterBusyCheck(_anyBusy);
    _heads?.cancel();
    for (final d in widget.docks) {
      d.detach(ws);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ws.onWindowFocused();
  }

  // ── 열기 ────────────────────────────────────────────────────────────────

  Future<void> _pickAndOpen() async {
    final dir = await (widget.pickFolder ?? getDirectoryPath)();
    if (dir != null) await _openPath(dir);
  }

  Future<void> _openPath(String path) =>
      _handle(() => ws.openDropped([path]), path: path);

  Future<void> _onDrop(List<String> paths) =>
      _handle(() => ws.openDropped(paths));

  Future<void> _handle(
    Future<DropResult> Function() run, {
    String? path,
  }) async {
    var r = await run();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (r.outcome == OpenOutcome.needsConfirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l10n.dropBusyTitle),
          content: Text(l10n.dropBusyBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.dropStopAndOpen),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      r = await ws.openDropped([r.path ?? path ?? ''], force: true);
      if (!mounted) return;
    }
    final messenger = ScaffoldMessenger.of(context);
    switch (r.outcome) {
      case OpenOutcome.ignoredFiles:
        messenger.showSnackBar(SnackBar(content: Text(l10n.dropFilesOnly)));
      case OpenOutcome.selectedDirChanged:
        final name =
            (ws.selectedDir ?? '')
                .split(RegExp(r'[\\/]'))
                .where((s) => s.isNotEmpty)
                .lastOrNull ??
            '';
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.dropSelectedDir(name))),
        );
      case OpenOutcome.failed:
        // 저장소가 이미 열려 있으면 시작 화면의 안내가 안 보이므로 여기서 묻는다 — 열린 저장소는 닫지 않는다.
        if (ws.isOpen &&
            ws.failure == OpenFailure.notARepository &&
            ws.failedPath != null) {
          final info = ws.notRepoInfo;
          if (info == null) break;
          if (info.childRepos.isNotEmpty) {
            // 하위에 저장소가 여럿 — git init 대신 그 목록에서 고른다 (§1.13).
            final picked = await showChildRepoChooser(context, info);
            if (picked != null && mounted) await _openPath(picked);
          } else if (info.initAllowed) {
            final choice = await showInitRepoDialog(context, info);
            if (choice != null) {
              await ws.initRepository(
                info.path,
                flutterGitignore: choice.flutterGitignore,
              );
            }
          } else {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.startInitUnsafe(info.path))),
            );
          }
        }
      case _:
        break;
    }
    if (r.extraIgnored && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.dropMultiple)));
    }
  }

  Future<void> _clone() async {
    final path = await showCloneSheet(context);
    if (path != null) await _openPath(path);
  }

  void _login() {
    final origin = ws.repo?.remotes
        .where((r) => r.name == 'origin')
        .firstOrNull;
    showLoginSheet(
      context,
      ws.environment,
      onChanged: ws.checkEnvironment,
      preferSsh: sshPreferred(remoteIsSsh: origin?.location?.ssh ?? false),
    );
  }

  // ── 파일 열기 ───────────────────────────────────────────────────────────

  /// 탐색기·빠른 열기에서 고른 파일을 연다. 내장 에디터(단계 15)가 붙기 전과 내장 에디터를 껐을 때는 외부 편집기다
  /// — 내장 에디터가 생기면 여기 한 곳만 바꾸면 된다 (PLAN.md §1.13).
  Future<void> _openFile(String path) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _opener.open(path);
    if (!mounted) return;
    switch (result) {
      case OpenFileResult.opened:
        break;
      case OpenFileResult.noEditor:
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.editorOpenNoEditor)),
        );
      case OpenFileResult.failed:
        messenger.showSnackBar(SnackBar(content: Text(l10n.editorOpenFailed)));
    }
  }

  /// 파일 이름으로 열기 (⌘/Ctrl+Shift+O). ⌘P 는 Git 칸의 Push 가 쓴다.
  Future<void> _quickOpen() async {
    final root = ws.root;
    if (root == null) return;
    final picked = await showQuickOpen(
      context,
      root: root,
      files: listProjectFiles(root),
    );
    if (picked != null && mounted) await _openFile(picked);
  }

  String get _quickOpenShortcut => Platform.isMacOS ? '⌘⇧O' : 'Ctrl+Shift+O';

  // ── 칸 ──────────────────────────────────────────────────────────────────

  void _select(String id) {
    setState(() => _expandedId = id);
    ws.prefs.setString(_expandedKey, id);
  }

  Future<void> _togglePin() async {
    if (!_desktop) return;
    final next = !_pinned;
    await windowManager.setAlwaysOnTop(next);
    if (mounted) setState(() => _pinned = next);
  }

  TaskbenchMood _mood(List<DockModule> shown) {
    if (shown.any((d) => d.mood(ws) == TaskbenchMood.failed)) {
      return TaskbenchMood.failed;
    }
    if (shown.any((d) => d.busy(ws) || d.mood(ws) == TaskbenchMood.working)) {
      return TaskbenchMood.working;
    }
    return TaskbenchMood.idle;
  }

  Widget _workspaceBar() => Stack(
    children: [
      const Positioned.fill(child: FocusTint()),
      WorkspaceBar(
        workspace: ws,
        onOpenFolder: _pickAndOpen,
        onOpenRecent: _openPath,
        onSettings: () => showSettingsDialog(context),
        onAbout: widget.onAbout,
        panels: widget.panels,
        alwaysOnTop: _pinned,
        onToggleAlwaysOnTop: _desktop ? _togglePin : null,
      ),
    ],
  );

  /// 도킹 모드면 도크 열이 창 전체를 쓰고, 확장 모드면 왼쪽에 확장 영역이 붙고 도크 열은 고정 폭이 된다 (§1.13).
  /// 도크 열은 [GlobalKey]를 달아 두 모드 사이를 오가도 State 가 유지된다.
  Widget _body(Widget dockColumn) {
    final panels = widget.panels;
    if (!panels.expanded) return dockColumn;
    // 창이 확장 최소 폭보다 좁은 순간(모드 전환으로 창 크기를 바꾸는 중)에도 넘치지 않게 도크 열 폭을 줄인다.
    return LayoutBuilder(
      builder: (context, c) {
        final width = dockColumnWidth.clamp(0.0, c.maxWidth * 0.65);
        return Row(
          children: [
            Expanded(
              child: ExpandedArea(
                panels: panels,
                workspace: ws,
                onOpenFile: _openFile,
                onQuickOpen: _quickOpen,
                quickOpenShortcut: _quickOpenShortcut,
              ),
            ),
            SizedBox(
              width: width,
              // 도크 열 안의 칸들은 창이 아니라 **자기 열의 크기**를 화면 크기로 본다. 그렇지 않으면 창이 넓다는
              // 이유로 Git 칸이 "넓은 창 배치"(왼쪽 레일)로 바뀌고 단추 라벨 힌트가 좁은 열에 넘친다 (§1.13).
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(size: Size(width, c.maxHeight)),
                child: dockColumn,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    final mac = Platform.isMacOS;
    final shortcuts = <ShortcutActivator, VoidCallback>{
      SingleActivator(LogicalKeyboardKey.keyO, control: !mac, meta: mac):
          _pickAndOpen,
      SingleActivator(
        LogicalKeyboardKey.keyO,
        control: !mac,
        meta: mac,
        shift: true,
      ): () {
        if (ws.isOpen) _quickOpen();
      },
      SingleActivator(LogicalKeyboardKey.comma, control: !mac, meta: mac): () =>
          showSettingsDialog(context),
      SingleActivator(LogicalKeyboardKey.keyR, control: !mac, meta: mac):
          ws.refresh,
      for (var i = 0; i < 4; i++)
        SingleActivator(
          LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i),
          control: !mac,
          meta: mac,
          alt: true,
        ): () {
          final shown = visibleDocks(widget.docks, _empty, ws);
          if (i < shown.length) _select(shown[i].id);
        },
    };
    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (d) {
            setState(() => _dragging = false);
            _onDrop([for (final f in d.files) f.path]);
          },
          child: ListenableBuilder(
            listenable: Listenable.merge([
              ws,
              ...widget.docks,
              settings,
              widget.panels,
            ]),
            builder: (context, _) {
              final open = ws.isOpen;
              final shown = open
                  ? visibleDocks(widget.docks, _empty, ws)
                  : const <DockModule>[];
              final expanded = shown.any((d) => d.id == _expandedId)
                  ? _expandedId
                  : shown.firstOrNull?.id;
              return AuroraBackground(
                mood: _mood(shown),
                moodEnabled: settings.stateTint,
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        if (open)
                          // 디렉터리 바·브랜치 줄·아코디언은 한 덩어리(도크 열)다. 확장해도 이 덩어리가 그대로
                          // 오른쪽에 남아서 도킹 모드와 같은 모습·위치를 유지한다 (§1.13).
                          _body(
                            KeyedSubtree(
                              key: _dockColumnKey,
                              child: Column(
                                children: [
                                  _workspaceBar(),
                                  BranchBar(
                                    workspace: ws,
                                    onBranchTap: () {
                                      final branch = widget.docks
                                          .whereType<BranchDock>()
                                          .firstOrNull;
                                      if (branch == null) return;
                                      _select(branch.id);
                                      branch.showTab(branchTabBranches);
                                    },
                                  ),
                                  Expanded(
                                    child: DockAccordion(
                                      docks: shown,
                                      workspace: ws,
                                      expandedId: expanded,
                                      onSelect: _select,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              _workspaceBar(),
                              Expanded(
                                child: StartScreen(
                                  workspace: ws,
                                  onOpenFolder: _pickAndOpen,
                                  onOpenPath: _openPath,
                                  onCheckEnvironment: ws.checkEnvironment,
                                  onClone: _clone,
                                  onLogin: _login,
                                  onSetToolPath: (_) => showSettingsDialog(
                                    context,
                                    initial: SettingsSection.tools,
                                  ),
                                  dragging: _dragging,
                                ),
                              ),
                            ],
                          ),
                        if (_dragging && open)
                          _DropOverlay(
                            title: l10n.dropOverlayTitle,
                            // 확장 모드에서는 도크 열 위에만 덮는다 — 폴더를 놓는 자리가 그쪽이다.
                            width: widget.panels.expanded
                                ? dockColumnWidth
                                : null,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 끄는 동안 공유 영역 두 줄 위에 덮는 안내 (§1.11). 그 아래 Dock 영역은 살짝 어둡게 한다.
class _DropOverlay extends StatelessWidget {
  const _DropOverlay({required this.title, this.width});

  final String title;

  /// null 이면 창 전체, 아니면 오른쪽 이 폭만.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overlay = IgnorePointer(
      child: Column(
        children: [
          Container(
            height: sharedBarHeight + branchBarHeight,
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.primary, width: 2),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: scheme.primary),
            ),
          ),
          Expanded(
            child: ColoredBox(color: scheme.scrim.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
    return Positioned.fill(
      child: width == null
          ? overlay
          : Align(
              alignment: Alignment.centerRight,
              child: SizedBox(width: width, child: overlay),
            ),
    );
  }
}
