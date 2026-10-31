import 'dart:async';

import 'package:flutter/foundation.dart';

/// 앱이 실행한 명령 하나 — 명령 바와 로그 패널에 보인다 (PLAN.md 3.12).
class CommandLogEntry {
  CommandLogEntry({required this.args, required this.started});

  /// 실행 파일 이름(`git`, `gh`)을 포함한 전체 인자.
  final List<String> args;
  final DateTime started;

  /// 한 항목이 보관하는 출력의 상한. 넘으면 앞부분을 버리고 꼬리만 남긴다 — `cargo`·`gradle` 같은
  /// 긴 빌드가 수천 줄을 내도 화면과 메모리가 버틴다.
  static const maxOutputChars = 1 << 20;

  StringBuffer _output = StringBuffer();
  int _dropped = 0;
  int? exitCode;
  Duration? duration;
  bool cancelled = false;

  bool get running => exitCode == null && !cancelled;
  bool get succeeded => exitCode == 0;
  String get output => _dropped == 0 ? _output.toString() : '[… $_dropped characters omitted]\n$_output';

  /// 버려진 앞부분의 글자 수 (0이면 전부 보관 중).
  int get droppedChars => _dropped;

  /// 사람이 읽고 복사해서 터미널에 붙여 넣을 수 있는 형태.
  String get commandLine => formatCommandLine(args);

  void append(String text) {
    _output.write(text);
    if (_output.length > maxOutputChars * 5 ~/ 4) {
      final all = _output.toString();
      final keep = all.substring(all.length - maxOutputChars);
      _dropped += all.length - keep.length;
      _output = StringBuffer(keep);
    }
  }
}

/// 셸에 그대로 붙여 넣을 수 있도록 공백·특수 문자가 있는 인자만 따옴표로 감싼다.
String formatCommandLine(List<String> args) => args.map(_quote).join(' ');

final _safe = RegExp(r'^[A-Za-z0-9_\-./:=@,+%^~]+$');

String _quote(String arg) {
  if (arg.isNotEmpty && _safe.hasMatch(arg)) return arg;
  return "'${arg.replaceAll("'", r"'\''")}'";
}

/// 최근 명령 기록. 오래된 것부터 버린다.
class CommandLog extends ChangeNotifier {
  CommandLog({this.capacity = 200});

  final int capacity;
  final List<CommandLogEntry> _entries = [];

  List<CommandLogEntry> get entries => List.unmodifiable(_entries);
  CommandLogEntry? get last => _entries.isEmpty ? null : _entries.last;

  CommandLogEntry start(List<String> args) {
    final entry = CommandLogEntry(args: args, started: DateTime.now());
    _entries.add(entry);
    if (_entries.length > capacity) _entries.removeAt(0);
    notifyListeners();
    return entry;
  }

  void update() {
    _pending?.cancel();
    _pending = null;
    notifyListeners();
  }

  Timer? _pending;
  DateTime? _lastNotify;

  /// 출력이 쏟아지는 동안의 갱신: 처음 한 번은 바로, 그 뒤는 [interval] 에 한 번으로 묶고 마지막 변화는
  /// 타이머로 반드시 알린다. 명령이 끝나면 [update] 가 대기 중인 타이머를 정리한다.
  void updateThrottled({Duration interval = const Duration(milliseconds: 100)}) {
    final now = DateTime.now();
    final last = _lastNotify;
    if (last == null || now.difference(last) >= interval) {
      _lastNotify = now;
      update();
      return;
    }
    _pending ??= Timer(interval, () {
      _pending = null;
      _lastNotify = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}
