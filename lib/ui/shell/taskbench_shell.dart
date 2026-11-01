// 앱의 한 화면: 저장소가 안 열렸으면 시작 화면, 열렸으면 공유 영역 두 줄 + 아코디언 (PLAN.md §1.0~1.2).
// 폴더 끌어다 놓기는 창 전체가 받고 공유 영역이 반응한다 (§1.11). Dock 은 자기 DropTarget 을 두지 않는다.

import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../app_identity.dart';
import '../../docks/branch/branch_dock.dart';
import '../../docks/dock_module.dart';
import '../../docks/registry.dart';
import '../../editor/editor_controller.dart';
import '../../editor/editor_settings.dart';
import '../../editor/formatters.dart';
import '../../explorer/file_opener.dart';
import '../../explorer/project_files.dart';
import '../../explorer/quick_open.dart';
import '../../l10n/app_localizations.dart';
import '../../terminal/terminal_sessions_controller.dart';
import '../../terminal/terminal_settings.dart';
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
import 'panels/panel_divider.dart';
import 'shell_shortcuts.dart';
import 'panels/panel_layout.dart';
import 'panels/panel_widths.dart';
import 'shared_bar.dart';

/// 종료 확인 창의 선택.
enum _QuitChoice { cancel, discard, save }

class TaskbenchShell extends StatefulWidget {
  const TaskbenchShell({
    super.key,
    required this.workspace,
    required this.docks,
    required this.onAbout,
    required this.panels,
    this.windowMode,
    this.opener,
    this.terminals,
    this.terminalSettings,
    this.editor,
    this.editorSettings,
    this.panelWidths,
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

  /// 터미널 세션과 설정. 테스트에서 가짜 pty 로 바꾼다.
  final TerminalSessionsController? terminals;
  final TerminalSettings? terminalSettings;

  /// 열린 편집기 탭들. 테스트에서 바꾼다.
  final EditorController? editor;

  /// 편집기 설정(들여쓰기 선·저장 시 정렬). 테스트에서 바꾼다.
  final EditorSettings? editorSettings;

  /// 탐색기·도크 열 너비(끌어서 조절, 저장). 테스트에서 바꾼다.
  final PanelWidths? panelWidths;

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
  // 밖에서 받지 않으면 셸이 직접 만들고 직접 정리한다 (처음 쓸 때 만든다).
  PanelWidths? _ownPanelWidths;
  PanelWidths get _panelWidths =>
      widget.panelWidths ??
      (_ownPanelWidths ??= PanelWidths(widget.workspace.prefs));
  EditorSettings? _ownEditorSettings;
  EditorSettings get _editorSettings =>
      widget.editorSettings ??
      (_ownEditorSettings ??= EditorSettings(widget.workspace.prefs));
  AppLifecycleListener? _exitListener;
  bool _quitDialogOpen = false;
  EditorController? get _editorIfCreated => widget.editor ?? _ownEditor;
  EditorController? _ownEditor;
  EditorController get _editor =>
      widget.editor ??
      (_ownEditor ??= EditorController(
        formatDart: DartFormatter(widget.workspace.runner).format,
        formatOnSave: () => _editorSettings.formatOnSave,
      ));
  TerminalSettings? _ownTerminalSettings;
  TerminalSessionsController? _ownTerminals;
  TerminalSettings get _terminalSettings =>
      widget.terminalSettings ??
      (_ownTerminalSettings ??= TerminalSettings(widget.workspace.prefs));
  TerminalSessionsController get _terminals =>
      widget.terminals ??
      (_ownTerminals ??= TerminalSessionsController(
        scrollback: () => _terminalSettings.scrollback,
      ));
  StreamSubscription<HeadChange>? _heads;
  String? _expandedId;
  bool _dragging = false;
  bool _pinned = false;

  /// 도크 열은 도킹↔확장 전환에서 같은 State 를 유지한다 (펼친 칸·스크롤·실행 중 빌드가 그대로).
  final _topKey = GlobalKey(debugLabel: 'top');
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
      // 열린 편집기 파일도 바로 정리한다: 다시 읽기·이 브랜치에 없는 탭 닫기·고치던 것은 그대로 (§1.10).
      _editorIfCreated?.handleHeadChange();
    });
    // 앱을 끄려 할 때(창 닫기·⌘Q) 저장하지 않은 수정이 있으면 먼저 묻는다.
    _exitListener = AppLifecycleListener(onExitRequested: _onExitRequested);
    ws.registerBusyCheck(_anyBusy);
    ws.openHandler = _openPath;
    ws.pickFolderHandler = _pickAndOpen;
    ws.openFileHandler = _openFile;
    ws.openLocationHandler = _openLocation;
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
    if (ws.openFileHandler == _openFile) ws.openFileHandler = null;
    if (ws.openLocationHandler == _openLocation) ws.openLocationHandler = null;
    ws.unregisterBusyCheck(_anyBusy);
    _heads?.cancel();
    for (final d in widget.docks) {
      d.detach(ws);
    }
    WidgetsBinding.instance.removeObserver(this);
    _exitListener?.dispose();
    _ownPanelWidths?.dispose();
    _ownEditor?.dispose();
    _ownEditorSettings?.dispose();
    _ownTerminals?.dispose();
    _ownTerminalSettings?.dispose();
    super.dispose();
  }

  /// 저장하지 않은 수정이 있으면 종료 전에 묻는다: 모두 저장하고 종료 · 저장하지 않고 종료 · 취소.
  /// 저장하지 못한 파일이 있으면 종료를 취소한다(잃지 않게).
  Future<AppExitResponse> _onExitRequested() async {
    final editor = _editorIfCreated;
    if (editor == null || !editor.hasUnsaved || !mounted) {
      return AppExitResponse.exit;
    }
    if (_quitDialogOpen) return AppExitResponse.cancel; // 이미 묻는 중이다
    _quitDialogOpen = true;
    try {
      final l10n = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      final names = [
        for (final t in editor.tabs)
          if (t.dirty) t.name,
      ];
      final shown = names.length <= 5
          ? names.join(', ')
          : '${names.take(5).join(', ')} …';
      final choice = await showDialog<_QuitChoice>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(l10n.quitUnsavedTitle),
          content: Text(l10n.quitUnsavedBody(names.length, shown)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _QuitChoice.cancel),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _QuitChoice.discard),
              child: Text(l10n.quitDiscardAndExit),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _QuitChoice.save),
              child: Text(l10n.quitSaveAndExit),
            ),
          ],
        ),
      );
      switch (choice) {
        case _QuitChoice.discard:
          return AppExitResponse.exit;
        case _QuitChoice.save:
          if (await editor.saveAll()) return AppExitResponse.exit;
          messenger?.showSnackBar(SnackBar(content: Text(l10n.quitSaveFailed)));
          return AppExitResponse.cancel;
        case _QuitChoice.cancel || null:
          return AppExitResponse.cancel;
      }
    } finally {
      _quitDialogOpen = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ws.onWindowFocused();
      // 창에 돌아왔을 때 바로 열린 파일이 디스크에서 바뀌었는지 본다 (밖에서 Claude Code 등이 고쳤을 수 있다).
      _ownEditor?.checkExternalChanges();
      widget.editor?.checkExternalChanges();
    }
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

  /// 탐색기·빠른 열기에서 고른 파일을 연다 (PLAN.md §1.13).
  /// 확장 모드(작업대)이고 "내장 에디터 사용"이 켜져 있으면 내장 에디터로 열고(에디터 패널이 꺼져 있으면 켠다),
  /// 도킹 모드이거나 내장 에디터를 껐으면 외부 편집기(설정의 편집기 명령, 없으면 VS Code)로 연다.
  Future<void> _openFile(String path) => _openIn(
    path,
    embedded: () => _editor.openFile(path),
    external: () => _opener.open(path),
  );

  /// [path] 의 [line]:[column] 을 연다 (빌드 오류 위치 등). 열 곳은 [_openFile]과 같다.
  Future<void> _openLocation(String path, int line, int column) => _openIn(
    path,
    embedded: () => _editor.openAt(path, line, column),
    external: () => _opener.openAt(path, line, column),
  );

  Future<void> _openIn(
    String path, {
    required Future<void> Function() embedded,
    required Future<OpenFileResult> Function() external,
  }) async {
    final panels = widget.panels;
    if (panels.embeddedEditor && panels.expanded) {
      panels.setEditor(true);
      await embedded();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await external();
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
        // 확장 모드에서는 "항상 위"를 숨긴다 (큰 작업창은 다른 창 위에 고정할 일이 없다). 도킹으로 돌아오면 다시 보인다.
        onToggleAlwaysOnTop: _desktop && !widget.panels.expanded
            ? _togglePin
            : null,
      ),
    ],
  );

  /// 제목 줄·브랜치 줄([top])은 두 모드 모두 창 전체 폭으로 맨 위에 있고, 그 아래가 [accordion]이다.
  /// 도킹 모드면 아코디언이 창 전체 폭을 쓰고, 확장 모드면 왼쪽에 확장 영역(카드)이 붙고 아코디언은 고정 폭 열이 된다 (§1.13).
  /// 제목 줄과 아코디언은 [GlobalKey]를 달아 두 모드 사이를 오가도 State 가 유지된다.
  Widget _body(Widget top, Widget accordion) {
    final panels = widget.panels;
    if (!panels.expanded) {
      return Column(
        children: [
          top,
          Expanded(child: accordion),
        ],
      );
    }
    final l10n = AppLocalizations.of(context);
    final widths = _panelWidths;
    // 도크 열 폭은 원하는 폭(저장한 값)이되, 왼쪽 영역이 최소 폭을 지킬 수 있게 창이 좁아진 순간에는 줄여서 보인다.
    // 모드 전환으로 창 크기를 바꾸는 중에도 넘치지 않는다.
    return Column(
      children: [
        top,
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final dock = PanelWidths.dockFit(
                total: c.maxWidth,
                areaMin: PanelWidths.areaMin(
                  hasExplorer: panels.explorer,
                  hasCenter: panels.hasCenter,
                ),
                preferred: widths.dock,
              );
              return Row(
                children: [
                  Expanded(
                    child: ExpandedArea(
                      panels: panels,
                      workspace: ws,
                      onOpenFile: _openFile,
                      terminals: _terminals,
                      terminalSettings: _terminalSettings,
                      editor: _editor,
                      widths: widths,
                      onQuickOpen: _quickOpen,
                      quickOpenShortcut: _quickOpenShortcut,
                    ),
                  ),
                  PanelDivider(
                    semanticLabel: l10n.panelResizeHandle,
                    // 왼쪽으로 끌면 도크 열이 넓어진다 (지금 보이는 폭에서 시작한다).
                    onDelta: (dx) => widths.setDock(dock - dx),
                    onReset: widths.resetDock,
                  ),
                  SizedBox(
                    width: dock,
                    // 아코디언 안의 칸들은 창이 아니라 **자기 열의 크기**를 화면 크기로 본다. 그렇지 않으면 창이 넓다는
                    // 이유로 Git 칸이 "넓은 창 배치"(왼쪽 레일)로 바뀌고 단추 라벨 힌트가 좁은 열에 넘친다 (§1.13).
                    child: MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(size: Size(dock, c.maxHeight)),
                      child: accordion,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    // 키 조합은 shell_shortcuts.dart 의 표 한곳에서 정한다 (겹침 검사·터미널 전달 목록과 같은 표).
    final shortcuts = <ShortcutActivator, VoidCallback>{
      activatorOf(ShellShortcut.openFolder): _pickAndOpen,
      activatorOf(ShellShortcut.quickOpen): () {
        if (ws.isOpen) _quickOpen();
      },
      activatorOf(ShellShortcut.settings): () => showSettingsDialog(context),
      activatorOf(ShellShortcut.refresh): ws.refresh,
      // 패널: 저장소가 열려 있을 때만 (시작 화면에는 패널이 없다).
      activatorOf(ShellShortcut.explorer): () {
        if (ws.isOpen) widget.panels.toggleExplorer();
      },
      activatorOf(ShellShortcut.editor): () {
        if (ws.isOpen) widget.panels.toggleEditor();
      },
      activatorOf(ShellShortcut.terminal): () {
        if (ws.isOpen) widget.panels.toggleTerminal();
      },
      for (final (i, s) in [
        ShellShortcut.dock1,
        ShellShortcut.dock2,
        ShellShortcut.dock3,
        ShellShortcut.dock4,
      ].indexed)
        activatorOf(s): () {
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
              _panelWidths,
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
                          // 제목 줄·브랜치 줄은 두 모드 모두 창 전체 폭으로 맨 위에 두고, 그 아래에 카드들이 놓인다 (§1.13).
                          _body(
                            KeyedSubtree(
                              key: _topKey,
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
                                ],
                              ),
                            ),
                            KeyedSubtree(
                              key: _dockColumnKey,
                              child: DockAccordion(
                                docks: shown,
                                workspace: ws,
                                expandedId: expanded,
                                onSelect: _select,
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
                          _DropOverlay(title: l10n.dropOverlayTitle),
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
  const _DropOverlay({required this.title});

  final String title;

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
    return Positioned.fill(child: overlay);
  }
}
