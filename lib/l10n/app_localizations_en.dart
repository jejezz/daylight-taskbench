// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutTooltip => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String get aboutOpenSourceLicenses => 'Open Source Licenses';

  @override
  String get aboutRepository => 'GitHub';

  @override
  String get commonClose => 'Close';

  @override
  String aboutMenuItem(String appName) {
    return 'About $appName';
  }

  @override
  String get themeMenuTooltip => 'Theme';

  @override
  String get themeSystem => 'Follow System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageMenuTooltip => 'Language';

  @override
  String get languageSystem => 'System / 시스템 설정 따르기';

  @override
  String get languageSystemShort => 'System';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsMode => 'Mode';

  @override
  String get settingsModeSystem => 'System';

  @override
  String get settingsPalette => 'Color scheme';

  @override
  String get settingsPaletteSaturn => 'Saturn';

  @override
  String get settingsPaletteTeal => 'Teal';

  @override
  String get settingsPaletteAmber => 'Amber';

  @override
  String get settingsPaletteRose => 'Rose';

  @override
  String get settingsPaletteSlate => 'Slate';

  @override
  String get settingsPaletteHighContrast => 'High contrast';

  @override
  String get aboutTagline =>
      'A workbench for building and running Flutter apps on GitHub';

  @override
  String get aboutDescription =>
      'A docked desktop workbench that sits beside your editor. It works on one folder and combines Git/GitHub tools (Branch Dock) with build-and-install on real Flutter devices (Flutty Dock) in a single window.';

  @override
  String get homeEmptyTitle => 'Drop a repository folder to get started';

  @override
  String get homeEmptyAction => 'Open folder';

  @override
  String get updateCheckMenuItem => 'Check for Updates';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateAvailableTitle => 'A new version is available';

  @override
  String updateAvailableBody(String appName, String current, String latest) {
    return '$appName $latest is available. You have $current.';
  }

  @override
  String get updateReleaseNotes => 'What\'s new';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateLater => 'Later';

  @override
  String get updateSkipVersion => 'Skip this version';

  @override
  String get updateDownloading => 'Downloading…';

  @override
  String get updateVerifying => 'Verifying the file…';

  @override
  String updateDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String get updateCancel => 'Cancel';

  @override
  String get updateFailedTitle => 'Couldn\'t update';

  @override
  String get updateCheckFailedTitle => 'Couldn\'t check for updates';

  @override
  String get updateErrorNetwork =>
      'Couldn\'t reach the update server. Check your internet connection and try again.';

  @override
  String get updateErrorChecksum =>
      'The downloaded file didn\'t pass verification, so it was not installed. Please try again later.';

  @override
  String get updateErrorInstall => 'Couldn\'t start the installation.';

  @override
  String get updateErrorGeneric =>
      'The update server sent an unexpected response. Please try again later.';

  @override
  String get updateUpToDateTitle => 'You\'re up to date';

  @override
  String updateUpToDateBody(String version) {
    return 'You\'re using version $version.';
  }

  @override
  String get updateUnavailableTitle => 'Install it manually';

  @override
  String updateUnavailableBody(String latest) {
    return 'Version $latest is available, but the app can\'t install it automatically. Please download it from the release page.';
  }

  @override
  String get updateOpenReleasePage => 'Open release page';

  @override
  String get updateBrowserDownloadTitle => 'Downloading in your browser';

  @override
  String updateBrowserDownloadBody(String appName) {
    return 'Your browser is downloading the new version. Open the DMG and drag $appName to the Applications folder. If it\'s running, quit it first and replace the old copy.';
  }

  @override
  String get updateMacosOpenedTitle => 'The installer window is open';

  @override
  String updateMacosOpenedBody(String appName) {
    return 'In the window that opened, drag $appName to the Applications folder. If it\'s running, quit it first and replace the old copy.';
  }

  @override
  String get updateWindowsInstallTitle => 'The installer is open';

  @override
  String updateWindowsInstallBody(String appName) {
    return '$appName must quit before it can be updated. Follow the installer\'s instructions.';
  }

  @override
  String updateQuitApp(String appName) {
    return 'Quit $appName';
  }

  @override
  String get updateLinuxInstallTitle => 'Ready to install';

  @override
  String updateLinuxInstallBody(String appName) {
    return '$appName will quit and install the update, then start again automatically.';
  }

  @override
  String get updateQuitAndInstall => 'Quit and install';

  @override
  String get updateBusyTitle => 'Can\'t update right now';

  @override
  String get updateBusyBody =>
      'A task is in progress. Please try again when it has finished.';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Check again';

  @override
  String get startTitle => 'Open a repository to get started';

  @override
  String get startDropHint =>
      'You can also drop a folder here. For a non-repository folder we offer git init.';

  @override
  String get startRecent => 'Recent repositories';

  @override
  String get startRemoveRecent => 'Remove from list';

  @override
  String startNotARepository(String path) {
    return '\"$path\" is not a git repository.';
  }

  @override
  String startNotFound(String path) {
    return 'Folder \"$path\" was not found.';
  }

  @override
  String get startInitRepository => 'Create a repository with git init';

  @override
  String get startOpening => 'Opening repository…';

  @override
  String get envTitle => 'Environment';

  @override
  String get envGitMissing =>
      'git was not found. git is required to open a repository.';

  @override
  String get envGhMissing =>
      'gh (GitHub CLI) is missing or not signed in. Only GitHub features such as PRs and releases are unavailable.';

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
    return 'gh $version (not signed in)';
  }

  @override
  String get dropOverlayTitle => 'Drop to open the repository';

  @override
  String get dropMultiple => 'Only the first of several folders was opened';

  @override
  String get dropFilesOnly => 'Please drop a folder';

  @override
  String get dropNotRepoTitle => 'Not a git repository';

  @override
  String dropNotRepoBody(String path) {
    return 'Make \"$path\" a git repository? (git init)';
  }

  @override
  String get dropBusyTitle => 'Work is in progress';

  @override
  String get dropBusyBody =>
      'Opening another repository stops the work in progress.';

  @override
  String get dropStopAndOpen => 'Stop and open';

  @override
  String dropSelectedDir(String name) {
    return 'Selected folder changed to \"$name\"';
  }

  @override
  String get workspaceOpenFolder => 'Open another folder…';

  @override
  String get workspaceCloseRepo => 'Close repository';

  @override
  String get workspaceRecent => 'Recent repositories';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get alwaysOnTopTooltip => 'Always on top';

  @override
  String branchChipTooltip(String branch) {
    return 'Branch $branch';
  }

  @override
  String get branchDetached => 'Detached HEAD';

  @override
  String get branchNoUpstream => 'Not on remote';

  @override
  String stateMerging(int count) {
    return 'Merging · $count conflicts';
  }

  @override
  String stateRebasing(int count) {
    return 'Rebasing · $count conflicts';
  }

  @override
  String get stateOperation => 'Operation in progress';

  @override
  String stateChanges(int count) {
    return '$count changes';
  }

  @override
  String get stateUpToDate => 'Up to date';

  @override
  String editorOpenTooltip(String command) {
    return 'Open in editor ($command)';
  }

  @override
  String get editorOpenNoEditor =>
      'No editor found. Install VS Code to open the folder with this button.';

  @override
  String get editorOpenFailed => 'Could not open the editor';

  @override
  String get dockBranchTitle => 'Branch Dock';

  @override
  String get dockFluttyTitle => 'Flutty Dock';

  @override
  String get dockRunTitle => 'Run';

  @override
  String get dockPlaceholderBranch =>
      'Git and GitHub tools arrive in this card (step 3).';

  @override
  String get dockPlaceholderFlutty =>
      'Real-device build and install arrive in this card (step 4).';

  @override
  String get dockNoProject => 'No Flutter project';

  @override
  String get dockNoProjectBody =>
      'No Flutter project was found in this folder or the folders directly below it. Pick another folder.';

  @override
  String dockProjects(int count) {
    return '$count projects';
  }

  @override
  String dockLastChange(String text) {
    return 'Last change: $text';
  }

  @override
  String dockChangeBranch(String from, String to) {
    return 'Branch $from → $to';
  }

  @override
  String get dockChangeCommit => 'Commit moved';

  @override
  String get dockChangeOperation => 'Merge/rebase state changed';

  @override
  String get dockNone => 'none';

  @override
  String get settingsSectionLanguage => 'Language';

  @override
  String get settingsFontSize => 'Text size';

  @override
  String get fontScaleSmall => 'Small';

  @override
  String get fontScaleNormal => 'Normal';

  @override
  String get fontScaleLarge => 'Large';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsStateTint => 'State-tinted background';

  @override
  String get settingsStateTintHelp =>
      'The background tint changes softly with building, failure and success.';

  @override
  String summaryPush(int count) {
    return 'Push ↑$count ready';
  }

  @override
  String summaryPull(int count) {
    return 'Pull ↓$count needed';
  }

  @override
  String get settingsSectionTools => 'Tools';

  @override
  String get toolsIntro =>
      'Locations of the external tools this app runs. Leave empty to search PATH; set a path to use that file.';

  @override
  String toolsFound(String path) {
    return 'Found: $path';
  }

  @override
  String get toolsNotFound => 'Not found';

  @override
  String get toolsCustom => 'Custom';

  @override
  String get toolsBrowse => 'Browse…';

  @override
  String get toolsClear => 'Clear';

  @override
  String get toolsPathHint => 'Path to the executable';
}
