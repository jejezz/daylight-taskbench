// Gradle Runner 칸 — Gradle 프로젝트(Android 앱·JVM)를 빌드·설치·실행한다 (docs/GRADLE_RUNNER.md, 단계 9).
//
// 지금(9b)은 감지와 뼈대까지다: 공유 영역의 폴더에서 Gradle 프로젝트를 depth 0 → 1 로 찾고(여럿이면 드롭다운),
// 고른 프로젝트의 모듈을 읽어 보여 준다. Run·Devices·Doctor 탭은 이어지는 단계에서 붙는다.
// 브랜치가 바뀌면(onHeadChange) 접혀 있어도 다시 찾는다 (§1.10).

import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/run_session.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/taskbench_style.dart';
import '../../workspace/git_state.dart';
import '../../workspace/project_detector.dart';
import '../../workspace/workspace.dart';
import '../dock_module.dart';
import 'detect/gradle_detector.dart';
import 'detect/gradle_project.dart';
import 'run/gradle_controller.dart';
import 'ui/gradle_dock_body.dart';

class GradleDock extends DockModule {
  // ignore: prefer_initializing_formals
  GradleDock({this.detector = const GradleDetector(), GradleController? controller}) : _controller = controller;

  final ProjectDetector detector;

  GradleController? _controller;

  /// 화면과 테스트가 읽는다. [attach] 전에는 null.
  GradleController? get controller => _controller;

  /// 실행 중에 브랜치가 바뀌었다는 알림 (배너). 사용자가 닫거나 실행이 끝나면 사라진다.
  String? branchChangedWhileRunning;

  List<DetectedProject> _projects = const [];

  /// 고른 프로젝트의 상세. 아직 읽는 중이거나 프로젝트가 없으면 null.
  GradleProject? get project => _controller?.project;

  String? _forDir;
  int _generation = 0;
  Workspace? _workspace;
  bool _disposed = false;

  List<DetectedProject> get projects => _projects;

  /// 여럿일 때 고른 프로젝트. 선택은 고른 폴더별로 기억한다 (`gradle.project_choice:<dir>`).
  DetectedProject? selected(Workspace w) {
    if (_projects.isEmpty) return null;
    final saved = w.prefs.getString('gradle.project_choice:${w.selectedDir}');
    return _projects.firstWhere((p) => p.path == saved, orElse: () => _projects.first);
  }

  Future<void> choose(Workspace w, DetectedProject p) async {
    await w.prefs.setString('gradle.project_choice:${w.selectedDir}', p.path);
    await _readProject(w);
    notifyListeners();
  }

  @override
  String get id => 'gradle';

  @override
  IconData get icon => Icons.play_circle_outline_rounded;

  @override
  bool get isRunner => true;

  @override
  String title(AppLocalizations l10n) => l10n.dockGradleTitle;

  @override
  bool appliesTo(Workspace w) => _projects.isNotEmpty;

  @override
  void attach(Workspace w) {
    _workspace = w;
    _controller ??= GradleController(runner: w.runner, prefs: w.prefs);
    _controller!.addListener(_onController);
    w.addListener(_onWorkspace);
    _onWorkspace();
  }

  @override
  void detach(Workspace w) {
    w.removeListener(_onWorkspace);
    _controller?.removeListener(_onController);
    _workspace = null;
    _generation++; // 진행 중이던 검색 결과는 버린다
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.dispose();
    super.dispose();
  }

  /// 칸이 처음 펼쳐질 때 기기 목록을 읽기 시작한다.
  void ensureStarted() => _controller?.ensureStarted();

  void dismissBranchBanner() {
    branchChangedWhileRunning = null;
    notifyListeners();
  }

  void _onController() {
    final c = _controller;
    if (c != null && !c.running) branchChangedWhileRunning = null;
    if (!_disposed) notifyListeners();
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
    var found = const <DetectedProject>[];
    if (dir != null) {
      try {
        found = await detector.detect(dir);
      } on FileSystemException {
        // 브랜치를 바꾸는 사이 파일이 사라졌다 — 없는 것으로 보고, 다음 변화에서 다시 찾는다.
      }
    }
    if (gen != _generation || _disposed) return;
    _projects = found;
    await _readProject(w, generation: gen);
    if (gen != _generation || _disposed) return;
    notifyListeners();
  }

  Future<void> _readProject(Workspace w, {int? generation}) async {
    final picked = selected(w);
    GradleProject? detail;
    if (picked != null) {
      detail = await GradleProject.read(picked.path, name: picked.name, version: picked.version);
    }
    if (_disposed || (generation != null && generation != _generation)) return;
    _controller?.setProject(detail);
  }

  @override
  void onHeadChange(Workspace w, HeadChange change) {
    // 브랜치에 따라 settings·모듈이 생기거나 사라질 수 있다 — 다시 찾는다 (§1.10).
    if (change.kind != HeadChangeKind.branch && change.kind != HeadChangeKind.commit) return;
    if (change.kind == HeadChangeKind.branch && (_controller?.running ?? false)) {
      // 실행 중이면 중지하지 않고 알리기만 한다 (확정된 결정 12번).
      branchChangedWhileRunning = change.to.branch ?? change.to.sha ?? '';
      notifyListeners();
    }
    // 모듈·변형·작업 목록은 브랜치마다 다를 수 있다.
    _controller?.invalidateCaches();
    _detect(w);
  }

  /// 병합·rebase 등이 진행 중이면 빌드 결과를 믿기 어렵다 (§1.10).
  bool operationInProgress(Workspace w) => (w.git?.operation ?? RepoOperation.none) != RepoOperation.none;

  @override
  TaskbenchMood mood(Workspace w) {
    final c = _controller;
    if (c == null) return TaskbenchMood.idle;
    if (c.busy) return TaskbenchMood.working;
    if (c.statuses.contains(StepStatus.failed)) return TaskbenchMood.failed;
    if (branchChangedWhileRunning != null || operationInProgress(w)) return TaskbenchMood.warning;
    if (c.statuses.isNotEmpty && c.statuses.every((s) => s == StepStatus.done)) return TaskbenchMood.success;
    return TaskbenchMood.idle;
  }

  @override
  bool busy(Workspace w) => _controller?.busy ?? false;

  @override
  Widget summary(BuildContext context, Workspace w) {
    final l10n = AppLocalizations.of(context);
    final p = selected(w);
    if (p == null) return const SizedBox.shrink();
    final shape = project == null
        ? null
        : project!.shape == GradleShape.androidApp
            ? l10n.grShapeAndroid
            : l10n.grShapeJvm;
    return Text(
      [p.name, ?shape].join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget body(BuildContext context, Workspace w) => GradleDockBody(dock: this, workspace: w);
}
