import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @aboutTooltip.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get aboutTooltip;

  /// No description provided for @aboutVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version} (빌드 {build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @aboutOpenSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get aboutOpenSourceLicenses;

  /// No description provided for @aboutRepository.
  ///
  /// In ko, this message translates to:
  /// **'GitHub'**
  String get aboutRepository;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @aboutMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 정보'**
  String aboutMenuItem(String appName);

  /// No description provided for @themeMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get themeMenuTooltip;

  /// No description provided for @themeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get themeDark;

  /// No description provided for @languageMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get languageMenuTooltip;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 설정 따르기 / System'**
  String get languageSystem;

  /// No description provided for @languageSystemShort.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystemShort;

  /// No description provided for @settingsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In ko, this message translates to:
  /// **'외형'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsMode.
  ///
  /// In ko, this message translates to:
  /// **'모드'**
  String get settingsMode;

  /// No description provided for @settingsModeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get settingsModeSystem;

  /// No description provided for @settingsPalette.
  ///
  /// In ko, this message translates to:
  /// **'색 구성'**
  String get settingsPalette;

  /// No description provided for @settingsPaletteSaturn.
  ///
  /// In ko, this message translates to:
  /// **'새턴'**
  String get settingsPaletteSaturn;

  /// No description provided for @settingsPaletteTeal.
  ///
  /// In ko, this message translates to:
  /// **'청록'**
  String get settingsPaletteTeal;

  /// No description provided for @settingsPaletteAmber.
  ///
  /// In ko, this message translates to:
  /// **'호박'**
  String get settingsPaletteAmber;

  /// No description provided for @settingsPaletteRose.
  ///
  /// In ko, this message translates to:
  /// **'장미'**
  String get settingsPaletteRose;

  /// No description provided for @settingsPaletteSlate.
  ///
  /// In ko, this message translates to:
  /// **'슬레이트'**
  String get settingsPaletteSlate;

  /// No description provided for @settingsPaletteHighContrast.
  ///
  /// In ko, this message translates to:
  /// **'고대비'**
  String get settingsPaletteHighContrast;

  /// No description provided for @aboutTagline.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 앱을 GitHub에서 만들고 굴리는 작업대'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'편집기 옆에 세워 두는 도킹형 작업대입니다. 같은 폴더를 보며 Git·GitHub(Git & GitHub)와 Flutter 앱의 실기기 빌드·설치(Flutter Runner)를 한 창에서 다룹니다.'**
  String get aboutDescription;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장소 폴더를 끌어다 놓아 시작하세요'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'폴더 열기'**
  String get homeEmptyAction;

  /// No description provided for @updateCheckMenuItem.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 확인'**
  String get updateCheckMenuItem;

  /// No description provided for @updateChecking.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하는 중…'**
  String get updateChecking;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 버전이 있습니다'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In ko, this message translates to:
  /// **'{appName} {latest} 버전이 나왔습니다. (현재 {current})'**
  String updateAvailableBody(String appName, String current, String latest);

  /// No description provided for @updateReleaseNotes.
  ///
  /// In ko, this message translates to:
  /// **'변경 내용'**
  String get updateReleaseNotes;

  /// No description provided for @updateNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 업데이트'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get updateLater;

  /// No description provided for @updateSkipVersion.
  ///
  /// In ko, this message translates to:
  /// **'이 버전 건너뛰기'**
  String get updateSkipVersion;

  /// No description provided for @updateDownloading.
  ///
  /// In ko, this message translates to:
  /// **'내려받는 중…'**
  String get updateDownloading;

  /// No description provided for @updateVerifying.
  ///
  /// In ko, this message translates to:
  /// **'파일을 확인하는 중…'**
  String get updateVerifying;

  /// No description provided for @updateDownloadProgress.
  ///
  /// In ko, this message translates to:
  /// **'{received} / {total}'**
  String updateDownloadProgress(String received, String total);

  /// No description provided for @updateCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get updateCancel;

  /// No description provided for @updateFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트하지 못했습니다'**
  String get updateFailedTitle;

  /// No description provided for @updateCheckFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트를 확인하지 못했습니다'**
  String get updateCheckFailedTitle;

  /// No description provided for @updateErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.'**
  String get updateErrorNetwork;

  /// No description provided for @updateErrorChecksum.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 파일이 올바르지 않아 설치하지 않았습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get updateErrorChecksum;

  /// No description provided for @updateErrorInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치를 시작하지 못했습니다.'**
  String get updateErrorInstall;

  /// No description provided for @updateErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 서버에서 예상하지 못한 응답을 받았습니다. 잠시 뒤에 다시 시도해 주세요.'**
  String get updateErrorGeneric;

  /// No description provided for @updateUpToDateTitle.
  ///
  /// In ko, this message translates to:
  /// **'최신 버전입니다'**
  String get updateUpToDateTitle;

  /// No description provided for @updateUpToDateBody.
  ///
  /// In ko, this message translates to:
  /// **'{version} 버전을 사용 중입니다.'**
  String updateUpToDateBody(String version);

  /// No description provided for @updateUnavailableTitle.
  ///
  /// In ko, this message translates to:
  /// **'직접 설치해 주세요'**
  String get updateUnavailableTitle;

  /// No description provided for @updateUnavailableBody.
  ///
  /// In ko, this message translates to:
  /// **'{latest} 버전이 있지만 앱에서 자동으로 설치할 수 없습니다. 릴리스 페이지에서 받아 주세요.'**
  String updateUnavailableBody(String latest);

  /// No description provided for @updateOpenReleasePage.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 페이지 열기'**
  String get updateOpenReleasePage;

  /// No description provided for @updateBrowserDownloadTitle.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 내려받습니다'**
  String get updateBrowserDownloadTitle;

  /// No description provided for @updateBrowserDownloadBody.
  ///
  /// In ko, this message translates to:
  /// **'브라우저가 새 버전 내려받기를 시작합니다. 받은 DMG를 열어 {appName} 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.'**
  String updateBrowserDownloadBody(String appName);

  /// No description provided for @updateMacosOpenedTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치 창이 열렸습니다'**
  String get updateMacosOpenedTitle;

  /// No description provided for @updateMacosOpenedBody.
  ///
  /// In ko, this message translates to:
  /// **'열린 창에서 {appName} 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.'**
  String updateMacosOpenedBody(String appName);

  /// No description provided for @updateWindowsInstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치 프로그램을 열었습니다'**
  String get updateWindowsInstallTitle;

  /// No description provided for @updateWindowsInstallBody.
  ///
  /// In ko, this message translates to:
  /// **'설치하려면 {appName} 을(를) 종료해야 합니다. 설치 프로그램의 안내를 따라 주세요.'**
  String updateWindowsInstallBody(String appName);

  /// No description provided for @updateQuitApp.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 종료'**
  String updateQuitApp(String appName);

  /// No description provided for @updateLinuxInstallTitle.
  ///
  /// In ko, this message translates to:
  /// **'설치를 준비했습니다'**
  String get updateLinuxInstallTitle;

  /// No description provided for @updateLinuxInstallBody.
  ///
  /// In ko, this message translates to:
  /// **'{appName} 을(를) 종료하고 설치합니다. 설치가 끝나면 자동으로 다시 시작됩니다.'**
  String updateLinuxInstallBody(String appName);

  /// No description provided for @updateQuitAndInstall.
  ///
  /// In ko, this message translates to:
  /// **'종료하고 설치'**
  String get updateQuitAndInstall;

  /// No description provided for @updateBusyTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금은 업데이트할 수 없습니다'**
  String get updateBusyTitle;

  /// No description provided for @updateBusyBody.
  ///
  /// In ko, this message translates to:
  /// **'작업이 진행 중입니다. 끝난 뒤에 다시 시도해 주세요.'**
  String get updateBusyBody;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 확인'**
  String get commonRetry;

  /// No description provided for @startTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장소를 열어 시작하세요'**
  String get startTitle;

  /// No description provided for @startDropHint.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 끌어다 놓아도 됩니다. 저장소가 아닌 폴더는 git init을 권해 드려요.'**
  String get startDropHint;

  /// No description provided for @startRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 저장소'**
  String get startRecent;

  /// No description provided for @startRemoveRecent.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 지우기'**
  String get startRemoveRecent;

  /// No description provided for @startNotARepository.
  ///
  /// In ko, this message translates to:
  /// **'\"{path}\"는 git 저장소가 아닙니다.'**
  String startNotARepository(String path);

  /// No description provided for @startNotFound.
  ///
  /// In ko, this message translates to:
  /// **'\"{path}\" 폴더를 찾을 수 없습니다.'**
  String startNotFound(String path);

  /// No description provided for @startInitRepository.
  ///
  /// In ko, this message translates to:
  /// **'git init으로 저장소 만들기'**
  String get startInitRepository;

  /// No description provided for @startOpening.
  ///
  /// In ko, this message translates to:
  /// **'저장소를 여는 중…'**
  String get startOpening;

  /// No description provided for @dropOverlayTitle.
  ///
  /// In ko, this message translates to:
  /// **'여기에 놓아 저장소 열기'**
  String get dropOverlayTitle;

  /// No description provided for @dropMultiple.
  ///
  /// In ko, this message translates to:
  /// **'폴더 여러 개 중 첫 번째만 열었습니다'**
  String get dropMultiple;

  /// No description provided for @dropFilesOnly.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 놓아 주세요'**
  String get dropFilesOnly;

  /// No description provided for @dropNotRepoTitle.
  ///
  /// In ko, this message translates to:
  /// **'git 저장소가 아닙니다'**
  String get dropNotRepoTitle;

  /// No description provided for @dropNotRepoBody.
  ///
  /// In ko, this message translates to:
  /// **'\"{path}\"를 git 저장소로 만들까요? (git init)'**
  String dropNotRepoBody(String path);

  /// No description provided for @dropBusyTitle.
  ///
  /// In ko, this message translates to:
  /// **'실행 중인 작업이 있습니다'**
  String get dropBusyTitle;

  /// No description provided for @dropBusyBody.
  ///
  /// In ko, this message translates to:
  /// **'다른 저장소를 열면 실행 중인 작업이 중지됩니다.'**
  String get dropBusyBody;

  /// No description provided for @dropStopAndOpen.
  ///
  /// In ko, this message translates to:
  /// **'중지하고 열기'**
  String get dropStopAndOpen;

  /// No description provided for @dropSelectedDir.
  ///
  /// In ko, this message translates to:
  /// **'선택한 폴더를 \"{name}\"(으)로 바꿨습니다'**
  String dropSelectedDir(String name);

  /// No description provided for @workspaceOpenFolder.
  ///
  /// In ko, this message translates to:
  /// **'다른 폴더 열기…'**
  String get workspaceOpenFolder;

  /// No description provided for @workspaceCloseRepo.
  ///
  /// In ko, this message translates to:
  /// **'저장소 닫기'**
  String get workspaceCloseRepo;

  /// No description provided for @workspaceRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 저장소'**
  String get workspaceRecent;

  /// No description provided for @refreshTooltip.
  ///
  /// In ko, this message translates to:
  /// **'새로 고침'**
  String get refreshTooltip;

  /// No description provided for @alwaysOnTopTooltip.
  ///
  /// In ko, this message translates to:
  /// **'항상 위에 표시'**
  String get alwaysOnTopTooltip;

  /// No description provided for @branchChipTooltip.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 {branch}'**
  String branchChipTooltip(String branch);

  /// No description provided for @branchDetached.
  ///
  /// In ko, this message translates to:
  /// **'분리된 HEAD'**
  String get branchDetached;

  /// No description provided for @branchNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'원격에 없음'**
  String get branchNoUpstream;

  /// No description provided for @stateMerging.
  ///
  /// In ko, this message translates to:
  /// **'병합 중 · 충돌 {count}'**
  String stateMerging(int count);

  /// No description provided for @stateRebasing.
  ///
  /// In ko, this message translates to:
  /// **'rebase 중 · 충돌 {count}'**
  String stateRebasing(int count);

  /// No description provided for @stateOperation.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 작업'**
  String get stateOperation;

  /// No description provided for @stateChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 {count}'**
  String stateChanges(int count);

  /// No description provided for @stateUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'최신'**
  String get stateUpToDate;

  /// No description provided for @editorOpenTooltip.
  ///
  /// In ko, this message translates to:
  /// **'편집기에서 열기 ({command})'**
  String editorOpenTooltip(String command);

  /// No description provided for @editorOpenNoEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집기를 찾지 못했습니다. VS Code를 설치하면 이 단추로 폴더를 열 수 있어요.'**
  String get editorOpenNoEditor;

  /// No description provided for @editorOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'편집기를 열지 못했습니다'**
  String get editorOpenFailed;

  /// No description provided for @dockBranchTitle.
  ///
  /// In ko, this message translates to:
  /// **'Git & GitHub'**
  String get dockBranchTitle;

  /// No description provided for @dockFluttyTitle.
  ///
  /// In ko, this message translates to:
  /// **'Flutter Runner'**
  String get dockFluttyTitle;

  /// No description provided for @dockRunTitle.
  ///
  /// In ko, this message translates to:
  /// **'Run'**
  String get dockRunTitle;

  /// No description provided for @dockPlaceholderBranch.
  ///
  /// In ko, this message translates to:
  /// **'Git·GitHub 도구가 이 칸에 들어옵니다 (단계 3).'**
  String get dockPlaceholderBranch;

  /// No description provided for @dockPlaceholderFlutty.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 실기기 빌드·설치가 이 칸에 들어옵니다 (단계 4).'**
  String get dockPlaceholderFlutty;

  /// No description provided for @dockNoProject.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 프로젝트 없음'**
  String get dockNoProject;

  /// No description provided for @dockNoProjectBody.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더와 한 단계 아래 폴더에서 Flutter 프로젝트를 찾지 못했습니다. 폴더를 바꾸거나 프로젝트가 있는 폴더를 선택하세요.'**
  String get dockNoProjectBody;

  /// No description provided for @dockProjects.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 {count}개'**
  String dockProjects(int count);

  /// No description provided for @dockLastChange.
  ///
  /// In ko, this message translates to:
  /// **'마지막 변화: {text}'**
  String dockLastChange(String text);

  /// No description provided for @dockChangeBranch.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 {from} → {to}'**
  String dockChangeBranch(String from, String to);

  /// No description provided for @dockChangeCommit.
  ///
  /// In ko, this message translates to:
  /// **'커밋 이동'**
  String get dockChangeCommit;

  /// No description provided for @dockChangeOperation.
  ///
  /// In ko, this message translates to:
  /// **'병합/rebase 상태 변화'**
  String get dockChangeOperation;

  /// No description provided for @dockNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get dockNone;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsFontSize.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기'**
  String get settingsFontSize;

  /// No description provided for @fontScaleSmall.
  ///
  /// In ko, this message translates to:
  /// **'작게'**
  String get fontScaleSmall;

  /// No description provided for @fontScaleNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get fontScaleNormal;

  /// No description provided for @fontScaleLarge.
  ///
  /// In ko, this message translates to:
  /// **'크게'**
  String get fontScaleLarge;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsStateTint.
  ///
  /// In ko, this message translates to:
  /// **'상태색 배경'**
  String get settingsStateTint;

  /// No description provided for @settingsStateTintHelp.
  ///
  /// In ko, this message translates to:
  /// **'빌드 중·실패·성공에 따라 배경 색이 은은하게 바뀝니다.'**
  String get settingsStateTintHelp;

  /// No description provided for @summaryPush.
  ///
  /// In ko, this message translates to:
  /// **'Push ↑{count} 가능'**
  String summaryPush(int count);

  /// No description provided for @summaryPull.
  ///
  /// In ko, this message translates to:
  /// **'Pull ↓{count} 필요'**
  String summaryPull(int count);

  /// No description provided for @settingsSectionTools.
  ///
  /// In ko, this message translates to:
  /// **'도구'**
  String get settingsSectionTools;

  /// No description provided for @toolsIntro.
  ///
  /// In ko, this message translates to:
  /// **'앱이 실행하는 외부 도구의 위치입니다. 비워 두면 PATH에서 찾습니다. 직접 지정하면 그 파일을 씁니다.'**
  String get toolsIntro;

  /// No description provided for @toolsFound.
  ///
  /// In ko, this message translates to:
  /// **'찾음: {path}'**
  String toolsFound(String path);

  /// No description provided for @toolsNotFound.
  ///
  /// In ko, this message translates to:
  /// **'찾지 못했습니다'**
  String get toolsNotFound;

  /// No description provided for @toolsCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 지정'**
  String get toolsCustom;

  /// No description provided for @toolsBrowse.
  ///
  /// In ko, this message translates to:
  /// **'찾아보기…'**
  String get toolsBrowse;

  /// No description provided for @toolsClear.
  ///
  /// In ko, this message translates to:
  /// **'지정 지우기'**
  String get toolsClear;

  /// No description provided for @toolsPathHint.
  ///
  /// In ko, this message translates to:
  /// **'실행 파일 경로'**
  String get toolsPathHint;

  /// No description provided for @bdAboutTagline.
  ///
  /// In ko, this message translates to:
  /// **'Git과 GitHub CLI를 위한 데스크톱 도우미'**
  String get bdAboutTagline;

  /// No description provided for @bdAboutDescription.
  ///
  /// In ko, this message translates to:
  /// **'편집기 옆에 세워 두고 브랜치, 태그, 병합, Pull/Push, 원격, 릴리스를 버튼으로 다룹니다. 버튼마다 실제로 실행되는 git·gh 명령을 보여 줍니다.'**
  String get bdAboutDescription;

  /// No description provided for @bdHomeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'시작하려면 저장소를 선택하세요'**
  String get bdHomeEmptyTitle;

  /// No description provided for @bdHomeEmptyAction.
  ///
  /// In ko, this message translates to:
  /// **'저장소 열기'**
  String get bdHomeEmptyAction;

  /// No description provided for @bdAppBarRefresh.
  ///
  /// In ko, this message translates to:
  /// **'새로 고침'**
  String get bdAppBarRefresh;

  /// No description provided for @bdAppBarPin.
  ///
  /// In ko, this message translates to:
  /// **'항상 위에 표시'**
  String get bdAppBarPin;

  /// No description provided for @bdAppBarUnpin.
  ///
  /// In ko, this message translates to:
  /// **'항상 위에 표시 끄기'**
  String get bdAppBarUnpin;

  /// No description provided for @bdMenuOpenFolder.
  ///
  /// In ko, this message translates to:
  /// **'다른 폴더 열기…'**
  String get bdMenuOpenFolder;

  /// No description provided for @bdMenuEditor.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열 편집기…'**
  String get bdMenuEditor;

  /// No description provided for @bdMenuEnvironment.
  ///
  /// In ko, this message translates to:
  /// **'환경 점검'**
  String get bdMenuEnvironment;

  /// No description provided for @bdMenuCloseRepo.
  ///
  /// In ko, this message translates to:
  /// **'저장소 닫기'**
  String get bdMenuCloseRepo;

  /// No description provided for @bdHostOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 git 서버'**
  String get bdHostOther;

  /// No description provided for @bdCommonCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get bdCommonCopy;

  /// No description provided for @bdCommonCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했습니다'**
  String get bdCommonCopied;

  /// No description provided for @bdCommonMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get bdCommonMore;

  /// No description provided for @bdCommonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get bdCommonSave;

  /// No description provided for @bdCommandPreviewLabel.
  ///
  /// In ko, this message translates to:
  /// **'실행될 명령'**
  String get bdCommandPreviewLabel;

  /// No description provided for @bdStartDropHint.
  ///
  /// In ko, this message translates to:
  /// **'git 저장소 폴더를 창에 끌어다 놓아도 됩니다.'**
  String get bdStartDropHint;

  /// No description provided for @bdStartRemoveRecent.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 빼기'**
  String get bdStartRemoveRecent;

  /// No description provided for @bdStartNotARepository.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더는 git 저장소가 아닙니다: {path}'**
  String bdStartNotARepository(String path);

  /// No description provided for @bdStartNotFound.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 찾을 수 없습니다: {path}'**
  String bdStartNotFound(String path);

  /// No description provided for @bdEnvTitle.
  ///
  /// In ko, this message translates to:
  /// **'환경 점검'**
  String get bdEnvTitle;

  /// No description provided for @bdEnvGitRequired.
  ///
  /// In ko, this message translates to:
  /// **'Daylight Taskbench는 설치된 git을 실행합니다. git을 먼저 설치하세요.'**
  String get bdEnvGitRequired;

  /// No description provided for @bdEnvGitOnlyNote.
  ///
  /// In ko, this message translates to:
  /// **'gh가 없거나 로그인하지 않아도 브랜치·태그·Pull·Push는 쓸 수 있습니다. GitHub에 올리기, PR, 릴리스에는 gh 로그인이 필요합니다.'**
  String get bdEnvGitOnlyNote;

  /// No description provided for @bdEnvVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String bdEnvVersion(String version);

  /// No description provided for @bdEnvNotInstalled.
  ///
  /// In ko, this message translates to:
  /// **'설치되지 않았거나 찾을 수 없습니다'**
  String get bdEnvNotInstalled;

  /// No description provided for @bdEnvLogin.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 로그인'**
  String get bdEnvLogin;

  /// No description provided for @bdEnvLoggedInAs.
  ///
  /// In ko, this message translates to:
  /// **'{login} 계정으로 로그인됨'**
  String bdEnvLoggedInAs(String login);

  /// No description provided for @bdEnvNotLoggedIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인하지 않았습니다. 터미널에서 아래 명령을 실행하세요.'**
  String get bdEnvNotLoggedIn;

  /// No description provided for @bdEnvRecheck.
  ///
  /// In ko, this message translates to:
  /// **'다시 확인'**
  String get bdEnvRecheck;

  /// No description provided for @bdEnvGhMissing.
  ///
  /// In ko, this message translates to:
  /// **'GitHub CLI(gh)가 설치되지 않아 쓸 수 없습니다. 메뉴의 환경 점검을 확인하세요.'**
  String get bdEnvGhMissing;

  /// No description provided for @bdEnvGhLoggedOut.
  ///
  /// In ko, this message translates to:
  /// **'gh에 로그인해야 쓸 수 있습니다. 터미널에서 gh auth login을 실행하세요.'**
  String get bdEnvGhLoggedOut;

  /// No description provided for @bdHeaderOpenFolder.
  ///
  /// In ko, this message translates to:
  /// **'편집기에서 이 폴더 열기'**
  String get bdHeaderOpenFolder;

  /// No description provided for @bdVscodeMissingTitle.
  ///
  /// In ko, this message translates to:
  /// **'VS Code를 찾지 못했습니다'**
  String get bdVscodeMissingTitle;

  /// No description provided for @bdVscodeMissingMessage.
  ///
  /// In ko, this message translates to:
  /// **'VS Code를 설치하면 이 버튼으로 현재 브랜치가 체크아웃된 폴더를 바로 열 수 있습니다. 다른 편집기를 쓰려면 저장소 메뉴의 ‘파일을 열 편집기…’에 명령(cursor, zed 등)을 적으세요.'**
  String get bdVscodeMissingMessage;

  /// No description provided for @bdVscodeDownload.
  ///
  /// In ko, this message translates to:
  /// **'VS Code 받기'**
  String get bdVscodeDownload;

  /// No description provided for @bdHeaderBranchTooltip.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 목록 보기'**
  String get bdHeaderBranchTooltip;

  /// No description provided for @bdHeaderDetached.
  ///
  /// In ko, this message translates to:
  /// **'분리된 HEAD'**
  String get bdHeaderDetached;

  /// No description provided for @bdHeaderNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'원격에 없음'**
  String get bdHeaderNoUpstream;

  /// No description provided for @bdHeaderNoUpstreamTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 아직 원격에 올라가지 않았습니다. 게시(Publish)하면 올라갑니다.'**
  String get bdHeaderNoUpstreamTooltip;

  /// No description provided for @bdHeaderAheadTooltip.
  ///
  /// In ko, this message translates to:
  /// **'원격에 아직 없는 내 커밋 {count}개'**
  String bdHeaderAheadTooltip(int count);

  /// No description provided for @bdHeaderBehindTooltip.
  ///
  /// In ko, this message translates to:
  /// **'내 컴퓨터에 아직 없는 원격 커밋 {count}개'**
  String bdHeaderBehindTooltip(int count);

  /// No description provided for @bdHeaderChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 {count}'**
  String bdHeaderChanges(int count);

  /// No description provided for @bdHeaderUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'최신'**
  String get bdHeaderUpToDate;

  /// No description provided for @bdHeaderNoCommits.
  ///
  /// In ko, this message translates to:
  /// **'아직 커밋 없음'**
  String get bdHeaderNoCommits;

  /// No description provided for @bdHeaderMerging.
  ///
  /// In ko, this message translates to:
  /// **'병합 중 · 충돌 {count}'**
  String bdHeaderMerging(int count);

  /// No description provided for @bdHeaderRebasing.
  ///
  /// In ko, this message translates to:
  /// **'rebase 중 · 충돌 {count}'**
  String bdHeaderRebasing(int count);

  /// No description provided for @bdHeaderFetch.
  ///
  /// In ko, this message translates to:
  /// **'Fetch'**
  String get bdHeaderFetch;

  /// No description provided for @bdHeaderPull.
  ///
  /// In ko, this message translates to:
  /// **'Pull'**
  String get bdHeaderPull;

  /// No description provided for @bdHeaderPush.
  ///
  /// In ko, this message translates to:
  /// **'Push'**
  String get bdHeaderPush;

  /// No description provided for @bdHeaderPublish.
  ///
  /// In ko, this message translates to:
  /// **'게시'**
  String get bdHeaderPublish;

  /// No description provided for @bdPullModeTooltip.
  ///
  /// In ko, this message translates to:
  /// **'Pull 방식'**
  String get bdPullModeTooltip;

  /// No description provided for @bdPullModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'Pull 방식'**
  String get bdPullModeTitle;

  /// No description provided for @bdPullModeMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합 (기본)'**
  String get bdPullModeMerge;

  /// No description provided for @bdPullModeMergeWhen.
  ///
  /// In ko, this message translates to:
  /// **'양쪽에 새 커밋이 있으면 병합 커밋으로 합칩니다. 가장 안전합니다.'**
  String get bdPullModeMergeWhen;

  /// No description provided for @bdPullModeRebase.
  ///
  /// In ko, this message translates to:
  /// **'Rebase'**
  String get bdPullModeRebase;

  /// No description provided for @bdPullModeRebaseWhen.
  ///
  /// In ko, this message translates to:
  /// **'내 커밋을 받아온 커밋 뒤로 옮겨 기록을 한 줄로 유지합니다.'**
  String get bdPullModeRebaseWhen;

  /// No description provided for @bdPullModeFastForward.
  ///
  /// In ko, this message translates to:
  /// **'Fast-forward만'**
  String get bdPullModeFastForward;

  /// No description provided for @bdPullModeFastForwardWhen.
  ///
  /// In ko, this message translates to:
  /// **'내 커밋이 없을 때만 받아옵니다. 갈라졌으면 멈추고 알려 줍니다.'**
  String get bdPullModeFastForwardWhen;

  /// No description provided for @bdOperationAbort.
  ///
  /// In ko, this message translates to:
  /// **'중단'**
  String get bdOperationAbort;

  /// No description provided for @bdOperationContinue.
  ///
  /// In ko, this message translates to:
  /// **'계속'**
  String get bdOperationContinue;

  /// No description provided for @bdOperationContinueBlocked.
  ///
  /// In ko, this message translates to:
  /// **'충돌을 모두 해결해야 계속할 수 있습니다'**
  String get bdOperationContinueBlocked;

  /// No description provided for @bdOperationAbortTitle.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 작업을 중단할까요?'**
  String get bdOperationAbortTitle;

  /// No description provided for @bdOperationAbortMergeMessage.
  ///
  /// In ko, this message translates to:
  /// **'병합을 시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.'**
  String get bdOperationAbortMergeMessage;

  /// No description provided for @bdOperationAbortRebaseMessage.
  ///
  /// In ko, this message translates to:
  /// **'rebase를 시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.'**
  String get bdOperationAbortRebaseMessage;

  /// No description provided for @bdBannerConflicts.
  ///
  /// In ko, this message translates to:
  /// **'충돌 파일 {count}개를 해결해야 합니다'**
  String bdBannerConflicts(int count);

  /// No description provided for @bdBannerPull.
  ///
  /// In ko, this message translates to:
  /// **'원격에 새 커밋 {count}개가 있습니다'**
  String bdBannerPull(int count);

  /// No description provided for @bdBannerPublish.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 아직 원격에 없습니다'**
  String get bdBannerPublish;

  /// No description provided for @bdBannerPush.
  ///
  /// In ko, this message translates to:
  /// **'커밋 {count}개가 아직 원격에 없습니다'**
  String bdBannerPush(int count);

  /// No description provided for @bdBannerNoRemote.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소는 아직 GitHub에 없습니다'**
  String get bdBannerNoRemote;

  /// No description provided for @bdBannerShow.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get bdBannerShow;

  /// No description provided for @bdBannerNotGitHub.
  ///
  /// In ko, this message translates to:
  /// **'{host} 저장소입니다. 브랜치·Pull·Push는 모두 쓸 수 있고, PR·릴리스·Actions는 GitHub 저장소에서만 쓸 수 있습니다.'**
  String bdBannerNotGitHub(String host);

  /// No description provided for @bdTabChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get bdTabChanges;

  /// No description provided for @bdTabBranches.
  ///
  /// In ko, this message translates to:
  /// **'브랜치'**
  String get bdTabBranches;

  /// No description provided for @bdTabRemotes.
  ///
  /// In ko, this message translates to:
  /// **'원격'**
  String get bdTabRemotes;

  /// No description provided for @bdChangesMessageHint.
  ///
  /// In ko, this message translates to:
  /// **'커밋 메시지'**
  String get bdChangesMessageHint;

  /// No description provided for @bdChangesPrefixTooltip.
  ///
  /// In ko, this message translates to:
  /// **'커밋 종류 접두어'**
  String get bdChangesPrefixTooltip;

  /// No description provided for @bdChangesFirstLineLong.
  ///
  /// In ko, this message translates to:
  /// **'첫 줄이 {length}자입니다. 72자 안으로 줄이면 목록에서 잘리지 않습니다.'**
  String bdChangesFirstLineLong(int length);

  /// No description provided for @bdChangesCommitStaged.
  ///
  /// In ko, this message translates to:
  /// **'커밋 (스테이징 {count})'**
  String bdChangesCommitStaged(int count);

  /// No description provided for @bdChangesCommitAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 스테이징하고 커밋'**
  String get bdChangesCommitAll;

  /// No description provided for @bdChangesConflicts.
  ///
  /// In ko, this message translates to:
  /// **'충돌'**
  String get bdChangesConflicts;

  /// No description provided for @bdChangesStaged.
  ///
  /// In ko, this message translates to:
  /// **'스테이징됨'**
  String get bdChangesStaged;

  /// No description provided for @bdChangesUnstaged.
  ///
  /// In ko, this message translates to:
  /// **'변경됨'**
  String get bdChangesUnstaged;

  /// No description provided for @bdChangesUntracked.
  ///
  /// In ko, this message translates to:
  /// **'추적 안 됨'**
  String get bdChangesUntracked;

  /// No description provided for @bdChangesStageAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 스테이징'**
  String get bdChangesStageAll;

  /// No description provided for @bdChangesUnstageAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 해제'**
  String get bdChangesUnstageAll;

  /// No description provided for @bdChangesStage.
  ///
  /// In ko, this message translates to:
  /// **'스테이징'**
  String get bdChangesStage;

  /// No description provided for @bdChangesUnstage.
  ///
  /// In ko, this message translates to:
  /// **'스테이징 해제'**
  String get bdChangesUnstage;

  /// No description provided for @bdChangesOpenInEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집기로 열기'**
  String get bdChangesOpenInEditor;

  /// No description provided for @bdChangesMarkResolved.
  ///
  /// In ko, this message translates to:
  /// **'해결됨 표시'**
  String get bdChangesMarkResolved;

  /// No description provided for @bdChangesCleanTitle.
  ///
  /// In ko, this message translates to:
  /// **'커밋할 변경이 없습니다'**
  String get bdChangesCleanTitle;

  /// No description provided for @bdChangesCleanMessage.
  ///
  /// In ko, this message translates to:
  /// **'편집기에서 파일을 저장하면 여기에 바로 나타납니다.'**
  String get bdChangesCleanMessage;

  /// No description provided for @bdBranchesTitle.
  ///
  /// In ko, this message translates to:
  /// **'브랜치'**
  String get bdBranchesTitle;

  /// No description provided for @bdBranchesNew.
  ///
  /// In ko, this message translates to:
  /// **'새 브랜치'**
  String get bdBranchesNew;

  /// No description provided for @bdBranchesCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get bdBranchesCreate;

  /// No description provided for @bdBranchesSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 찾기'**
  String get bdBranchesSearchHint;

  /// No description provided for @bdBranchesLocal.
  ///
  /// In ko, this message translates to:
  /// **'로컬'**
  String get bdBranchesLocal;

  /// No description provided for @bdBranchesRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격'**
  String get bdBranchesRemote;

  /// No description provided for @bdBranchesSwitch.
  ///
  /// In ko, this message translates to:
  /// **'전환'**
  String get bdBranchesSwitch;

  /// No description provided for @bdBranchesRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get bdBranchesRename;

  /// No description provided for @bdBranchesDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get bdBranchesDelete;

  /// No description provided for @bdBranchesDeleteRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 삭제'**
  String get bdBranchesDeleteRemote;

  /// No description provided for @bdBranchesUpstreamGone.
  ///
  /// In ko, this message translates to:
  /// **'원격 삭제됨'**
  String get bdBranchesUpstreamGone;

  /// No description provided for @bdBranchesUnbornTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 커밋이 없습니다'**
  String get bdBranchesUnbornTitle;

  /// No description provided for @bdBranchesUnbornMessage.
  ///
  /// In ko, this message translates to:
  /// **'첫 커밋을 만들면 브랜치를 만들 수 있습니다.'**
  String get bdBranchesUnbornMessage;

  /// No description provided for @bdBranchesForceDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'병합되지 않은 브랜치입니다'**
  String get bdBranchesForceDeleteTitle;

  /// No description provided for @bdBranchesForceDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{name}에는 다른 브랜치에 병합되지 않은 커밋이 있습니다. 삭제하면 그 커밋을 찾기 어려워집니다.'**
  String bdBranchesForceDeleteMessage(String name);

  /// No description provided for @bdBranchesDeleteRemoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격 브랜치를 삭제할까요?'**
  String get bdBranchesDeleteRemoteTitle;

  /// No description provided for @bdBranchesDeleteRemoteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{target}에서 {branch} 브랜치를 삭제합니다. 다른 사람도 더 이상 이 브랜치를 받을 수 없습니다.'**
  String bdBranchesDeleteRemoteMessage(String branch, String target);

  /// No description provided for @bdBranchNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 이름'**
  String get bdBranchNameLabel;

  /// No description provided for @bdBranchNameExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 브랜치가 이미 있습니다'**
  String get bdBranchNameExists;

  /// No description provided for @bdBranchNameEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력하세요'**
  String get bdBranchNameEmpty;

  /// No description provided for @bdBranchNameInvalidCharacter.
  ///
  /// In ko, this message translates to:
  /// **'공백과 ~ ^ : ? * [ \\ 는 쓸 수 없습니다'**
  String get bdBranchNameInvalidCharacter;

  /// No description provided for @bdBranchNameStartsWithDash.
  ///
  /// In ko, this message translates to:
  /// **'-로 시작할 수 없습니다'**
  String get bdBranchNameStartsWithDash;

  /// No description provided for @bdBranchNameInvalidSequence.
  ///
  /// In ko, this message translates to:
  /// **'.. 이나 //, .으로 시작하는 부분, .lock으로 끝나는 부분은 쓸 수 없습니다'**
  String get bdBranchNameInvalidSequence;

  /// No description provided for @bdBranchNameInvalidEdge.
  ///
  /// In ko, this message translates to:
  /// **'/ 로 시작하거나 / 또는 . 으로 끝날 수 없습니다'**
  String get bdBranchNameInvalidEdge;

  /// No description provided for @bdBranchBaseLabel.
  ///
  /// In ko, this message translates to:
  /// **'어디서 시작할까요'**
  String get bdBranchBaseLabel;

  /// No description provided for @bdBranchBaseCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 브랜치 ({name})'**
  String bdBranchBaseCurrent(String name);

  /// No description provided for @bdBranchSwitchAfter.
  ///
  /// In ko, this message translates to:
  /// **'만든 뒤 바로 전환'**
  String get bdBranchSwitchAfter;

  /// No description provided for @bdBranchRenameUpstreamNote.
  ///
  /// In ko, this message translates to:
  /// **'원격의 {upstream}은 그대로 남습니다. 새 이름으로 다시 게시하세요.'**
  String bdBranchRenameUpstreamNote(String upstream);

  /// No description provided for @bdRemotesTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격'**
  String get bdRemotesTitle;

  /// No description provided for @bdRemotesAdd.
  ///
  /// In ko, this message translates to:
  /// **'원격 추가'**
  String get bdRemotesAdd;

  /// No description provided for @bdRemotesRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 바꾸기'**
  String get bdRemotesRename;

  /// No description provided for @bdRemotesSetUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL 바꾸기'**
  String get bdRemotesSetUrl;

  /// No description provided for @bdRemotesRemove.
  ///
  /// In ko, this message translates to:
  /// **'원격 삭제'**
  String get bdRemotesRemove;

  /// No description provided for @bdRemotesRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격을 삭제할까요?'**
  String get bdRemotesRemoveTitle;

  /// No description provided for @bdRemotesRemoveMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소에서 {name} 연결만 지웁니다. 서버의 저장소는 그대로 남습니다.'**
  String bdRemotesRemoveMessage(String name);

  /// No description provided for @bdRemotesEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소는 아직 GitHub에 없습니다'**
  String get bdRemotesEmptyTitle;

  /// No description provided for @bdRemotesEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 새 저장소를 만들고 지금 브랜치를 올립니다.'**
  String get bdRemotesEmptyMessage;

  /// No description provided for @bdRemotesPublishToGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 올리기'**
  String get bdRemotesPublishToGitHub;

  /// No description provided for @bdRemotesPublishAlsoToGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에도 올리기 (원격 추가)'**
  String get bdRemotesPublishAlsoToGitHub;

  /// No description provided for @bdRemotesPublishConfirm.
  ///
  /// In ko, this message translates to:
  /// **'만들고 올리기'**
  String get bdRemotesPublishConfirm;

  /// No description provided for @bdRemotesNotGitHubNote.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 저장소가 아니라서 PR·릴리스·Actions는 쓸 수 없습니다 (gh는 GitHub 전용).'**
  String get bdRemotesNotGitHubNote;

  /// No description provided for @bdRemotesNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'원격 이름'**
  String get bdRemotesNameLabel;

  /// No description provided for @bdRemotesNameTaken.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 원격이 이미 있습니다'**
  String get bdRemotesNameTaken;

  /// No description provided for @bdRemotesNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'공백과 특수 문자는 쓸 수 없습니다'**
  String get bdRemotesNameInvalid;

  /// No description provided for @bdRemotesUrlLabel.
  ///
  /// In ko, this message translates to:
  /// **'URL'**
  String get bdRemotesUrlLabel;

  /// No description provided for @bdRemotesUseHttps.
  ///
  /// In ko, this message translates to:
  /// **'HTTPS 주소로 바꾸기'**
  String get bdRemotesUseHttps;

  /// No description provided for @bdRemotesUseSsh.
  ///
  /// In ko, this message translates to:
  /// **'SSH 주소로 바꾸기'**
  String get bdRemotesUseSsh;

  /// No description provided for @bdPublishNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'저장소 이름'**
  String get bdPublishNameLabel;

  /// No description provided for @bdPublishNameHelper.
  ///
  /// In ko, this message translates to:
  /// **'조직에 만들려면 조직/이름'**
  String get bdPublishNameHelper;

  /// No description provided for @bdPublishNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'영문, 숫자, - _ . 만 쓸 수 있습니다'**
  String get bdPublishNameInvalid;

  /// No description provided for @bdPublishDescriptionLabel.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get bdPublishDescriptionLabel;

  /// No description provided for @bdPublishPrivate.
  ///
  /// In ko, this message translates to:
  /// **'비공개'**
  String get bdPublishPrivate;

  /// No description provided for @bdPublishPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개'**
  String get bdPublishPublic;

  /// No description provided for @bdPublishNoCommitsNote.
  ///
  /// In ko, this message translates to:
  /// **'아직 커밋이 없어서 저장소만 만듭니다. 첫 커밋 뒤에 Push하세요.'**
  String get bdPublishNoCommitsNote;

  /// No description provided for @bdEditorTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열 편집기'**
  String get bdEditorTitle;

  /// No description provided for @bdEditorMessage.
  ///
  /// In ko, this message translates to:
  /// **'편집기 명령을 적으면 파일과 저장소 폴더를 그 편집기로 엽니다. 비워 두면 파일은 OS 기본 앱으로, 폴더는 VS Code로 엽니다.'**
  String get bdEditorMessage;

  /// No description provided for @bdEditorLabel.
  ///
  /// In ko, this message translates to:
  /// **'편집기 명령'**
  String get bdEditorLabel;

  /// No description provided for @bdLogTitle.
  ///
  /// In ko, this message translates to:
  /// **'명령 기록'**
  String get bdLogTitle;

  /// No description provided for @bdLogClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get bdLogClear;

  /// No description provided for @bdLogEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 실행한 명령이 없습니다'**
  String get bdLogEmpty;

  /// No description provided for @bdLogToggleTooltip.
  ///
  /// In ko, this message translates to:
  /// **'명령 기록 펼치기/접기'**
  String get bdLogToggleTooltip;

  /// No description provided for @bdDoneFetch.
  ///
  /// In ko, this message translates to:
  /// **'원격 정보를 가져왔습니다'**
  String get bdDoneFetch;

  /// No description provided for @bdDonePull.
  ///
  /// In ko, this message translates to:
  /// **'Pull을 마쳤습니다'**
  String get bdDonePull;

  /// No description provided for @bdDonePush.
  ///
  /// In ko, this message translates to:
  /// **'Push를 마쳤습니다'**
  String get bdDonePush;

  /// No description provided for @bdDonePublish.
  ///
  /// In ko, this message translates to:
  /// **'{branch} 브랜치를 게시했습니다'**
  String bdDonePublish(String branch);

  /// No description provided for @bdDoneCommit.
  ///
  /// In ko, this message translates to:
  /// **'커밋했습니다'**
  String get bdDoneCommit;

  /// No description provided for @bdDoneSwitch.
  ///
  /// In ko, this message translates to:
  /// **'{name}(으)로 전환했습니다'**
  String bdDoneSwitch(String name);

  /// No description provided for @bdDoneCreateBranch.
  ///
  /// In ko, this message translates to:
  /// **'{name} 브랜치를 만들었습니다'**
  String bdDoneCreateBranch(String name);

  /// No description provided for @bdDoneRenameBranch.
  ///
  /// In ko, this message translates to:
  /// **'이름을 {name}(으)로 바꿨습니다'**
  String bdDoneRenameBranch(String name);

  /// No description provided for @bdDoneDeleteBranch.
  ///
  /// In ko, this message translates to:
  /// **'{name} 브랜치를 삭제했습니다'**
  String bdDoneDeleteBranch(String name);

  /// No description provided for @bdDoneAddRemote.
  ///
  /// In ko, this message translates to:
  /// **'{name} 원격을 추가했습니다'**
  String bdDoneAddRemote(String name);

  /// No description provided for @bdDoneRenameRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격 이름을 {name}(으)로 바꿨습니다'**
  String bdDoneRenameRemote(String name);

  /// No description provided for @bdDoneSetRemoteUrl.
  ///
  /// In ko, this message translates to:
  /// **'{name}의 URL을 바꿨습니다'**
  String bdDoneSetRemoteUrl(String name);

  /// No description provided for @bdDoneRemoveRemote.
  ///
  /// In ko, this message translates to:
  /// **'{name} 원격을 삭제했습니다'**
  String bdDoneRemoveRemote(String name);

  /// No description provided for @bdDonePublishToGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 {name} 저장소를 만들었습니다'**
  String bdDonePublishToGitHub(String name);

  /// No description provided for @bdDoneAbort.
  ///
  /// In ko, this message translates to:
  /// **'중단했습니다'**
  String get bdDoneAbort;

  /// No description provided for @bdDoneContinue.
  ///
  /// In ko, this message translates to:
  /// **'계속 진행했습니다'**
  String get bdDoneContinue;

  /// No description provided for @bdErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'명령이 실패했습니다. 아래 원문을 확인하세요.'**
  String get bdErrorGeneric;

  /// No description provided for @bdErrorPushRejected.
  ///
  /// In ko, this message translates to:
  /// **'Push가 거부됐습니다. 원격에 내게 없는 커밋이 있어서입니다. 먼저 Pull 하세요.'**
  String get bdErrorPushRejected;

  /// No description provided for @bdErrorAuthFailed.
  ///
  /// In ko, this message translates to:
  /// **'인증에 실패했습니다. gh auth login으로 로그인했는지, SSH 키가 등록됐는지 확인하세요.'**
  String get bdErrorAuthFailed;

  /// No description provided for @bdErrorConflict.
  ///
  /// In ko, this message translates to:
  /// **'충돌이 났습니다. 변경 탭에서 충돌 파일을 편집기로 열어 고친 뒤 해결됨을 누르세요.'**
  String get bdErrorConflict;

  /// No description provided for @bdErrorLocalChanges.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경이 덮어써질 수 있어서 멈췄습니다. 먼저 커밋하세요.'**
  String get bdErrorLocalChanges;

  /// No description provided for @bdErrorNotFastForward.
  ///
  /// In ko, this message translates to:
  /// **'기록이 갈라져서 fast-forward로 받을 수 없습니다. Pull 방식을 병합이나 rebase로 바꾸세요.'**
  String get bdErrorNotFastForward;

  /// No description provided for @bdErrorProtectedBranch.
  ///
  /// In ko, this message translates to:
  /// **'보호된 브랜치라서 직접 Push할 수 없습니다. 새 브랜치로 올리고 PR을 만드세요.'**
  String get bdErrorProtectedBranch;

  /// No description provided for @bdErrorBranchNotMerged.
  ///
  /// In ko, this message translates to:
  /// **'병합되지 않은 커밋이 있는 브랜치입니다.'**
  String get bdErrorBranchNotMerged;

  /// No description provided for @bdErrorNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'추적 브랜치가 없습니다. 먼저 게시(Publish)하세요.'**
  String get bdErrorNoUpstream;

  /// No description provided for @bdErrorAlreadyExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름이 이미 있습니다.'**
  String get bdErrorAlreadyExists;

  /// No description provided for @bdErrorRepositoryNotFound.
  ///
  /// In ko, this message translates to:
  /// **'원격 저장소를 찾을 수 없습니다. URL과 접근 권한을 확인하세요.'**
  String get bdErrorRepositoryNotFound;

  /// No description provided for @bdErrorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'서버에 연결할 수 없습니다. 네트워크를 확인하세요.'**
  String get bdErrorNetwork;

  /// No description provided for @bdErrorNotInstalled.
  ///
  /// In ko, this message translates to:
  /// **'프로그램을 찾을 수 없습니다. 메뉴의 환경 점검을 확인하세요.'**
  String get bdErrorNotInstalled;

  /// No description provided for @bdErrorBranchInOtherWorktree.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 다른 worktree({path})에 체크아웃되어 있습니다. git은 한 브랜치를 한 번에 한 worktree에서만 체크아웃할 수 있습니다.'**
  String bdErrorBranchInOtherWorktree(String path);

  /// No description provided for @bdOpenWorktreeFolder.
  ///
  /// In ko, this message translates to:
  /// **'그 폴더 열기'**
  String get bdOpenWorktreeFolder;

  /// No description provided for @bdTimeJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get bdTimeJustNow;

  /// No description provided for @bdTimeMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String bdTimeMinutesAgo(int n);

  /// No description provided for @bdTimeHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String bdTimeHoursAgo(int n);

  /// No description provided for @bdTimeDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String bdTimeDaysAgo(int n);

  /// No description provided for @bdHelpTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이게 뭔가요?'**
  String get bdHelpTooltip;

  /// No description provided for @bdHelpSectionWord.
  ///
  /// In ko, this message translates to:
  /// **'낱말 뜻'**
  String get bdHelpSectionWord;

  /// No description provided for @bdHelpSectionInGit.
  ///
  /// In ko, this message translates to:
  /// **'git에서는'**
  String get bdHelpSectionInGit;

  /// No description provided for @bdHelpSectionWhy.
  ///
  /// In ko, this message translates to:
  /// **'왜 · 언제 쓰나'**
  String get bdHelpSectionWhy;

  /// No description provided for @bdHelpSectionLinks.
  ///
  /// In ko, this message translates to:
  /// **'더 알아보기'**
  String get bdHelpSectionLinks;

  /// No description provided for @bdHelpCaptionBefore.
  ///
  /// In ko, this message translates to:
  /// **'전'**
  String get bdHelpCaptionBefore;

  /// No description provided for @bdHelpCaptionAfter.
  ///
  /// In ko, this message translates to:
  /// **'후'**
  String get bdHelpCaptionAfter;

  /// No description provided for @bdHelpCaptionAfterFetch.
  ///
  /// In ko, this message translates to:
  /// **'Fetch 후 — 내 main은 그대로'**
  String get bdHelpCaptionAfterFetch;

  /// No description provided for @bdHelpCaptionAfterPull.
  ///
  /// In ko, this message translates to:
  /// **'Pull 후 — 내 main도 따라감'**
  String get bdHelpCaptionAfterPull;

  /// No description provided for @bdHelpCaptionAheadOne.
  ///
  /// In ko, this message translates to:
  /// **'feature가 origin/feature보다 커밋 하나 앞섬 (↑1)'**
  String get bdHelpCaptionAheadOne;

  /// No description provided for @bdHelpLinkBranchingBasics.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — 브랜치와 Merge의 기초'**
  String get bdHelpLinkBranchingBasics;

  /// No description provided for @bdHelpLinkRemoteBranches.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — 리모트 브랜치'**
  String get bdHelpLinkRemoteBranches;

  /// No description provided for @bdHelpLinkRebasing.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — Rebase 하기'**
  String get bdHelpLinkRebasing;

  /// No description provided for @bdHelpFetchVsPullTitle.
  ///
  /// In ko, this message translates to:
  /// **'Fetch와 Pull'**
  String get bdHelpFetchVsPullTitle;

  /// No description provided for @bdHelpFetchVsPullWord.
  ///
  /// In ko, this message translates to:
  /// **'fetch는 \'가서 가져오다\', pull은 \'끌어당기다\'.'**
  String get bdHelpFetchVsPullWord;

  /// No description provided for @bdHelpFetchVsPullInGit.
  ///
  /// In ko, this message translates to:
  /// **'Fetch는 원격(GitHub)에 새로 생긴 커밋을 내 컴퓨터로 가져와 origin/main 같은 \'원격 이름표\'만 옮깁니다. 내 브랜치와 파일은 건드리지 않습니다. Pull은 Fetch를 한 뒤, 가져온 커밋을 내 브랜치에 합칩니다.'**
  String get bdHelpFetchVsPullInGit;

  /// No description provided for @bdHelpFetchVsPullWhy.
  ///
  /// In ko, this message translates to:
  /// **'무엇이 바뀌었는지 먼저 보고 싶으면 Fetch — 안전하고 언제 해도 됩니다. 바로 최신으로 맞추려면 Pull. 커밋하지 않은 변경이 있으면 Pull이 멈출 수 있으니 먼저 커밋하세요.'**
  String get bdHelpFetchVsPullWhy;

  /// No description provided for @bdHelpUpstreamTitle.
  ///
  /// In ko, this message translates to:
  /// **'추적 브랜치 (upstream)와 origin'**
  String get bdHelpUpstreamTitle;

  /// No description provided for @bdHelpUpstreamWord.
  ///
  /// In ko, this message translates to:
  /// **'upstream은 \'상류\'. 물이 흘러오는 쪽입니다. origin은 \'출처, 기원\'.'**
  String get bdHelpUpstreamWord;

  /// No description provided for @bdHelpUpstreamInGit.
  ///
  /// In ko, this message translates to:
  /// **'origin은 저장소를 받아 온 원격(대개 GitHub)에 붙는 기본 이름입니다. 내 브랜치가 짝지어 둔 원격 브랜치(예: origin/feature)를 추적 브랜치, 곧 upstream이라고 합니다. ↑↓ 숫자는 이 짝과 비교한 것입니다.'**
  String get bdHelpUpstreamInGit;

  /// No description provided for @bdHelpUpstreamWhy.
  ///
  /// In ko, this message translates to:
  /// **'짝이 있어야 그냥 Push, Pull만 눌러도 어디로 보내고 어디서 받을지 압니다. 새 브랜치에는 짝이 없어서 처음 한 번은 \'게시\'(git push -u)로 짝을 지어 줍니다.'**
  String get bdHelpUpstreamWhy;

  /// No description provided for @bdHelpFastForwardTitle.
  ///
  /// In ko, this message translates to:
  /// **'Fast-forward (빨리 감기)'**
  String get bdHelpFastForwardTitle;

  /// No description provided for @bdHelpFastForwardWord.
  ///
  /// In ko, this message translates to:
  /// **'테이프나 영상을 앞으로 빨리 감는 것.'**
  String get bdHelpFastForwardWord;

  /// No description provided for @bdHelpFastForwardInGit.
  ///
  /// In ko, this message translates to:
  /// **'내 브랜치가 갈라진 적 없이 뒤처져 있기만 할 때, 새 커밋을 만들지 않고 브랜치 이름표를 최신 커밋 위치로 앞으로 옮기기만 합니다. 이미 있는 커밋을 따라 \'앞으로 감기\'만 하므로 이렇게 부릅니다.'**
  String get bdHelpFastForwardInGit;

  /// No description provided for @bdHelpFastForwardWhy.
  ///
  /// In ko, this message translates to:
  /// **'기록이 한 줄로 깔끔하고 합칠 것이 없으니 충돌도 없습니다. 양쪽에 서로 다른 새 커밋이 있으면(갈라졌으면) 빨리 감을 수 없어서, \'Fast-forward만\'은 멈추고 병합이나 rebase가 필요합니다. Push가 non-fast-forward로 거부되는 것도 같은 이유입니다.'**
  String get bdHelpFastForwardWhy;

  /// No description provided for @bdHelpMergeCommitTitle.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 (merge commit)'**
  String get bdHelpMergeCommitTitle;

  /// No description provided for @bdHelpMergeCommitWord.
  ///
  /// In ko, this message translates to:
  /// **'merge는 \'합치다\', 두 길이 하나로 합류하는 것.'**
  String get bdHelpMergeCommitWord;

  /// No description provided for @bdHelpMergeCommitInGit.
  ///
  /// In ko, this message translates to:
  /// **'갈라진 두 기록을 그대로 두고, 둘을 부모로 가진 새 커밋(병합 커밋)을 하나 만들어 합칩니다. 누가 언제 무엇을 합쳤는지 기록에 그대로 남습니다.'**
  String get bdHelpMergeCommitInGit;

  /// No description provided for @bdHelpMergeCommitWhy.
  ///
  /// In ko, this message translates to:
  /// **'이미 올린 커밋을 바꾸지 않아 가장 안전합니다. 다른 사람과 같이 쓰는 브랜치에 알맞습니다. 대신 기록에 병합 커밋이 늘어 조금 복잡해 보입니다.'**
  String get bdHelpMergeCommitWhy;

  /// No description provided for @bdHelpRebaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'Rebase'**
  String get bdHelpRebaseTitle;

  /// No description provided for @bdHelpRebaseWord.
  ///
  /// In ko, this message translates to:
  /// **'base는 \'밑받침\', rebase는 \'밑받침을 다시 놓다\'.'**
  String get bdHelpRebaseWord;

  /// No description provided for @bdHelpRebaseInGit.
  ///
  /// In ko, this message translates to:
  /// **'내 커밋들을 떼어 내서, 새로 받아온 커밋 뒤에 차례로 다시 붙입니다. 내용은 같지만 새 커밋(C\', D\')으로 다시 만들어지고, 기록은 한 줄이 됩니다.'**
  String get bdHelpRebaseInGit;

  /// No description provided for @bdHelpRebaseWhy.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 없이 기록이 깔끔합니다. 아직 Push하지 않은 내 커밋에만 쓰세요. 이미 올린 커밋을 rebase하면 다른 사람의 기록과 어긋나서 강제 Push가 필요해집니다.'**
  String get bdHelpRebaseWhy;

  /// No description provided for @bdTabTags.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get bdTabTags;

  /// No description provided for @bdTabRelease.
  ///
  /// In ko, this message translates to:
  /// **'릴리스'**
  String get bdTabRelease;

  /// No description provided for @bdTabPr.
  ///
  /// In ko, this message translates to:
  /// **'PR'**
  String get bdTabPr;

  /// No description provided for @bdBranchesMergeInto.
  ///
  /// In ko, this message translates to:
  /// **'{head}(으)로 병합해 오기'**
  String bdBranchesMergeInto(String head);

  /// No description provided for @bdMergeTitle.
  ///
  /// In ko, this message translates to:
  /// **'{source} → {into} 병합'**
  String bdMergeTitle(String source, String into);

  /// No description provided for @bdMergeNothing.
  ///
  /// In ko, this message translates to:
  /// **'{source}에는 {into}에 없는 커밋이 없습니다'**
  String bdMergeNothing(String source, String into);

  /// No description provided for @bdMergeIncoming.
  ///
  /// In ko, this message translates to:
  /// **'들어올 커밋 {count}개'**
  String bdMergeIncoming(int count);

  /// No description provided for @bdMergeFastForward.
  ///
  /// In ko, this message translates to:
  /// **'Fast-forward'**
  String get bdMergeFastForward;

  /// No description provided for @bdMergeFastForwardWhen.
  ///
  /// In ko, this message translates to:
  /// **'새 커밋 없이 이름표만 앞으로 옮깁니다. 기록이 한 줄로 남습니다.'**
  String get bdMergeFastForwardWhen;

  /// No description provided for @bdMergeFastForwardDisabled.
  ///
  /// In ko, this message translates to:
  /// **'현재 브랜치에도 새 커밋이 있어서(갈라져서) 쓸 수 없습니다.'**
  String get bdMergeFastForwardDisabled;

  /// No description provided for @bdMergeMergeCommit.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋'**
  String get bdMergeMergeCommit;

  /// No description provided for @bdMergeMergeCommitWhen.
  ///
  /// In ko, this message translates to:
  /// **'두 기록을 그대로 두고 병합 커밋으로 합칩니다. 가장 안전합니다.'**
  String get bdMergeMergeCommitWhen;

  /// No description provided for @bdMergeSquash.
  ///
  /// In ko, this message translates to:
  /// **'Squash'**
  String get bdMergeSquash;

  /// No description provided for @bdMergeSquashWhen.
  ///
  /// In ko, this message translates to:
  /// **'브랜치의 커밋을 하나로 눌러 합칩니다. 기능 하나 = 커밋 하나.'**
  String get bdMergeSquashWhen;

  /// No description provided for @bdMergeSquashNote.
  ///
  /// In ko, this message translates to:
  /// **'squash 뒤 {source}를 계속 쓰면 같은 변경이 다시 충돌할 수 있습니다. 병합 후 브랜치를 지우는 것을 권합니다.'**
  String bdMergeSquashNote(String source);

  /// No description provided for @bdMergeMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'커밋 메시지'**
  String get bdMergeMessageLabel;

  /// No description provided for @bdMergeConfirm.
  ///
  /// In ko, this message translates to:
  /// **'병합'**
  String get bdMergeConfirm;

  /// No description provided for @bdDoneMerge.
  ///
  /// In ko, this message translates to:
  /// **'{source}을(를) {into}(으)로 병합했습니다'**
  String bdDoneMerge(String source, String into);

  /// No description provided for @bdTagsTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get bdTagsTitle;

  /// No description provided for @bdTagsNew.
  ///
  /// In ko, this message translates to:
  /// **'새 태그'**
  String get bdTagsNew;

  /// No description provided for @bdTagsCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get bdTagsCreate;

  /// No description provided for @bdTagsCreateAndPush.
  ///
  /// In ko, this message translates to:
  /// **'만들고 push'**
  String get bdTagsCreateAndPush;

  /// No description provided for @bdTagsPushAll.
  ///
  /// In ko, this message translates to:
  /// **'원격에 없는 태그 {count}개 push'**
  String bdTagsPushAll(int count);

  /// No description provided for @bdTagsPushed.
  ///
  /// In ko, this message translates to:
  /// **'원격에 있음'**
  String get bdTagsPushed;

  /// No description provided for @bdTagsLocalOnly.
  ///
  /// In ko, this message translates to:
  /// **'내 컴퓨터에만 있음'**
  String get bdTagsLocalOnly;

  /// No description provided for @bdTagsLightweight.
  ///
  /// In ko, this message translates to:
  /// **'가벼운 태그'**
  String get bdTagsLightweight;

  /// No description provided for @bdTagsAnnotated.
  ///
  /// In ko, this message translates to:
  /// **'주석 태그'**
  String get bdTagsAnnotated;

  /// No description provided for @bdTagsPush.
  ///
  /// In ko, this message translates to:
  /// **'Push'**
  String get bdTagsPush;

  /// No description provided for @bdTagsDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get bdTagsDelete;

  /// No description provided for @bdTagsDeleteRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 삭제'**
  String get bdTagsDeleteRemote;

  /// No description provided for @bdTagsDeleteRemoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'원격 태그를 삭제할까요?'**
  String get bdTagsDeleteRemoteTitle;

  /// No description provided for @bdTagsDeleteRemoteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{target}에서 {tag} 태그를 삭제합니다. 이미 받아 간 사람이 있을 수 있으니, 같은 이름을 다시 쓰기보다 다음 번호를 쓰세요.'**
  String bdTagsDeleteRemoteMessage(String tag, String target);

  /// No description provided for @bdTagsEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 태그가 없습니다'**
  String get bdTagsEmptyTitle;

  /// No description provided for @bdTagsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'태그는 특정 커밋에 붙이는 이름표입니다. 보통 v1.0.0처럼 릴리스 버전에 씁니다.'**
  String get bdTagsEmptyMessage;

  /// No description provided for @bdTagsPushAfter.
  ///
  /// In ko, this message translates to:
  /// **'만든 뒤 {remote}에 push'**
  String bdTagsPushAfter(String remote);

  /// No description provided for @bdTagNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'태그 이름'**
  String get bdTagNameLabel;

  /// No description provided for @bdTagNameExists.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 태그가 이미 있습니다'**
  String get bdTagNameExists;

  /// No description provided for @bdTagNameInvalid.
  ///
  /// In ko, this message translates to:
  /// **'공백, .., ~ ^ : ? * [ \\ 는 쓸 수 없습니다'**
  String get bdTagNameInvalid;

  /// No description provided for @bdTagNameNotSemVer.
  ///
  /// In ko, this message translates to:
  /// **'버전 형식(v1.2.3)이 아닙니다. 만들 수는 있지만 릴리스에는 버전 형식을 권합니다.'**
  String get bdTagNameNotSemVer;

  /// No description provided for @bdTagNameMissingV.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 태그는 v를 붙이는 것이 관례입니다 (v1.2.3).'**
  String get bdTagNameMissingV;

  /// No description provided for @bdTagMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get bdTagMessageLabel;

  /// No description provided for @bdTagTargetLabel.
  ///
  /// In ko, this message translates to:
  /// **'어느 커밋에 달까요'**
  String get bdTagTargetLabel;

  /// No description provided for @bdTagTargetHead.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치 ({name})'**
  String bdTagTargetHead(String name);

  /// No description provided for @bdDoneCreateTag.
  ///
  /// In ko, this message translates to:
  /// **'{name} 태그를 만들었습니다'**
  String bdDoneCreateTag(String name);

  /// No description provided for @bdDonePushTags.
  ///
  /// In ko, this message translates to:
  /// **'태그 {count}개를 push했습니다'**
  String bdDonePushTags(int count);

  /// No description provided for @bdDoneDeleteTag.
  ///
  /// In ko, this message translates to:
  /// **'{name} 태그를 삭제했습니다'**
  String bdDoneDeleteTag(String name);

  /// No description provided for @bdDoneDeleteRemoteTag.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 {name} 태그를 삭제했습니다'**
  String bdDoneDeleteRemoteTag(String name);

  /// No description provided for @bdPrTitle.
  ///
  /// In ko, this message translates to:
  /// **'Pull Request'**
  String get bdPrTitle;

  /// No description provided for @bdPrCreate.
  ///
  /// In ko, this message translates to:
  /// **'PR 만들기'**
  String get bdPrCreate;

  /// No description provided for @bdPrPublishAndCreate.
  ///
  /// In ko, this message translates to:
  /// **'게시하고 PR 만들기'**
  String get bdPrPublishAndCreate;

  /// No description provided for @bdPrTitleLabel.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get bdPrTitleLabel;

  /// No description provided for @bdPrBodyLabel.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get bdPrBodyLabel;

  /// No description provided for @bdPrBodyChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 내용'**
  String get bdPrBodyChanges;

  /// No description provided for @bdPrDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안으로 만들기'**
  String get bdPrDraft;

  /// No description provided for @bdPrNotGitHubTitle.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 저장소가 아닙니다'**
  String get bdPrNotGitHubTitle;

  /// No description provided for @bdPrNotGitHubMessage.
  ///
  /// In ko, this message translates to:
  /// **'Pull Request는 GitHub 저장소에서만 쓸 수 있습니다 — gh는 GitHub 전용 도구입니다.'**
  String get bdPrNotGitHubMessage;

  /// No description provided for @bdPrGhRequiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'gh가 필요합니다'**
  String get bdPrGhRequiredTitle;

  /// No description provided for @bdPrDetached.
  ///
  /// In ko, this message translates to:
  /// **'브랜치에 있지 않습니다'**
  String get bdPrDetached;

  /// No description provided for @bdPrOnDefaultTitle.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치에 있습니다'**
  String get bdPrOnDefaultTitle;

  /// No description provided for @bdPrOnDefaultMessage.
  ///
  /// In ko, this message translates to:
  /// **'PR은 작업 브랜치에서 만듭니다. 브랜치 탭에서 새 브랜치를 만드세요.'**
  String get bdPrOnDefaultMessage;

  /// No description provided for @bdPrNoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'{head}에는 아직 PR이 없습니다'**
  String bdPrNoneTitle(String head);

  /// No description provided for @bdPrNoneMessage.
  ///
  /// In ko, this message translates to:
  /// **'{base}(으)로 합칠 PR을 만들면 GitHub에서 검토와 검사를 거쳐 병합합니다.'**
  String bdPrNoneMessage(String base);

  /// No description provided for @bdPrOpenOnGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에서 보기'**
  String get bdPrOpenOnGitHub;

  /// No description provided for @bdPrStateOpen.
  ///
  /// In ko, this message translates to:
  /// **'열림'**
  String get bdPrStateOpen;

  /// No description provided for @bdPrStateDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get bdPrStateDraft;

  /// No description provided for @bdPrStateMerged.
  ///
  /// In ko, this message translates to:
  /// **'병합됨'**
  String get bdPrStateMerged;

  /// No description provided for @bdPrStateClosed.
  ///
  /// In ko, this message translates to:
  /// **'닫힘'**
  String get bdPrStateClosed;

  /// No description provided for @bdPrNoChecks.
  ///
  /// In ko, this message translates to:
  /// **'검사 없음'**
  String get bdPrNoChecks;

  /// No description provided for @bdPrChecksPassed.
  ///
  /// In ko, this message translates to:
  /// **'통과 {n}'**
  String bdPrChecksPassed(int n);

  /// No description provided for @bdPrChecksFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패 {n}'**
  String bdPrChecksFailed(int n);

  /// No description provided for @bdPrChecksPending.
  ///
  /// In ko, this message translates to:
  /// **'진행 중 {n}'**
  String bdPrChecksPending(int n);

  /// No description provided for @bdPrApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인됨'**
  String get bdPrApproved;

  /// No description provided for @bdPrReviewRequired.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 필요'**
  String get bdPrReviewRequired;

  /// No description provided for @bdPrBlockedDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안 PR은 병합할 수 없습니다. GitHub에서 \'검토 준비 완료\'로 바꾸세요.'**
  String get bdPrBlockedDraft;

  /// No description provided for @bdPrBlockedConflict.
  ///
  /// In ko, this message translates to:
  /// **'기준 브랜치와 충돌이 있습니다. 기준 브랜치를 병합해 와서 충돌을 해결하세요.'**
  String get bdPrBlockedConflict;

  /// No description provided for @bdPrBlockedChecks.
  ///
  /// In ko, this message translates to:
  /// **'실패한 검사가 있습니다: {names}'**
  String bdPrBlockedChecks(String names);

  /// No description provided for @bdPrBlockedPending.
  ///
  /// In ko, this message translates to:
  /// **'검사 {count}개가 아직 진행 중입니다.'**
  String bdPrBlockedPending(int count);

  /// No description provided for @bdPrBlockedReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 승인이 필요할 수 있습니다. 병합이 거부되면 GitHub에서 확인하세요.'**
  String get bdPrBlockedReview;

  /// No description provided for @bdPrMethodMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 (merge)'**
  String get bdPrMethodMerge;

  /// No description provided for @bdPrMethodSquash.
  ///
  /// In ko, this message translates to:
  /// **'Squash 후 병합'**
  String get bdPrMethodSquash;

  /// No description provided for @bdPrMethodRebase.
  ///
  /// In ko, this message translates to:
  /// **'Rebase 후 병합'**
  String get bdPrMethodRebase;

  /// No description provided for @bdPrDeleteBranch.
  ///
  /// In ko, this message translates to:
  /// **'병합 후 브랜치 삭제'**
  String get bdPrDeleteBranch;

  /// No description provided for @bdPrMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합하기'**
  String get bdPrMerge;

  /// No description provided for @bdPrMerging.
  ///
  /// In ko, this message translates to:
  /// **'병합하는 중…'**
  String get bdPrMerging;

  /// No description provided for @bdDonePrCreated.
  ///
  /// In ko, this message translates to:
  /// **'PR을 만들었습니다'**
  String get bdDonePrCreated;

  /// No description provided for @bdDonePrMerged.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number}을(를) 병합했습니다'**
  String bdDonePrMerged(int number);

  /// No description provided for @bdReleaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스'**
  String get bdReleaseTitle;

  /// No description provided for @bdReleaseLatest.
  ///
  /// In ko, this message translates to:
  /// **'마지막 릴리스 {tag}'**
  String bdReleaseLatest(String tag);

  /// No description provided for @bdReleaseNoTags.
  ///
  /// In ko, this message translates to:
  /// **'아직 릴리스가 없습니다'**
  String get bdReleaseNoTags;

  /// No description provided for @bdReleaseIntro.
  ///
  /// In ko, this message translates to:
  /// **'버전 올리기 → PR → 병합 → 태그 → CI 확인을 차례로 안내합니다.'**
  String get bdReleaseIntro;

  /// No description provided for @bdReleaseNeedsGitHub.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 마법사는 GitHub 저장소에서 쓸 수 있습니다. 태그는 태그 탭에서 만들 수 있습니다.'**
  String get bdReleaseNeedsGitHub;

  /// No description provided for @bdReleaseStart.
  ///
  /// In ko, this message translates to:
  /// **'새 릴리스'**
  String get bdReleaseStart;

  /// No description provided for @bdReleaseNew.
  ///
  /// In ko, this message translates to:
  /// **'새 릴리스'**
  String get bdReleaseNew;

  /// No description provided for @bdReleaseNewVersion.
  ///
  /// In ko, this message translates to:
  /// **'새 릴리스 {tag}'**
  String bdReleaseNewVersion(String tag);

  /// No description provided for @bdReleaseCancel.
  ///
  /// In ko, this message translates to:
  /// **'그만두기'**
  String get bdReleaseCancel;

  /// No description provided for @bdReleaseCancelTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스를 그만둘까요?'**
  String get bdReleaseCancelTitle;

  /// No description provided for @bdReleaseCancelMessage.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 만든 {branch} 브랜치와 PR은 그대로 남습니다. 필요 없으면 직접 지우세요.'**
  String bdReleaseCancelMessage(String branch);

  /// No description provided for @bdReleaseCancelAfterTag.
  ///
  /// In ko, this message translates to:
  /// **'태그는 이미 push되었습니다. 마법사만 닫고, CI와 릴리스는 GitHub에서 확인하세요.'**
  String get bdReleaseCancelAfterTag;

  /// No description provided for @bdReleaseDone.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 마쳤습니다'**
  String bdReleaseDone(String tag);

  /// No description provided for @bdReleasePrerelease.
  ///
  /// In ko, this message translates to:
  /// **'프리릴리스'**
  String get bdReleasePrerelease;

  /// No description provided for @bdReleasePushAndPr.
  ///
  /// In ko, this message translates to:
  /// **'push하고 PR 만들기'**
  String get bdReleasePushAndPr;

  /// No description provided for @bdStepCheck.
  ///
  /// In ko, this message translates to:
  /// **'점검'**
  String get bdStepCheck;

  /// No description provided for @bdStepVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get bdStepVersion;

  /// No description provided for @bdStepPr.
  ///
  /// In ko, this message translates to:
  /// **'PR'**
  String get bdStepPr;

  /// No description provided for @bdStepMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합'**
  String get bdStepMerge;

  /// No description provided for @bdStepTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get bdStepTag;

  /// No description provided for @bdStepNotes.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 노트'**
  String get bdStepNotes;

  /// No description provided for @bdStepNotesCi.
  ///
  /// In ko, this message translates to:
  /// **'노트 (CI 릴리스 후)'**
  String get bdStepNotesCi;

  /// No description provided for @bdStepNotesCiSummary.
  ///
  /// In ko, this message translates to:
  /// **'CI가 릴리스를 만듭니다'**
  String get bdStepNotesCiSummary;

  /// No description provided for @bdStepCi.
  ///
  /// In ko, this message translates to:
  /// **'CI 확인'**
  String get bdStepCi;

  /// No description provided for @bdStepNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get bdStepNext;

  /// No description provided for @bdStepCheckDone.
  ///
  /// In ko, this message translates to:
  /// **'모두 통과'**
  String get bdStepCheckDone;

  /// No description provided for @bdStepMergeDone.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number} 병합됨'**
  String bdStepMergeDone(int number);

  /// No description provided for @bdCheckCleanTree.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경이 없다'**
  String get bdCheckCleanTree;

  /// No description provided for @bdCheckShowChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 보기'**
  String get bdCheckShowChanges;

  /// No description provided for @bdCheckOnDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치({branch})에 있다'**
  String bdCheckOnDefault(String branch);

  /// No description provided for @bdCheckSynced.
  ///
  /// In ko, this message translates to:
  /// **'받을 커밋도 보낼 커밋도 없다'**
  String get bdCheckSynced;

  /// No description provided for @bdCheckGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 원격과 gh 로그인'**
  String get bdCheckGitHub;

  /// No description provided for @bdCheckGitBash.
  ///
  /// In ko, this message translates to:
  /// **'Git for Windows의 bash (버전 올림 스크립트용)'**
  String get bdCheckGitBash;

  /// No description provided for @bdCheckChangesSince.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 이후 커밋 {count}개'**
  String bdCheckChangesSince(int count, String tag);

  /// No description provided for @bdCheckFirstRelease.
  ///
  /// In ko, this message translates to:
  /// **'첫 릴리스입니다'**
  String get bdCheckFirstRelease;

  /// No description provided for @bdCheckNoWorkflow.
  ///
  /// In ko, this message translates to:
  /// **'태그로 도는 워크플로가 없습니다. 앱이 GitHub 릴리스를 만듭니다.'**
  String get bdCheckNoWorkflow;

  /// No description provided for @bdCheckWorkflowCi.
  ///
  /// In ko, this message translates to:
  /// **'{file}이(가) 태그 push로 릴리스를 만듭니다. 앱은 태그까지 달고 CI를 지켜봅니다.'**
  String bdCheckWorkflowCi(String file);

  /// No description provided for @bdCheckWorkflowOther.
  ///
  /// In ko, this message translates to:
  /// **'{file}이(가) 태그 push로 돕니다.'**
  String bdCheckWorkflowOther(String file);

  /// No description provided for @bdManualBuildTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 전 수동 빌드 (권장)'**
  String get bdManualBuildTitle;

  /// No description provided for @bdManualBuildWhy.
  ///
  /// In ko, this message translates to:
  /// **'지난 릴리스 이후 빌드에 영향을 주는 파일이 바뀌었습니다. 태그 전에 모든 플랫폼이 빌드되는지 확인하세요. 수동 실행은 릴리스를 만들지 않습니다.'**
  String get bdManualBuildWhy;

  /// No description provided for @bdManualBuildStart.
  ///
  /// In ko, this message translates to:
  /// **'빌드만 확인'**
  String get bdManualBuildStart;

  /// No description provided for @bdManualBuildShort.
  ///
  /// In ko, this message translates to:
  /// **'수동 빌드 {state}'**
  String bdManualBuildShort(String state);

  /// No description provided for @bdDoneManualBuildStarted.
  ///
  /// In ko, this message translates to:
  /// **'수동 빌드를 시작했습니다'**
  String get bdDoneManualBuildStarted;

  /// No description provided for @bdVersionCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 {version} ({source})'**
  String bdVersionCurrent(String version, String source);

  /// No description provided for @bdVersionFromTag.
  ///
  /// In ko, this message translates to:
  /// **'마지막 태그'**
  String get bdVersionFromTag;

  /// No description provided for @bdVersionRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get bdVersionRecommended;

  /// No description provided for @bdVersionReason.
  ///
  /// In ko, this message translates to:
  /// **'새 기능 {feats} · 버그 수정 {fixes} · 호환 깨짐 {breaking}'**
  String bdVersionReason(int feats, int fixes, int breaking);

  /// No description provided for @bdVersionCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get bdVersionCustom;

  /// No description provided for @bdVersionFiles.
  ///
  /// In ko, this message translates to:
  /// **'바뀌는 파일'**
  String get bdVersionFiles;

  /// No description provided for @bdVersionNoFiles.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일이 없어서 태그만 만듭니다.'**
  String get bdVersionNoFiles;

  /// No description provided for @bdVersionCommit.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 브랜치 만들고 커밋'**
  String get bdVersionCommit;

  /// No description provided for @bdBumpFinal.
  ///
  /// In ko, this message translates to:
  /// **'정식'**
  String get bdBumpFinal;

  /// No description provided for @bdBumpPrerelease.
  ///
  /// In ko, this message translates to:
  /// **'프리릴리스'**
  String get bdBumpPrerelease;

  /// No description provided for @bdDoneReleaseCommit.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 버전 올림을 커밋했습니다'**
  String bdDoneReleaseCommit(String tag);

  /// No description provided for @bdMergeWaiting.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number} 병합을 기다리는 중 — GitHub에서 병합해도 알아챕니다'**
  String bdMergeWaiting(int number);

  /// No description provided for @bdTagCheckPrMerged.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number}이(가) 병합됐다'**
  String bdTagCheckPrMerged(int number);

  /// No description provided for @bdTagCheckSynced.
  ///
  /// In ko, this message translates to:
  /// **'{branch}에 있고 받을 커밋도 보낼 커밋도 없다'**
  String bdTagCheckSynced(String branch);

  /// No description provided for @bdTagCheckVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일이 {tag}와 같다'**
  String bdTagCheckVersion(String tag);

  /// No description provided for @bdTagCheckVersionWrong.
  ///
  /// In ko, this message translates to:
  /// **'지금 버전은 {version}입니다. 버전 올림 PR이 아직 병합되지 않았을 수 있습니다.'**
  String bdTagCheckVersionWrong(String version);

  /// No description provided for @bdTagCheckFree.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 태그가 아직 없다'**
  String bdTagCheckFree(String tag);

  /// No description provided for @bdTagConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 태그를 push할까요?'**
  String bdTagConfirmTitle(String tag);

  /// No description provided for @bdTagConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'{branch}의 병합 커밋에 {tag}를 답니다. push하면 릴리스가 공개되고, 태그는 옮기거나 지우지 않는 것이 규칙입니다.'**
  String bdTagConfirmMessage(String tag, String branch);

  /// No description provided for @bdTagConfirmPush.
  ///
  /// In ko, this message translates to:
  /// **'태그 달고 push'**
  String get bdTagConfirmPush;

  /// No description provided for @bdDoneTagPushed.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 태그를 push했습니다'**
  String bdDoneTagPushed(String tag);

  /// No description provided for @bdNotesLabel.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 노트 (마크다운)'**
  String get bdNotesLabel;

  /// No description provided for @bdNotesFeatures.
  ///
  /// In ko, this message translates to:
  /// **'새 기능'**
  String get bdNotesFeatures;

  /// No description provided for @bdNotesFixes.
  ///
  /// In ko, this message translates to:
  /// **'버그 수정'**
  String get bdNotesFixes;

  /// No description provided for @bdNotesOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get bdNotesOther;

  /// No description provided for @bdNotesCreateRelease.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스 만들기'**
  String get bdNotesCreateRelease;

  /// No description provided for @bdNotesEdit.
  ///
  /// In ko, this message translates to:
  /// **'노트 고치기'**
  String get bdNotesEdit;

  /// No description provided for @bdDoneReleaseCreated.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스를 만들었습니다'**
  String get bdDoneReleaseCreated;

  /// No description provided for @bdDoneNotesSaved.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 노트를 저장했습니다'**
  String get bdDoneNotesSaved;

  /// No description provided for @bdCiWaitingForRun.
  ///
  /// In ko, this message translates to:
  /// **'{tag}(으)로 시작된 워크플로를 찾는 중'**
  String bdCiWaitingForRun(String tag);

  /// No description provided for @bdCiOpenInBrowser.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 보기'**
  String get bdCiOpenInBrowser;

  /// No description provided for @bdCiRerunFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패한 잡 다시 실행'**
  String get bdCiRerunFailed;

  /// No description provided for @bdDoneRerun.
  ///
  /// In ko, this message translates to:
  /// **'실패한 잡을 다시 실행했습니다'**
  String get bdDoneRerun;

  /// No description provided for @bdRunQueued.
  ///
  /// In ko, this message translates to:
  /// **'대기 중'**
  String get bdRunQueued;

  /// No description provided for @bdRunRunning.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get bdRunRunning;

  /// No description provided for @bdRunSuccess.
  ///
  /// In ko, this message translates to:
  /// **'성공'**
  String get bdRunSuccess;

  /// No description provided for @bdRunFailure.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get bdRunFailure;

  /// No description provided for @bdRunCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get bdRunCancelled;

  /// No description provided for @bdRunSkipped.
  ///
  /// In ko, this message translates to:
  /// **'건너뜀'**
  String get bdRunSkipped;

  /// No description provided for @bdHelpCaptionAfterSquash.
  ///
  /// In ko, this message translates to:
  /// **'squash 병합 후 — main에 새 커밋 S 하나'**
  String get bdHelpCaptionAfterSquash;

  /// No description provided for @bdHelpCaptionTag.
  ///
  /// In ko, this message translates to:
  /// **'v1.0.0과 v1.1.0은 옮겨지지 않는 이름표, main은 앞으로 나아가는 이름표'**
  String get bdHelpCaptionTag;

  /// No description provided for @bdHelpLinkGitHubMergeMethods.
  ///
  /// In ko, this message translates to:
  /// **'GitHub — 병합 방법 정보'**
  String get bdHelpLinkGitHubMergeMethods;

  /// No description provided for @bdHelpLinkTagging.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — 태그'**
  String get bdHelpLinkTagging;

  /// No description provided for @bdHelpSquashTitle.
  ///
  /// In ko, this message translates to:
  /// **'Squash (눌러 합치기)'**
  String get bdHelpSquashTitle;

  /// No description provided for @bdHelpSquashWord.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 납작하게 만들다, 찌그러뜨리다.'**
  String get bdHelpSquashWord;

  /// No description provided for @bdHelpSquashInGit.
  ///
  /// In ko, this message translates to:
  /// **'브랜치의 여러 커밋을 눌러 커밋 하나로 합친 뒤 대상 브랜치에 올립니다. 변경 내용은 그대로이고 커밋 개수만 하나가 됩니다.'**
  String get bdHelpSquashInGit;

  /// No description provided for @bdHelpSquashWhy.
  ///
  /// In ko, this message translates to:
  /// **'\'오타 수정\', \'다시 시도\' 같은 작업 중 커밋을 기본 브랜치 기록에 남기지 않고, 기능 하나 = 커밋 하나로 정리합니다. PR을 병합할 때 많이 씁니다. 원래 커밋들은 기본 브랜치에 남지 않으니, 병합한 브랜치를 계속 쓰지 말고 지우세요.'**
  String get bdHelpSquashWhy;

  /// No description provided for @bdHelpTagTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 (주석 태그와 가벼운 태그)'**
  String get bdHelpTagTitle;

  /// No description provided for @bdHelpTagWord.
  ///
  /// In ko, this message translates to:
  /// **'tag는 \'꼬리표, 이름표\'.'**
  String get bdHelpTagWord;

  /// No description provided for @bdHelpTagInGit.
  ///
  /// In ko, this message translates to:
  /// **'특정 커밋에 붙이는 이름표입니다. 브랜치 이름표는 새 커밋을 따라 앞으로 가지만, 태그는 한 번 붙이면 그 커밋에 머뭅니다. 주석 태그는 만든 사람·날짜·메시지를 함께 저장하고, 가벼운 태그는 이름만 저장합니다.'**
  String get bdHelpTagInGit;

  /// No description provided for @bdHelpTagWhy.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 버전(v1.2.0)에는 주석 태그를 씁니다 — 릴리스 기록이 남고, GitHub 릴리스와 CI가 태그를 기준으로 돕니다. 이미 push한 태그는 옮기거나 지우지 말고, 잘못됐으면 다음 번호로 새로 다세요.'**
  String get bdHelpTagWhy;

  /// No description provided for @bdHeaderMergedAndGone.
  ///
  /// In ko, this message translates to:
  /// **'병합됨 · 원격 삭제됨'**
  String get bdHeaderMergedAndGone;

  /// No description provided for @bdHeaderMergedAndGoneTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 이미 기본 브랜치에 병합되었고 원격에서 삭제되었습니다. 다시 게시하면 지운 브랜치가 되살아납니다.'**
  String get bdHeaderMergedAndGoneTooltip;

  /// No description provided for @bdBannerMergedAndGone.
  ///
  /// In ko, this message translates to:
  /// **'이 브랜치는 병합되어 원격에서 삭제되었습니다. {branch}(으)로 돌아가세요'**
  String bdBannerMergedAndGone(String branch);

  /// No description provided for @bdBannerSwitchTo.
  ///
  /// In ko, this message translates to:
  /// **'{branch}(으)로 전환'**
  String bdBannerSwitchTo(String branch);

  /// No description provided for @bdBannerCreatePr.
  ///
  /// In ko, this message translates to:
  /// **'{branch}을(를) 올렸지만 아직 PR이 없습니다'**
  String bdBannerCreatePr(String branch);

  /// No description provided for @bdPrBaseLabel.
  ///
  /// In ko, this message translates to:
  /// **'기준 브랜치'**
  String get bdPrBaseLabel;

  /// No description provided for @bdPrBaseNotDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치({base})가 아닌 곳으로 합칩니다. 다른 기능 브랜치 위에 쌓는 PR일 때 씁니다.'**
  String bdPrBaseNotDefault(String base);

  /// No description provided for @bdTabCi.
  ///
  /// In ko, this message translates to:
  /// **'CI'**
  String get bdTabCi;

  /// No description provided for @bdCiTitle.
  ///
  /// In ko, this message translates to:
  /// **'CI 실행'**
  String get bdCiTitle;

  /// No description provided for @bdCiNotGitHubMessage.
  ///
  /// In ko, this message translates to:
  /// **'Actions는 GitHub 저장소에서만 쓸 수 있습니다 — gh는 GitHub 전용 도구입니다.'**
  String get bdCiNotGitHubMessage;

  /// No description provided for @bdCiEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'{branch}에는 아직 실행이 없습니다'**
  String bdCiEmptyTitle(String branch);

  /// No description provided for @bdCiEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'push나 PR, 태그로 워크플로가 돌면 여기에 나옵니다.'**
  String get bdCiEmptyMessage;

  /// No description provided for @bdCiRerun.
  ///
  /// In ko, this message translates to:
  /// **'다시 실행'**
  String get bdCiRerun;

  /// No description provided for @bdCiCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get bdCiCancel;

  /// No description provided for @bdCiDispatch.
  ///
  /// In ko, this message translates to:
  /// **'수동 실행'**
  String get bdCiDispatch;

  /// No description provided for @bdCiDispatchNeedsPush.
  ///
  /// In ko, this message translates to:
  /// **'수동 실행은 원격에 있는 브랜치에서만 할 수 있습니다. 먼저 게시하세요.'**
  String get bdCiDispatchNeedsPush;

  /// No description provided for @bdCiDispatchTitle.
  ///
  /// In ko, this message translates to:
  /// **'{file} 수동 실행'**
  String bdCiDispatchTitle(String file);

  /// No description provided for @bdCiDispatchMessage.
  ///
  /// In ko, this message translates to:
  /// **'{branch} 브랜치로 워크플로를 실행합니다. 입력이 필요한 워크플로는 브라우저에서 실행하세요.'**
  String bdCiDispatchMessage(String branch);

  /// No description provided for @bdCiDispatchConfirm.
  ///
  /// In ko, this message translates to:
  /// **'실행'**
  String get bdCiDispatchConfirm;

  /// No description provided for @bdDoneDispatched.
  ///
  /// In ko, this message translates to:
  /// **'{file}을(를) 실행했습니다'**
  String bdDoneDispatched(String file);

  /// No description provided for @bdDoneRunCancelled.
  ///
  /// In ko, this message translates to:
  /// **'실행을 취소했습니다'**
  String get bdDoneRunCancelled;

  /// No description provided for @bdNotifyRunTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} {state}'**
  String bdNotifyRunTitle(String name, String state);

  /// No description provided for @bdNotifyReleaseRun.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스 CI {state}'**
  String bdNotifyReleaseRun(String tag, String state);

  /// No description provided for @bdNotifyManualBuild.
  ///
  /// In ko, this message translates to:
  /// **'태그 전 수동 빌드 {state}'**
  String bdNotifyManualBuild(String state);

  /// No description provided for @bdPrFilterMine.
  ///
  /// In ko, this message translates to:
  /// **'내 PR'**
  String get bdPrFilterMine;

  /// No description provided for @bdPrFilterReview.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 요청'**
  String get bdPrFilterReview;

  /// No description provided for @bdPrFilterOpen.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get bdPrFilterOpen;

  /// No description provided for @bdPrListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'열린 PR이 없습니다'**
  String get bdPrListEmpty;

  /// No description provided for @bdPrCurrentBranch.
  ///
  /// In ko, this message translates to:
  /// **'현재 브랜치'**
  String get bdPrCurrentBranch;

  /// No description provided for @bdPrCheckout.
  ///
  /// In ko, this message translates to:
  /// **'이 PR 브랜치로 체크아웃'**
  String get bdPrCheckout;

  /// No description provided for @bdPrCheckoutWhy.
  ///
  /// In ko, this message translates to:
  /// **'PR 브랜치를 내 컴퓨터로 가져와 전환합니다. 직접 실행해 보거나 고칠 때 씁니다.'**
  String get bdPrCheckoutWhy;

  /// No description provided for @bdDonePrCheckout.
  ///
  /// In ko, this message translates to:
  /// **'PR #{number}의 {branch}(으)로 전환했습니다'**
  String bdDonePrCheckout(int number, String branch);

  /// No description provided for @bdReleasesTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스'**
  String get bdReleasesTitle;

  /// No description provided for @bdReleasesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스가 없습니다'**
  String get bdReleasesEmpty;

  /// No description provided for @bdReleasesLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 목록을 불러오지 못했습니다'**
  String get bdReleasesLoadFailed;

  /// No description provided for @bdReleaseLatestPill.
  ///
  /// In ko, this message translates to:
  /// **'최신'**
  String get bdReleaseLatestPill;

  /// No description provided for @bdReleaseDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안'**
  String get bdReleaseDraft;

  /// No description provided for @bdReleaseMakeFinal.
  ///
  /// In ko, this message translates to:
  /// **'정식 릴리스로 바꾸기'**
  String get bdReleaseMakeFinal;

  /// No description provided for @bdReleaseMakePrerelease.
  ///
  /// In ko, this message translates to:
  /// **'프리릴리스로 바꾸기'**
  String get bdReleaseMakePrerelease;

  /// No description provided for @bdReleasePublishDraft.
  ///
  /// In ko, this message translates to:
  /// **'초안 게시'**
  String get bdReleasePublishDraft;

  /// No description provided for @bdReleaseDelete.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 삭제'**
  String get bdReleaseDelete;

  /// No description provided for @bdReleaseDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 삭제할까요?'**
  String bdReleaseDeleteTitle(String tag);

  /// No description provided for @bdReleaseDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스와 올라간 파일이 사라집니다. 이미 받아 간 사람이 있을 수 있습니다.'**
  String get bdReleaseDeleteMessage;

  /// No description provided for @bdReleaseDeleteTagToo.
  ///
  /// In ko, this message translates to:
  /// **'GitHub의 {tag} 태그도 삭제 (로컬 태그는 남음)'**
  String bdReleaseDeleteTagToo(String tag);

  /// No description provided for @bdDoneReleaseDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 삭제했습니다'**
  String bdDoneReleaseDeleted(String tag);

  /// No description provided for @bdDoneReleaseMadeFinal.
  ///
  /// In ko, this message translates to:
  /// **'{tag}을(를) 정식 릴리스로 바꿨습니다'**
  String bdDoneReleaseMadeFinal(String tag);

  /// No description provided for @bdDoneReleaseMadePrerelease.
  ///
  /// In ko, this message translates to:
  /// **'{tag}을(를) 프리릴리스로 바꿨습니다'**
  String bdDoneReleaseMadePrerelease(String tag);

  /// No description provided for @bdDoneReleasePublished.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 초안을 게시했습니다'**
  String bdDoneReleasePublished(String tag);

  /// No description provided for @bdNotesEditTab.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get bdNotesEditTab;

  /// No description provided for @bdNotesPreviewTab.
  ///
  /// In ko, this message translates to:
  /// **'미리 보기'**
  String get bdNotesPreviewTab;

  /// No description provided for @bdNotesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'내용이 없습니다'**
  String get bdNotesEmpty;

  /// No description provided for @bdTagVersionMismatch.
  ///
  /// In ko, this message translates to:
  /// **'{file}의 버전은 {version}인데 태그는 {tag}입니다.'**
  String bdTagVersionMismatch(String file, String version, String tag);

  /// No description provided for @bdTagVersionMismatchWhy.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 태그는 버전을 먼저 올린 커밋에 달아야 합니다 — 릴리스 마법사가 버전 올림 PR부터 태그까지 차례로 합니다.'**
  String get bdTagVersionMismatchWhy;

  /// No description provided for @bdTagVersionMismatchCi.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소는 태그를 push하면 CI가 릴리스를 만드는데, 버전이 다르면 CI가 멈춥니다.'**
  String get bdTagVersionMismatchCi;

  /// No description provided for @bdTagVersionMismatchBlocked.
  ///
  /// In ko, this message translates to:
  /// **'그래서 push는 막았습니다. 로컬에만 만들려면 push를 끄세요.'**
  String get bdTagVersionMismatchBlocked;

  /// No description provided for @bdTagOpenReleaseWizard.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 마법사 열기'**
  String get bdTagOpenReleaseWizard;

  /// No description provided for @bdTabHistory.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get bdTabHistory;

  /// No description provided for @bdMenuAutoFetch.
  ///
  /// In ko, this message translates to:
  /// **'자동 fetch (5분마다·돌아올 때)'**
  String get bdMenuAutoFetch;

  /// No description provided for @bdChangesAmendToggle.
  ///
  /// In ko, this message translates to:
  /// **'직전 커밋 고치기'**
  String get bdChangesAmendToggle;

  /// No description provided for @bdChangesAmend.
  ///
  /// In ko, this message translates to:
  /// **'직전 커밋 고치기'**
  String get bdChangesAmend;

  /// No description provided for @bdChangesAmendPushedWarning.
  ///
  /// In ko, this message translates to:
  /// **'이미 원격에 올린 커밋입니다. 고치면 기록이 갈라져 강제 push(force-with-lease)가 필요합니다.'**
  String get bdChangesAmendPushedWarning;

  /// No description provided for @bdDoneAmend.
  ///
  /// In ko, this message translates to:
  /// **'직전 커밋을 고쳤습니다'**
  String get bdDoneAmend;

  /// No description provided for @bdChangesDiscard.
  ///
  /// In ko, this message translates to:
  /// **'변경 취소'**
  String get bdChangesDiscard;

  /// No description provided for @bdChangesDiscardMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}의 커밋하지 않은 변경을 버리고 마지막으로 스테이징(또는 커밋)한 상태로 되돌립니다. 되돌릴 수 없습니다.'**
  String bdChangesDiscardMessage(String path);

  /// No description provided for @bdChangesDeleteUntracked.
  ///
  /// In ko, this message translates to:
  /// **'파일 삭제'**
  String get bdChangesDeleteUntracked;

  /// No description provided for @bdChangesDeleteUntrackedMessage.
  ///
  /// In ko, this message translates to:
  /// **'git이 추적하지 않는 {path}을(를) 지웁니다. 휴지통으로 가지 않습니다.'**
  String bdChangesDeleteUntrackedMessage(String path);

  /// No description provided for @bdConflictUseMine.
  ///
  /// In ko, this message translates to:
  /// **'내 것 사용'**
  String get bdConflictUseMine;

  /// No description provided for @bdConflictUseIncoming.
  ///
  /// In ko, this message translates to:
  /// **'들어오는 것 사용'**
  String get bdConflictUseIncoming;

  /// No description provided for @bdConflictByBlock.
  ///
  /// In ko, this message translates to:
  /// **'구간별로 해결'**
  String get bdConflictByBlock;

  /// No description provided for @bdConflictSheetTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 충돌 해결'**
  String bdConflictSheetTitle(String name);

  /// No description provided for @bdConflictBlockTitle.
  ///
  /// In ko, this message translates to:
  /// **'충돌 {index}/{total}'**
  String bdConflictBlockTitle(int index, int total);

  /// No description provided for @bdConflictSideMine.
  ///
  /// In ko, this message translates to:
  /// **'내 것'**
  String get bdConflictSideMine;

  /// No description provided for @bdConflictSideIncoming.
  ///
  /// In ko, this message translates to:
  /// **'들어오는 것'**
  String get bdConflictSideIncoming;

  /// No description provided for @bdConflictKeepBoth.
  ///
  /// In ko, this message translates to:
  /// **'둘 다 유지 (위, 아래 순서)'**
  String get bdConflictKeepBoth;

  /// No description provided for @bdConflictEmptySide.
  ///
  /// In ko, this message translates to:
  /// **'(비어 있음)'**
  String get bdConflictEmptySide;

  /// No description provided for @bdConflictPickHint.
  ///
  /// In ko, this message translates to:
  /// **'구간마다 어느 쪽을 쓸지 골라 주세요. {left}개 남았습니다.'**
  String bdConflictPickHint(int left);

  /// No description provided for @bdConflictApply.
  ///
  /// In ko, this message translates to:
  /// **'적용하고 해결됨 표시'**
  String get bdConflictApply;

  /// No description provided for @bdConflictApplyNote.
  ///
  /// In ko, this message translates to:
  /// **'고른 대로 파일을 다시 쓰고 git add 합니다. 직접 고쳐 쓰려면 편집기로 여세요.'**
  String get bdConflictApplyNote;

  /// No description provided for @bdConflictBroken.
  ///
  /// In ko, this message translates to:
  /// **'충돌 표시가 온전하지 않아 앱에서 읽을 수 없습니다. 편집기에서 직접 고쳐 주세요.'**
  String get bdConflictBroken;

  /// No description provided for @bdConflictNone.
  ///
  /// In ko, this message translates to:
  /// **'이 파일에는 충돌 표시가 없습니다. 이미 고쳤다면 \'해결됨 표시\'만 누르면 됩니다.'**
  String get bdConflictNone;

  /// No description provided for @bdConflictUnreadable.
  ///
  /// In ko, this message translates to:
  /// **'파일을 읽을 수 없습니다 (이진 파일이거나 삭제된 파일일 수 있습니다). \'내 것 사용\' 또는 \'들어오는 것 사용\'으로 해결하세요.'**
  String get bdConflictUnreadable;

  /// No description provided for @bdDoneConflictResolved.
  ///
  /// In ko, this message translates to:
  /// **'{name}: 충돌 해결됨'**
  String bdDoneConflictResolved(String name);

  /// No description provided for @bdChangesOperationTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 작업이 끝나지 않았습니다'**
  String get bdChangesOperationTitle;

  /// No description provided for @bdChangesOperationMessage.
  ///
  /// In ko, this message translates to:
  /// **'충돌은 모두 해결됐습니다. 위의 \'계속\'으로 마무리하거나 \'중단\'으로 시작하기 전 상태로 되돌리세요.'**
  String get bdChangesOperationMessage;

  /// No description provided for @bdConflictReopen.
  ///
  /// In ko, this message translates to:
  /// **'다시 충돌 상태로'**
  String get bdConflictReopen;

  /// No description provided for @bdConflictReopenMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}을(를) 충돌이 난 직후의 모습으로 되돌립니다. 지금까지 해결한 내용은 사라지고, 충돌 표시가 다시 들어갑니다.'**
  String bdConflictReopenMessage(String path);

  /// No description provided for @bdConflictReopenConfirm.
  ///
  /// In ko, this message translates to:
  /// **'다시 충돌'**
  String get bdConflictReopenConfirm;

  /// No description provided for @bdConflictMarkersLeftTitle.
  ///
  /// In ko, this message translates to:
  /// **'충돌 표시가 남아 있습니다'**
  String get bdConflictMarkersLeftTitle;

  /// No description provided for @bdConflictMarkersLeftMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}에 아직 `<<<<<<<` 표시가 {count}군데 남아 있습니다. 이대로 해결됨으로 표시하면 표시가 그대로 커밋됩니다. 먼저 \'구간별로 해결\'이나 편집기로 정리하세요.'**
  String bdConflictMarkersLeftMessage(String path, int count);

  /// No description provided for @bdConflictMarkersLeftConfirm.
  ///
  /// In ko, this message translates to:
  /// **'그래도 해결됨 표시'**
  String get bdConflictMarkersLeftConfirm;

  /// No description provided for @bdDoneFileAction.
  ///
  /// In ko, this message translates to:
  /// **'{name}: 완료'**
  String bdDoneFileAction(String name);

  /// No description provided for @bdStashTitle.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장 (stash)'**
  String get bdStashTitle;

  /// No description provided for @bdStashSave.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장'**
  String get bdStashSave;

  /// No description provided for @bdStashSaveFile.
  ///
  /// In ko, this message translates to:
  /// **'이 파일만 임시 저장'**
  String get bdStashSaveFile;

  /// No description provided for @bdStashFileToStage.
  ///
  /// In ko, this message translates to:
  /// **'스테이징으로 꺼내기'**
  String get bdStashFileToStage;

  /// No description provided for @bdStashFileOverwriteMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}에 이미 변경이 있습니다. 임시 저장한 내용으로 덮어씁니다.'**
  String bdStashFileOverwriteMessage(String path);

  /// No description provided for @bdStashEmpty.
  ///
  /// In ko, this message translates to:
  /// **'파일 목록을 불러오지 못했습니다.'**
  String get bdStashEmpty;

  /// No description provided for @bdStashWhy.
  ///
  /// In ko, this message translates to:
  /// **'변경 {count}개를 커밋하지 않고 따로 치워 둡니다. 추적하지 않는 파일도 함께 저장합니다. 나중에 \'다시 적용\'으로 되살립니다.'**
  String bdStashWhy(int count);

  /// No description provided for @bdStashMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get bdStashMessageLabel;

  /// No description provided for @bdStashPop.
  ///
  /// In ko, this message translates to:
  /// **'적용하고 지우기 (pop)'**
  String get bdStashPop;

  /// No description provided for @bdStashApply.
  ///
  /// In ko, this message translates to:
  /// **'적용만 하기 (apply)'**
  String get bdStashApply;

  /// No description provided for @bdStashDrop.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get bdStashDrop;

  /// No description provided for @bdStashDropTitle.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장을 삭제할까요?'**
  String get bdStashDropTitle;

  /// No description provided for @bdStashDropMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{text}\'에 저장한 변경이 사라집니다.'**
  String bdStashDropMessage(String text);

  /// No description provided for @bdStashAndRetry.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장하고 다시'**
  String get bdStashAndRetry;

  /// No description provided for @bdStashAutoMessage.
  ///
  /// In ko, this message translates to:
  /// **'Branch Dock: 자동 임시 저장'**
  String get bdStashAutoMessage;

  /// No description provided for @bdDoneStashSaved.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장했습니다'**
  String get bdDoneStashSaved;

  /// No description provided for @bdDoneStashApplied.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장을 적용했습니다'**
  String get bdDoneStashApplied;

  /// No description provided for @bdDoneStashDropped.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장을 삭제했습니다'**
  String get bdDoneStashDropped;

  /// No description provided for @bdDoneStashAndRetry.
  ///
  /// In ko, this message translates to:
  /// **'변경을 임시 저장하고 다시 실행했습니다. 변경 탭의 임시 저장에서 되살릴 수 있습니다.'**
  String get bdDoneStashAndRetry;

  /// No description provided for @bdPushOptionsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'Push 옵션'**
  String get bdPushOptionsTooltip;

  /// No description provided for @bdPushOptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'Push 옵션'**
  String get bdPushOptionsTitle;

  /// No description provided for @bdPushFollowTags.
  ///
  /// In ko, this message translates to:
  /// **'태그도 함께 push (--follow-tags)'**
  String get bdPushFollowTags;

  /// No description provided for @bdPushFollowTagsWhy.
  ///
  /// In ko, this message translates to:
  /// **'올리는 커밋에 달린 주석 태그를 함께 올립니다. 이 저장소에만 적용됩니다.'**
  String get bdPushFollowTagsWhy;

  /// No description provided for @bdPushForceTitle.
  ///
  /// In ko, this message translates to:
  /// **'강제 push (force-with-lease)'**
  String get bdPushForceTitle;

  /// No description provided for @bdPushForceWhy.
  ///
  /// In ko, this message translates to:
  /// **'amend나 rebase로 이미 올린 커밋을 고쳤을 때만 씁니다. 내가 모르는 원격 커밋이 있으면 git이 거부해서 다른 사람의 작업을 덮어쓰지 않습니다.'**
  String get bdPushForceWhy;

  /// No description provided for @bdPushForceBlockedDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 브랜치({branch})에서는 강제 push를 막았습니다 — 다른 사람의 기록을 덮어쓸 수 있습니다.'**
  String bdPushForceBlockedDefault(String branch);

  /// No description provided for @bdPushForce.
  ///
  /// In ko, this message translates to:
  /// **'강제 push'**
  String get bdPushForce;

  /// No description provided for @bdPushForceConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{branch}을(를) 강제 push할까요?'**
  String bdPushForceConfirmTitle(String branch);

  /// No description provided for @bdPushForceConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'{upstream}의 기록을 내 {branch}로 바꿉니다. 내가 fetch한 뒤 누가 push했다면 git이 거부합니다.'**
  String bdPushForceConfirmMessage(String branch, String upstream);

  /// No description provided for @bdOperationSkip.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get bdOperationSkip;

  /// No description provided for @bdOperationSkipTooltip.
  ///
  /// In ko, this message translates to:
  /// **'충돌 난 이 커밋을 빼고 rebase를 계속합니다'**
  String get bdOperationSkipTooltip;

  /// No description provided for @bdDoneSkip.
  ///
  /// In ko, this message translates to:
  /// **'커밋을 건너뛰었습니다'**
  String get bdDoneSkip;

  /// No description provided for @bdBranchesSetUpstream.
  ///
  /// In ko, this message translates to:
  /// **'추적 브랜치 설정'**
  String get bdBranchesSetUpstream;

  /// No description provided for @bdBranchesSetUpstreamWhy.
  ///
  /// In ko, this message translates to:
  /// **'{branch}이(가) Push·Pull할 원격 브랜치를 정합니다.'**
  String bdBranchesSetUpstreamWhy(String branch);

  /// No description provided for @bdBranchesUpstreamLabel.
  ///
  /// In ko, this message translates to:
  /// **'원격 브랜치'**
  String get bdBranchesUpstreamLabel;

  /// No description provided for @bdDoneSetUpstream.
  ///
  /// In ko, this message translates to:
  /// **'{branch}의 추적 브랜치를 {upstream}(으)로 정했습니다'**
  String bdDoneSetUpstream(String branch, String upstream);

  /// No description provided for @bdBranchesCleanup.
  ///
  /// In ko, this message translates to:
  /// **'병합된 브랜치 정리'**
  String get bdBranchesCleanup;

  /// No description provided for @bdCleanupWhy.
  ///
  /// In ko, this message translates to:
  /// **'{base}에 이미 병합됐거나 원격에서 지워진 로컬 브랜치입니다. 원격 브랜치는 건드리지 않습니다.'**
  String bdCleanupWhy(String base);

  /// No description provided for @bdCleanupMerged.
  ///
  /// In ko, this message translates to:
  /// **'병합됨'**
  String get bdCleanupMerged;

  /// No description provided for @bdCleanupGoneNotMerged.
  ///
  /// In ko, this message translates to:
  /// **'원격에서 삭제됨 · 병합 안 됨 — 지우면 커밋을 찾기 어려워집니다'**
  String get bdCleanupGoneNotMerged;

  /// No description provided for @bdCleanupConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 삭제'**
  String bdCleanupConfirm(int count);

  /// No description provided for @bdCleanupNothing.
  ///
  /// In ko, this message translates to:
  /// **'정리할 브랜치가 없습니다 ({base}에 병합된 브랜치 없음)'**
  String bdCleanupNothing(String base);

  /// No description provided for @bdDoneCleanup.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 {count}개를 정리했습니다'**
  String bdDoneCleanup(int count);

  /// No description provided for @bdTagsCommitsSince.
  ///
  /// In ko, this message translates to:
  /// **'이전 태그 이후 커밋'**
  String get bdTagsCommitsSince;

  /// No description provided for @bdTagsCommitsBetween.
  ///
  /// In ko, this message translates to:
  /// **'{from} → {to}'**
  String bdTagsCommitsBetween(String from, String to);

  /// No description provided for @bdTagsCommitsUpTo.
  ///
  /// In ko, this message translates to:
  /// **'{tag}까지'**
  String bdTagsCommitsUpTo(String tag);

  /// No description provided for @bdTagsCommitsCount.
  ///
  /// In ko, this message translates to:
  /// **'커밋 {count}개'**
  String bdTagsCommitsCount(int count);

  /// No description provided for @bdTagsCheckout.
  ///
  /// In ko, this message translates to:
  /// **'이 태그로 이동'**
  String get bdTagsCheckout;

  /// No description provided for @bdTagsCheckoutTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tag}(으)로 이동할까요?'**
  String bdTagsCheckoutTitle(String tag);

  /// No description provided for @bdTagsCheckoutMessage.
  ///
  /// In ko, this message translates to:
  /// **'태그 위치의 파일을 그대로 볼 수 있습니다. 이때는 어느 브랜치에도 있지 않은 \'분리된 HEAD\' 상태라, 여기서 커밋하려면 먼저 브랜치를 만드세요.'**
  String get bdTagsCheckoutMessage;

  /// No description provided for @bdDoneCheckoutTag.
  ///
  /// In ko, this message translates to:
  /// **'{tag}(으)로 이동했습니다'**
  String bdDoneCheckoutTag(String tag);

  /// No description provided for @bdBannerDetached.
  ///
  /// In ko, this message translates to:
  /// **'어느 브랜치에도 있지 않습니다. 여기서 커밋하려면 브랜치를 만드세요'**
  String get bdBannerDetached;

  /// No description provided for @bdHistoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get bdHistoryTitle;

  /// No description provided for @bdHistoryUnpushed.
  ///
  /// In ko, this message translates to:
  /// **'↑ 올리지 않은 커밋 {count}'**
  String bdHistoryUnpushed(int count);

  /// No description provided for @bdHistoryNotPushed.
  ///
  /// In ko, this message translates to:
  /// **'아직 올리지 않음'**
  String get bdHistoryNotPushed;

  /// No description provided for @bdHistoryCopyHash.
  ///
  /// In ko, this message translates to:
  /// **'해시 복사'**
  String get bdHistoryCopyHash;

  /// No description provided for @bdHistoryBranchHere.
  ///
  /// In ko, this message translates to:
  /// **'여기서 브랜치 만들기'**
  String get bdHistoryBranchHere;

  /// No description provided for @bdHistoryTagHere.
  ///
  /// In ko, this message translates to:
  /// **'여기에 태그 달기'**
  String get bdHistoryTagHere;

  /// No description provided for @bdHelpLinkStashing.
  ///
  /// In ko, this message translates to:
  /// **'Pro Git — Stashing과 Cleaning'**
  String get bdHelpLinkStashing;

  /// No description provided for @bdHelpCaptionStash.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경 W를 stash 목록 맨 위에 치워 둠 — main은 그대로'**
  String get bdHelpCaptionStash;

  /// No description provided for @bdHelpStashTitle.
  ///
  /// In ko, this message translates to:
  /// **'Stash (임시 저장)'**
  String get bdHelpStashTitle;

  /// No description provided for @bdHelpStashWord.
  ///
  /// In ko, this message translates to:
  /// **'stash는 \'넣어 두다, 숨겨 두다\'. 잠깐 서랍에 치워 두는 것.'**
  String get bdHelpStashWord;

  /// No description provided for @bdHelpStashInGit.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경을 브랜치 기록에 남기지 않고 따로 저장한 뒤, 작업 트리를 깨끗하게 되돌립니다. 저장한 변경은 목록에 쌓이고(가장 최근 것이 맨 위), 나중에 어느 브랜치에서든 다시 적용할 수 있습니다.'**
  String get bdHelpStashInGit;

  /// No description provided for @bdHelpStashWhy.
  ///
  /// In ko, this message translates to:
  /// **'하던 일을 커밋하기엔 이른데 브랜치를 바꾸거나 Pull해야 할 때 씁니다. \'pop\'은 적용하고 목록에서 지우고, \'apply\'는 목록에 남겨 둡니다. 오래 두면 무엇이었는지 잊기 쉬우니 메모를 남기세요.'**
  String get bdHelpStashWhy;

  /// No description provided for @bdHelpCaptionDetached.
  ///
  /// In ko, this message translates to:
  /// **'HEAD가 브랜치가 아니라 v1.0.0 커밋을 직접 가리킴'**
  String get bdHelpCaptionDetached;

  /// No description provided for @bdHelpDetachedTitle.
  ///
  /// In ko, this message translates to:
  /// **'분리된 HEAD (detached HEAD)'**
  String get bdHelpDetachedTitle;

  /// No description provided for @bdHelpDetachedWord.
  ///
  /// In ko, this message translates to:
  /// **'detached는 \'떨어진, 분리된\'. HEAD는 \'지금 보고 있는 곳\'.'**
  String get bdHelpDetachedWord;

  /// No description provided for @bdHelpDetachedInGit.
  ///
  /// In ko, this message translates to:
  /// **'보통 HEAD는 브랜치 이름표를 가리키고, 커밋하면 그 이름표가 앞으로 갑니다. 태그나 커밋으로 직접 이동하면 HEAD가 브랜치에서 떨어져 커밋을 직접 가리킵니다.'**
  String get bdHelpDetachedInGit;

  /// No description provided for @bdHelpDetachedWhy.
  ///
  /// In ko, this message translates to:
  /// **'옛 버전을 실행해 보거나 비교할 때 안전하게 쓸 수 있습니다. 여기서 커밋하면 어느 브랜치에도 속하지 않아 다른 곳으로 옮기면 찾기 어려워지니, 커밋하려면 먼저 \'여기서 브랜치 만들기\'를 하세요.'**
  String get bdHelpDetachedWhy;

  /// No description provided for @bdHelpForceTitle.
  ///
  /// In ko, this message translates to:
  /// **'강제 push (force-with-lease)'**
  String get bdHelpForceTitle;

  /// No description provided for @bdHelpForceWord.
  ///
  /// In ko, this message translates to:
  /// **'force는 \'억지로\', lease는 \'임대 계약\' — 내가 본 상태 그대로일 때만 바꾼다는 조건.'**
  String get bdHelpForceWord;

  /// No description provided for @bdHelpForceInGit.
  ///
  /// In ko, this message translates to:
  /// **'amend나 rebase로 이미 올린 커밋을 고치면 원격 기록과 갈라져 보통 push가 거부됩니다. 강제 push는 원격 브랜치를 내 기록으로 바꿉니다. --force-with-lease는 원격이 내가 마지막으로 fetch한 상태 그대로일 때만 바꾸고, 그 사이 누가 push했으면 거부합니다.'**
  String get bdHelpForceInGit;

  /// No description provided for @bdHelpForceWhy.
  ///
  /// In ko, this message translates to:
  /// **'혼자 쓰는 작업 브랜치에서 기록을 정리했을 때만 씁니다. 여러 사람이 쓰는 브랜치, 특히 main에서는 쓰지 않습니다. 이 앱은 --force(무조건)는 제공하지 않고, 기본 브랜치에서는 막습니다.'**
  String get bdHelpForceWhy;

  /// No description provided for @bdMenuBrowse.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 저장소 열기'**
  String get bdMenuBrowse;

  /// No description provided for @bdMenuSnapRight.
  ///
  /// In ko, this message translates to:
  /// **'화면 오른쪽에 붙이기'**
  String get bdMenuSnapRight;

  /// No description provided for @bdMenuSnapLeft.
  ///
  /// In ko, this message translates to:
  /// **'화면 왼쪽에 붙이기'**
  String get bdMenuSnapLeft;

  /// No description provided for @bdStartInitRepository.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더를 git 저장소로 만들기'**
  String get bdStartInitRepository;

  /// No description provided for @bdCloneTitle.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에서 복제'**
  String get bdCloneTitle;

  /// No description provided for @bdCloneSearch.
  ///
  /// In ko, this message translates to:
  /// **'내 저장소 찾기'**
  String get bdCloneSearch;

  /// No description provided for @bdCloneEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장소가 없습니다'**
  String get bdCloneEmpty;

  /// No description provided for @bdCloneNoFolder.
  ///
  /// In ko, this message translates to:
  /// **'복제할 위치를 고르세요'**
  String get bdCloneNoFolder;

  /// No description provided for @bdCloneChooseFolder.
  ///
  /// In ko, this message translates to:
  /// **'위치 고르기'**
  String get bdCloneChooseFolder;

  /// No description provided for @bdCloneExists.
  ///
  /// In ko, this message translates to:
  /// **'이미 있는 폴더입니다: {path}'**
  String bdCloneExists(String path);

  /// No description provided for @bdCloneConfirm.
  ///
  /// In ko, this message translates to:
  /// **'복제하고 열기'**
  String get bdCloneConfirm;

  /// No description provided for @bdCloneRunning.
  ///
  /// In ko, this message translates to:
  /// **'복제하는 중…'**
  String get bdCloneRunning;

  /// No description provided for @bdLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 로그인'**
  String get bdLoginTitle;

  /// No description provided for @bdLoginSsh.
  ///
  /// In ko, this message translates to:
  /// **'SSH'**
  String get bdLoginSsh;

  /// No description provided for @bdLoginHttps.
  ///
  /// In ko, this message translates to:
  /// **'HTTPS'**
  String get bdLoginHttps;

  /// No description provided for @bdLoginSshRecommended.
  ///
  /// In ko, this message translates to:
  /// **'SSH 권장'**
  String get bdLoginSshRecommended;

  /// No description provided for @bdLoginSshWhy.
  ///
  /// In ko, this message translates to:
  /// **'SSH 주소의 원격이나 SSH로 접속한 환경에서는 HTTPS로 로그인하면 push 때 인증이 따로 놀 수 있습니다.'**
  String get bdLoginSshWhy;

  /// No description provided for @bdLoginStepKey.
  ///
  /// In ko, this message translates to:
  /// **'SSH 키 확인'**
  String get bdLoginStepKey;

  /// No description provided for @bdLoginStepKeyFound.
  ///
  /// In ko, this message translates to:
  /// **'이 키를 GitHub에 올립니다'**
  String get bdLoginStepKeyFound;

  /// No description provided for @bdLoginStepKeyMissing.
  ///
  /// In ko, this message translates to:
  /// **'키가 없습니다. 터미널에서 아래 명령으로 만드세요 (암호 문구 권장). 앱은 키와 암호 문구를 받지 않습니다.'**
  String get bdLoginStepKeyMissing;

  /// No description provided for @bdLoginStepLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get bdLoginStepLogin;

  /// No description provided for @bdLoginStepLoginWhy.
  ///
  /// In ko, this message translates to:
  /// **'브라우저에서 GitHub에 로그인하고 일회용 코드를 넣습니다.'**
  String get bdLoginStepLoginWhy;

  /// No description provided for @bdLoginLoggedIn.
  ///
  /// In ko, this message translates to:
  /// **'로그인되어 있습니다'**
  String get bdLoginLoggedIn;

  /// No description provided for @bdLoginStart.
  ///
  /// In ko, this message translates to:
  /// **'브라우저로 로그인'**
  String get bdLoginStart;

  /// No description provided for @bdLoginDeviceHowTo.
  ///
  /// In ko, this message translates to:
  /// **'브라우저가 열리지 않거나 원격 서버라면, 다른 기기의 브라우저에서 아래 주소를 열고 이 코드를 넣으세요.'**
  String get bdLoginDeviceHowTo;

  /// No description provided for @bdLoginStepUpload.
  ///
  /// In ko, this message translates to:
  /// **'공개 키 올리기'**
  String get bdLoginStepUpload;

  /// No description provided for @bdLoginStepUploadWhy.
  ///
  /// In ko, this message translates to:
  /// **'골라 둔 공개 키를 내 GitHub 계정에 등록합니다. 이미 등록돼 있으면 건너뜁니다.'**
  String get bdLoginStepUploadWhy;

  /// No description provided for @bdLoginUploadKey.
  ///
  /// In ko, this message translates to:
  /// **'공개 키 올리기'**
  String get bdLoginUploadKey;

  /// No description provided for @bdLoginNeedsKeyScope.
  ///
  /// In ko, this message translates to:
  /// **'키를 올릴 권한이 없습니다. 터미널에서 아래 명령으로 권한을 더한 뒤 다시 시도하세요.'**
  String get bdLoginNeedsKeyScope;

  /// No description provided for @bdLoginStepTest.
  ///
  /// In ko, this message translates to:
  /// **'연결 확인'**
  String get bdLoginStepTest;

  /// No description provided for @bdLoginStepTestWhy.
  ///
  /// In ko, this message translates to:
  /// **'GitHub에 SSH로 접속해 봅니다. 처음이면 github.com 호스트 키를 known_hosts에 더합니다.'**
  String get bdLoginStepTestWhy;

  /// No description provided for @bdLoginSshFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결하지 못했습니다. 키가 등록됐는지, ssh-agent에 키가 올라가 있는지 확인하세요.'**
  String get bdLoginSshFailed;

  /// No description provided for @bdLoginTest.
  ///
  /// In ko, this message translates to:
  /// **'연결 확인'**
  String get bdLoginTest;

  /// No description provided for @bdLoginChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인하는 중…'**
  String get bdLoginChecking;

  /// No description provided for @bdLoginStepProtocol.
  ///
  /// In ko, this message translates to:
  /// **'git 프로토콜을 SSH로'**
  String get bdLoginStepProtocol;

  /// No description provided for @bdLoginStepProtocolWhy.
  ///
  /// In ko, this message translates to:
  /// **'gh가 앞으로 만드는 원격 주소를 SSH로 씁니다. 이미 있는 HTTPS 원격은 원격 탭의 URL 바꾸기에서 SSH로 바꿀 수 있습니다.'**
  String get bdLoginStepProtocolWhy;

  /// No description provided for @bdLoginUseSshProtocol.
  ///
  /// In ko, this message translates to:
  /// **'SSH로 설정'**
  String get bdLoginUseSshProtocol;

  /// No description provided for @bdLoginAgentTip.
  ///
  /// In ko, this message translates to:
  /// **'암호 문구를 매번 묻지 않게 하려면 macOS는 ssh-add --apple-use-keychain, 그 밖에는 ssh-agent를 쓰세요.'**
  String get bdLoginAgentTip;

  /// No description provided for @bdDoneProtocolSsh.
  ///
  /// In ko, this message translates to:
  /// **'gh의 git 프로토콜을 SSH로 바꿨습니다'**
  String get bdDoneProtocolSsh;

  /// No description provided for @bdForkTitle.
  ///
  /// In ko, this message translates to:
  /// **'{parent}의 fork입니다'**
  String bdForkTitle(String parent);

  /// No description provided for @bdForkAddWhy.
  ///
  /// In ko, this message translates to:
  /// **'원본 저장소를 upstream 원격으로 추가하면 원본의 새 커밋을 가져올 수 있습니다.'**
  String get bdForkAddWhy;

  /// No description provided for @bdForkSyncWhy.
  ///
  /// In ko, this message translates to:
  /// **'원본(upstream)의 새 커밋을 가져와 현재 브랜치로 병합합니다.'**
  String get bdForkSyncWhy;

  /// No description provided for @bdForkAddUpstream.
  ///
  /// In ko, this message translates to:
  /// **'upstream 추가'**
  String get bdForkAddUpstream;

  /// No description provided for @bdForkSync.
  ///
  /// In ko, this message translates to:
  /// **'upstream에서 가져오기'**
  String get bdForkSync;

  /// No description provided for @bdRemotesGhDefault.
  ///
  /// In ko, this message translates to:
  /// **'gh가 쓰는 저장소 (PR·릴리스·CI)'**
  String get bdRemotesGhDefault;

  /// No description provided for @bdRemotesGhDefaultNone.
  ///
  /// In ko, this message translates to:
  /// **'정해지지 않음'**
  String get bdRemotesGhDefaultNone;

  /// No description provided for @bdDoneGhDefault.
  ///
  /// In ko, this message translates to:
  /// **'gh가 {repo}을(를) 쓰도록 정했습니다'**
  String bdDoneGhDefault(String repo);

  /// No description provided for @bdReleaseNeedsRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격이 없어 릴리스할 수 없습니다. 원격 탭에서 먼저 올리세요.'**
  String get bdReleaseNeedsRemote;

  /// No description provided for @bdReleaseNeedsFiles.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 워크플로가 쓰는 파일이 없어 릴리스할 수 없습니다: {files}. 태그를 달아도 CI가 패키지를 만들지 못합니다.'**
  String bdReleaseNeedsFiles(String files);

  /// No description provided for @bdReleaseDirectOnlyNotGitHub.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 저장소가 아니라서 바로 커밋 방식(점검 → 버전 → 태그)으로 진행합니다. PR·릴리스 노트·CI는 호스팅 웹에서 하세요.'**
  String get bdReleaseDirectOnlyNotGitHub;

  /// No description provided for @bdReleaseDirectOnly.
  ///
  /// In ko, this message translates to:
  /// **'gh를 쓸 수 없어 바로 커밋 방식만 됩니다.'**
  String get bdReleaseDirectOnly;

  /// No description provided for @bdReleaseDirectMode.
  ///
  /// In ko, this message translates to:
  /// **'바로 커밋 방식'**
  String get bdReleaseDirectMode;

  /// No description provided for @bdReleaseDirectModeWhy.
  ///
  /// In ko, this message translates to:
  /// **'PR 없이 {branch}에 버전 올림을 커밋하고 커밋과 태그를 함께 push합니다. 혼자 쓰는 저장소에서만 쓰세요 — 보호된 브랜치면 push가 거부됩니다.'**
  String bdReleaseDirectModeWhy(String branch);

  /// No description provided for @bdTagCheckSyncedDirect.
  ///
  /// In ko, this message translates to:
  /// **'{branch}에 있고 원격에 내게 없는 커밋이 없다'**
  String bdTagCheckSyncedDirect(String branch);

  /// No description provided for @bdVersionUsesScript.
  ///
  /// In ko, this message translates to:
  /// **'저장소의 scripts/bump-version.sh로 버전을 올립니다 (lock 파일 포함, 규약과 같은 결과).'**
  String get bdVersionUsesScript;

  /// No description provided for @bdVersionLockFiles.
  ///
  /// In ko, this message translates to:
  /// **'함께 맞출 lock 파일: {files}'**
  String bdVersionLockFiles(String files);

  /// No description provided for @bdVersionFileChoose.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일 바꾸기'**
  String get bdVersionFileChoose;

  /// No description provided for @bdVersionFileCustom.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일: {path} (직접 지정)'**
  String bdVersionFileCustom(String path);

  /// No description provided for @bdVersionFileTitle.
  ///
  /// In ko, this message translates to:
  /// **'버전 파일 지정'**
  String get bdVersionFileTitle;

  /// No description provided for @bdVersionFileWhy.
  ///
  /// In ko, this message translates to:
  /// **'자동으로 찾지 못하거나 다른 파일을 쓸 때 정합니다. 정규식의 첫 번째 괄호가 버전입니다. 이 저장소에만 적용됩니다.'**
  String get bdVersionFileWhy;

  /// No description provided for @bdVersionFilePath.
  ///
  /// In ko, this message translates to:
  /// **'파일 (저장소 기준 경로)'**
  String get bdVersionFilePath;

  /// No description provided for @bdVersionFilePattern.
  ///
  /// In ko, this message translates to:
  /// **'버전 줄 정규식'**
  String get bdVersionFilePattern;

  /// No description provided for @bdVersionFileFound.
  ///
  /// In ko, this message translates to:
  /// **'찾았습니다: {version}'**
  String bdVersionFileFound(String version);

  /// No description provided for @bdVersionFileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'파일이 없거나 패턴에 맞는 버전이 없습니다'**
  String get bdVersionFileNotFound;

  /// No description provided for @bdVersionFileAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동 감지로 되돌리기'**
  String get bdVersionFileAuto;

  /// No description provided for @bdRollbackTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 되돌리기'**
  String get bdRollbackTitle;

  /// No description provided for @bdRollbackConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tag} 릴리스를 되돌릴까요?'**
  String bdRollbackConfirmTitle(String tag);

  /// No description provided for @bdRollbackMessage.
  ///
  /// In ko, this message translates to:
  /// **'GitHub 릴리스, 원격 태그, 로컬 태그를 지웁니다. 이미 받아 간 사람이 있을 수 있으니 같은 번호를 다시 쓰지 말고 다음 번호({next})로 새로 릴리스하세요.'**
  String bdRollbackMessage(String next);

  /// No description provided for @bdDoneRollback.
  ///
  /// In ko, this message translates to:
  /// **'{tag}을(를) 되돌렸습니다'**
  String bdDoneRollback(String tag);

  /// No description provided for @bdDiffBinary.
  ///
  /// In ko, this message translates to:
  /// **'바이너리 파일이라 내용을 비교할 수 없습니다'**
  String get bdDiffBinary;

  /// No description provided for @bdDiffEmpty.
  ///
  /// In ko, this message translates to:
  /// **'차이가 없습니다'**
  String get bdDiffEmpty;

  /// No description provided for @bdDiffTruncated.
  ///
  /// In ko, this message translates to:
  /// **'너무 길어 처음 {count}줄만 보여 줍니다. 전체는 편집기에서 보세요.'**
  String bdDiffTruncated(int count);

  /// No description provided for @bdHeaderCherryPicking.
  ///
  /// In ko, this message translates to:
  /// **'cherry-pick 중 · 충돌 {count}'**
  String bdHeaderCherryPicking(int count);

  /// No description provided for @bdHeaderReverting.
  ///
  /// In ko, this message translates to:
  /// **'되돌리는 중 · 충돌 {count}'**
  String bdHeaderReverting(int count);

  /// No description provided for @bdOperationAbortPickMessage.
  ///
  /// In ko, this message translates to:
  /// **'시작하기 전 상태로 되돌립니다. 충돌을 해결하던 내용은 사라집니다.'**
  String get bdOperationAbortPickMessage;

  /// No description provided for @bdHistoryBranchLabel.
  ///
  /// In ko, this message translates to:
  /// **'볼 브랜치'**
  String get bdHistoryBranchLabel;

  /// No description provided for @bdHistoryOtherBranchHint.
  ///
  /// In ko, this message translates to:
  /// **'다른 브랜치의 기록입니다. 커밋 메뉴의 \'가져오기\'로 {head}에 복사할 수 있습니다.'**
  String bdHistoryOtherBranchHint(String head);

  /// No description provided for @bdHistoryViewChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 내용 보기'**
  String get bdHistoryViewChanges;

  /// No description provided for @bdHistoryFilesChanged.
  ///
  /// In ko, this message translates to:
  /// **'바뀐 파일 {count}개'**
  String bdHistoryFilesChanged(int count);

  /// No description provided for @bdHistoryMergeNote.
  ///
  /// In ko, this message translates to:
  /// **'병합 커밋 — 병합으로 들어온 변경'**
  String get bdHistoryMergeNote;

  /// No description provided for @bdHistoryRevert.
  ///
  /// In ko, this message translates to:
  /// **'이 커밋 되돌리기 (revert)'**
  String get bdHistoryRevert;

  /// No description provided for @bdHistoryRevertTitle.
  ///
  /// In ko, this message translates to:
  /// **'{hash}을(를) 되돌릴까요?'**
  String bdHistoryRevertTitle(String hash);

  /// No description provided for @bdHistoryRevertMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 커밋의 변경을 거꾸로 적용한 새 커밋을 만듭니다. 기록을 지우지 않으므로 이미 올린 커밋에도 안전합니다.'**
  String get bdHistoryRevertMessage;

  /// No description provided for @bdHistoryRevertUnpushed.
  ///
  /// In ko, this message translates to:
  /// **'이 커밋의 변경을 거꾸로 적용한 새 커밋을 만듭니다. 아직 올리지 않은 커밋이라면 \'직전 커밋 고치기\'나 새 커밋으로 고쳐도 됩니다.'**
  String get bdHistoryRevertUnpushed;

  /// No description provided for @bdHistoryCherryPick.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get bdHistoryCherryPick;

  /// No description provided for @bdHistoryCherryPickMenu.
  ///
  /// In ko, this message translates to:
  /// **'{head}(으)로 가져오기 (cherry-pick)'**
  String bdHistoryCherryPickMenu(String head);

  /// No description provided for @bdHistoryCherryPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'{hash}을(를) {head}(으)로 가져올까요?'**
  String bdHistoryCherryPickTitle(String hash, String head);

  /// No description provided for @bdHistoryCherryPickMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 커밋과 같은 변경을 현재 브랜치에 새 커밋으로 복사합니다. 브랜치 전체를 병합하지 않고 필요한 커밋 하나만 가져올 때 씁니다.'**
  String get bdHistoryCherryPickMessage;

  /// No description provided for @bdDoneRevert.
  ///
  /// In ko, this message translates to:
  /// **'{hash}을(를) 되돌리는 커밋을 만들었습니다'**
  String bdDoneRevert(String hash);

  /// No description provided for @bdDoneCherryPick.
  ///
  /// In ko, this message translates to:
  /// **'{hash}을(를) 가져왔습니다'**
  String bdDoneCherryPick(String hash);

  /// No description provided for @bdMenuPalette.
  ///
  /// In ko, this message translates to:
  /// **'명령 팔레트'**
  String get bdMenuPalette;

  /// No description provided for @bdPaletteHint.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 할까요? (예: push, 브랜치, 태그)'**
  String get bdPaletteHint;

  /// No description provided for @bdPaletteEmpty.
  ///
  /// In ko, this message translates to:
  /// **'맞는 명령이 없습니다'**
  String get bdPaletteEmpty;

  /// No description provided for @bdPaletteGroupActions.
  ///
  /// In ko, this message translates to:
  /// **'동작'**
  String get bdPaletteGroupActions;

  /// No description provided for @bdPaletteGroupTabs.
  ///
  /// In ko, this message translates to:
  /// **'탭'**
  String get bdPaletteGroupTabs;

  /// No description provided for @bdPaletteGroupBranches.
  ///
  /// In ko, this message translates to:
  /// **'브랜치'**
  String get bdPaletteGroupBranches;

  /// No description provided for @bdPaletteGroupRepos.
  ///
  /// In ko, this message translates to:
  /// **'저장소'**
  String get bdPaletteGroupRepos;

  /// No description provided for @bdPaletteGoToTab.
  ///
  /// In ko, this message translates to:
  /// **'{name} 탭으로'**
  String bdPaletteGoToTab(String name);

  /// No description provided for @bdPaletteSwitchTo.
  ///
  /// In ko, this message translates to:
  /// **'{branch}(으)로 전환'**
  String bdPaletteSwitchTo(String branch);

  /// No description provided for @bdHelpCaptionAfterRevert.
  ///
  /// In ko, this message translates to:
  /// **'C를 지우지 않고, C를 거꾸로 적용한 새 커밋 C⁻를 더함'**
  String get bdHelpCaptionAfterRevert;

  /// No description provided for @bdHelpCaptionAfterCherryPick.
  ///
  /// In ko, this message translates to:
  /// **'feature의 D와 같은 변경이 main에 새 커밋 D\'로 복사됨'**
  String get bdHelpCaptionAfterCherryPick;

  /// No description provided for @bdHelpRevertTitle.
  ///
  /// In ko, this message translates to:
  /// **'Revert (되돌리기)'**
  String get bdHelpRevertTitle;

  /// No description provided for @bdHelpRevertWord.
  ///
  /// In ko, this message translates to:
  /// **'revert는 \'원래 상태로 되돌리다\'.'**
  String get bdHelpRevertWord;

  /// No description provided for @bdHelpRevertInGit.
  ///
  /// In ko, this message translates to:
  /// **'커밋을 지우지 않고, 그 커밋의 변경을 거꾸로 적용한 새 커밋을 만듭니다. 기록에는 원래 커밋과 되돌린 커밋이 모두 남습니다.'**
  String get bdHelpRevertInGit;

  /// No description provided for @bdHelpRevertWhy.
  ///
  /// In ko, this message translates to:
  /// **'이미 올린 커밋이 문제를 일으켰을 때 씁니다. 기록을 고치지 않아 다른 사람과 어긋나지 않고 강제 push도 필요 없습니다. 아직 올리지 않은 커밋은 amend로 고치는 편이 깔끔합니다.'**
  String get bdHelpRevertWhy;

  /// No description provided for @bdHelpCaptionBeforeReset.
  ///
  /// In ko, this message translates to:
  /// **'전: main이 D를 가리킴'**
  String get bdHelpCaptionBeforeReset;

  /// No description provided for @bdHelpCaptionAfterReset.
  ///
  /// In ko, this message translates to:
  /// **'후: main이 B로 옮겨짐. C·D는 사라진 것 같지만 reflog에 남아 있음'**
  String get bdHelpCaptionAfterReset;

  /// No description provided for @bdHelpCaptionReflog.
  ///
  /// In ko, this message translates to:
  /// **'HEAD가 지나온 자리가 순서대로 적혀 있어, D로 다시 돌아갈 수 있음'**
  String get bdHelpCaptionReflog;

  /// No description provided for @bdHelpResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'Reset (브랜치 옮기기)'**
  String get bdHelpResetTitle;

  /// No description provided for @bdHelpResetWord.
  ///
  /// In ko, this message translates to:
  /// **'reset은 \'처음 자리로 되돌려 놓다\'.'**
  String get bdHelpResetWord;

  /// No description provided for @bdHelpResetInGit.
  ///
  /// In ko, this message translates to:
  /// **'브랜치가 가리키는 커밋을 뒤로 옮깁니다. 커밋이 지워진 것처럼 보이지만 reflog에 남아 있어 한동안 되살릴 수 있습니다. --soft는 변경을 스테이징한 채 남기고, --keep은 작업 중인 변경을 지키며, --hard는 작업 중인 변경까지 버립니다.'**
  String get bdHelpResetInGit;

  /// No description provided for @bdHelpResetWhy.
  ///
  /// In ko, this message translates to:
  /// **'아직 올리지 않은 커밋을 취소할 때 씁니다. 이미 올린 커밋에는 쓰지 마세요. 다른 사람의 기록과 어긋나니 revert를 쓰세요. 이 앱은 안전한 --soft와 --keep만 씁니다.'**
  String get bdHelpResetWhy;

  /// No description provided for @bdHelpReflogTitle.
  ///
  /// In ko, this message translates to:
  /// **'Reflog (실수 복구 기록)'**
  String get bdHelpReflogTitle;

  /// No description provided for @bdHelpReflogWord.
  ///
  /// In ko, this message translates to:
  /// **'reflog는 \'reference log\', 가리키던 자리의 기록.'**
  String get bdHelpReflogWord;

  /// No description provided for @bdHelpReflogInGit.
  ///
  /// In ko, this message translates to:
  /// **'HEAD와 브랜치가 어디를 가리켰는지 이 컴퓨터에만 적어 둔 기록입니다. 커밋을 취소하거나 브랜치를 지워도 보통 90일 동안은 그 시점을 찾아 되돌아갈 수 있습니다.'**
  String get bdHelpReflogInGit;

  /// No description provided for @bdHelpReflogWhy.
  ///
  /// In ko, this message translates to:
  /// **'\'실수했다\' 싶으면 먼저 reflog를 보세요. 이 컴퓨터에만 있는 기록이라 다른 컴퓨터나 원격에서는 볼 수 없고, 오래된 항목은 git이 정리합니다.'**
  String get bdHelpReflogWhy;

  /// No description provided for @bdHistoryGraph.
  ///
  /// In ko, this message translates to:
  /// **'그래프'**
  String get bdHistoryGraph;

  /// No description provided for @bdHistoryAllBranches.
  ///
  /// In ko, this message translates to:
  /// **'모든 브랜치'**
  String get bdHistoryAllBranches;

  /// No description provided for @bdHelpCaptionGraphMerged.
  ///
  /// In ko, this message translates to:
  /// **'main과 feature가 갈라졌다가 M에서 합쳐진 기록 (속이 빈 점이 병합 커밋)'**
  String get bdHelpCaptionGraphMerged;

  /// No description provided for @bdHelpCommitGraphTitle.
  ///
  /// In ko, this message translates to:
  /// **'커밋 그래프 읽는 법'**
  String get bdHelpCommitGraphTitle;

  /// No description provided for @bdHelpCommitGraphWord.
  ///
  /// In ko, this message translates to:
  /// **'graph는 \'점과 선으로 그린 그림\'.'**
  String get bdHelpCommitGraphWord;

  /// No description provided for @bdHelpCommitGraphInGit.
  ///
  /// In ko, this message translates to:
  /// **'점은 커밋, 선은 부모와의 이음입니다. 위가 최신입니다. 선이 둘로 갈라지면 브랜치가 갈라진 곳, 두 선이 하나로 합쳐지면 병합입니다. 속이 빈 점은 병합 커밋, 고리가 둘러진 점은 지금 있는 자리(HEAD)입니다.'**
  String get bdHelpCommitGraphInGit;

  /// No description provided for @bdHelpCommitGraphWhy.
  ///
  /// In ko, this message translates to:
  /// **'\'내 브랜치가 main과 어디서 갈라졌는지\', \'병합이 어디서 일어났는지\'를 한눈에 봅니다. 좁은 창에서는 선을 6줄까지만 그립니다. 그보다 많으면 맨 오른쪽 줄에 겹쳐 보입니다.'**
  String get bdHelpCommitGraphWhy;

  /// No description provided for @bdRecoveryTitle.
  ///
  /// In ko, this message translates to:
  /// **'실수 복구'**
  String get bdRecoveryTitle;

  /// No description provided for @bdRecoveryIntro.
  ///
  /// In ko, this message translates to:
  /// **'실수했어도 대부분 되돌릴 수 있습니다. 상황에 맞는 것을 고르세요.'**
  String get bdRecoveryIntro;

  /// No description provided for @bdRecoveryUndoCommit.
  ///
  /// In ko, this message translates to:
  /// **'마지막 커밋 취소'**
  String get bdRecoveryUndoCommit;

  /// No description provided for @bdRecoveryUndoCommitWhy.
  ///
  /// In ko, this message translates to:
  /// **'\'{subject}\' 커밋만 취소합니다. 바꾼 내용은 스테이징된 채 남습니다.'**
  String bdRecoveryUndoCommitWhy(String subject);

  /// No description provided for @bdRecoveryUndoCommitMessage.
  ///
  /// In ko, this message translates to:
  /// **'\'{subject}\' 커밋을 취소합니다. 그 커밋에서 바꾼 내용은 지워지지 않고 스테이징된 채 남아, 고쳐서 다시 커밋할 수 있습니다.'**
  String bdRecoveryUndoCommitMessage(String subject);

  /// No description provided for @bdRecoveryUndoCommitPushed.
  ///
  /// In ko, this message translates to:
  /// **'이 커밋은 이미 원격에 올라가 있습니다. 취소해도 원격에는 남아 있어 다시 올리려면 강제 push가 필요하고, 다른 사람의 기록과 어긋납니다. 올린 커밋은 기록 탭의 \'되돌리기(revert)\'가 더 안전합니다.'**
  String get bdRecoveryUndoCommitPushed;

  /// No description provided for @bdRecoveryUndoCommitConfirm.
  ///
  /// In ko, this message translates to:
  /// **'커밋 취소'**
  String get bdRecoveryUndoCommitConfirm;

  /// No description provided for @bdRecoveryNoParent.
  ///
  /// In ko, this message translates to:
  /// **'첫 커밋은 취소할 수 없습니다.'**
  String get bdRecoveryNoParent;

  /// No description provided for @bdRecoveryStash.
  ///
  /// In ko, this message translates to:
  /// **'작업 중인 변경을 잠시 치우기'**
  String get bdRecoveryStash;

  /// No description provided for @bdRecoveryStashWhy.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장(stash)에 보관했다가 나중에 다시 꺼냅니다.'**
  String get bdRecoveryStashWhy;

  /// No description provided for @bdRecoveryHistory.
  ///
  /// In ko, this message translates to:
  /// **'이전 상태로 돌아가기'**
  String get bdRecoveryHistory;

  /// No description provided for @bdRecoveryHistoryHint.
  ///
  /// In ko, this message translates to:
  /// **'HEAD가 지나온 자리입니다. 커밋을 취소하거나 브랜치를 지운 뒤에도 보통 90일 동안 남아 있습니다.'**
  String get bdRecoveryHistoryHint;

  /// No description provided for @bdRecoveryNow.
  ///
  /// In ko, this message translates to:
  /// **'지금'**
  String get bdRecoveryNow;

  /// No description provided for @bdRecoveryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없습니다.'**
  String get bdRecoveryEmpty;

  /// No description provided for @bdRecoveryKindCommit.
  ///
  /// In ko, this message translates to:
  /// **'커밋'**
  String get bdRecoveryKindCommit;

  /// No description provided for @bdRecoveryKindAmend.
  ///
  /// In ko, this message translates to:
  /// **'커밋 고침'**
  String get bdRecoveryKindAmend;

  /// No description provided for @bdRecoveryKindCheckout.
  ///
  /// In ko, this message translates to:
  /// **'전환'**
  String get bdRecoveryKindCheckout;

  /// No description provided for @bdRecoveryKindReset.
  ///
  /// In ko, this message translates to:
  /// **'되돌림'**
  String get bdRecoveryKindReset;

  /// No description provided for @bdRecoveryKindMerge.
  ///
  /// In ko, this message translates to:
  /// **'병합'**
  String get bdRecoveryKindMerge;

  /// No description provided for @bdRecoveryKindPull.
  ///
  /// In ko, this message translates to:
  /// **'pull'**
  String get bdRecoveryKindPull;

  /// No description provided for @bdRecoveryKindRebase.
  ///
  /// In ko, this message translates to:
  /// **'rebase'**
  String get bdRecoveryKindRebase;

  /// No description provided for @bdRecoveryKindCherryPick.
  ///
  /// In ko, this message translates to:
  /// **'cherry-pick'**
  String get bdRecoveryKindCherryPick;

  /// No description provided for @bdRecoveryKindRevert.
  ///
  /// In ko, this message translates to:
  /// **'revert'**
  String get bdRecoveryKindRevert;

  /// No description provided for @bdRecoveryKindOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get bdRecoveryKindOther;

  /// No description provided for @bdRecoveryGoBack.
  ///
  /// In ko, this message translates to:
  /// **'여기로 되돌리기'**
  String get bdRecoveryGoBack;

  /// No description provided for @bdRecoveryGoBackMessage.
  ///
  /// In ko, this message translates to:
  /// **'{branch}를 {target} 시점으로 되돌립니다. 그 뒤의 커밋은 브랜치에서 빠지지만 reflog에 남아 있습니다. 작업 중인 변경은 그대로 두며, 겹치는 파일이 있으면 아무것도 바꾸지 않고 멈춥니다.'**
  String bdRecoveryGoBackMessage(String branch, String target);

  /// No description provided for @bdRecoveryGoBackConfirm.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get bdRecoveryGoBackConfirm;

  /// No description provided for @bdRecoveryRescue.
  ///
  /// In ko, this message translates to:
  /// **'여기서 새 브랜치 만들기'**
  String get bdRecoveryRescue;

  /// No description provided for @bdDoneUndoCommit.
  ///
  /// In ko, this message translates to:
  /// **'마지막 커밋을 취소했습니다 (변경은 스테이징된 채 남음)'**
  String get bdDoneUndoCommit;

  /// No description provided for @bdDoneGoBack.
  ///
  /// In ko, this message translates to:
  /// **'{target} 시점으로 되돌렸습니다'**
  String bdDoneGoBack(String target);

  /// No description provided for @bdDoneRescue.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 {name}을 만들었습니다'**
  String bdDoneRescue(String name);

  /// No description provided for @bdHelpCherryPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'Cherry-pick (골라 가져오기)'**
  String get bdHelpCherryPickTitle;

  /// No description provided for @bdHelpCherryPickWord.
  ///
  /// In ko, this message translates to:
  /// **'cherry-pick은 \'체리를 하나씩 골라 따다\' — 좋은 것만 골라 가져오기.'**
  String get bdHelpCherryPickWord;

  /// No description provided for @bdHelpCherryPickInGit.
  ///
  /// In ko, this message translates to:
  /// **'다른 브랜치의 커밋 하나와 같은 변경을 현재 브랜치에 새 커밋으로 복사합니다. 내용은 같지만 새 커밋(D\')이라 해시가 다릅니다.'**
  String get bdHelpCherryPickInGit;

  /// No description provided for @bdHelpCherryPickWhy.
  ///
  /// In ko, this message translates to:
  /// **'다른 브랜치의 버그 수정 하나만 급히 가져올 때 씁니다. 브랜치를 나중에 병합하면 같은 변경이 두 번 들어와 충돌할 수 있으니, 자주 쓰기보다 병합이 기본입니다.'**
  String get bdHelpCherryPickWhy;

  /// No description provided for @bdConfirmTypeToContinue.
  ///
  /// In ko, this message translates to:
  /// **'되돌릴 수 없습니다. 계속하려면 {text}을(를) 그대로 입력하세요.'**
  String bdConfirmTypeToContinue(String text);

  /// No description provided for @bdTagsDeleteRemoteReleaseDraft.
  ///
  /// In ko, this message translates to:
  /// **'⚠️ {tag}에는 GitHub 릴리스가 있습니다. 태그를 지우면 GitHub가 그 릴리스를 초안(비공개)으로 바꿉니다 — 파일은 남지만 사람들이 볼 수 없게 됩니다. 릴리스까지 정리하려면 태그 메뉴의 \'릴리스 되돌리기\'를 쓰세요.'**
  String bdTagsDeleteRemoteReleaseDraft(String tag);

  /// No description provided for @bdTagsPushCiTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 {count}개를 push하면 릴리스가 새로 만들어집니다'**
  String bdTagsPushCiTitle(int count);

  /// No description provided for @bdTagsPushCiMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 저장소는 태그를 push하면 {workflow}이(가) 태그마다 빌드하고 GitHub 릴리스를 만듭니다: {tags}. 일부러 지운 옛 릴리스라면 다시 생깁니다. 로컬에서만 지우려면 태그 메뉴의 \'삭제\'를 쓰세요.'**
  String bdTagsPushCiMessage(String workflow, String tags);

  /// No description provided for @bdTagsPushAnyway.
  ///
  /// In ko, this message translates to:
  /// **'그래도 push'**
  String get bdTagsPushAnyway;

  /// No description provided for @bdTagsPushMismatchTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 {count}개의 버전이 버전 파일과 다릅니다'**
  String bdTagsPushMismatchTitle(int count);

  /// No description provided for @bdTagsPushMismatchMessage.
  ///
  /// In ko, this message translates to:
  /// **'태그가 가리키는 커밋의 {file} 버전이 태그와 다릅니다 (태그 → 파일의 버전): {tags}. 버전을 올리기 전의 커밋에 단 태그일 수 있습니다. 이대로 올리면 태그로 릴리스를 만드는 CI가 버전 검사에서 멈춥니다. 릴리스 마법사로 버전 올림부터 하세요.'**
  String bdTagsPushMismatchMessage(String file, String tags);

  /// No description provided for @bdCiVersionMismatchMessage.
  ///
  /// In ko, this message translates to:
  /// **'CI가 {tag} 태그와 버전 파일의 버전이 다르다며 멈췄습니다. 태그가 버전 올림 커밋보다 앞선 커밋에 달린 것입니다. 다시 실행해도 같은 결과이니, 버전 올림 커밋이 기본 브랜치에 들어갔는지 확인한 뒤 태그를 지우고 다시 다세요.'**
  String bdCiVersionMismatchMessage(String tag);

  /// No description provided for @bdCiRetag.
  ///
  /// In ko, this message translates to:
  /// **'태그 지우고 다시 달기'**
  String get bdCiRetag;

  /// No description provided for @bdCommonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get bdCommonDelete;

  /// No description provided for @bdPrReviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰와 코멘트'**
  String get bdPrReviewTitle;

  /// No description provided for @bdPrReviewShowAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 보기 ({count})'**
  String bdPrReviewShowAll(int count);

  /// No description provided for @bdPrReviewShowLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get bdPrReviewShowLess;

  /// No description provided for @bdPrReviewApprove.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get bdPrReviewApprove;

  /// No description provided for @bdPrReviewRequestChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경 요청'**
  String get bdPrReviewRequestChanges;

  /// No description provided for @bdPrReviewComment.
  ///
  /// In ko, this message translates to:
  /// **'코멘트'**
  String get bdPrReviewComment;

  /// No description provided for @bdPrReviewOwnPr.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 PR은 스스로 승인하거나 변경을 요청할 수 없습니다. 코멘트는 남길 수 있습니다.'**
  String get bdPrReviewOwnPr;

  /// No description provided for @bdPrReviewSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get bdPrReviewSend;

  /// No description provided for @bdPrReviewBody.
  ///
  /// In ko, this message translates to:
  /// **'내용 (Markdown)'**
  String get bdPrReviewBody;

  /// No description provided for @bdPrReviewBodyOptional.
  ///
  /// In ko, this message translates to:
  /// **'내용 (선택, Markdown)'**
  String get bdPrReviewBodyOptional;

  /// No description provided for @bdDonePrReview.
  ///
  /// In ko, this message translates to:
  /// **'#{number}에 리뷰를 남겼습니다'**
  String bdDonePrReview(int number);

  /// No description provided for @bdAssetTitle.
  ///
  /// In ko, this message translates to:
  /// **'첨부 파일 {count}개'**
  String bdAssetTitle(int count);

  /// No description provided for @bdAssetEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첨부 파일이 없습니다. CI가 올린 빌드 결과물이 여기에 보입니다.'**
  String get bdAssetEmpty;

  /// No description provided for @bdAssetMeta.
  ///
  /// In ko, this message translates to:
  /// **'{size} · 받은 횟수 {count}'**
  String bdAssetMeta(String size, int count);

  /// No description provided for @bdAssetUpload.
  ///
  /// In ko, this message translates to:
  /// **'파일 올리기'**
  String get bdAssetUpload;

  /// No description provided for @bdAssetDownload.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get bdAssetDownload;

  /// No description provided for @bdAssetReplace.
  ///
  /// In ko, this message translates to:
  /// **'덮어쓰기'**
  String get bdAssetReplace;

  /// No description provided for @bdAssetReplaceTitle.
  ///
  /// In ko, this message translates to:
  /// **'같은 이름의 파일을 덮어쓸까요?'**
  String get bdAssetReplaceTitle;

  /// No description provided for @bdAssetReplaceMessage.
  ///
  /// In ko, this message translates to:
  /// **'{names} — 이미 받아 간 사람이 있다면 내용이 서로 달라집니다. 가능하면 새 버전으로 릴리스하세요.'**
  String bdAssetReplaceMessage(String names);

  /// No description provided for @bdAssetDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 삭제할까요?'**
  String bdAssetDeleteTitle(String name);

  /// No description provided for @bdAssetDeleteMessage.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 페이지에서 이 파일을 지웁니다. 되돌릴 수 없고, 이 파일로 연결된 다운로드 주소도 끊깁니다.'**
  String get bdAssetDeleteMessage;

  /// No description provided for @bdDoneAssetDownloaded.
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 받았습니다'**
  String bdDoneAssetDownloaded(String name);

  /// No description provided for @bdDoneAssetUploaded.
  ///
  /// In ko, this message translates to:
  /// **'파일 {count}개를 올렸습니다'**
  String bdDoneAssetUploaded(int count);

  /// No description provided for @bdDoneAssetDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 삭제했습니다'**
  String bdDoneAssetDeleted(String name);

  /// No description provided for @bdSyncUpstreamCounts.
  ///
  /// In ko, this message translates to:
  /// **'{upstream}  ↑{ahead} ↓{behind}'**
  String bdSyncUpstreamCounts(String upstream, int ahead, int behind);

  /// No description provided for @bdSyncNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'{branch}에 연결된 원격 브랜치가 없습니다'**
  String bdSyncNoUpstream(String branch);

  /// No description provided for @bdSyncOnOtherBranch.
  ///
  /// In ko, this message translates to:
  /// **'지금은 {branch}에 있습니다'**
  String bdSyncOnOtherBranch(String branch);

  /// No description provided for @bdSyncBehind.
  ///
  /// In ko, this message translates to:
  /// **'원격에 아직 받지 않은 커밋이 {count}개 있습니다. Pull 하세요.'**
  String bdSyncBehind(int count);

  /// No description provided for @bdSyncAhead.
  ///
  /// In ko, this message translates to:
  /// **'push하지 않은 커밋이 {count}개 있습니다.'**
  String bdSyncAhead(int count);

  /// No description provided for @bdSyncAheadPr.
  ///
  /// In ko, this message translates to:
  /// **'push하지 않은 커밋이 {count}개 있습니다. 여기서 Push하면 PR 없이 {branch}에 바로 올라갑니다.'**
  String bdSyncAheadPr(int count, String branch);

  /// No description provided for @bdSyncDiverged.
  ///
  /// In ko, this message translates to:
  /// **'원격과 갈라졌습니다. 받을 커밋 {behind}개, 보낼 커밋 {ahead}개.'**
  String bdSyncDiverged(int behind, int ahead);

  /// No description provided for @bdSyncSameContent.
  ///
  /// In ko, this message translates to:
  /// **'파일 내용은 원격과 같고 커밋만 다릅니다 (로컬 커밋 {count}개). PR을 squash나 rebase로 병합하면 로컬에 옛 커밋이 남아 이렇게 됩니다.'**
  String bdSyncSameContent(int count);

  /// No description provided for @bdSyncMatchRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격에 맞추기'**
  String get bdSyncMatchRemote;

  /// No description provided for @bdSyncMatchRemoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'{branch}를 원격에 맞출까요?'**
  String bdSyncMatchRemoteTitle(String branch);

  /// No description provided for @bdSyncMatchRemoteMessage.
  ///
  /// In ko, this message translates to:
  /// **'로컬 커밋 {count}개를 버리고 {branch}를 {upstream}으로 옮깁니다. 파일 내용은 그대로이고 커밋하지 않은 변경도 지킵니다. 버린 커밋은 git reflog로 되찾을 수 있습니다.'**
  String bdSyncMatchRemoteMessage(int count, String branch, String upstream);

  /// No description provided for @bdDoneMatchRemote.
  ///
  /// In ko, this message translates to:
  /// **'{branch}를 원격에 맞췄습니다'**
  String bdDoneMatchRemote(String branch);

  /// No description provided for @bdSyncPushNoPrTitle.
  ///
  /// In ko, this message translates to:
  /// **'PR 없이 {branch}에 push할까요?'**
  String bdSyncPushNoPrTitle(String branch);

  /// No description provided for @bdSyncPushNoPrMessage.
  ///
  /// In ko, this message translates to:
  /// **'push하지 않은 커밋 {count}개가 PR을 거치지 않고 {branch}에 바로 올라갑니다. 보호된 브랜치면 거부됩니다. 작업 브랜치로 옮겨 PR을 올리는 편이 안전합니다.'**
  String bdSyncPushNoPrMessage(int count, String branch);

  /// No description provided for @bdWorktreesTitle.
  ///
  /// In ko, this message translates to:
  /// **'Worktree'**
  String get bdWorktreesTitle;

  /// No description provided for @bdWorktreePill.
  ///
  /// In ko, this message translates to:
  /// **'worktree'**
  String get bdWorktreePill;

  /// No description provided for @bdWorktreeHeldTooltip.
  ///
  /// In ko, this message translates to:
  /// **'{path}에 체크아웃되어 있습니다'**
  String bdWorktreeHeldTooltip(String path);

  /// No description provided for @bdWorktreeDetachedHead.
  ///
  /// In ko, this message translates to:
  /// **'분리된 HEAD'**
  String get bdWorktreeDetachedHead;

  /// No description provided for @bdWorktreeMainPill.
  ///
  /// In ko, this message translates to:
  /// **'기본 폴더'**
  String get bdWorktreeMainPill;

  /// No description provided for @bdWorktreeOpenPill.
  ///
  /// In ko, this message translates to:
  /// **'지금 연 폴더'**
  String get bdWorktreeOpenPill;

  /// No description provided for @bdWorktreeChangesPill.
  ///
  /// In ko, this message translates to:
  /// **'변경 {count}'**
  String bdWorktreeChangesPill(int count);

  /// No description provided for @bdWorktreeMissingPill.
  ///
  /// In ko, this message translates to:
  /// **'폴더 없음'**
  String get bdWorktreeMissingPill;

  /// No description provided for @bdWorktreeLockedPill.
  ///
  /// In ko, this message translates to:
  /// **'잠김'**
  String get bdWorktreeLockedPill;

  /// No description provided for @bdWorktreeOpen.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get bdWorktreeOpen;

  /// No description provided for @bdWorktreeDetach.
  ///
  /// In ko, this message translates to:
  /// **'브랜치 풀기'**
  String get bdWorktreeDetach;

  /// No description provided for @bdWorktreeRemove.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get bdWorktreeRemove;

  /// No description provided for @bdWorktreeClaudeWarning.
  ///
  /// In ko, this message translates to:
  /// **'Claude Code 세션이 쓰는 폴더일 수 있습니다. 세션이 끝났는지 먼저 확인하세요.'**
  String get bdWorktreeClaudeWarning;

  /// No description provided for @bdWorktreeHeldTitle.
  ///
  /// In ko, this message translates to:
  /// **'{branch}는 다른 worktree에 있습니다'**
  String bdWorktreeHeldTitle(String branch);

  /// No description provided for @bdWorktreeHeldMessage.
  ///
  /// In ko, this message translates to:
  /// **'git은 한 브랜치를 한 worktree에서만 체크아웃하게 합니다. {path}에서 이 브랜치를 쓰고 있어 여기서는 전환할 수 없습니다. 그 폴더를 열어 작업하거나, 그 폴더의 브랜치를 풀고(분리된 HEAD) 여기로 전환하세요.'**
  String bdWorktreeHeldMessage(String path);

  /// No description provided for @bdWorktreeDetachAndSwitch.
  ///
  /// In ko, this message translates to:
  /// **'풀고 여기로 전환'**
  String get bdWorktreeDetachAndSwitch;

  /// No description provided for @bdWorktreeDetachTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}의 브랜치를 풀까요?'**
  String bdWorktreeDetachTitle(String name);

  /// No description provided for @bdWorktreeDetachMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}를 {branch}에서 분리된 HEAD로 바꿉니다. 파일과 커밋은 그대로이고, {branch}를 다른 곳에서 체크아웃하거나 지울 수 있게 됩니다.'**
  String bdWorktreeDetachMessage(String path, String branch);

  /// No description provided for @bdWorktreeRemoveTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} worktree를 지울까요?'**
  String bdWorktreeRemoveTitle(String name);

  /// No description provided for @bdWorktreeRemoveMessage.
  ///
  /// In ko, this message translates to:
  /// **'폴더 {path}를 지웁니다. 브랜치와 커밋은 저장소에 남습니다.'**
  String bdWorktreeRemoveMessage(String path);

  /// No description provided for @bdWorktreeRemoveForceTitle.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경까지 지울까요?'**
  String get bdWorktreeRemoveForceTitle;

  /// No description provided for @bdWorktreeRemoveForceMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}에 커밋하지 않은 변경이 {count}개 있습니다. 지우면 되찾을 수 없습니다.'**
  String bdWorktreeRemoveForceMessage(String path, int count);

  /// No description provided for @bdWorktreeLockedMessage.
  ///
  /// In ko, this message translates to:
  /// **'{path}는 잠겨 있어 지울 수 없습니다. 먼저 git worktree unlock으로 잠금을 푸세요.'**
  String bdWorktreeLockedMessage(String path);

  /// No description provided for @bdWorktreeDeleteBranchTitle.
  ///
  /// In ko, this message translates to:
  /// **'worktree도 지우고 브랜치를 삭제할까요?'**
  String get bdWorktreeDeleteBranchTitle;

  /// No description provided for @bdWorktreeDeleteBranchMessage.
  ///
  /// In ko, this message translates to:
  /// **'{branch}는 {path}에 체크아웃되어 있어 그대로는 지울 수 없습니다. 그 worktree 폴더를 먼저 지우고 브랜치를 삭제합니다.'**
  String bdWorktreeDeleteBranchMessage(String branch, String path);

  /// No description provided for @bdWorktreeDeleteBranchDirty.
  ///
  /// In ko, this message translates to:
  /// **'{branch}는 {path}에 체크아웃되어 있고, 그 폴더에 커밋하지 않은 변경이 {count}개 있습니다. 그 폴더를 열어 정리한 뒤 다시 지우세요.'**
  String bdWorktreeDeleteBranchDirty(String branch, String path, int count);

  /// No description provided for @bdWorktreePrune.
  ///
  /// In ko, this message translates to:
  /// **'사라진 폴더 기록 정리'**
  String get bdWorktreePrune;

  /// No description provided for @bdDoneWorktreeRemoved.
  ///
  /// In ko, this message translates to:
  /// **'{name} worktree를 지웠습니다'**
  String bdDoneWorktreeRemoved(String name);

  /// No description provided for @bdDoneWorktreeDetached.
  ///
  /// In ko, this message translates to:
  /// **'{name}의 브랜치를 풀었습니다'**
  String bdDoneWorktreeDetached(String name);

  /// No description provided for @bdDoneWorktreePruned.
  ///
  /// In ko, this message translates to:
  /// **'worktree 기록을 정리했습니다'**
  String get bdDoneWorktreePruned;

  /// No description provided for @bdCleanupWorktree.
  ///
  /// In ko, this message translates to:
  /// **'worktree {name}도 함께 지웁니다'**
  String bdCleanupWorktree(String name);

  /// No description provided for @bdCleanupWorktreeBlocked.
  ///
  /// In ko, this message translates to:
  /// **'worktree {name}에 커밋하지 않은 변경이 있거나 잠겨 있어 지울 수 없습니다'**
  String bdCleanupWorktreeBlocked(String name);

  /// No description provided for @bdEnvCustomPath.
  ///
  /// In ko, this message translates to:
  /// **'직접 지정'**
  String get bdEnvCustomPath;

  /// No description provided for @bdEnvSetPath.
  ///
  /// In ko, this message translates to:
  /// **'경로 지정'**
  String get bdEnvSetPath;

  /// No description provided for @bdEnvGitTooOld.
  ///
  /// In ko, this message translates to:
  /// **'git {min} 이상이 필요합니다. 일부 명령이 실패하거나 결과를 잘못 읽을 수 있습니다.'**
  String bdEnvGitTooOld(String min);

  /// No description provided for @bdEnvGhTooOld.
  ///
  /// In ko, this message translates to:
  /// **'gh {min} 이상이 필요합니다. 더 낮으면 로그인 확인(gh auth status --json)이 안 돼 로그인했어도 \"로그인 안 됨\"으로 보입니다.'**
  String bdEnvGhTooOld(String min);

  /// No description provided for @bdEnvCopyDiagnostics.
  ///
  /// In ko, this message translates to:
  /// **'진단 정보 복사'**
  String get bdEnvCopyDiagnostics;

  /// No description provided for @bdEnvDiagnosticsCopied.
  ///
  /// In ko, this message translates to:
  /// **'진단 정보를 복사했습니다. 문제를 알릴 때 붙여 넣으세요.'**
  String get bdEnvDiagnosticsCopied;

  /// No description provided for @bdEnvSearchPath.
  ///
  /// In ko, this message translates to:
  /// **'앱이 쓰는 PATH'**
  String get bdEnvSearchPath;

  /// No description provided for @bdToolPathTitle.
  ///
  /// In ko, this message translates to:
  /// **'{tool} 경로'**
  String bdToolPathTitle(String tool);

  /// No description provided for @bdToolPathWhy.
  ///
  /// In ko, this message translates to:
  /// **'PATH에서 찾은 {tool} 대신 쓸 실행 파일을 고릅니다. 비워 두면 PATH에서 찾습니다.'**
  String bdToolPathWhy(String tool);

  /// No description provided for @bdToolPathLabel.
  ///
  /// In ko, this message translates to:
  /// **'실행 파일'**
  String get bdToolPathLabel;

  /// No description provided for @bdToolPathBrowse.
  ///
  /// In ko, this message translates to:
  /// **'파일 고르기'**
  String get bdToolPathBrowse;

  /// No description provided for @bdToolPathVerify.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get bdToolPathVerify;

  /// No description provided for @bdToolPathUsePath.
  ///
  /// In ko, this message translates to:
  /// **'PATH에서 찾기'**
  String get bdToolPathUsePath;

  /// No description provided for @bdToolPathOk.
  ///
  /// In ko, this message translates to:
  /// **'{tool} {version} 확인됨'**
  String bdToolPathOk(String tool, String version);

  /// No description provided for @bdToolPathBad.
  ///
  /// In ko, this message translates to:
  /// **'실행할 수 없거나 {tool}이(가) 아닙니다'**
  String bdToolPathBad(String tool);

  /// No description provided for @bdToolPathNeedsCheck.
  ///
  /// In ko, this message translates to:
  /// **'저장하기 전에 확인을 누르세요'**
  String get bdToolPathNeedsCheck;

  /// No description provided for @bdDoneToolPath.
  ///
  /// In ko, this message translates to:
  /// **'{tool} 경로를 저장했습니다'**
  String bdDoneToolPath(String tool);

  /// No description provided for @bdDoneToolPathReset.
  ///
  /// In ko, this message translates to:
  /// **'{tool}을(를) PATH에서 찾습니다'**
  String bdDoneToolPathReset(String tool);

  /// No description provided for @fdSecretsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 시크릿'**
  String get fdSecretsTooltip;

  /// No description provided for @fdSecretsTitle.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 시크릿 등록'**
  String get fdSecretsTitle;

  /// No description provided for @fdSecretsIntro.
  ///
  /// In ko, this message translates to:
  /// **'macOS 릴리스 워크플로가 서명·공증에 쓰는 GitHub Actions 시크릿을 gh로 등록합니다. 값은 이 앱에 저장되지 않습니다.'**
  String get fdSecretsIntro;

  /// No description provided for @fdSecretsRepoLabel.
  ///
  /// In ko, this message translates to:
  /// **'저장소 (owner/repo)'**
  String get fdSecretsRepoLabel;

  /// No description provided for @fdSecretsPickFolder.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 폴더에서 읽기'**
  String get fdSecretsPickFolder;

  /// No description provided for @fdSecretsRefresh.
  ///
  /// In ko, this message translates to:
  /// **'등록 상태 새로 고침'**
  String get fdSecretsRefresh;

  /// No description provided for @fdSecretsRepoInvalid.
  ///
  /// In ko, this message translates to:
  /// **'owner/repo 형식으로 입력하세요'**
  String get fdSecretsRepoInvalid;

  /// No description provided for @fdSecretsFolderNoRemote.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더에서 GitHub 원격(origin)을 찾지 못했습니다'**
  String get fdSecretsFolderNoRemote;

  /// No description provided for @fdSecretsGhMissing.
  ///
  /// In ko, this message translates to:
  /// **'GitHub CLI(gh)가 없습니다. 터미널에서 이 명령으로 설치하세요:'**
  String get fdSecretsGhMissing;

  /// No description provided for @fdSecretsGhNotLoggedIn.
  ///
  /// In ko, this message translates to:
  /// **'gh에 로그인하지 않았습니다. 터미널에서 이 명령을 실행하세요:'**
  String get fdSecretsGhNotLoggedIn;

  /// No description provided for @fdSecretsListFailed.
  ///
  /// In ko, this message translates to:
  /// **'등록 상태를 읽지 못했습니다. 저장소 이름과 권한을 확인하세요'**
  String get fdSecretsListFailed;

  /// No description provided for @fdSecretStatusRegistered.
  ///
  /// In ko, this message translates to:
  /// **'등록됨 · {date}'**
  String fdSecretStatusRegistered(String date);

  /// No description provided for @fdSecretStatusMissing.
  ///
  /// In ko, this message translates to:
  /// **'미등록'**
  String get fdSecretStatusMissing;

  /// No description provided for @fdSecretStatusUnknown.
  ///
  /// In ko, this message translates to:
  /// **'확인 안 됨'**
  String get fdSecretStatusUnknown;

  /// No description provided for @fdSecretSet.
  ///
  /// In ko, this message translates to:
  /// **'등록'**
  String get fdSecretSet;

  /// No description provided for @fdSecretOverwrite.
  ///
  /// In ko, this message translates to:
  /// **'덮어쓰기'**
  String get fdSecretOverwrite;

  /// No description provided for @fdSecretPickFile.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택…'**
  String get fdSecretPickFile;

  /// No description provided for @fdSecretNoFile.
  ///
  /// In ko, this message translates to:
  /// **'선택한 파일 없음'**
  String get fdSecretNoFile;

  /// No description provided for @fdSecretFileLoaded.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {bytes}바이트'**
  String fdSecretFileLoaded(String name, int bytes);

  /// No description provided for @fdSecretGenerate.
  ///
  /// In ko, this message translates to:
  /// **'무작위 생성'**
  String get fdSecretGenerate;

  /// No description provided for @fdSecretGenerated.
  ///
  /// In ko, this message translates to:
  /// **'무작위 값을 만들었습니다 (화면에 표시하지 않음)'**
  String get fdSecretGenerated;

  /// No description provided for @fdSecretViaStdin.
  ///
  /// In ko, this message translates to:
  /// **'값은 명령 인자가 아니라 표준 입력으로 전달되어 명령 기록에 남지 않습니다.'**
  String get fdSecretViaStdin;

  /// No description provided for @fdSecretIssueEmpty.
  ///
  /// In ko, this message translates to:
  /// **'값을 입력하세요'**
  String get fdSecretIssueEmpty;

  /// No description provided for @fdSecretIssueEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일 형식이 아닙니다'**
  String get fdSecretIssueEmail;

  /// No description provided for @fdSecretIssueTeamId.
  ///
  /// In ko, this message translates to:
  /// **'Team ID는 영문 대문자·숫자 10자입니다'**
  String get fdSecretIssueTeamId;

  /// No description provided for @fdSecretSaved.
  ///
  /// In ko, this message translates to:
  /// **'{name} 등록했습니다'**
  String fdSecretSaved(String name);

  /// No description provided for @fdSecretFailed.
  ///
  /// In ko, this message translates to:
  /// **'{name} 등록에 실패했습니다'**
  String fdSecretFailed(String name);

  /// No description provided for @fdSecretOverwriteTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}을(를) 덮어쓸까요?'**
  String fdSecretOverwriteTitle(String name);

  /// No description provided for @fdSecretOverwriteBody.
  ///
  /// In ko, this message translates to:
  /// **'이미 등록된 값을 새 값으로 바꿉니다. 되돌릴 수 없습니다.'**
  String get fdSecretOverwriteBody;

  /// No description provided for @fdSecretHelpP12.
  ///
  /// In ko, this message translates to:
  /// **'키체인 접근에서 \'Developer ID Application\' 인증서를 .p12로 내보낸 파일을 고르세요. 앱이 base64로 바꿔 등록합니다.'**
  String get fdSecretHelpP12;

  /// No description provided for @fdSecretHelpP12Password.
  ///
  /// In ko, this message translates to:
  /// **'.p12를 내보낼 때 지정한 암호입니다.'**
  String get fdSecretHelpP12Password;

  /// No description provided for @fdSecretHelpKeychain.
  ///
  /// In ko, this message translates to:
  /// **'CI가 빌드 중에만 쓰는 임시 키체인 암호입니다. 아무 값이나 괜찮아서 무작위로 만들어 드립니다.'**
  String get fdSecretHelpKeychain;

  /// No description provided for @fdSecretHelpAppleId.
  ///
  /// In ko, this message translates to:
  /// **'공증(notarization)에 쓰는 Apple ID 이메일입니다.'**
  String get fdSecretHelpAppleId;

  /// No description provided for @fdSecretHelpApplePassword.
  ///
  /// In ko, this message translates to:
  /// **'앱 암호(app-specific password)입니다. 계정 비밀번호가 아닙니다.'**
  String get fdSecretHelpApplePassword;

  /// No description provided for @fdSecretHelpTeamId.
  ///
  /// In ko, this message translates to:
  /// **'developer.apple.com/account의 Membership details에 있는 10자리 Team ID입니다.'**
  String get fdSecretHelpTeamId;

  /// No description provided for @fdSecretOpenAppleId.
  ///
  /// In ko, this message translates to:
  /// **'appleid.apple.com 열기'**
  String get fdSecretOpenAppleId;

  /// No description provided for @fdSecretOpenDeveloper.
  ///
  /// In ko, this message translates to:
  /// **'developer.apple.com/account 열기'**
  String get fdSecretOpenDeveloper;

  /// No description provided for @fdCommandBarEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 실행한 명령이 없습니다'**
  String get fdCommandBarEmpty;

  /// No description provided for @fdHomeProjectTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트'**
  String get fdHomeProjectTitle;

  /// No description provided for @fdHomeProjectOpen.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 열기'**
  String get fdHomeProjectOpen;

  /// No description provided for @fdHomeProjectReload.
  ///
  /// In ko, this message translates to:
  /// **'이 프로젝트 다시 읽기'**
  String get fdHomeProjectReload;

  /// No description provided for @fdHomeProjectDrop.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 프로젝트 폴더를 여기로 끌어다 놓거나 [프로젝트 열기]를 누르세요'**
  String get fdHomeProjectDrop;

  /// No description provided for @fdHomeProjectNotFlutter.
  ///
  /// In ko, this message translates to:
  /// **'Flutter 프로젝트가 아닙니다: {path}'**
  String fdHomeProjectNotFlutter(String path);

  /// No description provided for @fdHomePlatformIos.
  ///
  /// In ko, this message translates to:
  /// **'iOS'**
  String get fdHomePlatformIos;

  /// No description provided for @fdHomePlatformAndroid.
  ///
  /// In ko, this message translates to:
  /// **'Android'**
  String get fdHomePlatformAndroid;

  /// No description provided for @fdHomeDevicesTitle.
  ///
  /// In ko, this message translates to:
  /// **'기기'**
  String get fdHomeDevicesTitle;

  /// No description provided for @fdHomeDevicesRefresh.
  ///
  /// In ko, this message translates to:
  /// **'기기 새로 고침'**
  String get fdHomeDevicesRefresh;

  /// No description provided for @fdHomeDevicesNone.
  ///
  /// In ko, this message translates to:
  /// **'USB로 연결된 기기가 없습니다. 폰을 USB로 연결하고 잠금을 푼 뒤 새로 고치세요'**
  String get fdHomeDevicesNone;

  /// No description provided for @fdHomeLinkUsb.
  ///
  /// In ko, this message translates to:
  /// **'USB'**
  String get fdHomeLinkUsb;

  /// No description provided for @fdHomeLinkWireless.
  ///
  /// In ko, this message translates to:
  /// **'무선'**
  String get fdHomeLinkWireless;

  /// No description provided for @fdHomeBuildTitle.
  ///
  /// In ko, this message translates to:
  /// **'빌드'**
  String get fdHomeBuildTitle;

  /// No description provided for @fdHomeModeDebug.
  ///
  /// In ko, this message translates to:
  /// **'Debug'**
  String get fdHomeModeDebug;

  /// No description provided for @fdHomeModeRelease.
  ///
  /// In ko, this message translates to:
  /// **'Release'**
  String get fdHomeModeRelease;

  /// No description provided for @fdHomeTeamLabel.
  ///
  /// In ko, this message translates to:
  /// **'Apple Team ID'**
  String get fdHomeTeamLabel;

  /// No description provided for @fdHomeTeamHelp.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트를 고치지 않고 빌드 인자로만 넘깁니다. developer.apple.com/account → Membership에서 확인하세요'**
  String get fdHomeTeamHelp;

  /// No description provided for @fdHomeStepsTitle.
  ///
  /// In ko, this message translates to:
  /// **'실행할 명령'**
  String get fdHomeStepsTitle;

  /// No description provided for @fdHomeStepPrepare.
  ///
  /// In ko, this message translates to:
  /// **'준비'**
  String get fdHomeStepPrepare;

  /// No description provided for @fdHomeStepBuild.
  ///
  /// In ko, this message translates to:
  /// **'빌드'**
  String get fdHomeStepBuild;

  /// No description provided for @fdHomeStepInstall.
  ///
  /// In ko, this message translates to:
  /// **'설치'**
  String get fdHomeStepInstall;

  /// No description provided for @fdHomeStepLaunch.
  ///
  /// In ko, this message translates to:
  /// **'실행'**
  String get fdHomeStepLaunch;

  /// No description provided for @fdHomeStepRun.
  ///
  /// In ko, this message translates to:
  /// **'실행 (핫 리로드)'**
  String get fdHomeStepRun;

  /// No description provided for @fdHomeActionInstall.
  ///
  /// In ko, this message translates to:
  /// **'빌드 & 설치'**
  String get fdHomeActionInstall;

  /// No description provided for @fdHomeActionBuildRun.
  ///
  /// In ko, this message translates to:
  /// **'빌드 & 실행'**
  String get fdHomeActionBuildRun;

  /// No description provided for @fdHomeActionInstallOnly.
  ///
  /// In ko, this message translates to:
  /// **'설치만'**
  String get fdHomeActionInstallOnly;

  /// No description provided for @fdHomeActionClean.
  ///
  /// In ko, this message translates to:
  /// **'정리 후 패키지 다시 받기'**
  String get fdHomeActionClean;

  /// No description provided for @fdHomeCleanHelp.
  ///
  /// In ko, this message translates to:
  /// **'flutter clean → flutter pub get. 이유 없이 빌드가 실패할 때 해 볼 만합니다.'**
  String get fdHomeCleanHelp;

  /// No description provided for @fdOptTitle.
  ///
  /// In ko, this message translates to:
  /// **'빌드 옵션'**
  String get fdOptTitle;

  /// No description provided for @fdOptDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본값'**
  String get fdOptDefault;

  /// No description provided for @fdOptFlavor.
  ///
  /// In ko, this message translates to:
  /// **'Flavor'**
  String get fdOptFlavor;

  /// No description provided for @fdOptFlavorHelp.
  ///
  /// In ko, this message translates to:
  /// **'--flavor. 프로젝트에 flavor가 있을 때만 입력하세요 (Windows는 Flutter 3.47 이상)'**
  String get fdOptFlavorHelp;

  /// No description provided for @fdOptFlavorInvalid.
  ///
  /// In ko, this message translates to:
  /// **'영문자로 시작하고 영문자·숫자·_·-만 쓸 수 있습니다'**
  String get fdOptFlavorInvalid;

  /// No description provided for @fdOptHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움말'**
  String get fdOptHelp;

  /// No description provided for @fdOptHelpLink.
  ///
  /// In ko, this message translates to:
  /// **'선택한 대상(Android·iOS·Windows …)에 맞는 Flutter 문서의 flavor 설정 방법을 브라우저로 엽니다'**
  String get fdOptHelpLink;

  /// No description provided for @fdOptTarget.
  ///
  /// In ko, this message translates to:
  /// **'진입 파일'**
  String get fdOptTarget;

  /// No description provided for @fdOptTargetHelp.
  ///
  /// In ko, this message translates to:
  /// **'-t. 비우면 lib/main.dart'**
  String get fdOptTargetHelp;

  /// No description provided for @fdOptDefineFile.
  ///
  /// In ko, this message translates to:
  /// **'dart-define 파일'**
  String get fdOptDefineFile;

  /// No description provided for @fdOptDefineFileHelp.
  ///
  /// In ko, this message translates to:
  /// **'--dart-define-from-file. 경로만 저장하고 파일 내용은 읽거나 저장하지 않습니다'**
  String get fdOptDefineFileHelp;

  /// No description provided for @fdOptFileMissing.
  ///
  /// In ko, this message translates to:
  /// **'파일을 찾을 수 없습니다'**
  String get fdOptFileMissing;

  /// No description provided for @fdOptAppId.
  ///
  /// In ko, this message translates to:
  /// **'앱 ID (선택)'**
  String get fdOptAppId;

  /// No description provided for @fdOptAppIdHelp.
  ///
  /// In ko, this message translates to:
  /// **'flavor가 앱 ID를 바꿀 때, 설치 뒤 실행에 쓸 ID (예: art.zoomon.app.dev)'**
  String get fdOptAppIdHelp;

  /// No description provided for @fdOptExtra.
  ///
  /// In ko, this message translates to:
  /// **'추가 인자'**
  String get fdOptExtra;

  /// No description provided for @fdOptExtraHelp.
  ///
  /// In ko, this message translates to:
  /// **'예: --obfuscate --split-debug-info=build/symbols'**
  String get fdOptExtraHelp;

  /// No description provided for @fdOptPick.
  ///
  /// In ko, this message translates to:
  /// **'파일 고르기'**
  String get fdOptPick;

  /// No description provided for @fdOptClear.
  ///
  /// In ko, this message translates to:
  /// **'옵션 지우기'**
  String get fdOptClear;

  /// No description provided for @fdHomeCleanDone.
  ///
  /// In ko, this message translates to:
  /// **'정리했고 패키지를 다시 받았습니다. 이제 빌드해 보세요.'**
  String get fdHomeCleanDone;

  /// No description provided for @fdHomeCleanFailed.
  ///
  /// In ko, this message translates to:
  /// **'정리에 실패했습니다. 기록 탭에서 출력을 확인하세요.'**
  String get fdHomeCleanFailed;

  /// No description provided for @fdHomeActionRun.
  ///
  /// In ko, this message translates to:
  /// **'디버그 실행'**
  String get fdHomeActionRun;

  /// No description provided for @fdHomeActionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get fdHomeActionCancel;

  /// No description provided for @fdHomeActionStop.
  ///
  /// In ko, this message translates to:
  /// **'중지'**
  String get fdHomeActionStop;

  /// No description provided for @fdHomeHotReload.
  ///
  /// In ko, this message translates to:
  /// **'핫 리로드'**
  String get fdHomeHotReload;

  /// No description provided for @fdHomeHotRestart.
  ///
  /// In ko, this message translates to:
  /// **'핫 리스타트'**
  String get fdHomeHotRestart;

  /// No description provided for @fdHomeOutputTitle.
  ///
  /// In ko, this message translates to:
  /// **'출력'**
  String get fdHomeOutputTitle;

  /// No description provided for @fdHomeCopyCommand.
  ///
  /// In ko, this message translates to:
  /// **'명령 복사'**
  String get fdHomeCopyCommand;

  /// No description provided for @fdBlockerNoProject.
  ///
  /// In ko, this message translates to:
  /// **'먼저 Flutter 프로젝트를 여세요'**
  String get fdBlockerNoProject;

  /// No description provided for @fdBlockerNoDevice.
  ///
  /// In ko, this message translates to:
  /// **'기기를 연결하고 선택하세요'**
  String get fdBlockerNoDevice;

  /// No description provided for @fdBlockerPlatformMissing.
  ///
  /// In ko, this message translates to:
  /// **'이 프로젝트에는 선택한 기기의 플랫폼 폴더(ios/ 또는 android/)가 없습니다'**
  String get fdBlockerPlatformMissing;

  /// No description provided for @fdBlockerIosNeedsMac.
  ///
  /// In ko, this message translates to:
  /// **'iPhone에 설치하려면 macOS와 Xcode가 필요합니다'**
  String get fdBlockerIosNeedsMac;

  /// No description provided for @fdBlockerWireless.
  ///
  /// In ko, this message translates to:
  /// **'무선으로 잡힌 기기입니다. USB 케이블로 연결하세요 (무선에서는 설치가 끊깁니다)'**
  String get fdBlockerWireless;

  /// No description provided for @fdBlockerDeveloperModeOff.
  ///
  /// In ko, this message translates to:
  /// **'iPhone의 개발자 모드가 꺼져 있습니다. 설정 → 개인정보 보호 및 보안 → 개발자 모드를 켜고 재시동하세요'**
  String get fdBlockerDeveloperModeOff;

  /// No description provided for @fdBlockerAndroidUnauthorized.
  ///
  /// In ko, this message translates to:
  /// **'폰 화면의 \'USB 디버깅 허용\' 창에서 이 컴퓨터를 승인하세요'**
  String get fdBlockerAndroidUnauthorized;

  /// No description provided for @fdBlockerNeedsTeamId.
  ///
  /// In ko, this message translates to:
  /// **'iOS 서명에 쓸 Apple Team ID를 입력하세요'**
  String get fdBlockerNeedsTeamId;

  /// No description provided for @fdHintUseUsb.
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊겼습니다. 무선이 아니라 USB 케이블로 연결했는지 확인하세요'**
  String get fdHintUseUsb;

  /// No description provided for @fdHintUnlockDevice.
  ///
  /// In ko, this message translates to:
  /// **'iPhone이 잠겨 있습니다. 잠금을 풀고 다시 시도하세요'**
  String get fdHintUnlockDevice;

  /// No description provided for @fdHintDeveloperMode.
  ///
  /// In ko, this message translates to:
  /// **'iPhone의 개발자 모드를 켜세요: 설정 → 개인정보 보호 및 보안 → 개발자 모드'**
  String get fdHintDeveloperMode;

  /// No description provided for @fdHintSigning.
  ///
  /// In ko, this message translates to:
  /// **'서명 프로파일 문제입니다. Team ID가 맞는지, Xcode에 Apple 계정이 로그인되어 있는지 확인하세요'**
  String get fdHintSigning;

  /// No description provided for @fdHintTrustComputer.
  ///
  /// In ko, this message translates to:
  /// **'iPhone에서 \'이 컴퓨터를 신뢰\'를 누르세요'**
  String get fdHintTrustComputer;

  /// No description provided for @fdHintNoAdb.
  ///
  /// In ko, this message translates to:
  /// **'adb를 찾지 못했습니다. Android SDK platform-tools를 설치하고 PATH에 추가하세요'**
  String get fdHintNoAdb;

  /// No description provided for @fdHintMissingCommand.
  ///
  /// In ko, this message translates to:
  /// **'{command} 명령을 찾지 못했습니다. 설치하고 PATH에 있는지 확인하세요'**
  String fdHintMissingCommand(String command);

  /// No description provided for @fdTabInstall.
  ///
  /// In ko, this message translates to:
  /// **'실행'**
  String get fdTabInstall;

  /// No description provided for @fdTabDevices.
  ///
  /// In ko, this message translates to:
  /// **'기기'**
  String get fdTabDevices;

  /// No description provided for @fdTabSigning.
  ///
  /// In ko, this message translates to:
  /// **'서명'**
  String get fdTabSigning;

  /// No description provided for @fdTabDoctor.
  ///
  /// In ko, this message translates to:
  /// **'점검'**
  String get fdTabDoctor;

  /// No description provided for @fdTabLog.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get fdTabLog;

  /// No description provided for @fdBannerNextStep.
  ///
  /// In ko, this message translates to:
  /// **'지금 할 일'**
  String get fdBannerNextStep;

  /// No description provided for @fdBannerShowSteps.
  ///
  /// In ko, this message translates to:
  /// **'해결 방법 보기'**
  String get fdBannerShowSteps;

  /// No description provided for @fdDoctorRun.
  ///
  /// In ko, this message translates to:
  /// **'다시 점검'**
  String get fdDoctorRun;

  /// No description provided for @fdDoctorRunning.
  ///
  /// In ko, this message translates to:
  /// **'점검 중…'**
  String get fdDoctorRunning;

  /// No description provided for @fdDoctorNever.
  ///
  /// In ko, this message translates to:
  /// **'아직 점검하지 않았습니다'**
  String get fdDoctorNever;

  /// No description provided for @fdDoctorCollected.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 점검함'**
  String fdDoctorCollected(String time);

  /// No description provided for @fdDoctorAllGood.
  ///
  /// In ko, this message translates to:
  /// **'문제가 없습니다'**
  String get fdDoctorAllGood;

  /// No description provided for @fdSigningTeams.
  ///
  /// In ko, this message translates to:
  /// **'서명 Team'**
  String get fdSigningTeams;

  /// No description provided for @fdSigningTeamsHelp.
  ///
  /// In ko, this message translates to:
  /// **'키체인에 개인 키가 있는 인증서의 Team입니다. 누르면 이 Team으로 서명합니다'**
  String get fdSigningTeamsHelp;

  /// No description provided for @fdSigningNoTeams.
  ///
  /// In ko, this message translates to:
  /// **'사용할 수 있는 개발 인증서가 없습니다'**
  String get fdSigningNoTeams;

  /// No description provided for @fdSigningCerts.
  ///
  /// In ko, this message translates to:
  /// **'개발 인증서'**
  String get fdSigningCerts;

  /// No description provided for @fdSigningProfiles.
  ///
  /// In ko, this message translates to:
  /// **'이 프로젝트의 프로파일'**
  String get fdSigningProfiles;

  /// No description provided for @fdSigningNoProfiles.
  ///
  /// In ko, this message translates to:
  /// **'아직 없습니다 — 첫 빌드에서 Xcode가 자동으로 만듭니다'**
  String get fdSigningNoProfiles;

  /// No description provided for @fdSigningShortLived.
  ///
  /// In ko, this message translates to:
  /// **'7일 프로파일'**
  String get fdSigningShortLived;

  /// No description provided for @fdSigningNoKey.
  ///
  /// In ko, this message translates to:
  /// **'개인 키 없음'**
  String get fdSigningNoKey;

  /// No description provided for @fdSigningDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String fdSigningDaysLeft(String days);

  /// No description provided for @fdSigningExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료됨'**
  String get fdSigningExpired;

  /// No description provided for @fdSigningAndroid.
  ///
  /// In ko, this message translates to:
  /// **'Android 릴리스 서명'**
  String get fdSigningAndroid;

  /// No description provided for @fdSigningMacOnly.
  ///
  /// In ko, this message translates to:
  /// **'iOS 서명 점검은 macOS에서만 합니다'**
  String get fdSigningMacOnly;

  /// No description provided for @fdElevatedTitle.
  ///
  /// In ko, this message translates to:
  /// **'관리자 권한으로 실행 중입니다'**
  String get fdElevatedTitle;

  /// No description provided for @fdElevatedBody.
  ///
  /// In ko, this message translates to:
  /// **'관리자 권한으로 실행하면 flutter 빌드(CMake)가 실패할 수 있습니다. 앱을 종료하고 일반 권한으로 다시 엽니다.'**
  String get fdElevatedBody;

  /// No description provided for @fdElevatedQuit.
  ///
  /// In ko, this message translates to:
  /// **'종료 후 다시 열기'**
  String get fdElevatedQuit;

  /// No description provided for @fdLogClear.
  ///
  /// In ko, this message translates to:
  /// **'기록 지우기'**
  String get fdLogClear;

  /// No description provided for @fdOutputCopyAll.
  ///
  /// In ko, this message translates to:
  /// **'출력 전체 복사'**
  String get fdOutputCopyAll;

  /// No description provided for @fdOutputCopied.
  ///
  /// In ko, this message translates to:
  /// **'출력을 복사했습니다'**
  String get fdOutputCopied;

  /// No description provided for @fdOutputViewer.
  ///
  /// In ko, this message translates to:
  /// **'뷰어로 보기'**
  String get fdOutputViewer;

  /// No description provided for @fdViewerPause.
  ///
  /// In ko, this message translates to:
  /// **'갱신 멈추기 (텍스트 선택용)'**
  String get fdViewerPause;

  /// No description provided for @fdViewerResume.
  ///
  /// In ko, this message translates to:
  /// **'실시간 갱신 다시 켜기'**
  String get fdViewerResume;

  /// No description provided for @fdViewerLines.
  ///
  /// In ko, this message translates to:
  /// **'{count}줄'**
  String fdViewerLines(Object count);

  /// No description provided for @fdLogEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 실행한 명령이 없습니다'**
  String get fdLogEmpty;

  /// No description provided for @fdLogRunning.
  ///
  /// In ko, this message translates to:
  /// **'실행 중'**
  String get fdLogRunning;

  /// No description provided for @fdLogExit.
  ///
  /// In ko, this message translates to:
  /// **'종료 코드 {code}'**
  String fdLogExit(String code);

  /// No description provided for @fdCheckFlutterOk.
  ///
  /// In ko, this message translates to:
  /// **'Flutter {version}'**
  String fdCheckFlutterOk(String version);

  /// No description provided for @fdCheckFlutterRunFail.
  ///
  /// In ko, this message translates to:
  /// **'flutter를 실행했지만 실패했습니다: {error}'**
  String fdCheckFlutterRunFail(String error);

  /// No description provided for @fdCheckFlutterFail.
  ///
  /// In ko, this message translates to:
  /// **'flutter를 찾지 못했습니다'**
  String get fdCheckFlutterFail;

  /// No description provided for @fdCheckXcodeOk.
  ///
  /// In ko, this message translates to:
  /// **'Xcode {version}'**
  String fdCheckXcodeOk(String version);

  /// No description provided for @fdCheckXcodeFail.
  ///
  /// In ko, this message translates to:
  /// **'Xcode를 찾지 못했습니다'**
  String get fdCheckXcodeFail;

  /// No description provided for @fdCheckAdbOk.
  ///
  /// In ko, this message translates to:
  /// **'adb {version}'**
  String fdCheckAdbOk(String version);

  /// No description provided for @fdCheckAdbWarn.
  ///
  /// In ko, this message translates to:
  /// **'adb를 찾지 못했습니다 (Android 설치에 필요)'**
  String get fdCheckAdbWarn;

  /// No description provided for @fdCheckConnectionOk.
  ///
  /// In ko, this message translates to:
  /// **'{name}: USB로 연결됨'**
  String fdCheckConnectionOk(String name);

  /// No description provided for @fdCheckConnectionFail.
  ///
  /// In ko, this message translates to:
  /// **'{name}: USB가 아니라 무선으로 연결됨'**
  String fdCheckConnectionFail(String name);

  /// No description provided for @fdCheckDeveloperModeOk.
  ///
  /// In ko, this message translates to:
  /// **'iPhone 개발자 모드 켜짐'**
  String get fdCheckDeveloperModeOk;

  /// No description provided for @fdCheckDeveloperModeFail.
  ///
  /// In ko, this message translates to:
  /// **'iPhone 개발자 모드가 꺼져 있음'**
  String get fdCheckDeveloperModeFail;

  /// No description provided for @fdCheckAndroidAuthOk.
  ///
  /// In ko, this message translates to:
  /// **'USB 디버깅 승인됨'**
  String get fdCheckAndroidAuthOk;

  /// No description provided for @fdCheckAndroidAuthFail.
  ///
  /// In ko, this message translates to:
  /// **'USB 디버깅을 승인하지 않음'**
  String get fdCheckAndroidAuthFail;

  /// No description provided for @fdCheckCertificateOk.
  ///
  /// In ko, this message translates to:
  /// **'개발 인증서 {count}개 (개인 키 있음)'**
  String fdCheckCertificateOk(String count);

  /// No description provided for @fdCheckCertificateFail.
  ///
  /// In ko, this message translates to:
  /// **'사용할 수 있는 Apple Development 인증서가 없음'**
  String get fdCheckCertificateFail;

  /// No description provided for @fdCheckCertExpiryOk.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {days}일 남음'**
  String fdCheckCertExpiryOk(String name, String days);

  /// No description provided for @fdCheckCertExpiryWarn.
  ///
  /// In ko, this message translates to:
  /// **'{name} · {days}일 뒤 만료'**
  String fdCheckCertExpiryWarn(String name, String days);

  /// No description provided for @fdCheckCertExpiryFail.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 만료됨'**
  String fdCheckCertExpiryFail(String name);

  /// No description provided for @fdCheckTeamOk.
  ///
  /// In ko, this message translates to:
  /// **'서명 Team {team}'**
  String fdCheckTeamOk(String team);

  /// No description provided for @fdCheckTeamFail.
  ///
  /// In ko, this message translates to:
  /// **'서명할 Team ID가 정해지지 않음'**
  String get fdCheckTeamFail;

  /// No description provided for @fdCheckTeamWarn.
  ///
  /// In ko, this message translates to:
  /// **'Team {team}의 인증서가 이 Mac에 없음'**
  String fdCheckTeamWarn(String team);

  /// No description provided for @fdCheckProfileOk.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일 · {days}일 남음'**
  String fdCheckProfileOk(String bundle, String days);

  /// No description provided for @fdCheckProfileWarn.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일이 곧 만료됨 ({days}일 남음)'**
  String fdCheckProfileWarn(String bundle, String days);

  /// No description provided for @fdCheckProfileFail.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일이 만료됨'**
  String fdCheckProfileFail(String bundle);

  /// No description provided for @fdCheckProfileInfo.
  ///
  /// In ko, this message translates to:
  /// **'{bundle} 프로파일 없음 — 첫 빌드에서 자동으로 만들어짐'**
  String fdCheckProfileInfo(String bundle);

  /// No description provided for @fdCheckProfileShort.
  ///
  /// In ko, this message translates to:
  /// **'무료 계정의 7일 프로파일입니다. 만료되면 다시 빌드해서 설치하세요'**
  String get fdCheckProfileShort;

  /// No description provided for @fdCheckAndroidSigningDebugKey.
  ///
  /// In ko, this message translates to:
  /// **'키스토어 설정 없음 — debug 키로 서명 (개인 기기 설치용으로 충분)'**
  String get fdCheckAndroidSigningDebugKey;

  /// No description provided for @fdCheckAndroidSigningKeystore.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 키스토어로 서명'**
  String get fdCheckAndroidSigningKeystore;

  /// No description provided for @fdCheckAndroidSigningMissing.
  ///
  /// In ko, this message translates to:
  /// **'key.properties가 가리키는 키스토어 파일이 없음'**
  String get fdCheckAndroidSigningMissing;

  /// No description provided for @fdStepsWireless.
  ///
  /// In ko, this message translates to:
  /// **'1. iPhone을 USB 케이블로 Mac에 연결합니다\n2. 잠금을 풀고 \'이 컴퓨터를 신뢰\'를 누릅니다\n3. 기기 새로 고침을 누르고 USB 표시가 뜨는지 확인합니다'**
  String get fdStepsWireless;

  /// No description provided for @fdStepsDeveloperMode.
  ///
  /// In ko, this message translates to:
  /// **'1. iPhone: 설정 → 개인정보 보호 및 보안 → 개발자 모드\n2. 켜고 재시동합니다\n3. 재시동 후 나오는 확인 창에서 \'켜기\'를 누릅니다'**
  String get fdStepsDeveloperMode;

  /// No description provided for @fdStepsAndroidAuth.
  ///
  /// In ko, this message translates to:
  /// **'1. 폰을 USB로 연결하고 잠금을 풉니다\n2. \'USB 디버깅 허용\' 창에서 이 컴퓨터를 허용합니다\n3. 창이 안 뜨면 개발자 옵션에서 USB 디버깅을 켭니다'**
  String get fdStepsAndroidAuth;

  /// No description provided for @fdStepsTeamId.
  ///
  /// In ko, this message translates to:
  /// **'1. developer.apple.com/account → Membership details에서 Team ID(10자)를 확인합니다\n2. 빌드 영역의 Apple Team ID에 입력합니다\n3. 서명 탭에서 인증서의 Team을 눌러 고를 수도 있습니다'**
  String get fdStepsTeamId;

  /// No description provided for @fdStepsCertificate.
  ///
  /// In ko, this message translates to:
  /// **'1. Xcode → Settings → Accounts에서 Apple ID로 로그인합니다\n2. Manage Certificates → + → Apple Development을 추가합니다\n3. 다시 점검을 누릅니다'**
  String get fdStepsCertificate;

  /// No description provided for @fdStepsFlutterMissing.
  ///
  /// In ko, this message translates to:
  /// **'1. flutter.dev에서 Flutter SDK를 설치합니다\n2. flutter/bin을 PATH에 추가합니다 (~/.zshrc)\n3. 앱을 다시 열고 점검을 누릅니다'**
  String get fdStepsFlutterMissing;

  /// No description provided for @fdStepsFlutterMissingWindows.
  ///
  /// In ko, this message translates to:
  /// **'1. flutter.dev에서 Flutter SDK를 설치합니다\n2. flutter\\bin 폴더를 PATH에 추가하거나, 위의 \'도구 경로 지정\'에서 flutter.bat을 직접 고릅니다\n3. 다시 점검을 누릅니다'**
  String get fdStepsFlutterMissingWindows;

  /// No description provided for @fdStepsXcodeMissing.
  ///
  /// In ko, this message translates to:
  /// **'1. App Store에서 Xcode를 설치합니다\n2. 터미널에서 sudo xcode-select -s /Applications/Xcode.app 를 실행합니다\n3. Xcode를 한 번 열어 라이선스에 동의합니다'**
  String get fdStepsXcodeMissing;

  /// No description provided for @fdStepsAdbMissing.
  ///
  /// In ko, this message translates to:
  /// **'1. Android SDK platform-tools를 설치합니다 (Android Studio SDK Manager)\n2. platform-tools 폴더를 PATH에 추가합니다\n3. 다시 점검을 누릅니다'**
  String get fdStepsAdbMissing;

  /// No description provided for @fdStepsAndroidKeystore.
  ///
  /// In ko, this message translates to:
  /// **'1. android/key.properties의 storeFile 경로를 확인합니다\n2. 파일이 없으면 키스토어를 다시 만들거나 경로를 고칩니다\n3. 개인 설치만 한다면 key.properties를 쓰지 않아도 debug 키로 서명됩니다'**
  String get fdStepsAndroidKeystore;

  /// No description provided for @fdStepsCertExpiry.
  ///
  /// In ko, this message translates to:
  /// **'1. Xcode → Settings → Accounts → Manage Certificates에서 새 Apple Development 인증서를 만듭니다\n2. 다시 점검을 누릅니다'**
  String get fdStepsCertExpiry;

  /// No description provided for @fdHomeOpenVsCode.
  ///
  /// In ko, this message translates to:
  /// **'VS Code로 열기'**
  String get fdHomeOpenVsCode;

  /// No description provided for @fdVscodeNotFound.
  ///
  /// In ko, this message translates to:
  /// **'VS Code를 찾지 못했습니다'**
  String get fdVscodeNotFound;

  /// No description provided for @fdVscodeDownload.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get fdVscodeDownload;

  /// No description provided for @fdVscodeOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'VS Code를 열지 못했습니다'**
  String get fdVscodeOpenFailed;

  /// No description provided for @fdSecretFileTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 한 번에 등록'**
  String get fdSecretFileTitle;

  /// No description provided for @fdSecretFileHelp.
  ///
  /// In ko, this message translates to:
  /// **'NAME=값 형식(.env) 파일의 모든 항목을 gh secret set -f로 등록합니다. 이 앱은 값을 읽어 두지 않고 이름만 보여 줍니다. 파일은 gh가 직접 읽습니다.'**
  String get fdSecretFileHelp;

  /// No description provided for @fdSecretFileEmpty.
  ///
  /// In ko, this message translates to:
  /// **'NAME=값 형식의 항목이 없습니다'**
  String get fdSecretFileEmpty;

  /// No description provided for @fdSecretFileUnknown.
  ///
  /// In ko, this message translates to:
  /// **'릴리스 시크릿이 아닌 항목도 함께 등록됩니다: {names}'**
  String fdSecretFileUnknown(String names);

  /// No description provided for @fdSecretFileMissing.
  ///
  /// In ko, this message translates to:
  /// **'파일에 없는 릴리스 시크릿: {names}'**
  String fdSecretFileMissing(String names);

  /// No description provided for @fdSecretFileRegister.
  ///
  /// In ko, this message translates to:
  /// **'파일로 등록'**
  String get fdSecretFileRegister;

  /// No description provided for @fdSecretFileConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 시크릿을 등록할까요?'**
  String fdSecretFileConfirmTitle(int count);

  /// No description provided for @fdSecretFileSaved.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 시크릿을 등록했습니다'**
  String fdSecretFileSaved(int count);

  /// No description provided for @fdSecretFileFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일로 등록하지 못했습니다'**
  String get fdSecretFileFailed;

  /// No description provided for @fdToolPathsOpen.
  ///
  /// In ko, this message translates to:
  /// **'도구 경로 지정…'**
  String get fdToolPathsOpen;

  /// No description provided for @fdToolPathsTitle.
  ///
  /// In ko, this message translates to:
  /// **'도구 경로'**
  String get fdToolPathsTitle;

  /// No description provided for @fdToolPathsHelp.
  ///
  /// In ko, this message translates to:
  /// **'PATH에서 찾지 못하는 도구는 직접 지정할 수 있습니다. 한 번 지정하면 저장되고 다음 실행에도 쓰입니다. 폴더가 아니라 실행 파일을 고르세요.'**
  String get fdToolPathsHelp;

  /// No description provided for @fdToolPathNotFound.
  ///
  /// In ko, this message translates to:
  /// **'찾지 못함'**
  String get fdToolPathNotFound;

  /// No description provided for @fdToolPathChoose.
  ///
  /// In ko, this message translates to:
  /// **'찾아서 지정…'**
  String get fdToolPathChoose;

  /// No description provided for @fdToolPathAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동으로'**
  String get fdToolPathAuto;

  /// No description provided for @fdToolPathCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 지정'**
  String get fdToolPathCustom;

  /// No description provided for @fdToolPathFlutter.
  ///
  /// In ko, this message translates to:
  /// **'flutter'**
  String get fdToolPathFlutter;

  /// No description provided for @fdToolPathAdb.
  ///
  /// In ko, this message translates to:
  /// **'adb (Android SDK platform-tools)'**
  String get fdToolPathAdb;

  /// No description provided for @fdHomeDevicesCauses.
  ///
  /// In ko, this message translates to:
  /// **'기기가 안 보이는 이유일 수 있는 것'**
  String get fdHomeDevicesCauses;

  /// No description provided for @fdStepsNoDevice.
  ///
  /// In ko, this message translates to:
  /// **'1. USB 케이블로 폰을 연결합니다 (충전 전용 케이블은 안 됩니다)\n2. 잠금을 풀고, iPhone은 \'이 컴퓨터를 신뢰\', Android는 \'USB 디버깅 허용\'을 누릅니다\n3. 위의 새로 고침을 누릅니다'**
  String get fdStepsNoDevice;

  /// No description provided for @fdHomeThisMac.
  ///
  /// In ko, this message translates to:
  /// **'이 Mac'**
  String get fdHomeThisMac;

  /// No description provided for @fdHomeThisPc.
  ///
  /// In ko, this message translates to:
  /// **'이 PC'**
  String get fdHomeThisPc;

  /// No description provided for @fdHomeLinkLocal.
  ///
  /// In ko, this message translates to:
  /// **'이 컴퓨터'**
  String get fdHomeLinkLocal;

  /// No description provided for @fdHomePlatformMacos.
  ///
  /// In ko, this message translates to:
  /// **'macOS'**
  String get fdHomePlatformMacos;

  /// No description provided for @fdHomePlatformWindows.
  ///
  /// In ko, this message translates to:
  /// **'Windows'**
  String get fdHomePlatformWindows;

  /// No description provided for @fdHintCocoapods.
  ///
  /// In ko, this message translates to:
  /// **'CocoaPods가 없어 macOS 앱을 빌드하지 못했습니다'**
  String get fdHintCocoapods;

  /// No description provided for @fdHintVisualStudio.
  ///
  /// In ko, this message translates to:
  /// **'Visual Studio의 C++ 데스크톱 개발 구성 요소가 없어 Windows 앱을 빌드하지 못했습니다'**
  String get fdHintVisualStudio;

  /// No description provided for @fdHintRestartApp.
  ///
  /// In ko, this message translates to:
  /// **'빌드 환경이 아직 준비되지 않아 실패했습니다 (플러그인 링크를 찾지 못함). 앱을 종료하고 다시 실행하면 해결됩니다'**
  String get fdHintRestartApp;

  /// No description provided for @fdHintStaleBuildCache.
  ///
  /// In ko, this message translates to:
  /// **'이전 버전의 Visual Studio로 만든 빌드 캐시가 남아 있어 Windows 빌드가 실패했습니다 (Visual Studio를 새 버전으로 바꾼 뒤에 생깁니다). 정리하면 해결됩니다'**
  String get fdHintStaleBuildCache;

  /// No description provided for @fdStepsStaleBuildCache.
  ///
  /// In ko, this message translates to:
  /// **'1. 아래 \'정리 후 패키지 다시 받기\'를 누릅니다 (build 폴더를 지우고 패키지를 다시 받습니다)\n2. 다시 빌드합니다'**
  String get fdStepsStaleBuildCache;

  /// No description provided for @fdRestartAppButton.
  ///
  /// In ko, this message translates to:
  /// **'종료 후 다시 실행'**
  String get fdRestartAppButton;

  /// No description provided for @fdHomeActionBuildOnly.
  ///
  /// In ko, this message translates to:
  /// **'빌드만'**
  String get fdHomeActionBuildOnly;

  /// No description provided for @fdHomeActionRunOnly.
  ///
  /// In ko, this message translates to:
  /// **'실행만'**
  String get fdHomeActionRunOnly;

  /// No description provided for @fdHomeRunOnlyNeedsBuild.
  ///
  /// In ko, this message translates to:
  /// **'실행할 release 결과물이 없습니다. 먼저 빌드하세요'**
  String get fdHomeRunOnlyNeedsBuild;

  /// No description provided for @fdGitTitle.
  ///
  /// In ko, this message translates to:
  /// **'Git'**
  String get fdGitTitle;

  /// No description provided for @fdTabGit.
  ///
  /// In ko, this message translates to:
  /// **'Git'**
  String get fdTabGit;

  /// No description provided for @fdTitleMenuTooltip.
  ///
  /// In ko, this message translates to:
  /// **'최근 프로젝트 · 폴더 열기 · 창 붙이기'**
  String get fdTitleMenuTooltip;

  /// No description provided for @fdMenuRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 프로젝트'**
  String get fdMenuRecent;

  /// No description provided for @fdMenuRecentEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 연 프로젝트가 없습니다'**
  String get fdMenuRecentEmpty;

  /// No description provided for @fdMenuOpenFolder.
  ///
  /// In ko, this message translates to:
  /// **'다른 폴더 열기…'**
  String get fdMenuOpenFolder;

  /// No description provided for @fdMenuDockRight.
  ///
  /// In ko, this message translates to:
  /// **'화면 오른쪽에 붙이기'**
  String get fdMenuDockRight;

  /// No description provided for @fdMenuDockLeft.
  ///
  /// In ko, this message translates to:
  /// **'화면 왼쪽에 붙이기'**
  String get fdMenuDockLeft;

  /// No description provided for @fdGitNotRepo.
  ///
  /// In ko, this message translates to:
  /// **'이 프로젝트 폴더는 git 저장소가 아닙니다'**
  String get fdGitNotRepo;

  /// No description provided for @fdGitChipUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'✓ 최신'**
  String get fdGitChipUpToDate;

  /// No description provided for @fdGitChipBehind.
  ///
  /// In ko, this message translates to:
  /// **'↓ {count}개 받을 수 있음'**
  String fdGitChipBehind(int count);

  /// No description provided for @fdGitChipAhead.
  ///
  /// In ko, this message translates to:
  /// **'↑ {count}개 앞섬'**
  String fdGitChipAhead(int count);

  /// No description provided for @fdGitChipNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'추적 브랜치 없음'**
  String get fdGitChipNoUpstream;

  /// No description provided for @fdGitChipDirty.
  ///
  /// In ko, this message translates to:
  /// **'● 변경 있음'**
  String get fdGitChipDirty;

  /// No description provided for @fdGitWorktree.
  ///
  /// In ko, this message translates to:
  /// **'Worktree'**
  String get fdGitWorktree;

  /// No description provided for @fdGitWorktreeHelp.
  ///
  /// In ko, this message translates to:
  /// **'다른 worktree를 고르면 그 폴더의 같은 프로젝트를 엽니다. 파일은 바꾸지 않습니다'**
  String get fdGitWorktreeHelp;

  /// No description provided for @fdGitDetached.
  ///
  /// In ko, this message translates to:
  /// **'분리된 HEAD'**
  String get fdGitDetached;

  /// No description provided for @fdGitUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'원격과 같음'**
  String get fdGitUpToDate;

  /// No description provided for @fdGitAhead.
  ///
  /// In ko, this message translates to:
  /// **'로컬이 {count}개 앞섬'**
  String fdGitAhead(int count);

  /// No description provided for @fdGitBehind.
  ///
  /// In ko, this message translates to:
  /// **'원격이 {count}개 앞섬'**
  String fdGitBehind(int count);

  /// No description provided for @fdGitNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'추적하는 원격 브랜치 없음'**
  String get fdGitNoUpstream;

  /// No description provided for @fdGitDirty.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경 있음'**
  String get fdGitDirty;

  /// No description provided for @fdGitNoRemote.
  ///
  /// In ko, this message translates to:
  /// **'원격 주소 없음'**
  String get fdGitNoRemote;

  /// No description provided for @fdGitOpenRemote.
  ///
  /// In ko, this message translates to:
  /// **'브라우저로 원격 저장소 열기'**
  String get fdGitOpenRemote;

  /// No description provided for @fdGitFetch.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 (fetch)'**
  String get fdGitFetch;

  /// No description provided for @fdGitPull.
  ///
  /// In ko, this message translates to:
  /// **'받기 (pull)'**
  String get fdGitPull;

  /// No description provided for @fdGitPullHelp.
  ///
  /// In ko, this message translates to:
  /// **'git pull --ff-only — 충돌 없이 앞으로만 합칩니다'**
  String get fdGitPullHelp;

  /// No description provided for @fdGitPullBlockedDirty.
  ///
  /// In ko, this message translates to:
  /// **'커밋하지 않은 변경이 있어 받지 않습니다'**
  String get fdGitPullBlockedDirty;

  /// No description provided for @fdGitPullBlockedDiverged.
  ///
  /// In ko, this message translates to:
  /// **'로컬과 원격이 갈라졌습니다. 터미널에서 병합하세요'**
  String get fdGitPullBlockedDiverged;

  /// No description provided for @fdGitPullBlockedNoUpstream.
  ///
  /// In ko, this message translates to:
  /// **'추적하는 원격 브랜치가 없습니다'**
  String get fdGitPullBlockedNoUpstream;

  /// No description provided for @fdGitPullBlockedUpToDate.
  ///
  /// In ko, this message translates to:
  /// **'받을 변경이 없습니다 (먼저 가져오기를 누르세요)'**
  String get fdGitPullBlockedUpToDate;

  /// No description provided for @fdGitFetchDone.
  ///
  /// In ko, this message translates to:
  /// **'가져왔습니다'**
  String get fdGitFetchDone;

  /// No description provided for @fdGitPullDone.
  ///
  /// In ko, this message translates to:
  /// **'받았습니다'**
  String get fdGitPullDone;

  /// No description provided for @fdGitFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패했습니다. 기록 탭에서 출력을 확인하세요. 자격 증명이 필요하면 터미널에서 한 번 로그인해 두세요'**
  String get fdGitFailed;

  /// No description provided for @fdStepsCocoapods.
  ///
  /// In ko, this message translates to:
  /// **'1. 터미널에서 brew install cocoapods 를 실행합니다\n2. 다시 빌드합니다'**
  String get fdStepsCocoapods;

  /// No description provided for @fdCheckWindowsDevModeOk.
  ///
  /// In ko, this message translates to:
  /// **'Windows 개발자 모드 켜짐 (플러그인 링크를 만들 수 있음)'**
  String get fdCheckWindowsDevModeOk;

  /// No description provided for @fdCheckWindowsDevModeWarn.
  ///
  /// In ko, this message translates to:
  /// **'Windows 개발자 모드가 꺼져 있습니다 (플러그인 링크를 만들지 못해 빌드가 실패할 수 있음)'**
  String get fdCheckWindowsDevModeWarn;

  /// No description provided for @fdCheckVisualStudioOk.
  ///
  /// In ko, this message translates to:
  /// **'Visual Studio {version} (C++ 도구 있음)'**
  String fdCheckVisualStudioOk(String version);

  /// No description provided for @fdCheckVisualStudioFail.
  ///
  /// In ko, this message translates to:
  /// **'Visual Studio의 \'C++를 사용한 데스크톱 개발\'이 없습니다 (Windows 앱 빌드에 필요)'**
  String get fdCheckVisualStudioFail;

  /// No description provided for @fdStepsWindowsDevMode.
  ///
  /// In ko, this message translates to:
  /// **'1. Windows 설정을 열고 \'개발자용\'(개발자 설정)을 검색해 엽니다\n2. \'개발자 모드\'를 켭니다\n3. 다시 점검을 누릅니다'**
  String get fdStepsWindowsDevMode;

  /// No description provided for @fdStepsVisualStudio.
  ///
  /// In ko, this message translates to:
  /// **'1. Visual Studio 2022(Community 가능)를 설치합니다\n2. 설치 관리자에서 \'C++를 사용한 데스크톱 개발\'을 선택합니다\n3. 다시 빌드합니다'**
  String get fdStepsVisualStudio;

  /// No description provided for @fdBranchChangedWhileRunning.
  ///
  /// In ko, this message translates to:
  /// **'실행 중인 빌드가 있는 동안 브랜치가 {branch}(으)로 바뀌었습니다. 빌드는 이전 파일로 계속됩니다.'**
  String fdBranchChangedWhileRunning(String branch);

  /// No description provided for @fdDoctorStale.
  ///
  /// In ko, this message translates to:
  /// **'브랜치가 바뀌었습니다. 이전 브랜치 기준의 점검 결과이니 다시 점검하세요.'**
  String get fdDoctorStale;

  /// No description provided for @fdOperationInProgress.
  ///
  /// In ko, this message translates to:
  /// **'병합·리베이스 등이 진행 중입니다. 충돌 중에는 빌드 결과를 믿을 수 없습니다.'**
  String get fdOperationInProgress;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
