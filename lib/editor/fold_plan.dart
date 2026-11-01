import 'package:re_editor/re_editor.dart';

/// 접을 구간을 고른다: 안쪽(깊이 1) 구간 + 안에 다른 구간이 없는 바깥 구간.
/// 클래스가 하나뿐인 Dart 파일에서 메서드 몸통이 접히고 클래스는 열려 있는 모양이 된다.
/// 중첩이 전혀 없으면 바깥 구간을 모두 접는다.
List<CodeChunk> chunksToFold(List<CodeChunk> chunks) {
  final depth1 = <CodeChunk>[];
  final leafOuter = <CodeChunk>[];
  final outer = <CodeChunk>[];
  var lastEnd = -1;
  CodeChunk? parent;
  for (final c in chunks) {
    if (c.index >= lastEnd) {
      outer.add(c);
      parent = c;
      lastEnd = c.end;
      continue;
    }
    // parent 안에 들어 있는 구간. 부모 바로 아래만 깊이 1로 센다.
    var nested = false;
    for (final o in chunks) {
      if (o != c &&
          o.index > parent!.index &&
          o.index < c.index &&
          c.end <= o.end &&
          o.end <= parent.end) {
        nested = true;
      }
    }
    if (!nested) depth1.add(c);
  }
  for (final o in outer) {
    final hasChild = chunks.any(
      (c) => c != o && c.index > o.index && c.end <= o.end,
    );
    if (!hasChild && o.canCollapse) leafOuter.add(o);
  }
  final picked = [...depth1, ...leafOuter];
  return (picked.isEmpty ? outer : picked)..sort((a, b) => a.index - b.index);
}

void foldAll(CodeChunkController? chunks) {
  if (chunks == null) return;
  // 뒤에서부터 접어야 앞쪽 구간의 줄 번호가 밀리지 않는다.
  for (final c in chunksToFold(chunks.value).reversed) {
    chunks.collapse(c.index);
  }
}

void unfoldAll(CodeLineEditingController editing, CodeChunkController? chunks) {
  if (chunks == null) return;
  // 펴면 안쪽에 접혀 있던 줄이 드러나므로, 접힌 줄이 없을 때까지 마지막 것부터 반복한다.
  for (var guard = 0; guard < 2000; guard++) {
    var found = -1;
    for (var i = editing.codeLines.length - 1; i >= 0; i--) {
      if (editing.codeLines[i].chunkParent) {
        found = i;
        break;
      }
    }
    if (found < 0) return;
    chunks.expand(found);
  }
}
