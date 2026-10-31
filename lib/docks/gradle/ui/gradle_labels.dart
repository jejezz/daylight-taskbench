// 동작 이름 (Run 탭의 드롭다운과 접힌 제목의 요약이 같은 문구를 쓴다).

import '../../../l10n/app_localizations.dart';
import '../run/gradle_plan.dart';

String gradleActionLabel(AppLocalizations l10n, GradleAction a) => switch (a) {
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
