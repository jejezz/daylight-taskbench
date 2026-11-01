// 탭 줄 + 도구 줄 + 편집 영역 (daylight-workbench 의 ui/editor_pane.dart 를 줄여 옮겼다).
// [Taskbench에서 달라진 곳] 아이콘은 `Icons.x`, 색은 ColorScheme·TaskbenchStyle. 변경 표시(gutter)·문제 표시·들여쓰기 선·
// 정의로 이동·Markdown 미리보기·정렬·git 비교는 아직 없다 (단계 15의 뒤 차례).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

import '../explorer/file_icons.dart';
import '../explorer/file_kind.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/taskbench_style.dart';
import 'dart_chunk_analyzer.dart';
import 'editor_controller.dart';
import 'editor_tab.dart';
import 'editor_theme.dart';
import 'editor_zoom.dart';
import 'find_panel.dart';
import 'fold_plan.dart';

class EditorPane extends StatelessWidget {
  const EditorPane({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tab = controller.activeTab;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.tabs.isNotEmpty) ...[
          _TabBar(controller: controller),
          const Divider(height: 1),
        ],
        if (tab != null && tab.external != ExternalChange.none)
          _ExternalBanner(controller: controller, tab: tab),
        if (tab != null) ...[
          _Toolbar(controller: controller, tab: tab),
          const Divider(height: 1),
        ],
        Expanded(
          child: tab == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.editorOpenFromExplorer,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : CallbackShortcuts(
                  bindings: {
                    const SingleActivator(
                      LogicalKeyboardKey.keyS,
                      control: true,
                    ): () =>
                        controller.save(tab),
                    const SingleActivator(
                      LogicalKeyboardKey.keyS,
                      meta: true,
                    ): () =>
                        controller.save(tab),
                    ..._zoomBindings(EditorZoomScope.maybeOf(context)),
                  },
                  child: _CodeView(
                    key: ValueKey(tab.path),
                    tab: tab,
                    onSave: () => controller.save(tab),
                  ),
                ),
        ),
      ],
    );
  }
}

/// 글자 크기 단축키: Ctrl(macOS는 Cmd)+`+`/`=`, `-`, `0`. 숫자패드 `+`/`-`도 받는다.
Map<ShortcutActivator, VoidCallback> _zoomBindings(EditorZoom? zoom) {
  if (zoom == null) return const {};
  return {
    for (final ctrl in [true, false]) ...{
      SingleActivator(LogicalKeyboardKey.equal, control: ctrl, meta: !ctrl):
          zoom.zoomIn,
      SingleActivator(
        LogicalKeyboardKey.equal,
        control: ctrl,
        meta: !ctrl,
        shift: true,
      ): zoom.zoomIn,
      SingleActivator(LogicalKeyboardKey.numpadAdd, control: ctrl, meta: !ctrl):
          zoom.zoomIn,
      SingleActivator(LogicalKeyboardKey.minus, control: ctrl, meta: !ctrl):
          zoom.zoomOut,
      SingleActivator(
        LogicalKeyboardKey.numpadSubtract,
        control: ctrl,
        meta: !ctrl,
      ): zoom.zoomOut,
      SingleActivator(LogicalKeyboardKey.digit0, control: ctrl, meta: !ctrl):
          zoom.reset,
    },
  };
}

/// 열린 파일이 디스크에서 바뀌었을 때, 수정 중인 탭에서 어떻게 할지 고르게 한다.
class _ExternalBanner extends StatelessWidget {
  const _ExternalBanner({required this.controller, required this.tab});

  final EditorController controller;
  final EditorTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final warning = context.style.warning;
    final deleted = tab.external == ExternalChange.deleted;
    return Container(
      color: warning.withValues(alpha: 0.14),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              deleted ? l10n.editorFileGone : l10n.editorFileChanged,
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (deleted) ...[
            TextButton(
              onPressed: () =>
                  controller.closeTab(controller.tabs.indexOf(tab)),
              child: Text(l10n.editorCloseTab),
            ),
            TextButton(
              onPressed: () => controller.keepMine(tab),
              child: Text(l10n.editorLeaveAsIs),
            ),
          ] else ...[
            TextButton(
              onPressed: () => controller.reloadFromDisk(tab),
              child: Text(l10n.editorReloadDiscard),
            ),
            TextButton(
              onPressed: () => controller.keepMine(tab),
              child: Text(l10n.editorKeepMine),
            ),
          ],
        ],
      ),
    );
  }
}

/// 편집기 단축키. re_editor 기본값에서 바꾸기만 `Ctrl/⌘+R`로 바꾼다(기본은 `Ctrl/⌘+Alt+F`).
/// 터미널에서는 `Ctrl+R`이 셸의 기록 검색이라, 앱 전체 단축키가 아니라 편집기 안에서만 쓴다.
class EditorShortcuts extends CodeShortcutsActivatorsBuilder {
  const EditorShortcuts();

  static const _defaults = DefaultCodeShortcutsActivatorsBuilder();

  @override
  List<ShortcutActivator>? build(CodeShortcutType type) {
    if (type != CodeShortcutType.replace) return _defaults.build(type);
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    return [SingleActivator(LogicalKeyboardKey.keyR, control: !mac, meta: mac)];
  }
}

