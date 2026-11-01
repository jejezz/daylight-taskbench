# workbench 코드 비교 — 확장 모드 단계 10 결과 (2026-11-01)

PLAN.md §5 단계 10. daylight-workbench(v0.5.2, 2026-10-30)와 taskbench(2026-11-01)에서 **같은 원본에서 복사한 코드**를 비교해,
확장 모드(§1.13)로 workbench를 흡수할 때 무엇을 가져오고 무엇을 버릴지 가렸다. 이 단계에서 **코드는 바꾸지 않았다.**

## 1. 비교 방법과 한계

- 대응: workbench `branchdock/` ↔ taskbench `docks/branch/`, workbench `core/` ↔ `core/`, workbench `devices/`·`doctor/`·`flutter/`·`install/` ↔ `docks/flutty/` 같은 이름.
- 정규화: 주석, `import/export/part`, 공백·줄바꿈, 닫는 괄호 앞 쉼표를 지우고 토큰 단위로 비교했다 (workbench는 120칸, taskbench는 80칸으로 포맷돼서 줄 단위 diff는 서식 차이로 부풀려진다). 그다음 `context.icons.x`/`Icons.x`를 같은 것으로, `bdFoo`를 `foo`로 간주해 한 번 더 비교했다.
- **한계**: 두 앱이 복사해 온 원본(`branch-dock-flutter`, `flutty-dock-flutter`)이 이 폴더에 없어서 3자 비교는 못 했다. 그래서 "어느 쪽이 나중에 고친 것인가"는 git 기록(workbench 218커밋, taskbench 44커밋)과 코드 내용으로만 짐작했다. 또 큰 파일의 작은 차이(10~70토큰)는 대표 몇 곳만 읽었고 전부 읽지는 않았다.

## 2. 수치

| | 개수 |
|---|---|
| 양쪽에 있는 파일 | 60 |
| 정규화 후 완전히 같음 | 26 (줄 단위 24 → 토큰 단위 25 → 아이콘·접두어 정규화 후 26) |
| 차이가 있음 | 34 — 그중 10토큰 이하가 10개 (아이콘·글꼴·문구 접두어 수준) |
| workbench에만 있음 | 8 |
| taskbench에만 있음 | 26 |

결론: **branch 코드의 "갈라짐"은 대부분 로직 차이가 아니라 UI 스타일 API 차이**다 (아래 A). 실제 기능 차이는 몇 군데에 몰려 있다.

## 3. 차이의 종류

### A. 스타일 API 차이 — 로직은 같음 (taskbench 쪽을 유지)

| 영역 | workbench | taskbench |
|---|---|---|
| 아이콘 | `context.icons.x` (`theme/studio_icons.dart` 157줄) | `Icons.x_rounded` 직접 |
| 글꼴 | `context.mono(..)`, `context.userText(..)` | `AppFonts.mono.copyWith(..)`, `AppFonts.userContent` |
| 단추 라벨 + 단축키 | `Text('$label  ${shortcutLabel(..)}')` | `LabelWithShortcut` 위젯 |
| 문구 접두어 | `bd…` (`branchdock/l10n`) | 접두어 없는 공통 키 |
| 설정 키 | `pull_mode:`, `auto_fetch`, `recent_repos` | `branch.pull_mode:`, `branch.auto_fetch`, 최근 목록은 공통 `recent_dirs` |

pr_tab(472토큰), widgets(376), release_tab(76), branches_tab(71)의 차이는 이 표의 항목이 대부분이다. 읽은 hunk 가운데 이 범위를 벗어나는 것은 B-1(병합 관문)과 B-2(에디터 연결점)뿐이었다.

### B. workbench에만 있는 것 — **가져올지 정해야 한다**

