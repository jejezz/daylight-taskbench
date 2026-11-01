/// 들여쓰기 선을 그리기 위한 줄별 들여쓰기 깊이 계산 (그리는 것과 무관한 순수 함수).
library;

/// 줄 앞의 공백 칸 수 (탭은 [tabWidth]칸). 줄이 비었거나 공백뿐이면 null.
int? leadingColumns(String line, {int tabWidth = 2}) {
  var columns = 0;
  for (var i = 0; i < line.length; i++) {
    final ch = line.codeUnitAt(i);
    if (ch == 0x20) {
      columns++;
    } else if (ch == 0x09) {
      columns += tabWidth;
    } else {
      return columns;
    }
  }
  return null;
}

/// 한 단계가 몇 칸인지: 앞 [limit]줄에서 들여쓰기가 늘어나는 폭 중 가장 작은 값.
/// 알 수 없으면 [fallback] (Dart·Flutter 관례의 2칸).
int detectIndentUnit(Iterable<String> lines, {int limit = 400, int fallback = 2}) {
  var previous = 0;
  int? unit;
  var seen = 0;
  for (final line in lines) {
    if (seen++ >= limit) break;
    final cols = leadingColumns(line);
    if (cols == null) continue;
    final step = cols - previous;
    if (step > 0 && (unit == null || step < unit)) unit = step;
    previous = cols;
  }
  return unit == null || unit < 1 ? fallback : unit.clamp(1, 8);
}

/// [index]번 줄의 들여쓰기 깊이. 빈 줄은 위아래 가장 가까운 글자 있는 줄 중 더 얕은 쪽을 따른다
/// (함수 몸통 안의 빈 줄에서 선이 끊기지 않고, 블록 사이의 빈 줄에서는 이어지지 않는다).
int indentLevelAt(int count, String Function(int) line, int index, int unit, {int scan = 200}) {
  final own = leadingColumns(line(index));
  if (own != null) return own ~/ unit;
  int? up, down;
  for (var i = index - 1; i >= 0 && i >= index - scan; i--) {
    final c = leadingColumns(line(i));
    if (c != null) {
      up = c ~/ unit;
      break;
    }
  }
  for (var i = index + 1; i < count && i <= index + scan; i++) {
    final c = leadingColumns(line(i));
    if (c != null) {
      down = c ~/ unit;
      break;
    }
  }
  if (up == null || down == null) return 0;
  return up < down ? up : down;
}
