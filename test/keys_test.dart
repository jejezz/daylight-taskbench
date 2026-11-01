// 저장 키·ARB 키 충돌을 막는 검사 (PLAN.md §3.2, §6 위험표). 칸을 더해도 이 규칙이 지켜진다.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 접두어 없이 쓰는 공통 저장 키 (설정 규약 + 앱 공통).
const _commonKeys = {
  'theme_mode', 'theme_palette', 'text_scale', 'app_locale', // 규약 (settings.md · localization.md)
  'style_state_tint', // 앱 공통 설정 (localization.md §5 `<기능>_<이름>`)
  'recent_dirs', 'dock_expanded', 'editor_command', // Workspace · 셸 · 편집기에서 열기(공통)
  'window_placement', // 창 크기·위치 (window-placement.md 템플릿)
  'window_size_dock', 'window_width_dock', 'window_width_explorer', 'window_width_expanded', // 모드별 창 크기 (§1.13)
  'panel_center', 'editor_embedded', // 확장 패널: 가운데 마지막 선택 · 내장 에디터 설정 (§1.13)
  'terminal_font_size', 'terminal_scrollback', // 터미널 설정 (§1.13)
};

/// 칸 id 접두어. 칸이 늘면 여기에 더한다.
const _dockPrefixes = ['branch.', 'flutty.', 'gradle.', 'rust.', 'electron.'];

List<File> _dartFiles(String dir) => [
      for (final e in Directory(dir).listSync(recursive: true))
        if (e is File && e.path.endsWith('.dart') && !e.path.contains('/l10n/')) e,
    ];

void main() {
  test('ARB: ko/en 키가 같고, 중복 키가 없다', () {
    Set<String> keysOf(String f) {
      final text = File(f).readAsStringSync();
      final keys = <String>[];
      // 최상위 키만: 두 칸 들여쓴 `"key":` 줄
      for (final m in RegExp(r'^  "([^"@][^"]*)":', multiLine: true).allMatches(text)) {
        keys.add(m.group(1)!);
      }
      expect(keys.toSet().length, keys.length, reason: '$f 에 중복 키');
      expect(() => jsonDecode(text), returnsNormally);
      return keys.toSet();
    }

    expect(keysOf('lib/l10n/app_ko.arb'), keysOf('lib/l10n/app_en.arb'));
  });

  // SharedPreferences 호출(`prefs.getString('…')` 등)과 `…Key = '…'` 상수만 본다 — Map·환경 변수 조회는 제외.
  final prefsCall = RegExp(r"""\b_?prefs\.(?:get|set|remove|containsKey)(?:String|StringList|Bool|Double|Int)?\(\s*['"]([^'"]+)['"]""");
  final keyConst = RegExp(r"""static const \w*[kK]ey\s*=\s*['"]([a-z][^'"]*)['"]""");

  Iterable<String> storedKeys() sync* {
    for (final f in _dartFiles('lib')) {
      final text = f.readAsStringSync();
      for (final m in [...prefsCall.allMatches(text), ...keyConst.allMatches(text)]) {
        yield '${f.path}\u0000${m.group(1)}';
      }
    }
  }

  test('저장 키는 공통 목록에 있거나, 칸 접두어(branch. flutty. …)로 시작한다', () {
    final found = storedKeys().toList();
    expect(found, isNotEmpty); // 검사가 아무것도 못 잡고 통과하는 일을 막는다
    final bad = <String>[];
    for (final entry in found) {
      final parts = entry.split('\u0000');
      final k = parts[1];
      final ok = _commonKeys.contains(k) || _dockPrefixes.any(k.startsWith) || k.startsWith('tool_path_');
      if (!ok) bad.add('${parts[0]}: $k');
    }
    expect(bad, isEmpty, reason: '접두어 규칙을 벗어난 저장 키');
  });

  test('이 검사가 실제 키를 잡는다 (공통 키가 목록에 모두 나타난다)', () {
    final keys = storedKeys().map((e) => e.split('\u0000')[1]).toSet();
    for (final k in ['theme_mode', 'theme_palette', 'text_scale', 'app_locale', 'style_state_tint', 'recent_dirs']) {
      expect(keys, contains(k), reason: k);
    }
  });
}
