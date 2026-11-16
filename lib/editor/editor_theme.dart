// 코드 편집기(re_editor)의 모양. 색은 현재 테마(ColorScheme · TaskbenchStyle)에서, 글꼴은 앱의 고정폭 글꼴에
// 편집기 배율을 곱한 것이다 — 색 리터럴은 쓰지 않는다 (CLAUDE.md 테마 규칙).
// [Taskbench에서 달라진 곳] workbench 는 구문 강조 전용 색 표(SyntaxTokens)를 테마에 두었다. 여기서는 ColorScheme 과
// 상태색(성공·경고)에서 같은 이름표의 색을 고른다. 글꼴 이름·색상 구성표는 설정(EditorSettings)에서 고른다. 줄 간격·합자 설정은 아직 없다.

import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart';

import '../theme/app_theme.dart';
import '../theme/editor_schemes.dart';
import '../theme/taskbench_style.dart';
import 'editor_settings.dart';
import 'editor_zoom.dart';

/// 지금 고른 편집기 색상 구성표. null 이면 앱 테마를 따른다.
EditorScheme? editorSchemeOf(BuildContext context) =>
    EditorSettingsScope.maybeOf(context)?.scheme;

/// 편집기 본문 글꼴: 앱의 고정폭 글꼴 13에 배율을 곱한 것.
TextStyle editorTextStyle(BuildContext context) {
  const base = 13.0;
  // Text 위젯은 주변 글자 모양을 물려받지만 편집기는 받지 않는다. 같은 글꼴이 같게 보이도록 값을 못 박는다.
  // 사용자가 고른 고정폭 글꼴이 있으면 그것을 앞세우고, 없는 글리프는 앱 기본 고정폭 → OS 한글 글꼴이 채운다.
  final custom = EditorSettingsScope.maybeOf(context)?.fontFamily;
  return AppFonts.mono.copyWith(
    fontSize: base * EditorZoomScope.scaleOf(context),
    height: 1.5,
    fontFamily: custom ?? AppFonts.mono.fontFamily,
    fontFamilyFallback: [
      if (custom != null) AppFonts.mono.fontFamily!,
      ...AppFonts.mono.fontFamilyFallback!,
      ...AppFonts.fallback,
    ],
    letterSpacing: 0,
    wordSpacing: 0,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.normal,
  );
}

/// 줄 번호 글꼴. 현재 줄은 본문 색, 나머지는 흐린 색.
TextStyle editorLineNumberStyle(BuildContext context, {required bool focused}) {
  final picked = editorSchemeOf(context);
  final scheme = Theme.of(context).colorScheme;
  final Color color;
  if (picked != null) {
    color = focused ? picked.foreground : picked.foreground.withValues(alpha: 0.45);
  } else {
    color = focused ? scheme.onSurface : scheme.outline;
  }
  return editorTextStyle(context).copyWith(color: color);
}

/// 고른 구성표의 highlight.js 이름표 → 글자 모양. 이름표는 [highlightTheme]와 같다.
Map<String, TextStyle> schemeHighlightTheme(EditorScheme s) {
  TextStyle c(Color color, {FontStyle? italic, FontWeight? weight}) =>
      TextStyle(color: color, fontStyle: italic, fontWeight: weight);
  return {
    'root': TextStyle(color: s.foreground),
    'comment': c(s.comment, italic: FontStyle.italic),
    'quote': c(s.comment),
    'doctag': c(s.keyword),
    'keyword': c(s.keyword),
    'formula': c(s.keyword),
    'section': c(s.function, weight: FontWeight.bold),
    'name': c(s.keyword),
    'selector-tag': c(s.keyword),
    'deletion': c(s.variable),
    'subst': c(s.foreground),
    'literal': c(s.keyword),
    'string': c(s.string),
    'regexp': c(s.string),
    'addition': c(s.string),
    'attribute': c(s.variable),
    'meta-string': c(s.string),
    'attr': c(s.variable),
    'variable': c(s.variable),
    'template-variable': c(s.variable),
    'type': c(s.type),
    'selector-class': c(s.type),
    'selector-attr': c(s.type),
    'selector-pseudo': c(s.type),
    'number': c(s.number),
    'symbol': c(s.meta),
    'bullet': c(s.meta),
    'link': c(s.meta),
    'meta': c(s.meta),
    'selector-id': c(s.meta),
    'title': c(s.function),
    'title.function_': c(s.function),
    'title.class_': c(s.type),
    'class-title': c(s.type),
    'built_in': c(s.type),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
  };
}

