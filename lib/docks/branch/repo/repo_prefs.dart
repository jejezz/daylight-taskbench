import 'package:shared_preferences/shared_preferences.dart';

import '../git/commands.dart';
import '../release/version_files.dart';

/// Branch Dock 이 저장소별로 기억할 값과 설정 (PLAN.md §5 저장).
///
/// [Taskbench에서 달라진 곳] 저장 키는 `branch.` 접두어(PLAN.md §3.2). 최근 목록은 Workspace,
/// 창 크기·위치는 WindowPlacement, git/gh 경로는 ToolPaths, 편집기 명령은 공통 설정 `editor_command`가 맡는다.
class RepoPrefs {
  RepoPrefs(this._prefs);

  static Future<RepoPrefs> load() async => RepoPrefs(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _editorKey = 'editor_command';

  PullMode pullMode(String repo) =>
      PullMode.values.asNameMap()[_prefs.getString('branch.pull_mode:$repo')] ?? PullMode.merge;

  Future<void> setPullMode(String repo, PullMode mode) => _prefs.setString('branch.pull_mode:$repo', mode.name);

  /// 자동 fetch (PLAN.md 3.3 P1). 기본은 켬.
  bool get autoFetch => _prefs.getBool('branch.auto_fetch') ?? true;
  Future<void> setAutoFetch(bool value) => _prefs.setBool('branch.auto_fetch', value);

  /// Push할 때 태그도 함께 (--follow-tags). 저장소별, 기본은 끔.
  bool followTags(String repo) => _prefs.getBool('branch.push_follow_tags:$repo') ?? false;
  Future<void> setFollowTags(String repo, bool value) => _prefs.setBool('branch.push_follow_tags:$repo', value);

  /// 저장소별로 정한 버전 파일 (PLAN.md 3.8.2a). 없으면 자동 감지.
  CustomVersionFile? customVersionFile(String repo) {
    final v = _prefs.getStringList('branch.version_file:$repo');
    return v == null || v.length != 2 ? null : CustomVersionFile(v[0], v[1]);
  }

  Future<void> setCustomVersionFile(String repo, CustomVersionFile? f) => f == null
      ? _prefs.remove('branch.version_file:$repo')
      : _prefs.setStringList('branch.version_file:$repo', [f.path, f.pattern]);

  int lastTab(String repo) => _prefs.getInt('branch.last_tab:$repo') ?? 0;
  Future<void> setLastTab(String repo, int tab) => _prefs.setInt('branch.last_tab:$repo', tab);

  /// 파일을 여는 편집기 명령(예: `code`). 비어 있으면 OS 기본 앱.
  String get editorCommand => _prefs.getString(_editorKey) ?? '';
  Future<void> setEditorCommand(String command) => _prefs.setString(_editorKey, command.trim());
}
