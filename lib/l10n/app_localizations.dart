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
  /// **'편집기 옆에 세워 두는 도킹형 작업대입니다. 같은 폴더를 보며 Git·GitHub(Branch Dock)와 Flutter 앱의 실기기 빌드·설치(Flutty Dock)를 한 창에서 다룹니다.'**
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

  /// No description provided for @envTitle.
  ///
  /// In ko, this message translates to:
  /// **'환경'**
  String get envTitle;

  /// No description provided for @envGitMissing.
  ///
  /// In ko, this message translates to:
  /// **'git을 찾을 수 없습니다. git이 있어야 저장소를 열 수 있어요.'**
  String get envGitMissing;

  /// No description provided for @envGhMissing.
  ///
  /// In ko, this message translates to:
  /// **'gh(GitHub CLI)가 없거나 로그인하지 않았습니다. PR·릴리스 같은 GitHub 기능만 쓸 수 없어요.'**
  String get envGhMissing;

  /// No description provided for @envGitOk.
  ///
  /// In ko, this message translates to:
  /// **'git {version}'**
  String envGitOk(String version);

  /// No description provided for @envGhOk.
  ///
  /// In ko, this message translates to:
  /// **'gh {version} · {login}'**
  String envGhOk(String version, String login);

  /// No description provided for @envGhVersionOnly.
  ///
  /// In ko, this message translates to:
  /// **'gh {version} (로그인 안 됨)'**
  String envGhVersionOnly(String version);

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
  /// **'Branch Dock'**
  String get dockBranchTitle;

  /// No description provided for @dockFluttyTitle.
  ///
  /// In ko, this message translates to:
  /// **'Flutty Dock'**
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
