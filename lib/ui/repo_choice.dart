// 저장소가 아닌 폴더를 열었을 때 쓰는 두 창 (PLAN.md §1.13):
//   · [showInitRepoDialog]  — 하위·위험 위치 검사를 통과한 폴더에서 "git 저장소로 만들까요?" (실행할 명령을 미리 보인다)
//   · [showChildRepoChooser] — 하위에 저장소가 여럿이면 그 목록에서 고른다
// 시작 화면과 끌어다 놓기가 같은 창을 쓴다.

import 'dart:io';

import 'package:flutter/material.dart';

import '../docks/branch/git/commands.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../workspace/folder_scan.dart';

/// 확인 창의 결과. 취소하면 null.
class InitChoice {
  const InitChoice({required this.flutterGitignore});

  /// Flutter용 `.gitignore`도 만든다.
  final bool flutterGitignore;
}

Future<InitChoice?> showInitRepoDialog(BuildContext context, NotRepoInfo info) {
  return showDialog<InitChoice>(
    context: context,
    builder: (_) => _InitRepoDialog(info: info),
  );
}

class _InitRepoDialog extends StatefulWidget {
  const _InitRepoDialog({required this.info});

  final NotRepoInfo info;

  @override
  State<_InitRepoDialog> createState() => _InitRepoDialogState();
}

class _InitRepoDialogState extends State<_InitRepoDialog> {
  // Flutter 프로젝트이고 .gitignore 가 아직 없을 때만 제안하고, 제안하면 기본으로 켠다.
  late bool _gitignore = _offerGitignore;

  bool get _offerGitignore =>
      widget.info.isFlutterProject && !widget.info.hasGitignore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.initRepoTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.initRepoBody(widget.info.path)),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.initRepoCommand, style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              GitCommands.init.join(' '),
              style: AppFonts.mono.copyWith(fontSize: 12),
            ),
            if (_offerGitignore) ...[
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.initRepoGitignore),
                value: _gitignore,
                onChanged: (v) => setState(() => _gitignore = v ?? false),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.initRepoNoCommit, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            InitChoice(flutterGitignore: _offerGitignore && _gitignore),
          ),
          child: Text(l10n.initRepoConfirm),
        ),
      ],
    );
  }
}

/// 하위 저장소 목록에서 하나를 고른다. 취소하면 null.
Future<String?> showChildRepoChooser(BuildContext context, NotRepoInfo info) {
  final l10n = AppLocalizations.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.chooseRepoTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chooseRepoBody(info.path)),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                child: ChildRepoList(
                  info: info,
                  onPick: (p) => Navigator.pop(context, p),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
      ],
    ),
  );
}

/// 하위 저장소 목록 (폴더 이름 + 상대 경로). 시작 화면 카드와 고르기 창이 같이 쓴다.
class ChildRepoList extends StatelessWidget {
  const ChildRepoList({super.key, required this.info, required this.onPick});

  final NotRepoInfo info;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = info.path;
    return Column(
      children: [
        for (final repo in info.childRepos)
          ListTile(
            dense: true,
            leading: const Icon(Icons.folder_outlined, size: 20),
            title: Text(
              repo.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).last,
              style: AppFonts.userContent.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _relative(base, repo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.merge(AppFonts.userContent),
            ),
            onTap: () => onPick(repo),
          ),
      ],
    );
  }

  static String _relative(String base, String path) {
    if (!path.startsWith(base)) return path;
    final rest = path.substring(base.length);
    return rest.replaceFirst(RegExp(r'^[\\/]'), '').replaceAll(Platform.pathSeparator, '/');
  }
}
