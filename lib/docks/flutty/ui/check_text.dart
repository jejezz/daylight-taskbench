import 'dart:io' show Platform;

import '../doctor/checks.dart';
import '../install/install_plan.dart';
import '../../../l10n/app_localizations.dart';

/// 점검 항목([CheckItem])을 화면 문구로 바꾼다 — 판단은 `doctor/checks.dart`, 문구는 여기.
String checkTitle(AppLocalizations l, CheckItem c) {
  final p = c.params;
  final s = c.status;
  return switch (c.id) {
    CheckId.flutter =>
      s == CheckStatus.ok
          ? l.fdCheckFlutterOk(p['version']!)
          : p['error'] != null
          ? l.fdCheckFlutterRunFail(p['error']!)
          : l.fdCheckFlutterFail,
    CheckId.xcode =>
      s == CheckStatus.ok
          ? l.fdCheckXcodeOk(p['version']!)
          : l.fdCheckXcodeFail,
    CheckId.adb =>
      s == CheckStatus.ok ? l.fdCheckAdbOk(p['version']!) : l.fdCheckAdbWarn,
    CheckId.connection =>
      s == CheckStatus.ok
          ? l.fdCheckConnectionOk(p['name']!)
          : l.fdCheckConnectionFail(p['name']!),
    CheckId.developerMode =>
      s == CheckStatus.ok
          ? l.fdCheckDeveloperModeOk
          : l.fdCheckDeveloperModeFail,
    CheckId.androidAuth =>
      s == CheckStatus.ok ? l.fdCheckAndroidAuthOk : l.fdCheckAndroidAuthFail,
    CheckId.certificate =>
      s == CheckStatus.ok
          ? l.fdCheckCertificateOk(p['count']!)
          : l.fdCheckCertificateFail,
    CheckId.certificateExpiry => switch (s) {
      CheckStatus.ok => l.fdCheckCertExpiryOk(p['name']!, p['days']!),
      CheckStatus.warn => l.fdCheckCertExpiryWarn(p['name']!, p['days']!),
      _ => l.fdCheckCertExpiryFail(p['name']!),
    },
    CheckId.team => switch (s) {
      CheckStatus.ok => l.fdCheckTeamOk(p['team']!),
      CheckStatus.warn => l.fdCheckTeamWarn(p['team']!),
      _ => l.fdCheckTeamFail,
    },
    CheckId.profile => switch (s) {
      CheckStatus.ok => l.fdCheckProfileOk(p['bundle']!, p['days']!),
      CheckStatus.warn => l.fdCheckProfileWarn(p['bundle']!, p['days']!),
      CheckStatus.fail => l.fdCheckProfileFail(p['bundle']!),
      CheckStatus.info => l.fdCheckProfileInfo(p['bundle']!),
    },
    CheckId.windowsDeveloperMode =>
      s == CheckStatus.ok
          ? l.fdCheckWindowsDevModeOk
          : l.fdCheckWindowsDevModeWarn,
    CheckId.visualStudio =>
      s == CheckStatus.ok
          ? l.fdCheckVisualStudioOk(p['version']!)
          : l.fdCheckVisualStudioFail,
    CheckId.androidSigning => switch (p['mode']) {
      'keystore' => l.fdCheckAndroidSigningKeystore,
      'keystoreMissing' => l.fdCheckAndroidSigningMissing,
      _ => l.fdCheckAndroidSigningDebugKey,
    },
  };
}

/// 덧붙일 한 줄 설명. 없으면 null.
String? checkNote(AppLocalizations l, CheckItem c) =>
    c.id == CheckId.profile && c.params['short'] == 'true'
    ? l.fdCheckProfileShort
    : null;

/// 문제 항목을 고치는 단계별 안내(번호 붙은 여러 줄). 해결할 것이 없으면 null.
String? checkSteps(AppLocalizations l, CheckItem c) {
  if (c.status == CheckStatus.ok || c.status == CheckStatus.info) return null;
  return switch (c.id) {
    CheckId.flutter =>
      Platform.isWindows
          ? l.fdStepsFlutterMissingWindows
          : l.fdStepsFlutterMissing,
    CheckId.xcode => l.fdStepsXcodeMissing,
    CheckId.adb => l.fdStepsAdbMissing,
    CheckId.connection => l.fdStepsWireless,
    CheckId.developerMode => l.fdStepsDeveloperMode,
    CheckId.androidAuth => l.fdStepsAndroidAuth,
    CheckId.certificate => l.fdStepsCertificate,
    CheckId.certificateExpiry || CheckId.profile => l.fdStepsCertExpiry,
    CheckId.team => l.fdStepsTeamId,
    CheckId.androidSigning => l.fdStepsAndroidKeystore,
    CheckId.windowsDeveloperMode => l.fdStepsWindowsDevMode,
    CheckId.visualStudio => l.fdStepsVisualStudio,
  };
}

String blockerText(AppLocalizations l, Blocker b) => switch (b) {
  Blocker.noProject => l.fdBlockerNoProject,
  Blocker.noDevice => l.fdBlockerNoDevice,
  Blocker.platformMissing => l.fdBlockerPlatformMissing,
  Blocker.iosNeedsMac => l.fdBlockerIosNeedsMac,
  Blocker.wireless => l.fdBlockerWireless,
  Blocker.developerModeOff => l.fdBlockerDeveloperModeOff,
  Blocker.androidUnauthorized => l.fdBlockerAndroidUnauthorized,
  Blocker.needsTeamId => l.fdBlockerNeedsTeamId,
};

String? blockerSteps(AppLocalizations l, Blocker b) => switch (b) {
  Blocker.wireless => l.fdStepsWireless,
  Blocker.developerModeOff => l.fdStepsDeveloperMode,
  Blocker.androidUnauthorized => l.fdStepsAndroidAuth,
  Blocker.needsTeamId => l.fdStepsTeamId,
  _ => null,
};

String failureHintText(AppLocalizations l, FailureHint h) => switch (h) {
  FailureHint.useUsb => l.fdHintUseUsb,
  FailureHint.unlockDevice => l.fdHintUnlockDevice,
  FailureHint.developerMode => l.fdHintDeveloperMode,
  FailureHint.signing => l.fdHintSigning,
  FailureHint.trustComputer => l.fdHintTrustComputer,
  FailureHint.noAdb => l.fdHintNoAdb,
  FailureHint.cocoapods => l.fdHintCocoapods,
  FailureHint.visualStudio => l.fdHintVisualStudio,
  FailureHint.restartApp => l.fdHintRestartApp,
  FailureHint.staleBuildCache => l.fdHintStaleBuildCache,
};

String? failureHintSteps(AppLocalizations l, FailureHint h) => switch (h) {
  FailureHint.useUsb || FailureHint.trustComputer => l.fdStepsWireless,
  FailureHint.developerMode => l.fdStepsDeveloperMode,
  FailureHint.signing => l.fdStepsTeamId,
  FailureHint.noAdb => l.fdStepsAdbMissing,
  FailureHint.cocoapods => l.fdStepsCocoapods,
  FailureHint.visualStudio => l.fdStepsVisualStudio,
  FailureHint.staleBuildCache => l.fdStepsStaleBuildCache,
  _ => null,
};
