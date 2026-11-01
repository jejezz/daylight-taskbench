// 폴더를 펼칠 때 내용을 읽는 파일 트리 (daylight-workbench 에서 옮겼고 다시 짰다).
// [Taskbench에서 달라진 곳]
//  · 아이콘은 `Icons.x`로, 처음 펼칠 위치([expandTo])를 받는다 — 저장소의 하위 폴더를 열었다면 탐색기가 그 위치까지
//    펼쳐 보여 준다 (PLAN.md §1.13).
//  · **선택**이 있다: 한 번 누르면 선택(강조)되고, 파일은 **두 번 누르면** 열린다. 방향키로 선택을 옮긴다
//    (↑↓ 이동 · → 펼치기/첫 자식 · ← 접기/부모 · Enter 파일 열기·폴더 접고 펼치기 · Home/End).
//  · 줄 목록을 한 곳에서 쥐고 그린다(보이는 줄 목록) — 방향키 이동이 보이는 줄 순서를 알아야 해서다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'file_icons.dart';
import 'file_kind.dart';

/// 한 줄의 높이. 고정이라서 선택을 옮길 때 화면 안으로 스크롤하는 계산이 단순하다.
const double fileTreeRowHeight = 26;

/// 이 시간 안에 같은 파일을 다시 누르면 더블클릭이다. 첫 클릭을 기다렸다가 처리하지 않으므로 선택은 바로 보인다.
const Duration fileTreeDoubleTap = Duration(milliseconds: 350);

class FileTree extends StatefulWidget {
  const FileTree({
    super.key,
    required this.root,
    required this.onOpenFile,
    this.activePath,
    this.revision = 0,
    this.expandTo,
  });

  final String root;

  /// 지금 열려 있는 파일(에디터가 붙으면 쓴다). 선택과는 별개로 글자색만 달리 보인다.
  final String? activePath;

  /// 올라가면 펼쳐진 폴더의 내용을 다시 읽는다.
  final int revision;

  /// 이 경로까지 폴더를 펼친다 (저장소 루트와 같거나 그 하위 폴더).
  final String? expandTo;

  /// 파일을 두 번 누르거나 Enter 로 열 때 부른다.
  final void Function(String path) onOpenFile;

  @override
  State<FileTree> createState() => _FileTreeState();
}

const _hidden = {'.git'};

String _baseName(String p) =>
    p.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).last;

enum _Kind { dir, file, error }

class _Row {
  const _Row(this.kind, this.path, this.depth, [this.text]);

  final _Kind kind;
  final String path;
  final int depth;
  final String? text;

  bool get selectable => kind != _Kind.error;
  bool get isDir => kind == _Kind.dir;
}

class _FileTreeState extends State<FileTree> {
  final _focus = FocusNode(debugLabel: 'fileTree');
  final _scroll = ScrollController();
  final _expanded = <String>{};
  final _children = <String, List<FileSystemEntity>>{};
  final _errors = <String, String>{};
  String? _selected;
  String? _lastTapPath;
  DateTime? _lastTapAt;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
    _reset();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  void _reset() {
    _expanded
      ..clear()
      ..add(widget.root);
    _children.clear();
    _errors.clear();
    _selected = null;
    _expandPathTo(widget.expandTo);
    for (final d in _expanded.toList()) {
      _load(d);
    }
  }

  @override
  void didUpdateWidget(FileTree old) {
    super.didUpdateWidget(old);
    if (old.root != widget.root) {
      _reset();
    } else {
      if (old.expandTo != widget.expandTo) {
        final before = {..._expanded};
        _expandPathTo(widget.expandTo);
        for (final d in _expanded.difference(before)) {
          _load(d);
        }
      }
      if (old.revision != widget.revision) {
        for (final d in _expanded.toList()) {
          _load(d);
        }
      }
    }
  }

  /// [target]까지 가는 길 위의 폴더를 펼침 목록에 넣는다.
  void _expandPathTo(String? target) {
    if (target == null) return;
    final sep = Platform.pathSeparator;
    String n(String s) => s.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final root = n(widget.root);
    final t = n(target);
    if (t != root && !t.startsWith('$root/')) return;
    var current = widget.root;
    for (final seg in t.substring(root.length).split('/').where((s) => s.isNotEmpty)) {
      current = '$current$sep$seg';
      _expanded.add(current);
    }
  }

