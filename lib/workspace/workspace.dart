// 앱 전체가 함께 보는 "지금 열린 저장소"의 주인 (PLAN.md §1.4, §1.9~1.11).
//
// - 폴더를 열고(저장소 루트를 찾고, 고른 폴더는 [selectedDir]로 따로 기억), 최근 목록을 쥔다.
// - HEAD 변화([headChanges])를 한 번만 감지해 모든 칸에 알린다 (§1.10).
// - 끌어다 놓은 경로를 규칙대로 처리한다 ([openDropped], §1.11) — 위젯 없이 테스트할 수 있다.
// Dock끼리는 서로를 직접 모르고 이 객체만 본다.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/command_runner.dart';
import '../core/vscode.dart';
import '../docks/branch/git/commands.dart';
import '../docks/branch/repo/environment.dart';
import '../docks/branch/repo/repo_controller.dart';
import 'git_state.dart';

export '../docks/branch/repo/repo_controller.dart' show OpenFailure;

/// [Workspace.open] / [Workspace.openDropped] 의 결과.
enum OpenOutcome {
  /// 새 저장소를 열었다.
  opened,

  /// 같은 저장소의 하위 폴더 — 저장소는 그대로, 고른 폴더만 바뀌었다 (§1.11).
  selectedDirChanged,

  /// 같은 폴더 — 새로 읽기만 했다.
  refreshed,

  /// 열지 못했다 ([Workspace.failure] 참고). 열려 있던 저장소는 닫지 않는다.
  failed,

  /// 작업 중이라 확인이 필요하다 — 호출한 쪽이 묻고 `force: true` 로 다시 부른다.
  needsConfirm,

  /// 폴더가 아니라 파일만 놓였다.
  ignoredFiles,
}

class DropResult {
  const DropResult(this.outcome, {this.path, this.extraIgnored = false});

  final OpenOutcome outcome;

  /// 처리한 폴더(결과가 needsConfirm·failed 일 때 다시 쓴다).
  final String? path;

  /// 폴더가 여럿이라 첫 번째만 열었다.
  final bool extraIgnored;
}

class Workspace extends ChangeNotifier {
  Workspace({required this.runner, required SharedPreferences prefs, EnvironmentStatus environment = const EnvironmentStatus()})
      : _prefs = prefs,
        _env = environment {
    _recent = prefs.getStringList(recentKey) ?? const [];
  }

  /// 공통 저장 키 (settings.md — 접두어 없음).
  static const recentKey = 'recent_dirs';
  static const maxRecent = 10;

  final CommandRunner runner;
  final SharedPreferences _prefs;

  List<String> _recent = const [];
  EnvironmentStatus _env;
  String? _selectedDir;
  GitStateSource? _source;
  StreamSubscription<GitState>? _sub;
  GitState? _git;
  OpenFailure? _failure;
  String? _failedPath;
  bool _opening = false;
  final _headChanges = StreamController<HeadChange>.broadcast(sync: true);
  final List<bool Function()> _busy = [];

  /// 칸이 디렉터리별 선택(예: 프로젝트 드롭다운)을 기억하는 데 쓴다 — 키는 `<칸 id>.…` 접두어.
  SharedPreferences get prefs => _prefs;

  /// 편집기에서 열기에 쓸 명령(예: `code`). 비어 있으면 VS Code 를 찾는다. 공통 설정 키 `editor_command`.
  String get editorCommand => _prefs.getString('editor_command') ?? '';
  Future<void> setEditorCommand(String command) async {
    await _prefs.setString('editor_command', command.trim());
    notifyListeners();
  }

  /// [root] 폴더를 편집기로 여는 명령. 편집기를 못 찾으면 null.
  Future<List<String>?> folderEditorCommand(String root) async {
    final editor = editorCommand;
    if (editor.isNotEmpty) return [...editor.split(RegExp(r'\s+')), root];
    return vscodeOpenCommand(root, path: runner.effectivePath);
  }

  List<String> get recent => _recent;
  EnvironmentStatus get environment => _env;

  @visibleForTesting
  set environment(EnvironmentStatus v) {
    _env = v;
    notifyListeners();
  }

  /// 사용자가 고른 폴더. 저장소 루트와 같거나 그 하위 폴더다. Flutty 같은 칸의 프로젝트 검색 기준.
  String? get selectedDir => _selectedDir;

  /// 열린 저장소(worktree) 루트. 닫혀 있으면 null.
  String? get root => _git?.root;
  GitState? get git => _git;

  /// 열린 저장소의 전체 상태·동작 (Branch Dock 이 쓴다). 닫혀 있거나 테스트용 가짜 원본이면 null.
  RepoController? get repo => (_source is RepoGitStateSource) ? (_source as RepoGitStateSource).repo : null;
  bool get isOpen => _git != null;
  bool get opening => _opening;
  OpenFailure? get failure => _failure;
  String? get failedPath => _failedPath;

  /// 브랜치 전환·커밋 이동·병합 시작/끝. 같은 저장소 안에서만 나온다.
  Stream<HeadChange> get headChanges => _headChanges.stream;

  /// 셸이 등록하는 저장소 열기·폴더 고르기 처리 (확인 창·안내 포함). 칸은 이것을 통해 저장소를 연다.
  Future<void> Function(String path)? openHandler;
  Future<void> Function()? pickFolderHandler;

  Future<void> requestOpen(String path) async {
    final h = openHandler;
    if (h != null) {
      await h(path);
    } else {
      await open(path);
    }
  }

  Future<void> requestPickFolder() async => pickFolderHandler?.call();

