// 마지막 명령의 출력 꼬리 + 전체 보기·복사. Flutty Run 탭에서 옮겼다 — Gradle 칸도 같은 구역을 쓴다.

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../command_log.dart';
import 'copy_output_button.dart';
import 'output_viewer.dart';
import 'section_widgets.dart';

class OutputSection extends StatelessWidget {
  const OutputSection({super.key, required this.log});

  final CommandLog log;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) {
        final last = log.last;
        if (last == null) return const SizedBox.shrink();
        final lines = last.output.trimRight().split('\n');
        final tail = lines.length > 60 ? lines.sublist(lines.length - 60) : lines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SectionTitle(l10n.fdHomeOutputTitle)),
                IconButton(
                  tooltip: l10n.fdOutputViewer,
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  icon: const Icon(Icons.open_in_full_rounded),
                  onPressed: () => OutputViewerScreen.open(context, log, last),
                ),
                CopyOutputButton(text: () => '\$ ${last.commandLine}\n${last.output.trimRight()}'),
              ],
            ),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  '\$ ${last.commandLine}\n${tail.join('\n')}',
                  style: AppFonts.mono.copyWith(fontSize: 11.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
