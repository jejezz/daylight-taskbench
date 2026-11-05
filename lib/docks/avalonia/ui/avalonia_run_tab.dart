// 실행 탭: 앱·동작·옵션 → 실행할 명령 → 시작/중지 → 환경 점검 → 출력 (docs/AVALONIA_RUNNER.md §4.1).
// Gradle Run 탭과 같은 틀이다: 화면에 보이는 명령이 곧 실제로 실행되는 명령이다.

import 'package:flutter/material.dart';

import '../../../core/check_status.dart';
import '../../../core/command_log.dart';
import '../../../core/ui/check_status_icon.dart';
import '../../../core/ui/command_text.dart';
import '../../../core/ui/output_section.dart';
import '../../../core/ui/section_widgets.dart';
import '../../../core/ui/step_status_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../detect/avalonia_project.dart';
import '../run/avalonia_controller.dart';
import '../run/avalonia_plan.dart';
import 'avalonia_labels.dart';

String _stepLabel(AppLocalizations l10n, AvaloniaStepKind k) => switch (k) {
      AvaloniaStepKind.dotnet => l10n.avStepDotnet,
      AvaloniaStepKind.launch => l10n.avStepLaunch,
    };

String _blockerText(AppLocalizations l10n, AvaloniaBlocker b) => switch (b) {
      AvaloniaBlocker.noProject || AvaloniaBlocker.noApp => l10n.avBlockNoApp,
      AvaloniaBlocker.noSolution => l10n.avBlockNoSolution,
    };

String _failureText(AppLocalizations l10n, AvaloniaFailure f) => switch (f) {
      AvaloniaFailure.aotLinker => l10n.avHintAotLinker,
      AvaloniaFailure.sdk => l10n.avHintSdk,
      AvaloniaFailure.fileLocked => l10n.avHintFileLocked,
      AvaloniaFailure.restore => l10n.avHintRestore,
      AvaloniaFailure.rid => l10n.avHintRid,
    };

String _checkText(AppLocalizations l10n, AvaloniaCheck c) {
  final ok = c.status == CheckStatus.ok;
  return switch (c.id) {
    AvaloniaCheckId.dotnet => ok ? l10n.avCheckDotnetOk(c.value ?? '') : l10n.avCheckDotnetFail,
    AvaloniaCheckId.project => ok ? l10n.avCheckProjectOk(c.value ?? '') : l10n.avCheckProjectFail,
    AvaloniaCheckId.solution => ok ? l10n.avCheckSolutionOk(c.value ?? '') : l10n.avCheckSolutionWarn,
    AvaloniaCheckId.aot => ok ? l10n.avCheckAotOk : l10n.avCheckAotWarn,
  };
}

class AvaloniaRunTab extends StatefulWidget {
  const AvaloniaRunTab({super.key, required this.controller, required this.log});

  final AvaloniaController controller;
  final CommandLog log;

  @override
  State<AvaloniaRunTab> createState() => _AvaloniaRunTabState();
}

class _AvaloniaRunTabState extends State<AvaloniaRunTab> {
  late final _extra = TextEditingController(text: widget.controller.options.extraArgs);
  late final _rid = TextEditingController(text: widget.controller.options.rid);
  late final _aotDir = TextEditingController(text: widget.controller.options.aotDir);

  @override
  void dispose() {
    _extra.dispose();
    _rid.dispose();
    _aotDir.dispose();
    super.dispose();
  }

  AvaloniaController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = c.plan;
    final interactive = plan.steps.any((s) => s.interactive);
    final apps = c.project?.apps ?? const <AvaloniaApp>[];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (apps.length > 1) ...[
          _Labeled(
            l10n.avAppLabel,
            DropdownButton<AvaloniaApp>(
              isExpanded: true,
              isDense: true,
              value: c.app,
              items: [for (final a in apps) DropdownMenuItem(value: a, child: Text(a.fileName, overflow: TextOverflow.ellipsis))],
              onChanged: c.running ? null : (a) => a == null ? null : c.selectApp(a),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _Labeled(
          l10n.avActionLabel,
          DropdownButton<AvaloniaAction>(
            isExpanded: true,
            isDense: true,
            value: c.action,
            items: [for (final a in c.actions) DropdownMenuItem(value: a, child: Text(avaloniaActionLabel(l10n, a)))],
            onChanged: c.running ? null : (a) => a == null ? null : c.selectAction(a),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _options(l10n),
        const SizedBox(height: AppSpacing.lg),
        SectionTitle(l10n.avCommandsTitle),
        if (plan.blocker != null)
          Text(_blockerText(l10n, plan.blocker!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < plan.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(padding: const EdgeInsets.only(top: 2), child: StepStatusIcon(i < c.statuses.length ? c.statuses[i] : null)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${i + 1}. ${_stepLabel(l10n, plan.steps[i].kind)}', style: theme.textTheme.labelLarge),
                                CommandText(plan.steps[i].commandLine),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (plan.pathExtended)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.avPathNote, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: c.running
                ? OutlinedButton(onPressed: c.cancel, child: Text(interactive ? l10n.avStop : l10n.avCancel))
                : FilledButton(onPressed: plan.runnable ? c.start : null, child: Text(avaloniaActionLabel(l10n, c.action))),
          ),
        ]),
        if (c.missingCommand != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l10n.avHintMissingCommand(c.missingCommand!), style: TextStyle(color: theme.colorScheme.error)),
          )
        else if (c.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(_failureText(l10n, c.hint!), style: TextStyle(color: theme.colorScheme.error)),
          ),
        const SizedBox(height: AppSpacing.lg),
        _checks(l10n, theme),
        const SizedBox(height: AppSpacing.lg),
        OutputSection(log: widget.log),
      ],
    );
  }

  Widget _checks(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          l10n.avChecksTitle,
          trailing: c.diagnosing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: c.busy ? null : c.runDiagnostics, child: Text(l10n.avRecheck)),
        ),
        if (c.diagnosticsStale) Text(l10n.avChecksStale, style: theme.textTheme.bodySmall),
        for (final k in c.checks)
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

  Widget _options(AppLocalizations l10n) {
    final o = c.options;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: !o.isDefault,
      title: Text(l10n.avOptionsTitle, style: Theme.of(context).textTheme.titleSmall),
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.avOptDebug),
          value: o.debug,
          onChanged: c.running ? null : (v) => c.setOptions(o.copyWith(debug: v)),
        ),
        TextField(
          controller: _rid,
          decoration: InputDecoration(labelText: l10n.avRidField, isDense: true),
          style: AppFonts.mono,
          onChanged: (v) => c.setOptions(c.options.copyWith(rid: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _aotDir,
          decoration: InputDecoration(labelText: l10n.avAotDirField, isDense: true),
          style: AppFonts.mono,
          onChanged: (v) => c.setOptions(c.options.copyWith(aotDir: v.trim().isEmpty ? AvaloniaOptions.defaultAotDir : v)),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _extra,
          decoration: InputDecoration(labelText: l10n.avExtraArgs, isDense: true),
          style: AppFonts.mono,
          onChanged: (v) => c.setOptions(c.options.copyWith(extraArgs: v)),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.child);

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          child,
        ],
      );
}
