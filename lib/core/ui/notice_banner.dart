// 칸 안에서 보이는 한 줄 안내(브랜치가 바뀜, 작업 진행 중 …). Flutty 칸에서 옮겼다 — Gradle 칸도 쓴다.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, this.onClose});

  final String text;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSecondaryContainer;
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.xs, AppSpacing.xs),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: fg))),
            if (onClose != null)
              IconButton(
                tooltip: l10n.commonClose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}
