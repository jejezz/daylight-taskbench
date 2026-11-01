import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'editor_theme.dart';
import 'editor_zoom.dart';

// daylight-workbench 의 ui/markdown_view.dart 를 옮겼다. [Taskbench에서 달라진 곳] 코드 글꼴은 앱의 고정폭 글꼴, 색·모양은 ColorScheme 에서.

/// Markdown을 렌더링해서 보여 준다. 색과 글꼴은 모두 현재 테마를 따르고,
/// 글자 크기는 편집기와 같은 배율을 쓰며, 상대 경로 이미지는 문서가 있는 폴더 기준으로 읽는다.
class MarkdownView extends StatefulWidget {
  const MarkdownView({super.key, required this.text, required this.baseDir});

  final String text;

  /// 문서가 있는 폴더 (상대 경로 이미지의 기준).
  final String baseDir;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final zoom = EditorZoomScope.scaleOf(context);
    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      // 글자 배율은 본문과 코드에 한 번만 곱한다 — 코드 글꼴은 배율을 곱하지 않은 값(13)을 쓴다.
      code: editorTextStyle(context).copyWith(
        fontSize: 13,
        backgroundColor: scheme.surfaceContainerHighest,
        color: scheme.onSurface,
      ),
      codeblockPadding: const EdgeInsets.all(AppSpacing.md),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      blockquoteDecoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: scheme.primary, width: 3)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      tableBorder: TableBorder.all(color: scheme.outlineVariant),
    );
    return ZoomWheel(
      scrollers: [_scroll],
      // 글자 배율은 본문과 코드에 한 번만 곱한다 (코드 글꼴은 배율을 곱하지 않은 값을 쓴다).
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(zoom)),
        child: Markdown(
          controller: _scroll,
          data: widget.text,
          selectable: true,
          styleSheet: sheet,
          padding: const EdgeInsets.all(AppSpacing.lg),
          extensionSet: md.ExtensionSet.gitHubFlavored,
          onTapLink: (_, href, _) => _open(href),
          imageBuilder: (uri, title, alt) => _image(uri, alt),
        ),
      ),
    );
  }

  Widget _image(Uri uri, String? alt) {
    final l10n = AppLocalizations.of(context);
    final fallback = Text(
      alt == null || alt.isEmpty
          ? l10n.markdownImageUnavailable
          : l10n.markdownImage(alt),
    );
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return Image.network(uri.toString(), errorBuilder: (_, _, _) => fallback);
    }
    final file = File(
      uri.scheme == 'file'
          ? uri.toFilePath()
          : '${widget.baseDir}${Platform.pathSeparator}${Uri.decodeComponent(uri.path)}',
    );
    return Image.file(file, errorBuilder: (_, _, _) => fallback);
  }

  /// 웹 주소만 연다. 그 밖의 링크(상대 경로, 파일, 앱 실행 주소)는 열지 않는다.
  static Future<void> _open(String? href) async {
    final uri = href == null ? null : Uri.tryParse(href);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
