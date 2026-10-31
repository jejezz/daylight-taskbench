import 'package:flutter/material.dart';

import '../../../ui/style/status_pill.dart';

import '../doctor/checks.dart';
import '../install/flutty_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import 'check_tile.dart';
import '../../../settings/settings_dialog.dart';

/// 점검 탭: 도구·기기·서명 점검 전체와 다시 점검 버튼.
class DoctorTab extends StatelessWidget {
  const DoctorTab({super.key, required this.controller});

  final FluttyController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checks = controller.checks;
    final at = controller.diagnostics?.collectedAt;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                at == null
                    ? l10n.fdDoctorNever
                    : l10n.fdDoctorCollected(
                        TimeOfDay.fromDateTime(at).format(context),
                      ),
                style: theme.textTheme.bodySmall,
              ),
            ),
            FilledButton.tonal(
              onPressed: controller.diagnosing
                  ? null
                  : controller.runDiagnostics,
              child: Text(
                controller.diagnosing ? l10n.fdDoctorRunning : l10n.fdDoctorRun,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                showSettingsDialog(context, initial: SettingsSection.tools),
            child: Text(l10n.fdToolPathsOpen),
          ),
        ),
        if (controller.diagnosticsStale)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.fdDoctorStale, style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.warning))),
          ),
        Opacity(opacity: controller.diagnosticsStale ? 0.6 : 1, child: CheckList(checks)),
        if (checks.isNotEmpty && firstProblem(checks) == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              l10n.fdDoctorAllGood,
              style: theme.textTheme.bodySmall?.copyWith(
                color: toneColor(context, Tone.success),
              ),
            ),
          ),
      ],
    );
  }
}
