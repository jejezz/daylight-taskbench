// 점검 탭: dotnet SDK·프로젝트·솔루션·AOT 링크 도구 점검과 다시 점검 버튼 (docs/AVALONIA_RUNNER.md "환경 점검").
// 점검은 칸이 처음 펼쳐질 때 한 번 읽고, 브랜치가 바뀌면 오래된 값으로 표시한다.

import 'package:flutter/material.dart';

import '../../../core/check_status.dart';
import '../../../core/ui/check_status_icon.dart';
import '../../../core/ui/section_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../run/avalonia_controller.dart';

String _checkText(AppLocalizations l10n, AvaloniaCheck c) {
  final ok = c.status == CheckStatus.ok;
  return switch (c.id) {
    AvaloniaCheckId.dotnet => ok ? l10n.avCheckDotnetOk(c.value ?? '') : l10n.avCheckDotnetFail,
    AvaloniaCheckId.project => ok ? l10n.avCheckProjectOk(c.value ?? '') : l10n.avCheckProjectFail,
    AvaloniaCheckId.solution => ok ? l10n.avCheckSolutionOk(c.value ?? '') : l10n.avCheckSolutionWarn,
    AvaloniaCheckId.aot => ok ? l10n.avCheckAotOk : l10n.avCheckAotWarn,
  };
}

class AvaloniaDoctorTab extends StatelessWidget {
  const AvaloniaDoctorTab({super.key, required this.controller});

  final AvaloniaController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        SectionTitle(
          l10n.avChecksTitle,
          trailing: controller.diagnosing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: controller.busy ? null : controller.runDiagnostics, child: Text(l10n.avRecheck)),
        ),
        if (controller.diagnosticsStale) Text(l10n.avChecksStale, style: theme.textTheme.bodySmall),
        for (final k in controller.checks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: CheckStatusIcon(k.status)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(_checkText(l10n, k), style: theme.textTheme.bodySmall)),
            ]),
          ),
      ],
    );
  }
}
