// 아코디언 한 칸 = DockModule (PLAN.md §4.1). 셸은 이 목록만 안다 — 칸을 추가해도 셸 코드는 바뀌지 않는다.
//
// 새 칸은 이 약속(appliesTo · summary · mood · onHeadChange)만 지키면 공유 영역·브랜치 전환·끌어놓기 규칙을
// 자동으로 따른다. `test/dock_contract_test.dart` 가 같은 약속을 모든 칸에 대해 검사한다.
// 이 인터페이스는 0.x — Rust·Electron runner 를 붙이며 모양을 다시 검증한다 (§4.3).

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/taskbench_style.dart';
import '../workspace/git_state.dart';
import '../workspace/workspace.dart';

abstract class DockModule extends ChangeNotifier {
  /// 'branch', 'flutty', 나중에 'rust', 'electron'. 설정 키 접두어와 저장된 펼침 상태에도 쓴다.
  String get id;

  IconData get icon;

  String title(AppLocalizations l10n);

  /// 실행기(runner) 칸인가. 실행기가 하나도 안 보이면 셸이 "Run" 안내 칸을 대신 둔다 (§4.1).
  bool get isRunner => false;

  /// 이 디렉터리에서 칸을 보일지. Branch는 항상, 실행기 칸은 프로젝트가 감지될 때만 (§4.1).
  bool appliesTo(Workspace w) => true;

  /// 접힌 제목 오른쪽의 한 줄 요약.
  Widget summary(BuildContext context, Workspace w);

  /// 펼쳤을 때 남는 높이 전체를 쓰는 내용. 접혀도 위젯은 살아 있다.
  Widget body(BuildContext context, Workspace w);

  /// 배경 색과 제목 점에 쓰는 지금 상태.
  TaskbenchMood mood(Workspace w) => TaskbenchMood.idle;

  /// 일이 진행 중인가 (점이 깜빡이고, 다른 저장소를 열 때 확인을 받는다).
  bool busy(Workspace w) => false;

  /// 저장소가 열렸거나 바뀐 뒤 한 번 불린다. 구독이 필요하면 여기서 한다.
  void attach(Workspace w) {}

  void detach(Workspace w) {}

  /// 브랜치 전환·커밋 이동·병합 시작/끝. **접혀 있어도** 불린다 (§1.10).
  void onHeadChange(Workspace w, HeadChange change) {}
}
