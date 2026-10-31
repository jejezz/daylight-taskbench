// 칸 목록 한 곳 (PLAN.md §4.1 "칸 추가 절차" 4번). 새 runner는 여기에 한 줄을 더한다.
// 순서가 곧 화면 순서다 — Branch 맨 위, 이후 추가된 순서로 고정.

import 'package:flutter/material.dart';

import '../core/tool_paths.dart';
import '../l10n/app_localizations.dart';
import '../workspace/workspace.dart';
import 'branch/branch_dock.dart';
import 'dock_module.dart';
import 'flutty/flutty_dock.dart';
import 'gradle/gradle_dock.dart';

List<DockModule> createDocks({ToolPaths? tools}) => [
      BranchDock(),
      FluttyDock(tools: tools),
      GradleDock(),
      // 나중에: RustDock(), ElectronDock() …
    ];

/// 아무 실행기도 감지되지 않았을 때 Flutty 자리에 놓는 안내 칸. 지원 종류와 다음 행동을 보여 준다.
class RunEmptyDock extends DockModule {
  @override
  String get id => 'run-empty';

  @override
  IconData get icon => Icons.play_circle_outline_rounded;

  @override
  String title(AppLocalizations l10n) => l10n.dockRunTitle;

  @override
  Widget summary(BuildContext context, Workspace w) =>
      Text(AppLocalizations.of(context).dockNoProject, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall);

  @override
  Widget body(BuildContext context, Workspace w) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.dockNoProject, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.dockNoProjectBody, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

/// 지금 디렉터리에서 보일 칸들. 실행기가 하나도 없으면 안내 칸을 끝에 붙인다.
List<DockModule> visibleDocks(List<DockModule> all, RunEmptyDock empty, Workspace w) {
  final shown = [for (final m in all) if (m.appliesTo(w)) m];
  if (!shown.any((m) => m.isRunner)) shown.add(empty);
  return shown;
}
