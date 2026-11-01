// 열린 편집기 탭과 그 파일들 (daylight-workbench 의 StudioController 에서 편집기 탭에 해당하는 부분을 줄여 옮겼다).
// 탭 열기·닫기·순서·저장·디스크 변경 감지만 한다. 프로젝트(저장소) 열기·worktree·git 비교·정렬은 여기 없다 —
// 저장소는 Workspace 가 쥔다.
//
// 알림 문구는 번역이 필요해서 컨트롤러는 [EditorMessage](종류 + 값)만 남기고, 화면이 번역해 보여 준다.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:re_editor/re_editor.dart';

import 'editor_tab.dart';

enum EditorMessageKind {
  fileTooLarge,
  notUtf8Open,
  readFailed,
  saveFailed,
  diskChangedSaveBlocked,
  changedNotUtf8,
  changedReloaded,
  reloadedFromDisk,
  notUtf8Reload,
}

/// 화면이 번역해서 보여 주는 알림 하나. [arg]는 파일 이름 또는 오류 문구.
class EditorMessage {
  const EditorMessage(this.kind, [this.arg = '']);

  final EditorMessageKind kind;
  final String arg;
}

/// 경로 비교용 키: 구분자를 `/`로 통일하고 Windows 에서는 대소문자를 무시한다.
String pathKey(String path) {
  final p = path.replaceAll('\\', '/');
  return Platform.isWindows ? p.toLowerCase() : p;
}

class EditorController extends ChangeNotifier {
  /// 이보다 큰 파일은 열지 않는다.
  static const maxFileBytes = 2 * 1024 * 1024;

  final List<EditorTab> tabs = [];
  int activeIndex = -1;

  /// 마지막으로 낸 알림(열 수 없는 파일, 저장 실패 등). 화면이 보여 주고 [clearMessage]로 지운다.
  EditorMessage? message;

  bool _disposed = false;

  EditorTab? get activeTab =>
      activeIndex >= 0 && activeIndex < tabs.length ? tabs[activeIndex] : null;

  /// [path]를 가진 탭. 경로 표기(구분자·대소문자)가 달라도 같은 파일이면 찾는다.
  EditorTab? tabFor(String path) {
    final key = pathKey(path);
    return tabs.where((t) => pathKey(t.path) == key).firstOrNull;
  }

  /// 파일을 탭으로 연다. 이미 열려 있으면 그 탭으로 옮긴다. 열지 못했으면 [message]를 남긴다.
  Future<void> openFile(String path) async {
    final existing = tabs.indexWhere((t) => pathKey(t.path) == pathKey(path));
    if (existing >= 0) {
      activeIndex = existing;
      notifyListeners();
      return;
    }
    final file = File(path);
    final name = file.uri.pathSegments.last;
    try {
      if (await file.length() > maxFileBytes) {
        message = EditorMessage(EditorMessageKind.fileTooLarge, name);
        notifyListeners();
        return;
      }
      final text = utf8.decode(await file.readAsBytes());
      final tab = EditorTab(path, text)..stamp = await _stampOf(path);
      _watch(tab);
      tabs.add(tab);
      activeIndex = tabs.length - 1;
    } on FormatException {
      message = EditorMessage(EditorMessageKind.notUtf8Open, name);
    } on FileSystemException catch (e) {
      message = EditorMessage(EditorMessageKind.readFailed, e.message);
    }
    notifyListeners();
  }

  /// 파일을 열고 [line]/[column](1부터)에 커서를 두어 보여 준다. 오류 목록·검색 결과에서 이동할 때 쓴다.
  Future<void> openAt(String path, int line, int column) async {
    await openFile(path);
    final tab = tabFor(path);
    if (tab == null) return;
    activeIndex = tabs.indexOf(tab);
    final lines = tab.controller.codeLines;
    final index = (line - 1).clamp(0, lines.length - 1);
    final offset = (column - 1).clamp(0, lines[index].text.length);
    tab.controller.selection = CodeLineSelection.collapsed(
      index: index,
      offset: offset,
    );
    notifyListeners();
    // 편집기가 화면에 올라와 배치를 마친 뒤에 그 줄이 가운데 오게 스크롤한다.
    void center() {
      try {
        tab.controller.makeCursorCenterIfInvisible();
      } on Object {
        // 편집기가 아직 붙지 않았으면 선택만 남는다.
      }
      tab.focusNode.requestFocus();
    }

    SchedulerBinding.instance.addPostFrameCallback(
      (_) => SchedulerBinding.instance.addPostFrameCallback((_) => center()),
    );
  }

