import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:re_editor/re_editor.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

// daylight-workbench 의 ui/find_panel.dart 를 옮겼다. [Taskbench에서 달라진 곳] 아이콘은 `Icons.x`, 간격은 AppSpacing.

/// 편집기 위에 뜨는 찾기·바꾸기 줄 (Ctrl/Cmd+F, 바꾸기는 왼쪽 화살표 단추).
///
/// 찾는 일은 re_editor의 [CodeFindController]가 한다 — 이 위젯은 모양과 단추만 맡는다.
class FindPanel extends StatelessWidget implements PreferredSizeWidget {
  const FindPanel({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  final CodeFindController controller;
  final bool readOnly;

  static const _rowHeight = 40.0;

  /// 찾기 줄 맨 앞의 바꾸기 토글 폭. 바꾸기 줄의 빈 자리도 같은 폭이어야 두 입력칸의 글이 같은 자리에서 시작한다.
  static const _leadWidth = 40.0;

  bool get _replacing => !readOnly && (controller.value?.replaceMode ?? false);

  @override
  Size get preferredSize =>
      Size.fromHeight(_replacing ? _rowHeight * 2 : _rowHeight);

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (value == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final result = value.result;
    final total = result?.matches.length ?? 0;
    final hasPattern = value.option.pattern.isNotEmpty;
    final status = !hasPattern
        ? ''
        : total == 0
        ? l10n.findNoResults
        : l10n.findCount((result?.index ?? 0) + 1, total);

    Widget toggle({
      required IconData icon,
      required String tooltip,
      required bool on,
      required VoidCallback onTap,
    }) {
      return IconButton(
        tooltip: tooltip,
        isSelected: on,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon),
        onPressed: onTap,
      );
    }

    Widget field(
      TextEditingController c,
      FocusNode node,
      String hint, {
      VoidCallback? onSubmit,
      ValueChanged<String>? onChanged,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape):
                  controller.close,
              if (onSubmit != null)
                const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                    controller.previousMatch,
            },
            child: TextField(
              controller: c,
              focusNode: node,
              decoration: InputDecoration(hintText: hint, isDense: true),
              onChanged: onChanged,
              onSubmitted: onSubmit == null ? null : (_) => onSubmit(),
            ),
          ),
        ),
      );
    }

    return Material(
      color: scheme.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                if (!readOnly)
                  SizedBox(
                    width: _leadWidth,
                    child: toggle(
                      icon: value.replaceMode
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      tooltip: l10n.findToggleReplace,
                      on: false,
                      onTap: controller.toggleMode,
                    ),
                  ),
                field(
                  controller.findInputController,
                  controller.findInputFocusNode,
                  l10n.findHint,
                  onSubmit: controller.nextMatch,
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                toggle(
                  icon: Icons.text_fields_rounded,
                  tooltip: l10n.findMatchCase,
                  on: value.option.caseSensitive,
                  onTap: controller.toggleCaseSensitive,
                ),
                toggle(
                  icon: Icons.code_rounded,
                  tooltip: l10n.findRegex,
                  on: value.option.regex,
                  onTap: controller.toggleRegex,
                ),
                toggle(
                  icon: Icons.arrow_upward_rounded,
                  tooltip: l10n.findPrevious,
                  on: false,
                  onTap: controller.previousMatch,
                ),
                toggle(
                  icon: Icons.arrow_downward_rounded,
                  tooltip: l10n.findNext,
                  on: false,
                  onTap: controller.nextMatch,
                ),
                toggle(
                  icon: Icons.close_rounded,
                  tooltip: l10n.findClose,
                  on: false,
                  onTap: controller.close,
                ),
              ],
            ),
          ),
          if (_replacing)
            SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  const SizedBox(width: _leadWidth),
                  field(
                    controller.replaceInputController,
                    controller.replaceInputFocusNode,
                    l10n.findReplaceHint,
                    onSubmit: controller.replaceMatch,
                  ),
                  TextButton(
                    onPressed: controller.replaceMatch,
                    child: Text(l10n.findReplaceOne),
                  ),
                  TextButton(
                    onPressed: controller.replaceAllMatches,
                    child: Text(l10n.findReplaceAll),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