1. **검증 관문(병합 전 로컬 검증 기록).** `verify/`(345줄: `verify_store`·`verify_state`·`verify_gate_controller`) + `branchdock/ui/merge_gate.dart` + `pr_tab`의 병합 단추 연결 + Run 패널의 검증 기록. PR head 커밋이 로컬에서 검증됐는지(검증됨 / 빌드만 / 문제 / 오래됨 / 없음) 판정해 병합·릴리스 앞에 세운다. workbench README의 "작업 → 로컬 검증 → 병합 → 릴리스를 건너뛸 수 없게"가 이것이다. **taskbench에는 없다** (`MergeGate`·`verify` 검색 결과 없음). 이 기능을 쓰는 사람이 workbench를 보관하면 잃는 유일한 "기능"이다.
2. **에디터 연결점.** `changes_tab`의 `onShowDiff`·`onOpenFile`(변경 파일 더블클릭 → 내장 에디터, 변경점 보기), `markdown_editor`, `status_header`의 `onBranchTap`. 에디터가 없는 taskbench에는 당연히 없다. **단계 15·16에서 다시 연결**한다.
3. **Git 패널 범위의 바텀시트.** workbench `action_sheet.dart`는 `useRootNavigator: false`로 시트를 Git 패널 안의 로컬 Navigator에 띄운다 ("앱 전역이 아니라 패널 범위"). taskbench는 이 처리가 없다. 확장 모드에서 도크 열이 창의 일부가 되면 **시트가 도크 열 안에 떠야 하는지 창 전체에 떠야 하는지** 정해야 한다 (단계 11).
4. **확인 못 한 수정.** workbench 커밋 기록에 있는 "앱 종료 시 디버그 실행도 끝낸다", "Windows debug를 빌드 없이 다시 실행", "Stop이 프로세스 트리 전체를 끝낸다"는 taskbench에도 있는지 확인하지 못했다. 트리 종료는 taskbench `command_runner`에 `taskkill`·`pgrep` 처리가 있어 같은 문제를 푼 것으로 보이지만, 나머지 둘은 코드를 찾지 못했다. → 단계 11·16에서 실제 앱으로 확인한다.

### C. taskbench가 더 나아간 것 — 유지

- 공통 코어로 추출: `core/command_runner`(합집합, 단계 2), `core/run_session`, `core/tool_paths`, `core/check_status`, `core/elevation`, `core/devices/*`, `core/ui/*`(공용 위젯 11개).
- Doctor: 점검 항목이 13개로 workbench(7개)보다 많다 (기기 연결·개발자 모드·서명·프로필 등). workbench `doctor/`는 "환경 점검"만 있다.
- Branch Dock 쪽 화면: `branch_dock_body`, `command_palette`, `environment_sheet`, `onboarding`, 접힌 제목 요약 등. `status_header`는 공유 영역으로 올라가면서 workbench와 구조가 다르다 (1553토큰 차이는 이 구조 변경 때문).
- Flutter 프로젝트 감지는 `workspace/project_detector.dart`로 옮겨 갔다 (workbench `flutter_project.dart`의 `findAll`에 해당).

## 4. 제안 (사용자 확인 필요)

| # | 항목 | 제안 | 이유 |
|---|---|---|---|
| 1 | 아이콘 API | **taskbench 방식(`Icons.x`)으로 통일** — 에디터·터미널·탐색기를 옮길 때 `context.icons`를 변환한다 | workbench의 `context.icons` 사용 파일은 81개, 그중 에디터·트리·터미널·diff 쪽이 24개. 변환은 기계적이지만 양이 있다. 대안: `studio_icons`(157줄)를 taskbench로 가져와 한 곳에서 아이콘을 바꿀 수 있게 한다 — 테마별 아이콘 교체를 쓰고 있다면 이쪽 |
| 2 | 검증 관문 | **가져오지 않는다 (보류)**. 가져오려면 별도 단계로 | taskbench의 정체성(도킹형 Git·Runner)과 별개 기능이고 `verify/`·Run 패널·pr_tab이 얽혀 있다. 지금 쓰고 있다면 "단계 18 후보"로 두고 사용 여부를 알려 주기 |
| 3 | 바텀시트 범위 | **도크 열 안에 가둔다** (확장 모드에서) — 단계 11에서 결정 | 확장 모드에서는 도크 열이 창의 일부이므로, 시트가 창 전체를 덮으면 탐색기·에디터까지 가려진다. 다만 실제 폭과 느낌은 단계 11 화면에서 보고 정한다 |
| 4 | 문구·설정 키 | taskbench 쪽을 그대로 | A 표 |
| 5 | 확인 못 한 수정 3건 | 단계 11·16의 완료 조건에 실제 확인 항목으로 넣는다 | B-4 |

## 5. 다음 단계에 주는 영향

- **단계 11**: B-3(시트 범위) 결정이 필요하고, 모드 전환 때 창 크기 기억에 workbench의 "창 크기 기억" 수정(2026-10-29)과 겹치는 부분이 있는지 본다.
- **단계 13~15**: 아이콘 API(제안 1)에 따라 이식 작업량이 달라진다. 에디터·트리·터미널 쪽 24개 파일이 변환 대상이다.
- **단계 15·16**: B-2의 에디터 연결점을 다시 이어 붙인다.
- 갈라진 로직이 크지 않아서 **단계 10을 이유로 이후 범위가 커질 일은 없다.** 검증 관문(B-1)만 범위 결정이 남아 있다.
