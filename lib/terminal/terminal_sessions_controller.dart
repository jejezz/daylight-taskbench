/// 열려 있는 터미널 탭(세션) 목록과 선택된 탭. daylight-terminal-flutter의 state/sessions_controller.dart를
/// 로컬 셸 한 가지만 다루게 줄인 것 — SSH·시리얼·탭 기억(복원)은 없다.
library;

import 'package:flutter/foundation.dart';

import 'local_shell.dart';
import 'local_shell_finder.dart';
import 'local_shell_session.dart';
import 'pty_backend.dart';

class TerminalSessionsController extends ChangeNotifier {
  /// [scrollback]은 새 탭을 만들 때마다 불러 스크롤백 줄 수를 얻는다 (설정이 바뀌어도 새 탭부터 적용).
  /// [shellFinder]와 [ptyFactory]는 테스트에서 가짜로 바꿔 끼운다.
  TerminalSessionsController({this.scrollback, LocalShellFinder? shellFinder, this.ptyFactory})
    : _shellFinder = shellFinder ?? LocalShellFinder();

  final int Function()? scrollback;
  final LocalShellFinder _shellFinder;
  final PtyFactory? ptyFactory;

  final List<LocalShellSession> sessions = [];

  /// [Taskbench에서 달라진 곳] 터미널 패널이 처음 열릴 때 기본 셸을 한 번 자동으로 띄웠는가.
  /// 사용자가 탭을 모두 닫은 뒤에는 다시 자동으로 띄우지 않는다.
  bool autoOpened = false;
  int _selected = 0;
  List<LocalShell> _shells = const [];
  bool _shellsLoaded = false;

  int get selected => _selected;
  LocalShellSession? get current => sessions.isEmpty ? null : sessions[_selected];

  /// 이 컴퓨터에서 탭으로 열 수 있는 로컬 셸. [loadShells]가 끝나기 전에는 비어 있다. 첫 번째가 기본 셸.
  List<LocalShell> get shells => _shells;
  bool get shellsLoaded => _shellsLoaded;

  /// 설치된 셸을 찾는다 (Windows에서는 WSL 배포판을 묻느라 잠깐 걸린다). 앱을 켤 때 한 번 부른다.
  Future<void> loadShells() async {
    if (_shellsLoaded) return;
    try {
      _shells = await _shellFinder.find();
    } catch (e) {
      debugPrint('shell discovery failed: $e');
      _shells = const [];
    }
    _shellsLoaded = true;
    notifyListeners();
  }

  /// [workingDirectory]에서 셸을 띄우고 탭으로 연다. [shell]을 안 주면 기본 셸.
  /// 쓸 수 있는 셸이 없으면(아직 못 찾았거나 하나도 없으면) null.
  LocalShellSession? add(String workingDirectory, [LocalShell? shell]) {
    final chosen = shell ?? (_shells.isEmpty ? null : _shells.first);
    if (chosen == null) return null;
    final session = LocalShellSession(
      chosen,
      workingDirectory: workingDirectory,
      scrollback: scrollback?.call() ?? 10000,
      ptyFactory: ptyFactory,
    );
    session.addListener(notifyListeners);
    sessions.add(session);
    _selected = sessions.length - 1;
    notifyListeners();
    session.start();
    return session;
  }

  void select(int index) {
    if (index < 0 || index >= sessions.length || index == _selected) return;
    _selected = index;
    notifyListeners();
  }

  /// [from] 자리의 탭을 [to] 자리로 옮긴다. 선택된 탭은 그대로 유지된다.
  void move(int from, int to) {
    if (from < 0 || from >= sessions.length || to < 0 || to >= sessions.length || from == to) return;
    final keep = sessions[_selected];
    sessions.insert(to, sessions.removeAt(from));
    _selected = sessions.indexOf(keep);
    notifyListeners();
  }

  void closeAt(int index) {
    if (index < 0 || index >= sessions.length) return;
    final removed = sessions.removeAt(index);
    removed.removeListener(notifyListeners);
    if (_selected > index || _selected >= sessions.length) {
      _selected = (_selected - 1).clamp(0, sessions.isEmpty ? 0 : sessions.length - 1);
    }
    notifyListeners();
    // 위젯 트리가 이 세션을 내려놓은 다음에 정리한다.
    Future<void>.microtask(removed.dispose);
  }

  void closeCurrent() => closeAt(_selected);

  @override
  void dispose() {
    for (final s in sessions) {
      s.removeListener(notifyListeners);
      s.dispose();
    }
    super.dispose();
  }
}
