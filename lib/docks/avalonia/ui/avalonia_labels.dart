// 동작 이름 (Run 탭의 드롭다운과 접힌 제목의 요약이 같은 문구를 쓴다).

import '../../../l10n/app_localizations.dart';
import '../run/avalonia_plan.dart';

String avaloniaActionLabel(AppLocalizations l10n, AvaloniaAction a) => switch (a) {
      AvaloniaAction.run => l10n.avActionRun,
      AvaloniaAction.build => l10n.avActionBuild,
      AvaloniaAction.test => l10n.avActionTest,
      AvaloniaAction.publishAot => l10n.avActionPublishAot,
      AvaloniaAction.aotRun => l10n.avActionAotRun,
      AvaloniaAction.clean => l10n.avActionClean,
    };
