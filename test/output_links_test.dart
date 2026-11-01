import 'package:daylight_taskbench/core/output_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> found(String text) => [
    for (final l in findOutputLinks(text))
      '${l.path}:${l.line}:${l.column}${l.package ? ' (pkg)' : ''}',
  ];

  test('flutter/dart 오류: lib/main.dart:12:5', () {
    expect(found("lib/main.dart:12:5: Error: Expected ';'"), [
      'lib/main.dart:12:5',
    ]);
  });

  test('칸이 없으면 1', () {
    expect(found('lib/a/b.dart:7 warning'), ['lib/a/b.dart:7:1']);
  });

  test('package:이름/경로 는 lib 아래 경로로 푼다', () {
    expect(found('#0 main (package:my_app/src/x.dart:30:9)'), [
      'src/x.dart:30:9 (pkg)',
    ]);
  });

  test('file:// 주소와 gradle/kotlin 오류', () {
    expect(found('e: file:///Users/me/app/Main.kt:10:4 Unresolved'), [
      '/Users/me/app/Main.kt:10:4',
    ]);
  });

  test('절대·상대(./ ../)·윈도 드라이브 경로', () {
    expect(found('/a/b/c.dart:1:2 x'), ['/a/b/c.dart:1:2']);
    expect(found('./c.dart:3 x ../d.dart:4:1'), [
      './c.dart:3:1',
      '../d.dart:4:1',
    ]);
    expect(found(r'C:\proj\lib\m.dart:5:6: error'), [
      r'C:\proj\lib\m.dart:5:6',
    ]);
  });

  test('MSVC 모양: file(line,col)', () {
    expect(found(r'C:\p\x.cpp(12,5): error C2065'), [r'C:\p\x.cpp:12:5']);
    expect(found('src/y.cpp(7): warning'), ['src/y.cpp:7:1']);
  });

  test('URL 은 링크가 아니다', () {
    expect(found('Serving at http://localhost:8080/index.html'), isEmpty);
    expect(found('see https://example.com:443/x.html'), isEmpty);
  });

  test('글자 범위가 맞다', () {
    const t = 'at lib/m.dart:3:4 boom';
    final l = findOutputLinks(t).single;
    expect(t.substring(l.start, l.end), 'lib/m.dart:3:4');
  });

  test('resolve: base 를 차례로 보고, 없으면 null', () {
    const l = OutputLink(start: 0, end: 1, path: 'lib/m.dart', line: 1);
    bool exists(String p) => p == '/r/app/lib/m.dart';
    expect(
      resolveOutputLink(l, ['/r', '/r/app'], exists: exists),
      '/r/app/lib/m.dart',
    );
    expect(resolveOutputLink(l, ['/r'], exists: exists), isNull);
    const pk = OutputLink(
      start: 0,
      end: 1,
      path: 'm.dart',
      line: 1,
      package: true,
    );
    expect(
      resolveOutputLink(pk, ['/r/app'], exists: exists),
      '/r/app/lib/m.dart',
    );
    const abs = OutputLink(
      start: 0,
      end: 1,
      path: '/r/app/lib/m.dart',
      line: 1,
    );
    expect(resolveOutputLink(abs, [], exists: exists), '/r/app/lib/m.dart');
  });
}
