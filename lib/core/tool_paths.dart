// 사용자가 직접 지정한 실행 파일 경로 (git·gh·flutter·adb …) — Branch 의 tool_path_sheet 와
// Flutty 의 tool_paths_dialog 를 하나로 합친 저장소 (PLAN.md 단계 2). 화면은 설정 창의 "도구" 구역.
//
// 저장 키는 도구마다 `tool_path_<이름>` (공통 키 — 접두어 없음). 값이 없으면 PATH 에서 찾는다.
// 새 runner 칸은 자기 도구를 [ToolPaths.known] 에 더하면 설정 창에 줄이 생긴다.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'command_runner.dart';

@immutable
class ToolSpec {
  const ToolSpec(this.name, this.label);

  /// 실행 이름 (`git`, `gh`, `flutter`, `adb`). `CommandRunner.toolPaths` 의 키이기도 하다.
  final String name;
  final String label;

  String get prefsKey => 'tool_path_$name';
}

class ToolPaths extends ChangeNotifier {
  ToolPaths({
    required this.runner,
    required this._prefs,
    List<ToolSpec> known = defaultTools,
  }) : known = List.of(known) {
    _load();
  }

  /// 앞으로 칸이 더해질 때마다 여기에 도구가 늘어난다 (Flutty: flutter·adb, Rust: cargo …).
  static const defaultTools = [
    ToolSpec('git', 'git'),
    ToolSpec('gh', 'gh (GitHub CLI)'),
  ];

  final CommandRunner runner;
  final SharedPreferences _prefs;
  final List<ToolSpec> known;

  /// 지정이 바뀐 뒤 불린다 — 예: 환경 점검을 다시 한다.
  VoidCallback? onChanged;

  void _load() {
    final map = <String, String>{};
    for (final t in known) {
      final v = _prefs.getString(t.prefsKey);
      if (v != null && v.isNotEmpty) map[t.name] = v;
    }
    runner.toolPaths = map;
  }

  /// 도구를 더한다 (이미 있으면 무시). 저장된 값이 있으면 runner 에 바로 반영된다.
  void register(ToolSpec spec) {
    if (known.any((t) => t.name == spec.name)) return;
    known.add(spec);
    _load();
    notifyListeners();
  }

  String? customPath(String name) => runner.toolPaths[name];

  /// 실제로 실행하게 될 파일. 지정이 없으면 PATH 에서 찾고, 못 찾으면 null.
  String? resolved(String name) => runner.locate(name);

  /// [path]가 null 이거나 비어 있으면 지정을 지운다.
  Future<void> set(String name, String? path) async {
    final spec = known.firstWhere((t) => t.name == name);
    final v = path?.trim();
    if (v == null || v.isEmpty) {
      await _prefs.remove(spec.prefsKey);
    } else {
      await _prefs.setString(spec.prefsKey, v);
    }
    _load();
    notifyListeners();
    onChanged?.call();
  }
}

class ToolPathsScope extends InheritedNotifier<ToolPaths> {
  const ToolPathsScope({
    super.key,
    required ToolPaths tools,
    required super.child,
  }) : super(notifier: tools);

  static ToolPaths? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ToolPathsScope>()?.notifier;
}
