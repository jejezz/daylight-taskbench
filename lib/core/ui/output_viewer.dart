import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../command_log.dart';
import '../output_links.dart';
import '../../workspace/workspace.dart';
import '../../workspace/workspace_scope.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'copy_output_button.dart';

/// 명령 출력을 전체 화면으로 보는 뷰어. 출력 전체를 한 덩어리로 보여 줘서 스크롤해도 선택
/// 영역이 바뀌지 않고, 실행 중이면 실시간으로 따라간다. 일시정지하면 내용이 고정돼 선택·복사가 쉽다.
class OutputViewerScreen extends StatefulWidget {
  const OutputViewerScreen({super.key, required this.log, required this.entry});

  final CommandLog log;
  final CommandLogEntry entry;

  static Future<void> open(
    BuildContext context,
    CommandLog log,
    CommandLogEntry entry,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => OutputViewerScreen(log: log, entry: entry),
    ),
  );

  @override
  State<OutputViewerScreen> createState() => _OutputViewerScreenState();
}

class _OutputViewerScreenState extends State<OutputViewerScreen> {
  final _scroll = ScrollController();
  bool _paused = false;
  String _frozen = '';

  // 오류 위치 링크: 같은 글이면 다시 찾지 않고, 파일이 있는지는 한 번만 본다.
  final _recognizers = <TapGestureRecognizer>[];
  final _resolved = <String, String?>{};
  String? _spansFor;
  List<InlineSpan> _spans = const [];

  String get _live => widget.entry.output.trimRight();
  String get _text => _paused ? _frozen : _live;

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  /// [text] 를 글자와 (파일이 실제로 있는) 오류 위치 링크로 나눈다.
  List<InlineSpan> _buildSpans(
    String text,
    Workspace? ws,
    TextStyle linkStyle,
  ) {
    if (text == _spansFor) return _spans;
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    _spansFor = text;
    if (ws == null || !ws.canOpenFiles) return _spans = [TextSpan(text: text)];
    final bases = [
      if (ws.selectedDir != null) ws.selectedDir!,
      if (ws.root != null && ws.root != ws.selectedDir) ws.root!,
    ];
    final spans = <InlineSpan>[];
    var at = 0;
    for (final link in findOutputLinks(text)) {
      final key = '${link.package}|${link.path}';
      final file = _resolved.putIfAbsent(
        key,
        () => resolveOutputLink(link, bases),
      );
      if (file == null) continue;
      if (link.start > at) {
        spans.add(TextSpan(text: text.substring(at, link.start)));
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => ws.requestOpenLocation(file, link.line, link.column);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: text.substring(link.start, link.end),
          style: linkStyle,
          recognizer: recognizer,
        ),
      );
      at = link.end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return _spans = spans;
  }

  void _togglePause() => setState(() {
    _paused = !_paused;
    if (_paused) _frozen = _live;
  });

  void _followTail() {
    if (_paused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      // 사용자가 위로 올려 읽는 중이면 끌어내리지 않는다.
      if (pos.maxScrollExtent - pos.pixels < 120) {
        _scroll.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry.commandLine,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.mono.copyWith(fontSize: 12),
        ),
        actions: [
          IconButton(
            tooltip: _paused ? l10n.fdViewerResume : l10n.fdViewerPause,
            icon: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            onPressed: _togglePause,
          ),
          CopyOutputButton(
            text: () => '\$ ${widget.entry.commandLine}\n$_text',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.log,
        builder: (context, _) {
          final text = _text;
          _followTail();
          final lines = text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;
          return Column(
            children: [
              Expanded(
                child: Scrollbar(
                  controller: _scroll,
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SizedBox(
                      width: double.infinity,
                      child: SelectableText.rich(
                        TextSpan(
                          children: _buildSpans(
                            text,
                            WorkspaceScope.maybeOf(context),
                            TextStyle(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        style: AppFonts.mono.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.fdViewerLines(lines),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      widget.entry.running
                          ? l10n.fdLogRunning
                          : l10n.fdLogExit('${widget.entry.exitCode ?? -1}'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
