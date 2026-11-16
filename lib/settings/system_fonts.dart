// 설치된 글꼴 이름 목록. Flutter 에는 시스템 글꼴을 나열하는 API 가 없어서 OS 에 물어본다.
//   Windows: 레지스트리 `Fonts` 키 (HKLM·HKCU)   macOS: `system_profiler SPFontsDataType` (몇 초 걸려서 한 번만)
// 읽지 못하면 미리 정해 둔 후보 목록으로 대신한다 — 없는 글꼴을 골라도 Flutter 가 대체 글꼴로 그리므로 깨지지 않는다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SystemFonts {
  SystemFonts._();

  static final instance = SystemFonts._();

  Future<List<String>>? _all;

  /// 설치된 글꼴 가족 이름(중복 없이 정렬). 한 번 읽은 뒤에는 같은 결과를 돌려준다.
  Future<List<String>> families() => _all ??= _read();

  /// [families] 중 고정폭으로 보이는 것. 이름만으로 가려내므로 완벽하지 않다.
  Future<List<String>> monospaced() async => [
    for (final f in await families())
      if (looksMonospaced(f)) f,
  ];

  /// 테스트에서 OS 를 읽지 않도록 값을 미리 넣는다.
  void debugSet(List<String> families) => _all = Future.value(families);

  static final _monoName = RegExp(
    r'mono|code|consolas|courier|menlo|monaco|hack|inconsolata|iosevka|'
    r'lucida console|fixedsys|andale|cascadia|d2coding|gothic coding|'
    r'victor|terminus|source code|jetbrains|fira',
    caseSensitive: false,
  );

  static bool looksMonospaced(String family) =>
      _monoName.hasMatch(family) && !family.toLowerCase().contains('sans mono cjk');

  /// OS 를 읽지 못했을 때 쓰는 후보.
  static const fallbackUi = [
    'Segoe UI',
    'Malgun Gothic',
    'Apple SD Gothic Neo',
    'Noto Sans KR',
    'Arial',
    'Verdana',
    'Tahoma',
    'Helvetica Neue',
  ];

  static const fallbackMono = [
    'Cascadia Mono',
    'Cascadia Code',
    'Consolas',
    'Menlo',
    'SF Mono',
    'Monaco',
    'JetBrains Mono',
    'Fira Code',
    'D2Coding',
    'Courier New',
  ];

  Future<List<String>> _read() async {
    try {
      final names = Platform.isWindows
          ? await _windows()
          : Platform.isMacOS
          ? await _macos()
          : <String>{};
      if (names.isNotEmpty) {
        // 글꼴 이름이 아닌 숨은 글꼴(@로 시작하는 세로쓰기용 등)은 뺀다.
        return (names.where((n) => n.isNotEmpty && !n.startsWith('@')).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));
      }
    } on Object {
      // 읽지 못했다 — 후보 목록으로 넘어간다.
    }
    return [...{...fallbackUi, ...fallbackMono}]..sort();
  }

  Future<Set<String>> _windows() async {
    final out = <String>{};
    for (final key in const [
      r'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
      r'HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts',
    ]) {
      final r = await Process.run('reg', ['query', key])
          .timeout(const Duration(seconds: 8));
      if (r.exitCode != 0) continue;
      out.addAll(parseWindowsRegistry(utf8Safe(r.stdout)));
    }
    return out;
  }

  Future<Set<String>> _macos() async {
    final r = await Process.run('system_profiler', ['SPFontsDataType'])
        .timeout(const Duration(seconds: 40));
    if (r.exitCode != 0) return {};
    return parseMacProfiler(utf8Safe(r.stdout));
  }

  static String utf8Safe(Object? stdout) =>
      stdout is String ? stdout : utf8.decode(stdout as List<int>, allowMalformed: true);

  static final _styleWords = RegExp(
    r'\s+(regular|bold|italic|oblique|light|semilight|semibold|extrabold|extralight|'
    r'black|thin|medium|demi|book|condensed|narrow|heavy|ultra)\b.*$',
    caseSensitive: false,
  );

  /// `reg query` 출력의 `이름 (TrueType)    REG_SZ    파일` 줄들에서 가족 이름을 뽑는다.
  /// `A & B (TrueType)` 처럼 묶여 있으면 각각으로 나눈다. 굵기·기울임 낱말은 가족 이름에서 뺀다.
  static Set<String> parseWindowsRegistry(String text) {
    final out = <String>{};
    final line = RegExp(r'^\s*(.+?)\s+\((?:TrueType|OpenType|Type 1)\)\s+REG_SZ', caseSensitive: false);
    for (final raw in const LineSplitter().convert(text)) {
      final m = line.firstMatch(raw);
      if (m == null) continue;
      for (final part in m.group(1)!.split(' & ')) {
        final family = part.replaceFirst(_styleWords, '').trim();
        if (family.isNotEmpty) out.add(family);
      }
    }
    return out;
  }

  /// `system_profiler` 출력의 `Family: 이름` 줄들.
  static Set<String> parseMacProfiler(String text) => {
    for (final m in RegExp(r'^\s*Family:\s*(.+?)\s*$', multiLine: true).allMatches(text))
      m.group(1)!,
  };
}
