// Run 탭 — 빌드 모드·옵션·계획·실행 단추와 마지막 출력 (flutty-dock-flutter 의 home_screen.dart 에서 옮김).
// [Taskbench에서 달라진 곳] 화면 전체가 아니라 칸 안의 탭 하나다. 프로젝트 머리·Git 구역은 공유 영역으로 올라갔다.

import 'package:flutter/material.dart';

import '../../../core/ui/command_text.dart';
import '../../../core/ui/step_status_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../ui/style/status_pill.dart';
import '../devices/mobile_device.dart';
import '../install/flutty_controller.dart';
import '../install/install_plan.dart';
import 'build_options_section.dart';
import 'check_text.dart';
import 'widgets.dart';

// [Taskbench에서 달라진 곳] OutputSection 은 core/ui/output_section.dart 로 옮겼다. 다시 내보낸다.
export '../../../core/ui/output_section.dart';

class BuildSection extends StatefulWidget {
  const BuildSection({super.key, required this.controller});

  final FluttyController controller;

  @override
  State<BuildSection> createState() => BuildSectionState();
}

class BuildSectionState extends State<BuildSection> {
  late final _team = TextEditingController(text: widget.controller.teamId ?? '');

  @override
  void dispose() {
    _team.dispose();
    super.dispose();
  }

  String _stepLabel(AppLocalizations l10n, StepKind k) => switch (k) {
    StepKind.prepare => l10n.fdHomeStepPrepare,
    StepKind.build => l10n.fdHomeStepBuild,
    StepKind.install => l10n.fdHomeStepInstall,
    StepKind.launch => l10n.fdHomeStepLaunch,
    StepKind.run => l10n.fdHomeStepRun,
  };

  /// `flutter clean` → `flutter pub get`을 지금 실행하는 단추와 마지막 결과.
  Widget _cleanButton(FluttyController c, AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message: l10n.fdHomeCleanHelp,
          child: OutlinedButton.icon(
            onPressed: c.running || c.cleaning ? null : c.cleanProject,
            icon: c.cleaning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cleaning_services_rounded, size: 18),
            label: Text(l10n.fdHomeActionClean),
          ),
        ),
        if (c.cleanResult != null && !c.cleaning)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              c.cleanResult! ? l10n.fdHomeCleanDone : l10n.fdHomeCleanFailed,
              style: TextStyle(fontSize: 12, color: c.cleanResult! ? toneColor(context, Tone.success) : theme.colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _runOnlyButton(FluttyController c, AppLocalizations l10n, InstallPlan plan) {
    final ready = plan.runnable && c.artifactReady;
    final button = OutlinedButton(
      onPressed: ready ? () => c.start(phase: RunPhase.run) : null,
      child: Text((c.device?.isDesktop ?? false) ? l10n.fdHomeActionRunOnly : l10n.fdHomeActionInstallOnly),
    );
    // 결과물이 없어서 눌 수 없을 때만 이유를 알려 준다.
    return plan.runnable && !c.artifactReady ? Tooltip(message: l10n.fdHomeRunOnlyNeedsBuild, child: button) : button;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = c.plan;
    final isIos = c.device?.platform == DevicePlatform.ios;
    final interactive = plan.steps.isNotEmpty && plan.steps.first.interactive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(l10n.fdHomeBuildTitle),
        SegmentedButton<BuildMode>(
          segments: [
            ButtonSegment(value: BuildMode.debug, label: Text(l10n.fdHomeModeDebug)),
            ButtonSegment(value: BuildMode.release, label: Text(l10n.fdHomeModeRelease)),
          ],
          selected: {c.mode},
          onSelectionChanged: c.running ? null : (s) => c.setMode(s.first),
        ),
        if (c.project != null) ...[
          const SizedBox(height: AppSpacing.xs),
          // 프로젝트마다 입력 칸을 새로 만든다 (저장된 옵션이 그 프로젝트 것으로 채워지게).
          BuildOptionsSection(key: ValueKey(c.project!.path), controller: c),
        ],
        if (isIos) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _team,
            enabled: !c.running,
            decoration: InputDecoration(
              labelText: l10n.fdHomeTeamLabel,
              hintText: c.project?.iosTeamId,
              helperText: l10n.fdHomeTeamHelp,
              helperMaxLines: 3,
              isDense: true,
            ),
            onChanged: c.setTeamId,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (plan.steps.isNotEmpty) ...[
          SectionTitle(l10n.fdHomeStepsTitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 빌드 전에 하는 일이라 목록 맨 위에 둔다. 누르면 바로 실행하고, 안 눌러도 빌드는 된다.
                  _cleanButton(c, l10n, theme),
                  const Divider(height: AppSpacing.xl),
                  for (var i = 0; i < plan.steps.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == plan.steps.length - 1 ? 0 : AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: StepStatusIcon(i < c.statuses.length ? c.statuses[i] : null),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${_stepLabel(l10n, plan.steps[i].kind)}',
                                  style: theme.textTheme.labelLarge,
                                ),
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
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: c.running
                  ? OutlinedButton(
                      onPressed: c.cancel,
                      child: Text(interactive ? l10n.fdHomeActionStop : l10n.fdHomeActionCancel),
                    )
                  : FilledButton(
                      onPressed: plan.runnable ? c.start : null,
                      // 데스크톱(이 컴퓨터)은 바로 실행하고, 폰은 설치한다.
                      child: Text(
                        interactive
                            ? l10n.fdHomeActionRun
                            : (c.device?.isDesktop ?? false)
                            ? l10n.fdHomeActionBuildRun
                            : l10n.fdHomeActionInstall,
                      ),
                    ),
            ),
            if (c.running && interactive) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                tooltip: l10n.fdHomeHotReload,
                icon: const Icon(Icons.bolt_rounded),
                onPressed: () => c.sendKey('r'),
              ),
              IconButton.outlined(
                tooltip: l10n.fdHomeHotRestart,
                icon: const Icon(Icons.restart_alt_rounded),
                onPressed: () => c.sendKey('R'),
              ),
            ],
          ],
        ),
        // release: 빌드와 실행을 따로 할 수 있다. 실행만은 이미 만든 결과물이 있을 때 쓴다.
        if (plan.splittable && !c.running) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: plan.runnable ? () => c.start(phase: RunPhase.build) : null,
                  child: Text(l10n.fdHomeActionBuildOnly),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _runOnlyButton(c, l10n, plan)),
            ],
          ),
        ],
        // 실행할 명령이 없을 때(기기를 아직 못 골랐을 때 등)는 카드가 없으므로 정리 단추만 따로 둔다.
        if (c.project != null && plan.steps.isEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _cleanButton(c, l10n, theme),
        ],
        if (c.missingCommand != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(l10n.fdHintMissingCommand(c.missingCommand!), style: TextStyle(color: theme.colorScheme.error)),
          )
        else if (c.hint != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(failureHintText(l10n, c.hint!), style: TextStyle(color: theme.colorScheme.error)),
          ),
      ],
    );
  }
}
