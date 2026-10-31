// 설정 창 (conventions/settings.md). 바꾼 값은 바로 적용되고 저장된다 — 확인·적용 버튼은 없다.
//
// 이 앱의 기본 창 폭은 380~440 이라 **도킹한 좁은 배치가 기본**이다: 설정 창은 앱 창보다 커질 수 없으므로
// 창 크기만 보고 배치를 고른다 — 너비 560 이상은 왼쪽 구역 목록(160), 미만은 위쪽 ChoiceChip 한 줄.
// 구역을 더하려면 [SettingsSection]에 한 줄을 더한다 (앞으로 편집기·Branch·Flutty 구역이 들어온다).

import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../core/tool_paths.dart';
import '../docks/branch/repo/repo_prefs.dart';
import '../docks/flutty/secrets/secrets_screen.dart';
import '../l10n/app_localizations.dart';
import '../workspace/workspace_scope.dart';
import 'app_settings.dart';
import 'settings_menus.dart';

enum SettingsSection {
  appearance(Icons.palette_outlined),
  language(Icons.language_rounded),
  branch(Icons.call_split_rounded),
  tools(Icons.build_outlined),
  secrets(Icons.key_rounded);

  const SettingsSection(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    appearance => l10n.settingsSectionAppearance,
    language => l10n.settingsSectionLanguage,
    branch => l10n.dockBranchTitle,
    tools => l10n.settingsSectionTools,
    secrets => l10n.fdSecretsTitle,
  };
}

Future<void> showSettingsDialog(
  BuildContext context, {
  SettingsSection initial = SettingsSection.appearance,
}) => showDialog<void>(
  context: context,
  builder: (_) => SettingsDialog(initial: initial),
);

/// 구역 목록을 왼쪽 열로 두는 최소 너비 (이 아래면 위쪽 칩).
const double settingsWideWidth = 560;

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, this.initial = SettingsSection.appearance});

  final SettingsSection initial;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late SettingsSection _section = widget.initial;

  /// 칸·도구 구역은 해당 객체가 앱 루트에서 내려와 있을 때만 (설정 창이 앱 안 어디서나 같은 코드로 뜬다).
  bool _available(SettingsSection s) => switch (s) {
    SettingsSection.branch => WorkspaceScope.maybeOf(context) != null,
    SettingsSection.tools => ToolPathsScope.maybeOf(context) != null,
    // macOS 릴리스 서명 시크릿 — Windows 릴리스는 시크릿이 필요 없다 (Flutty 원본과 같은 규칙).
    SettingsSection.secrets => SecretsPanel.available && WorkspaceScope.maybeOf(context) != null,
    _ => true,
  };

  List<SettingsSection> get _sections => [
    for (final s in SettingsSection.values)
      if (_available(s)) s,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screen = MediaQuery.sizeOf(context);
    // 바깥 여백 16(양쪽 32), 제목 줄 + 닫기 줄이 차지하는 높이 150 (settings.md "크기와 도킹한 창").
    final width = math.min(640.0, screen.width - 32);
    final height = (screen.height - 32 - 150).clamp(160.0, 380.0);
    final wide = width >= settingsWideWidth;
    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      title: Text(l10n.settingsTitle),
      contentPadding: EdgeInsets.fromLTRB(wide ? 0 : 16, 8, 16, 0),
      content: SizedBox(
        width: width,
        height: height,
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 160,
                    child: ListView(
                      children: [
                        for (final s in _sections)
                          _SectionTile(
                            selected: s == _section,
                            icon: s.icon,
                            label: s.label(l10n),
                            onTap: () => setState(() => _section = s),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(child: _Content(section: _section, leftPadding: 16)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _sections)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: s == _section,
                              showCheckmark: false,
                              avatar: Icon(s.icon, size: 16),
                              label: Text(s.label(l10n)),
                              onSelected: (_) => setState(() => _section = s),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Expanded(child: _Content(section: _section, leftPadding: 0)),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.section, required this.leftPadding});

  final SettingsSection section;
  final double leftPadding;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.only(left: leftPadding, bottom: 16),
    child: switch (section) {
      SettingsSection.appearance => const _AppearanceSection(),
      SettingsSection.language => const _LanguageSection(),
      SettingsSection.branch => const _BranchSection(),
      SettingsSection.tools => const _ToolsSection(),
      SettingsSection.secrets => const SecretsPanel(),
    },
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

/// 고른 구역은 배경을 채우는 대신 왼쪽에 굵은 선(3px)으로 표시한다 — 고대비에서도 글자가 읽힌다.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          // 선택 안 된 줄도 같은 폭을 비워 둬서, 고를 때 글자가 옆으로 밀리지 않는다.
          border: Border(
            left: BorderSide(
              width: 3,
              color: selected ? scheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: selected ? scheme.onSurface : color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(l10n.settingsMode),
        const ModeSegmentedButton(),
        _Heading(l10n.settingsPalette),
        const ColorPaletteChips(),
        _Heading(l10n.settingsFontSize),
        const FontScaleSegmentedButton(),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(l10n.settingsStateTint),
          subtitle: Text(l10n.settingsStateTintHelp),
          value: settings.stateTint,
          onChanged: settings.setStateTint,
        ),
      ],
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(l10n.settingsLanguage),
        const LanguageSegmentedButton(),
      ],
    );
  }
}

