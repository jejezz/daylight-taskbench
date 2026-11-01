// 확장 영역 가운데의 터미널 (PLAN.md §1.13): 처음 보일 때 셸을 찾고, 기본 셸을 **저장소 루트**에서 한 번 자동으로 띄운다.
// 세션은 [TerminalSessionsController]가 쥐고 있어서 이 위젯이 내려가도(터미널 패널을 껐다 켜도, 에디터로 전환해도)
// 살아 있다. 새 탭의 작업 폴더는 그때 열려 있는 저장소 루트다 (이미 열린 셸은 자기 폴더를 그대로 쓴다).

import 'package:flutter/material.dart';

import '../workspace/workspace.dart';
import 'terminal_panel.dart';
import 'terminal_sessions_controller.dart';
import 'terminal_settings.dart';

class TerminalHost extends StatefulWidget {
  const TerminalHost({
    super.key,
    required this.controller,
    required this.settings,
    required this.workspace,
  });

  final TerminalSessionsController controller;
  final TerminalSettings settings;
  final Workspace workspace;

  @override
  State<TerminalHost> createState() => _TerminalHostState();
}

class _TerminalHostState extends State<TerminalHost> {
  @override
  void initState() {
    super.initState();
    _autoOpen();
  }

  Future<void> _autoOpen() async {
    final c = widget.controller;
    await c.loadShells();
    if (!mounted || c.autoOpened || c.sessions.isNotEmpty) return;
    final root = widget.workspace.root;
    if (root == null || c.shells.isEmpty) return;
    c.autoOpened = true;
    c.add(root);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.workspace,
      builder: (context, _) => TerminalPanel(
        controller: widget.controller,
        settings: widget.settings,
        projectRoot: widget.workspace.root ?? '',
      ),
    );
  }
}
