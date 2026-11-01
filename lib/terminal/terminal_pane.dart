import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm2/ui.dart' as xterm_ui;
import 'package:xterm2/xterm.dart';

import '../theme/app_theme.dart';
import 'local_shell_session.dart';
import 'pass_through_cursor.dart';
import 'terminal_settings.dart';
import 'terminal_theme.dart';

// [Taskbench에서 달라진 곳] 위치는 lib/terminal/, 앱 전역 단축키 전달 목록이 taskbench 것(⌘/Ctrl+, · ⌘/Ctrl+Shift+O)이다.

/// 터미널 탭 하나의 화면. 렌더링과 키보드(IME 포함) 입력은 xterm2의 [xterm_ui.TerminalView]가 전담한다.
/// daylight-terminal-flutter의 widgets/terminal_pane.dart에서 가져와 줄인 것(파일 끌어놓기는 없다).
class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key, required this.session, required this.settings, this.active = true});

  final LocalShellSession session;
  final TerminalSettings settings;

  /// 보이는 탭인가 — 가려진 탭은 스크롤바 등 포인터 영역을 그리지 않는다.
  final bool active;

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  final _controller = xterm_ui.TerminalController();
  final _scroll = ScrollController();
  final _focusNode = FocusNode();
  bool _scrollable = false;

  /// 스크롤바가 있을 때 오른쪽 가장자리의 폭(바깥 여백 + 호버 때 두꺼워진 스크롤바 12px + 여유).
  static const _scrollbarWidth = AppSpacing.sm + 16.0;

  @override
  void initState() {
    super.initState();
    if (widget.active) _requestFocusSoon();
  }

  @override
  void didUpdateWidget(covariant TerminalPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // IndexedStack은 탭을 숨길 뿐 내려놓지 않으므로, 다른 세션 탭에서 돌아왔을 때 직접 포커스를 되돌린다.
    if (widget.active && !oldWidget.active) _requestFocusSoon();
  }

  void _requestFocusSoon() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _focusNode.requestFocus();
  });

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 스크롤 범위가 생기거나 없어졌는지 프레임 뒤에 직접 읽는다.
  void _checkScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final scrollable = _scroll.position.maxScrollExtent > 0;
      if (scrollable != _scrollable) setState(() => _scrollable = scrollable);
    });
  }

  /// 오른쪽 클릭: 선택이 있으면 복사, 없으면 붙여넣기.
  Future<void> _onSecondaryTapDown(Terminal terminal) async {
    final selection = _controller.selection;
    if (selection != null) {
      final text = terminal.buffer.getText(selection);
      _controller.clearSelection();
      await Clipboard.setData(ClipboardData(text: text));
    } else {
      final data = await Clipboard.getData('text/plain');
      final text = data?.text;
      if (text != null) terminal.paste(text);
    }
  }

  /// 앱 전역 단축키는 xterm이 제어 문자로 보내버리기 전에 상위(셸의 `CallbackShortcuts`)로 넘긴다.
  /// 설정(⌘/Ctrl+,)과 파일 이름으로 열기(⌘/Ctrl+Shift+O)만 넘긴다. `Ctrl+O·R` 같은 것은 셸의 줄 편집에서 쓰므로
  /// 가로채지 않는다.
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final keys = HardwareKeyboard.instance;
    final primary = mac ? keys.isMetaPressed : keys.isControlPressed;
    if (!primary) return KeyEventResult.ignored;
    final forward = switch (event.logicalKey) {
      LogicalKeyboardKey.comma => true,
      LogicalKeyboardKey.keyO => keys.isShiftPressed,
      _ => false,
    };
    return forward ? KeyEventResult.skipRemainingHandlers : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final terminal = widget.session.terminal;
    return LayoutBuilder(
      builder: (context, constraints) {
        // 리사이즈 중 잠깐 0이 되면 xterm2가 행/열 계산에서 오류를 내므로 그릴 때만 건너뛴다.
        if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) return const SizedBox.shrink();
        final view = xterm_ui.TerminalView(
          terminal,
          controller: _controller,
          scrollController: _scroll,
          focusNode: _focusNode,
          theme: terminalColorTheme(context),
          textStyle: terminalStyle(context, widget.settings),
          padding: const EdgeInsets.all(AppSpacing.sm),
          onKeyEvent: _onKeyEvent,
          onSecondaryTapDown: (details, offset) => _onSecondaryTapDown(terminal),
        );
        return NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _checkScrollable();
            return false;
          },
          child: Stack(
            children: [
              Positioned.fill(child: view),
              if (_scrollable && widget.active)
                const Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: _scrollbarWidth,
                  child: PassThroughCursorRegion(cursor: SystemMouseCursors.basic),
                ),
            ],
          ),
        );
      },
    );
  }
}
