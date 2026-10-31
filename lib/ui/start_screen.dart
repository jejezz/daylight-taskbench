// 저장소를 열기 전 화면 — Branch Dock 의 시작 화면에서 시작한다 (PLAN.md §1.0).
// 폴더 열기 · 끌어놓기 · 최근 저장소 · 저장소가 아닌 폴더의 git init · git/gh 환경 요약.
// [Taskbench에서 달라진 곳] GitHub 복제, 도구 경로 지정, 진단 복사는 단계 3(Branch Dock 이식)에서 들어온다.

import 'package:daylight_taskbench/core/ui/label_with_shortcut.dart';
import 'dart:io';

import 'package:flutter/material.dart';

import '../docks/branch/ui/environment_sheet.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../workspace/workspace.dart';
import 'style/app_mark.dart';
import 'style/glass_card.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({
    super.key,
    required this.workspace,
    required this.onOpenFolder,
    required this.onOpenPath,
    required this.onCheckEnvironment,
    this.onClone,
    this.onLogin,
    this.onSetToolPath,
    this.dragging = false,
  });

  final Workspace workspace;
  final VoidCallback onOpenFolder;
  final ValueChanged<String> onOpenPath;
  final VoidCallback onCheckEnvironment;

  /// GitHub 에서 복제 (gh 로그인이 있을 때). 로그인 안내. git/gh 경로 지정(설정 창의 도구 구역으로).
  final VoidCallback? onClone;
  final VoidCallback? onLogin;
  final ValueChanged<String>? onSetToolPath;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final env = workspace.environment;
    final failure = workspace.failure;
    final failed = workspace.failedPath;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: dragging ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Center(child: AppMark(size: 64)),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.startTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.startDropHint, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          if (failure != null && failed != null) ...[
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  failure == OpenFailure.notARepository ? l10n.startNotARepository(failed) : l10n.startNotFound(failed),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                if (failure == OpenFailure.notARepository) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => workspace.initRepository(failed),
                    icon: const Icon(Icons.create_new_folder_outlined, size: 16),
                    label: Text(l10n.startInitRepository),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Center(
            child: workspace.opening
                ? Row(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text(l10n.startOpening),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    FilledButton.icon(
                      onPressed: env.checked && !env.hasGit ? null : onOpenFolder,
                      icon: const Icon(Icons.folder_open_rounded, size: 16),
                      label: LabelWithShortcut(l10n.homeEmptyAction, _shortcut('O')),
                    ),
                    if (onClone != null && env.ghReady) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: onClone,
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text(l10n.bdCloneTitle),
                      ),
                    ],
                  ]),
          ),
          if (workspace.recent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xl, 0, AppSpacing.sm),
              child: Text(l10n.startRecent, style: theme.textTheme.titleSmall),
            ),
            GlassCard(
              child: Column(children: [
                for (final path in workspace.recent)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder_outlined, size: 20),
                    title: Text(path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).lastOrNull ?? path,
                        style: AppFonts.userContent.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.merge(AppFonts.userContent)),
                    trailing: IconButton(
                      tooltip: l10n.startRemoveRecent,
                      iconSize: 16,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => workspace.removeRecent(path),
                    ),
                    onTap: () => onOpenPath(path),
                  ),
              ]),
            ),
          ],
          // git 이 없으면 전체 안내, gh 가 없거나 로그인 전이면 아래에 점검 카드 (Branch 의 환경 카드 그대로).
          if (env.checked && (!env.hasGit || !env.ghReady)) ...[
            const SizedBox(height: AppSpacing.xl),
            EnvironmentCard(environment: env, onRecheck: onCheckEnvironment, onLogin: env.hasGit ? onLogin : null, onSetPath: onSetToolPath),
          ],
        ],
      ),
    );
  }
}

String _shortcut(String key) => Platform.isMacOS ? '⌘$key' : 'Ctrl+$key';
