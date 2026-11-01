// 터미널(xterm2)의 글꼴과 색. 둘 다 현재 테마(ColorScheme · TaskbenchStyle)에서 읽는다 — 터미널만의 색 구성표를
// 따로 고르지 않는다. 색 리터럴은 쓰지 않는다 (CLAUDE.md 테마 규칙).
// [Taskbench에서 달라진 곳] workbench 는 구문 강조 색을 ANSI 색으로 재활용했다. 여기서는 ColorScheme 과 상태색
// (성공·경고)으로 ANSI 16색을 채운다.

import 'package:flutter/material.dart';
import 'package:xterm2/ui.dart' show TerminalStyle, TerminalTheme;

import '../theme/app_theme.dart';
import '../theme/taskbench_style.dart';
import 'terminal_settings.dart';

/// 터미널 글자 모양: 앱의 고정폭 글꼴([AppFonts.mono]) + 설정한 크기. 고른 글꼴에 없는 글리프는 고정폭 대체 글꼴이,
/// 한글은 OS 한글 글꼴이 채운다.
TerminalStyle terminalStyle(BuildContext context, TerminalSettings settings) {
  return TerminalStyle.fromTextStyle(
    TextStyle(
      fontSize: settings.size,
      fontFamily: AppFonts.mono.fontFamily,
      fontFamilyFallback: [
        ...AppFonts.mono.fontFamilyFallback!,
        ...AppFonts.fallback,
      ],
    ),
  );
}

/// 터미널 배경·글자·커서·선택 영역·ANSI 16색.
TerminalTheme terminalColorTheme(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final style = context.style;
  return TerminalTheme(
    cursor: scheme.primary,
    selection: scheme.primary.withValues(alpha: 0.28),
    foreground: scheme.onSurface,
    background: scheme.surface,
    black: scheme.outline,
    red: scheme.error,
    green: style.success,
    yellow: style.warning,
    blue: scheme.primary,
    magenta: scheme.tertiary,
    cyan: scheme.secondary,
    white: scheme.onSurface,
    brightBlack: scheme.onSurfaceVariant,
    brightRed: scheme.error,
    brightGreen: style.success,
    brightYellow: style.warning,
    brightBlue: scheme.primary,
    brightMagenta: scheme.tertiary,
    brightCyan: scheme.secondary,
    brightWhite: scheme.onSurface,
    searchHitBackground: style.warning.withValues(alpha: 0.55),
    searchHitBackgroundCurrent: style.success.withValues(alpha: 0.65),
    searchHitForeground: scheme.onSurface,
  );
}
