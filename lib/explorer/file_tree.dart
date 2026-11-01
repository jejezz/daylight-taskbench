// 폴더를 펼칠 때 내용을 읽는 파일 트리 (daylight-workbench 에서 옮겼다).
// [Taskbench에서 달라진 곳] 아이콘은 `Icons.x`로, 처음 펼칠 위치([expandTo])를 받는다 — 저장소의 하위 폴더를
// 열었다면 탐색기가 그 위치까지 펼쳐 보여 준다 (PLAN.md §1.13).

import 'dart:io';

import 'package:flutter/material.dart';

import 'file_icons.dart';
import 'file_kind.dart';

class FileTree extends StatelessWidget {
  const FileTree({
    super.key,
    required this.root,
    required this.onOpenFile,
    this.activePath,
    this.revision = 0,
    this.expandTo,
  });

  final String root;
  final String? activePath;

  /// 올라가면 펼쳐진 폴더의 내용을 다시 읽는다.
  final int revision;

  /// 이 경로까지 폴더를 펼친다 (저장소 루트와 같거나 그 하위 폴더).
  final String? expandTo;
  final void Function(String path) onOpenFile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        _DirNode(
          key: ValueKey(root),
          path: root,
          depth: 0,
          initiallyExpanded: true,
          revision: revision,
          activePath: activePath,
          expandTo: expandTo,
          onOpenFile: onOpenFile,
        ),
      ],
    );
  }
}

const _hidden = {'.git'};

String _baseName(String p) =>
    p.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).last;

/// [dir]이 [target]과 같거나 그 윗 폴더인가 (target 까지 가는 길 위에 있는 폴더).
bool _onPathTo(String dir, String? target) {
  if (target == null) return false;
  final d = dir.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  final t = target.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  return t == d || t.startsWith('$d/');
}

class _DirNode extends StatefulWidget {
  const _DirNode({
    super.key,
    required this.path,
    required this.depth,
    required this.activePath,
    required this.onOpenFile,
    required this.revision,
    required this.expandTo,
    this.initiallyExpanded = false,
  });

  final String path;
  final int depth;
  final bool initiallyExpanded;
  final int revision;
  final String? activePath;
  final String? expandTo;
  final void Function(String path) onOpenFile;

  @override
  State<_DirNode> createState() => _DirNodeState();
}

class _DirNodeState extends State<_DirNode> {
  late bool _expanded = widget.initiallyExpanded;
  List<FileSystemEntity>? _children;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_expanded) _load();
  }

  @override
  void didUpdateWidget(_DirNode old) {
    super.didUpdateWidget(old);
    // 고른 폴더가 바뀌면 그 길 위의 폴더를 펼친다 (이미 펼친 폴더는 접지 않는다).
    if (old.expandTo != widget.expandTo &&
        !_expanded &&
        _onPathTo(widget.path, widget.expandTo)) {
      _expanded = true;
      _load();
    } else if (old.revision != widget.revision && _expanded) {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final list = await Directory(widget.path)
          .list(followLinks: false)
          .toList();
      list.removeWhere((e) => _hidden.contains(_baseName(e.path)));
      list.sort((a, b) {
        final ad = a is Directory, bd = b is Directory;
        if (ad != bd) return ad ? -1 : 1;
        return _baseName(a.path)
            .toLowerCase()
            .compareTo(_baseName(b.path).toLowerCase());
      });
      if (mounted) {
        setState(() {
          _children = list;
          _error = null;
        });
      }
    } on FileSystemException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = 8.0 + widget.depth * 14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: EdgeInsets.fromLTRB(indent, 3, 8, 3),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                  size: 16,
                ),
                const SizedBox(width: 2),
                Icon(
                  _expanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _baseName(widget.path),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded && _error != null)
          Padding(
            padding: EdgeInsets.fromLTRB(indent + 20, 2, 8, 2),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (_expanded && _children != null)
          for (final e in _children!)
            if (e is Directory)
              _DirNode(
                key: ValueKey(e.path),
                path: e.path,
                depth: widget.depth + 1,
                revision: widget.revision,
                activePath: widget.activePath,
                expandTo: widget.expandTo,
                initiallyExpanded: _onPathTo(e.path, widget.expandTo),
                onOpenFile: widget.onOpenFile,
              )
            else
              _FileRow(
                path: e.path,
                depth: widget.depth + 1,
                active: e.path == widget.activePath,
                onTap: () => widget.onOpenFile(e.path),
              ),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.path,
    required this.depth,
    required this.active,
    required this.onTap,
  });

  final String path;
  final int depth;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileIcon = context.fileIcon(fileKindOf(path));
    return InkWell(
      onTap: onTap,
      child: Container(
        color: active
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : null,
        padding: EdgeInsets.fromLTRB(8.0 + depth * 14 + 18, 3, 8, 3),
        child: Row(
          children: [
            Icon(fileIcon.icon, size: 15, color: fileIcon.color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(_baseName(path), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
