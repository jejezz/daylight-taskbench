// 색 구성이 화면 전체에 퍼지려면 화면 코드가 색을 테마에서 읽어야 한다 (settings.md "색을 테마에서 읽기").
// `AppColors.*` 상수나 `Color(0x…)` 리터럴을 위젯에서 직접 쓰면 그 부분만 색 구성을 따라가지 않는다.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 색 값을 정해도 되는 곳: 테마 정의와 장식 위젯(테마 확장에서 파생해 쓴다).
bool _allowed(String path) => path.startsWith('lib/theme/') || path.startsWith('lib/ui/style/');

void main() {
  final files = [
    for (final e in Directory('lib').listSync(recursive: true))
      if (e is File && e.path.endsWith('.dart') && !e.path.contains('/l10n/') && !_allowed(e.path)) e,
  ];

  test('화면 코드는 AppColors·색 리터럴을 직접 쓰지 않는다', () {
    final bad = <String>[];
    final literal = RegExp(r'AppColors\.|Color\(0x[0-9A-Fa-f]+\)');
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final l = lines[i].trim();
        if (l.startsWith('//') || l.startsWith('///')) continue;
        if (literal.hasMatch(l)) bad.add('${f.path}:${i + 1}: $l');
      }
    }
    expect(bad, isEmpty, reason: '색은 Theme.of(context).colorScheme · lib/theme 의 토큰에서 읽어야 한다');
  });

  test('이 검사가 실제 파일을 보고 있다', () {
    expect(files.length, greaterThan(40));
  });
}
