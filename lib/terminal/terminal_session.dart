/// daylight-terminal-flutter의 state/terminal_session.dart를 간단히 줄인 것 — 이 앱은 로컬 셸 한 가지만
/// 다루므로 SSH·기록(logging)·ANSI 제거·파일 끌어놓기·터미널 현재 경로 확인 같은 것은 두지 않는다.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:xterm2/xterm.dart';

enum SessionStatus { idle, connecting, connected, error }

/// 탭 하나의 터미널 세션. 터미널 화면과 입력 보내기를 맡는다.
///
/// 하위 클래스는 입력을 어디로 보낼지([writeInput])와 크기가 바뀔 때 무엇을 할지([onTerminalResize])를
/// 채우고, 받은 출력을 [handleOutput]으로 넘긴다.
abstract class TerminalSession extends ChangeNotifier {
  TerminalSession({int scrollback = 10000}) : terminal = Terminal(maxLines: scrollback) {
    terminal.onOutput = (data) => writeInput(utf8.encode(data));
    terminal.onResize = onTerminalResize;
  }

  final Terminal terminal;
  late final ByteConversionSink _terminalSink = const Utf8Decoder(allowMalformed: true)
      .startChunkedConversion(FnSink((s) => terminal.write(s)));

  bool _disposed = false;
  SessionStatus _status = SessionStatus.idle;

  /// 탭에 보이는 이름.
  String get tabTitle;

  /// 터미널(셸)에 입력 바이트를 보낸다. 연결되어 있지 않으면 아무 일도 하지 않는다.
  @protected
  void writeInput(List<int> bytes);

  /// 터미널 화면의 칸 수가 바뀌었다 — 상대 쪽 pty 크기도 맞춘다.
  @protected
  void onTerminalResize(int width, int height, int pixelWidth, int pixelHeight);

  SessionStatus get status => _status;
  bool get connected => _status == SessionStatus.connected;
  bool get disposed => _disposed;

  @protected
  void setStatus(SessionStatus value) => _status = value;

  /// 해제된 뒤에는 알리지 않는다.
  @protected
  void notify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// 셸이 보낸 출력을 화면에 그린다.
  @protected
  void handleOutput(Uint8List chunk) => _terminalSink.add(chunk);

  /// 탐색기 등에서 끌어온 경로를 인용해 프롬프트에 입력한다 (Enter는 누르지 않는다).
  void typePaths(List<String> paths) {
    if (!connected || paths.isEmpty) return;
    terminal.paste('${paths.map(_quote).join(' ')} ');
  }

  String _quote(String path) => path.contains(' ') || path.contains("'") ? '"${path.replaceAll('"', '\\"')}"' : path;

  void clearTerminal() => terminal.clear();

  @override
  void dispose() {
    _disposed = true;
    terminal.dispose();
    super.dispose();
  }
}

/// 문자열을 받는 함수 하나를 [Sink]로 감싼다 (청크 디코더의 출력용).
class FnSink implements Sink<String> {
  FnSink(this._onData);
  final void Function(String) _onData;
  @override
  void add(String data) => _onData(data);
  @override
  void close() {}
}