class _CodeView extends StatefulWidget {
  const _CodeView({super.key, required this.tab, required this.onSave});

  final EditorTab tab;

  /// Ctrl/Cmd+S. re_editor 는 저장 단축키를 받아 아무것도 하지 않고 삼키므로, 바깥 `CallbackShortcuts`까지 올라가지 않는다.
  final VoidCallback onSave;

  @override
  State<_CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<_CodeView> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  late final CodeScrollController _scroll = CodeScrollController(
    verticalScroller: _vertical,
    horizontalScroller: _horizontal,
  );

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    return ZoomWheel(
      scrollers: [_vertical, _horizontal],
      child: CodeEditor(
        controller: tab.controller,
        findController: tab.find,
        focusNode: tab.focusNode,
        shortcutsActivatorsBuilder: const EditorShortcuts(),
        shortcutOverrideActions: {
          CodeShortcutSaveIntent: CallbackAction<CodeShortcutSaveIntent>(
            onInvoke: (_) => widget.onSave(),
          ),
        },
        scrollController: _scroll,
        wordWrap: false,
        findBuilder: (context, find, readOnly) =>
            FindPanel(controller: find, readOnly: readOnly),
        padding: const EdgeInsets.all(AppSpacing.sm),
        chunkAnalyzer: tab.language.isDart
            ? const DartChunkAnalyzer()
            : const DefaultCodeChunkAnalyzer(),
        style: buildEditorStyle(
          context,
          languageId: tab.language.id,
          mode: tab.language.mode,
        ),
        indicatorBuilder: (context, editing, chunks, notifier) {
          tab.chunks = chunks;
          return Row(
            children: [
              DefaultCodeLineNumber(
                controller: editing,
                notifier: notifier,
                textStyle: editorLineNumberStyle(context, focused: false),
                focusedTextStyle: editorLineNumberStyle(context, focused: true),
              ),
              DefaultCodeChunkIndicator(
                width: 20,
                controller: chunks,
                notifier: notifier,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.controller, required this.tab});

  final EditorController controller;
  final EditorTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final zoom = EditorZoomScope.maybeOf(context);
    final label = tab.language.id == 'plain'
        ? l10n.languagePlain
        : tab.language.label;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const Spacer(),
          if (zoom != null)
            Tooltip(
              message: l10n.editorZoomHint,
              child: TextButton(
                onPressed: zoom.isDefault ? null : zoom.reset,
                child: Text('${zoom.percent}%'),
              ),
            ),
          IconButton(
            tooltip: l10n.editorFoldAll,
            icon: const Icon(Icons.unfold_less_rounded, size: 18),
            onPressed: () => foldAll(tab.chunks),
          ),
          IconButton(
            tooltip: l10n.editorUnfoldAll,
            icon: const Icon(Icons.unfold_more_rounded, size: 18),
            onPressed: () => unfoldAll(tab.controller, tab.chunks),
          ),
          IconButton(
            tooltip: l10n.editorSaveTooltip,
            icon: const Icon(Icons.save_outlined, size: 18),
            onPressed: tab.dirty ? () => controller.save(tab) : null,
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      // 탭을 끌어서 순서를 바꾼다. 탭 어디를 잡아도 끌리고, 기본 끌기 손잡이는 그리지 않는다.
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: controller.tabs.length,
        onReorderItem: controller.moveTab,
        proxyDecorator: (child, index, animation) =>
            Material(type: MaterialType.transparency, child: child),
        itemBuilder: (context, i) {
          final t = controller.tabs[i];
          final active = i == controller.activeIndex;
          final icon = context.fileIcon(fileKindOf(t.path));
          return ReorderableDragStartListener(
            key: ValueKey(t.path),
            index: i,
            child: Tooltip(
              message: t.path,
              child: InkWell(
                onTap: () => controller.selectTab(i),
                child: Container(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.colorScheme.surfaceContainerHighest
                        : null,
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: theme.colorScheme.primary.withValues(
                          alpha: active ? 1 : 0,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon.icon, size: 16, color: icon.color),
                      const SizedBox(width: 6),
                      Text(t.dirty ? '● ${t.name}' : t.name),
                      IconButton(
                        iconSize: 14,
                        visualDensity: VisualDensity.compact,
                        tooltip: l10n.commonClose,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            closeTabWithPrompt(context, controller, i),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 탭을 닫는다. 고친 내용이 있으면 저장할지 묻는다.
Future<void> closeTabWithPrompt(
  BuildContext context,
  EditorController controller,
  int i,
) async {
  final l10n = AppLocalizations.of(context);
  final t = controller.tabs[i];
  if (!t.dirty) return controller.closeTab(i);
  final choice = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.editorSavePromptTitle(t.name)),
      content: Text(l10n.editorSavePromptBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'discard'),
          child: Text(l10n.editorDontSave),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'save'),
          child: Text(l10n.commonSave),
        ),
      ],
    ),
  );
  // 물어보는 사이 탭이 바뀌었을 수 있다 — 같은 탭을 다시 찾는다.
  final index = controller.tabs.indexOf(t);
  if (index < 0) return;
  if (choice == 'save') {
    if (await controller.save(t)) {
      controller.closeTab(controller.tabs.indexOf(t));
    }
  } else if (choice == 'discard') {
    controller.closeTab(index);
  }
}
