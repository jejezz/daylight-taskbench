// Run 탭: 모듈·변형·동작·옵션 → 실행할 명령 → 시작/중지 → 출력 (docs/GRADLE_RUNNER.md §4.1, §4.1b).
// Flutty Run 탭과 같은 틀이다: 화면에 보이는 명령이 곧 실제로 실행되는 명령이다.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/command_log.dart';
import '../../../core/run_session.dart';
import '../../../core/ui/command_text.dart';
import '../../../core/ui/output_section.dart';
import '../../../core/ui/section_widgets.dart';
import '../../../core/ui/step_status_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../detect/gradle_project.dart';
import '../run/gradle_controller.dart';
import '../run/gradle_plan.dart';

String _actionLabel(AppLocalizations l10n, GradleAction a) => switch (a) {
      GradleAction.installRun => l10n.grActionInstallRun,
      GradleAction.install => l10n.grActionInstall,
      GradleAction.assemble => l10n.grActionAssemble,
      GradleAction.bundle => l10n.grActionBundle,
      GradleAction.test => l10n.grActionTest,
      GradleAction.lint => l10n.grActionLint,
      GradleAction.clean => l10n.grActionClean,
      GradleAction.build => l10n.grActionBuild,
      GradleAction.check => l10n.grActionCheck,
      GradleAction.run => l10n.grActionRun,
      GradleAction.bootRun => l10n.grActionBootRun,
      GradleAction.task => l10n.grActionTask,
    };

String _stepLabel(AppLocalizations l10n, GradleStepKind k) => switch (k) {
      GradleStepKind.gradle => l10n.grStepGradle,
      GradleStepKind.launch => l10n.grStepLaunch,
    };

String _blockerText(AppLocalizations l10n, GradleBlocker b) => switch (b) {
      GradleBlocker.noProject || GradleBlocker.noModule => l10n.grBlockNoModule,
      GradleBlocker.noVariant => l10n.grBlockNoVariant,
      GradleBlocker.noTask => l10n.grBlockNoTask,
      GradleBlocker.noDevice => l10n.grBlockNoDevice,
      GradleBlocker.deviceUnauthorized => l10n.grBlockUnauthorized,
    };

String _failureText(AppLocalizations l10n, GradleFailure f, String? detail) => switch (f) {
      GradleFailure.sdkLocation => l10n.grHintSdkLocation,
      GradleFailure.licenses => l10n.grHintLicenses,
      GradleFailure.jdk => l10n.grHintJdk,
      GradleFailure.resolve => l10n.grHintResolve,
      GradleFailure.keystore => l10n.grHintKeystore,
      GradleFailure.installFailed => l10n.grHintInstallFailed(detail ?? 'INSTALL_FAILED'),
      GradleFailure.noDevice => l10n.grHintNoDevice,
    };

class GradleRunTab extends StatefulWidget {
  const GradleRunTab({super.key, required this.controller, required this.log, this.onOpenDoctor});

  final GradleController controller;
  final CommandLog log;

  /// 실패 원인이 환경 문제일 때 Doctor 탭으로 가는 단추.
  final VoidCallback? onOpenDoctor;

  @override
  State<GradleRunTab> createState() => _GradleRunTabState();
}

class _GradleRunTabState extends State<GradleRunTab> {
  late final _extra = TextEditingController(text: widget.controller.options.extraArgs);
  late final _task = TextEditingController(text: widget.controller.customTask);
  final _search = TextEditingController();

  @override
  void dispose() {
    _extra.dispose();
    _task.dispose();
    _search.dispose();
    super.dispose();
  }

