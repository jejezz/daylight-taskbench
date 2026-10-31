// 설정 창 (conventions/settings.md). 바꾼 값은 바로 적용되고 저장된다 — 확인·적용 버튼은 없다.
//
// 이 앱의 기본 창 폭은 380~440 이라 **도킹한 좁은 배치가 기본**이다: 설정 창은 앱 창보다 커질 수 없으므로
// 창 크기만 보고 배치를 고른다 — 너비 560 이상은 왼쪽 구역 목록(160), 미만은 위쪽 ChoiceChip 한 줄.
// 구역을 더하려면 [SettingsSection]에 한 줄을 더한다 (앞으로 편집기·Branch·Flutty 구역이 들어온다).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_settings.dart';
import 'settings_menus.dart';

enum SettingsSection {
  appearance(Icons.palette_outlined),
  language(Icons.language_rounded);

  const SettingsSection(this.icon);

  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
        appearance => l10n.settingsSectionAppearance,
        language => l10n.settingsSectionLanguage,
      };
}

Future<void> showSettingsDialog(BuildContext context, {SettingsSection initial = SettingsSection.appearance}) =>
    showDialog<void>(context: context, builder: (_) => SettingsDialog(initial: initial));

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
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 160,
                  child: ListView(children: [
                    for (final s in SettingsSection.values)
                      _SectionTile(selected: s == _section, icon: s.icon, label: s.label(l10n), onTap: () => setState(() => _section = s)),
                  ]),
                ),
                const VerticalDivider(),
                Expanded(child: _Content(section: _section, leftPadding: 16)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final s in SettingsSection.values)
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
                  ]),
                ),
                const Divider(height: 16),
                Expanded(child: _Content(section: _section, leftPadding: 0)),
              ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose))],
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
        },
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      );
}

/// 고른 구역은 배경을 채우는 대신 왼쪽에 굵은 선(3px)으로 표시한다 — 고대비에서도 글자가 읽힌다.
class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.selected, required this.icon, required this.label, required this.onTap});

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
          border: Border(left: BorderSide(width: 3, color: selected ? scheme.primary : Colors.transparent)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: selected ? scheme.onSurface : color))),
        ]),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Heading(l10n.settingsLanguage),
      const LanguageSegmentedButton(),
    ]);
  }
}
