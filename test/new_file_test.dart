import 'dart:io';

import 'package:daylight_taskbench/explorer/new_file.dart';
import 'package:daylight_taskbench/settings/system_fonts.dart';
import 'package:daylight_taskbench/theme/editor_schemes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('newfile_'));
  tearDown(() => root.deleteSync(recursive: true));

  test('새 파일을 만들고, 하위 폴더도 함께 만든다', () async {
    final a = await createNewFile(rootDir: root.path, baseDir: root.path, input: ' a.dart ');
    expect(a.result, NewFileResult.created);
    expect(File(p.join(root.path, 'a.dart')).existsSync(), isTrue);
    final b = await createNewFile(rootDir: root.path, baseDir: root.path, input: 'lib/x/b.dart');
    expect(b.result, NewFileResult.created);
    expect(File(p.join(root.path, 'lib', 'x', 'b.dart')).existsSync(), isTrue);
  });

  test('이미 있으면 덮어쓰지 않는다', () async {
    final f = File(p.join(root.path, 'a.txt'))..writeAsStringSync('keep');
    final r = await createNewFile(rootDir: root.path, baseDir: root.path, input: 'a.txt');
    expect(r.result, NewFileResult.exists);
    expect(f.readAsStringSync(), 'keep');
  });

  test('저장소 밖·절대 경로·빈 이름·쓸 수 없는 글자는 거부한다', () async {
    for (final bad in ['', '  ', '../out.txt', 'a/../../out.txt', '/abs.txt', 'dir/', 'a?b', 'x:y']) {
      final r = await createNewFile(rootDir: root.path, baseDir: root.path, input: bad);
      expect(r.result, NewFileResult.invalid, reason: '"$bad"');
    }
  });

  test('고른 하위 폴더 안에 만든다', () async {
    final sub = Directory(p.join(root.path, 'sub'))..createSync();
    final r = await createNewFile(rootDir: root.path, baseDir: sub.path, input: 'n.md');
    expect(r.result, NewFileResult.created);
    expect(File(p.join(sub.path, 'n.md')).existsSync(), isTrue);
  });

  test('Windows 레지스트리 출력에서 글꼴 가족 이름을 뽑는다', () {
    const out = r'''
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
    Cascadia Mono Regular (TrueType)    REG_SZ    CascadiaMono.ttf
    Segoe UI Semibold (TrueType)    REG_SZ    seguisb.ttf
    Cambria & Cambria Math (TrueType)    REG_SZ    cambria.ttc
''';
    expect(
      SystemFonts.parseWindowsRegistry(out),
      {'Cascadia Mono', 'Segoe UI', 'Cambria', 'Cambria Math'},
    );
  });

  test('고정폭 글꼴 이름을 가려낸다', () {
    expect(SystemFonts.looksMonospaced('Cascadia Mono'), isTrue);
    expect(SystemFonts.looksMonospaced('Consolas'), isTrue);
    expect(SystemFonts.looksMonospaced('Segoe UI'), isFalse);
  });

  test('편집기 색상 구성표: id 가 겹치지 않고, 모르는 id 는 앱 테마를 따른다', () {
    final ids = EditorScheme.choices.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(EditorScheme.byId('dracula')?.name, 'Dracula');
    expect(EditorScheme.byId(EditorScheme.followAppId), isNull);
    expect(EditorScheme.byId('nope'), isNull);
    expect(EditorScheme.byId(null), isNull);
  });
}