  void selectTab(int index) {
    if (index < 0 || index >= tabs.length || index == activeIndex) return;
    activeIndex = index;
    notifyListeners();
  }

  /// 탭을 끌어서 순서를 바꾼다. [newIndex]는 옮긴 뒤의 자리다. 보고 있던 탭은 그대로 보고 있는다.
  void moveTab(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= tabs.length) return;
    newIndex = newIndex.clamp(0, tabs.length - 1);
    if (newIndex == oldIndex) return;
    final active = activeTab;
    tabs.insert(newIndex, tabs.removeAt(oldIndex));
    if (active != null) activeIndex = tabs.indexOf(active);
    notifyListeners();
  }

  void closeTab(int index) {
    if (index < 0 || index >= tabs.length) return;
    final tab = tabs.removeAt(index);
    if (activeIndex > index || activeIndex >= tabs.length) activeIndex -= 1;
    if (tabs.isEmpty) activeIndex = -1;
    notifyListeners();
    // 편집기 위젯이 이 탭을 내려놓은 다음에 정리한다.
    Future<void>.microtask(tab.dispose);
  }

  /// 수정 여부가 바뀔 때만 화면을 다시 그린다 (커서 이동·글자 입력마다 전체를 그리지 않는다).
  void _watch(EditorTab tab) {
    var wasDirty = false;
    tab.controller.addListener(() {
      final now = tab.dirty;
      if (now == wasDirty) return;
      wasDirty = now;
      _notifySafely();
    });
  }

  /// 편집기가 그려지는 도중(초기화·선택 영역 정리)에 값이 바뀌면 그 프레임이 끝난 뒤에 알린다.
  void _notifySafely() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // --- 저장 ----------------------------------------------------------------

  /// 탭의 글을 파일에 쓴다. 디스크의 파일이 따로 바뀐 상태면 덮어쓰지 않고 false.
  Future<bool> save(EditorTab tab) async {
    if (tab.external == ExternalChange.modified) {
      message = const EditorMessage(EditorMessageKind.diskChangedSaveBlocked);
      notifyListeners();
      return false;
    }
    try {
      await File(tab.path).writeAsString(tab.controller.text);
      tab.savedText = tab.controller.text;
      tab.stamp = await _stampOf(tab.path);
      tab.external = ExternalChange.none;
      notifyListeners();
      return true;
    } on FileSystemException catch (e) {
      message = EditorMessage(EditorMessageKind.saveFailed, e.message);
      notifyListeners();
      return false;
    }
  }

  /// 고친 탭을 모두 저장한다. 하나라도 저장하지 못하면 false.
  Future<bool> saveAll() async {
    var ok = true;
    for (final t in List.of(tabs)) {
      if (t.dirty && !await save(t)) ok = false;
    }
    return ok;
  }

  bool get hasUnsaved => tabs.any((t) => t.dirty);

  // --- 디스크 변경 감지 -------------------------------------------------------
  // Claude Code 가 같은 파일을 고치는 동안 그 파일이 열려 있으면 낡은 글이 보이고, 거기서 저장하면 그 수정을
  // 덮어쓴다. 열린 탭의 수정 시각·크기를 주기적으로 확인한다.

  Timer? _timer;
  bool _checking = false;

  /// 열린 탭을 [interval]마다 확인하기 시작한다. 창이 다시 활성화될 때는 바로 [checkExternalChanges]를 부른다.
  void startWatching({Duration interval = const Duration(seconds: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => checkExternalChanges());
  }

  void stopWatching() {
    _timer?.cancel();
    _timer = null;
  }

  Future<FileStamp?> _stampOf(String path) async {
    final stat = await FileStat.stat(path);
    return stat.type == FileSystemEntityType.notFound
        ? null
        : FileStamp(stat.modified, stat.size);
  }

  /// 열린 탭마다 디스크의 파일이 바뀌었는지 보고 처리한다.
  /// 수정하지 않은 탭은 조용히 다시 읽고, 수정 중인 탭은 사용자가 고르도록 표시만 한다.
  Future<void> checkExternalChanges() async {
    if (_checking || _disposed) return;
    _checking = true;
    try {
      var changed = false;
      for (final tab in List.of(tabs)) {
        final now = await _stampOf(tab.path);
        if (_disposed || !tabs.contains(tab)) continue;
        if (now == null) {
          if (tab.external != ExternalChange.deleted) {
            tab.external = ExternalChange.deleted;
            tab.stamp = null;
            changed = true;
          }
          continue;
        }
        if (now == tab.stamp && tab.external != ExternalChange.deleted) {
          continue;
        }
        changed |= await _applyDiskChange(tab, now);
      }
      if (changed) notifyListeners();
    } finally {
      _checking = false;
    }
  }

  /// 디스크의 글이 달라졌을 때의 처리. 화면을 다시 그려야 하면 true.
  Future<bool> _applyDiskChange(EditorTab tab, FileStamp now) async {
    String disk;
    try {
      disk = utf8.decode(await File(tab.path).readAsBytes());
    } on FormatException {
      tab.stamp = now;
      tab.external = ExternalChange.modified;
      message = EditorMessage(EditorMessageKind.changedNotUtf8, tab.name);
      return true;
    } on FileSystemException {
      return false; // 쓰는 도중이었을 수 있다 — 다음 확인 때 다시 본다.
    }
    tab.stamp = now;
    final wasExternal = tab.external != ExternalChange.none;
    // 시각만 바뀌고 글이 같으면 없던 일로 한다 (줄 끝 차이도 같은 글로 본다).
    if (_sameText(tab, disk)) {
      tab.external = ExternalChange.none;
      return wasExternal;
    }
    if (tab.dirty) {
      tab.external = ExternalChange.modified;
      return true;
    }
    _replaceText(tab, disk);
    tab.external = ExternalChange.none;
    message = EditorMessage(EditorMessageKind.changedReloaded, tab.name);
    return true;
  }

  bool _sameText(EditorTab tab, String disk) =>
      disk.replaceAll('\r\n', '\n') == tab.savedText.replaceAll('\r\n', '\n');

  /// 편집기 글을 [text]로 바꾸고 그것을 저장된 상태로 삼는다. 커서가 있던 줄은 가능한 한 유지한다.
  void _replaceText(EditorTab tab, String text) {
    final line = tab.controller.selection.extentIndex;
    tab.controller.text = text;
    tab.savedText = tab.controller.text;
    final last = tab.controller.codeLines.length - 1;
    tab.controller.selection = CodeLineSelection.collapsed(
      index: line > last ? last : line,
      offset: 0,
    );
  }

  /// 내 수정을 버리고 디스크의 글을 다시 읽는다.
  Future<void> reloadFromDisk(EditorTab tab) async {
    try {
      final disk = utf8.decode(await File(tab.path).readAsBytes());
      _replaceText(tab, disk);
      tab.stamp = await _stampOf(tab.path);
      tab.external = ExternalChange.none;
      message = EditorMessage(EditorMessageKind.reloadedFromDisk, tab.name);
    } on FormatException {
      message = const EditorMessage(EditorMessageKind.notUtf8Reload);
    } on FileSystemException catch (e) {
      message = EditorMessage(EditorMessageKind.readFailed, e.message);
    }
    notifyListeners();
  }

  /// 내 글을 유지한다. 다음에 저장하면 디스크의 파일을 내 글로 덮어쓰거나(바뀐 경우) 다시 만든다(삭제된 경우).
  void keepMine(EditorTab tab) {
    tab.external = ExternalChange.none;
    notifyListeners();
  }

  void clearMessage() {
    message = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final t in tabs) {
      t.dispose();
    }
    super.dispose();
  }
}
