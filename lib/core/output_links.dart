// 명령 출력 속의 "파일 위치"(오류·경고가 가리키는 `path:줄:칸`)를 찾아 파일로 바꾼다 (PLAN.md §5 단계 16).
// 출력에서 찾는 것은 모양뿐이라 오탐이 있다 — 실제로 있는 파일로 풀리는 것만 링크로 쓴다 ([resolveOutputLink]).

import 'dart:io';

/// 출력 글자 `[start, end)` 가 가리키는 파일 위치. [path] 는 출력에 적힌 그대로(상대 경로일 수 있다).
class OutputLink {
  const OutputLink({
    required this.start,
    required this.end,
    required this.path,
    required this.line,
    this.column = 1,
    this.package = false,
  });

  final int start;
  final int end;
  final String path;
  final int line;
  final int column;

  /// `package:name/…` 형태였다 — [path] 는 `lib/` 아래 경로다.
  final bool package;

  @override
  String toString() => 'OutputLink($path:$line:$column @$start-$end)';
}

// 경로에 쓰는 글자: 공백·따옴표·괄호·콜론 따위를 뺀다 (공백이 든 경로는 포기한다).
const _seg = r'''[^\s:'"()<>|*?]''';
final _pattern = RegExp(
  // 앞 글자가 경로·단어 글자면 중간에서 시작한 것이라 건너뛴다 (URL 의 `//host:80` 도 여기서 걸러진다).
  r'(?<![\w:/\\.@-])(?:'
  // 1) file:///경로:줄:칸
  '(?<file>file:///?$_seg+?):(?<fl>\\d+)(?::(?<fc>\\d+))?'
  // 2) package:이름/경로:줄:칸
  '|package:(?<pkg>$_seg+?):(?<pl>\\d+)(?::(?<pc>\\d+))?'
  // 3) 경로:줄(:칸) — 드라이브·절대·상대·그냥 상대, 확장자가 있어야 한다
  '|(?<p>(?:[A-Za-z]:[\\\\/]|\\.{1,2}[\\\\/]|/)?$_seg+?\\.[A-Za-z0-9]+):(?<pl3>\\d+)(?::(?<pc3>\\d+))?'
  // 4) MSVC: 경로(줄,칸)
  '|(?<m>(?:[A-Za-z]:[\\\\/])?[^\\s()]+?\\.[A-Za-z0-9]+)\\((?<ml>\\d+)(?:,(?<mc>\\d+))?\\)'
  ')',
);

/// [text] 에서 파일 위치를 모두 찾는다 (겹치지 않게, 앞에서부터).
List<OutputLink> findOutputLinks(String text) {
  final links = <OutputLink>[];
  for (final m in _pattern.allMatches(text)) {
    int? num(String? s) => s == null ? null : int.tryParse(s);
    String? path;
    int? line;
    int? col;
    var package = false;
    if (m.namedGroup('file') != null) {
      path = _fileUrlToPath(m.namedGroup('file')!);
      line = num(m.namedGroup('fl'));
      col = num(m.namedGroup('fc'));
    } else if (m.namedGroup('pkg') != null) {
      // `package:name/a/b.dart` → `a/b.dart` (이름은 버린다. lib/ 아래라고 가정)
      final raw = m.namedGroup('pkg')!;
      final slash = raw.indexOf('/');
      if (slash > 0) path = raw.substring(slash + 1);
      package = true;
      line = num(m.namedGroup('pl'));
      col = num(m.namedGroup('pc'));
    } else if (m.namedGroup('p') != null) {
      path = m.namedGroup('p');
      line = num(m.namedGroup('pl3'));
      col = num(m.namedGroup('pc3'));
    } else if (m.namedGroup('m') != null) {
      path = m.namedGroup('m');
      line = num(m.namedGroup('ml'));
      col = num(m.namedGroup('mc'));
    }
    if (path == null || line == null || line < 1) continue;
    links.add(
      OutputLink(
        start: m.start,
        end: m.end,
        path: path,
        line: line,
        column: (col == null || col < 1) ? 1 : col,
        package: package,
      ),
    );
  }
  return links;
}

String _fileUrlToPath(String url) {
  try {
    return Uri.parse(Uri.encodeFull(url))
        .toFilePath(windows: Platform.isWindows);
  } on Object {
    return url.replaceFirst(RegExp(r'^file:/+'), '/');
  }
}

bool _isAbsolute(String p) =>
    p.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(p);

/// [link] 가 가리키는 실제 파일 경로. [bases] (명령을 돌린 폴더, 선택한 폴더, 저장소 루트 …) 를 차례로 시도하고,
/// 없으면 null. `package:` 는 각 base 의 `lib/` 아래를 본다.
String? resolveOutputLink(
  OutputLink link,
  List<String> bases, {
  bool Function(String path)? exists,
}) {
  final has = exists ?? (String p) => File(p).existsSync();
  final sep = Platform.pathSeparator;
  if (!link.package && _isAbsolute(link.path)) {
    return has(link.path) ? link.path : null;
  }
  for (final base in bases) {
    final rel = link.package ? 'lib/${link.path}' : link.path;
    final joined = '$base$sep${rel.replaceAll('/', sep)}';
    final normalized = Uri.file(joined)
        .normalizePath()
        .toFilePath(windows: Platform.isWindows);
    if (has(normalized)) return normalized;
  }
  return null;
}