/// highlight.js 이름표 → 글자 모양 (workbench 의 SyntaxTokens.highlightTheme 와 같은 이름표). 색은 현재 테마에서 고른다.
Map<String, TextStyle> highlightTheme(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final style = context.style;
  final base = scheme.onSurface;
  final comment = scheme.onSurfaceVariant;
  final keyword = scheme.tertiary;
  final string = style.success;
  final number = style.warning;
  final classType = scheme.secondary;
  final title = scheme.primary;
  final meta = scheme.secondary;
  final attr = scheme.error;
  final builtIn = scheme.tertiary;
  final literal = scheme.primary;
  TextStyle c(Color color, {FontStyle? italic, FontWeight? weight}) =>
      TextStyle(color: color, fontStyle: italic, fontWeight: weight);
  return {
    'root': TextStyle(color: base),
    'comment': c(comment, italic: FontStyle.italic),
    'quote': c(comment),
    'doctag': c(keyword),
    'keyword': c(keyword),
    'formula': c(keyword),
    'section': c(title, weight: FontWeight.bold),
    'name': c(attr),
    'selector-tag': c(attr),
    'deletion': c(attr),
    'subst': c(base),
    'literal': c(literal),
    'string': c(string),
    'regexp': c(string),
    'addition': c(string),
    'attribute': c(string),
    'meta-string': c(string),
    'attr': c(attr),
    'variable': c(attr),
    'template-variable': c(attr),
    'type': c(classType),
    'selector-class': c(classType),
    'selector-attr': c(classType),
    'selector-pseudo': c(classType),
    'number': c(number),
    'symbol': c(meta),
    'bullet': c(meta),
    'link': c(meta),
    'meta': c(meta),
    'selector-id': c(meta),
    'title': c(title),
    'title.function_': c(title),
    'title.class_': c(classType),
    'class-title': c(classType),
    'built_in': c(builtIn),
    'emphasis': const TextStyle(fontStyle: FontStyle.italic),
    'strong': const TextStyle(fontWeight: FontWeight.bold),
  };
}

/// [languageId]/[mode]는 구문 강조 규칙이다. 모르는 파일이면 mode 가 null 이고 색 없이 보여 준다.
CodeEditorStyle buildEditorStyle(
  BuildContext context, {
  required String languageId,
  Mode? mode,
}) {
  final scheme = Theme.of(context).colorScheme;
  final picked = editorSchemeOf(context);
  final font = editorTextStyle(context);
  return CodeEditorStyle(
    fontSize: font.fontSize,
    fontFamily: font.fontFamily,
    fontFamilyFallback: font.fontFamilyFallback,
    fontHeight: font.height,
    fontFeatures: font.fontFeatures,
    textColor: picked?.foreground ?? scheme.onSurface,
    hintTextColor: picked?.comment ?? scheme.onSurfaceVariant,
    backgroundColor: picked?.background ?? scheme.surface,
    selectionColor: picked?.selection ?? scheme.primary.withValues(alpha: 0.28),
    cursorColor: picked?.cursor ?? scheme.primary,
    cursorLineColor: (picked?.foreground ?? scheme.primary).withValues(alpha: 0.07),
    chunkIndicatorColor: picked?.comment ?? scheme.onSurfaceVariant,
    codeTheme: mode == null
        ? null
        : CodeHighlightTheme(
            languages: {languageId: CodeHighlightThemeMode(mode: mode)},
            theme: picked == null ? highlightTheme(context) : schemeHighlightTheme(picked),
          ),
  );
}
