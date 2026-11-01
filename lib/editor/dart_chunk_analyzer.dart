/// Dart 코드의 접기 구간. `()`, `[]`, `{}`가 여러 줄에 걸친 곳을 찾는다.
///
/// 기본 분석기와 달리 주석(`//`, `/* */`), 여러 줄 문자열(`'''`, `"""`), 원시 문자열(`r'…'`)을
/// 줄을 넘어 추적하고, 같은 줄에서 시작하는 구간이 겹치면 **가장 바깥 것**을 쓴다.
/// Flutter 위젯 트리는 `Column(children: [` 처럼 한 줄에 `(`와 `[`가 함께 열리는데,
/// 바깥 `(`를 접어야 `children: [ … ]` 전체가 한 번에 접힌다.
library;

import 'package:re_editor/re_editor.dart';

class DartChunkAnalyzer implements CodeChunkAnalyzer {
  const DartChunkAnalyzer();

  static const _closers = {'(': ')', '[': ']', '{': '}'};

  @override
  List<CodeChunk> run(CodeLines codeLines) => findChunks([
    for (var i = 0; i < codeLines.length; i++) codeLines[i].text,
  ]);

  /// 줄 목록에서 접을 수 있는 구간을 찾는다 (테스트하기 쉽게 글자 목록을 받는다).
  static List<CodeChunk> findChunks(List<String> lines) {
    final byStart = <int, CodeChunk>{};
    final stack = <({String ch, int line})>[];
    var inBlockComment = false;
    // 여러 줄 문자열이 열려 있으면 그 따옴표(`'''` 또는 `"""`), 아니면 null.
    String? inTriple;

    for (var i = 0; i < lines.length; i++) {
      final text = lines[i];
      var j = 0;
      while (j < text.length) {
        final ch = text[j];
        if (inBlockComment) {
          if (text.startsWith('*/', j)) {
            inBlockComment = false;
            j += 2;
          } else {
            j++;
          }
          continue;
        }
        if (inTriple != null) {
          if (ch == r'\') {
            j += 2;
          } else if (text.startsWith(inTriple, j)) {
            inTriple = null;
            j += 3;
          } else {
            j++;
          }
          continue;
        }
        if (text.startsWith('//', j)) break;
        if (text.startsWith('/*', j)) {
          inBlockComment = true;
          j += 2;
          continue;
        }
        if (ch == "'" || ch == '"') {
          final raw =
              j > 0 &&
              text[j - 1] == 'r' &&
              (j < 2 || !_isIdentChar(text[j - 2]));
          if (text.startsWith(ch * 3, j)) {
            inTriple = ch * 3;
            j += 3;
            continue;
          }
          j = _skipString(text, j, raw: raw);
          continue;
        }
        if (_closers.containsKey(ch)) {
          stack.add((ch: ch, line: i));
        } else if (ch == ')' || ch == ']' || ch == '}') {
          // 짝이 맞는 여는 괄호를 찾을 때까지 꺼낸다 (짝 없는 괄호는 무시).
          while (stack.isNotEmpty) {
            final open = stack.removeLast();
            if (_closers[open.ch] == ch) {
              if (i > open.line) {
                final prev = byStart[open.line];
                if (prev == null || prev.end < i) {
                  byStart[open.line] = CodeChunk(open.line, i);
                }
              }
              break;
            }
          }
        }
        j++;
      }
    }
    return byStart.values.toList()..sort((a, b) => a.index - b.index);
  }

  static bool _isIdentChar(String c) => RegExp(r'[A-Za-z0-9_$]').hasMatch(c);

  /// 한 줄 문자열이 끝난 다음 위치. 닫히지 않으면 줄 끝.
  static int _skipString(String text, int start, {required bool raw}) {
    final quote = text[start];
    var j = start + 1;
    while (j < text.length) {
      if (!raw && text[j] == r'\') {
        j += 2;
      } else if (text[j] == quote) {
        return j + 1;
      } else {
        j++;
      }
    }
    return text.length;
  }
}
