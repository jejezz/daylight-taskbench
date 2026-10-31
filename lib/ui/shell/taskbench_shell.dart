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
import '../../l10n/app_localizations.dart';
import '../../settings/app_settings.dart';
import '../../settings/settings_dialog.dart';
import '../../theme/taskbench_style.dart';
import '../../window/focus_tint.dart';
import '../../workspace/git_state.dart';
import '../../workspace/workspace.dart';
import '../../docks/branch/ui/branch_dock_body.dart' show branchTabBranches;
import '../start_screen.dart';
import '../style/aurora_background.dart';
import 'dock_accordion.dart';
import 'shared_bar.dart';

class TaskbenchShell extends StatefulWidget {
  const TaskbenchShell({
    super.key,
    required this.workspace,
    required this.docks,
    required this.onAbout,
    this.pickFolder,
  });

  final Workspace workspace;
  final List<DockModule> docks;
  final VoidCallback onAbout;

  /// 폴더 고르기 창. 테스트에서 바꾼다.
  final Future<String?> Function()? pickFolder;

  @override
  State<TaskbenchShell> createState() => _TaskbenchShellState();
}

class _TaskbenchShellState extends State<TaskbenchShell>
    with WidgetsBindingObserver {
  static const _expandedKey = 'dock_expanded';

  final _empty = RunEmptyDock();
  StreamSubscription<HeadChange>? _heads;
  String? _expandedId;
  bool _dragging = false;
  bool _pinned = false;

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
          final target = ws.failedPath!;
          final init = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(l10n.dropNotRepoTitle),
              content: Text(l10n.dropNotRepoBody(target)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('git init'),
                ),
              ],
            ),
          );
          if (init == true) await ws.initRepository(target);
        }
      case _:
        break;
    }
    if (r.extraIgnored && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.dropMultiple)));
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    final mac = Platform.isMacOS;
    final shortcuts = <ShortcutActivator, VoidCallback>{
      SingleActivator(LogicalKeyboardKey.keyO, control: !mac, meta: mac):
          _pickAndOpen,
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
            listenable: Listenable.merge([ws, ...widget.docks, settings]),
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
                        Column(
                          children: [
                            Stack(
                              children: [
                                const Positioned.fill(child: FocusTint()),
                                WorkspaceBar(
                                  workspace: ws,
                                  onOpenFolder: _pickAndOpen,
                                  onOpenRecent: _openPath,
                                  onSettings: () => showSettingsDialog(context),
                                  onAbout: widget.onAbout,
                                  alwaysOnTop: _pinned,
                                  onToggleAlwaysOnTop: _desktop
                                      ? _togglePin
                                      : null,
                                ),
                              ],
                            ),
                            if (open) ...[
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
                            ] else
                              Expanded(
                                child: StartScreen(
                                  workspace: ws,
                                  onOpenFolder: _pickAndOpen,
                                  onOpenPath: _openPath,
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
    return Positioned.fill(
      child: IgnorePointer(
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
      ),
    );
  }
}