  /// 칸이 "지금 중단하면 안 되는 일(빌드·실행·병합 중)"을 알려 주는 검사를 등록한다.
  void registerBusyCheck(bool Function() check) => _busy.add(check);
  void unregisterBusyCheck(bool Function() check) => _busy.remove(check);
  bool get hasRunningWork => _busy.any((c) => c());

  Future<void> checkEnvironment({String? cwd}) async {
    _env = await EnvironmentStatus.check(runner, cwd ?? Directory.systemTemp.path);
    repo?.ghReady = _env.ghReady;
    notifyListeners();
  }

  /// [path] 를 연다. 저장소가 아니면 열려 있던 저장소는 그대로 두고 [failure]만 채운다.
  Future<OpenOutcome> open(String path, {bool force = false}) async {
    final dir = _normalize(path);
    if (dir == null) return _fail(OpenFailure.notFound, path);
    final top = await runner.run(GitCommands.topLevel, workingDirectory: dir, quiet: true);
    final raw = top.stdout.trim();
    if (!top.ok || raw.isEmpty) return _fail(OpenFailure.notARepository, dir);
    final newRoot = _normalize(raw) ?? raw;

    final current = _git?.root;
    if (current != null && _same(current, newRoot)) {
      // 같은 저장소(중첩된 worktree는 toplevel 이 달라 여기에 오지 않는다).
      _failure = null;
      _failedPath = null;
      if (_selectedDir != null && _same(_selectedDir!, dir)) {
        await _source?.refresh();
        return OpenOutcome.refreshed;
      }
      _selectedDir = dir;
      await _remember(dir);
      notifyListeners();
      return OpenOutcome.selectedDirChanged;
    }

    if (current != null && !force && hasRunningWork) return OpenOutcome.needsConfirm;

    _opening = true;
    notifyListeners();
    try {
      final (controller, failure) = await RepoController.open(runner, newRoot);
      if (controller == null) return _fail(failure ?? OpenFailure.notARepository, dir);
      controller.ghReady = _env.ghReady;
      final source = RepoGitStateSource(controller);
      _attach(source, source.current);
      _selectedDir = dir;
      _failure = null;
      _failedPath = null;
      await _remember(dir);
      return OpenOutcome.opened;
    } finally {
      _opening = false;
      notifyListeners();
    }
  }

  /// 테스트·자리표시자용: 이미 만든 [source]로 저장소를 연 것처럼 만든다.
  void attachForTest(GitStateSource source, {String? selectedDir}) {
    _attach(source, source.current ?? const GitState(root: '/test'));
    _selectedDir = selectedDir ?? _git!.root;
    notifyListeners();
  }

  void _attach(GitStateSource source, GitState initial) {
    _sub?.cancel();
    _source?.dispose();
    _source = source;
    _git = initial;
    _sub = source.states.listen(_onState);
  }

  void _onState(GitState next) {
    final prev = _git;
    _git = next;
    final change = prev == null ? null : HeadChange.between(prev, next);
    // 상태(공유 영역 pill)가 먼저 갱신되고, 그 뒤 칸들이 변화를 받는다.
    notifyListeners();
    if (change != null) _headChanges.add(change);
  }

  /// 저장소를 닫고 시작 화면으로 돌아간다.
  void close() {
    _sub?.cancel();
    _source?.dispose();
    _source = null;
    _sub = null;
    _git = null;
    _selectedDir = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _source?.refresh();
    notifyListeners();
  }

  /// 창이 다시 활성화될 때 — 감시가 놓친 변화를 잡는다.
  Future<void> onWindowFocused() => _source?.refresh() ?? Future.value();

  /// 끌어다 놓은 경로 처리 (§1.11).
  Future<DropResult> openDropped(List<String> paths, {bool force = false}) async {
    final dirs = paths.where((p) => FileSystemEntity.isDirectorySync(p)).toList();
    if (dirs.isEmpty) return const DropResult(OpenOutcome.ignoredFiles);
    final outcome = await open(dirs.first, force: force);
    return DropResult(outcome, path: dirs.first, extraIgnored: dirs.length > 1);
  }

  /// 저장소가 아닌 폴더를 git 저장소로 만든다 — 사용자가 "git init" 을 눌렀을 때만.
  Future<OpenOutcome> initRepository(String path) async {
    final r = await runner.run(GitCommands.init, workingDirectory: path);
    if (!r.ok) return _fail(OpenFailure.notARepository, path);
    return open(path);
  }

  Future<void> removeRecent(String path) async {
    _recent = [for (final p in _recent) if (p != path) p];
    await _prefs.setStringList(recentKey, _recent);
    notifyListeners();
  }

  Future<void> _remember(String dir) async {
    _recent = [dir, for (final p in _recent) if (!_same(p, dir)) p].take(maxRecent).toList();
    await _prefs.setStringList(recentKey, _recent);
  }

  OpenOutcome _fail(OpenFailure f, String path) {
    _failure = f;
    _failedPath = path;
    notifyListeners();
    return OpenOutcome.failed;
  }

  /// 존재하는 폴더면 심볼릭 링크를 풀고 끝의 구분자를 뗀 실제 경로, 아니면 null.
  static String? _normalize(String path) {
    try {
      if (!Directory(path).existsSync()) return null;
      return Directory(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      return null;
    }
  }

  static bool _same(String a, String b) {
    String n(String p) => Platform.isWindows ? p.toLowerCase().replaceAll('\\', '/') : p;
    return n(a).replaceAll(RegExp(r'/+$'), '') == n(b).replaceAll(RegExp(r'/+$'), '');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _source?.dispose();
    _headChanges.close();
    super.dispose();
  }
}
