// Doctor 탭: JDK·SDK·adb·래퍼·서명 점검과 다시 점검 버튼 (docs/GRADLE_RUNNER.md §4.4).
// 점검 결과는 칸이 처음 펼쳐질 때 한 번 읽고, 브랜치가 바뀌면 오래된 값으로 표시한다.

import 'package:flutter/material.dart';

import '../../../core/check_status.dart';
import '../../../core/ui/check_status_icon.dart';
import '../../../core/ui/section_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../settings/settings_dialog.dart';
import '../../../theme/app_theme.dart';
import '../../../ui/style/status_pill.dart';
import '../doctor/gradle_diagnostics.dart';
import '../run/gradle_controller.dart';

/// 점검 항목의 제목·보충 설명·해결 단계. 문구는 [GradleCheck.id]·상태·params 로 만든다.
({String title, String? steps}) gradleCheckText(AppLocalizations l10n, GradleCheck c) {
  String p(String k) => c.params[k] ?? '';
  final s = c.status;
  return switch (c.id) {
    GradleCheckId.project => switch (s) {
        CheckStatus.fail => (title: l10n.grCheckProjectFail(p('reason')), steps: null),
        CheckStatus.warn => (title: l10n.grCheckProjectWarn, steps: null),
        _ => (title: l10n.grCheckProjectOk(p('count')), steps: null),
      },
    GradleCheckId.wrapper => switch (s) {
        CheckStatus.ok => (title: l10n.grCheckWrapperOk, steps: null),
        CheckStatus.warn => (title: l10n.grCheckWrapperWarn(p('gradle')), steps: null),
        _ => (title: l10n.grCheckWrapperFail, steps: l10n.grStepsWrapper),
      },
    GradleCheckId.jdk => switch (s) {
        CheckStatus.fail => (title: l10n.grCheckJdkFail, steps: l10n.grStepsJdkFail),
        CheckStatus.warn => (title: l10n.grCheckJdkOld(p('version'), p('required'), p('agp')), steps: l10n.grStepsJdkOld),
        _ => (title: l10n.grCheckJdkOk(p('version'), p('source')), steps: null),
      },
    GradleCheckId.sdk => s == CheckStatus.ok
        ? (title: l10n.grCheckSdkOk(p('dir'), p('source')), steps: null)
        : (title: l10n.grCheckSdkFail, steps: l10n.grStepsSdkFail),
    GradleCheckId.platform => switch (s) {
        CheckStatus.fail => (title: l10n.grCheckPlatformFail(p('api')), steps: l10n.grStepsPlatformFail(p('api'))),
        CheckStatus.warn => (title: l10n.grCheckPlatformWarn, steps: l10n.grStepsPlatformWarn),
        _ => (title: c.params.containsKey('api') ? l10n.grCheckPlatformOkApi(p('api')) : l10n.grCheckPlatformOk, steps: null),
      },
    GradleCheckId.licenses => s == CheckStatus.ok
        ? (title: l10n.grCheckLicensesOk, steps: null)
        : (title: l10n.grCheckLicensesWarn, steps: l10n.grStepsLicenses),
    GradleCheckId.adb => switch (s) {
        CheckStatus.ok => (title: l10n.grCheckAdbOk(p('version')), steps: null),
        CheckStatus.warn => (title: l10n.grCheckAdbWarn(p('path')), steps: l10n.grStepsAdb),
        _ => (title: l10n.grCheckAdbFail, steps: l10n.grStepsAdb),
      },
    GradleCheckId.signing => switch (s) {
        CheckStatus.ok => (title: l10n.grCheckSigningOk, steps: null),
        CheckStatus.warn => (title: l10n.grCheckSigningWarn, steps: l10n.grStepsSigning),
        _ => (title: l10n.grCheckSigningFail, steps: l10n.grStepsSigning),
      },
  };
}

class GradleDoctorTab extends StatelessWidget {
  const GradleDoctorTab({super.key, required this.controller});

  final GradleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final checks = controller.checks;
    final at = controller.diagnostics?.collectedAt;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(children: [
          Expanded(
            child: Text(
              at == null ? l10n.grDoctorNever : l10n.grDoctorCollected(TimeOfDay.fromDateTime(at).format(context)),
              style: theme.textTheme.bodySmall,
            ),
          ),
          FilledButton.tonal(
            onPressed: controller.diagnosing ? null : controller.runDiagnostics,
            child: Text(controller.diagnosing ? l10n.grDoctorRunning : l10n.grDoctorRun),
          ),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => showSettingsDialog(context, initial: SettingsSection.tools),
            child: Text(l10n.grToolPathsOpen),
          ),
        ),
        if (controller.diagnosticsStale)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(l10n.grDoctorStale, style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.warning))),
          ),
        if (checks.isNotEmpty)
          Opacity(
            opacity: controller.diagnosticsStale ? 0.6 : 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Column(children: [for (final c in checks) _CheckTile(c)]),
              ),
            ),
          ),
        if (checks.isNotEmpty && firstGradleProblem(checks) == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(l10n.grDoctorAllGood, style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.success))),
          ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile(this.check);

  final GradleCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final text = gradleCheckText(l10n, check);
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: CheckStatusIcon(check.status)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text.title, style: theme.textTheme.bodyMedium)),
      ],
    );
    final steps = check.status == CheckStatus.ok ? null : text.steps;
    if (steps == null) return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: row);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 24, bottom: AppSpacing.sm),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        dense: true,
        title: row,
        children: [StepsBox(steps)],
      ),
    );
  }
}
