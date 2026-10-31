import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:daylight_taskbench/l10n/app_localizations.dart';
import '../repo/environment.dart';
import 'package:daylight_taskbench/theme/app_theme.dart';
import 'action_sheet.dart';
import 'widgets.dart';


/// 환경 점검 체크리스트 (UI_UX.md §8): 항목별 ✓/✕, 설치·로그인 명령 복사.
class EnvironmentCard extends StatelessWidget {
  const EnvironmentCard({super.key, required this.environment, required this.onRecheck, this.onLogin, this.onSetPath});

  final EnvironmentStatus environment;
  final VoidCallback onRecheck;

  /// 로그인 안내(SSH/HTTPS)를 연다. 없으면 명령 복사만.
  final VoidCallback? onLogin;

  /// git / gh 경로를 직접 지정한다 (PLAN.md 3.14). 인자는 `git` 또는 `gh`.
  final ValueChanged<String>? onSetPath;

  Future<void> _copyDiagnostics(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    var version = '?';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } on Object {
      // 테스트처럼 플랫폼 정보가 없으면 버전 없이 복사한다.
    }
    await Clipboard.setData(ClipboardData(text: environment.diagnostics(appVersion: version)));
    if (context.mounted) showDone(context, l10n.bdEnvDiagnosticsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final env = environment;

    String install(String tool) {
      if (Platform.isMacOS) return 'brew install $tool';
      if (Platform.isWindows) return tool == 'git' ? 'winget install --id Git.Git -e' : 'winget install --id GitHub.cli -e';
      return tool == 'git' ? 'sudo apt install git' : 'sudo apt install gh';
    }

    Widget item(
      bool ok,
      String title,
      String detail, {
      String? command,
      String? path,
      bool custom = false,
      String? warning,
      String? tool,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            !ok ? Icons.cancel_rounded : (warning != null ? Icons.warning_rounded : Icons.check_circle_rounded),
            size: 18,
            color: toneColor(context, !ok ? Tone.danger : (warning != null ? Tone.warning : Tone.success)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (custom) ...[
                      const SizedBox(width: 6),
                      StatusPill(label: l10n.bdEnvCustomPath, tone: Tone.primary),
                    ],
                    const Spacer(),
                    if (tool != null && onSetPath != null)
                      SizedBox(
                        height: 24,
                        child: TextButton(onPressed: () => onSetPath!(tool), child: Text(l10n.bdEnvSetPath)),
                      ),
                  ],
                ),
                Text(detail, style: theme.textTheme.bodySmall),
                if (path != null)
                  SelectableText(
                    path,
                    style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                if (warning != null)
                  Text(warning, style: theme.textTheme.bodySmall?.copyWith(color: toneColor(context, Tone.warning))),
                if (!ok && command != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: SelectableText(command, style: AppFonts.mono.copyWith(fontSize: 12))),
                      CopyButton(text: command, size: 14),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // Material이어야 안의 PATH 펼치기(ExpansionTile)가 배경 위에 그려진다.
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.tile),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.bdEnvTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(env.hasGit ? l10n.bdEnvGitOnlyNote : l10n.bdEnvGitRequired, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            item(
              env.hasGit,
              'git',
              env.hasGit ? l10n.bdEnvVersion(env.gitVersion!) : l10n.bdEnvNotInstalled,
              command: install('git'),
              path: env.gitPath,
              custom: env.gitCustom,
              warning: env.gitTooOld ? l10n.bdEnvGitTooOld(EnvironmentStatus.minGit) : null,
              tool: 'git',
            ),
            item(
              env.hasGh,
              'gh (GitHub CLI)',
              env.hasGh ? l10n.bdEnvVersion(env.ghVersion!) : l10n.bdEnvNotInstalled,
              command: install('gh'),
              path: env.ghPath,
              custom: env.ghCustom,
              warning: env.ghTooOld ? l10n.bdEnvGhTooOld(EnvironmentStatus.minGh) : null,
              tool: 'gh',
            ),
            if (env.hasGh)
              item(
                env.ghLoggedIn,
                l10n.bdEnvLogin,
                env.ghLoggedIn ? l10n.bdEnvLoggedInAs(env.ghLogins['github.com'] ?? '') : l10n.bdEnvNotLoggedIn,
                command: 'gh auth login',
              ),
            if (env.hasGh && !env.ghLoggedIn && onLogin != null)
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: Text(l10n.bdLoginTitle),
                ),
              ),
            if (env.checked && env.searchPath.isNotEmpty)
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  dense: true,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(l10n.bdEnvSearchPath, style: theme.textTheme.bodySmall),
                  children: [
                    SelectableText(
                      env.searchPath.split(Platform.isWindows ? ';' : ':').where((p) => p.trim().isNotEmpty).join('\n'),
                      style: AppFonts.mono.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (env.checked)
                  TextButton.icon(
                    onPressed: () => _copyDiagnostics(context),
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: Text(l10n.bdEnvCopyDiagnostics),
                  ),
                OutlinedButton.icon(
                  onPressed: onRecheck,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.bdEnvRecheck),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 앱 바 메뉴의 "환경 점검".
Future<void> showEnvironmentSheet(
  BuildContext context,
  EnvironmentStatus env,
  VoidCallback onRecheck, {
  VoidCallback? onLogin,
  ValueChanged<String>? onSetPath,
}) {
  return showActionSheet<void>(
    context,
    (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: EnvironmentCard(
          environment: env,
          onRecheck: () {
            Navigator.pop(context);
            onRecheck();
          },
          onLogin: onLogin == null
              ? null
              : () {
                  Navigator.pop(context);
                  onLogin();
                },
          onSetPath: onSetPath == null
              ? null
              : (tool) {
                  Navigator.pop(context);
                  onSetPath(tool);
                },
        ),
      ),
    ),
  );
}

/// 파일을 열 편집기 명령 (PLAN.md 3.2). 비우면 OS 기본 앱.
Future<String?> showEditorCommandSheet(BuildContext context, String current) {
  final controller = TextEditingController(text: current);
  return showActionSheet<String>(context, (context) {
    final l10n = AppLocalizations.of(context);
    return StatefulBuilder(
      builder: (context, setState) => ActionSheetBody(
        title: l10n.bdEditorTitle,
        commands: [
          if (controller.text.trim().isNotEmpty) [...controller.text.trim().split(RegExp(r'\s+')), '<file>'],
        ],
        confirmLabel: l10n.bdCommonSave,
        onConfirm: () => Navigator.pop(context, controller.text.trim()),
        children: [
          Text(l10n.bdEditorMessage, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            autofocus: true,
            style: AppFonts.mono.copyWith(fontSize: 12),
            decoration: InputDecoration(labelText: l10n.bdEditorLabel, hintText: 'code'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: 6, children: [
            for (final c in ['code', 'cursor', 'idea', 'subl', 'zed'])
              SmallChip(label: c, onPressed: () => setState(() => controller.text = c)),
          ]),
        ],
      ),
    );
  });
}
