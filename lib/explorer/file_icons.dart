// 파일 트리에 그릴 아이콘 하나: 모양은 파일 종류에서, 색은 현재 테마의 색 구성(ColorScheme)에서 가져온다.
// 그래서 색 구성(고대비 포함)을 바꾸면 함께 바뀐다 — 화면 코드는 색 리터럴을 쓰지 않는다 (CLAUDE.md 테마 규칙).
// [Taskbench에서 달라진 곳] workbench 는 아이콘 세트(`context.icons`)와 구문 강조 색을 썼다. 여기서는 `Icons.x`와 ColorScheme 로 통일했다 (PLAN.md 결정 22).

import 'package:flutter/material.dart';

import 'file_kind.dart';

typedef FileIcon = ({IconData icon, Color color});

extension FileKindIcons on BuildContext {
  FileIcon fileIcon(FileKind kind) {
    final scheme = Theme.of(this).colorScheme;
    final dim = scheme.onSurfaceVariant;
    return switch (kind) {
      FileKind.dart => (icon: Icons.code_rounded, color: scheme.primary),
      FileKind.package => (
        icon: Icons.inventory_2_outlined,
        color: scheme.primary,
      ),
      FileKind.settings => (icon: Icons.tune_rounded, color: scheme.tertiary),
      FileKind.yaml => (
        icon: Icons.format_align_left_rounded,
        color: scheme.tertiary,
      ),
      FileKind.json => (
        icon: Icons.data_object_rounded,
        color: scheme.secondary,
      ),
      FileKind.document => (
        icon: Icons.article_outlined,
        color: scheme.secondary,
      ),
      FileKind.image => (icon: Icons.image_outlined, color: scheme.tertiary),
      FileKind.markup => (icon: Icons.code_rounded, color: scheme.secondary),
      FileKind.source => (icon: Icons.code_rounded, color: dim),
      FileKind.script => (
        icon: Icons.terminal_rounded,
        color: scheme.secondary,
      ),
      FileKind.config => (icon: Icons.settings_outlined, color: dim),
      FileKind.other => (icon: Icons.insert_drive_file_outlined, color: dim),
    };
  }
}
