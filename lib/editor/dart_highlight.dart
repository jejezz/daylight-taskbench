/// 구문 강조용 Dart 문법: `re_highlight`의 기본 Dart 문법에 Flutter 코드를 더 폭넓게 칠하는 규칙을 덧붙인 것.
///
/// 기본 문법은 키워드·문자열·숫자·주석·어노테이션·클래스 선언 이름만 구분한다. 여기서는 다음을 더 구분한다.
///  - 함수·메서드 이름(선언과 호출, `Theme.of(…)`의 `of` 포함)  → `title.function_`
///  - 타입·클래스 이름과 위젯 생성(`Scaffold(`, `Text(`, `BuildContext`) → `type`
///  - 이름 붙인 인자(`child:`, `onPressed:`) → `attr`
///  - `true`/`false`/`null` → `literal`
///  - Flutter 프레임워크의 핵심 이름(`Widget`, `BuildContext`, `State` …) → `built_in`
///
/// 색은 [SyntaxTokens.highlightTheme]이 정한다 (이 파일은 이름표만 붙인다).
library;

import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/re_highlight.dart';

/// Flutter 프레임워크의 핵심 이름. Dart 기본 내장 이름과 같은 색으로 칠한다.
const flutterCoreNames = [
  'Widget',
  'BuildContext',
  'State',
  'StatelessWidget',
  'StatefulWidget',
  'InheritedWidget',
  'InheritedNotifier',
  'ChangeNotifier',
  'ValueNotifier',
  'ValueListenable',
  'Listenable',
  'Key',
  'ValueKey',
  'GlobalKey',
  'VoidCallback',
  'Navigator',
  'Theme',
  'ThemeData',
  'ThemeMode',
  'MediaQuery',
  'Colors',
  'Icons',
  'TextEditingController',
  'ScrollController',
  'FocusNode',
  'WidgetsBinding',
];

List<String> _words(Object? list) => [
  for (final w in (list as List).cast<String>()) w.replaceAll('?', ''),
];

Mode _build() {
  final base = langDart;
  final keywords = Map<String, dynamic>.of(
    base.keywords as Map<String, dynamic>,
  );
  final dartKeywords = _words(keywords['keyword']);
  final dartBuiltIns = _words(keywords['built_in']);
  keywords['built_in'] = <String>[
    ...(keywords['built_in'] as List).cast<String>(),
    ...flutterCoreNames,
  ];

  final keywordAlt = dartKeywords.toSet().join('|');
  final builtInAlt = {...dartBuiltIns, ...flutterCoreNames}.join('|');

  final extras = <Mode>[
    // true/false/null은 기본 문법에서는 키워드 색이라 다른 키워드와 구분되지 않는다.
    Mode(scope: 'literal', begin: r'\b(?:true|false|null)\b'),
    // 소문자로 시작하고 바로 뒤에 `(`가 오는 이름 = 함수·메서드 (키워드 `if (`, `for (`, `catch (` 는 제외).
    Mode(
      scope: 'title.function_',
      begin: '\\b(?!(?:$keywordAlt)\\b)[a-z_][A-Za-z0-9_]*(?=\\s*\\()',
    ),
    // 대문자로 시작하는 이름 = 타입·클래스·위젯. Dart·Flutter 내장 이름은 built_in 색으로 남긴다.
    Mode(
      scope: 'type',
      begin: '\\b(?!(?:$builtInAlt)\\b)[A-Z][A-Za-z0-9_]*\\b',
    ),
    // `이름:` 형태 = 이름 붙인 인자 (삼항 연산자의 `? a : b` 와 `::` 는 제외).
    Mode(
      scope: 'attr',
      begin: r'(?<=[(,{]\s{0,80})[a-z_][A-Za-z0-9_]*(?=\s*:(?!:))',
    ),
  ];

  return Mode(
    refs: base.refs,
    name: 'Dart',
    keywords: keywords,
    contains: <Mode>[...(base.contains as List<Mode>), ...extras],
  );
}

final langDartRich = _build();
