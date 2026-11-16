// 설정 창 "외형" 구역의 글꼴·편집기 색상 구성표·화면 글자 크기 선택 (그림의 네 항목).
//   UiFontPicker / EditorFontPicker: 설치된 글꼴을 이름으로 찾아 고른다 (편집기는 고정폭만).
//   EditorSchemePicker: 색 견본이 달린 목록.   TextScaleSlider: 80%~150%, 5% 단위 배율.

import 'dart:io';

import 'package:flutter/material.dart';

import '../editor/editor_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/editor_schemes.dart';
import 'app_settings.dart';
import 'system_fonts.dart';

/// 기본값을 뜻하는 항목의 값 (글꼴 이름은 비어 있을 수 없다).
const _defaultValue = '';

class _FontDropdown extends StatelessWidget {
  const _FontDropdown({
    required this.current,
    required this.defaultName,
    required this.families,
    required this.onChanged,
    this.previewInOwnFont = false,
  });

  final String? current;
  final String defaultName;
  final List<String> families;
  final ValueChanged<String?> onChanged;

  /// 항목을 그 글꼴로 그린다 (목록이 짧은 고정폭 글꼴에서만 — 수백 개를 다 그리면 느리다).
  final bool previewInOwnFont;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 지금 고른 글꼴이 이 컴퓨터에 없어도(지워졌거나 다른 컴퓨터) 목록에 남겨서 보이게 한다.
    final names = {
      for (final f in families)
        if (f != defaultName) f,
      if (current != null && current != defaultName) current!,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return DropdownMenu<String>(
      key: ValueKey('${current ?? _defaultValue}/${names.length}'),
      expandedInsets: EdgeInsets.zero,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 320,
      hintText: l10n.settingsFontSearchHint,
      initialSelection: current ?? _defaultValue,
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: _defaultValue,
          label: l10n.settingsFontDefault(defaultName),
        ),
        for (final n in names)
          DropdownMenuEntry(
            value: n,
            label: n,
            labelWidget: previewInOwnFont
                ? Text(n, style: TextStyle(fontFamily: n, fontFamilyFallback: AppFonts.fallback))
                : null,
          ),
      ],
      onSelected: (v) {
        if (v != null) onChanged(v.isEmpty ? null : v);
      },
    );
  }
}

/// 화면(메뉴·본문) 글꼴.
class UiFontPicker extends StatelessWidget {
  const UiFontPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    return FutureBuilder<List<String>>(
      future: SystemFonts.instance.families(),
      builder: (context, snap) => _FontDropdown(
        current: settings.uiFont,
        defaultName: AppFonts.family,
        families: snap.data ?? const [],
        onChanged: settings.setUiFont,
      ),
    );
  }
}

/// 편집기 글꼴 — 고정폭 글꼴만.
class EditorFontPicker extends StatelessWidget {
  const EditorFontPicker({super.key, required this.settings});

  final EditorSettings settings;

  /// 앱 기본 고정폭 글꼴 중 이 OS 에서 먼저 쓰이는 이름 (표시용).
  static String get defaultName => Platform.isMacOS ? 'Menlo' : 'Consolas';

  @override
  Widget build(BuildContext context) => FutureBuilder<List<String>>(
    future: SystemFonts.instance.monospaced(),
    builder: (context, snap) => _FontDropdown(
      current: settings.fontFamily,
      defaultName: defaultName,
      families: snap.data ?? const [],
      onChanged: settings.setFontFamily,
      previewInOwnFont: true,
    ),
  );
}

/// 색 견본: 바탕 위에 문법 색 다섯 개.
class _SchemeSwatch extends StatelessWidget {
  const _SchemeSwatch(this.scheme);

  final EditorScheme? scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final s = scheme;
    // 앱 테마를 따름: 견본 대신 앱의 면과 주색.
    final bg = s?.background ?? theme.surfaceContainerHighest;
    final bars = s == null
        ? [theme.primary, theme.secondary, theme.tertiary]
        : [s.keyword, s.string, s.number, s.type, s.function];
    return Container(
      width: 56,
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final c in bars)
            Container(
              width: 6,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      ),
    );
  }
}

/// 편집기 색상 구성표. 첫 항목은 앱 테마를 따른다.
class EditorSchemePicker extends StatelessWidget {
  const EditorSchemePicker({super.key, required this.settings});

  final EditorSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownMenu<String>(
      key: ValueKey(settings.schemeId),
      expandedInsets: EdgeInsets.zero,
      requestFocusOnTap: false,
      menuHeight: 320,
      initialSelection: settings.schemeId,
      leadingIcon: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: _SchemeSwatch(settings.scheme),
      ),
      dropdownMenuEntries: [
        DropdownMenuEntry(
          value: EditorScheme.followAppId,
          label: l10n.settingsEditorSchemeFollow,
          leadingIcon: const _SchemeSwatch(null),
        ),
        for (final s in EditorScheme.choices)
          DropdownMenuEntry(value: s.id, label: s.name, leadingIcon: _SchemeSwatch(s)),
      ],
      onSelected: (id) {
        if (id != null) settings.setSchemeId(id);
      },
    );
  }
}

/// 화면 글자 크기 배율 슬라이더 (바로 적용).
class TextScaleSlider extends StatelessWidget {
  const TextScaleSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final l10n = AppLocalizations.of(context);
    final percent = (settings.textScale * 100).round();
    return Row(
      children: [
        Expanded(
          child: Slider(
            min: AppSettings.minTextScale,
            max: AppSettings.maxTextScale,
            divisions: ((AppSettings.maxTextScale - AppSettings.minTextScale) / AppSettings.textScaleStep).round(),
            value: settings.textScale,
            label: '$percent%',
            onChanged: settings.setTextScale,
          ),
        ),
        SizedBox(width: 48, child: Text('$percent%', textAlign: TextAlign.end)),
        IconButton(
          tooltip: l10n.settingsTextScaleReset,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          onPressed: settings.textScale == 1.0 ? null : () => settings.setTextScale(1.0),
        ),
      ],
    );
  }
}
