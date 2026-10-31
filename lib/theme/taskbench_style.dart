// Daylight Taskbench 장식 — 글래스 카드, 은은한 배경 워시, 펼친 칸의 글로우 (PLAN.md §1.12).
//
// 규약 테마(app_theme.dart)를 대체하지 않고 그 위에 ThemeExtension 으로 얹는다 (daylight-broom의
// BroomStyle 방식, theming.md §2). 색은 모두 ColorScheme 에서 파생하므로 색 구성(settings.md §4)을
// 바꾸면 장식도 따라가고, 고대비에서는 장식을 끈다. 화면 코드는 색 리터럴을 쓰지 않고
// `Theme.of(context).extension<TaskbenchStyle>()` 와 colorScheme 만 읽는다.

import 'package:flutter/material.dart';

/// 상태에 따라 배경 색이 바뀌는 효과가 가리키는 앱 상태 (PLAN.md §1.12).
enum TaskbenchMood { idle, working, failed, success }

@immutable
class TaskbenchStyle extends ThemeExtension<TaskbenchStyle> {
  const TaskbenchStyle({
    required this.enabled,
    required this.intensity,
    required this.radius,
    required this.cardTop,
    required this.cardBottom,
    required this.border,
    required this.accent,
    required this.working,
    required this.failed,
    required this.success,
    required this.inset,
  });

  /// false 면 장식을 모두 끄고 평평한 면과 굵은 테두리만 쓴다 (고대비).
  final bool enabled;

  /// 장식 세기 배율. "은은하게"를 1.0 으로 두고, 더 화사하게 바꾸려면 이 값만 키운다.
  final double intensity;
  final double radius;

  /// 카드 위·아래 색 (반투명 면).
  final Color cardTop;
  final Color cardBottom;
  final Color border;

  /// 펼친 칸의 워시·글로우 색 = 선택한 색 구성의 주색.
  final Color accent;

  /// 상태색: 작업 중 / 실패 / 성공. 색 구성과 무관한 고정 의미 색.
  final Color working;
  final Color failed;
  final Color success;

  /// 로그·diff 같은 글자 영역 뒤에 까는 안쪽 판.
  final Color inset;

  factory TaskbenchStyle.of(ColorScheme scheme, {required bool enabled, double intensity = 1.0}) {
    final dark = scheme.brightness == Brightness.dark;
    final base = scheme.surface;
    return TaskbenchStyle(
      enabled: enabled,
      intensity: intensity,
      radius: 12,
      cardTop: enabled ? Color.alphaBlend((dark ? Colors.white : scheme.primary).withValues(alpha: dark ? 0.045 : 0.035), base) : base,
      cardBottom: enabled ? Color.alphaBlend((dark ? Colors.white : scheme.primary).withValues(alpha: dark ? 0.015 : 0.01), base) : base,
      border: enabled ? scheme.outlineVariant : scheme.outline,
      accent: scheme.primary,
      working: dark ? const Color(0xFFA78BFA) : const Color(0xFF6D4AE0),
      failed: scheme.error,
      success: dark ? const Color(0xFF34D399) : const Color(0xFF0F8A5F),
      inset: dark ? Colors.black.withValues(alpha: 0.28) : scheme.onSurface.withValues(alpha: 0.05),
    );
  }

  Color moodColor(TaskbenchMood mood) => switch (mood) {
        TaskbenchMood.idle => accent,
        TaskbenchMood.working => working,
        TaskbenchMood.failed => failed,
        TaskbenchMood.success => success,
      };

  @override
  TaskbenchStyle copyWith({bool? enabled, double? intensity}) => TaskbenchStyle(
        enabled: enabled ?? this.enabled,
        intensity: intensity ?? this.intensity,
        radius: radius,
        cardTop: cardTop,
        cardBottom: cardBottom,
        border: border,
        accent: accent,
        working: working,
        failed: failed,
        success: success,
        inset: inset,
      );

  @override
  TaskbenchStyle lerp(ThemeExtension<TaskbenchStyle>? other, double t) {
    if (other is! TaskbenchStyle) return this;
    return TaskbenchStyle(
      enabled: t < 0.5 ? enabled : other.enabled,
      intensity: intensity + (other.intensity - intensity) * t,
      radius: radius + (other.radius - radius) * t,
      cardTop: Color.lerp(cardTop, other.cardTop, t)!,
      cardBottom: Color.lerp(cardBottom, other.cardBottom, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      working: Color.lerp(working, other.working, t)!,
      failed: Color.lerp(failed, other.failed, t)!,
      success: Color.lerp(success, other.success, t)!,
      inset: Color.lerp(inset, other.inset, t)!,
    );
  }
}

extension TaskbenchStyleContext on BuildContext {
  /// 장식이 없는 테마(테스트 등)에서도 안전하게 평평한 값으로 돌아간다.
  TaskbenchStyle get style =>
      Theme.of(this).extension<TaskbenchStyle>() ?? TaskbenchStyle.of(Theme.of(this).colorScheme, enabled: false);
}
