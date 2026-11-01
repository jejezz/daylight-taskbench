// 확장 영역 가운데의 에디터 (PLAN.md §1.13, 단계 15): 열린 탭을 보이고, 컨트롤러가 남기는 알림을 번역해 안내한다.
// 탭(과 고치던 글)은 [EditorController]가 쥐고 있어서 이 위젯이 내려가도(에디터 패널을 껐다 켜도, 터미널과 전환해도)
// 그대로 남는다.

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'editor_controller.dart';
import 'editor_pane.dart';

String editorMessageText(AppLocalizations l10n, EditorMessage m) =>
    switch (m.kind) {
      EditorMessageKind.fileTooLarge => l10n.messageFileTooLarge(m.arg),
      EditorMessageKind.notUtf8Open => l10n.messageNotUtf8Open(m.arg),
      EditorMessageKind.readFailed => l10n.messageReadFailed(m.arg),
      EditorMessageKind.saveFailed => l10n.messageSaveFailed(m.arg),
      EditorMessageKind.diskChangedSaveBlocked =>
        l10n.messageDiskChangedSaveBlocked,
      EditorMessageKind.changedNotUtf8 => l10n.messageChangedNotUtf8(m.arg),
      EditorMessageKind.changedReloaded => l10n.messageChangedReloaded(m.arg),
      EditorMessageKind.reloadedFromDisk => l10n.messageReloadedFromDisk(m.arg),
      EditorMessageKind.notUtf8Reload => l10n.messageNotUtf8Reload,
      EditorMessageKind.formatted => l10n.messageFormatted,
      EditorMessageKind.alreadyFormatted => l10n.messageAlreadyFormatted,
      EditorMessageKind.formatNoDart => l10n.formatNoDart,
      EditorMessageKind.formatTempWriteFailed => l10n.formatTempWriteFailed(
        m.arg,
      ),
      EditorMessageKind.formatFailed => l10n.formatFailed,
      EditorMessageKind.formatFailedDetail => l10n.formatFailedDetail(m.arg),
      EditorMessageKind.formatJsonInvalid => l10n.formatJsonInvalid(m.arg),
    };

class EditorHost extends StatefulWidget {
  const EditorHost({super.key, required this.controller});

  final EditorController controller;

  @override
  State<EditorHost> createState() => _EditorHostState();
}

class _EditorHostState extends State<EditorHost> {
  @override
  void initState() {
    super.initState();
    // 에디터가 보이는 동안만 디스크 변경을 주기적으로 본다. 패널을 껐다 켰을 때는 켜자마자 한 번 바로 본다.
    widget.controller
      ..addListener(_showMessage)
      ..startWatching()
      ..checkExternalChanges();
  }

  @override
  void dispose() {
    widget.controller
      ..removeListener(_showMessage)
      ..stopWatching();
    super.dispose();
  }

  /// 컨트롤러가 알림을 남기면 한 번 보이고 지운다.
  void _showMessage() {
    final m = widget.controller.message;
    if (m == null || !mounted) return;
    widget.controller.clearMessage();
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(editorMessageText(AppLocalizations.of(context), m)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => EditorPane(controller: widget.controller),
  );
}
