// Flutty Dock 칸 — 단계 1 자리표시자. 단계 4에서 flutty-dock-flutter 의 화면이 이 칸 안으로 들어온다.
// 지금은 "고른 폴더(depth 0) → 없으면 depth 1" 프로젝트 검색(PLAN.md §1.4)과 브랜치 전환 뒤 재감지를 보여 준다.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/taskbench_style.dart';
import '../../workspace/git_state.dart';
import '../../workspace/project_detector.dart';
import '../../workspace/workspace.dart';
import '../dock_module.dart';

class FluttyDock extends DockModule {
  FluttyDock({this._detector = const FlutterDetector()});

  final ProjectDetector _detector;

  List<DetectedProject> _projects = const [];
  String? _forDir;
  int _generation = 0;
  Workspace? _workspace;
  bool _disposed = false;

  List<DetectedProject> get projects => _projects;

  /// 여럿일 때 고른 프로젝트. 선택은 고른 폴더별로 기억한다 (`flutty.project_choice:<dir>`).
  DetectedProject? selected(Workspace w) {
    if (_projects.isEmpty) return null;
    final saved = w.prefs.getString('flutty.project_choice:${w.selectedDir}');
    return _projects.firstWhere((p) => p.path == saved, orElse: () => _projects.first);
  }

  Future<void> choose(Workspace w, DetectedProject p) async {
    await w.prefs.setString('flutty.project_choice:${w.selectedDir}', p.path);
    notifyListeners();
  }

  @override
  String get id => 'flutty';

  @override
  IconData get icon => Icons.play_circle_outline_rounded;

  @override
  bool get isRunner => true;

  @override
  String title(AppLocalizations l10n) => l10n.dockFluttyTitle;

  @override
  bool appliesTo(Workspace w) => _projects.isNotEmpty;

  @override
  void attach(Workspace w) {
    _workspace = w;
    w.addListener(_onWorkspace);
    _onWorkspace();
  }

  @override
  void detach(Workspace w) {
    w.removeListener(_onWorkspace);
    _workspace = null;
    _generation++; // 진행 중이던 검색 결과는 버린다
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _onWorkspace() {
    final w = _workspace;
    if (w == null) return;
    if (w.selectedDir != _forDir) _detect(w);
  }

  Future<void> _detect(Workspace w) async {
    final dir = w.selectedDir;
    _forDir = dir;
    final gen = ++_generation;
    final found = dir == null ? const <DetectedProject>[] : await _detector.detect(dir);
    if (gen != _generation || _disposed) return; // 그 사이 폴더가 또 바뀌었거나 칸이 사라졌다
    _projects = found;
    notifyListeners();
  }

  @override
  void onHeadChange(Workspace w, HeadChange change) {
    // 브랜치에 따라 pubspec·하위 프로젝트가 생기거나 사라질 수 있다 — 다시 찾는다 (§1.10).
    if (change.kind == HeadChangeKind.branch || change.kind == HeadChangeKind.commit) _detect(w);
  }

  @override
  TaskbenchMood mood(Workspace w) => TaskbenchMood.idle;

  @override
  Widget summary(BuildContext context, Workspace w) {
    final p = selected(w);
    if (p == null) return const SizedBox.shrink();
    return Text(
      p.version == null ? p.name : '${p.name} ${p.version}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget body(BuildContext context, Workspace w) => _FluttyBody(dock: this, workspace: w);
}

class _FluttyBody extends StatelessWidget {
  const _FluttyBody({required this.dock, required this.workspace});

  final FluttyDock dock;
  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([dock, workspace]),
      builder: (context, _) {
        final p = dock.selected(workspace);
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(l10n.dockPlaceholderFlutty, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (dock.projects.length > 1)
              DropdownButton<String>(
                isExpanded: true,
                value: p?.path,
                items: [
                  for (final project in dock.projects)
                    DropdownMenuItem(value: project.path, child: Text(project.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (path) {
                  final chosen = dock.projects.where((e) => e.path == path).firstOrNull;
                  if (chosen != null) dock.choose(workspace, chosen);
                },
              ),
            if (p != null) SelectableText('${p.name} ${p.version ?? ''}\n${p.path}', style: theme.textTheme.bodySmall),
          ],
        );
      },
    );
  }
}