/// 도구 경로 (git·gh·… ) — 줄마다 찾은 경로를 보이고, 직접 지정하거나 지울 수 있다.
class _ToolsSection extends StatelessWidget {
  const _ToolsSection();

  @override
  Widget build(BuildContext context) {
    final tools = ToolPathsScope.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    if (tools == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.toolsIntro, style: Theme.of(context).textTheme.bodySmall),
        for (final t in tools.known) _ToolRow(tools: tools, spec: t),
      ],
    );
  }
}

class _ToolRow extends StatefulWidget {
  const _ToolRow({required this.tools, required this.spec});

  final ToolPaths tools;
  final ToolSpec spec;

  @override
  State<_ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<_ToolRow> {
  late final _controller = TextEditingController(
    text: widget.tools.customPath(widget.spec.name) ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _browse() async {
    final file = await openFile();
    if (file == null) return;
    _controller.text = file.path;
    await widget.tools.set(widget.spec.name, file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.tools,
      builder: (context, _) {
        final found = widget.tools.resolved(widget.spec.name);
        final custom = widget.tools.customPath(widget.spec.name) != null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Heading(widget.spec.label),
            Row(
              children: [
                Icon(
                  found != null
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 16,
                  color: found != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    found != null ? l10n.toolsFound(found) : l10n.toolsNotFound,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (custom)
                  Text(l10n.toolsCustom, style: theme.textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.toolsPathHint,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (v) => widget.tools.set(widget.spec.name, v),
                  ),
                ),
                IconButton(
                  tooltip: l10n.toolsBrowse,
                  icon: const Icon(Icons.folder_open_rounded),
                  onPressed: _browse,
                ),
                IconButton(
                  tooltip: l10n.toolsClear,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: custom
                      ? () {
                          _controller.clear();
                          widget.tools.set(widget.spec.name, null);
                        }
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Branch Dock 설정 — 자동 fetch(5분마다·창으로 돌아올 때)와 파일·폴더를 여는 편집기 명령.
/// 편집기 명령은 공유 영역의 "편집기에서 열기"와 변경 파일 열기가 함께 쓴다 (공통 키 `editor_command`).
class _BranchSection extends StatefulWidget {
  const _BranchSection();

  @override
  State<_BranchSection> createState() => _BranchSectionState();
}

class _BranchSectionState extends State<_BranchSection> {
  TextEditingController? _editor;

  @override
  void dispose() {
    _editor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.maybeOf(context);
    if (ws == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final prefs = RepoPrefs(ws.prefs);
    _editor ??= TextEditingController(text: ws.editorCommand);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(l10n.bdMenuAutoFetch),
          value: prefs.autoFetch,
          onChanged: (v) async {
            await prefs.setAutoFetch(v);
            if (mounted) setState(() {});
          },
        ),
        _Heading(l10n.bdMenuEditor),
        Text(
          l10n.bdEditorMessage,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _editor,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'code',
            border: const OutlineInputBorder(),
            labelText: l10n.bdEditorLabel,
          ),
          onChanged: ws.setEditorCommand,
        ),
      ],
    );
  }
}