  GradleController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = c.plan;
    final interactive = plan.steps.isNotEmpty && plan.steps.first.interactive;
    final m = c.module;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (c.runnableModules.length > 1) ...[
          _Labeled(
            l10n.grModuleLabel,
            DropdownButton<GradleModule>(
              isExpanded: true,
              isDense: true,
              value: m,
              items: [for (final x in c.runnableModules) DropdownMenuItem(value: x, child: Text(x.path, overflow: TextOverflow.ellipsis))],
              onChanged: c.running ? null : (x) => x == null ? null : c.selectModule(x),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (c.isAndroid) ...[
          _Labeled(
            l10n.grVariantLabel,
            Row(children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: c.variants.contains(c.variant) ? c.variant : null,
                  items: [for (final v in c.variants) DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))],
                  onChanged: c.running ? null : (v) => v == null ? null : c.selectVariant(v),
                ),
              ),
              c.loadingVariants
                  ? const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(
                      tooltip: '${l10n.grLoadVariants}\n${l10n.grLoadVariantsHint}',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.manage_search_rounded, size: 18),
                      onPressed: c.busy ? null : c.loadVariants,
                    ),
            ]),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _Labeled(
          l10n.grActionLabel,
          DropdownButton<GradleAction>(
            isExpanded: true,
            isDense: true,
            value: c.actions.contains(c.action) ? c.action : null,
            items: [for (final a in c.actions) DropdownMenuItem(value: a, child: Text(_actionLabel(l10n, a)))],
            onChanged: c.running ? null : (a) => a == null ? null : c.selectAction(a),
          ),
        ),
        if (c.action == GradleAction.task) ..._taskPicker(l10n, theme),
        const SizedBox(height: AppSpacing.sm),
        _options(l10n),
        const SizedBox(height: AppSpacing.lg),
        SectionTitle(l10n.grCommandsTitle),
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
        if (plan.launchSkipped)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.grLaunchSkipped, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: c.running
                ? OutlinedButton(onPressed: c.cancel, child: Text(interactive ? l10n.grStop : l10n.grCancel))
                : FilledButton(onPressed: plan.runnable ? c.start : null, child: Text(_actionLabel(l10n, c.action))),
          ),
          if (c.running && interactive) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton.outlined(tooltip: l10n.grStopDaemons, icon: const Icon(Icons.power_settings_new_rounded), onPressed: c.stopDaemons),
          ],
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: Tooltip(
            message: l10n.grStopDaemonsHint,
            child: TextButton(onPressed: c.busy ? null : c.stopDaemons, child: Text(l10n.grStopDaemons)),
          ),
        ),
        if (c.missingCommand != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l10n.grHintMissingCommand(c.missingCommand!), style: TextStyle(color: theme.colorScheme.error)),
          )
        else if (c.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(_failureText(l10n, c.hint!, c.hintDetail), style: TextStyle(color: theme.colorScheme.error)),
          ),
        if (c.hint != null && const {GradleFailure.sdkLocation, GradleFailure.licenses, GradleFailure.jdk}.contains(c.hint) && widget.onOpenDoctor != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: widget.onOpenDoctor, child: Text(l10n.grDoctorOpen)),
          ),
        ..._outputFolder(l10n),
        const SizedBox(height: AppSpacing.lg),
        OutputSection(log: widget.log),
      ],
    );
  }

  /// 산출물 폴더 열기: 마지막 실행이 APK·AAB 를 만들었고 폴더가 있을 때만.
  List<Widget> _outputFolder(AppLocalizations l10n) {
    final p = c.project;
    final m = c.module;
    if (p == null || m == null || c.running || c.statuses.isEmpty || c.statuses.any((s) => s != StepStatus.done)) return const [];
    final kind = switch (c.action) {
      GradleAction.assemble => 'apk',
      GradleAction.bundle => 'bundle',
      _ => null,
    };
    if (kind == null) return const [];
    final sep = Platform.pathSeparator;
    final dir = '${p.path}$sep${m.dir.replaceAll('/', sep)}${m.dir.isEmpty ? '' : sep}build${sep}outputs$sep$kind';
    if (!Directory(dir).existsSync()) return const [];
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => launchUrl(Uri.file(dir)),
          icon: const Icon(Icons.folder_open_rounded, size: 16),
          label: Text(l10n.grOpenOutput),
        ),
      ),
    ];
  }

  List<Widget> _taskPicker(AppLocalizations l10n, ThemeData theme) {
    final tasks = c.tasks;
    final q = _search.text.trim().toLowerCase();
    final matches = tasks == null ? const <GradleTaskInfo>[] : [for (final t in tasks) if (q.isEmpty || t.name.toLowerCase().contains(q)) t].take(8).toList();
    return [
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: _task,
        decoration: InputDecoration(labelText: l10n.grTaskField, isDense: true),
        style: AppFonts.mono,
        onChanged: c.setCustomTask,
      ),
      const SizedBox(height: AppSpacing.xs),
      Row(children: [
        TextButton(onPressed: c.busy ? null : c.loadTasks, child: Text(c.loadingTasks ? l10n.grLoadingTasks : l10n.grLoadTasks)),
        if (tasks != null)
          Expanded(
            child: TextField(
              controller: _search,
              decoration: InputDecoration(hintText: l10n.grTaskSearch, isDense: true, prefixIcon: const Icon(Icons.search_rounded, size: 18)),
              onChanged: (_) => setState(() {}),
            ),
          ),
      ]),
      if (tasks == null)
        Text(l10n.grTaskNone, style: theme.textTheme.bodySmall)
      else
        for (final t in matches)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(t.name, style: AppFonts.mono.copyWith(fontSize: 12.5)),
            subtitle: t.description.isEmpty ? null : Text(t.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () {
              _task.text = t.name;
              c.setCustomTask(t.name);
            },
          ),
    ];
  }

  Widget _options(AppLocalizations l10n) {
    final o = c.options;
    Widget sw(String label, bool value, GradleOptions Function(bool) change) => SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(label),
          value: value,
          onChanged: c.running ? null : (v) => c.setOptions(change(v)),
        );
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded: !o.isDefault,
      title: Text(l10n.grOptionsTitle, style: Theme.of(context).textTheme.titleSmall),
      children: [
        sw(l10n.grOptOffline, o.offline, (v) => o.copyWith(offline: v)),
        sw(l10n.grOptStacktrace, o.stacktrace, (v) => o.copyWith(stacktrace: v)),
        sw(l10n.grOptNoDaemon, o.noDaemon, (v) => o.copyWith(noDaemon: v)),
        sw(l10n.grOptContinue, o.keepGoing, (v) => o.copyWith(keepGoing: v)),
        TextField(
          controller: _extra,
          decoration: InputDecoration(labelText: l10n.grExtraArgs, isDense: true),
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
