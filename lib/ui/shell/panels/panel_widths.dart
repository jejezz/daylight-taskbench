// 확장 모드의 패널 너비 (PLAN.md §1.13): 탐색기 · 가운데(에디터|터미널) · 도크 열. 탐색기와 도크 열은 구분선을 끌어
// 너비를 바꾸고, 가운데는 남는 폭을 쓴다. 원하는 너비는 저장하고(다음 실행에도), 창이 좁아지면 그 순간만 최소 너비를
// 지키는 선에서 줄여서 보인다(저장한 값은 그대로 둔다).
// 계산은 화면과 무관한 순수 함수라서 테스트할 수 있다.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanelWidths extends ChangeNotifier {
  PanelWidths(this._prefs)
    : _explorer = _read(
        _prefs,
        explorerKey,
        defaultExplorer,
        minExplorer,
        maxExplorer,
      ),
      _dock = _read(_prefs, dockKey, defaultDock, minDock, maxDock);

  /// 저장 키 — 앱 공통 목록(`keys_test`)에 있다.
  static const explorerKey = 'panel_width_explorer';
  static const dockKey = 'panel_width_dock';

  static const defaultExplorer = 240.0;
  static const minExplorer = 160.0;
  static const maxExplorer = 480.0;

  /// 도크 열의 기본 폭은 도킹 모드의 기본 폭과 같다 — 앱 바·브랜치 줄·아코디언이 도킹 모드와 똑같이 보인다.
  static const defaultDock = 440.0;

  /// 도크 열의 최소 폭. 앱 바의 좁은 막대 모드(420 미만)가 폴더 이름과 단추를 지키는 한계다.
  static const minDock = 380.0;
  static const maxDock = 760.0;

  /// 가운데(에디터·터미널)의 최소 폭.
  static const minCenter = 270.0;

  /// 구분선(끄는 자리)의 폭.
  static const handle = 6.0;

  final SharedPreferences _prefs;
  double _explorer;
  double _dock;

  /// 사용자가 원하는 너비(저장한 값). 화면에 보이는 너비는 [explorerFit]·[dockFit]이 창 크기에 맞춰 정한다.
  double get explorer => _explorer;
  double get dock => _dock;

  Future<void> setExplorer(double value) async {
    final v = value.clamp(minExplorer, maxExplorer);
    if (v == _explorer) return;
    _explorer = v;
    notifyListeners();
    await _store(explorerKey, v);
  }

  Future<void> setDock(double value) async {
    final v = value.clamp(minDock, maxDock);
    if (v == _dock) return;
    _dock = v;
    notifyListeners();
    await _store(dockKey, v);
  }

  Future<void> resetExplorer() => setExplorer(defaultExplorer);
  Future<void> resetDock() => setDock(defaultDock);

  Future<void> _store(String key, double value) async {
    try {
      await _prefs.setDouble(key, value);
    } on Object {
      // 저장하지 못해도 이번 실행에는 적용된다.
    }
  }

  static double _read(
    SharedPreferences p,
    String key,
    double def,
    double min,
    double max,
  ) {
    final v = p.getDouble(key);
    if (v == null || !v.isFinite) return def;
    return v.clamp(min, max);
  }

  // ── 창 크기에 맞춘 계산 (순수 함수) ─────────────────────────────────────

  /// 도크 열 왼쪽 영역(탐색기 + 가운데)이 가져야 하는 최소 폭.
  static double areaMin({required bool hasExplorer, required bool hasCenter}) {
    var w = 0.0;
    if (hasExplorer) w += minExplorer;
    if (hasCenter) w += minCenter;
    if (hasExplorer && hasCenter) w += handle;
    return w;
  }

  /// 창 전체 폭 [total] 안에서 도크 열이 실제로 가질 폭: 원하는 폭 [preferred]를 [minDock] 이상으로 하되, 왼쪽 영역이
  /// 최소 폭 [areaMin]을 지킬 수 있게 줄인다. 창이 너무 좁으면 도크 열의 최소 폭을 우선한다.
  static double dockFit({
    required double total,
    required double areaMin,
    required double preferred,
  }) {
    final upper = total - handle - areaMin;
    return preferred.clamp(minDock, upper < minDock ? minDock : upper);
  }

  /// 왼쪽 영역 폭 [area] 안에서 탐색기가 실제로 가질 폭. 가운데가 없으면 영역 전체를 쓰고, 있으면 가운데가
  /// [minCenter]를 지킬 수 있게 줄인다.
  static double explorerFit({
    required double area,
    required bool hasCenter,
    required double preferred,
  }) {
    if (!hasCenter) return area;
    final upper = area - handle - minCenter;
    return preferred.clamp(
      minExplorer,
      upper < minExplorer ? minExplorer : upper,
    );
  }
}
