// 도킹 모드와 확장 모드의 창 크기 (PLAN.md §1.13). 모드는 패널 켜짐에서 파생되고(PanelLayout),
// 이 클래스는 모드가 바뀔 때 창 크기를 그 모드의 크기로 바꾸고 모드별로 기억한다.
//
// - 모드가 바뀌면 **너비만** 그 모드의 것으로 바꾼다. 높이는 사용자가 맞춰 둔 그대로 둔다 (패널을 켰다고
//   창 높이가 바뀌면 안 된다). 너비는 모드별로 기억한다.
// - **도크 열이 있는 오른쪽 가장자리를 고정한 채** 왼쪽으로 늘어나거나 줄어든다. 창이 화면 밖으로 나가지 않게
//   모니터 작업 영역 안으로 맞춘다.
// - 앱은 항상 도킹 모드로 시작한다 (패널 켜짐은 저장하지 않는다). Windows 는 기존 [WindowPlacement]가 도킹
//   모드의 위치·크기를 기억한다 (다른 모드에서는 저장하지 않아 다음 시작이 큰 창으로 열리지 않는다).

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'window_placement.dart';

/// 창 크기 모드 (§1.13). 패널 켜짐에서 파생된다 — 탐색기만 켜면 가운데 자리가 없어서 창도 그만큼만 넓어진다.
enum WindowMode { dock, explorer, expanded }

class WindowModeSpec {
  const WindowModeSpec({
    required this.size,
    required this.minimum,
    required this.widthKey,
  });

  final Size size;
  final Size minimum;

  /// 이 모드의 마지막 너비를 저장하는 키.
  final String widthKey;
}

/// 도킹: 편집기 옆 세로 창 (§1.5). 탐색기만: 탐색기 240 + 도크 열 440. 확장: 도크 열 440 + 확장 영역 (§1.13).
/// 확장의 최소 폭 960 = 도크 열 440 + 확장 영역 520 (탐색기 240 + 가운데 최소 270 + 여백).
const dockSpec = WindowModeSpec(
  size: Size(440, 960),
  minimum: Size(380, 560),
  widthKey: 'window_width_dock',
);
const explorerSpec = WindowModeSpec(
  size: Size(680, 960),
  minimum: Size(680, 560),
  widthKey: 'window_width_explorer',
);
const expandedSpec = WindowModeSpec(
  size: Size(1240, 820),
  minimum: Size(960, 560),
  widthKey: 'window_width_expanded',
);

WindowModeSpec specOf(WindowMode mode) => switch (mode) {
  WindowMode.dock => dockSpec,
  WindowMode.explorer => explorerSpec,
  WindowMode.expanded => expandedSpec,
};

/// 크기 계산 (화면에 아무것도 하지 않는 순수 함수라서 테스트할 수 있다).
abstract final class WindowModeMath {
  /// [current] 창을 [target] 크기로 바꾼다. 오른쪽 가장자리와 위쪽을 고정하고 왼쪽으로 늘어난다.
  /// [work]가 있으면 그 작업 영역 안에 들어오도록 줄이고 밀어 넣는다.
  static Rect anchoredRight(Rect current, Size target, {Rect? work}) {
    var w = target.width;
    var h = target.height;
    if (work != null) {
      w = w.clamp(0, work.width);
      h = h.clamp(0, work.height);
    }
    var left = current.right - w;
    var top = current.top;
    if (work != null) {
      left = left.clamp(work.left, work.right - w);
      top = top.clamp(work.top, work.bottom - h);
    }
    return Rect.fromLTWH(left, top, w, h);
  }

  /// 모드가 바뀔 때의 목표 크기: 너비는 그 모드의 기억(없으면 기본), 높이는 지금 높이 그대로.
  /// 둘 다 그 모드의 최소 크기보다 작아지지 않는다.
  static Size target({
    required double? savedWidth,
    required double currentHeight,
    required WindowModeSpec spec,
  }) {
    final width = sanitizeWidth(savedWidth, spec);
    final height = currentHeight.isFinite && currentHeight > spec.minimum.height
        ? currentHeight
        : spec.minimum.height;
    return Size(width, height);
  }

  /// 저장한 너비가 없거나 최소 너비보다 작거나 이상하면 그 모드의 기본 너비로 돌린다.
  static double sanitizeWidth(double? saved, WindowModeSpec spec) {
    if (saved == null || !saved.isFinite || saved < spec.minimum.width) {
      return spec.size.width;
    }
    return saved;
  }

  /// 저장한 크기가 최소 크기보다 작거나 이상하면 기본 크기로 돌린다.
  static Size sanitize(Size? saved, WindowModeSpec spec) {
    if (saved == null ||
        !saved.width.isFinite ||
        !saved.height.isFinite ||
        saved.width < spec.minimum.width ||
        saved.height < spec.minimum.height) {
      return spec.size;
    }
    return saved;
  }

