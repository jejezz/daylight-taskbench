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
      'A docked desktop workbench that sits beside your editor. It works on one folder and combines Git/GitHub tools (Git & GitHub) with build-and-install on real Flutter devices (Flutter Runner) in a single window.';

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
  String get moreTooltip => 'More';

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
  String get dockBranchTitle => 'Git & GitHub';

  @override
  String get dockFluttyTitle => 'Flutter Runner';

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

  @override
  String get bdAboutTagline => 'A desktop companion for Git and the GitHub CLI';

  @override
  String get bdAboutDescription =>
      'Dock it beside your editor and handle branches, tags, merges, pull/push, remotes and releases with buttons that show the exact git and gh commands they run.';

  @override
  String get bdHomeEmptyTitle => 'Choose a repository to get started';

  @override
  String get bdHomeEmptyAction => 'Open repository';

  @override
  String get bdAppBarRefresh => 'Refresh';

  @override
  String get bdAppBarPin => 'Keep on top';

  @override
  String get bdAppBarUnpin => 'Stop keeping on top';

  @override
  String get bdMenuOpenFolder => 'Open another folder…';

  @override
  String get bdMenuEditor => 'Editor for opening files…';

  @override
  String get bdMenuEnvironment => 'Check git and gh';

  @override
  String get bdMenuCloseRepo => 'Close repository';

  @override
  String get bdHostOther => 'Other git server';

  @override
  String get bdCommonCopy => 'Copy';

  @override
  String get bdCommonCopied => 'Copied';

  @override
  String get bdCommonMore => 'More';

  @override
  String get bdCommonSave => 'Save';

  @override
  String get bdCommandPreviewLabel => 'Command to run';

  @override
  String get bdStartDropHint =>
      'You can also drop a git repository folder on this window.';

  @override
  String get bdStartRemoveRecent => 'Remove from list';

  @override
  String bdStartNotARepository(String path) {
    return 'This folder isn\'t a git repository: $path';
  }

  @override
  String bdStartNotFound(String path) {
    return 'Folder not found: $path';
  }

  @override
  String get bdEnvTitle => 'git and GitHub CLI';

  @override
  String get bdEnvGitRequired =>
      'Daylight Taskbench runs the git installed on your computer. Install git first.';

  @override
  String get bdEnvGitOnlyNote =>
      'Branches, pull and push work without gh. Publishing to GitHub, pull requests and releases need gh and a login.';

  @override
  String bdEnvVersion(String version) {
    return 'Version $version';
  }

  @override
  String get bdEnvNotInstalled => 'Not installed, or not found';

  @override
  String get bdEnvLogin => 'GitHub login';

  @override
  String bdEnvLoggedInAs(String login) {
    return 'Logged in as $login';
  }

  @override
  String get bdEnvNotLoggedIn => 'Not logged in. Run this in a terminal.';

  @override
  String get bdEnvRecheck => 'Check again';

  @override
  String get bdEnvGhMissing =>
      'Needs the GitHub CLI (gh), which isn\'t installed. See Check git and gh in the menu.';

  @override
  String get bdEnvGhLoggedOut =>
      'Log in to gh first: run gh auth login in a terminal.';

  @override
  String get bdHeaderOpenFolder => 'Open this folder in the editor';

  @override
  String get bdVscodeMissingTitle => 'VS Code not found';

  @override
  String get bdVscodeMissingMessage =>
      'Install VS Code to open the folder where the current branch is checked out with this button. To use another editor, enter its command (cursor, zed, …) under ‘Editor for opening files…’ in the repository menu.';

  @override
  String get bdVscodeDownload => 'Get VS Code';

  @override
  String get bdHeaderBranchTooltip => 'Show branches';

  @override
  String get bdHeaderDetached => 'Detached HEAD';

  @override
  String get bdHeaderNoUpstream => 'Not on remote';

  @override
  String get bdHeaderNoUpstreamTooltip =>
      'This branch isn\'t on the remote yet. Publish it to push it there.';

  @override
  String bdHeaderAheadTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0 not on the remote yet';
  }

  @override
  String bdHeaderBehindTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count remote commits',
      one: '1 remote commit',
    );
    return '$_temp0 you don\'t have yet';
  }

  @override
  String bdHeaderChanges(int count) {
    return '$count changed';
  }

  @override
  String get bdHeaderUpToDate => 'Up to date';

  @override
  String get bdHeaderNoCommits => 'No commits yet';

  @override
  String bdHeaderMerging(int count) {
    return 'Merging · $count conflicts';
  }

  @override
  String bdHeaderRebasing(int count) {
    return 'Rebasing · $count conflicts';
  }

  @override
  String get bdHeaderFetch => 'Fetch';

  @override
  String get bdHeaderPull => 'Pull';

  @override
  String get bdHeaderPush => 'Push';

  @override
  String get bdHeaderPublish => 'Publish';

  @override
  String get bdPullModeTooltip => 'Pull method';

  @override
  String get bdPullModeTitle => 'How to pull';

  @override
  String get bdPullModeMerge => 'Merge (default)';

  @override
  String get bdPullModeMergeWhen =>
      'If both sides have new commits, joins them with a merge commit. The safest choice.';

  @override
  String get bdPullModeRebase => 'Rebase';

  @override
  String get bdPullModeRebaseWhen =>
      'Moves your commits on top of the new ones to keep history in one line.';

  @override
  String get bdPullModeFastForward => 'Fast-forward only';

  @override
  String get bdPullModeFastForwardWhen =>
      'Only pulls when you have no commits of your own; stops and tells you if history has split.';

  @override
  String get bdOperationAbort => 'Abort';

  @override
  String get bdOperationContinue => 'Continue';

  @override
  String get bdOperationContinueBlocked => 'Resolve every conflict to continue';

  @override
  String get bdOperationAbortTitle => 'Abort the operation in progress?';

  @override
  String get bdOperationAbortMergeMessage =>
      'Goes back to before the merge started. Any conflict resolutions you\'ve made are lost.';

  @override
  String get bdOperationAbortRebaseMessage =>
      'Goes back to before the rebase started. Any conflict resolutions you\'ve made are lost.';

  @override
  String bdBannerConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files have',
      one: '1 file has',
    );
    return '$_temp0 conflicts to resolve';
  }

  @override
  String bdBannerPull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new commits',
      one: '1 new commit',
    );
    return '$_temp0 on the remote';
  }

  @override
  String get bdBannerPublish => 'This branch isn\'t on the remote yet';

  @override
  String bdBannerPush(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits aren\'t',
      one: '1 commit isn\'t',
    );
    return '$_temp0 on the remote yet';
  }

  @override
  String get bdBannerNoRemote => 'This repository isn\'t on GitHub yet';

  @override
  String get bdBannerShow => 'Show';

  @override
  String bdBannerNotGitHub(String host) {
    return 'This is a $host repository. Branches, pull and push all work; pull requests, releases and Actions need a GitHub repository.';
  }

  @override
  String get bdTabChanges => 'Changes';

  @override
  String get bdTabBranches => 'Branches';

  @override
  String get bdTabRemotes => 'Remotes';

  @override
  String get bdChangesMessageHint => 'Commit message';

  @override
  String get bdChangesPrefixTooltip => 'Commit type prefix';

  @override
  String bdChangesFirstLineLong(int length) {
    return 'The first line is $length characters. Keep it under 72 so it isn\'t cut off in lists.';
  }

  @override
  String bdChangesCommitStaged(int count) {
    return 'Commit ($count staged)';
  }

  @override
  String get bdChangesCommitAll => 'Stage all and commit';

  @override
  String get bdChangesConflicts => 'Conflicts';

  @override
  String get bdChangesStaged => 'Staged';

  @override
  String get bdChangesUnstaged => 'Changed';

  @override
  String get bdChangesUntracked => 'Untracked';

  @override
  String get bdChangesStageAll => 'Stage all';

  @override
  String get bdChangesUnstageAll => 'Unstage all';

  @override
  String get bdChangesStage => 'Stage';

  @override
  String get bdChangesUnstage => 'Unstage';

  @override
  String get bdChangesOpenInEditor => 'Open in editor';

  @override
  String get bdChangesMarkResolved => 'Mark resolved';

  @override
  String get bdChangesCleanTitle => 'Nothing to commit';

  @override
  String get bdChangesCleanMessage =>
      'Save a file in your editor and it shows up here.';

  @override
  String get bdBranchesTitle => 'Branches';

  @override
  String get bdBranchesNew => 'New branch';

  @override
  String get bdBranchesCreate => 'Create';

  @override
  String get bdBranchesSearchHint => 'Find a branch';

  @override
  String get bdBranchesLocal => 'Local';

  @override
  String get bdBranchesRemote => 'Remote';

  @override
  String get bdBranchesSwitch => 'Switch to';

  @override
  String get bdBranchesRename => 'Rename';

  @override
  String get bdBranchesDelete => 'Delete';

  @override
  String get bdBranchesDeleteRemote => 'Delete from remote';

  @override
  String get bdBranchesUpstreamGone => 'Gone on remote';

  @override
  String get bdBranchesUnbornTitle => 'No commits yet';

  @override
  String get bdBranchesUnbornMessage =>
      'Make the first commit, then you can create branches.';

  @override
  String get bdBranchesForceDeleteTitle => 'This branch isn\'t merged';

  @override
  String bdBranchesForceDeleteMessage(String name) {
    return '$name has commits that aren\'t merged into another branch. Deleting it makes them hard to find.';
  }

  @override
  String get bdBranchesDeleteRemoteTitle => 'Delete the remote branch?';

  @override
  String bdBranchesDeleteRemoteMessage(String branch, String target) {
    return 'Deletes $branch from $target. Nobody else can fetch it after this.';
  }

  @override
  String get bdBranchNameLabel => 'Branch name';

  @override
  String get bdBranchNameExists => 'A branch with this name already exists';

  @override
  String get bdBranchNameEmpty => 'Enter a name';

  @override
  String get bdBranchNameInvalidCharacter =>
      'Spaces and ~ ^ : ? * [ \\ aren\'t allowed';

  @override
  String get bdBranchNameStartsWithDash => 'Can\'t start with -';

  @override
  String get bdBranchNameInvalidSequence =>
      'Can\'t contain .. or //, a part starting with ., or a part ending in .lock';

  @override
  String get bdBranchNameInvalidEdge =>
      'Can\'t start with / or end with / or .';

  @override
  String get bdBranchBaseLabel => 'Start from';

  @override
  String bdBranchBaseCurrent(String name) {
    return 'Current branch ($name)';
  }

  @override
  String get bdBranchSwitchAfter => 'Switch to it after creating';

  @override
  String bdBranchRenameUpstreamNote(String upstream) {
    return '$upstream on the remote keeps its old name. Publish again under the new name.';
  }

  @override
  String get bdRemotesTitle => 'Remotes';

  @override
  String get bdRemotesAdd => 'Add remote';

  @override
  String get bdRemotesRename => 'Rename';

  @override
  String get bdRemotesSetUrl => 'Change URL';

  @override
  String get bdRemotesRemove => 'Remove remote';

  @override
  String get bdRemotesRemoveTitle => 'Remove this remote?';

  @override
  String bdRemotesRemoveMessage(String name) {
    return 'Only removes the $name link from this repository. The repository on the server stays.';
  }

  @override
  String get bdRemotesEmptyTitle => 'This repository isn\'t on GitHub yet';

  @override
  String get bdRemotesEmptyMessage =>
      'Creates a new repository on GitHub and pushes your current branch.';

  @override
  String get bdRemotesPublishToGitHub => 'Publish to GitHub';

  @override
  String get bdRemotesPublishAlsoToGitHub =>
      'Also publish to GitHub (adds a remote)';

  @override
  String get bdRemotesPublishConfirm => 'Create and publish';

  @override
  String get bdRemotesNotGitHubNote =>
      'Not a GitHub repository, so pull requests, releases and Actions aren\'t available (gh is GitHub-only).';

  @override
  String get bdRemotesNameLabel => 'Remote name';

  @override
  String get bdRemotesNameTaken => 'A remote with this name already exists';

  @override
  String get bdRemotesNameInvalid => 'No spaces or special characters';

  @override
  String get bdRemotesUrlLabel => 'URL';

  @override
  String get bdRemotesUseHttps => 'Use the HTTPS address';

  @override
  String get bdRemotesUseSsh => 'Use the SSH address';

  @override
  String get bdPublishNameLabel => 'Repository name';

  @override
  String get bdPublishNameHelper =>
      'Use org/name to create it in an organization';

  @override
  String get bdPublishNameInvalid => 'Letters, numbers, - _ . only';

  @override
  String get bdPublishDescriptionLabel => 'Description (optional)';

  @override
  String get bdPublishPrivate => 'Private';

  @override
  String get bdPublishPublic => 'Public';

  @override
  String get bdPublishNoCommitsNote =>
      'There are no commits yet, so this only creates the repository. Push after your first commit.';

  @override
  String get bdEditorTitle => 'Editor for opening files';

  @override
  String get bdEditorMessage =>
      'Enter an editor command to open files and the repository folder with it. Leave it empty to open files with the system default app and the folder with VS Code.';

  @override
  String get bdEditorLabel => 'Editor command';

  @override
  String get bdLogTitle => 'Command log';

  @override
  String get bdLogClear => 'Clear';

  @override
  String get bdLogEmpty => 'No commands run yet';

  @override
  String get bdLogToggleTooltip => 'Show or hide the command log';

  @override
  String get bdDoneFetch => 'Fetched from the remote';

  @override
  String get bdDonePull => 'Pulled';

  @override
  String get bdDonePush => 'Pushed';

  @override
  String bdDonePublish(String branch) {
    return 'Published $branch';
  }

  @override
  String get bdDoneCommit => 'Committed';

  @override
  String bdDoneSwitch(String name) {
    return 'Switched to $name';
  }

  @override
  String bdDoneCreateBranch(String name) {
    return 'Created $name';
  }

  @override
  String bdDoneRenameBranch(String name) {
    return 'Renamed to $name';
  }

  @override
  String bdDoneDeleteBranch(String name) {
    return 'Deleted $name';
  }

  @override
  String bdDoneAddRemote(String name) {
    return 'Added remote $name';
  }

  @override
  String bdDoneRenameRemote(String name) {
    return 'Renamed the remote to $name';
  }

  @override
  String bdDoneSetRemoteUrl(String name) {
    return 'Changed the URL of $name';
  }

  @override
  String bdDoneRemoveRemote(String name) {
    return 'Removed remote $name';
  }

  @override
  String bdDonePublishToGitHub(String name) {
    return 'Created $name on GitHub';
  }

  @override
  String get bdDoneAbort => 'Aborted';

  @override
  String get bdDoneContinue => 'Continued';

  @override
  String get bdErrorGeneric => 'The command failed. See the output below.';

  @override
  String get bdErrorPushRejected =>
      'Push was rejected because the remote has commits you don\'t have. Pull first.';

  @override
  String get bdErrorAuthFailed =>
      'Authentication failed. Check that you\'re logged in with gh auth login, or that your SSH key is registered.';

  @override
  String get bdErrorConflict =>
      'There are conflicts. Open the conflicted files from Changes, fix them, then mark them resolved.';

  @override
  String get bdErrorLocalChanges =>
      'Stopped because uncommitted changes would be overwritten. Commit them first.';

  @override
  String get bdErrorNotFastForward =>
      'History has split, so it can\'t fast-forward. Change the pull method to merge or rebase.';

  @override
  String get bdErrorProtectedBranch =>
      'This branch is protected, so you can\'t push to it directly. Push a new branch and open a pull request.';

  @override
  String get bdErrorBranchNotMerged => 'This branch has unmerged commits.';

  @override
  String get bdErrorNoUpstream => 'No upstream branch. Publish it first.';

  @override
  String get bdErrorAlreadyExists => 'That name already exists.';

  @override
  String get bdErrorRepositoryNotFound =>
      'Remote repository not found. Check the URL and your access.';

  @override
  String get bdErrorNetwork => 'Can\'t reach the server. Check your network.';

  @override
  String get bdErrorNotInstalled =>
      'Program not found. See Check git and gh in the menu.';

  @override
  String bdErrorBranchInOtherWorktree(String path) {
    return 'This branch is checked out in another worktree ($path). Git lets only one worktree check out a branch at a time.';
  }

  @override
  String get bdOpenWorktreeFolder => 'Open that folder';

  @override
  String get bdTimeJustNow => 'just now';

  @override
  String bdTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String bdTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String bdTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get bdHelpTooltip => 'What\'s this?';

  @override
  String get bdHelpSectionWord => 'The word';

  @override
  String get bdHelpSectionInGit => 'In git';

  @override
  String get bdHelpSectionWhy => 'Why and when';

  @override
  String get bdHelpSectionLinks => 'Learn more';

  @override
  String get bdHelpCaptionBefore => 'Before';

  @override
  String get bdHelpCaptionAfter => 'After';

  @override
  String get bdHelpCaptionAfterFetch => 'After fetch — your main hasn\'t moved';

  @override
  String get bdHelpCaptionAfterPull => 'After pull — your main catches up';

  @override
  String get bdHelpCaptionAheadOne =>
      'feature is one commit ahead of origin/feature (↑1)';

  @override
  String get bdHelpLinkBranchingBasics =>
      'Pro Git — Basic Branching and Merging';

  @override
  String get bdHelpLinkRemoteBranches => 'Pro Git — Remote Branches';

  @override
  String get bdHelpLinkRebasing => 'Pro Git — Rebasing';

  @override
  String get bdHelpFetchVsPullTitle => 'Fetch vs. pull';

  @override
  String get bdHelpFetchVsPullWord =>
      'To fetch is to go and get something; to pull is to draw it toward you.';

  @override
  String get bdHelpFetchVsPullInGit =>
      'Fetch downloads new commits from the remote (GitHub) and only moves the remote labels such as origin/main. Your branch and files stay as they are. Pull does a fetch and then joins those commits into your branch.';

  @override
  String get bdHelpFetchVsPullWhy =>
      'Fetch when you want to see what changed first; it\'s always safe. Pull when you want to catch up right away. Pull can stop if you have uncommitted changes, so commit first.';

  @override
  String get bdHelpUpstreamTitle => 'Upstream and origin';

  @override
  String get bdHelpUpstreamWord =>
      'Upstream is the part of a river the water comes from. Origin is where something comes from.';

  @override
  String get bdHelpUpstreamInGit =>
      'origin is the default name for the remote you cloned from, usually GitHub. The remote branch your branch is paired with (such as origin/feature) is its upstream. The ↑↓ numbers compare your branch with it.';

  @override
  String get bdHelpUpstreamWhy =>
      'With an upstream, plain Push and Pull know where to go. A new branch has none, so the first push is a Publish (git push -u), which sets it.';

  @override
  String get bdHelpFastForwardTitle => 'Fast-forward';

  @override
  String get bdHelpFastForwardWord =>
      'Winding a tape or video quickly forward.';

  @override
  String get bdHelpFastForwardInGit =>
      'When your branch is simply behind and hasn\'t split off, git makes no new commit; it just moves the branch label forward to the latest commit. It only winds forward along commits that already exist.';

  @override
  String get bdHelpFastForwardWhy =>
      'History stays in one clean line and there\'s nothing to conflict. If both sides have different new commits (history has split) it can\'t wind forward, so fast-forward only stops and you need a merge or rebase. A push rejected as non-fast-forward fails for the same reason.';

  @override
  String get bdHelpMergeCommitTitle => 'Merge commit';

  @override
  String get bdHelpMergeCommitWord =>
      'To merge is to join; two roads becoming one.';

  @override
  String get bdHelpMergeCommitInGit =>
      'Keeps both lines of history as they are and adds one new commit whose parents are both of them. The history shows exactly what was joined and when.';

  @override
  String get bdHelpMergeCommitWhy =>
      'It never rewrites commits you\'ve already shared, so it\'s the safest. Good for branches you share with others. The trade-off is extra merge commits in the history.';

  @override
  String get bdHelpRebaseTitle => 'Rebase';

  @override
  String get bdHelpRebaseWord =>
      'Base is what something stands on; to rebase is to set it on a new base.';

  @override
  String get bdHelpRebaseInGit =>
      'Takes your commits off and replays them one by one on top of the commits you just got. The changes are the same, but they become new commits (C\', D\') and the history is a single line.';

  @override
  String get bdHelpRebaseWhy =>
      'Keeps history clean with no merge commits. Use it only on commits you haven\'t pushed yet: rebasing pushed commits makes your history differ from everyone else\'s and needs a force push.';

  @override
  String get bdTabTags => 'Tags';

  @override
  String get bdTabRelease => 'Release';

  @override
  String get bdTabPr => 'PRs';

  @override
  String bdBranchesMergeInto(String head) {
    return 'Merge into $head';
  }

  @override
  String bdMergeTitle(String source, String into) {
    return 'Merge $source into $into';
  }

  @override
  String bdMergeNothing(String source, String into) {
    return '$source has nothing that $into doesn\'t already have';
  }

  @override
  String bdMergeIncoming(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count incoming commits',
      one: '1 incoming commit',
    );
    return '$_temp0';
  }

  @override
  String get bdMergeFastForward => 'Fast-forward';

  @override
  String get bdMergeFastForwardWhen =>
      'Just moves the label forward, no new commit. History stays in one line.';

  @override
  String get bdMergeFastForwardDisabled =>
      'Not possible: the current branch has its own new commits (history has split).';

  @override
  String get bdMergeMergeCommit => 'Merge commit';

  @override
  String get bdMergeMergeCommitWhen =>
      'Keeps both histories and joins them with a merge commit. The safest choice.';

  @override
  String get bdMergeSquash => 'Squash';

  @override
  String get bdMergeSquashWhen =>
      'Squashes the branch\'s commits into one. One feature, one commit.';

  @override
  String bdMergeSquashNote(String source) {
    return 'If you keep using $source after a squash, the same changes can conflict again. Delete the branch after merging.';
  }

  @override
  String get bdMergeMessageLabel => 'Commit message';

  @override
  String get bdMergeConfirm => 'Merge';

  @override
  String bdDoneMerge(String source, String into) {
    return 'Merged $source into $into';
  }

  @override
  String get bdTagsTitle => 'Tags';

  @override
  String get bdTagsNew => 'New tag';

  @override
  String get bdTagsCreate => 'Create';

  @override
  String get bdTagsCreateAndPush => 'Create and push';

  @override
  String bdTagsPushAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Push $_temp0 not on the remote';
  }

  @override
  String get bdTagsPushed => 'On the remote';

  @override
  String get bdTagsLocalOnly => 'Only on this computer';

  @override
  String get bdTagsLightweight => 'Lightweight';

  @override
  String get bdTagsAnnotated => 'Annotated';

  @override
  String get bdTagsPush => 'Push';

  @override
  String get bdTagsDelete => 'Delete';

  @override
  String get bdTagsDeleteRemote => 'Delete from remote';

  @override
  String get bdTagsDeleteRemoteTitle => 'Delete the remote tag?';

  @override
  String bdTagsDeleteRemoteMessage(String tag, String target) {
    return 'Deletes $tag from $target. Others may already have it, so use the next number instead of reusing the name.';
  }

  @override
  String get bdTagsEmptyTitle => 'No tags yet';

  @override
  String get bdTagsEmptyMessage =>
      'A tag is a name for a specific commit, usually a release version like v1.0.0.';

  @override
  String bdTagsPushAfter(String remote) {
    return 'Push to $remote after creating';
  }

  @override
  String get bdTagNameLabel => 'Tag name';

  @override
  String get bdTagNameExists => 'A tag with this name already exists';

  @override
  String get bdTagNameInvalid => 'No spaces, .., or ~ ^ : ? * [ \\';

  @override
  String get bdTagNameNotSemVer =>
      'Not a version (v1.2.3). Allowed, but releases should use versions.';

  @override
  String get bdTagNameMissingV => 'Release tags usually start with v (v1.2.3).';

  @override
  String get bdTagMessageLabel => 'Message';

  @override
  String get bdTagTargetLabel => 'Tag which commit';

  @override
  String bdTagTargetHead(String name) {
    return 'Current position ($name)';
  }

  @override
  String bdDoneCreateTag(String name) {
    return 'Created tag $name';
  }

  @override
  String bdDonePushTags(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tags',
      one: '1 tag',
    );
    return 'Pushed $_temp0';
  }

  @override
  String bdDoneDeleteTag(String name) {
    return 'Deleted tag $name';
  }

  @override
  String bdDoneDeleteRemoteTag(String name) {
    return 'Deleted tag $name from the remote';
  }

  @override
  String get bdPrTitle => 'Pull request';

  @override
  String get bdPrCreate => 'Create pull request';

  @override
  String get bdPrPublishAndCreate => 'Publish and create';

  @override
  String get bdPrTitleLabel => 'Title';

  @override
  String get bdPrBodyLabel => 'Description';

  @override
  String get bdPrBodyChanges => 'Changes';

  @override
  String get bdPrDraft => 'Create as draft';

  @override
  String get bdPrNotGitHubTitle => 'Not a GitHub repository';

  @override
  String get bdPrNotGitHubMessage =>
      'Pull requests need a GitHub repository — gh only works with GitHub.';

  @override
  String get bdPrGhRequiredTitle => 'Needs gh';

  @override
  String get bdPrDetached => 'Not on a branch';

  @override
  String get bdPrOnDefaultTitle => 'You\'re on the default branch';

  @override
  String get bdPrOnDefaultMessage =>
      'Pull requests come from a work branch. Create one in Branches.';

  @override
  String bdPrNoneTitle(String head) {
    return '$head has no pull request yet';
  }

  @override
  String bdPrNoneMessage(String base) {
    return 'Open a pull request into $base to review, check and merge it on GitHub.';
  }

  @override
  String get bdPrOpenOnGitHub => 'Open on GitHub';

  @override
  String get bdPrStateOpen => 'Open';

  @override
  String get bdPrStateDraft => 'Draft';

  @override
  String get bdPrStateMerged => 'Merged';

  @override
  String get bdPrStateClosed => 'Closed';

  @override
  String get bdPrNoChecks => 'No checks';

  @override
  String bdPrChecksPassed(int n) {
    return '$n passed';
  }

  @override
  String bdPrChecksFailed(int n) {
    return '$n failed';
  }

  @override
  String bdPrChecksPending(int n) {
    return '$n running';
  }

  @override
  String get bdPrApproved => 'Approved';

  @override
  String get bdPrReviewRequired => 'Review required';

  @override
  String get bdPrBlockedDraft =>
      'Draft pull requests can\'t be merged. Mark it ready for review on GitHub.';

  @override
  String get bdPrBlockedConflict =>
      'It conflicts with the base branch. Merge the base branch in and resolve the conflicts.';

  @override
  String bdPrBlockedChecks(String names) {
    return 'Some checks failed: $names';
  }

  @override
  String bdPrBlockedPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checks are',
      one: '1 check is',
    );
    return '$_temp0 still running.';
  }

  @override
  String get bdPrBlockedReview =>
      'A review may be required. If merging is refused, check on GitHub.';

  @override
  String get bdPrMethodMerge => 'Merge commit';

  @override
  String get bdPrMethodSquash => 'Squash and merge';

  @override
  String get bdPrMethodRebase => 'Rebase and merge';

  @override
  String get bdPrDeleteBranch => 'Delete the branch after merging';

  @override
  String get bdPrMerge => 'Merge';

  @override
  String get bdPrMerging => 'Merging…';

  @override
  String get bdDonePrCreated => 'Pull request created';

  @override
  String bdDonePrMerged(int number) {
    return 'Merged pull request #$number';
  }

  @override
  String get bdReleaseTitle => 'Release';

  @override
  String bdReleaseLatest(String tag) {
    return 'Latest release $tag';
  }

  @override
  String get bdReleaseNoTags => 'No releases yet';

  @override
  String get bdReleaseIntro =>
      'Walks you through version bump → PR → merge → tag → CI.';

  @override
  String get bdReleaseNeedsGitHub =>
      'The release wizard needs a GitHub repository. You can still create tags in Tags.';

  @override
  String get bdReleaseStart => 'New release';

  @override
  String get bdReleaseNew => 'New release';

  @override
  String bdReleaseNewVersion(String tag) {
    return 'New release $tag';
  }

  @override
  String get bdReleaseCancel => 'Stop';

  @override
  String get bdReleaseCancelTitle => 'Stop this release?';

  @override
  String bdReleaseCancelMessage(String branch) {
    return 'The $branch branch and pull request made so far stay. Delete them yourself if you don\'t need them.';
  }

  @override
  String get bdReleaseCancelAfterTag =>
      'The tag is already pushed. This only closes the wizard; check CI and the release on GitHub.';

  @override
  String bdReleaseDone(String tag) {
    return '$tag is released';
  }

  @override
  String get bdReleasePrerelease => 'Pre-release';

  @override
  String get bdReleasePushAndPr => 'Push and create PR';

  @override
  String get bdStepCheck => 'Check';

  @override
  String get bdStepVersion => 'Version';

  @override
  String get bdStepPr => 'Pull request';

  @override
  String get bdStepMerge => 'Merge';

  @override
  String get bdStepTag => 'Tag';

  @override
  String get bdStepNotes => 'Release notes';

  @override
  String get bdStepNotesCi => 'Notes (after CI release)';

  @override
  String get bdStepNotesCiSummary => 'CI creates the release';

  @override
  String get bdStepCi => 'CI';

  @override
  String get bdStepNext => 'Next';

  @override
  String get bdStepCheckDone => 'All passed';

  @override
  String bdStepMergeDone(int number) {
    return 'PR #$number merged';
  }

  @override
  String get bdCheckCleanTree => 'No uncommitted changes';

  @override
  String get bdCheckShowChanges => 'Show changes';

  @override
  String bdCheckOnDefault(String branch) {
    return 'On the default branch ($branch)';
  }

  @override
  String get bdCheckSynced => 'Nothing to pull or push';

  @override
  String get bdCheckGitHub => 'GitHub remote and gh login';

  @override
  String get bdCheckGitBash =>
      'Git for Windows bash (for the version bump script)';

  @override
  String bdCheckChangesSince(int count, String tag) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0 since $tag';
  }

  @override
  String get bdCheckFirstRelease => 'This is the first release';

  @override
  String get bdCheckNoWorkflow =>
      'No workflow runs on tags, so the app creates the GitHub release.';

  @override
  String bdCheckWorkflowCi(String file) {
    return '$file creates the release when a tag is pushed. The app tags and then watches CI.';
  }

  @override
  String bdCheckWorkflowOther(String file) {
    return '$file runs when a tag is pushed.';
  }

  @override
  String get bdManualBuildTitle => 'Build check before tagging (recommended)';

  @override
  String get bdManualBuildWhy =>
      'Files that affect the build changed since the last release. Check that every platform builds before tagging. A manual run never publishes.';

  @override
  String get bdManualBuildStart => 'Run build check';

  @override
  String bdManualBuildShort(String state) {
    return 'build check $state';
  }

  @override
  String get bdDoneManualBuildStarted => 'Build check started';

  @override
  String bdVersionCurrent(String version, String source) {
    return 'Current $version ($source)';
  }

  @override
  String get bdVersionFromTag => 'last tag';

  @override
  String get bdVersionRecommended => 'Suggested';

  @override
  String bdVersionReason(int feats, int fixes, int breaking) {
    return '$feats features · $fixes fixes · $breaking breaking';
  }

  @override
  String get bdVersionCustom => 'Custom version';

  @override
  String get bdVersionFiles => 'Files to change';

  @override
  String get bdVersionNoFiles => 'No version file, so only the tag is created.';

  @override
  String get bdVersionCommit => 'Create release branch and commit';

  @override
  String get bdBumpFinal => 'Final';

  @override
  String get bdBumpPrerelease => 'Pre-release';

  @override
  String bdDoneReleaseCommit(String tag) {
    return 'Committed the $tag version bump';
  }

  @override
  String bdMergeWaiting(int number) {
    return 'Waiting for PR #$number to merge — merging on GitHub works too';
  }

  @override
  String bdTagCheckPrMerged(int number) {
    return 'PR #$number is merged';
  }

  @override
  String bdTagCheckSynced(String branch) {
    return 'On $branch with nothing to pull or push';
  }

  @override
  String bdTagCheckVersion(String tag) {
    return 'Version files match $tag';
  }

  @override
  String bdTagCheckVersionWrong(String version) {
    return 'The version is $version. The version bump PR may not be merged yet.';
  }

  @override
  String bdTagCheckFree(String tag) {
    return '$tag doesn\'t exist yet';
  }

  @override
  String bdTagConfirmTitle(String tag) {
    return 'Push tag $tag?';
  }

  @override
  String bdTagConfirmMessage(String tag, String branch) {
    return 'Tags the merge commit on $branch as $tag. Pushing publishes the release, and tags aren\'t moved or deleted afterwards.';
  }

  @override
  String get bdTagConfirmPush => 'Tag and push';

  @override
  String bdDoneTagPushed(String tag) {
    return 'Pushed $tag';
  }

  @override
  String get bdNotesLabel => 'Release notes (Markdown)';

  @override
  String get bdNotesFeatures => 'New features';

  @override
  String get bdNotesFixes => 'Bug fixes';

  @override
  String get bdNotesOther => 'Other changes';

  @override
  String get bdNotesCreateRelease => 'Create GitHub release';

  @override
  String get bdNotesEdit => 'Edit notes';

  @override
  String get bdDoneReleaseCreated => 'GitHub release created';

  @override
  String get bdDoneNotesSaved => 'Release notes saved';

  @override
  String bdCiWaitingForRun(String tag) {
    return 'Looking for the workflow run for $tag';
  }

  @override
  String get bdCiOpenInBrowser => 'Open in browser';

  @override
  String get bdCiRerunFailed => 'Re-run failed jobs';

  @override
  String get bdDoneRerun => 'Re-running failed jobs';

  @override
  String get bdRunQueued => 'queued';

  @override
  String get bdRunRunning => 'running';

  @override
  String get bdRunSuccess => 'succeeded';

  @override
  String get bdRunFailure => 'failed';

  @override
  String get bdRunCancelled => 'cancelled';

  @override
  String get bdRunSkipped => 'skipped';

  @override
  String get bdHelpCaptionAfterSquash =>
      'After a squash merge — one new commit S on main';

  @override
  String get bdHelpCaptionTag =>
      'v1.0.0 and v1.1.0 stay put; main keeps moving forward';

  @override
  String get bdHelpLinkGitHubMergeMethods => 'GitHub — About merge methods';

  @override
  String get bdHelpLinkTagging => 'Pro Git — Tagging';

  @override
  String get bdHelpSquashTitle => 'Squash';

  @override
  String get bdHelpSquashWord => 'To press something flat.';

  @override
  String get bdHelpSquashInGit =>
      'Presses the branch\'s commits into a single commit on the target branch. The changes are the same; only the number of commits becomes one.';

  @override
  String get bdHelpSquashWhy =>
      'Keeps work-in-progress commits like \'fix typo\' out of the main history: one feature, one commit. Common when merging pull requests. The original commits don\'t reach the default branch, so delete the merged branch instead of reusing it.';

  @override
  String get bdHelpTagTitle => 'Tags (annotated and lightweight)';

  @override
  String get bdHelpTagWord => 'A tag is a label you attach to something.';

  @override
  String get bdHelpTagInGit =>
      'A name attached to one commit. A branch label moves forward with new commits; a tag stays on its commit. An annotated tag also stores who made it, when, and a message; a lightweight tag stores only the name.';

  @override
  String get bdHelpTagWhy =>
      'Use annotated tags for release versions (v1.2.0): the release is recorded, and GitHub releases and CI run from the tag. Don\'t move or delete a pushed tag; if it\'s wrong, tag the next number.';

  @override
  String get bdHeaderMergedAndGone => 'Merged · deleted on remote';

  @override
  String get bdHeaderMergedAndGoneTooltip =>
      'This branch is already merged into the default branch and was deleted on the remote. Publishing it again would bring the deleted branch back.';

  @override
  String bdBannerMergedAndGone(String branch) {
    return 'This branch was merged and deleted on the remote. Go back to $branch';
  }

  @override
  String bdBannerSwitchTo(String branch) {
    return 'Switch to $branch';
  }

  @override
  String bdBannerCreatePr(String branch) {
    return '$branch is pushed but has no pull request yet';
  }

  @override
  String get bdPrBaseLabel => 'Base branch';

  @override
  String bdPrBaseNotDefault(String base) {
    return 'Merges into a branch other than the default ($base) — for a PR stacked on another feature branch.';
  }

  @override
  String get bdTabCi => 'CI';

  @override
  String get bdCiTitle => 'Workflow runs';

  @override
  String get bdCiNotGitHubMessage =>
      'Actions need a GitHub repository — gh only works with GitHub.';

  @override
  String bdCiEmptyTitle(String branch) {
    return 'No runs on $branch yet';
  }

  @override
  String get bdCiEmptyMessage =>
      'Runs triggered by pushes, pull requests or tags show up here.';

  @override
  String get bdCiRerun => 'Re-run';

  @override
  String get bdCiCancel => 'Cancel run';

  @override
  String get bdCiDispatch => 'Run workflow';

  @override
  String get bdCiDispatchNeedsPush =>
      'Manual runs need a branch that\'s on the remote. Publish it first.';

  @override
  String bdCiDispatchTitle(String file) {
    return 'Run $file';
  }

  @override
  String bdCiDispatchMessage(String branch) {
    return 'Runs the workflow on $branch. For workflows that need inputs, run them in the browser.';
  }

  @override
  String get bdCiDispatchConfirm => 'Run';

  @override
  String bdDoneDispatched(String file) {
    return 'Started $file';
  }

  @override
  String get bdDoneRunCancelled => 'Run cancelled';

  @override
  String bdNotifyRunTitle(String name, String state) {
    return '$name $state';
  }

  @override
  String bdNotifyReleaseRun(String tag, String state) {
    return '$tag release CI $state';
  }

  @override
  String bdNotifyManualBuild(String state) {
    return 'Build check $state';
  }

  @override
  String get bdPrFilterMine => 'Mine';

  @override
  String get bdPrFilterReview => 'To review';

  @override
  String get bdPrFilterOpen => 'All open';

  @override
  String get bdPrListEmpty => 'No open pull requests';

  @override
  String get bdPrCurrentBranch => 'Current branch';

  @override
  String get bdPrCheckout => 'Check out this PR';

  @override
  String get bdPrCheckoutWhy =>
      'Fetches the PR\'s branch and switches to it — to try it out or fix something.';

  @override
  String bdDonePrCheckout(int number, String branch) {
    return 'Switched to $branch from PR #$number';
  }

  @override
  String get bdReleasesTitle => 'Releases';

  @override
  String get bdReleasesEmpty => 'No GitHub releases';

  @override
  String get bdReleasesLoadFailed => 'Couldn\'t load releases';

  @override
  String get bdReleaseLatestPill => 'Latest';

  @override
  String get bdReleaseDraft => 'Draft';

  @override
  String get bdReleaseMakeFinal => 'Mark as full release';

  @override
  String get bdReleaseMakePrerelease => 'Mark as pre-release';

  @override
  String get bdReleasePublishDraft => 'Publish draft';

  @override
  String get bdReleaseDelete => 'Delete release';

  @override
  String bdReleaseDeleteTitle(String tag) {
    return 'Delete the $tag release?';
  }

  @override
  String get bdReleaseDeleteMessage =>
      'The GitHub release and its files are removed. People may have downloaded them already.';

  @override
  String bdReleaseDeleteTagToo(String tag) {
    return 'Also delete the $tag tag on GitHub (the local tag stays)';
  }

  @override
  String bdDoneReleaseDeleted(String tag) {
    return 'Deleted the $tag release';
  }

  @override
  String bdDoneReleaseMadeFinal(String tag) {
    return '$tag is now a full release';
  }

  @override
  String bdDoneReleaseMadePrerelease(String tag) {
    return '$tag is now a pre-release';
  }

  @override
  String bdDoneReleasePublished(String tag) {
    return 'Published the $tag draft';
  }

  @override
  String get bdNotesEditTab => 'Edit';

  @override
  String get bdNotesPreviewTab => 'Preview';

  @override
  String get bdNotesEmpty => 'Nothing to preview';

  @override
  String bdTagVersionMismatch(String file, String version, String tag) {
    return '$file says $version, but the tag is $tag.';
  }

  @override
  String get bdTagVersionMismatchWhy =>
      'A release tag goes on the commit that bumps the version — the release wizard does the bump PR through the tag in order.';

  @override
  String get bdTagVersionMismatchCi =>
      'In this repository pushing a tag makes CI build the release, and CI stops when the versions differ.';

  @override
  String get bdTagVersionMismatchBlocked =>
      'So pushing is blocked. Turn off push to create it only locally.';

  @override
  String get bdTagOpenReleaseWizard => 'Open the release wizard';

  @override
  String get bdTabHistory => 'History';

  @override
  String get bdMenuAutoFetch => 'Auto fetch (every 5 min and on return)';

  @override
  String get bdChangesAmendToggle => 'Amend the last commit';

  @override
  String get bdChangesAmend => 'Amend';

  @override
  String get bdChangesAmendPushedWarning =>
      'This commit is already on the remote. Amending splits the history and needs a force push (force-with-lease).';

  @override
  String get bdDoneAmend => 'Amended the last commit';

  @override
  String get bdChangesDiscard => 'Discard changes';

  @override
  String bdChangesDiscardMessage(String path) {
    return 'Throws away the uncommitted changes in $path and goes back to the last staged (or committed) version. This can\'t be undone.';
  }

  @override
  String get bdChangesDeleteUntracked => 'Delete file';

  @override
  String bdChangesDeleteUntrackedMessage(String path) {
    return 'Deletes $path, which git doesn\'t track. It doesn\'t go to the trash.';
  }

  @override
  String get bdConflictUseMine => 'Use mine';

  @override
  String get bdConflictUseIncoming => 'Use incoming';

  @override
  String get bdConflictByBlock => 'Resolve block by block';

  @override
  String bdConflictSheetTitle(String name) {
    return 'Resolve conflicts in $name';
  }

  @override
  String bdConflictBlockTitle(int index, int total) {
    return 'Conflict $index of $total';
  }

  @override
  String get bdConflictSideMine => 'Mine';

  @override
  String get bdConflictSideIncoming => 'Incoming';

  @override
  String get bdConflictKeepBoth => 'Keep both (top, then bottom)';

  @override
  String get bdConflictEmptySide => '(empty)';

  @override
  String bdConflictPickHint(int left) {
    return 'Pick a side for each block. $left left.';
  }

  @override
  String get bdConflictApply => 'Apply and mark resolved';

  @override
  String get bdConflictApplyNote =>
      'Rewrites the file as you chose and runs git add. To edit by hand, open it in your editor.';

  @override
  String get bdConflictBroken =>
      'The conflict markers are damaged, so the app can\'t read them. Fix the file in your editor.';

  @override
  String get bdConflictNone =>
      'This file has no conflict markers. If you already fixed it, just press Mark resolved.';

  @override
  String get bdConflictUnreadable =>
      'Can\'t read the file (it may be binary or deleted). Use \"Use mine\" or \"Use incoming\" instead.';

  @override
  String bdDoneConflictResolved(String name) {
    return '$name: conflict resolved';
  }

  @override
  String get bdChangesOperationTitle => 'The operation isn\'t finished yet';

  @override
  String get bdChangesOperationMessage =>
      'All conflicts are resolved. Press Continue above to finish, or Abort to go back to before it started.';

  @override
  String get bdConflictReopen => 'Back to conflicted';

  @override
  String bdConflictReopenMessage(String path) {
    return 'Puts $path back the way it was right after the conflict. What you resolved so far is lost and the conflict markers come back.';
  }

  @override
  String get bdConflictReopenConfirm => 'Reopen conflict';

  @override
  String get bdConflictMarkersLeftTitle =>
      'Conflict markers are still in the file';

  @override
  String bdConflictMarkersLeftMessage(String path, int count) {
    return '$path still has $count `<<<<<<<` marker(s). If you mark it resolved now, the markers get committed as they are. Clean it up first with \"Resolve block by block\" or in your editor.';
  }

  @override
  String get bdConflictMarkersLeftConfirm => 'Mark resolved anyway';

  @override
  String bdDoneFileAction(String name) {
    return '$name: done';
  }

  @override
  String get bdStashTitle => 'Stashes';

  @override
  String get bdStashSave => 'Stash changes';

  @override
  String get bdStashSaveFile => 'Stash this file only';

  @override
  String get bdStashFileToStage => 'Move to staged';

  @override
  String bdStashFileOverwriteMessage(String path) {
    return '$path already has changes. They will be overwritten with the stashed version.';
  }

  @override
  String get bdStashEmpty => 'Couldn\'t load the file list.';

  @override
  String bdStashWhy(int count) {
    return 'Puts your $count changes aside without committing, including untracked files. Bring them back later with Apply.';
  }

  @override
  String get bdStashMessageLabel => 'Note (optional)';

  @override
  String get bdStashPop => 'Apply and remove (pop)';

  @override
  String get bdStashApply => 'Apply and keep (apply)';

  @override
  String get bdStashDrop => 'Delete';

  @override
  String get bdStashDropTitle => 'Delete this stash?';

  @override
  String bdStashDropMessage(String text) {
    return 'The changes saved in \'$text\' will be lost.';
  }

  @override
  String get bdStashAndRetry => 'Stash and retry';

  @override
  String get bdStashAutoMessage => 'Branch Dock: auto stash';

  @override
  String get bdDoneStashSaved => 'Stashed';

  @override
  String get bdDoneStashApplied => 'Stash applied';

  @override
  String get bdDoneStashDropped => 'Stash deleted';

  @override
  String get bdDoneStashAndRetry =>
      'Stashed your changes and ran it again. Restore them from Stashes in Changes.';

  @override
  String get bdPushOptionsTooltip => 'Push options';

  @override
  String get bdPushOptionsTitle => 'Push options';

  @override
  String get bdPushFollowTags => 'Push tags too (--follow-tags)';

  @override
  String get bdPushFollowTagsWhy =>
      'Also pushes annotated tags on the commits you push. Applies to this repository only.';

  @override
  String get bdPushForceTitle => 'Force push (force-with-lease)';

  @override
  String get bdPushForceWhy =>
      'Only after amending or rebasing commits you already pushed. git refuses if the remote has commits you haven\'t seen, so nobody else\'s work is overwritten.';

  @override
  String bdPushForceBlockedDefault(String branch) {
    return 'Force push is blocked on the default branch ($branch) — it could overwrite other people\'s history.';
  }

  @override
  String get bdPushForce => 'Force push';

  @override
  String bdPushForceConfirmTitle(String branch) {
    return 'Force push $branch?';
  }

  @override
  String bdPushForceConfirmMessage(String branch, String upstream) {
    return 'Replaces $upstream with your $branch. If someone pushed since your last fetch, git refuses.';
  }

  @override
  String get bdOperationSkip => 'Skip';

  @override
  String get bdOperationSkipTooltip =>
      'Drops the conflicting commit and continues the rebase';

  @override
  String get bdDoneSkip => 'Skipped the commit';

  @override
  String get bdBranchesSetUpstream => 'Set upstream';

  @override
  String bdBranchesSetUpstreamWhy(String branch) {
    return 'Chooses the remote branch $branch pushes to and pulls from.';
  }

  @override
  String get bdBranchesUpstreamLabel => 'Remote branch';

  @override
  String bdDoneSetUpstream(String branch, String upstream) {
    return '$branch now tracks $upstream';
  }

  @override
  String get bdBranchesCleanup => 'Clean up merged branches';

  @override
  String bdCleanupWhy(String base) {
    return 'Local branches already merged into $base, or deleted on the remote. Remote branches aren\'t touched.';
  }

  @override
  String get bdCleanupMerged => 'Merged';

  @override
  String get bdCleanupGoneNotMerged =>
      'Gone on remote · not merged — its commits get hard to find';

  @override
  String bdCleanupConfirm(int count) {
    return 'Delete $count';
  }

  @override
  String bdCleanupNothing(String base) {
    return 'Nothing to clean up (no branches merged into $base)';
  }

  @override
  String bdDoneCleanup(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count branches',
      one: '1 branch',
    );
    return 'Cleaned up $_temp0';
  }

  @override
  String get bdTagsCommitsSince => 'Commits since previous tag';

  @override
  String bdTagsCommitsBetween(String from, String to) {
    return '$from → $to';
  }

  @override
  String bdTagsCommitsUpTo(String tag) {
    return 'Up to $tag';
  }

  @override
  String bdTagsCommitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get bdTagsCheckout => 'Check out this tag';

  @override
  String bdTagsCheckoutTitle(String tag) {
    return 'Check out $tag?';
  }

  @override
  String get bdTagsCheckoutMessage =>
      'You\'ll see the files exactly as they were at the tag. You won\'t be on any branch (\'detached HEAD\'), so create a branch before committing here.';

  @override
  String bdDoneCheckoutTag(String tag) {
    return 'Checked out $tag';
  }

  @override
  String get bdBannerDetached =>
      'You\'re not on a branch. Create one before committing here';

  @override
  String get bdHistoryTitle => 'History';

  @override
  String bdHistoryUnpushed(int count) {
    return '↑ $count not pushed';
  }

  @override
  String get bdHistoryNotPushed => 'not pushed';

  @override
  String get bdHistoryCopyHash => 'Copy hash';

  @override
  String get bdHistoryBranchHere => 'Create branch here';

  @override
  String get bdHistoryTagHere => 'Tag this commit';

  @override
  String get bdHelpLinkStashing => 'Pro Git — Stashing and Cleaning';

  @override
  String get bdHelpCaptionStash =>
      'Uncommitted changes W put aside at the top of the stash list — main is unchanged';

  @override
  String get bdHelpStashTitle => 'Stash';

  @override
  String get bdHelpStashWord =>
      'To stash is to put something away for later, like into a drawer.';

  @override
  String get bdHelpStashInGit =>
      'Saves your uncommitted changes outside the branch history and resets the working tree to clean. Stashes pile up in a list (newest on top) and can be applied later on any branch.';

  @override
  String get bdHelpStashWhy =>
      'Use it when it\'s too early to commit but you need to switch branches or pull. \'pop\' applies and removes it; \'apply\' keeps it in the list. Add a note — old stashes are easy to forget.';

  @override
  String get bdHelpCaptionDetached =>
      'HEAD points straight at the v1.0.0 commit, not at a branch';

  @override
  String get bdHelpDetachedTitle => 'Detached HEAD';

  @override
  String get bdHelpDetachedWord =>
      'Detached means separated. HEAD means \'where you are now\'.';

  @override
  String get bdHelpDetachedInGit =>
      'Normally HEAD points at a branch label, and committing moves that label forward. Checking out a tag or commit makes HEAD point straight at the commit, detached from any branch.';

  @override
  String get bdHelpDetachedWhy =>
      'Safe for trying out or comparing an old version. Commits made here belong to no branch and are hard to find once you move away — create a branch first if you want to commit.';

  @override
  String get bdHelpForceTitle => 'Force push (force-with-lease)';

  @override
  String get bdHelpForceWord =>
      'Force means by force; a lease is an agreement — here, \'only if it\'s still how I last saw it\'.';

  @override
  String get bdHelpForceInGit =>
      'After amending or rebasing commits you already pushed, your history has split from the remote and a normal push is rejected. A force push replaces the remote branch with yours. --force-with-lease only does so if the remote is exactly as you last fetched it, and refuses if someone pushed in between.';

  @override
  String get bdHelpForceWhy =>
      'Only on a work branch you use alone, after tidying its history. Never on shared branches, especially main. This app doesn\'t offer plain --force, and blocks force push on the default branch.';

  @override
  String get bdMenuBrowse => 'Open repository in browser';

  @override
  String get bdMenuSnapRight => 'Snap to right edge';

  @override
  String get bdMenuSnapLeft => 'Snap to left edge';

  @override
  String get bdStartInitRepository => 'Make this folder a git repository';

  @override
  String get bdCloneTitle => 'Clone from GitHub';

  @override
  String get bdCloneSearch => 'Find one of your repositories';

  @override
  String get bdCloneEmpty => 'No repositories';

  @override
  String get bdCloneNoFolder => 'Choose where to clone';

  @override
  String get bdCloneChooseFolder => 'Choose folder';

  @override
  String bdCloneExists(String path) {
    return 'That folder already exists: $path';
  }

  @override
  String get bdCloneConfirm => 'Clone and open';

  @override
  String get bdCloneRunning => 'Cloning…';

  @override
  String get bdLoginTitle => 'Log in to GitHub';

  @override
  String get bdLoginSsh => 'SSH';

  @override
  String get bdLoginHttps => 'HTTPS';

  @override
  String get bdLoginSshRecommended => 'SSH recommended';

  @override
  String get bdLoginSshWhy =>
      'With an SSH remote or an SSH session, logging in over HTTPS can leave git push authenticating separately.';

  @override
  String get bdLoginStepKey => 'Check for an SSH key';

  @override
  String get bdLoginStepKeyFound => 'This key will be added to GitHub';

  @override
  String get bdLoginStepKeyMissing =>
      'No key found. Create one in a terminal with the command below (a passphrase is recommended). The app never handles keys or passphrases.';

  @override
  String get bdLoginStepLogin => 'Log in';

  @override
  String get bdLoginStepLoginWhy =>
      'Log in to GitHub in the browser and enter a one-time code.';

  @override
  String get bdLoginLoggedIn => 'You\'re logged in';

  @override
  String get bdLoginStart => 'Log in with browser';

  @override
  String get bdLoginDeviceHowTo =>
      'If no browser opens, or you\'re on a remote server, open this address on any device and enter the code.';

  @override
  String get bdLoginStepUpload => 'Add the public key';

  @override
  String get bdLoginStepUploadWhy =>
      'Registers the chosen public key with your GitHub account. Skipped if it\'s already there.';

  @override
  String get bdLoginUploadKey => 'Add key';

  @override
  String get bdLoginNeedsKeyScope =>
      'Missing permission to add keys. Add it with the command below in a terminal, then try again.';

  @override
  String get bdLoginStepTest => 'Test the connection';

  @override
  String get bdLoginStepTestWhy =>
      'Connects to GitHub over SSH. The first time, github.com\'s host key is added to known_hosts.';

  @override
  String get bdLoginSshFailed =>
      'Couldn\'t connect. Check that the key is added to GitHub and loaded in ssh-agent.';

  @override
  String get bdLoginTest => 'Test';

  @override
  String get bdLoginChecking => 'Checking…';

  @override
  String get bdLoginStepProtocol => 'Use SSH for git';

  @override
  String get bdLoginStepProtocolWhy =>
      'gh will use SSH addresses from now on. Switch existing HTTPS remotes in Remotes → Change URL.';

  @override
  String get bdLoginUseSshProtocol => 'Use SSH';

  @override
  String get bdLoginAgentTip =>
      'To avoid typing the passphrase every time, use ssh-add --apple-use-keychain on macOS, or ssh-agent elsewhere.';

  @override
  String get bdDoneProtocolSsh => 'gh now uses SSH for git';

  @override
  String bdForkTitle(String parent) {
    return 'Fork of $parent';
  }

  @override
  String get bdForkAddWhy =>
      'Add the original repository as the upstream remote to bring in its new commits.';

  @override
  String get bdForkSyncWhy =>
      'Fetches new commits from the original (upstream) and merges them into your current branch.';

  @override
  String get bdForkAddUpstream => 'Add upstream';

  @override
  String get bdForkSync => 'Sync from upstream';

  @override
  String get bdRemotesGhDefault => 'Repository gh uses (PRs, releases, CI)';

  @override
  String get bdRemotesGhDefaultNone => 'Not set';

  @override
  String bdDoneGhDefault(String repo) {
    return 'gh now uses $repo';
  }

  @override
  String get bdReleaseNeedsRemote =>
      'No remote to release to. Publish it from Remotes first.';

  @override
  String bdReleaseNeedsFiles(String files) {
    return 'Can\'t release: files the release workflow uses are missing: $files. CI could not build the packages after tagging.';
  }

  @override
  String get bdReleaseDirectOnlyNotGitHub =>
      'Not a GitHub repository, so this uses direct commit (check → version → tag). Do PRs, release notes and CI on your host\'s website.';

  @override
  String get bdReleaseDirectOnly =>
      'Without gh, only direct commit is available.';

  @override
  String get bdReleaseDirectMode => 'Direct commit';

  @override
  String bdReleaseDirectModeWhy(String branch) {
    return 'Commits the version bump straight to $branch and pushes it with the tag, no PR. Only for repositories you work on alone — protected branches reject the push.';
  }

  @override
  String bdTagCheckSyncedDirect(String branch) {
    return 'On $branch with no remote commits you\'re missing';
  }

  @override
  String get bdVersionUsesScript =>
      'Uses the repository\'s scripts/bump-version.sh (lock files included, same result as the conventions).';

  @override
  String bdVersionLockFiles(String files) {
    return 'Lock files updated too: $files';
  }

  @override
  String get bdVersionFileChoose => 'Change version file';

  @override
  String bdVersionFileCustom(String path) {
    return 'Version file: $path (custom)';
  }

  @override
  String get bdVersionFileTitle => 'Version file';

  @override
  String get bdVersionFileWhy =>
      'For when the version file isn\'t found or is the wrong one. The first group in the pattern is the version. Applies to this repository only.';

  @override
  String get bdVersionFilePath => 'File (path in the repository)';

  @override
  String get bdVersionFilePattern => 'Version line pattern';

  @override
  String bdVersionFileFound(String version) {
    return 'Found: $version';
  }

  @override
  String get bdVersionFileNotFound =>
      'File missing, or no version matches the pattern';

  @override
  String get bdVersionFileAuto => 'Back to auto-detect';

  @override
  String get bdRollbackTitle => 'Roll back release';

  @override
  String bdRollbackConfirmTitle(String tag) {
    return 'Roll back $tag?';
  }

  @override
  String bdRollbackMessage(String next) {
    return 'Deletes the GitHub release, the remote tag and the local tag. People may already have it, so don\'t reuse the number — release the next one ($next) instead.';
  }

  @override
  String bdDoneRollback(String tag) {
    return 'Rolled back $tag';
  }

  @override
  String get bdDiffBinary => 'Binary file — no text diff';

  @override
  String get bdDiffEmpty => 'No differences';

  @override
  String bdDiffTruncated(int count) {
    return 'Showing the first $count lines only. Open it in your editor for the rest.';
  }

  @override
  String bdHeaderCherryPicking(int count) {
    return 'Cherry-picking · $count conflicts';
  }

  @override
  String bdHeaderReverting(int count) {
    return 'Reverting · $count conflicts';
  }

  @override
  String get bdOperationAbortPickMessage =>
      'Goes back to before it started. Any conflict resolutions you\'ve made are lost.';

  @override
  String get bdHistoryBranchLabel => 'Branch';

  @override
  String bdHistoryOtherBranchHint(String head) {
    return 'Another branch\'s history. Use \'Bring into\' in a commit\'s menu to copy it onto $head.';
  }

  @override
  String get bdHistoryViewChanges => 'View changes';

  @override
  String bdHistoryFilesChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files changed',
      one: '1 file changed',
    );
    return '$_temp0';
  }

  @override
  String get bdHistoryMergeNote => 'merge commit — changes it brought in';

  @override
  String get bdHistoryRevert => 'Revert this commit';

  @override
  String bdHistoryRevertTitle(String hash) {
    return 'Revert $hash?';
  }

  @override
  String get bdHistoryRevertMessage =>
      'Makes a new commit that undoes this one. History isn\'t rewritten, so it\'s safe even for commits you\'ve pushed.';

  @override
  String get bdHistoryRevertUnpushed =>
      'Makes a new commit that undoes this one. Since it isn\'t pushed yet, you could also amend or fix it in a new commit.';

  @override
  String get bdHistoryCherryPick => 'Bring in';

  @override
  String bdHistoryCherryPickMenu(String head) {
    return 'Bring into $head (cherry-pick)';
  }

  @override
  String bdHistoryCherryPickTitle(String hash, String head) {
    return 'Bring $hash into $head?';
  }

  @override
  String get bdHistoryCherryPickMessage =>
      'Copies the same change onto your current branch as a new commit — for taking just one commit without merging the whole branch.';

  @override
  String bdDoneRevert(String hash) {
    return 'Reverted $hash';
  }

  @override
  String bdDoneCherryPick(String hash) {
    return 'Brought in $hash';
  }

  @override
  String get bdMenuPalette => 'Command palette';

  @override
  String get bdPaletteHint =>
      'What do you want to do? (e.g. push, branch, tag)';

  @override
  String get bdPaletteEmpty => 'No matching commands';

  @override
  String get bdPaletteGroupActions => 'Action';

  @override
  String get bdPaletteGroupTabs => 'Tab';

  @override
  String get bdPaletteGroupBranches => 'Branch';

  @override
  String get bdPaletteGroupRepos => 'Repository';

  @override
  String bdPaletteGoToTab(String name) {
    return 'Go to $name';
  }

  @override
  String bdPaletteSwitchTo(String branch) {
    return 'Switch to $branch';
  }

  @override
  String get bdHelpCaptionAfterRevert => 'C stays; a new commit C⁻ undoes it';

  @override
  String get bdHelpCaptionAfterCherryPick =>
      'The change from feature\'s D is copied onto main as a new commit D\'';

  @override
  String get bdHelpRevertTitle => 'Revert';

  @override
  String get bdHelpRevertWord =>
      'To revert is to go back to how something was.';

  @override
  String get bdHelpRevertInGit =>
      'Doesn\'t delete the commit — it adds a new commit that applies the opposite change. Both the original and the revert stay in history.';

  @override
  String get bdHelpRevertWhy =>
      'Use it when a commit you\'ve already pushed causes trouble. History isn\'t rewritten, so nobody else is affected and no force push is needed. For commits not yet pushed, amending is cleaner.';

  @override
  String get bdHelpCaptionBeforeReset => 'Before: main points at D';

  @override
  String get bdHelpCaptionAfterReset =>
      'After: main moved to B. C and D look gone but are still in the reflog';

  @override
  String get bdHelpCaptionReflog =>
      'The places HEAD has been are listed in order, so you can go back to D';

  @override
  String get bdHelpResetTitle => 'Reset';

  @override
  String get bdHelpResetWord =>
      'To reset is to put something back where it was.';

  @override
  String get bdHelpResetInGit =>
      'Moves the branch back to an earlier commit. The commits look deleted but stay in the reflog for a while. --soft keeps the changes staged, --keep protects your uncommitted work, and --hard throws that work away too.';

  @override
  String get bdHelpResetWhy =>
      'Use it to undo commits you haven\'t pushed yet. Don\'t use it on pushed commits: it disagrees with everyone else\'s history, so use revert. This app only uses the safe --soft and --keep.';

  @override
  String get bdHelpReflogTitle => 'Reflog';

  @override
  String get bdHelpReflogWord =>
      'Reflog is short for \'reference log\': a record of where a name pointed.';

  @override
  String get bdHelpReflogInGit =>
      'A record, kept only on this computer, of where HEAD and your branches pointed. Even after you undo a commit or delete a branch, you can usually find that point again for about 90 days.';

  @override
  String get bdHelpReflogWhy =>
      'When you think \'I made a mistake\', look at the reflog first. It exists only on this computer, not on the remote or another machine, and git cleans up old entries.';

  @override
  String get bdHistoryGraph => 'Graph';

  @override
  String get bdHistoryAllBranches => 'All branches';

  @override
  String get bdHelpCaptionGraphMerged =>
      'main and feature split apart and meet again at M (the hollow dot is a merge commit)';

  @override
  String get bdHelpCommitGraphTitle => 'Reading the commit graph';

  @override
  String get bdHelpCommitGraphWord =>
      'A graph is a picture made of dots and lines.';

  @override
  String get bdHelpCommitGraphInGit =>
      'Dots are commits and lines connect each commit to its parent. Newest is at the top. A line that splits is where a branch began; two lines that join are a merge. A hollow dot is a merge commit, and a dot with a ring is where you are now (HEAD).';

  @override
  String get bdHelpCommitGraphWhy =>
      'See at a glance where your branch left main and where merges happened. In a narrow window only six lines are drawn; any more overlap on the right-most one.';

  @override
  String get bdRecoveryTitle => 'Undo a mistake';

  @override
  String get bdRecoveryIntro => 'Most mistakes can be undone. Pick what fits.';

  @override
  String get bdRecoveryUndoCommit => 'Undo the last commit';

  @override
  String bdRecoveryUndoCommitWhy(String subject) {
    return 'Undoes only \"$subject\". Its changes stay staged.';
  }

  @override
  String bdRecoveryUndoCommitMessage(String subject) {
    return 'Undoes the commit \"$subject\". Its changes aren\'t deleted — they stay staged so you can fix them and commit again.';
  }

  @override
  String get bdRecoveryUndoCommitPushed =>
      'This commit is already on the remote. Undoing it here leaves it there, so pushing again needs a force push and your history no longer matches everyone else\'s. For a pushed commit, Revert in the History tab is safer.';

  @override
  String get bdRecoveryUndoCommitConfirm => 'Undo commit';

  @override
  String get bdRecoveryNoParent => 'The first commit can\'t be undone.';

  @override
  String get bdRecoveryStash => 'Set my changes aside for now';

  @override
  String get bdRecoveryStashWhy =>
      'Keeps them in a stash so you can bring them back later.';

  @override
  String get bdRecoveryHistory => 'Go back to an earlier state';

  @override
  String get bdRecoveryHistoryHint =>
      'Where HEAD has been. Even after undoing commits or deleting a branch, it usually stays for 90 days.';

  @override
  String get bdRecoveryNow => 'Now';

  @override
  String get bdRecoveryEmpty => 'Nothing recorded yet.';

  @override
  String get bdRecoveryKindCommit => 'Commit';

  @override
  String get bdRecoveryKindAmend => 'Amend';

  @override
  String get bdRecoveryKindCheckout => 'Switch';

  @override
  String get bdRecoveryKindReset => 'Reset';

  @override
  String get bdRecoveryKindMerge => 'Merge';

  @override
  String get bdRecoveryKindPull => 'Pull';

  @override
  String get bdRecoveryKindRebase => 'Rebase';

  @override
  String get bdRecoveryKindCherryPick => 'Cherry-pick';

  @override
  String get bdRecoveryKindRevert => 'Revert';

  @override
  String get bdRecoveryKindOther => 'Other';

  @override
  String get bdRecoveryGoBack => 'Go back here';

  @override
  String bdRecoveryGoBackMessage(String branch, String target) {
    return 'Moves $branch back to $target. The commits after it leave the branch but stay in the reflog. Your uncommitted work is kept, and if a file overlaps, nothing changes and git stops.';
  }

  @override
  String get bdRecoveryGoBackConfirm => 'Go back';

  @override
  String get bdRecoveryRescue => 'Create a branch here';

  @override
  String get bdDoneUndoCommit =>
      'Undid the last commit (its changes stay staged)';

  @override
  String bdDoneGoBack(String target) {
    return 'Went back to $target';
  }

  @override
  String bdDoneRescue(String name) {
    return 'Created branch $name';
  }

  @override
  String get bdHelpCherryPickTitle => 'Cherry-pick';

  @override
  String get bdHelpCherryPickWord =>
      'To cherry-pick is to pick only the best cherries — take just what you want.';

  @override
  String get bdHelpCherryPickInGit =>
      'Copies the change from one commit on another branch onto your current branch as a new commit. Same change, but a new commit (D\') with a different hash.';

  @override
  String get bdHelpCherryPickWhy =>
      'Handy for pulling one urgent fix from another branch. If you merge that branch later the same change arrives twice and can conflict — merging is still the default.';

  @override
  String bdConfirmTypeToContinue(String text) {
    return 'This can\'t be undone. Type $text to continue.';
  }

  @override
  String bdTagsDeleteRemoteReleaseDraft(String tag) {
    return '⚠️ $tag has a GitHub release. Deleting the tag makes GitHub turn that release into a draft (hidden) — the files stay but nobody can see them. To clean up the release too, use \'Roll back release\' in the tag menu.';
  }

  @override
  String bdTagsPushCiTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'these $count tags',
      one: 'this tag',
    );
    return 'Pushing $_temp0 creates releases';
  }

  @override
  String bdTagsPushCiMessage(String workflow, String tags) {
    return 'In this repository, pushing a tag makes $workflow build it and create a GitHub release: $tags. Old releases you deleted on purpose would come back. To remove them locally instead, use \'Delete\' in the tag menu.';
  }

  @override
  String get bdTagsPushAnyway => 'Push anyway';

  @override
  String bdTagsPushMismatchTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'These $count tags\' versions differ',
      one: 'This tag\'s version differs',
    );
    return '$_temp0 from the version file';
  }

  @override
  String bdTagsPushMismatchMessage(String file, String tags) {
    return 'The $file on the commit the tag points to has a different version (tag → file version): $tags. The tag may be on a commit from before the version bump. Pushing it makes the tag-triggered release CI stop at its version check. Bump the version first with the release wizard.';
  }

  @override
  String bdCiVersionMismatchMessage(String tag) {
    return 'CI stopped because tag $tag does not match the version file. The tag is on a commit before the version bump. Re-running gives the same result: make sure the version bump is on the default branch, then delete the tag and tag again.';
  }

  @override
  String get bdCiRetag => 'Delete the tag and tag again';

  @override
  String get bdCommonDelete => 'Delete';

  @override
  String get bdPrReviewTitle => 'Reviews and comments';

  @override
  String bdPrReviewShowAll(int count) {
    return 'Show all ($count)';
  }

  @override
  String get bdPrReviewShowLess => 'Show less';

  @override
  String get bdPrReviewApprove => 'Approve';

  @override
  String get bdPrReviewRequestChanges => 'Request changes';

  @override
  String get bdPrReviewComment => 'Comment';

  @override
  String get bdPrReviewOwnPr =>
      'You can\'t approve or request changes on your own PR, but you can comment.';

  @override
  String get bdPrReviewSend => 'Send';

  @override
  String get bdPrReviewBody => 'Message (Markdown)';

  @override
  String get bdPrReviewBodyOptional => 'Message (optional, Markdown)';

  @override
  String bdDonePrReview(int number) {
    return 'Review posted on #$number';
  }

  @override
  String bdAssetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count assets',
      one: '1 asset',
    );
    return '$_temp0';
  }

  @override
  String get bdAssetEmpty =>
      'No assets. Build outputs uploaded by CI appear here.';

  @override
  String bdAssetMeta(String size, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count downloads',
      one: '1 download',
    );
    return '$size · $_temp0';
  }

  @override
  String get bdAssetUpload => 'Upload files';

  @override
  String get bdAssetDownload => 'Download';

  @override
  String get bdAssetReplace => 'Replace';

  @override
  String get bdAssetReplaceTitle => 'Replace files with the same name?';

  @override
  String bdAssetReplaceMessage(String names) {
    return '$names — anyone who already downloaded them will have a different file. Prefer releasing a new version.';
  }

  @override
  String bdAssetDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get bdAssetDeleteMessage =>
      'Removes this file from the release page. This can\'t be undone, and download links to it will break.';

  @override
  String bdDoneAssetDownloaded(String name) {
    return 'Downloaded $name';
  }

  @override
  String bdDoneAssetUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Uploaded $count files',
      one: 'Uploaded 1 file',
    );
    return '$_temp0';
  }

  @override
  String bdDoneAssetDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String bdSyncUpstreamCounts(String upstream, int ahead, int behind) {
    return '$upstream  ↑$ahead ↓$behind';
  }

  @override
  String bdSyncNoUpstream(String branch) {
    return '$branch has no remote branch to track';
  }

  @override
  String bdSyncOnOtherBranch(String branch) {
    return 'You\'re on $branch';
  }

  @override
  String bdSyncBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits on the remote aren\'t pulled yet',
      one: '1 commit on the remote isn\'t pulled yet',
    );
    return '$_temp0. Pull first.';
  }

  @override
  String bdSyncAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits aren\'t pushed yet',
      one: '1 commit isn\'t pushed yet',
    );
    return '$_temp0.';
  }

  @override
  String bdSyncAheadPr(int count, String branch) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits aren\'t pushed yet',
      one: '1 commit isn\'t pushed yet',
    );
    return '$_temp0. Pushing here puts them on $branch without a PR.';
  }

  @override
  String bdSyncDiverged(int behind, int ahead) {
    return 'Diverged from the remote: $behind to pull, $ahead to push.';
  }

  @override
  String bdSyncSameContent(int count) {
    return 'Files match the remote, but the commits don\'t ($count local). This happens when a PR is merged with squash or rebase and the old commits stay on your branch.';
  }

  @override
  String get bdSyncMatchRemote => 'Match remote';

  @override
  String bdSyncMatchRemoteTitle(String branch) {
    return 'Match $branch to the remote?';
  }

  @override
  String bdSyncMatchRemoteMessage(int count, String branch, String upstream) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count local commits',
      one: '1 local commit',
    );
    return 'Drops $_temp0 and moves $branch to $upstream. Files stay the same and uncommitted changes are kept. The dropped commits can be recovered with git reflog.';
  }

  @override
  String bdDoneMatchRemote(String branch) {
    return 'Matched $branch to the remote';
  }

  @override
  String bdSyncPushNoPrTitle(String branch) {
    return 'Push to $branch without a PR?';
  }

  @override
  String bdSyncPushNoPrMessage(int count, String branch) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unpushed commits go',
      one: '1 unpushed commit goes',
    );
    return '$_temp0 straight to $branch without a PR. A protected branch will reject it. Moving the work to a branch and opening a PR is safer.';
  }

  @override
  String get bdWorktreesTitle => 'Worktrees';

  @override
  String get bdWorktreePill => 'worktree';

  @override
  String bdWorktreeHeldTooltip(String path) {
    return 'Checked out in $path';
  }

  @override
  String get bdWorktreeDetachedHead => 'Detached HEAD';

  @override
  String get bdWorktreeMainPill => 'Main';

  @override
  String get bdWorktreeOpenPill => 'Open here';

  @override
  String bdWorktreeChangesPill(int count) {
    return '$count changed';
  }

  @override
  String get bdWorktreeMissingPill => 'Missing';

  @override
  String get bdWorktreeLockedPill => 'Locked';

  @override
  String get bdWorktreeOpen => 'Open';

  @override
  String get bdWorktreeDetach => 'Release branch';

  @override
  String get bdWorktreeRemove => 'Remove';

  @override
  String get bdWorktreeClaudeWarning =>
      'A Claude Code session may be using this folder. Make sure the session has finished first.';

  @override
  String bdWorktreeHeldTitle(String branch) {
    return '$branch is checked out in another worktree';
  }

  @override
  String bdWorktreeHeldMessage(String path) {
    return 'Git lets only one worktree check out a branch at a time. $path is using this branch, so you can\'t switch to it here. Open that folder, or release the branch there (detached HEAD) and switch here.';
  }

  @override
  String get bdWorktreeDetachAndSwitch => 'Release and switch here';

  @override
  String bdWorktreeDetachTitle(String name) {
    return 'Release the branch in $name?';
  }

  @override
  String bdWorktreeDetachMessage(String path, String branch) {
    return '$path moves from $branch to a detached HEAD. Files and commits stay as they are, and $branch can then be checked out or deleted elsewhere.';
  }

  @override
  String bdWorktreeRemoveTitle(String name) {
    return 'Remove the $name worktree?';
  }

  @override
  String bdWorktreeRemoveMessage(String path) {
    return 'Deletes the folder $path. Branches and commits stay in the repository.';
  }

  @override
  String get bdWorktreeRemoveForceTitle => 'Delete uncommitted changes too?';

  @override
  String bdWorktreeRemoveForceMessage(String path, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uncommitted changes',
      one: '1 uncommitted change',
    );
    return '$path has $_temp0. They can\'t be recovered once removed.';
  }

  @override
  String bdWorktreeLockedMessage(String path) {
    return '$path is locked and can\'t be removed. Unlock it first with git worktree unlock.';
  }

  @override
  String get bdWorktreeDeleteBranchTitle =>
      'Remove the worktree and delete the branch?';

  @override
  String bdWorktreeDeleteBranchMessage(String branch, String path) {
    return '$branch is checked out in $path, so it can\'t be deleted as is. The worktree folder is removed first, then the branch.';
  }

  @override
  String bdWorktreeDeleteBranchDirty(String branch, String path, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uncommitted changes',
      one: '1 uncommitted change',
    );
    return '$branch is checked out in $path, which has $_temp0. Open that folder, tidy it up, then delete again.';
  }

  @override
  String get bdWorktreePrune => 'Clean up missing folders';

  @override
  String bdDoneWorktreeRemoved(String name) {
    return 'Removed the $name worktree';
  }

  @override
  String bdDoneWorktreeDetached(String name) {
    return 'Released the branch in $name';
  }

  @override
  String get bdDoneWorktreePruned => 'Cleaned up worktree records';

  @override
  String bdCleanupWorktree(String name) {
    return 'Also removes the $name worktree';
  }

  @override
  String bdCleanupWorktreeBlocked(String name) {
    return 'Can\'t remove: the $name worktree has uncommitted changes or is locked';
  }

  @override
  String get bdEnvCustomPath => 'Custom';

  @override
  String get bdEnvSetPath => 'Set path';

  @override
  String bdEnvGitTooOld(String min) {
    return 'git $min or later is needed. Some commands may fail or be read wrongly.';
  }

  @override
  String bdEnvGhTooOld(String min) {
    return 'gh $min or later is needed. Older versions can\'t report login (gh auth status --json), so you show as logged out even when you aren\'t.';
  }

  @override
  String get bdEnvCopyDiagnostics => 'Copy diagnostics';

  @override
  String get bdEnvDiagnosticsCopied =>
      'Diagnostics copied. Paste them into your report.';

  @override
  String get bdEnvSearchPath => 'PATH used by the app';

  @override
  String bdToolPathTitle(String tool) {
    return '$tool path';
  }

  @override
  String bdToolPathWhy(String tool) {
    return 'Choose an executable to use instead of the $tool found on PATH. Leave it empty to search PATH.';
  }

  @override
  String get bdToolPathLabel => 'Executable';

  @override
  String get bdToolPathBrowse => 'Choose file';

  @override
  String get bdToolPathVerify => 'Check';

  @override
  String get bdToolPathUsePath => 'Search PATH';

  @override
  String bdToolPathOk(String tool, String version) {
    return '$tool $version found';
  }

  @override
  String bdToolPathBad(String tool) {
    return 'Can\'t run it, or it isn\'t $tool';
  }

  @override
  String get bdToolPathNeedsCheck => 'Press Check before saving';

  @override
  String bdDoneToolPath(String tool) {
    return 'Saved the $tool path';
  }

  @override
  String bdDoneToolPathReset(String tool) {
    return 'Searching PATH for $tool';
  }

  @override
  String get fdSecretsTooltip => 'Release secrets';

  @override
  String get fdSecretsTitle => 'Register release secrets';

  @override
  String get fdSecretsIntro =>
      'Registers the GitHub Actions secrets that the macOS release workflow uses for signing and notarization, through gh. Values are not stored in this app.';

  @override
  String get fdSecretsRepoLabel => 'Repository (owner/repo)';

  @override
  String get fdSecretsPickFolder => 'Read from a project folder';

  @override
  String get fdSecretsRefresh => 'Refresh registration status';

  @override
  String get fdSecretsRepoInvalid => 'Use the owner/repo form';

  @override
  String get fdSecretsFolderNoRemote =>
      'No GitHub remote (origin) found in that folder';

  @override
  String get fdSecretsGhMissing =>
      'GitHub CLI (gh) isn\'t installed. Install it in a terminal with:';

  @override
  String get fdSecretsGhNotLoggedIn =>
      'gh isn\'t signed in. Run this in a terminal:';

  @override
  String get fdSecretsListFailed =>
      'Couldn\'t read the registration status. Check the repository name and your access';

  @override
  String fdSecretStatusRegistered(String date) {
    return 'Registered · $date';
  }

  @override
  String get fdSecretStatusMissing => 'Not registered';

  @override
  String get fdSecretStatusUnknown => 'Unknown';

  @override
  String get fdSecretSet => 'Register';

  @override
  String get fdSecretOverwrite => 'Overwrite';

  @override
  String get fdSecretPickFile => 'Choose file…';

  @override
  String get fdSecretNoFile => 'No file chosen';

  @override
  String fdSecretFileLoaded(String name, int bytes) {
    return '$name · $bytes bytes';
  }

  @override
  String get fdSecretGenerate => 'Generate';

  @override
  String get fdSecretGenerated => 'A random value was generated (not shown)';

  @override
  String get fdSecretViaStdin =>
      'The value is passed on standard input, not as a command argument, so it never appears in the command log.';

  @override
  String get fdSecretIssueEmpty => 'Enter a value';

  @override
  String get fdSecretIssueEmail => 'Not an email address';

  @override
  String get fdSecretIssueTeamId =>
      'A Team ID is 10 uppercase letters or digits';

  @override
  String fdSecretSaved(String name) {
    return 'Registered $name';
  }

  @override
  String fdSecretFailed(String name) {
    return 'Couldn\'t register $name';
  }

  @override
  String fdSecretOverwriteTitle(String name) {
    return 'Overwrite $name?';
  }

  @override
  String get fdSecretOverwriteBody =>
      'This replaces the registered value with the new one. It can\'t be undone.';

  @override
  String get fdSecretHelpP12 =>
      'Choose the \'Developer ID Application\' certificate exported as .p12 from Keychain Access. The app registers it as base64.';

  @override
  String get fdSecretHelpP12Password =>
      'The password you set when exporting the .p12.';

  @override
  String get fdSecretHelpKeychain =>
      'A temporary keychain password CI uses only during the build. Any value works, so it can be generated for you.';

  @override
  String get fdSecretHelpAppleId => 'The Apple ID email used for notarization.';

  @override
  String get fdSecretHelpApplePassword =>
      'An app-specific password, not your account password.';

  @override
  String get fdSecretHelpTeamId =>
      'The 10-character Team ID from Membership details at developer.apple.com/account.';

  @override
  String get fdSecretOpenAppleId => 'Open appleid.apple.com';

  @override
  String get fdSecretOpenDeveloper => 'Open developer.apple.com/account';

  @override
  String get fdCommandBarEmpty => 'No commands run yet';

  @override
  String get fdHomeProjectTitle => 'Project';

  @override
  String get fdHomeProjectOpen => 'Open project';

  @override
  String get fdHomeProjectReload => 'Reload this project';

  @override
  String get fdHomeProjectDrop =>
      'Drop a Flutter project folder here, or press Open project';

  @override
  String fdHomeProjectNotFlutter(String path) {
    return 'Not a Flutter project: $path';
  }

  @override
  String get fdHomePlatformIos => 'iOS';

  @override
  String get fdHomePlatformAndroid => 'Android';

  @override
  String get fdHomeDevicesTitle => 'Devices';

  @override
  String get fdHomeDevicesRefresh => 'Refresh devices';

  @override
  String get fdHomeDevicesNone =>
      'No device is connected over USB. Plug in your phone, unlock it, then refresh';

  @override
  String get fdHomeLinkUsb => 'USB';

  @override
  String get fdHomeLinkWireless => 'Wireless';

  @override
  String get fdHomeBuildTitle => 'Build';

  @override
  String get fdHomeModeDebug => 'Debug';

  @override
  String get fdHomeModeRelease => 'Release';

  @override
  String get fdHomeTeamLabel => 'Apple Team ID';

  @override
  String get fdHomeTeamHelp =>
      'Passed only as a build argument — the project is not modified. Find it at developer.apple.com/account → Membership';

  @override
  String get fdHomeStepsTitle => 'Commands to run';

  @override
  String get fdHomeStepPrepare => 'Prepare';

  @override
  String get fdHomeStepBuild => 'Build';

  @override
  String get fdHomeStepInstall => 'Install';

  @override
  String get fdHomeStepLaunch => 'Launch';

  @override
  String get fdHomeStepRun => 'Run (hot reload)';

  @override
  String get fdHomeActionInstall => 'Build & install';

  @override
  String get fdHomeActionBuildRun => 'Build & run';

  @override
  String get fdHomeActionInstallOnly => 'Install only';

  @override
  String get fdHomeActionClean => 'Clean & get packages';

  @override
  String get fdHomeCleanHelp =>
      'flutter clean → flutter pub get. Worth trying when a build fails for no clear reason.';

  @override
  String get fdOptTitle => 'Build options';

  @override
  String get fdOptDefault => 'Defaults';

  @override
  String get fdOptFlavor => 'Flavor';

  @override
  String get fdOptFlavorHelp =>
      '--flavor. Only if the project defines flavors (Windows needs Flutter 3.47+)';

  @override
  String get fdOptFlavorInvalid =>
      'Start with a letter; letters, digits, _ and - only';

  @override
  String get fdOptHelp => 'Help';

  @override
  String get fdOptHelpLink =>
      'Opens the Flutter docs on setting up flavors for the selected target (Android, iOS, Windows …) in a browser';

  @override
  String get fdOptTarget => 'Entry point';

  @override
  String get fdOptTargetHelp => '-t. Empty means lib/main.dart';

  @override
  String get fdOptDefineFile => 'dart-define file';

  @override
  String get fdOptDefineFileHelp =>
      '--dart-define-from-file. Only the path is stored; the file is never read or saved';

  @override
  String get fdOptFileMissing => 'File not found';

  @override
  String get fdOptAppId => 'App ID (optional)';

  @override
  String get fdOptAppIdHelp =>
      'When the flavor changes the app ID, the ID to launch after installing (e.g. art.zoomon.app.dev)';

  @override
  String get fdOptExtra => 'Extra arguments';

  @override
  String get fdOptExtraHelp =>
      'e.g. --obfuscate --split-debug-info=build/symbols';

  @override
  String get fdOptPick => 'Choose file';

  @override
  String get fdOptClear => 'Clear options';

  @override
  String get fdHomeCleanDone =>
      'Cleaned and packages restored. Try building again.';

  @override
  String get fdHomeCleanFailed =>
      'Clean failed. Check the output in the Log tab.';

  @override
  String get fdHomeActionRun => 'Run debug';

  @override
  String get fdHomeActionCancel => 'Cancel';

  @override
  String get fdHomeActionStop => 'Stop';

  @override
  String get fdHomeHotReload => 'Hot reload';

  @override
  String get fdHomeHotRestart => 'Hot restart';

  @override
  String get fdHomeOutputTitle => 'Output';

  @override
  String get fdHomeCopyCommand => 'Copy command';

  @override
  String get fdBlockerNoProject => 'Open a Flutter project first';

  @override
  String get fdBlockerNoDevice => 'Connect and select a device';

  @override
  String get fdBlockerPlatformMissing =>
      'This project has no folder (ios/ or android/) for the selected device\'s platform';

  @override
  String get fdBlockerIosNeedsMac =>
      'Installing on an iPhone needs macOS and Xcode';

  @override
  String get fdBlockerWireless =>
      'This device is connected wirelessly. Use a USB cable — installs drop over wireless';

  @override
  String get fdBlockerDeveloperModeOff =>
      'Developer Mode is off on the iPhone. Turn it on in Settings → Privacy & Security → Developer Mode, then restart';

  @override
  String get fdBlockerAndroidUnauthorized =>
      'Approve this computer in the \'Allow USB debugging\' prompt on the phone';

  @override
  String get fdBlockerNeedsTeamId =>
      'Enter the Apple Team ID to sign iOS builds with';

  @override
  String get fdHintUseUsb =>
      'The connection dropped. Make sure the phone is on a USB cable, not wireless';

  @override
  String get fdHintUnlockDevice =>
      'The iPhone is locked. Unlock it and try again';

  @override
  String get fdHintDeveloperMode =>
      'Turn on Developer Mode on the iPhone: Settings → Privacy & Security → Developer Mode';

  @override
  String get fdHintSigning =>
      'A signing profile problem. Check the Team ID and that Xcode is signed in to your Apple account';

  @override
  String get fdHintTrustComputer => 'Tap \'Trust This Computer\' on the iPhone';

  @override
  String get fdHintNoAdb =>
      'adb wasn\'t found. Install the Android SDK platform-tools and add it to PATH';

  @override
  String fdHintMissingCommand(String command) {
    return 'The $command command wasn\'t found. Install it and make sure it is on PATH';
  }

  @override
  String get fdTabInstall => 'Run';

  @override
  String get fdTabDevices => 'Devices';

  @override
  String get fdTabSigning => 'Signing';

  @override
  String get fdTabDoctor => 'Doctor';

  @override
  String get fdTabLog => 'Log';

  @override
  String get fdBannerNextStep => 'Next step';

  @override
  String get fdBannerShowSteps => 'Show how to fix';

  @override
  String get fdDoctorRun => 'Check again';

  @override
  String get fdDoctorRunning => 'Checking…';

  @override
  String get fdDoctorNever => 'Not checked yet';

  @override
  String fdDoctorCollected(String time) {
    return 'Checked at $time';
  }

  @override
  String get fdDoctorAllGood => 'No problems found';

  @override
  String get fdSigningTeams => 'Signing team';

  @override
  String get fdSigningTeamsHelp =>
      'Teams of certificates whose private key is in your keychain. Tap one to sign with it';

  @override
  String get fdSigningNoTeams => 'No usable development certificate';

  @override
  String get fdSigningCerts => 'Development certificates';

  @override
  String get fdSigningProfiles => 'Profiles for this project';

  @override
  String get fdSigningNoProfiles =>
      'None yet — Xcode creates one on the first build';

  @override
  String get fdSigningShortLived => '7-day profile';

  @override
  String get fdSigningNoKey => 'No private key';

  @override
  String fdSigningDaysLeft(String days) {
    return '$days days left';
  }

  @override
  String get fdSigningExpired => 'Expired';

  @override
  String get fdSigningAndroid => 'Android release signing';

  @override
  String get fdSigningMacOnly => 'iOS signing checks run on macOS only';

  @override
  String get fdElevatedTitle => 'Running as administrator';

  @override
  String get fdElevatedBody =>
      'Builds with flutter (CMake) can fail when run as administrator. The app will close and reopen with normal permissions.';

  @override
  String get fdElevatedQuit => 'Close and reopen';

  @override
  String get fdLogClear => 'Clear log';

  @override
  String get fdOutputCopyAll => 'Copy all output';

  @override
  String get fdOutputCopied => 'Output copied';

  @override
  String get fdOutputViewer => 'Open in viewer';

  @override
  String get fdViewerPause => 'Pause updates (to select text)';

  @override
  String get fdViewerResume => 'Resume live updates';

  @override
  String fdViewerLines(Object count) {
    return '$count lines';
  }

  @override
  String get fdLogEmpty => 'No commands run yet';

  @override
  String get fdLogRunning => 'Running';

  @override
  String fdLogExit(String code) {
    return 'Exit code $code';
  }

  @override
  String fdCheckFlutterOk(String version) {
    return 'Flutter $version';
  }

  @override
  String fdCheckFlutterRunFail(String error) {
    return 'flutter ran but failed: $error';
  }

  @override
  String get fdCheckFlutterFail => 'flutter wasn\'t found';

  @override
  String fdCheckXcodeOk(String version) {
    return 'Xcode $version';
  }

  @override
  String get fdCheckXcodeFail => 'Xcode wasn\'t found';

  @override
  String fdCheckAdbOk(String version) {
    return 'adb $version';
  }

  @override
  String get fdCheckAdbWarn =>
      'adb wasn\'t found (needed to install on Android)';

  @override
  String fdCheckConnectionOk(String name) {
    return '$name: connected over USB';
  }

  @override
  String fdCheckConnectionFail(String name) {
    return '$name: connected wirelessly, not over USB';
  }

  @override
  String get fdCheckDeveloperModeOk => 'Developer Mode is on';

  @override
  String get fdCheckDeveloperModeFail => 'Developer Mode is off on the iPhone';

  @override
  String get fdCheckAndroidAuthOk => 'USB debugging approved';

  @override
  String get fdCheckAndroidAuthFail => 'USB debugging not approved';

  @override
  String fdCheckCertificateOk(String count) {
    return '$count development certificate(s) with a private key';
  }

  @override
  String get fdCheckCertificateFail =>
      'No usable Apple Development certificate';

  @override
  String fdCheckCertExpiryOk(String name, String days) {
    return '$name · $days days left';
  }

  @override
  String fdCheckCertExpiryWarn(String name, String days) {
    return '$name · expires in $days days';
  }

  @override
  String fdCheckCertExpiryFail(String name) {
    return '$name · expired';
  }

  @override
  String fdCheckTeamOk(String team) {
    return 'Signing team $team';
  }

  @override
  String get fdCheckTeamFail => 'No signing Team ID chosen';

  @override
  String fdCheckTeamWarn(String team) {
    return 'No certificate for team $team on this Mac';
  }

  @override
  String fdCheckProfileOk(String bundle, String days) {
    return '$bundle profile · $days days left';
  }

  @override
  String fdCheckProfileWarn(String bundle, String days) {
    return '$bundle profile expires soon ($days days left)';
  }

  @override
  String fdCheckProfileFail(String bundle) {
    return '$bundle profile expired';
  }

  @override
  String fdCheckProfileInfo(String bundle) {
    return 'No $bundle profile yet — it is created automatically on the first build';
  }

  @override
  String get fdCheckProfileShort =>
      'A 7-day profile from a free account. When it expires, build and install again';

  @override
  String get fdCheckAndroidSigningDebugKey =>
      'No keystore configured — signed with the debug key (fine for installing on your own device)';

  @override
  String get fdCheckAndroidSigningKeystore =>
      'Signed with the release keystore';

  @override
  String get fdCheckAndroidSigningMissing =>
      'The keystore file key.properties points to is missing';

  @override
  String get fdStepsWireless =>
      '1. Connect the iPhone to the Mac with a USB cable\n2. Unlock it and tap \'Trust This Computer\'\n3. Press Refresh devices and check the USB badge appears';

  @override
  String get fdStepsDeveloperMode =>
      '1. On the iPhone: Settings → Privacy & Security → Developer Mode\n2. Turn it on and restart\n3. After the restart, tap \'Turn On\' in the confirmation prompt';

  @override
  String get fdStepsAndroidAuth =>
      '1. Connect the phone over USB and unlock it\n2. Allow this computer in the \'Allow USB debugging\' prompt\n3. If no prompt appears, enable USB debugging in Developer options';

  @override
  String get fdStepsTeamId =>
      '1. Find the Team ID (10 characters) at developer.apple.com/account → Membership details\n2. Enter it in Apple Team ID under Build\n3. Or tap a team of your certificates in the Signing tab';

  @override
  String get fdStepsCertificate =>
      '1. Xcode → Settings → Accounts: sign in with your Apple ID\n2. Manage Certificates → + → add Apple Development\n3. Press Check again';

  @override
  String get fdStepsFlutterMissing =>
      '1. Install the Flutter SDK from flutter.dev\n2. Add flutter/bin to PATH (~/.zshrc)\n3. Reopen the app and press Check again';

  @override
  String get fdStepsFlutterMissingWindows =>
      '1. Install the Flutter SDK from flutter.dev\n2. Add the flutter\\bin folder to PATH, or pick flutter.bat with \"Set tool paths…\" above\n3. Press Check again';

  @override
  String get fdStepsXcodeMissing =>
      '1. Install Xcode from the App Store\n2. In a terminal run sudo xcode-select -s /Applications/Xcode.app\n3. Open Xcode once and accept the license';

  @override
  String get fdStepsAdbMissing =>
      '1. Install the Android SDK platform-tools (Android Studio SDK Manager)\n2. Add the platform-tools folder to PATH\n3. Press Check again';

  @override
  String get fdStepsAndroidKeystore =>
      '1. Check the storeFile path in android/key.properties\n2. If the file is gone, recreate the keystore or fix the path\n3. For personal installs you can drop key.properties — the debug key signs the build';

  @override
  String get fdStepsCertExpiry =>
      '1. Xcode → Settings → Accounts → Manage Certificates: create a new Apple Development certificate\n2. Press Check again';

  @override
  String get fdHomeOpenVsCode => 'Open in VS Code';

  @override
  String get fdVscodeNotFound => 'VS Code wasn\'t found';

  @override
  String get fdVscodeDownload => 'Get it';

  @override
  String get fdVscodeOpenFailed => 'Couldn\'t open VS Code';

  @override
  String get fdSecretFileTitle => 'Register from a file';

  @override
  String get fdSecretFileHelp =>
      'Registers every entry of a NAME=value (.env) file with gh secret set -f. The app doesn\'t keep the values — it only shows the names; gh reads the file itself.';

  @override
  String get fdSecretFileEmpty => 'No NAME=value entries found';

  @override
  String fdSecretFileUnknown(String names) {
    return 'Entries that aren\'t release secrets are registered too: $names';
  }

  @override
  String fdSecretFileMissing(String names) {
    return 'Release secrets not in the file: $names';
  }

  @override
  String get fdSecretFileRegister => 'Register file';

  @override
  String fdSecretFileConfirmTitle(int count) {
    return 'Register $count secrets?';
  }

  @override
  String fdSecretFileSaved(int count) {
    return 'Registered $count secrets';
  }

  @override
  String get fdSecretFileFailed => 'Couldn\'t register from the file';

  @override
  String get fdToolPathsOpen => 'Set tool paths…';

  @override
  String get fdToolPathsTitle => 'Tool paths';

  @override
  String get fdToolPathsHelp =>
      'Point the app at tools it can\'t find on PATH. The choice is saved and used the next time too. Pick the executable file, not the folder.';

  @override
  String get fdToolPathNotFound => 'Not found';

  @override
  String get fdToolPathChoose => 'Locate…';

  @override
  String get fdToolPathAuto => 'Automatic';

  @override
  String get fdToolPathCustom => 'Custom';

  @override
  String get fdToolPathFlutter => 'flutter';

  @override
  String get fdToolPathAdb => 'adb (Android SDK platform-tools)';

  @override
  String get fdHomeDevicesCauses => 'Possible reasons no device shows up';

  @override
  String get fdStepsNoDevice =>
      '1. Connect the phone with a USB cable (a charge-only cable won\'t work)\n2. Unlock it, then tap \'Trust This Computer\' on an iPhone or \'Allow USB debugging\' on Android\n3. Press refresh above';

  @override
  String get fdHomeThisMac => 'This Mac';

  @override
  String get fdHomeThisPc => 'This PC';

  @override
  String get fdHomeLinkLocal => 'This computer';

  @override
  String get fdHomePlatformMacos => 'macOS';

  @override
  String get fdHomePlatformWindows => 'Windows';

  @override
  String get fdHintCocoapods =>
      'CocoaPods is missing, so the macOS app couldn\'t be built';

  @override
  String get fdHintVisualStudio =>
      'Visual Studio\'s \'Desktop development with C++\' workload is missing, so the Windows app couldn\'t be built';

  @override
  String get fdHintRestartApp =>
      'The build failed because the build environment wasn\'t ready (plugin links not found). Closing and reopening the app fixes it';

  @override
  String get fdHintStaleBuildCache =>
      'The Windows build failed because a build cache from an older Visual Studio is left over (it happens after switching Visual Studio versions). Cleaning fixes it';

  @override
  String get fdStepsStaleBuildCache =>
      '1. Press \'Clean and re-fetch packages\' below (it deletes the build folder and fetches packages again)\n2. Build again';

  @override
  String get fdRestartAppButton => 'Close and reopen';

  @override
  String get fdHomeActionBuildOnly => 'Build only';

  @override
  String get fdHomeActionRunOnly => 'Run only';

  @override
  String get fdHomeRunOnlyNeedsBuild => 'No release build to run. Build first';

  @override
  String get fdGitTitle => 'Git';

  @override
  String get fdTabGit => 'Git';

  @override
  String get fdTitleMenuTooltip =>
      'Recent projects, open a folder, dock the window';

  @override
  String get fdMenuRecent => 'Recent projects';

  @override
  String get fdMenuRecentEmpty => 'No project opened yet';

  @override
  String get fdMenuOpenFolder => 'Open another folder…';

  @override
  String get fdMenuDockRight => 'Dock to the right edge';

  @override
  String get fdMenuDockLeft => 'Dock to the left edge';

  @override
  String get fdGitNotRepo => 'This project folder is not a git repository';

  @override
  String get fdGitChipUpToDate => '✓ Up to date';

  @override
  String fdGitChipBehind(int count) {
    return '↓ $count to pull';
  }

  @override
  String fdGitChipAhead(int count) {
    return '↑ $count ahead';
  }

  @override
  String get fdGitChipNoUpstream => 'No upstream';

  @override
  String get fdGitChipDirty => '● Changes';

  @override
  String get fdGitWorktree => 'Worktree';

  @override
  String get fdGitWorktreeHelp =>
      'Choosing another worktree opens the same project in that folder. No files are changed';

  @override
  String get fdGitDetached => 'Detached HEAD';

  @override
  String get fdGitUpToDate => 'Up to date with the remote';

  @override
  String fdGitAhead(int count) {
    return '$count ahead of the remote';
  }

  @override
  String fdGitBehind(int count) {
    return '$count behind the remote';
  }

  @override
  String get fdGitNoUpstream => 'No upstream branch';

  @override
  String get fdGitDirty => 'Uncommitted changes';

  @override
  String get fdGitNoRemote => 'No remote';

  @override
  String get fdGitOpenRemote => 'Open the remote repository in a browser';

  @override
  String get fdGitFetch => 'Fetch';

  @override
  String get fdGitPull => 'Pull';

  @override
  String get fdGitPullHelp =>
      'git pull --ff-only — fast-forwards only, never merges';

  @override
  String get fdGitPullBlockedDirty =>
      'Not pulling: there are uncommitted changes';

  @override
  String get fdGitPullBlockedDiverged =>
      'Local and remote have diverged. Merge in a terminal';

  @override
  String get fdGitPullBlockedNoUpstream => 'This branch has no upstream';

  @override
  String get fdGitPullBlockedUpToDate => 'Nothing to pull (fetch first)';

  @override
  String get fdGitFetchDone => 'Fetched';

  @override
  String get fdGitPullDone => 'Pulled';

  @override
  String get fdGitFailed =>
      'Failed. See the output in the Log tab. If credentials are needed, sign in once in a terminal';

  @override
  String get fdStepsCocoapods =>
      '1. Run brew install cocoapods in a terminal\n2. Build again';

  @override
  String get fdCheckWindowsDevModeOk =>
      'Windows Developer Mode is on (plugin links can be created)';

  @override
  String get fdCheckWindowsDevModeWarn =>
      'Windows Developer Mode is off (builds can fail because plugin links can\'t be created)';

  @override
  String fdCheckVisualStudioOk(String version) {
    return 'Visual Studio $version (C++ tools found)';
  }

  @override
  String get fdCheckVisualStudioFail =>
      'Visual Studio\'s \'Desktop development with C++\' is missing (needed to build the Windows app)';

  @override
  String get fdStepsWindowsDevMode =>
      '1. Open Windows Settings and search for \'For developers\'\n2. Turn on \'Developer Mode\'\n3. Press Check again';

  @override
  String get fdStepsVisualStudio =>
      '1. Install Visual Studio 2022 (Community is fine)\n2. In the installer pick \'Desktop development with C++\'\n3. Build again';

  @override
  String fdBranchChangedWhileRunning(String branch) {
    return 'The branch changed to $branch while a build is running. The build continues with the previous files.';
  }

  @override
  String get fdDoctorStale =>
      'The branch changed. These results are from the previous branch — run the check again.';

  @override
  String get fdOperationInProgress =>
      'A merge or rebase is in progress. Build results are unreliable while conflicts exist.';
}
