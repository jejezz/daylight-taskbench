// daylight-workbench 의 studio/file_language.dart 를 옮겼다.
// [Taskbench에서 달라진 곳] 번역 도우미(CurrentL10n)가 없어서 일반 텍스트의 이름 번역은 화면이 맡는다.

import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/cmake.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/diff.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/gradle.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/powershell.dart';
import 'package:re_highlight/languages/properties.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';

import 'dart_highlight.dart';

/// 파일 하나의 언어: 구문 강조 규칙과 접기·정렬 방식을 정한다.
class FileLanguage {
  const FileLanguage(this.id, this._label, this.mode);

  final String id;
  final String _label;

  /// 화면에 보일 이름. 일반 텍스트(`plain`)는 번역이 필요하므로 화면에서 `languagePlain`을 쓴다.
  String get label => _label;

  /// 구문 강조 규칙. 모르는 파일이면 null (색 없이 보여 준다).
  final Mode? mode;

  bool get isDart => id == 'dart';
  bool get isMarkdown => id == 'markdown';
  bool get isJson => id == 'json';

  static final _byExtension = <String, FileLanguage>{
    'dart': FileLanguage('dart', 'Dart', langDartRich),
    'md': FileLanguage('markdown', 'Markdown', langMarkdown),
    'markdown': FileLanguage('markdown', 'Markdown', langMarkdown),
    'yaml': FileLanguage('yaml', 'YAML', langYaml),
    'yml': FileLanguage('yaml', 'YAML', langYaml),
    'json': FileLanguage('json', 'JSON', langJson),
    'arb': FileLanguage('json', 'JSON', langJson),
    'xml': FileLanguage('xml', 'XML', langXml),
    'plist': FileLanguage('xml', 'XML', langXml),
    'html': FileLanguage('xml', 'HTML', langXml),
    'kt': FileLanguage('kotlin', 'Kotlin', langKotlin),
    'kts': FileLanguage('kotlin', 'Kotlin', langKotlin),
    'swift': FileLanguage('swift', 'Swift', langSwift),
    'gradle': FileLanguage('gradle', 'Gradle', langGradle),
    'cmake': FileLanguage('cmake', 'CMake', langCmake),
    'sh': FileLanguage('bash', 'Shell', langBash),
    'bash': FileLanguage('bash', 'Shell', langBash),
    'ps1': FileLanguage('powershell', 'PowerShell', langPowershell),
    'properties': FileLanguage('properties', 'Properties', langProperties),
    'ini': FileLanguage('ini', 'INI', langIni),
    'c': FileLanguage('cpp', 'C/C++', langCpp),
    'h': FileLanguage('cpp', 'C/C++', langCpp),
    'cc': FileLanguage('cpp', 'C/C++', langCpp),
    'cpp': FileLanguage('cpp', 'C/C++', langCpp),
    'js': FileLanguage('javascript', 'JavaScript', langJavascript),
    'py': FileLanguage('python', 'Python', langPython),
    'css': FileLanguage('css', 'CSS', langCss),
    'sql': FileLanguage('sql', 'SQL', langSql),
    'diff': FileLanguage('diff', 'Diff', langDiff),
    'patch': FileLanguage('diff', 'Diff', langDiff),
  };

  static const plain = FileLanguage('plain', 'Text', null);

  /// 파일 경로로 언어를 정한다. `CMakeLists.txt`, `Dockerfile`은 이름으로, 나머지는 확장자로.
  static FileLanguage of(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    if (name == 'CMakeLists.txt') return _byExtension['cmake']!;
    if (name == 'Dockerfile') {
      return FileLanguage('dockerfile', 'Dockerfile', langDockerfile);
    }
    final dot = name.lastIndexOf('.');
    if (dot < 0) return plain;
    return _byExtension[name.substring(dot + 1).toLowerCase()] ?? plain;
  }
}
