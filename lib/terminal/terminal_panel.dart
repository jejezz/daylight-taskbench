import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'local_shell.dart';
import 'local_shell_session.dart';
import 'terminal_pane.dart';
import 'terminal_session.dart';
import 'terminal_sessions_controller.dart';
import 'terminal_settings.dart';

// [Taskbench에서 달라진 곳] 위치는 lib/terminal/, 아래 패널이 아니라 확장 영역 가운데에 놓인다. 처음 열릴 때 기본 셸을
// 저장소 루트에서 한 번 자동으로 띄운다 ([_AutoOpen]).

/// 터미널 탭: 로컬 셸 세션 여러 개를 작은 탭 줄로 보여 준다.
/// 세션은 [TerminalSessionsController]가 쥐고 있어서, 이 패널이 다시 그려져도(아래 패널을 접었다 펴도) 살아 있다.
class TerminalPanel extends StatelessWidget {
  const TerminalPanel({super.key, required this.controller, required this.settings, required this.projectRoot});

  final TerminalSessionsController controller;
  final TerminalSettings settings;

  /// 새 터미널을 열 때 쓸 작업 폴더(열린 프로젝트/worktree). 이미 열린 세션은 자기 폴더를 그대로 쓴다.
  final String projectRoot;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // settings도 함께 듣는다 — 글꼴 설정을 바꾸면 열려 있는 터미널에도 바로 적용된다.
      listenable: Listenable.merge([controller, settings]),
      builder: (context, _) {
        final sessions = controller.sessions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Expanded(
                    child: sessions.isEmpty
                        ? const SizedBox.shrink()
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (var i = 0; i < sessions.length; i++)
                                _SessionTab(
                                  session: sessions[i],
                                  selected: i == controller.selected,
                                  onTap: () => controller.select(i),
                                  onClose: () => controller.closeAt(i),
                                ),
                            ],
                          ),
                  ),
                  _NewTerminalButton(controller: controller, workingDirectory: projectRoot),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: sessions.isEmpty
                  ? _EmptyState(controller: controller, workingDirectory: projectRoot)
                  : IndexedStack(
                      index: controller.selected,
                      children: [
                        for (var i = 0; i < sessions.length; i++)
                          _SessionBody(
                            key: ValueKey(sessions[i]),
                            session: sessions[i],
                            settings: settings,
                            active: i == controller.selected,
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// 세션 하나의 작은 탭(이름 + 닫기). 끝났으면 색이 달라진다.
class _SessionTab extends StatelessWidget {
  const _SessionTab({required this.session, required this.selected, required this.onTap, required this.onClose});

  final LocalShellSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final exited = session.status == SessionStatus.idle && session.exitCode != null;
        final failed = session.status == SessionStatus.error;
        return InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0),
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.terminal_rounded,
                  size: 14,
                  color: failed
                      ? theme.colorScheme.error
                      : exited
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(session.tabTitle, style: theme.textTheme.bodySmall),
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs / 2),
                    child: Tooltip(
                      message: l10n.terminalCloseTooltip,
                      child: Icon(Icons.close_rounded, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 터미널 화면 + (끝났으면) 다시 시작할 수 있는 안내 띠.
class _SessionBody extends StatelessWidget {
  const _SessionBody({super.key, required this.session, required this.settings, required this.active});

  final LocalShellSession session;
  final TerminalSettings settings;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final error = session.startError;
        final exitCode = session.exitCode;
        final message = session.status == SessionStatus.error && error != null
            ? l10n.terminalStartError(error)
            : session.status == SessionStatus.idle && exitCode != null
            ? l10n.terminalExited(session.shell.name, exitCode)
            : null;
        return Stack(
          children: [
            Positioned.fill(child: TerminalPane(session: session, settings: settings, active: active)),
            if (message != null) Positioned(left: 0, right: 0, bottom: 0, child: _ExitBanner(message: message, onRestart: session.restart)),
          ],
        );
      },
    );
  }
}

class _ExitBanner extends StatelessWidget {
  const _ExitBanner({required this.message, required this.onRestart});

  final String message;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
          TextButton(onPressed: onRestart, child: Text(l10n.terminalRestart)),
        ],
      ),
    );
  }
}

class _NewTerminalButton extends StatelessWidget {
  const _NewTerminalButton({required this.controller, required this.workingDirectory});

  final TerminalSessionsController controller;
  final String workingDirectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!controller.shellsLoaded) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final shells = controller.shells;
    if (shells.isEmpty) {
      return IconButton(tooltip: l10n.terminalNoShells, icon: Icon(Icons.add_rounded, size: 18), onPressed: null);
    }
    if (shells.length == 1) {
      return IconButton(
        tooltip: l10n.terminalNew,
        icon: Icon(Icons.add_rounded, size: 18),
        onPressed: () => controller.add(workingDirectory, shells.first),
      );
    }
    return PopupMenuButton<LocalShell>(
      tooltip: l10n.terminalNew,
      icon: Icon(Icons.add_rounded, size: 18),
      itemBuilder: (context) => [for (final shell in shells) PopupMenuItem(value: shell, child: Text(shell.name))],
      onSelected: (shell) => controller.add(workingDirectory, shell),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.controller, required this.workingDirectory});

  final TerminalSessionsController controller;
  final String workingDirectory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canAdd = controller.shellsLoaded && controller.shells.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.terminalEmpty, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.terminalEmptyHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: canAdd ? () => controller.add(workingDirectory) : null,
            icon: Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.terminalNew),
          ),
        ],
      ),
    );
  }
}