  static Size? parseSize(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final w = double.tryParse(parts[0]);
    final h = double.tryParse(parts[1]);
    if (w == null || h == null) return null;
    return Size(w, h);
  }
}

class WindowModeController with WindowListener {
  WindowModeController(this._prefs) {
    if (WindowPlacement.enabled) {
      _placement = WindowPlacement(
        _prefs,
        defaultSize: dockSpec.size,
        // 도킹 모드가 아닐 때는 위치·크기를 저장하지 않는다 — 다음 시작은 항상 도킹이다.
        isDocked: () => _mode != WindowMode.dock,
      );
    }
  }

  /// 도킹 모드의 크기를 저장하는 키 (Windows 가 아닌 곳).
  static const dockSizeKey = 'window_size_dock';

  final SharedPreferences _prefs;
  WindowPlacement? _placement;
  WindowMode _mode = WindowMode.dock;
  Timer? _debounce;

  WindowMode get mode => _mode;
  WindowModeSpec get spec => specOf(_mode);

  /// 시작할 때 쓸 창 크기: 도킹 모드에서 기억한 크기가 있으면 그것, 없으면 기본.
  Size get initialSize => WindowModeMath.sanitize(
    WindowModeMath.parseSize(_prefs.getString(dockSizeKey)),
    dockSpec,
  );

  /// Windows 의 배치 도우미 (그 밖 OS 는 null).
  WindowPlacement? get placement => _placement;

  /// 창을 보인 뒤에 한 번 부른다.
  void attach() {
    _placement?.attach();
    windowManager.addListener(this);
  }

  void detach() {
    _debounce?.cancel();
    _placement?.detach();
    windowManager.removeListener(this);
  }

  // ── 크기 기억 ────────────────────────────────────────────────────────────

  @override
  void onWindowResized() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveSize);
  }

  /// 지금 모드의 너비를 저장한다. 도킹 모드는 (Windows 가 아니면) 크기도 저장한다.
  Future<void> _saveSize() async {
    try {
      if (await windowManager.isMaximized() ||
          await windowManager.isFullScreen() ||
          await windowManager.isMinimized()) {
        return;
      }
      final size = await windowManager.getSize();
      await _prefs.setDouble(spec.widthKey, size.width);
      if (_mode == WindowMode.dock && _placement == null) {
        await _prefs.setString(dockSizeKey, '${size.width},${size.height}');
      }
    } catch (e) {
      debugPrint('window size save failed: $e');
    }
  }

  // ── 모드 전환 ────────────────────────────────────────────────────────────

  /// 모드가 바뀌었을 때 창의 **너비만** 그 모드의 것으로 바꾼다 (높이는 그대로). 같은 모드면 아무것도 하지 않는다.
  Future<void> switchTo(WindowMode next) async {
    if (next == _mode) return;
    final prev = _mode;
    final from = specOf(prev);
    final to = specOf(next);
    try {
      await _saveSize(); // 떠나는 모드의 너비를 기억한다
      _mode = next;
      // 줄일 때는 최소 크기를 먼저 낮추고, 늘릴 때는 늘린 뒤에 올린다 (창이 최소 크기에 걸려 안 줄어드는 것을 막는다).
      await windowManager.setMinimumSize(
        Size(
          from.minimum.width < to.minimum.width
              ? from.minimum.width
              : to.minimum.width,
          from.minimum.height < to.minimum.height
              ? from.minimum.height
              : to.minimum.height,
        ),
      );
      final current = await windowManager.getBounds();
      final target = WindowModeMath.target(
        savedWidth: _prefs.getDouble(to.widthKey),
        currentHeight: current.height,
        spec: to,
      );
      await windowManager.setBounds(
        WindowModeMath.anchoredRight(
          current,
          target,
          work: await _workAreaOf(current),
        ),
      );
      await windowManager.setMinimumSize(to.minimum);
    } catch (e) {
      // 크기를 못 바꿔도 앱은 계속 쓸 수 있어야 한다.
      _mode = next;
      debugPrint('window mode switch failed: $e');
    }
  }

  /// 창이 걸쳐 있는 모니터의 작업 영역 (논리 좌표). 못 찾으면 null.
  Future<Rect?> _workAreaOf(Rect window) async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      Rect? best;
      var bestArea = 0.0;
      for (final d in displays) {
        final size = d.visibleSize ?? d.size;
        final pos = d.visiblePosition ?? Offset.zero;
        final area = pos & size;
        final i = window.intersect(area);
        final a = i.width <= 0 || i.height <= 0 ? 0.0 : i.width * i.height;
        if (a > bestArea) {
          best = area;
          bestArea = a;
        }
      }
      return best;
    } catch (_) {
      return null;
    }
  }
}
