// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get aboutTooltip => '정보';

  @override
  String aboutVersion(String version, String build) {
    return '버전 $version (빌드 $build)';
  }

  @override
  String get aboutOpenSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => '닫기';

  @override
  String aboutMenuItem(String appName) {
    return '$appName 정보';
  }

  @override
  String get themeMenuTooltip => '테마';

  @override
  String get themeSystem => '시스템 설정 따르기';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get languageMenuTooltip => '언어';

  @override
  String get languageSystem => '시스템 설정 따르기 / System';

  @override
  String get languageSystemShort => '시스템';

  @override
  String get settingsTooltip => '설정';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionAppearance => '외형';

  @override
  String get settingsMode => '모드';

  @override
  String get settingsModeSystem => '시스템';

  @override
  String get settingsPalette => '색 구성';

  @override
  String get settingsPaletteSaturn => '새턴';

  @override
  String get settingsPaletteTeal => '청록';

  @override
  String get settingsPaletteAmber => '호박';

  @override
  String get settingsPaletteRose => '장미';

  @override
  String get settingsPaletteSlate => '슬레이트';

  @override
  String get settingsPaletteHighContrast => '고대비';

  @override
  String get aboutTagline => 'Flutter 앱을 GitHub에서 만들고 굴리는 작업대';

  @override
  String get aboutDescription =>
      '편집기 옆에 세워 두는 도킹형 작업대입니다. 같은 폴더를 보며 Git·GitHub(Branch Dock)와 Flutter 앱의 실기기 빌드·설치(Flutty Dock)를 한 창에서 다룹니다.';

  @override
  String get homeEmptyTitle => '저장소 폴더를 끌어다 놓아 시작하세요';

  @override
  String get homeEmptyAction => '폴더 열기';

  @override
  String get updateCheckMenuItem => '업데이트 확인';

  @override
  String get updateChecking => '업데이트를 확인하는 중…';

  @override
  String get updateAvailableTitle => '새 버전이 있습니다';

  @override
  String updateAvailableBody(String appName, String current, String latest) {
    return '$appName $latest 버전이 나왔습니다. (현재 $current)';
  }

  @override
  String get updateReleaseNotes => '변경 내용';

  @override
  String get updateNow => '지금 업데이트';

  @override
  String get updateLater => '나중에';

  @override
  String get updateSkipVersion => '이 버전 건너뛰기';

  @override
  String get updateDownloading => '내려받는 중…';

  @override
  String get updateVerifying => '파일을 확인하는 중…';

  @override
  String updateDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get updateCancel => '취소';

  @override
  String get updateFailedTitle => '업데이트하지 못했습니다';

  @override
  String get updateCheckFailedTitle => '업데이트를 확인하지 못했습니다';

  @override
  String get updateErrorNetwork =>
      '업데이트 서버에 연결하지 못했습니다. 인터넷 연결을 확인한 뒤 다시 시도해 주세요.';

  @override
  String get updateErrorChecksum =>
      '내려받은 파일이 올바르지 않아 설치하지 않았습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get updateErrorInstall => '설치를 시작하지 못했습니다.';

  @override
  String get updateErrorGeneric =>
      '업데이트 서버에서 예상하지 못한 응답을 받았습니다. 잠시 뒤에 다시 시도해 주세요.';

  @override
  String get updateUpToDateTitle => '최신 버전입니다';

  @override
  String updateUpToDateBody(String version) {
    return '$version 버전을 사용 중입니다.';
  }

  @override
  String get updateUnavailableTitle => '직접 설치해 주세요';

  @override
  String updateUnavailableBody(String latest) {
    return '$latest 버전이 있지만 앱에서 자동으로 설치할 수 없습니다. 릴리스 페이지에서 받아 주세요.';
  }

  @override
  String get updateOpenReleasePage => '릴리스 페이지 열기';

  @override
  String get updateBrowserDownloadTitle => '브라우저에서 내려받습니다';

  @override
  String updateBrowserDownloadBody(String appName) {
    return '브라우저가 새 버전 내려받기를 시작합니다. 받은 DMG를 열어 $appName 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.';
  }

  @override
  String get updateMacosOpenedTitle => '설치 창이 열렸습니다';

  @override
  String updateMacosOpenedBody(String appName) {
    return '열린 창에서 $appName 을(를) Applications 폴더로 끌어다 놓아 주세요. 실행 중이면 종료한 뒤 덮어쓰세요.';
  }

  @override
  String get updateWindowsInstallTitle => '설치 프로그램을 열었습니다';

  @override
  String updateWindowsInstallBody(String appName) {
    return '설치하려면 $appName 을(를) 종료해야 합니다. 설치 프로그램의 안내를 따라 주세요.';
  }

  @override
  String updateQuitApp(String appName) {
    return '$appName 종료';
  }

  @override
  String get updateLinuxInstallTitle => '설치를 준비했습니다';

  @override
  String updateLinuxInstallBody(String appName) {
    return '$appName 을(를) 종료하고 설치합니다. 설치가 끝나면 자동으로 다시 시작됩니다.';
  }

  @override
  String get updateQuitAndInstall => '종료하고 설치';

  @override
  String get updateBusyTitle => '지금은 업데이트할 수 없습니다';

  @override
  String get updateBusyBody => '작업이 진행 중입니다. 끝난 뒤에 다시 시도해 주세요.';

  @override
  String get commonCancel => '취소';

  @override
  String get commonRetry => '다시 확인';

  @override
  String get startTitle => '저장소를 열어 시작하세요';

  @override
  String get startDropHint => '폴더를 끌어다 놓아도 됩니다. 저장소가 아닌 폴더는 git init을 권해 드려요.';

  @override
  String get startRecent => '최근 저장소';

  @override
  String get startRemoveRecent => '목록에서 지우기';

  @override
  String startNotARepository(String path) {
    return '\"$path\"는 git 저장소가 아닙니다.';
  }

  @override
  String startNotFound(String path) {
    return '\"$path\" 폴더를 찾을 수 없습니다.';
  }

  @override
  String get startInitRepository => 'git init으로 저장소 만들기';

  @override
  String get startOpening => '저장소를 여는 중…';

  @override
  String get envTitle => '환경';

  @override
  String get envGitMissing => 'git을 찾을 수 없습니다. git이 있어야 저장소를 열 수 있어요.';

  @override
  String get envGhMissing =>
      'gh(GitHub CLI)가 없거나 로그인하지 않았습니다. PR·릴리스 같은 GitHub 기능만 쓸 수 없어요.';

  @override
  String envGitOk(String version) {
    return 'git $version';
  }

  @override
  String envGhOk(String version, String login) {
    return 'gh $version · $login';
  }

  @override
  String envGhVersionOnly(String version) {
    return 'gh $version (로그인 안 됨)';
  }

  @override
  String get dropOverlayTitle => '여기에 놓아 저장소 열기';

  @override
  String get dropMultiple => '폴더 여러 개 중 첫 번째만 열었습니다';

  @override
  String get dropFilesOnly => '폴더를 놓아 주세요';

  @override
  String get dropNotRepoTitle => 'git 저장소가 아닙니다';

  @override
  String dropNotRepoBody(String path) {
    return '\"$path\"를 git 저장소로 만들까요? (git init)';
  }

  @override
  String get dropBusyTitle => '실행 중인 작업이 있습니다';

  @override
  String get dropBusyBody => '다른 저장소를 열면 실행 중인 작업이 중지됩니다.';

  @override
  String get dropStopAndOpen => '중지하고 열기';

  @override
  String dropSelectedDir(String name) {
    return '선택한 폴더를 \"$name\"(으)로 바꿨습니다';
  }

  @override
  String get workspaceOpenFolder => '다른 폴더 열기…';

  @override
  String get workspaceCloseRepo => '저장소 닫기';

  @override
  String get workspaceRecent => '최근 저장소';

  @override
  String get refreshTooltip => '새로 고침';

  @override
  String get alwaysOnTopTooltip => '항상 위에 표시';

  @override
  String branchChipTooltip(String branch) {
    return '브랜치 $branch';
  }

  @override
  String get branchDetached => '분리된 HEAD';

  @override
  String get branchNoUpstream => '원격에 없음';

  @override
  String stateMerging(int count) {
    return '병합 중 · 충돌 $count';
  }

  @override
  String stateRebasing(int count) {
    return 'rebase 중 · 충돌 $count';
  }

  @override
  String get stateOperation => '진행 중인 작업';

  @override
  String stateChanges(int count) {
    return '변경 $count';
  }

  @override
  String get stateUpToDate => '최신';

  @override
  String editorOpenTooltip(String command) {
    return '편집기에서 열기 ($command)';
  }

  @override
  String get editorOpenNoEditor =>
      '편집기를 찾지 못했습니다. VS Code를 설치하면 이 단추로 폴더를 열 수 있어요.';

  @override
  String get editorOpenFailed => '편집기를 열지 못했습니다';

  @override
  String get dockBranchTitle => 'Branch Dock';

  @override
  String get dockFluttyTitle => 'Flutty Dock';

  @override
  String get dockRunTitle => 'Run';

  @override
  String get dockPlaceholderBranch => 'Git·GitHub 도구가 이 칸에 들어옵니다 (단계 3).';

  @override
  String get dockPlaceholderFlutty => 'Flutter 실기기 빌드·설치가 이 칸에 들어옵니다 (단계 4).';

  @override
  String get dockNoProject => 'Flutter 프로젝트 없음';

  @override
  String get dockNoProjectBody =>
      '이 폴더와 한 단계 아래 폴더에서 Flutter 프로젝트를 찾지 못했습니다. 폴더를 바꾸거나 프로젝트가 있는 폴더를 선택하세요.';

  @override
  String dockProjects(int count) {
    return '프로젝트 $count개';
  }

  @override
  String dockLastChange(String text) {
    return '마지막 변화: $text';
  }

  @override
  String dockChangeBranch(String from, String to) {
    return '브랜치 $from → $to';
  }

  @override
  String get dockChangeCommit => '커밋 이동';

  @override
  String get dockChangeOperation => '병합/rebase 상태 변화';

  @override
  String get dockNone => '없음';

  @override
  String get settingsSectionLanguage => '언어';

  @override
  String get settingsFontSize => '글자 크기';

  @override
  String get fontScaleSmall => '작게';

  @override
  String get fontScaleNormal => '보통';

  @override
  String get fontScaleLarge => '크게';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsStateTint => '상태색 배경';

  @override
  String get settingsStateTintHelp => '빌드 중·실패·성공에 따라 배경 색이 은은하게 바뀝니다.';

  @override
  String summaryPush(int count) {
    return 'Push ↑$count 가능';
  }

  @override
  String summaryPull(int count) {
    return 'Pull ↓$count 필요';
  }

  @override
  String get settingsSectionTools => '도구';

  @override
  String get toolsIntro =>
      '앱이 실행하는 외부 도구의 위치입니다. 비워 두면 PATH에서 찾습니다. 직접 지정하면 그 파일을 씁니다.';

  @override
  String toolsFound(String path) {
    return '찾음: $path';
  }

  @override
  String get toolsNotFound => '찾지 못했습니다';

  @override
  String get toolsCustom => '직접 지정';

  @override
  String get toolsBrowse => '찾아보기…';

  @override
  String get toolsClear => '지정 지우기';

  @override
  String get toolsPathHint => '실행 파일 경로';
}
