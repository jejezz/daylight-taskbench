// 빠른 열기: 파일 이름 일부를 치면 맞는 파일이 점수 순으로 나온다 (daylight-workbench 에서 옮겼다).
// 고른 파일의 절대 경로를 돌려준다. 취소하면 null.
// [Taskbench에서 달라진 곳] 단축키는 ⌘/Ctrl+Shift+O — ⌘P 는 Git 칸의 Push 가 쓴다. 아이콘은 `Icons.x`.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'file_icons.dart';
import 'file_kind.dart';
import 'project_files.dart';

Future<String?> showQuickOpen(
  BuildContext context, {
  required String root,
  required Future<List<String>> files,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _QuickOpen(root: root, files: files),
  );
}

class _QuickOpen extends StatefulWidget {
  const _QuickOpen({required this.root, required this.files});

  final String root;
  final Future<List<String>> files;

  @override
  State<_QuickOpen> createState() => _QuickOpenState();
}

class _QuickOpenState extends State<_QuickOpen> {
  final _query = TextEditingController();
  List<String>? _all;
  List<String> _shown = const [];
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    widget.files.then((f) {
      if (!mounted) return;
      setState(() {
        _all = f;
        _refilter();
      });
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _refilter() {
    _shown = rankFiles(_query.text.trim(), _all ?? const []);
    _selected = 0;
  }

  void _move(int delta) {
    if (_shown.isEmpty) return;
    setState(() => _selected = (_selected + delta).clamp(0, _shown.length - 1));
  }

  void _open(String rel) {
    final sep = Platform.pathSeparator;
    Navigator.of(context).pop('${widget.root}$sep${rel.replaceAll('/', sep)}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 80,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 460),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _query,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.quickOpenHint,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  ),
                  onChanged: (_) => setState(_refilter),
                  onSubmitted: (_) {
                    if (_shown.isNotEmpty) _open(_shown[_selected]);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: _all == null
                      ? _note(theme, l10n.quickOpenLoading)
                      : _shown.isEmpty
                      ? _note(theme, l10n.quickOpenNoMatch)
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _shown.length,
                          itemBuilder: (context, i) {
                            final rel = _shown[i];
                            final slash = rel.lastIndexOf('/');
                            final icon = context.fileIcon(fileKindOf(rel));
                            return ListTile(
                              dense: true,
                              selected: i == _selected,
                              selectedTileColor:
                                  theme.colorScheme.secondaryContainer,
                              leading: Icon(
                                icon.icon,
                                size: 18,
                                color: icon.color,
                              ),
                              title: Text(
                                slash < 0 ? rel : rel.substring(slash + 1),
                              ),
                              subtitle: slash < 0
                                  ? null
                                  : Text(
                                      rel.substring(0, slash),
                                      style: AppFonts.mono.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                              onTap: () => _open(rel),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Text(text, style: theme.textTheme.bodySmall),
  );
}