  Future<void> _load(String dir) async {
    try {
      final list = await Directory(dir).list(followLinks: false).toList();
      list.removeWhere((e) => _hidden.contains(_baseName(e.path)));
      list.sort((a, b) {
        final ad = a is Directory, bd = b is Directory;
        if (ad != bd) return ad ? -1 : 1;
        return _baseName(a.path).toLowerCase().compareTo(_baseName(b.path).toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _children[dir] = list;
        _errors.remove(dir);
      });
    } on FileSystemException catch (e) {
      if (mounted) setState(() => _errors[dir] = e.message);
    }
  }

  /// 지금 보이는 줄들 (펼친 폴더의 자식만).
  List<_Row> _rows() {
    final rows = <_Row>[_Row(_Kind.dir, widget.root, 0)];
    void walk(String dir, int depth) {
      final error = _errors[dir];
      if (error != null) rows.add(_Row(_Kind.error, dir, depth, error));
      for (final e in _children[dir] ?? const <FileSystemEntity>[]) {
        final isDir = e is Directory;
        rows.add(_Row(isDir ? _Kind.dir : _Kind.file, e.path, depth));
        if (isDir && _expanded.contains(e.path)) walk(e.path, depth + 1);
      }
    }

    if (_expanded.contains(widget.root)) walk(widget.root, 1);
    return rows;
  }

  void _toggle(String dir) {
    setState(() {
      if (!_expanded.remove(dir)) {
        _expanded.add(dir);
        _load(dir);
      }
    });
  }

  void _select(String path, {bool scroll = false}) {
    setState(() => _selected = path);
    if (scroll) _scrollToSelected();
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final i = _rows().indexWhere((r) => r.path == _selected);
      if (i < 0) return;
      final top = i * fileTreeRowHeight;
      final bottom = top + fileTreeRowHeight;
      final view = _scroll.position.viewportDimension;
      final offset = _scroll.offset;
      if (top < offset) {
        _scroll.jumpTo(top);
      } else if (bottom > offset + view) {
        _scroll.jumpTo(bottom - view);
      }
    });
  }

  void _tap(_Row row) {
    _focus.requestFocus();
    final now = DateTime.now();
    final again =
        _lastTapPath == row.path && _lastTapAt != null && now.difference(_lastTapAt!) < fileTreeDoubleTap;
    _lastTapPath = row.path;
    _lastTapAt = now;
    _select(row.path);
    if (row.isDir) {
      // 폴더는 한 번 누르면 접고 펼친다. 더블클릭의 두 번째 클릭에서는 다시 접지 않는다.
      if (!again) _toggle(row.path);
    } else if (again) {
      _lastTapPath = null;
      widget.onOpenFile(row.path);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    // ⌘/Ctrl/Alt 가 눌린 조합은 셸의 단축키에 맡긴다.
    if (keyboard.isMetaPressed || keyboard.isControlPressed || keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final rows = _rows().where((r) => r.selectable).toList();
    if (rows.isEmpty) return KeyEventResult.ignored;
    final i = rows.indexWhere((r) => r.path == _selected);
    final key = event.logicalKey;

    void move(int to) => _select(rows[to.clamp(0, rows.length - 1)].path, scroll: true);

    if (key == LogicalKeyboardKey.arrowDown) {
      move(i < 0 ? 0 : i + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      move(i < 0 ? 0 : i - 1);
    } else if (key == LogicalKeyboardKey.home) {
      move(0);
    } else if (key == LogicalKeyboardKey.end) {
      move(rows.length - 1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (i < 0) return KeyEventResult.ignored;
      final r = rows[i];
      if (!r.isDir) return KeyEventResult.handled;
      if (!_expanded.contains(r.path)) {
        _toggle(r.path);
      } else if (i + 1 < rows.length && rows[i + 1].depth > r.depth) {
        move(i + 1); // 첫 자식으로
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (i < 0) return KeyEventResult.ignored;
      final r = rows[i];
      if (r.isDir && _expanded.contains(r.path) && r.path != widget.root) {
        _toggle(r.path);
      } else {
        // 부모 폴더로
        for (var j = i - 1; j >= 0; j--) {
          if (rows[j].depth < r.depth) {
            move(j);
            break;
          }
        }
      }
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (i < 0) return KeyEventResult.ignored;
      final r = rows[i];
      if (r.isDir) {
        _toggle(r.path);
      } else {
        widget.onOpenFile(r.path);
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    return Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemExtent: fileTreeRowHeight,
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          return _RowTile(
            key: ValueKey('tree-row:${r.path}'),
            row: r,
            expanded: _expanded.contains(r.path),
            selected: r.path == _selected,
            focused: _focus.hasFocus,
            active: r.path == widget.activePath,
            onTap: r.selectable ? () => _tap(r) : null,
          );
        },
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    super.key,
    required this.row,
    required this.expanded,
    required this.selected,
    required this.focused,
    required this.active,
    required this.onTap,
  });

  final _Row row;
  final bool expanded;
  final bool selected;

  /// 트리에 키보드 포커스가 있는가 — 선택 강조가 더 진하다.
  final bool focused;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final indent = 8.0 + row.depth * 14;

    if (row.kind == _Kind.error) {
      return Padding(
        padding: EdgeInsets.fromLTRB(indent + 20, 2, 8, 2),
        child: Text(
          row.text ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
        ),
      );
    }

    final background = selected
        ? (focused ? scheme.primaryContainer : scheme.primaryContainer.withValues(alpha: 0.5))
        : null;
    final textStyle = active ? TextStyle(color: scheme.primary, fontWeight: FontWeight.w700) : null;

    final Widget leading;
    if (row.isDir) {
      leading = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(expanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 16),
          const SizedBox(width: 2),
          Icon(
            expanded ? Icons.folder_open_rounded : Icons.folder_rounded,
            size: 16,
            color: scheme.primary,
          ),
        ],
      );
    } else {
      final icon = context.fileIcon(fileKindOf(row.path));
      leading = Padding(
        padding: const EdgeInsets.only(left: 18),
        child: Icon(icon.icon, size: 15, color: icon.color),
      );
    }

    final tile = InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent, 0, 8, 0),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _baseName(row.path),
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      selected: selected,
      child: background == null
          ? Material(type: MaterialType.transparency, child: tile)
          : Material(color: background, child: tile),
    );
  }
}
