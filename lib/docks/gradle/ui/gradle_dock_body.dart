// Gradle Runner 칸의 내용 (단계 9b): 프로젝트 머리와 모듈 목록. 탭은 이어지는 단계에서 붙는다.

import 'package:flutter/material.dart';

import '../../../core/ui/info_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../workspace/workspace.dart';
import '../detect/gradle_project.dart';
import '../gradle_dock.dart';

class GradleDockBody extends StatelessWidget {
  const GradleDockBody({super.key, required this.dock, required this.workspace});

  final GradleDock dock;
  final Workspace workspace;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: dock,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final selected = dock.selected(workspace);
          final project = dock.project;
          if (selected == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (dock.projects.length > 1)
                DropdownButton<String>(
                  isExpanded: true,
                  isDense: true,
                  value: selected.path,
                  items: [
                    for (final p in dock.projects) DropdownMenuItem(value: p.path, child: Text(p.name, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (path) {
                    final chosen = dock.projects.where((e) => e.path == path).firstOrNull;
                    if (chosen != null) dock.choose(workspace, chosen);
                  },
                )
              else
                Text(selected.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.xs),
              if (project != null)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    InfoChip(project.shape == GradleShape.androidApp ? l10n.grShapeAndroid : l10n.grShapeJvm),
                    if (selected.version != null) InfoChip(selected.version!),
                    InfoChip(project.hasWrapper ? l10n.grWrapperFound : l10n.grWrapperMissing),
                  ],
                ),
              if (project?.readError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.grReadFailed(project!.readError!), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
              ],
              if (project != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.grModules, style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                if (project.modules.isEmpty)
                  Text(l10n.grNoModules, style: theme.textTheme.bodySmall)
                else
                  for (final m in project.modules) _ModuleRow(module: m),
              ],
            ],
          );
        },
      );
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module});

  final GradleModule module;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final kind = switch (module.kind) {
      ModuleKind.androidApp => l10n.grModuleAndroidApp,
      ModuleKind.androidLibrary => l10n.grModuleAndroidLib,
      ModuleKind.jvmApp => l10n.grModuleJvmApp,
      ModuleKind.springBoot => l10n.grModuleSpring,
      ModuleKind.other => l10n.grModuleOther,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(module.path, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.sm),
          InfoChip(kind),
        ],
      ),
    );
  }
}
