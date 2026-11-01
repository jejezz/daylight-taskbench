# Daylight Taskbench — 합치기 계획서 (초안 v0.2)

**Taskbench = 개발 작업대(task bench).** 처음 이름은 Fig(Flutter in GitHub)였고, Flutter + GitHub 도구 두 개(Branch Dock, Flutty Dock)로 시작해 Rust runner 등 작업 도구를 더 꽂을 수 있게 확장할 앱이다. 도킹형 데스크톱 앱.

- **Branch Dock** (`branch-dock-flutter`, v1.0.1+39) — git / gh: 변경·브랜치·태그·원격·릴리스·PR·CI
- **Flutty Dock** (`flutty-dock-flutter`, v0.8.1+22) — Flutter 앱을 USB 실기기·데스크톱에 빌드/설치/실행

두 앱은 이미 기능이 거의 끝나 있다. 이 계획의 중심은 **(1) 한 창의 화면 구성**과 **(2) 기능을 깨뜨리지 않고 옮기는 방법**이다.
원본 두 저장소는 **수정하지 않는다** (daylight-workbench와 같은 방식: 복사해서 쓰고, 달라진 곳은 주석으로 표시).

---

## 1. 화면 구성 (가장 중요)

### 1.0 시작 화면 — 저장소 열기에서 시작

앱을 처음 켜면(또는 저장소를 닫으면) **Branch Dock의 시작 화면(`start_screen.dart`)을 그대로** 보여 준다. 아코디언은 저장소가 열린 뒤에야 나타난다.

```
┌────────────────────────────────────────┐
│ Daylight Taskbench           ◐ 文 ⚙ ⓘ │  앱 바 (디렉터리·브랜치 줄 없음)
├────────────────────────────────────────┤
│            📂                           │
│   저장소를 열어 시작하세요              │
│   [ 폴더 열기  ⌘O ]  [ GitHub에서 복제 ]│
│   (폴더를 끌어다 놓아도 됩니다)         │
│                                        │
│ 최근 저장소                             │
│  ▣ my_app        ~/dev/my_app        ✕ │
│  ▣ other         ~/dev/other         ✕ │
│                                        │
│ 환경: ✓ git 2.45   ✓ gh 2.50 (로그인됨) │  환경 점검 (없으면 경고 + 경로 지정)
└────────────────────────────────────────┘
```

- 내용은 Branch Dock과 같다: 폴더 열기(⌘O), 끌어놓기, 최근 목록(✕로 제거), GitHub 복제(`gh` 로그인 시), 환경 점검(git·gh 경로 지정, 진단 복사, 다시 확인).
- **저장소가 아닌 폴더**를 고르면 지금처럼 시작 화면에 머문 채 실패 안내 + `git init` 단추를 보여 준다 (`OpenFailure.notRepo` → `onInitRepository`). 즉 **Taskbench는 git 저장소를 기준으로 열린다.** (Flutty만 쓰려고 비-git 폴더를 여는 경우는 지원하지 않는다 — §6 질문 10.)
- 하위 폴더를 고르면 `git rev-parse --show-toplevel`로 저장소 루트를 찾아 연다 (Branch 동작 그대로). 이때 사용자가 **고른 폴더**는 `selectedDir`로 따로 기억해서 Flutty의 프로젝트 검색 기준으로 쓴다 (§1.4).
- 최근 목록은 하나뿐이며 두 Dock이 공유한다 (`recent_dirs` (공통 키, 접두어 없음 — §1.8); Flutty의 `recent_projects`는 가져오지 않는다).
- Flutty용 환경 점검(flutter·adb·Xcode)은 시작 화면에 올리지 않는다. 실행기 칸 안의 점검 탭에 둔다 (저장소 열기 전에는 의미가 없고, 시작 화면을 단순하게 유지).

### 1.1 전체 골격

저장소가 열린 뒤의 화면. 위의 **공유 영역 두 줄**(바 + 브랜치 줄)은 어느 Dock이 펼쳐져 있든 항상 보인다.

```
┌────────────────────────────────────────────────────────┐
│ ▣ my_app ▾ [📄]                ⟳  📌  ⚙  ⓘ           │ ① 디렉터리 바      높이 44
│ ⎇ feature/login ▾  ↑2 ↓0 ● 변경 3                    │ ② 브랜치 줄        높이 36
├────────────────────────────────────────────────────────┤
│ ▾ ⎇ Branch Dock                                        │ ③ 제목 (눌러서 펼침) 높이 40
│ ┌────────────────────────────────────────────────────┐ │
│ │ (Branch Dock 내용 — 펼쳤을 때 남는 높이 전체)      │ │ ④ 내용
│ └────────────────────────────────────────────────────┘ │
│ ▸ ▶ Flutty Dock    my_app · iPhone 15 · Debug          │ ③ 제목 (접힘)
└────────────────────────────────────────────────────────┘
```

- **① 디렉터리 바**: 왼쪽 = 디렉터리 이름(누르면 최근 목록 · 폴더 열기 ⌘O · 저장소 닫기 · 창 붙이기, 툴팁에 전체 경로). 오른쪽 = 아이콘(새로 고침 · 항상 위 · 설정 · 정보). 폴더 끌어다 놓기는 창 전체가 받고 이 영역이 반응한다 (§1.11).
- **② 브랜치 줄**: 현재 브랜치 칩(누르면 브랜치 빠른 전환), `↑↓`·변경 수 pill. **편집기에서 열기** 단추는 폴더에 하는 동작이라 ① 디렉터리 이름 바로 옆에 둔다 (단계 1 확인 중 위치 변경). 자세한 동작은 §1.9.
- **③ 제목 + ④ 내용 = 아코디언(스택 카드)**: 제목은 항상 보이고 **제목을 누르면 그 내용이 남는 화면 전체로 펼쳐진다. 동시에 하나만 펼친다** (다른 쪽은 제목 한 줄로 접힘). 제목 순서는 고정(Branch 위, Flutty 아래) — 펼쳐도 제목이 자리를 바꾸지 않는다.
- 접힌 제목에도 **한 줄 요약**을 보여 줘서 펼치지 않고도 상태를 안다.
- 지금은 칸이 둘이지만 Rust·Electron runner가 더 붙는다 (§4). 칸은 `DockModule` 목록이고, 실행기 칸은 **그 디렉터리에서 프로젝트가 감지될 때만** 제목이 나타난다. 그림의 두 칸은 "Branch + Flutter 프로젝트" 경우다.

### 1.2 두 가지 상태

**A. Branch Dock 펼침** (기본) — 공유 영역은 그대로, 아래만 바뀐다

```
│ ▣ my_app ▾ [📄]                            ⟳ 📌 ⚙ ⓘ  │
│ ⎇ feature/login ▾  ↑2 ↓0 ● 변경 3          [📄] │  ← 공유
│ ▾ ⎇ Branch Dock                                        │
│   [Fetch] [Pull] [Push ↑2]                              │  Branch 전용 작업 줄
│   💡 커밋 2개가 아직 GitHub에 없습니다     [Push] ✕    │  추천 배너
│   변경 브랜치 태그 원격 릴리스 PR CI 기록              │  섹션 탭
│   ……(목록, 세로 스크롤)……                              │
│   ✓ git push origin feature/login            0.8s      │  명령 바
│ ▸ ▶ Flutty Dock   my_app · iPhone 15 · Debug           │
```

- 원래 Branch Dock의 **상태 헤더 1·2행(브랜치 칩·편집기 단추·상태 pill)은 공유 영역 ②로 올라갔다.** Branch Dock 안에는 3행(Fetch/Pull/Push)부터 남는다. 같은 정보를 두 번 보여 주지 않는다.

**B. Flutty Dock 펼침**

```
│ ▣ my_app ▾ [📄]                            ⟳ 📌 ⚙ ⓘ  │
│ ⎇ feature/login ▾  ↑2 ↓0 ● 변경 3          [📄] │  ← 공유 (같은 내용)
│ ▸ ⎇ Branch Dock   Fetch · Pull · Push                  │
│ ▾ ▶ Flutty Dock                                        │
│   my_app 1.2.0+7 · [iPhone 15 ▾] · Debug|Release  [▶]  │  프로젝트·대상·실행
│   💡 다음 할 일 배너                                   │
│   실행 기기 서명 점검 기록                             │  섹션 탭
│   ……빌드 옵션 · 출력……                                 │
```

### 1.3 접힌 제목의 한 줄 요약

| Dock | 요약 | 강조 |
|---|---|---|
| Branch | 브랜치·↑↓는 공유 줄에 이미 있으므로 **다음 행동 한 줄** (`Push ↑2 가능`, `충돌 2개 해결`, `PR 만들기`, 없으면 `최신`) | 충돌/병합 중이면 danger 점, 원격이 앞서면 warning 점 |
| Flutty | `my_app · iPhone 15 · Debug` (실행 중이면 `● 실행 중 02:13`) | 빌드 실패면 danger 점, 설치 성공이면 success 점 |

### 1.4 디렉터리 하나로 두 Dock을 부리는 규칙

디렉터리는 **하나의 `WorkspaceController`** 가 쥐고, 각 Dock이 거기서 파생 상태를 읽는다. Dock끼리 서로를 직접 알지 못한다.

| 상황 | Branch Dock | Flutty Dock |
|---|---|---|
| 폴더 = git 저장소 + Flutter 프로젝트 | 저장소 열림 | 프로젝트 열림 |
| 폴더 = git 저장소 하위 폴더 | `git rev-parse --show-toplevel`로 루트를 찾아 연다 (지금 Branch Dock 동작 그대로) | 아래 검색 규칙 |
| 폴더가 git 저장소가 아님 | **열리지 않음** — 시작 화면에 실패 안내 + `git init` (§1.0) | (칸 없음) |
| Flutter 프로젝트가 없음 | 정상 | 빈 상태: "이 폴더(와 한 단계 아래 폴더)에 Flutter 프로젝트가 없습니다" |
| 저장소가 아직 안 열림 | 시작 화면(§1.0). 아코디언·공유 영역 없음 | ← |

**Flutty Dock 프로젝트 검색 (요청 사항)**
1. 사용자가 **고른 폴더(`selectedDir`)** 의 **depth 0** 이 Flutter 프로젝트(`pubspec.yaml` + `flutter: sdk: flutter`)면 그것을 쓴다.
2. 아니면 **depth 1** (바로 아래 폴더)까지 찾는다. `.`으로 시작하는 폴더와 `build`·`node_modules`·`target`·`dist`는 건너뛴다. (daylight-workbench의 `FlutterProject.findAll`을 그대로 가져온다.)
3. 하나면 자동 선택, 여럿이면 Flutty Dock 머리의 프로젝트 드롭다운에서 고른다. 선택은 **디렉터리별로 기억**(`flutty.project_choice:<dir>`).
4. depth 2 이상은 찾지 않는다 (느려지고 엉뚱한 프로젝트를 잡는다).
5. 이 규칙은 `ProjectDetector`의 한 구현일 뿐이다 → §4 확장.

### 1.5 창과 도킹 ("docking 시 무리 없이")

두 앱 모두 이미 편집기 옆 세로 창이다. 합쳐도 이 성격을 지킨다.

- 기본 **440×960**, 최소 **380×560**. 최소 높이(560)에서도 `80(공유 두 줄) + 40+40(제목 둘) + 내용 ≥ 400`이 남는다 (560−80−80 = 400) (아래 §1.7 검증 항목).
- **크기·위치 기억** 필수 (`window-placement.md`의 `placeWindowAtStartup` 규칙, 모니터가 사라진 경우 기본 위치로).
- **화면 가장자리에 붙이기**(오른쪽/왼쪽), **항상 위**(핀). 두 앱에 있던 `dockWindow`/`DockSide`를 하나로 합친다.
- 도킹/해제, 모니터 이동, 창 크기 변경 중에 **펼침 상태·스크롤·입력 중 값이 사라지지 않는다**: 접힌 Dock도 위젯을 살려 둔다(`Offstage` + `TickerMode`로 애니메이션만 끔). 빌드 중인 Flutty를 접어도 프로세스와 출력은 계속된다.
- 폭 대응:

  | 모드 | 배치 |
  |---|---|
  | 도킹 모드 (확장 패널 없음) | 위 골격 그대로 (아코디언). 폭은 380 이상 |
  | 확장 모드 (§1.13) | 도크 열(아코디언)은 그대로 두고 그 왼쪽에 확장 패널이 붙는다. **폭이 아니라 패널 켜짐 여부가 배치를 정한다** — 폭에 따른 분기는 없다 |

- 패널 단축키(단계 16, 표는 `lib/ui/shell/shell_shortcuts.dart` 한 곳): `⌘/Ctrl+Shift+E` 탐색기, `⌘/Ctrl+Shift+D` 에디터, `Ctrl+\``(macOS 도 ⌘ 아님 — ⌘\`는 앱 창 전환) 터미널, `⌘/Ctrl+Shift+O` 빠른 열기. 에디터·터미널은 켜짐↔꺼짐, 켜져 있지만 가려져 있으면 앞으로 가져온다. 터미널은 위 키(와 `⌘/Ctrl+,`)만 셸로 보내지 않고 앱에 돌려주고 `Ctrl+O/R` 같은 셸 줄 편집 키는 그대로 보낸다. 패널 메뉴 항목에 단축키 글자가 붙는다. 충돌 검사: `test/shell_shortcuts_test.dart`.
- 키보드: `⌘/Ctrl+Alt+1` Branch, `+2` Flutty 펼침. (Branch Dock의 `⌘1–7` 섹션 탭 단축키는 **펼쳐진 Dock 안에서만** 동작하고, Dock 전환과 겹치지 않게 Alt를 붙인다.) `⌘O` 폴더 열기, `⌘R` 새로 고침은 공통.

### 1.6 앱 바 아이콘 (규약 + 두 앱의 합집합)

| 아이콘 | 출처 | 비고 |
|---|---|---|
| 새로 고침 | Branch | 펼쳐진 Dock을 새로 읽음 |
| 항상 위(핀) | Branch | |
| ~~시크릿 키 `🔑`~~ | Flutty | **앱 바에서 뺀다 (확정).** macOS 릴리스 서명용 시크릿 화면(`SecretsScreen`)은 설정 창의 구역으로 옮긴다 (§1.8). Windows에서는 구역을 숨김 (지금과 같음) |
| 설정 · 정보 | 규약 ([settings.md](../application-release-templates/conventions/settings.md)) | 앱 바 오른쪽 끝은 `… 설정 \| 정보`. 테마·언어 팝업 버튼은 **두지 않고** 설정 창으로 옮긴다 (§1.8) |

### 1.7 화면 검증 기준 (구현 단계의 완료 조건)

폭 380 / 440 / 840, 높이 560 / 960, 라이트·다크, 한국어·영어, 시스템 글자 크기 큰 설정에서 스크린샷으로 확인.

- 제목 두 줄이 어떤 크기에서도 가려지지 않는다.
- 펼침/접힘 애니메이션 중 오버플로 줄무늬가 없다.
- 폴더 없음 / git 아님 / Flutter 프로젝트 없음 / 둘 다 있음 — 4가지 상태가 모두 설명 있는 빈 상태로 보인다.
- 빌드 실행 중 Branch로 전환 → 돌아와도 출력이 이어져 있다.
- 폴더를 끌어다 놓으면 §1.11 규칙대로 열린다 (시작 화면·아코디언 모두, 하위 폴더·비-git·작업 중 케이스 포함).
- 시작 화면 → 저장소 열기 → 아코디언 진입, 저장소 닫기 → 시작 화면 복귀가 막힘 없이 된다 (비-git 폴더 실패 안내 포함).
- 브랜치 전환(앱 안/밖) 시 공유 영역·두 Dock이 함께 갱신된다 (§1.10 테스트).
- 380px에서 긴 브랜치 이름이어도 편집기 단추가 가려지지 않는다.

### 1.8 설정 창 (settings.md 2026-10-29 개정 반영)

Branch/Flutty의 설정 창은 개정 전 규약(고정 폭 420, 팔레트 키 `accent_palette`, 글자 크기 없음, `settings-screen.md` 참조)이라 **그대로 복사하지 않는다**. 개정된 [settings.md](../application-release-templates/conventions/settings.md)를 기준으로 새로 맞추고, 구현은 daylight-commander(`lib/settings/settings_dialog.dart`)와 daylight-workbench를 참고한다. (템플릿 `common/lib/settings/`에는 아직 `settings_dialog.dart`가 없다 — 규약 문서가 템플릿보다 앞서 있음.)

| 항목 | 규약 | 이 앱에서 |
|---|---|---|
| 저장 키 | `theme_mode`, `theme_palette`, `text_scale`(0.9/1.0/1.15), `app_locale` | 공통 키는 접두어 없이 위 이름 그대로 (§3.2의 `app.*`는 **쓰지 않는다** — 규약 키와 달라진다). Dock 설정만 `branch.*`/`flutty.*`. 옛 `accent_palette`는 가져올 필요 없음(새 앱) |
| 색 구성 | `saturn/teal/amber/rose/slate/highContrast` 6종, 고대비는 별도 `ColorScheme` | Branch의 `AccentPalette`를 규약의 `ColorPalette`로 교체 |
| 글자 크기 | 설정 창 `SegmentedButton`, `MediaQuery.textScaler`로 적용 | 새로 추가. §1.7 "시스템 글자 크기 큰 설정" 검증과 함께 확인 |
| 앱 바 | 설정 아이콘이 정보 바로 왼쪽. Icons8 설정 아이콘이 없으면 **Material 아이콘** (`settings_outlined`, 앱 바가 둥근 계열이면 `settings_rounded`), 한 앱에서 Icons8/Material 혼용 금지 | Branch/Flutty 모두 Material 계열 → `Icons.settings_outlined` (앱 바 나머지 아이콘 계열과 맞춤) |
| **도킹한 좁은 창** | 설정 창은 앱 창보다 커질 수 없다. `insetPadding: all(16)`, 너비 `min(640, 화면너비−32)`, 높이 `clamp(160,380)` 안에서 `화면높이−32−150`, 본문 스크롤. **너비 560 미만이면 구역 목록을 위쪽 `ChoiceChip` 한 줄(가로 스크롤)** 로, 이상이면 왼쪽 160 목록 | 이 앱의 기본 폭이 380–440이므로 **항상 좁은 배치가 기본**이다. 창 크기만 보고 배치를 고른다 |
| 구역 | 화면(테마·색 구성·글자 크기) / 언어 + 앱 고유 구역 | 고유 구역: **Branch**(도구 경로 git·gh, 알림, 편집기), **Flutty**(도구 경로 flutter·adb·Xcode, 환경 점검 진입점, **릴리스 시크릿 — macOS만**; 키·비밀번호는 저장하지 않고 경로만 참조하는 기존 규칙 유지). 앱 고유 키는 `<기능>_<이름>` ([localization.md](../application-release-templates/conventions/localization.md) §5) |
| ARB 키 | `settingsTooltip/Title/Section*/Brightness/Palette/Palette{…}/FontSize/Language` | 두 앱의 `settingsMode`, `settingsSectionAppearance` 등 옛 키 이름은 규약 이름으로 바꿔서 합친다 (§3.2 접두어 규칙의 **예외** — 공통 설정 문구는 접두어 없음) |
| 선택 표시 | 구역 선택은 배경 채움이 아니라 왼쪽 3px 굵은 선(넓은 배치) / `ChoiceChip(showCheckmark:false)`(좁은 배치) | |
| 테스트 | 480×480에서 오버플로 없음 + 칩 전환, 각 선택지 저장, `theme_palette` 읽기, 고대비 `surface` 순흑/순백 | 단계 1(셸)에 설정 창 포함 — 도킹 크기 테스트가 §1.7 완료 조건에 추가됨 |

**색을 테마에서 읽는 규칙** (가장 중요): 위젯이 `AppColors.primary/surface/stroke` 상수를 직접 쓰면 색 구성을 바꿔도 그 부분만 남는다. 두 원본의 `lib/ui`에 `AppColors.*` 직접 사용이 17곳 있어(확인함, 양이 많지 않음) **이식 단계(3·4)에서 `Theme.of(context).colorScheme` / `dividerColor`로 바꾸는 작업을 포함**하고, workbench의 `test/theme_rules_test.dart` 같은 검사를 가져와 위젯의 `Colors.*`·`AppColors.*` 직접 사용을 막는다. 또 `ThemeData.dividerColor = stroke`를 채워야 드래그 분할선이 기본색으로 남지 않는다 (아코디언 경계선, 디렉터리 바 구분선에 해당).

### 1.9 공유 영역: 디렉터리 · 현재 브랜치 · 편집기에서 열기

세 가지를 **모든 Dock 위에 고정**한다. 상태의 주인은 `WorkspaceController` 하나이고, 이 영역과 각 Dock은 읽기만 한다.

| 요소 | 보여 주는 것 | 누르면 |
|---|---|---|
| **디렉터리** (①) | 저장소(또는 worktree) 폴더 이름. `selectedDir`이 루트와 다르면 `my_app / app` 식으로 하위 경로 표시. 툴팁 = 전체 경로 | 메뉴: 최근 저장소 · 다른 폴더 열기 ⌘O · 이 worktree의 형제 worktree 전환 · 저장소 닫기(→ 시작 화면) |
| **현재 브랜치** (②) | 브랜치 칩 `⎇ feature/login`, 추적 브랜치 없으면 "원격에 없음" pill. 분리된 HEAD면 `태그 v1.2.0에 있음`(warning), 병합/rebase 중이면 `병합 중 · 충돌 2`(danger). 뒤에 `↑2 ↓0 ● 변경 3` (Branch 상태 헤더의 `StatusPill` 그대로) | 칩: 브랜치 빠른 전환 목록 (Branch Dock의 기존 전환 흐름 — 변경이 있으면 묻고, 충돌 시 안내 — 을 **Dock이 접혀 있어도 그대로** 쓴다. 시트는 앱 전체 위에 뜬다) |
| **편집기에서 열기** (①, 디렉터리 이름 바로 옆) | `📄` 아이콘 단추. 툴팁에 **실제로 실행될 명령** | 설정한 편집기(없으면 VS Code)로 폴더를 연다. 찾지 못하면 설치 링크만 보여 준다 (Branch 동작 그대로) |

**편집기에서 열기 세부**
- 여는 폴더: 현재 브랜치가 체크아웃된 폴더 = **저장소 루트(worktree면 그 worktree)**. `selectedDir`이 루트와 다르면 단추 옆 ▾ 메뉴에 "선택한 폴더만 열기 (`app/`)"를 추가하고, 감지된 프로젝트가 있으면 "프로젝트 폴더 열기 (`gui/`)"도 준다.
- 편집기 명령은 Branch의 `editorCommand` 설정(기본 VS Code)을 쓰고, 설정 창의 **편집기 구역**(§1.8)으로 옮긴다 (지금은 시트로 따로 연다).
- 모든 칸이 같은 단추를 쓴다 — Flutty의 "VS Code에서 열기"(`openInVsCode`)는 **없앤다**(중복).

**좁은 폭(380)**: 브랜치 이름이 길면 칩이 줄어들고(말줄임) 편집기 단추는 자리를 지킨다. 상태 pill은 폭이 모자라면 `↑2 ↓0 ●3`로 줄이고, 그래도 모자라면 칩 아래 둘째 줄로 내려가는 대신 **pill을 숨기고 칩 툴팁에 표시**한다 (줄 높이를 32로 고정).

### 1.10 브랜치가 바뀌면 앱 전체가 따라간다

**원칙: 브랜치(HEAD) 변화는 `WorkspaceController`가 한 번만 감지하고, 모든 Dock과 공유 영역이 같은 신호를 받는다.** 어느 Dock이 펼쳐져 있든, 접혀 있든, 앱 밖(터미널·VS Code)에서 바꿨든 같다.

**감지** — Branch의 `RepoController`가 이미 `.git` 변화를 감시한다(파일 감시 + 400ms 디바운스, 감시가 안 되면 5초 폴링). 이것을 **Workspace가 소유**하고(Branch Dock 칸이 아니라), 거기서 `GitState`를 만든다.

```dart
class GitState {                // 불변 값. 같으면 알리지 않는다.
  final String root;            // 저장소(worktree) 루트
  final String? branch;         // 분리된 HEAD면 null
  final String? sha;            // HEAD 커밋
  final RepoOperation operation;// none / merging / rebasing …
  final bool dirty; final int ahead, behind;
}
enum HeadChangeKind { branch, commit, operation }   // 이름이 바뀜 / 같은 브랜치에서 커밋이 움직임 / 병합 시작·끝
class HeadChange { final GitState from, to; HeadChangeKind kind; }
```

- `Workspace.gitState`(ValueListenable)와 `Workspace.headChanges`(Stream)를 둔다. `DockModule.onHeadChange(HeadChange)`가 칸마다 한 번 불린다.
- `index.lock` 이 있는 동안(checkout 진행 중)은 알리지 않고 **안정된 뒤 한 번만** 알린다 — 전환 중 파일이 반쯤 바뀐 상태로 Flutty가 pubspec을 읽는 일을 막는다.
- 창이 다시 활성화될 때도 한 번 확인한다 (감시가 놓친 경우의 안전망).

**누가 무엇을 하나**

| 대상 | 브랜치 전환 (`kind=branch`) | 커밋 이동 (`commit`: pull·commit·reset) | 병합/rebase 시작·끝 (`operation`) |
|---|---|---|---|
| 공유 영역 ② | 칩·pill 즉시 갱신 | `↑↓`·변경 수 갱신 | pill이 danger로 바뀜 |
| 앱 바 / 창 제목 | 제목 `Daylight Taskbench — my_app (feature/login)` | — | — |
| **Branch Dock** | 모든 탭(변경·브랜치·태그·PR·CI·기록)을 새로 읽고, 선택·검색 필터는 초기화, 브랜치별 PR/CI 조회 | 기록·변경 갱신 | 충돌 배너·다음 행동 갱신 |
| **Flutty Dock** | ① 프로젝트 다시 감지(브랜치에 따라 `pubspec`·하위 프로젝트가 생기거나 사라질 수 있음; 선택한 프로젝트가 사라지면 §1.4 규칙으로 재선택) ② 이름·버전 다시 읽기 ③ 점검(분석)·서명 결과를 **오래된 값으로 표시**하고 다시 확인 유도 ④ 열려 있던 빌드 옵션은 프로젝트별 저장값 유지 | pubspec 버전만 다시 읽기 | 병합 중이면 "충돌 중에는 빌드 결과가 신뢰할 수 없습니다" 배너 |
| **실행기 칸 일반** (Rust·Electron, §4) | 위 Flutty와 같은 `onHeadChange` 규약 — 감지 재실행, 오래된 값 표시 | | |
| 접힌 제목 요약 | 즉시 갱신 | | 점 색 갱신 |

**실행 중인 작업은 건드리지 않는다**: Flutty에서 빌드·실행 중에 브랜치가 바뀌면 프로세스를 멈추지 않고, 칸 안에 "실행 중 브랜치가 `main` → `feature/login`으로 바뀌었습니다. 이 실행은 전환 전 코드 기준일 수 있습니다" 배너를 붙인다 (닫을 수 있음). 접혀 있으면 제목 점(warning)으로 알린다.

**Taskbench가 직접 바꾼 경우와 밖에서 바꾼 경우를 구분하지 않는다** — 둘 다 같은 경로(감지 → `HeadChange`)로 처리해 한 가지 동작만 테스트한다. (Branch Dock의 전환 흐름은 끝난 뒤 `refresh()`만 부르고, 나머지는 감지에 맡긴다.)

**worktree 전환은 브랜치 변경이 아니라 디렉터리 변경이다**: 루트가 바뀌므로 `Workspace.rootChanged`로 처리하고(Dock 상태 전부 재설정, `selectedDir`은 새 worktree의 같은 하위 경로가 있으면 유지), 공유 영역에 worktree 표식을 붙인다.

**테스트 (단계 1에서 가짜 `GitState`로 먼저, 단계 3에서 실제 git으로)**
- `GitState` 변화 → 공유 영역·두 Dock 요약이 한 프레임 안에 같이 바뀐다.
- 접힌 Dock도 `onHeadChange`를 받는다.
- 임시 저장소에서 `git checkout -b`/`git switch` 후 1초 안에 `HeadChange(kind=branch)` 한 번만 발생 (디바운스 중복 없음).
- 분리된 HEAD, 병합 충돌, `index.lock` 존재 중에는 알림이 늦춰진다.
- 실행 중인 가짜 프로세스가 있을 때 전환해도 중지되지 않고 배너만 뜬다.

### 1.11 폴더 끌어다 놓기 (공유 영역)

**가능하다.** 두 원본이 이미 `desktop_drop`의 `DropTarget`으로 같은 일을 하고(Branch `main_screen.dart:405`, Flutty `home_screen.dart:131`), 앱의 macOS 샌드박스가 꺼져 있어(`app-sandbox=false`) 끌어놓은 경로를 바로 쓸 수 있다. 새로 만드는 것은 "한 곳에서 받고, 공유 영역이 반응하게" 하는 배선뿐이다. 두 앱의 드롭은 모두 *폴더 열기 용도 하나*라서 합쳐도 충돌하지 않는다 (확인함).

**받는 곳 — `DropTarget`은 앱 전체에 하나**

| 선택지 | 장점 | 단점 |
|---|---|---|
| A. 공유 영역(76px)만 | 의도가 분명 | 좁아서 맞추기 어렵고, 시작 화면과 규칙이 달라짐 |
| **B. 창 전체가 받고, 반응은 공유 영역에 표시 (제안)** | 어디에 놓아도 된다. 시작 화면·아코디언 모두 같은 규칙. 두 원본이 이미 이 방식 | Dock 안에서 파일 놓기가 필요한 기능이 생기면 위임 규칙이 필요 |

→ **B로 한다.** 끄는 동안 공유 영역(①②)에 점선 테두리와 "여기에 놓아 저장소 열기" 안내를 덮고, 아래 Dock 영역은 살짝 어둡게 한다. 시작 화면은 지금처럼 자기 안내(`dragging`)를 쓴다. Dock이 자기 `DropTarget`을 두는 것은 금지하고, 나중에 필요하면 루트가 위치를 보고 위임한다(지금은 만들지 않는다).

**놓았을 때 규칙** — 로직은 `WorkspaceController.openDropped(List<String> paths)` 한 곳에 둔다 (위젯 없이 테스트 가능).

| 놓은 것 | 동작 |
|---|---|
| 폴더 하나 | 연다 (§1.0과 같은 열기: 저장소 루트를 찾고, 고른 폴더는 `selectedDir`로 기억) |
| 현재 저장소의 **하위 폴더** | 저장소는 그대로 두고 `selectedDir`만 바꾼다 → Flutty 프로젝트 검색만 다시 돈다. 모든 Dock 상태 유지 |
| 현재 저장소의 **다른 worktree** | 디렉터리 변경으로 처리 (§1.10 worktree 규칙) |
| 폴더 여럿 | 첫 번째만 열고 스낵바 "폴더 여러 개 중 첫 번째만 열었습니다" |
| 파일만 | 열지 않는다. 스낵바 "폴더를 놓아 주세요" (Branch 현재 동작과 같음) |
| git 저장소가 아닌 폴더 | **지금 열려 있는 저장소를 닫지 않는다.** 시작 화면이면 실패 안내, 열려 있으면 대화상자 "git 저장소가 아닙니다 — [git init] [취소]" |
| 같은 폴더 | 아무것도 하지 않고 새로 읽기만 |
| 심볼릭 링크·바로가기 | 링크를 풀어 실제 경로로 연다 (Branch가 이미 함) |

**작업 중일 때**: Flutty에서 빌드·실행 중이거나 Branch에서 병합/rebase 중인데 *다른 저장소*를 놓으면, 열기 전에 확인한다: "실행 중인 작업이 있습니다. [중지하고 열기] [취소]". (같은 저장소 안의 하위 폴더 전환은 확인 없이 된다.)

**알려진 한계**
- Windows: 이 앱을 **관리자 권한으로 실행하면** 일반 탐색기에서 끌어놓기가 막힌다(UIPI, OS 규칙). 폴더 열기(⌘O)는 항상 된다.
- Linux는 대상이 아니다(§2).
- 놓기 동작은 위젯 테스트로 흉내 낼 수 없으므로 `openDropped` 단위 테스트 + 실제 macOS·Windows 수동 확인으로 나눠 검증한다.

### 1.12 장식 스타일 `TaskbenchStyle` — 확정: **은은하게**

[allwinner-phoenix-flutter](../allwinner-phoenix-flutter/gui/lib/widgets.dart)처럼 글래스 카드·그라디언트·글로우로 화사하게 꾸밀 수 있다. **가능하고, 이 앱 구조에 잘 맞는다** (아코디언 카드 = 글래스 카드). 선례는 두 가지다: Allwinner(`GlassCard`, `AuroraBackground`, 맥박 점)와 daylight-broom(`BroomStyle` — 규약 테마를 대체하지 않고 `ThemeExtension`으로 얹음). 후자 방식을 따른다.

**무엇을 꾸미나** (넷 모두 작은 위젯 하나씩)

| 요소 | 모양 | 어디에 |
|---|---|---|
| **오로라 배경** | 창 전체에 대각선 그라디언트 + 상태색 번짐. 상태에 따라 천천히(600ms) 색이 바뀐다: 평상시 주색(파랑) · Flutty 빌드·실행 중 보라 · 실패/충돌 빨강 · 성공 직후 잠깐 초록 | 창 배경 (공유 영역·Dock 뒤) |
| **글래스 카드 아코디언** | 칸마다 반투명 카드(위→아래 옅은 그라디언트 + 헤어라인 테두리). **펼쳐진 칸은 주색 워시 + 은은한 글로우**, 접힌 칸은 평평하게. 펼침/접힘은 260ms 이징 | ③제목 + ④내용 |
| **앱 마크** | 앱 아이콘과 같은 그라디언트 판 위의 글리프(Allwinner `AppMark`) | 디렉터리 바 왼쪽, 시작 화면 중앙 |
| **맥박 점** | 실행 중인 일(빌드·fetch·pull)이 있으면 제목 오른쪽 점이 1.4초 주기로 깜빡임, 상태별 색(성공 초록·경고 노랑·실패 빨강) | 접힌 제목 요약 옆, 공유 영역 pill |

시작 화면은 같은 배경 위에 큰 마크 + 글래스 카드(최근 저장소 목록)로 꾸민다.

**지켜야 할 규칙 (결정 필요한 것 아님, 기본 적용)**
1. **규약 테마를 대체하지 않는다.** `lib/theme/taskbench_style.dart`에 `ThemeExtension<TaskbenchStyle>`로 두고 라이트/다크 한 쌍(`theming.md` §2). 화면 코드는 `Theme.of(context).extension<TaskbenchStyle>()`와 `colorScheme`만 읽고 `Color(0x…)`·`Colors.*`를 직접 쓰지 않는다 (§1.8 규칙 + 규칙 테스트). Allwinner는 자기 `theme.dart`를 따로 쓰는 예외였지만 이 앱은 규약 테마 위에 얹는다.
2. **색 구성(§1.8)을 따른다.** 글로우·워시·오로라는 선택한 `colorScheme.primary`에서 파생하므로 `teal/amber/rose/slate`가 그대로 반영된다. 보라/빨강 같은 *상태색*은 고정 의미 색(성공·경고·위험)이다.
3. **고대비(`highContrast`)에서는 장식을 끈다**: 그라디언트·글로우·반투명 없이 순흑/순백 + 굵은 테두리. 글자 대비가 최우선.
4. **움직임 줄이기**: OS의 "동작 줄이기"(`MediaQuery.disableAnimations`)가 켜져 있으면 배경 전환·맥박·펼침 이징을 모두 즉시 전환으로 바꾼다.
5. **공간을 먹지 않는다.** 장식은 패딩·그림자·배경만 쓰고 레이아웃 높이를 늘리지 않는다 — §1.5의 최소 높이 계산(76 + 40×칸)과 380px 폭 기준이 그대로 유지된다. 카드 모서리는 12, 바깥 여백은 8을 넘기지 않는다.
6. **성능**: 그라디언트·BoxShadow만 쓰고 `BackdropFilter`(실제 블러)는 쓰지 않는다 (접힌 Dock이 살아 있고 빌드 로그가 빠르게 갱신되므로). 배경 애니메이션은 상태가 바뀔 때만, 상시 루프는 맥박 점뿐이고 접히면 멈춘다.
7. **가독성**: 로그·diff·명령 출력 영역은 카드 위에 **불투명한 안쪽 판**(`insetFill`)을 깔아 글자 배경을 장식과 분리한다 (Allwinner 로그 상자와 같음).

**파일 / 단계**: `lib/theme/taskbench_style.dart`(토큰) + `lib/ui/style/`(`GlassCard`, `AuroraBackground`, `AppMark`, `PulseDot`). **단계 1(셸)에 포함** — 화면 확정 지점에서 장식까지 같이 눈으로 보고 승인한다 (강도는 `TaskbenchStyle.intensity` 한 값으로 조절되게 만들어 두어, 보고 나서 더 화사하게 바꾸기 쉽다). 두 Dock 이식(3·4단계) 때 기존 위젯의 `Card`/`Container`를 `GlassCard`로 바꾸는 작업은 *바깥 껍질과 섹션 카드까지만* 하고, 목록 행·표 등 안쪽은 건드리지 않는다 (이식 기능 회귀 위험을 줄이기 위해).

**테스트**: ① 라이트·다크·6개 색 구성에서 골든 스크린샷(최소 380×560, 기본 440×960) ② 고대비에서 장식 위젯이 그라디언트를 쓰지 않음 ③ `disableAnimations`에서 `AnimationController`가 돌지 않음 ④ 규칙 테스트: 장식 코드가 `lib/theme/`·`lib/ui/style/` 밖에서 색 리터럴을 쓰지 않음.

**결정 (확정)**
- **A. 강도: 은은하게 ✅** — 배경 워시는 약하게(주색 알파 ≈ 0.08~0.10), 글로우는 **펼친 칸 하나에만**(접힌 칸은 평평), 앱 마크·맥박 점은 작게. 보라·핑크 그라디언트는 앱 마크 판에만 쓰고 화면 배경에는 쓰지 않는다.
- **B. 상태색 배경**: 기본 켬(제안 그대로 적용), 설정 → 화면 구역에 끄는 스위치를 둔다 — 별도 이의가 없으면 이대로 진행.

### 1.13 확장 모드 — 탐색기 · 에디터/터미널 (daylight-workbench 흡수, 2026-11-01)

기본 화면은 지금까지의 **도킹 모드**다. 여기에 **확장 패널**을 왼쪽에 붙여 workbench와 같은 작업대로 쓴다. 창은 하나, 상태만 둘이다.

```
[도킹 모드 440×960]            [확장 모드 — 도킹 창 모양은 쓰지 않는다]
┌──────────┐                  ┌────────┬────────────────┬──────────┐
│ 도크 열   │       ⇄         │탐색기  │[에디터|터미널]  │ 도크 열   │
│(아코디언) │                  │        │                │(아코디언) │
└──────────┘                  └────────┴────────────────┴──────────┘
```

- **도크 열**은 두 모드에서 같다: Git & GitHub와 Runner 칸만 아코디언이다 (§1.1~1.3 그대로, 동시에 하나만 펼침, 폭과 무관). 탐색기·에디터·터미널은 도크 칸이 아니다.
- **가운데 영역은 에디터 / 터미널 전환형**이다. 둘이 동시에 보이지는 않는다. 전환해도 열린 파일과 터미널 세션은 유지한다 (§1.5의 "접어도 위젯을 살려 둔다" 규칙과 같다).
- **켜짐 조합과 보이는 것**

  | 탐색기 | 에디터 | 터미널 | 보이는 것 | 모드 |
  |---|---|---|---|---|
  | 꺼짐 | 꺼짐 | 꺼짐 | 도크 열 | **도킹** |
  | 켜짐 | 꺼짐 | 꺼짐 | 탐색기 + 도크 열 | 확장 |
  | 켜짐 | 켜짐 | 켜짐 | 탐색기 + [에디터\|터미널] + 도크 열 | 확장 |
  | 켜짐 | 켜짐 | 꺼짐 | 탐색기 + 에디터 + 도크 열 | 확장 |
  | 켜짐 | 꺼짐 | 켜짐 | 탐색기 + 터미널 + 도크 열 | 확장 |
  | 꺼짐 | 꺼짐 | 켜짐 | 터미널 + 도크 열 | 확장 (탐색기 없이 터미널만 — 허용) |

  에디터만 끄면 가운데는 터미널만, 둘 다 끄면 가운데가 없어진다.
- **도킹 모드는 파생 상태다.** 탐색기·에디터·터미널 중 하나라도 켜면 도킹 모드가 풀리고 도킹 창 모양(440×960)으로의 전환은 비활성화된다 (툴팁: "패널을 모두 닫으면 도킹 모드로 돌아갑니다"). 모두 끄면 마지막 도킹 크기·위치로 돌아간다. "도킹 모드" 설정값은 따로 두지 않는다 — 패널 켜짐 상태에서 계산한다.
- **창 크기 모드는 셋이다**: 도킹(440) / **탐색기만**(탐색기 240 + 도크 열 440 ≈ 680, 가운데 빈칸 없음) / 가운데가 있는 전체(1240). 사용자 확정 2026-11-01("탐색기만 열어 둔 상태의 빈칸은 의도가 아니다"). 탐색기만 켠 창을 넓히면 탐색기가 남는 폭을 쓴다.
- **모드가 바뀌어도 창 높이는 그대로, 너비만 그 모드의 것으로 바뀐다** (모드별 너비를 기억). 도크 열이 있는 오른쪽 가장자리를 고정한 채 왼쪽으로 늘어나고 줄어든다 (창이 화면 밖으로 나가지 않게).
- **에디터는 선택 기능**이다. 설정 "내장 에디터 사용"을 끄면 에디터 패널이 없고, 파일 열기·빌드 오류 위치 누르기는 외부 VS Code로 열린다 (켜져 있으면 내장 에디터가 그 줄로 이동). 빌드는 하나이며 실행 중에 정한다. 에디터 코드는 `lib/` 안의 독립 모듈로 두고 도크·Git 코드가 에디터를 참조하지 않게 한다 (workbench의 `branchdock`·`problems`·`diff`·`run`·`install` 등은 에디터를 참조하지 않고 에디터가 `problems`·`diff`를 쓰는 한 방향이다. 다만 workbench `ui/`의 `diff_view`·`file_tree` 등 일부 화면이 에디터 쪽 심볼을 참조하므로, 옮길 때 에디터용과 공용으로 나누는 작업이 필요하다 — 단계 착수 전에 확인).
- **저장소가 기준**이다 (§1.0·§1.4 그대로). 폴더를 열 때의 분기:

  | 상황 | 동작 |
  |---|---|
  | 폴더 자체가 저장소 루트 | 그대로 연다 |
  | 저장소 안의 하위 폴더 | 저장소 **루트로 연다** (§1.0). 고른 폴더는 `selectedDir`로 기억하고 탐색기가 그 위치를 펼쳐 보여 준다 |
  | 저장소가 아니고 **하위에 저장소들이 있음** | `git init`을 권하지 않는다. **하위 저장소 목록을 보여 주고 고르게 한다** |
  | 저장소도 아니고 하위에도 저장소가 없음 | "Git 저장소로 만들까요?" (`git init`, 기본 브랜치 `main`, 실행 내용을 미리 보여 줌, `pubspec.yaml`이 있으면 Flutter용 `.gitignore` 제안, 첫 커밋은 자동으로 만들지 않음) |
  | 홈·루트·바탕화면·문서 등 위험한 위치 | `git init`을 제안하지 않는다 (정확한 목록은 구현 단계에서 정한다) |

  저장소 루트는 Git 칸·탐색기·터미널의 기준이고, Runner 칸의 기준은 §1.4의 프로젝트 검색 규칙(`selectedDir`의 depth 0·1)이다 — 모노레포에서 앱 폴더가 루트와 달라도 Runner가 깨지지 않는다.
- **키보드**: 패널 켜기/끄기와 에디터↔터미널 전환 단축키는 구현 단계에서 §1.5 단축키 표에 추가하고 충돌 검사 테스트를 통과시킨다.

---

## 2. 정체성 (identity.md)

| 항목 | 값 |
|---|---|
| 표시 이름 | `Daylight Taskbench` |
| 파일 이름 | `DaylightTaskbench` |
| 패키지 | `daylight_taskbench` |
| 식별자 | `art.zoomon.daylighttaskbench` (macOS Debug는 `.dev`) |
| 저장소 | `daylight-taskbench` (이름에 Flutter를 넣지 않는다 — workbench와 같은 규칙) |
| 게시자 / 저작권자 | `Jongyun Ahn`, `Copyright © 2026 Jongyun Ahn` |
| 규약 버전 | `conventions-v1` |
| 시작 버전 | `0.1.0+1` |

- 이름에 "Flutter"·"GitHub"·"Git"을 넣지 않는다 (상표). Flutter 전용이라는 설명은 부제·소개 문구("Flutter 앱을 GitHub에서 만들고 굴리는 작업대")에서만 쓴다. 옛 작업 이름 Fig는 코드·식별자 어디에도 남기지 않는다.
- 두 원본의 식별자(`art.zoomon.branchdock`, `art.zoomon.fluttydock`)는 **쓰지 않는다**. 새 앱이라 설정은 이어지지 않는다 (원하면 §6의 가져오기 질문).
- 플랫폼은 **macOS + Windows** (Flutty가 둘만 지원, workbench와 동일). Branch의 `linux/`는 가져오지 않는다 (§6 질문).
- 시작은 `flutter-app-bootstrap` 스킬로 골격(식별자, 버전, 릴리스 워크플로, 설치 프로그램, 정보 창, 아이콘, 라이선스, l10n, 테마, 글꼴, README, CLAUDE.md)을 **기능 코드 이전에** 만든다.

---

## 3. 코드 합치기 방식

### 3.1 디렉터리 구조

```
lib/
  main.dart · app_identity.dart
  app/            taskbench_shell.dart(아코디언 셸) · dock_title.dart · workspace_bar.dart
  workspace/      workspace_controller.dart(디렉터리·최근·선택) · project_detector.dart
  docks/
    dock_module.dart      ← Dock 인터페이스·레지스트리 (§4)
    branch/               ← branch-dock-flutter/lib 의 git/ github/ repo/ release/ ui/ 를 옮김
    flutty/               ← flutty-dock-flutter/lib 의 install/ doctor/ devices/ flutter/ secrets/ ui/ 를 옮김
    (rust/ electron/      ← 확장 단계 7·8, §4)
  core/           command_runner · command_log · vscode · tool_paths (공통, §3.2)
  about/ settings/ theme/ update/ window/ l10n/   (공통)
```

### 3.2 공통으로 합치는 것 / 따로 두는 것

| 영역 | 처리 | 이유 |
|---|---|---|
| `about/`, `window/focus_tint` | 한 벌 (두 앱이 사실상 동일) | diff 5줄 이내 |
| `settings/app_settings`, 설정 창 | **한 벌로 새로 맞춤** — 두 앱의 설정은 옛 규약(고정 420 폭, `accent_palette` 키, 글자 크기 없음)이라 그대로 못 쓴다. §1.8 | 최신 settings.md (2026-10-29) |
| `theme/app_theme` | 한 벌 | 5줄 차이 |
| `core/command_log`, `core/vscode` | 한 벌 | 4~12줄 차이 |
| **`core/command_runner`** | **합집합으로 새로 정리** (296줄 차이) | 위험 1순위. 두 쪽 테스트를 모두 통과해야 함 |
| `update/update_service` | 한 벌 (107줄 차이는 조사 후 합침) | 같은 `app_updater` 사용 |
| 도구 경로 UI (`tool_path_sheet` / `tool_paths_dialog`) | 한 벌로 통합 (git·gh·flutter·adb·xcode 경로) | |
| `core/git_client`, `core/gh_client` (Flutty) vs `git/`, `github/` (Branch) | **우선 각자 유지**, 중복은 합친 뒤 3단계에서 정리 | 기능 보존이 우선 |
| 설정 저장 | 하나의 `SharedPreferences`, Dock 고유 키만 접두어 `branch.*` / `flutty.*` (공통 설정 키는 규약 이름 그대로, §1.8) | `RepoPrefs`, `InstallController` 저장 키 충돌 방지 |
| l10n ARB | 키 접두어 `bd*` / `fd*` / 공통은 접두어 없음 (972 + 496 키) | 키 충돌 방지, 테스트로 중복 검사 |
| 폰트·아이콘 | 한 벌 (SeoulNamsan 400/700/800) | |

### 3.3 줄이는 것 (중복 제거)

- Flutty의 **Git 탭**(`git_section`: 상태·fetch·pull)은 Branch Dock이 더 완전하게 하므로 **뺀다**. 그러면 Flutty의 "git은 fetch/pull만" 규칙은 Taskbench에선 Branch Dock 쪽 규칙이 이어받는다. (workbench에서 같은 결정을 이미 했다.)
- Flutty 탭: `실행 · 기기 · 서명 · 점검 · 기록`(5개). Branch 탭: `변경 · 브랜치 · 태그 · 원격 · 릴리스 · PR · CI · 기록`.
- 두 앱에 각각 있던 "다음 할 일" 배너는 **각 Dock 안에** 둔다 (서로 다른 맥락).

### 3.4 Dock 사이의 연결점 — 최소한만

- 디렉터리 변경 (Workspace → 두 Dock).
- Branch Dock에서 worktree를 열면 **디렉터리가 그 worktree로 바뀐다** → Flutty도 따라간다 (workbench의 `onOpenFolder`와 같은 개념).
- **HEAD 변경은 Workspace가 감지해 모두에게 알린다** — 상세 규칙은 §1.10. Dock끼리 직접 부르지 않는다.
- 그 외 자동 연동은 만들지 않는다 (예: 빌드 성공 → PR 관문은 workbench의 일이지 Taskbench의 일이 아니다).

---

## 4. 확장: Rust runner · Electron runner

Flutty Dock은 사실상 **"프로젝트 종류별 실행기(runner)"** 의 첫 구현이다. 확장 대상은 둘이다.

| Runner | 감지(`ProjectDetector`) | 하는 일 | Flutter runner와 다른 점 |
|---|---|---|---|
| **Flutter** (Flutty, 지금) | `pubspec.yaml` + `flutter: sdk: flutter` | USB 기기·데스크톱에 빌드/설치/실행, 서명, 환경 점검 | 대상 = 기기 목록, 핫 리로드, iOS 서명 |
| **Rust** | `Cargo.toml` (워크스페이스면 멤버의 bin 목록) | `cargo build/run/test`, 프로필 debug/release, 대상 triple, features, bin 선택, `clippy`/`fmt` | 대상 = 이 컴퓨터 + (선택) 크로스 triple. 기기 없음. 오래 도는 프로세스 + 출력 스트림 |
| **Electron** | `package.json`에 `electron` 의존성 | `start`/`dev` 스크립트 실행, 패키징(`electron-builder`/`forge` 스크립트), Node·패키지 매니저(npm/pnpm/yarn) 자동 판별 | 대상 = 이 컴퓨터. 스크립트 목록에서 고름. 패키징 산출물 폴더 열기 |

### 4.1 구조: 칸(Dock) = 모듈, 감지가 칸을 켠다

```dart
abstract class DockModule {            // 아코디언 한 칸
  String get id;                       // 'branch', 'flutty', 'rust', 'electron'
  IconData get icon;
  String title(AppLocalizations l10n);
  bool appliesTo(Workspace w);         // 이 디렉터리에서 칸을 보일지
  Widget summary(BuildContext c, Workspace w);   // 접힌 제목 한 줄
  Widget body(BuildContext c, Workspace w);      // 펼친 내용
  void onWorkspaceChanged(Workspace w);
}

abstract class RunnerModule extends DockModule {   // 실행기 칸의 공통 약속
  ProjectDetector get detector;
  Future<List<RunTarget>> targets(DetectedProject p); // 기기 / 이 컴퓨터 / triple
  List<RunProfile> get profiles;                      // Debug·Release 등
  RunCapabilities get capabilities;                   // 중지·핫 리로드·빌드만·패키징
  List<DoctorCheck> doctor();                         // 환경 점검 항목
}

abstract class ProjectDetector {
  String get kind;                     // 'flutter', 'cargo', 'electron'
  Future<List<DetectedProject>> detect(String dir);   // 아래 4.2 검색 규칙
}
```

- 셸은 `List<DockModule>`만 안다. 칸을 추가해도 셸 코드 수정이 없다 (§1.1 규칙: 하나만 펼침, 제목 순서 고정).
- **`appliesTo`로 칸이 켜진다.** Branch는 항상. 실행기 칸은 **그 디렉터리에서 프로젝트가 감지될 때만** 제목이 보인다. 그래서 제목은 보통 2~3개이고, 4개를 넘기지 않는다.
- **아무 실행기도 감지되지 않으면** 제목 하나 "▶ Run"만 보여 주고, 펼치면 지원 종류(Flutter · Rust · Electron)와 "폴더를 바꾸거나 한 단계 아래 폴더를 보세요" 안내를 띄운다. (칸이 갑자기 사라져 헷갈리는 일을 막는다.)
- 최소 높이 계산: `80 + 40 × (칸 수) + 내용 ≥ 400`. 칸이 3개면 364px, 4개면 약 324px — 최소 높이 560에서 불충분해지면 **제목 줄을 36으로 줄이는 밀도 단계**를 둔다(§1.7 검증에 칸 4개 케이스 추가).

**칸 추가 절차 (러너가 계속 늘어날 수 있다 — 확정)**: 새 runner는 아래 네 가지만 추가하면 되고 셸·공유 영역·Workspace는 수정하지 않는다.
1. `ProjectDetector` 하나 (`lib/docks/<id>/detector.dart`)
2. `RunnerModule` 구현 하나 (`lib/docks/<id>/`)
3. 설정 구역 하나 + 키 접두어 `<id>.*` + ARB 접두어
4. `lib/docks/registry.dart`의 목록에 한 줄

- 칸 순서는 레지스트리 순서(Branch 맨 위, 이후 추가된 순서)로 고정한다.
- **칸이 5개 이상 동시에 켜지는 경우**는 실제로 생기기 전까지 만들지 않는다. 그때는 접힌 제목 영역을 최대 높이 160px의 스크롤 목록으로 바꾼다 (펼친 칸의 내용이 최소 300px 이상 남도록).
- 각 runner는 `onHeadChange`(§1.10)·`appliesTo`·`summary` 세 가지 약속만 지키면 공유 영역·브랜치 전환·끌어놓기 규칙을 자동으로 따른다. 이 약속을 지키는지 검사하는 **공통 계약 테스트**(`test/dock_contract_test.dart`)를 단계 1에서 만들어 두고, runner마다 통과시킨다.

### 4.2 검색 규칙은 종류별로 독립 적용

요청된 규칙("depth 0에서 안 잡히면 depth 1")을 **detector마다 따로** 적용한다.

- 예: 폴더 = Rust 프로젝트 루트(`Cargo.toml`) 안에 Flutter GUI(`gui/pubspec.yaml`)가 있는 경우 → Rust 칸은 depth 0에서, Flutty 칸은 depth 0에 없으니 depth 1의 `gui/`에서 잡힌다. 한 디렉터리에서 칸 둘이 같이 켜진다.
- Electron도 `package.json`이 depth 0에 없으면 depth 1(`app/`, `desktop/` 등)에서 찾는다. `node_modules`는 건너뛴다. Rust는 `target`을 건너뛴다.
- 같은 종류가 depth 1에서 여럿이면 지금처럼 칸 머리의 드롭다운에서 고르고 디렉터리별로 기억한다 (`<kind>.project_choice:<dir>`).

### 4.3 지금 만드는 것 / 만들지 않는 것

| 지금 (1~5단계) | 나중 (확장 단계) |
|---|---|
| `DockModule`, `RunnerModule`, `ProjectDetector`, `DetectedProject` 인터페이스 | Rust·Electron 칸 구현 |
| Flutter detector (+ Branch는 Run 계약 없이 `DockModule`만) | Rust·Electron detector |
| 공통 UI를 `core/ui/`로 이동: 출력 뷰어, 복사 버튼, 명령 표시, 점검 타일, 배너 — Flutter 전용 문구 없이 쓸 수 있게 | 필요 시 실행 세션(`RunSession`: 프로세스 시작·중지·출력 스트림·종료 코드) 공통 추출 |
| 접힌 칸도 살아 있는 구조(§1.5)이므로 장시간 프로세스가 칸 전환에 영향받지 않음 | |
| 설정 구역·키 접두어 규칙: `flutty.*` 처럼 `rust.*`, `electron.*` 자리 예약 (§1.8) | 칸별 설정 구역 추가 |

- **Flutty 내부(`InstallController`)는 지금 분해하지 않는다.** Flutter 전용 가정(기기 감시, 서명, 핫 리로드)이 많아 두 번째 runner 없이 추상화하면 틀린 모양이 된다. 단, 공통 UI만 `core/ui/`로 미리 빼 두어 Rust 칸이 첫 구현 때 바로 재사용한다. **Rust 칸을 실제로 만드는 시점에** `RunSession`을 Flutty에서 추출한다 (추출은 Flutty 테스트로 보호).
- 세 번째 구현(Electron) 때 `RunnerModule`의 모양을 한 번 더 검증하고, 맞지 않으면 인터페이스를 고친다 — 그래서 인터페이스는 `0.x`로 두고 문서에 "미확정"을 표시한다.

### 4.4 상표·이름

- 앱 이름은 `Daylight Taskbench`라 문제 없다. 칸 제목은 **하는 일이 보이는 이름**을 쓴다: `Git & GitHub`, `Flutter Runner`, `Rust Runner`, `Electron Runner` (결정 13). 기술 이름은 앱 이름·식별자·저장소 이름에는 넣지 않는다.
- 각 도구(cargo, node, npm, rustup)는 사용자가 설치한 것을 호출한다 (`flutter`/`git`과 같은 규칙). 앱에 번들하지 않는다.

---

## 5. 단계 (각 단계 끝에 `flutter analyze` + 테스트 통과, 사용자 확인 후 다음)

| 단계 | 내용 | 완료 조건 |
|---|---|---|
| **0. 골격** | `flutter-app-bootstrap`으로 Daylight Taskbench 골격 + CLAUDE.md. git init, 브랜치 규칙 | 빈 앱이 뜨고 정보 창·테마·언어·창 기억 동작 |
| **1. 셸** | **장식 스타일(§1.12, 승인 시)**, **폴더 끌어놓기(§1.11)**, **시작 화면(Branch `start_screen` 이식 — 환경 점검·최근·복제·init 포함)**, `WorkspaceController`(+가짜 `GitState`, §1.10), 디렉터리 바·브랜치 줄(§1.9), 아코디언(`DockModule` 두 개를 **빈 자리표시자**로), 창 도킹·기억, **설정 창(§1.8, 도킹 크기 포함)** | §1.7 화면 검증을 자리표시자로 먼저 통과 — **화면 확정 지점. 사용자가 보고 승인** |
| **2. 공통 코어** | `command_runner` 합집합, 설정 키(규약 이름)/l10n 접두어 체계, 도구 경로 통합 | 두 앱의 runner 테스트가 모두 통과 |
| **3. Branch Dock 이식** | `docks/branch/` + 테스트 이식 (19개 테스트 파일). `RepoController`를 Workspace 소유로 옮기고 상태 헤더 1·2행을 공유 영역으로 이동, 가짜 `GitState`를 실제로 교체, 편집기 명령 설정을 설정 창으로 | 단독 화면에서 원본과 기능 동일 + §1.10 실제 git 테스트 |
| **4. Flutty Dock 이식** | `docks/flutty/` + 테스트 이식 (22개) + 프로젝트 검색 depth 0→1, Git 탭 제거 | 〃 |
| **5. 연결** | §3.4 연결점, `onHeadChange` 정책 전부(§1.10 표), 접힌 제목 요약, 빈 상태 | §1.7 전부 통과 |
| **6. 릴리스 준비** | README(영·한), 스크린샷, 설치 프로그램, `flutter-app-release-check` | `v0.1.0` 태그 가능 |
| **7. Rust runner** (확장) | `RunSession` 추출 → Rust 감지·칸·설정 구역·환경 점검(cargo/rustup) | 계획서 [docs/RUST_RUNNER.md](docs/RUST_RUNNER.md) 작성됨(승인 대기, 질문 §10) — 승인 후 시작 |
| **8. Electron runner** (확장) | Electron 감지·칸·스크립트 실행·패키징 | 〃 `docs/ELECTRON_RUNNER.md` + `RunnerModule` 모양 재검증 |
| **9. Gradle runner** (후보, 순서 미정) | Gradle 프로젝트 감지·칸 — Android 앱은 설치/실행·환경 점검(adb 공통화), 그 밖은 작업 선택기 | 계획서 [docs/GRADLE_RUNNER.md](docs/GRADLE_RUNNER.md) — **9a(공통 추출)·9b(감지·칸 뼈대)·9c(Run·Devices·Log 탭)·9d(Doctor·도구)·9e(연결) 완료**, 9f(README·스크린샷·릴리스)만 남음 |
| **10. 통합 기준 정리** (확장 모드, §1.13) | workbench `lib/branchdock/`·`core/`·`devices/`·`flutter/`·`install/`와 taskbench의 같은 코드를 **diff로 읽는다.** import 경로·접두어 차이와 실제 로직 차이를 가르고, workbench에만 있는 개선을 목록으로 만든다. 필요한 것만 taskbench에 반영 (코드 변경은 이 단계에서 최소) | `docs/WORKBENCH_MERGE.md`에 차이 목록·반영/버림 결정이 있고, 반영한 것은 테스트와 함께 통과. 사용자 확인 |
| **11. 확장 셸** | 패널 켜짐 상태(탐색기·에디터·터미널)와 **파생 모드**(§1.13), **도크 열을 독립 위젯으로 분리**, 확장 패널 자리를 **빈 자리표시자**로 놓기, 모드별 창 크기·위치 기억, 도킹 전환 비활성화·툴팁, 에디터↔터미널 전환 껍데기, 설정 "내장 에디터 사용" | 도킹↔확장 전환에서 **도크 열의 펼침 칸·스크롤·실행 중 빌드가 그대로**, §1.7 화면 검증 + 모드 전환 골든. **화면 확정 지점 — 사용자가 보고 승인** |
| **12. 폴더 열기 분기** | §1.13 표 구현: 하위 저장소 목록 고르기, 위험한 위치에서 `git init` 숨김, 하위 폴더 → 루트로 열고 `selectedDir`을 탐색기가 펼치기 준비 | 5가지 상황 테스트(임시 디렉터리로 저장소·하위·다중 저장소·빈 폴더·위험 위치) 통과 |
| **13. 탐색기 이식** | workbench의 `file_tree`·`tree_pane`·`file_icons`·`quick_open`·`project_search`·`recent_projects` 이식, 에디터가 꺼져 있을 때 파일 열기 → 외부 VS Code | 탐색기 단독으로 동작 (에디터 패널은 아직 자리표시자). 외부 VS Code 열기 확인 |
| **14. 터미널 이식** | workbench `terminal/`과 `packages/xterm2`·`flutter_pty`(path 의존) 이식, 저장소 루트를 cwd로 시작, 에디터↔터미널 전환 시 세션 유지, 폰트·테마 설정 | macOS·Windows에서 터미널이 뜨고 세션이 전환·모드 전환 중 유지됨. 네이티브 빌드 확인 |
| **15. 에디터 이식** | `daylight-editor-flutter`(`re_editor` 포크), `studio/`, 에디터 `ui/`(`editor_pane`·gutter·squiggle·find 등), `problems/`·`diff/`. workbench `ui/`의 공용 화면(`diff_view`·`compare_dialog` 등)은 에디터용과 공용으로 **나눠서** 옮긴다. 도크·Git 코드가 에디터를 참조하지 않는 경계 테스트 추가 | 에디터 켜짐/꺼짐 양쪽에서 같은 빌드로 동작, 경계 테스트 통과 |
| **16. 연결** | 에디터↔터미널 전환·패널 단축키(§1.5 표 + 충돌 검사), **브랜치가 바뀔 때 열린 파일 처리**(§1.10 확장: 저장 안 된 변경이 있는 파일, 다른 브랜치에 없는 파일), 빌드 오류 위치 → 에디터/VS Code(Flutty에 이미 있는지 확인 후), Git 칸 변경 파일 ↔ 에디터 | §1.7 + 확장 모드 시나리오 4개(VS Code 사용자 · 빠른 수정 · 빌드 실패 추적 · 터미널만) 실제 앱으로 통과 |
| **17. 릴리스·정리** | README(영·한)·스크린샷 갱신, 버전은 기능 추가이므로 minor(`v0.3.0` 제안), `flutter-app-release-check`, workbench 보관 안내(README·릴리스 노트에 이동 경로. 저장소 archive는 사용자가 직접) | 태그 가능. workbench 사용자가 옮겨 올 안내가 있음 |

단계 1을 먼저 하는 이유: 기능은 이미 있으므로 틀릴 수 있는 것은 **화면**이다. 자리표시자 셸로 구성을 먼저 눈으로 확정하고 나서 기능을 채운다.

**확장 모드(10~17)의 순서 이유**
- 10을 가장 먼저 하는 이유: 같은 코드가 두 앱에서 갈라져 있어, 어느 쪽이 최신인지 모르는 채 옮기면 버그를 두 번 만든다. 읽는 일이라 위험이 없다.
- 11에서 화면을 확정하는 이유는 단계 1과 같다. 확장 패널이 비어 있어도 도크 열이 모드 전환에 흔들리지 않는지를 먼저 본다.
- 13 → 14 → 15 순서는 **위험이 작은 것부터**다. 에디터가 가장 크고(약 10k LOC + 포크 15k), 터미널은 네이티브 의존이 있다. 앞 단계가 끝나야 도킹을 풀고 쓰는 최소한의 작업대가 생긴다.
- 12는 11 이후라면 13과 병행할 수 있다 (서로 다른 파일을 건드린다).

---

### 단계 1 결과 (2026-10-31)

만든 것: 장식 스타일(`TaskbenchStyle`·`GlassCard`·`AuroraBackground`·`AppMark`·`PulseDot`), `Workspace`(열기·최근·끌어놓기 규칙·HeadChange 전파), 시작 화면, 공유 영역 두 줄, 아코디언, 설정 창(도킹 배치), 자리표시자 Branch/Flutty 칸, 칸 계약 테스트. `flutter analyze` 0, 테스트 94개 통과.

계획과 달라진 점 (단계 1에서 정한 것):
- **설정 규약 문서가 둘이었다.** `settings.md`(2026-10-29 오전)와 `settings-screen.md`(같은 날 오전 11:43, 템플릿 코드의 기준)가 키·이름·언어 위치에서 서로 어긋난다. 충돌한 곳은 `settings.md`/`localization.md`를 따랐다: `theme_palette`·`ColorPalette`·`text_scale`·`Icons.settings_outlined`, 언어는 별도 구역. 라벨은 템플릿 ARB(`settingsMode` "모드")를 썼다. **규약 저장소에서 두 문서를 하나로 정리해야 한다.**
- **GitState 는 가짜가 아니라 가벼운 실제 구현**(`ProcessGitStateSource`: `git status` + `.git` 감시 + `index.lock` 대기)으로 먼저 만들었다. 실제 `git switch`·`checkout --detach` 가 HeadChange 를 정확히 한 번 내는 테스트가 있다. 단계 3에서 RepoController 로 바뀌어도 `GitStateSource` 뒤라서 셸은 그대로다.
- **시작 화면의 일부는 단계 3으로 미룸**: GitHub 복제, git/gh 경로 지정, 진단 복사 (지금은 열기·최근·끌어놓기·`git init`·환경 요약).
- **브랜치 칩 전환·편집기 명령 설정**은 단계 3 (지금은 VS Code 기본, 칩은 안내만).
- 접힌 Branch 칸 요약은 `↑2` 대신 다음 행동(`Push ↑2 가능`)으로 했다 — 공유 줄과 같은 정보를 두 번 보이지 않으려고.
- 화면 확인용 스크린샷 도구: `SHOTS_DIR=… flutter test test/tool/screenshot_test.dart` (440/380, 라이트/다크).

### 단계 2 결과 (2026-10-31)

- **`command_runner` 합집합** (`lib/core/command_runner.dart`): 두 원본의 호출 코드가 이름만 바꾸면 그대로 돈다. Branch의 `gitPath`/`ghPath`·`cancel:`·git 환경(`LC_ALL=C`)·Git Bash 찾기, Flutty의 `toolPaths`·`RunHandle.send`·`keepStdinOpen`·`onOutput`·코드 페이지 해석·Windows `flutter` 실행을 모두 가진다. 달라진 점: `path`는 시작 때 한 번 만든 동기 문자열(Flutty의 지연 `Future` 대신), `CancelToken`은 `RunHandle`의 별칭, `NO_COLOR`는 모든 명령에 준다(Branch는 gh에만).
- `resolvePath()`는 두 원본의 흔한 위치(Homebrew·linuxbrew·WinGet·GitHub CLI·Android platform-tools·flutter/fvm)를 모두 더했다.
- **도구 경로 통합**: `lib/core/tool_paths.dart`(저장 키 `tool_path_<이름>`)와 설정 창의 "도구" 구역. 칸이 자기 도구를 `register`하면 줄이 생긴다 (지금 git·gh, 단계 4에서 flutter·adb). 경로가 바뀌면 환경 점검을 다시 한다.
- **키 충돌 검사** (`test/keys_test.dart`): ARB ko/en 키 동일·중복 없음, 저장 키는 공통 목록이거나 칸 접두어(`branch.`·`flutty.`·`rust.`·`electron.`)로 시작해야 한다. 칸을 더할 때 이 검사가 규칙을 지킨다.
- `command_log`·`vscode`는 두 원본이 서식만 달라 Branch 것을 그대로 썼다 (vscode 테스트 이식).
- 테스트 130개 통과 (runner 28개 신규: 도구 지정, 환경 변수, 실행 중 입력, 취소, 출력 스트림, 127, PATH 만들기).
- 아직 안 한 것: 두 원본의 `CommandRunner`를 쓰는 기능 테스트(Branch 10개·Flutty 14개)는 각 Dock 이식(단계 3·4)에서 함께 옮긴다.
- 알려 둘 것: 위젯 테스트에서 실제 파일 I/O(`Directory.createTemp` 등)는 `tester.runAsync` 안에서 해야 한다 — 밖에서 하면 가짜 시계 때문에 영원히 멈춘다. 포커스된 `TextField`가 있으면 `pumpAndSettle`이 끝나지 않는다.

### 단계 3 결과 (2026-10-31)

Branch Dock 이식 완료. 실제 저장소로 앱을 띄워 확인했다(공유 영역 아래 Branch Dock 의 Fetch/Pull/Push·탭 8개·추천 배너·변경 목록·커밋 상자·명령 바, 접힌 Flutty 칸). `flutter analyze` 0, 테스트 272개 통과.

- Branch 의 `git/`·`github/`·`release/`·`repo/`·`ui/`(탭 8개·시트·도움말)를 `lib/docks/branch/` 로 옮겼다 (원본 수정 없음). ARB 는 같은 값 58개 공유, 821개는 `bd` 접두어.
- **RepoController 는 Workspace 소유** (`RepoGitStateSource` → `GitState`). 본문(`BranchDockBody`)은 저장소를 만들지도 닫지도 않는다. 상태 헤더 1·2행은 공유 영역으로 올라갔다. 저장 키는 `branch.` 접두어.
- **원본 테스트 이식**: Branch 고유 테스트 14개 + vscode 를 `test/branch/` 로 옮겼다 (about·app_settings·high_contrast·update 는 템플릿 공통이라 이미 있음). `screens_test` 의 시작 화면 구간은 새 `test/start_screen_test.dart`, 공유 영역 pill 은 `shell_test` 로 옮겼다.
- **시작 화면 마무리**: GitHub 복제, `gh` 로그인 안내, 환경 점검 카드(진단 복사·경로 지정)를 Branch 것으로 이었다. 경로 지정은 설정 창의 "도구" 구역으로 간다.
- **공유 영역 브랜치 칩 = 빠른 전환**: 누르면 로컬 브랜치 목록이 뜨고, 고르면 바로 전환한다 (변경 때문에 막히면 임시 저장 후 재시도 제안, 다른 worktree 면 그 폴더 열기). Dock 이 접혀 있어도 된다.
- **설정 창**: "Branch Dock" 구역(자동 fetch, 편집기 명령 — 공통 키 `editor_command`)을 더했다. 칸·도구 구역은 해당 객체가 있을 때만 보인다.
- **색 규칙**: 화면 코드의 `AppColors`·색 리터럴을 모두 없앴다(Branch 의 중복 Tone/StatusPill 은 공통 위젯으로 통합, 그래프 줄 색은 `lib/theme/graph_colors.dart`). `test/theme_rules_test.dart` 가 어기면 실패한다.
- **알려 둠**: 공유 영역 칩의 전환 메뉴는 실제 클릭으로 아직 확인하지 못했다(전환 로직 `withStashRetry`는 원본 테스트가 지킨다). 위젯 테스트 안에서 실제 프로세스를 도는 동작(git init 단추 등)은 단위 테스트로 대신 지킨다.

### 단계 4 결과 (2026-10-31)

Flutty Dock 이식 완료. 실제 앱으로 확인했다(칸 펼침 → 프로젝트 머리·탭 5개, 점검 탭의 실제 flutter/Xcode/adb/인증서 점검, 설정 "도구" 구역에 flutter·adb 줄). `flutter analyze` 0, 테스트 379개 통과.

- 원본의 `flutter/`·`devices/`·`doctor/`·`install/`·`secrets/`와 탭 화면을 `lib/docks/flutty/` 로 옮겼다 (원본 수정 없음). `InstallController` → **`FluttyController`**: 프로젝트 열기·최근 목록·git 상태·worktree·VS Code 열기·도구 경로를 걷어냈다. 프로젝트는 칸이 `setProject()` 로 넘긴다.
- **FluttyDock**: 공유 폴더에서 depth 0→1 로 찾고(여럿이면 머리의 드롭다운), 고른 프로젝트 상세(`FlutterProject.detect`)를 컨트롤러에 준다. 브랜치·커밋이 바뀌면 다시 찾는다. 실행 중에 브랜치가 바뀌면 **배너만** 띄우고 멈추지 않는다 (§1.10). 파일이 사라지는 경쟁(브랜치 전환 중 pubspec)은 "없음"으로 본다.
- **늦은 시작**: 기기 목록·환경 점검은 칸을 처음 펼칠 때 시작한다 (`ensureStarted`) — 앱 시작에 xcrun/adb 가 돌지 않는다.
- **mood/busy**: 실행·정리 중이면 working+busy, 실패 단계가 있으면 failed, 모두 끝났으면 success.
- **탭 5개** (실행·기기·서명·점검·기록; Git 탭은 Branch Dock 과 공유 영역으로). 저장 키는 모두 `flutty.` 접두어 (`ios_team_id`·`build_mode`·`last_tab_id`·`build_options:`·`project_mode:`·`project_device:`·`secrets_repo`). 옛 앱의 값은 가져오지 않는다 (결정 §6).
- **시크릿 화면 → 설정 "릴리스 시크릿" 구역** (macOS 에서만, 칸·워크스페이스가 있을 때). Scaffold 를 걷어낸 `SecretsPanel`, 앱 공용 실행기를 써서 `gh` 경로 지정이 그대로 적용된다. 좁은 폭에서는 칩 줄이 가로로 스크롤된다.
- **도구 경로**: `FluttyDock(tools:)` 가 `flutter`·`adb` 를 `ToolPaths` 에 등록하고, 바뀌면 기기·점검을 다시 읽는다. 배너·기기 탭·점검 탭의 "도구 경로 지정" 은 설정 창 "도구" 구역을 연다.
- **공통 UI** → `lib/core/ui/`: output_viewer·copy_output_button·command_text (CheckTile·CheckText 는 Flutty 점검 모델에 묶여 칸 안에 남겼다). 번역 키 264개는 `fd` 접두어로 합쳤고(같은 값 59개는 공유), 상태색은 `toneColor` 로 읽는다.
- **테스트 이식**: 원본 22개 중 칸에 해당하는 9개(build_options·desktop_build·doctor·windows_checks·install·banner_adb·devices_tab·secrets·stale_build_cache)를 `test/flutty/` 로 옮겼고, 칸 모듈 테스트 3개를 새로 썼다. 나머지(about·app_settings·high_contrast·update·vscode·tool_paths·title_menu·window_vscode·worktrees·home_screen·tabs·git_and_phase·command_output_decode)는 셸·공통 코어가 이미 같은 일을 하는 테스트가 있거나 화면이 사라진 것이다.
- **알려 둠**: 실제 기기에 설치하는 흐름(실기기 빌드·`flutter run`)은 이 환경에서 확인하지 못했다 (원본 테스트가 계획 생성·실행 순서를 지킨다). `RunSession` 추출은 7단계 Rust runner 와 함께 한다.

### 단계 5 결과 (2026-10-31)

연결 완료. `flutter analyze` 0, 테스트 381개 통과.

- §1.10 표의 Flutty 열을 채웠다: 브랜치 변경 → 프로젝트 재감지(이미 있음) + **점검 결과를 오래된 값으로 표시**(`diagnosticsStale`, 점검 탭에 안내·흐리게, 다시 점검하면 풀림). 커밋 이동 → 이름·버전만 다시 읽기. 병합·rebase 등 진행 중 → "충돌 중에는 빌드 결과를 믿을 수 없습니다" 배너.
- **접힌 제목 점**: `TaskbenchMood.warning`(주의색)을 더했다. Flutty 는 실행 중 브랜치가 바뀌었거나 작업(병합 등)이 진행 중이면 이 색이 된다 (실패 > 주의 > 성공 순). 앱 전체 배경 틴트는 그대로 working/failed/success 만 본다.
- 4가지 빈 상태(폴더 없음 / git 아님 / Flutter 프로젝트 없음 / 둘 다 있음)는 단계 1의 시작 화면·`RunEmptyDock` 로 이미 설명이 붙어 있다.
- 접힌 칸도 `onHeadChange` 를 받고(계약 테스트), 빌드 상태는 칸 객체(`FluttyController`)가 쥐고 있어 Branch 로 갔다 와도 이어진다.
- 알려 둠: §1.7 의 폭·테마·글자 크기별 스크린샷 전수 확인은 6단계(릴리스 준비) 때 스크린샷과 함께 한다.

### 단계 6 결과 (2026-10-31)

릴리스 준비 완료 — 태그만 남았다. `flutter analyze` 0, 테스트 381개 통과, `check_readme.py` 전체 검사 통과(경고 0), 릴리스 감사에서 남은 차단 항목은 "원격에 없는 로컬 커밋"과 "버전 올리기" 둘뿐.

- README(영·한) 기능·동작 방식·개발 절을 채웠다. 스크린샷 2장(라이트·다크 대각선 `home.png`, Flutty `detail.png`)과 데모 GIF(Flutty → Branch → Flutty → 기기 탭, 3.3 MB)는 중립 데모 프로젝트(`photo_notes`)로 영어 UI에서 찍었다 — 개인 경로·인증서 이름이 보이지 않는다. 캡처 원본 PNG는 `docs/screenshots/raw/`에 두고 `.mov`는 무시한다.
- 코드의 한국어 리터럴(Git Bash 못 찾음 메시지)을 영어 진단 메시지로 바꿨다.
- GitHub 시크릿은 macOS 서명 6개·모바일용이 이미 등록되어 있다.
- 알려 둠: Windows 설치 프로그램·워크플로는 이 앱 코드로는 아직 한 번도 돌려 보지 않았다(`v0.1.0-rc.1`은 골격 시절 것). 태그 전에 `gh workflow run release.yml --ref <브랜치>`(게시 없음)로 한 번 증명하는 것을 권한다.
- 앱 아이콘은 Branch Dock의 것을 그대로 쓴다 (사용자 결정). `assets/icon/`에 Branch의 `cat.json`(`app_id: branch-dock`)·`source_glyph.{svg,png}`를 복사하고 `generate_icons.py`로 다시 만들어, 마스터·macOS 세트·Windows `.ico`가 Branch와 바이트 단위로 같다. 판 색은 app id 해시이므로 `cat.json`의 `app_id`를 `daylight-taskbench`로 바꾸지 않는다. 쓰지 않게 된 `tool/icon/icons8-grinning-cat-1024.png`는 지웠다.

### 단계 9 결과 (2026-10-31) — Gradle runner

계획서는 [docs/GRADLE_RUNNER.md](docs/GRADLE_RUNNER.md). `flutter analyze` 0, 테스트 500여 개 통과, Flutty 테스트는 한 줄도 고치지 않았다.

- **9a 공통 추출**: `RunSession`(단계 실행·취소·키), `core/devices`(기기 타입·`AdbDevices`), 출력 1 MiB 꼬리 상한과 갱신 묶기, 취소가 자식 프로세스까지 끝냄, `LogTab`·`InfoChip`·`DeviceListSection`·`OutputSection`·`StepStatusIcon`·`NoticeBanner`·`SectionTitle`을 `core/ui`로. 계획서의 `DeviceWatcher`는 Flutty가 기기를 폴링하지 않아 필요 없었다.
- **9b 감지·뼈대**: `GradleDetector`(Flutter·React Native의 `android/` 제외), 한 줄 단위의 가벼운 Gradle 읽기, Android 앱/JVM 모양 판정.
- **9c Run·Devices·Log 탭**: 모듈·변형·동작·옵션 → 실제 실행 명령(미리보기 = 실행) → 시작/중지, `ANDROID_SERIAL`로 기기 하나 지정, `adb shell monkey`로 앱 열기, 일반 Gradle은 작업 선택기. 정확한 변형·작업 목록은 자동이 아니라 **단추를 눌렀을 때만** 읽는다 (펼치기만 해도 Gradle 배포판 다운로드가 시작되면 놀라므로).
- **9d Doctor 탭**: JDK·SDK·플랫폼·라이선스·adb·래퍼·릴리스 서명 점검, AGP→JDK 작은 힌트, 환경에 없는 `JAVA_HOME`·`ANDROID_HOME`만 실행 때 넣고 미리보기에 보인다.
- **9e 연결**: 접힌 제목의 요약(실행 중·실패·완료), 색(점검 실패·오래된 점검이면 경고), 실행 중 브랜치 전환은 배너만, `Stop daemons`.
- **9f**: README(영·한)·스크린샷(`gradle.png`). **실제 앱으로 보다가 잡은 오류**: 루트 build 파일의 `plugins { id("com.android.application") apply false }`를 적용한 플러그인으로 읽어 루트가 Android 앱 모듈이 되던 것 — 실제 Android Studio 구조에서 흔한 형태라 `apply false` 줄은 건너뛰도록 고치고 테스트를 더했다.
- **알려 둠**: 실제 Gradle·기기로 설치해 열어 본 적은 없다 (테스트와 스크린샷은 가짜 `gradlew`·`adb`). `ANDROID_SERIAL`로 기기를 좁히는 방식과 `monkey`로 앱을 여는 방식은 직접 확인이 필요하다.

### 단계 10 결과 (2026-11-01) — 확장 모드 통합 기준 정리

비교 결과는 [docs/WORKBENCH_MERGE.md](docs/WORKBENCH_MERGE.md). 코드는 바꾸지 않았다.
- branch 코드의 갈라짐은 **대부분 UI 스타일 API 차이**(아이콘 `context.icons` ↔ `Icons.x`, 글꼴, 문구 접두어)이고 로직 차이는 몇 군데에 몰려 있다. 공통 60개 파일 중 26개는 정규화 후 완전히 같다.
- **정해야 할 것**(같은 문서 §4): 확장 모드에서 바텀시트를 도크 열에 가둘지, 확인 못 한 workbench 수정 3건의 실제 확인. (검증 관문은 결정 21, 아이콘 통일은 결정 22로 확정.)

### 단계 11 결과 (2026-11-01) — 확장 셸 (화면 확정 지점)

- **파생 모드**: `PanelLayout`(`lib/ui/shell/panels/panel_layout.dart`)이 탐색기·에디터·터미널 켜짐과 "내장 에디터 사용"(`editor_embedded`)을 쥐고, 확장 여부(`expanded`)와 가운데에 보이는 것(`center`)을 계산한다. 도킹 모드 설정값은 없다.
- **셸**: 도킹이면 도크 열이 창 전체, 확장이면 `ExpandedArea`(탐색기 240 + 가운데)가 왼쪽에 붙고 도크 열은 오른쪽 440(도킹 기본 폭과 같음). 디렉터리 바·브랜치 줄·아코디언이 **한 덩어리로 오른쪽에 남아** 도킹 모드와 똑같이 보인다(사용자 확인). 도크 열은 `GlobalKey`를 달아 모드를 오가도 State(펼친 칸·스크롤·실행 중 빌드)가 유지된다 — 위젯 테스트로 검증. 탐색기·에디터·터미널은 **자리표시자**이고 단계 13~15에서 채운다.
- **조작**: 앱 바의 "패널" 단추(체크 메뉴 3개, 켜져 있으면 "모두 닫으면 도킹으로 돌아갑니다" 안내). 도킹 최소 폭(380)에서는 폴더 이름에 자리를 주려고 같은 항목이 "더 보기" 메뉴 안으로 들어간다. 설정 창에 "에디터" 구역(내장 에디터 사용)을 더했다.
- **창 크기**: `WindowModeController`(`lib/window/window_mode.dart`) — 도킹 440×960(최소 380×560), 탐색기만 680×960(최소 680×560), 확장 1240×820(최소 960×560). 모드가 바뀌면 **너비만** 그 모드의 기억된 너비로 바꾸고 높이는 지금 그대로 둔다(패널을 켰다고 높이가 바뀌지 않는다), 오른쪽 가장자리 고정. Windows 는 기존 `WindowPlacement`가 **도킹 모드의 위치·크기만** 기억한다.
- **도크 열 안의 칸은 자기 열 크기를 화면 크기로 본다**(확장 모드의 `MediaQuery` 덮어쓰기): 그렇지 않으면 창이 840 이상이라는 이유로 Git 칸이 "넓은 창 배치"(왼쪽 레일)로 바뀐다. 사용자가 실제 앱에서 발견했다.
- **아직 안 한 것·알려 둠**: ① 실제 창 크기 전환(macOS·Windows)은 사람이 앱을 띄워 보지 못했다 — 계산 함수와 위젯 레이아웃만 테스트했다. ② Windows 는 확장을 처음 열 때 오른쪽 고정이 아니라 가운데에 열린다. ③ **바텀시트 범위**(도크 열에 가둘지)는 아직 정하지 않았다 — 화면을 보고 정한다. ④ 에디터↔터미널 단축키와 확장 영역 폭 조절은 단계 16.
- **화면 방향 (사용자 확인, 2026-11-01)**: workbench처럼 — 떠 있는 카드가 아니라 얇은 구분선으로 나뉜 평평한 패널(탐색기 | 가운데 | 도크 열), 가운데 위쪽은 파일 탭 줄이고 오른쪽 끝에 에디터↔터미널 전환. **전환형은 유지**(터미널을 하단 패널로 두는 workbench 방식은 택하지 않음). Run 탭은 없다. 오른쪽 도크 열은 taskbench의 카드 아코디언 그대로. 하단 상태 줄(브랜치·문제·저장됨)은 에디터가 붙는 단계 15에서 정한다.
- **낮은 창**: `DockAccordion`은 펼친 칸의 내용 높이를 280 아래로 줄이지 않고, 창이 그보다 낮아지면 넘침 오류 대신 도크 열이 스크롤된다 (사용자가 높이를 줄이면 Runner 에서 오버플로가 난다고 지적).
- **알려진 디버그 소음 두 가지 (나중에 고치기로 함, 2026-11-01)**: ① 시작 직후 `DockAccordion`의 `Column`이 "아래로 N픽셀 넘침"을 낸다 — 창 높이가 칸 제목들보다 작은 시작 순간으로 추정하며(측정은 못 함), `dock_accordion.dart`는 이 단계에서 바꾸지 않았다. ② 시작할 때 `FluttyDock.attach` → `ToolPaths.register`가 build 중에 알림을 보내 "setState() called during build"가 난다 (디버그 모드). 둘 다 기능에는 영향이 없다.
- 테스트 549개 통과, `flutter analyze` 깨끗.

### 단계 12 결과 (2026-11-01) — 폴더 열기 분기

설계는 §1.13 표. 구현은 `lib/workspace/folder_scan.dart`(분석), `Workspace`(`notRepoInfo`·`initRepository`), `lib/ui/repo_choice.dart`(두 창), 시작 화면·셸의 끌어다 놓기.
- **분석(`FolderScanner`)**: 저장소가 아닌 폴더를 열면 하위 **2단계**까지 `.git`(폴더 또는 파일)을 찾는다 — 저장소 안으로는 들어가지 않고, 숨김·`node_modules`·`build` 등은 건너뛰며 30개에서 멈춘다. 위험한 위치(파일 시스템 루트, 홈과 그 부모, 홈 아래 Desktop·Documents·Downloads·Library 등 기본 폴더, 시스템 폴더)는 `git init`을 허용하지 않는다. 정확한 목록은 `isUnsafeInitLocation`에 있다.
- **동작**: 하위에 저장소가 있으면 시작 화면에 목록(폴더 이름 + 상대 경로)을 보이고 누르면 그 저장소를 연다 — `git init` 단추 없음. 열린 저장소가 있을 때 끌어다 놓은 폴더면 고르기 창. 하위에도 없고 안전하면 `git init` 단추 → **확인 창**(실행할 명령 `git init -b main`, Flutter 프로젝트이고 `.gitignore`가 없으면 Flutter용 `.gitignore` 선택(기본 켬), "첫 커밋은 만들지 않습니다") → 만든 뒤 연다. 위험한 위치면 안내 문구만 있다.
- **`initRepository`는 스스로도 막는다**: UI 가 단추를 숨기는 것과 별개로, 하위에 저장소가 있거나 위험한 위치면 `git init`을 실행하지 않는다.
- 실제 폴더로 확인: `FlutterProject`(하위 저장소 19개, init 불허), 홈(30개에서 멈춤, init 불허), `Desktop`(init 불허), 저장소 없는 빈 프로젝트 폴더(init 허용).
- `path` 패키지를 직접 의존성으로 올렸다(이미 잠겨 있던 1.9.1). 테스트 584개 통과.
- **알려 둠**: 위험한 위치 목록은 macOS·Windows·Linux 기본 폴더 이름 기준이다 (한글로 보이는 폴더 이름이 실제로는 영문이다). 앱으로 직접 눌러 본 확인은 사용자 몫이다.

### 단계 13 결과 (2026-11-01) — 탐색기 이식

`lib/explorer/`(독립 모듈) — `file_kind`·`file_icons`·`file_tree`·`project_files`·`quick_open`·`file_opener`·`explorer_panel`. 확장 영역의 탐색기 자리표시자를 `ExplorerPanel`로 바꿨다.
- **탐색기**: 저장소 루트를 보이고, 고른 하위 폴더(`selectedDir`)까지 폴더를 펼친다 (§1.13). 머리줄에 제목·빠른 열기·새로 고침. 폴더가 먼저, 이름순(대소문자 무시), `.git`은 숨김. 새로 고침은 펼친 폴더를 다시 읽는다.
- **선택·열기·키보드 (사용자 지적으로 보강)**: 파일을 **한 번 누르면 선택(강조)만** 되고 **두 번 누르면 열린다**(첫 클릭을 기다리지 않아 선택은 바로 보인다, 350ms 안에 같은 파일). 폴더는 한 번에 접고 펼친다(더블클릭의 두 번째 클릭은 다시 접지 않는다). 방향키: ↑↓ 선택 이동, → 펼치기·첫 자식, ← 접기·부모, Enter 파일 열기·폴더 접고 펼치기, Home/End. ⌘/Ctrl/Alt 조합은 셸 단축키에 맡긴다. 트리는 보이는 줄 목록을 한 곳에서 쥔다(방향키 이동이 보이는 줄 순서를 알아야 해서 전에 재귀 위젯으로 짠 것을 다시 짰다).
- **파일 열기**: 파일을 **두 번 누르거나 Enter**를 치면 `FileOpener` → 외부 편집기(설정의 편집기 명령, 없으면 VS Code)로 연다. 셸의 `_openFile` **한 곳**만 부른다 — 단계 15에서 내장 에디터가 붙으면 에디터 패널이 켜져 있을 때 그쪽으로 보내도록 이 함수만 바꾼다. 편집기를 못 찾거나 실행에 실패하면 안내 메시지(기존 `editorOpenNoEditor`·`editorOpenFailed`).
- **빠른 열기**: 파일 이름 일부로 찾기(글자 순서 맞춤 점수). 단축키는 **⌘/Ctrl+Shift+O** — workbench 의 ⌘P 는 Git 칸의 Push 가 쓰고 있어서 겹치지 않게 바꿨다. 탐색기 머리줄의 돋보기로도 연다. 저장소가 열려 있으면 도킹 모드에서도 동작하고 고르면 외부 편집기로 연다.
- **아이콘**: 결정 22대로 `Icons.x_rounded`, 색은 `ColorScheme`에서 (workbench 의 구문 강조 색 대신). 테마 규칙(색 리터럴 금지)을 지킨다.
- **옮기지 않은 것**: 프로젝트 안 **검색·바꾸기**(`project_search`·`project_replace`), 심볼 검색(`symbol_search`·`symbol_index`), worktree 선택. 에디터가 붙는 단계 15에서 같이 정하거나 쓰지 않기로 한다 — 검색 결과를 에디터로 여는 기능이라 외부 편집기만으로는 반쪽이다. `recent_projects`는 taskbench 에 이미 같은 기능(시작 화면·디렉터리 바 메뉴)이 있어 옮기지 않았다.
- 테스트 19개 추가(파일 종류·점수·목록·트리 선택·방향키·더블클릭·열기·빠른 열기·셸 안 탐색기). **알려 둠**: 앱 화면으로 직접 눌러 본 확인은 사용자 몫이다.

### 단계 14 결과 (2026-11-01) — 터미널 이식

- **패키지(복사)**: `packages/xterm2`(드래그 선택·한글 IME 결함을 고친 복사본)와 `packages/flutter_pty`(Windows 결함 4가지를 고친 복사본, **네이티브 코드 포함**)를 workbench 에서 그대로 복사하고 `path:` 의존성으로 걸었다. 고친 점은 각 폴더의 `PATCHES.md`. `analysis_options.yaml`은 `packages/**`를 분석에서 뺀다.
- **`lib/terminal/`(독립 모듈)**: `local_shell`·`local_shell_finder`·`local_shell_session`·`pty_backend`·`terminal_session`·`terminal_sessions_controller`·`pass_through_cursor`는 workbench 코드 그대로(원본 테스트 15개도 함께). 새로 만들거나 고친 것: `terminal_settings`(글자 크기·스크롤백), `terminal_theme`(ColorScheme·상태색으로 ANSI 16색 — 색 리터럴 없음), `terminal_pane`(앱 전역 단축키 ⌘/Ctrl+`,`·⌘/Ctrl+Shift+O만 셸로 넘김), `terminal_panel`(탭 줄 + 종료 안내 + 다시 시작), `terminal_host`(처음 보일 때 기본 셸을 **저장소 루트**에서 한 번 자동 실행).
- **세션은 셸이 쥔다**: `TerminalSessionsController`를 셸 State 가 가지고 있어서 터미널 패널을 껐다 켜도, 에디터와 전환해도 세션(과 셸 프로세스)이 살아 있다. 탭을 모두 닫으면 다시 자동으로 띄우지 않고 안내만 나온다. 새 탭의 작업 폴더는 그때 열린 저장소 루트다(이미 열린 셸은 자기 폴더 그대로).
- **설정 창**에 "터미널" 구역(글자 크기 슬라이더 — 바로 적용, 스크롤백 — 새 탭부터). 저장 키 `terminal_font_size`·`terminal_scrollback`. workbench 의 "편집기와 같은 글꼴"·글꼴 이름은 내장 에디터가 생기는 단계 15 이후에 다시 본다.
- **빌드 확인**: macOS 디버그 빌드 성공(`flutter_pty.framework`가 앱에 들어간다, `Podfile.lock`·Xcode 프로젝트·Windows `generated_plugins.cmake`가 자동 갱신됨). macOS 릴리스 워크플로의 서명은 `codesign --deep`이라 안쪽 프레임워크까지 서명한다. Windows 설치 프로그램은 빌드 폴더를 통째로(`recursesubdirs`) 담아 DLL 이 포함된다.
- **확인하지 못한 것(알려 둠)**: ① **진짜 셸이 뜨는지는 앱으로 눌러 보지 못했다** — 테스트는 가짜 pty 로 한다. ② **Windows 빌드·실행은 이 컴퓨터에서 할 수 없어 확인하지 못했다**(ConPTY, PowerShell·cmd·WSL 찾기). ③ 한글 IME 는 workbench 에서 고쳐 둔 대로 가져왔을 뿐 이 앱에서 다시 입력해 보지 않았다.
- **패널 닫기 x (사용자 요청)**: 탐색기 머리줄과 가운데(에디터·터미널) 머리줄 오른쪽 끝에 x 단추. 탐색기의 x 는 탐색기를, 가운데의 x 는 **지금 보이는 쪽**만 끈다(둘 다 켜져 있으면 다른 쪽은 남는다). 마지막 패널을 닫으면 도킹 모드로 돌아간다. 둘 다 켜져 있을 때는 전환 단추가 제목을 겸해서(아이콘·제목 글자 생략) 최소 폭(960)에서도 넘치지 않고, 더 좁아지면 전환 단추가 줄어든다.
- 테스트 33개 추가(원본 15 + 패널·호스트·설정 13 + 닫기 x 3 + 열쇠). 전체 634개 통과.

### 단계 15-1 결과 (2026-11-01) — 에디터 이식: 포크와 기본 에디터

단계 15를 나눠서 진행한다 — 15-1 기본 에디터(이 결과), 15-2 문제 표시·변경 표시·찾기 다듬기, 15-3 프로젝트 검색·바꾸기 등 보류분.
- **의존성**: `re_editor`(공용 포크 `jejezz/daylight-editor-flutter`, `v0.10.0+1`)는 workbench 와 같은 **git 의존성**이다 — 복사본을 두지 않는다. 동작을 고치려면 그 저장소에서 고치고 새 태그를 달아 `ref`를 올린다. `re_highlight`도 더했다.
- **`lib/editor/`(독립 모듈)**: `editor_controller`(탭 열기·닫기·순서·저장·디스크 변경 감지)·`editor_tab`·`editor_pane`(탭 줄 + 도구 줄 + 편집 영역 + 변경 배너)·`editor_host`·`editor_theme`·`editor_zoom`·`find_panel`·`file_language`·`dart_highlight`·`dart_chunk_analyzer`·`fold_plan`. workbench 의 `StudioController`에서 **편집기 탭에 해당하는 부분만** 줄여 옮겼다 — 저장소 열기·worktree·최근 프로젝트·git 비교는 여기 없다(저장소는 `Workspace`가 쥔다).
- **되는 것**: 파일을 탭으로 열기(2MB 초과·UTF-8 아님·읽기 실패는 알림), 구문 강조(Dart·YAML·JSON·Markdown 등 20여 종), 줄 번호, 코드 접기(Dart 는 전용 분석기), 찾기·바꾸기(⌘/Ctrl+F, 바꾸기는 ⌘/Ctrl+R), 저장(⌘/Ctrl+S·도구 줄 단추), 고친 탭 닫을 때 저장 확인(취소·저장 안 함·저장), 탭 끌어 순서 바꾸기, 글자 크기 배율(⌘/Ctrl+±·0·휠, 저장 키 `editor_zoom`).
- **디스크 변경 감지**: 열린 탭을 1초마다 확인하고 창에 돌아왔을 때 바로 확인한다. 고치지 않은 탭은 조용히 다시 읽고, **고치던 탭은 덮어쓰지 않고 배너로 고르게 한다**(다시 읽기·내 수정 유지·탭 닫기·그대로 두기). 이 상태에서는 저장도 막는다. 감시는 에디터 패널이 보이는 동안만 돌고, 다시 켜면 바로 한 번 확인한다.
- **파일 열기 규칙(셸 `_openFile` 한 곳)**: **확장 모드이고 "내장 에디터 사용"이 켜져 있으면** 내장 에디터로 열고 꺼져 있던 에디터 패널은 켠다. **도킹 모드이거나 내장 에디터를 껐으면** 외부 편집기(설정의 편집기 명령, 없으면 VS Code). 그래서 도킹 모드의 빠른 열기(⌘⇧O)는 창을 키우지 않는다.
- **세션 유지**: 탭과 고치던 글은 셸이 쥔 `EditorController`에 있어서 에디터 패널을 껐다 켜도, 터미널과 전환해도 남는다.
- **옮기지 않은 것(알려 둠)**: 문제(분석) 표시·변경 표시(gutter)·들여쓰기 선·정의로 이동·Markdown 미리보기·정렬·git 비교(`compareRef`)·편집기 글꼴 이름·줄 간격·합자 설정·프로젝트 검색/바꾸기·심볼 검색. 열어 둔 탭은 앱을 껐다 켜면 사라진다(도킹으로 시작하므로 복원하지 않았다).
- **알려 둠**: 저장하지 않은 수정이 있을 때 **앱을 종료하면 묻지 않고 버려진다**(탭을 닫을 때만 묻는다). 이 보호는 아직 없다. 앱 화면으로 직접 입력·저장해 본 확인은 사용자 몫이다(한글 입력 포함).
- 테스트 32개 추가(컨트롤러 열기·탭·저장·디스크 변경·배율, 탭 줄·저장 확인·배너·알림·배율, 셸 안에서 탐색기 → 에디터). 전체 666개 통과. macOS 디버그 빌드 확인.

### 단계 15-2a 결과 (2026-11-01) — 에디터 부가 기능 첫 묶음

15-2 의 첫 묶음(사용자 지정: "들여쓰기 선·Markdown 미리보기·정렬·저장 시 정렬"). 변경 표시·변경점 보기, 문제(분석) 표시, 프로젝트 검색·바꾸기는 다음 묶음이다.
- **들여쓰기 선**: 들여쓴 줄마다 깊이별 색의 세로선(처음 400줄에서 한 단계 폭을 알아낸다 — 2칸·4칸 모두). 빈 줄은 위아래 중 더 얕은 쪽을 따라 블록 안에서는 이어지고 블록 사이에서는 끊긴다. 색은 ColorScheme·상태색에서 고른다. 설정으로 끌 수 있다(기본 켬).
- **정렬**: Dart 는 `dart format`(편집기의 저장 안 한 글도 임시 파일에 써서 같은 폴더의 `analysis_options.yaml`을 따른다), JSON·ARB 는 들여쓰기 2칸(키 순서·끝 줄바꿈 유지). 도구 줄 단추와 `Ctrl+Alt+L`·`Shift+Alt+F`. 정렬한 글은 **실행 취소할 수 있다**. 실패 이유는 종류(`FormatFailure`)로 돌려주고 화면이 번역한다 — 임시 파일 이름 대신 열린 파일 이름을 보인다.
- **저장할 때 정렬**: 설정(기본 끔). 켜면 Dart·JSON·ARB 를 저장하기 직전에 정렬한다. **문법 오류로 정렬하지 못해도 저장은 한다**.
- **Markdown 미리보기**: 도구 줄의 보기/편집 단추(좁은 폭을 위해 분할 단추 대신 아이콘 하나). 렌더링은 `flutter_markdown_plus`(GitHub 문법), 글자 크기는 편집기 배율을 따르고 상대 경로 그림은 문서 폴더 기준, 웹 주소 링크만 연다. 오류·검색 결과로 줄 이동(`openAt`)하면 미리보기에서 편집으로 돌아온다(커서가 보여야 해서).
- **좁은 폭**: 도구 줄은 가운데가 좁아지는 최소 폭에서 넘치지 않고 가로로 스크롤된다.
- **설정 창** 에디터 구역에 "들여쓰기 선"·"저장할 때 자동 정렬" 스위치. 저장 키 `indent_guides`·`format_on_save`.
- `markdown` 패키지를 직접 의존성으로 올렸다(이미 쓰이던 전이 의존성).
- 테스트 24개 추가(workbench 의 들여쓰기·정렬 테스트를 옮긴 것 포함, 진짜 `dart format` 실행). 전체 690개 통과. macOS 디버그 빌드 확인.
- **알려 둠**: Dart 정렬은 PATH 의 `dart` 를 쓴다(없으면 안내 문구). 앱 화면으로 직접 눌러 본 확인은 사용자 몫이다.

### 패널 너비 조절 (2026-11-01, 사용자 요청)

확장 모드에서 [탐색기] [에디터·터미널] [도크 열] 각각의 너비를 조절한다.
- **조작**: 패널 사이의 구분선(끄는 자리 6px, 위로는 1px 선)을 **끈다.** 마우스를 올리면 선이 굵고 주색이 되고 커서가 좌우 화살표로 바뀐다. **두 번 누르면 기본 너비**로 돌아간다. 구분선은 탐색기|가운데, 가운데(또는 탐색기)|도크 열 두 곳이다. 도킹 모드에는 없다.
- **너비 규칙** (`PanelWidths`): 탐색기 기본 240(최소 160·최대 480), 도크 열 기본 440(최소 380·최대 760), 가운데는 **남는 폭**(최소 270). 원하는 너비는 저장한다(`panel_width_explorer`·`panel_width_dock`, 다음 실행에도).
- **창이 좁아졌을 때**: 저장한 값은 그대로 두고 **보이는 너비만** 최소 너비를 지키는 선에서 줄인다 — 도크 열이 먼저 줄고(왼쪽 영역 최소 폭을 지키게), 그다음 탐색기가 줄어 가운데가 최소 폭을 지킨다. 창이 너무 좁으면 도크 열의 최소 폭을 우선한다. 기본 너비는 확장 최소 창(960)에 모두 들어간다.
- **탐색기만 켠 상태**에서도 도크 열 구분선을 끌 수 있다(탐색기가 남는 폭을 쓴다).
- 구분선은 끄는 도중 현재 **보이는** 너비에서 시작한다(저장값이 아니라) — 줄여서 보이는 상태에서 끌어도 어긋나지 않는다.
- 테스트 15개 추가(계산·저장·끌기·최소/최대·더블클릭 초기화·좁은 창). 기존 테스트 1개는 구분선 폭만큼 위치 기대값을 고쳤다. 전체 703개 통과. macOS 디버그 빌드 확인.
- **알려 둠**: 키보드로 너비를 바꾸는 방법은 아직 없다(끌기·더블클릭만). 앱 화면으로 직접 끌어 본 확인은 사용자 몫이다.

### 열린 파일 보호 (2026-11-01) — 단계 16의 일부를 앞당김

데이터를 잃을 수 있는 두 곳을 먼저 막았다.
- **저장하지 않은 수정이 있을 때 앱 종료 확인**: 창 닫기·⌘Q(Flutter 의 `AppLifecycleListener.onExitRequested`)에서 에디터에 고친 탭이 있으면 **파일 이름을 보이며 묻는다** — 모두 저장하고 종료 / 저장하지 않고 종료 / 취소. 저장하지 못한 파일이 있으면 **종료를 취소**하고 알린다(잃지 않게). 이미 묻는 중에 또 요청이 오면 그 요청은 취소한다. 고친 것이 없으면 묻지 않는다.
- **브랜치·커밋이 바뀐 뒤 열린 파일 정리**(§1.10 확장): HEAD 변화(브랜치 전환·pull·병합 등)가 감지되면 **주기 확인(1초)을 기다리지 않고 바로** 열린 탭을 정리한다. 고치지 않은 탭은 다시 읽고, **이 브랜치에 없는 파일의 고치지 않은 탭은 닫는다**(보기만 하던 탭이라 잃을 것이 없다). **고치던 탭은 닫지도 덮어쓰지도 않고** 배너(다시 읽기·내 수정 유지 등)로 고르게 하며 저장도 막는다. 파일별 알림 대신 **한 번의 요약**("다시 읽음 N개 · 이 브랜치에 없어 닫은 탭 N개 · 고치던 중이라 그대로 둔 파일 N개")만 낸다. 에디터가 보이지 않는 동안 남은 요약은 에디터를 다시 켰을 때 보인다. 평소의 주기 확인은 전과 같다(파일별 알림, 없어진 탭은 남김).
- 테스트 17개 추가(컨트롤러 8·셸 안에서 종료 확인 7·브랜치 전환 2, 진짜 임시 파일). 전체 통과, macOS 디버그 빌드 확인.
- **알려 둠**: ① **Git 칸이 브랜치를 바꾸기 전에 막지는 않는다** — 바꾼 뒤에 정리한다(고친 글은 지켜진다). 전환 전에 "저장하지 않은 수정이 있습니다" 같은 확인을 Git 칸에 넣는 것은 하지 않았다. ② 종료 확인은 macOS 의 창 닫기·⌘Q 로 눌러 확인하는 것은 사용자 몫이고, **Windows 에서 창 닫기가 같은 종료 요청으로 오는지는 확인하지 못했다**. ③ `flutter run` 에서 `q`로 끄는 것은 앱 종료 요청이 아니라 확인 창이 뜨지 않는다.

### 단계 16 결과 (2026-11-01) — 연결

- **패널 단축키 + 충돌 검사**: 위 §1.5. 조합이 서로 겹치지 않고 Branch 칸의 알려진 키(⌘K·J·T·Shift+R·P·Shift+P·Shift+F·B·숫자·F5)와도 겹치지 않음을 `test/shell_shortcuts_test.dart`가 검사한다. 새로 더한 키는 Windows 의 AltGr 충돌을 피해 Alt 조합을 쓰지 않았다.
- **빌드 오류 위치 → 에디터**: 출력 전체 보기(`OutputViewerScreen`)가 `path:줄:칸`, `package:이름/경로:줄:칸`, `file:///…`, MSVC `경로(줄,칸)`을 찾아(`lib/core/output_links.dart`) **실제로 있는 파일만** 밑줄 링크로 보인다(명령을 돌린 폴더는 기록에 없어 선택한 폴더 → 저장소 루트 순으로 찾는다). 누르면 확장 모드·내장 에디터 켜짐이면 내장 에디터의 그 줄·칸, 아니면 외부 편집기: 편집기 명령이 없으면 `vscode://file/경로:줄:칸`, 있으면 파일만 연다(줄 번호를 넘기는 규칙은 편집기마다 달라 정하지 않았다).
- **Git 변경 파일 ↔ 에디터**: `RepoActions.openInEditor`가 셸이 등록한 파일 열기(`Workspace.requestOpenFile`)를 먼저 쓴다 — 탐색기와 같은 규칙. **동작이 바뀐 곳**: 도킹 모드에서 변경 파일을 두 번 누르면 전에는 OS 기본 앱이었고 이제는 편집기 명령/VS Code 다(찾지 못하면 "편집기를 찾을 수 없음" 안내).
- 테스트 약 25개 추가(단축키 11·링크 해석 9·뷰어/열기 8·셸 안 2). 전체 747 통과.
- **알려 둠**: ① 터미널 출력(pty)의 오류 위치는 링크로 만들지 않았다(출력 뷰어만). ② 링크 해석은 공백이 든 경로를 포기한다. ③ Windows 의 `Ctrl+\``·VS Code URL 동작은 못 봤다. ④ 실제 화면 확인은 사용자 몫.

### 단계 17 결과 (2026-11-01) — 릴리스 준비

- README(영/한)에 확장 작업대·선택형 내장 에디터·오류 위치 링크·단축키와 "Daylight Workbench도 대신한다(검증 관문은 가져오지 않음)"를 적었다. 릴리스 점검(`audit_app.py --stage release`) 판정은 "버전만 올리면 진행", 막는 항목은 버전 미상승 하나였고 `0.2.1+6 → 0.3.0+7`로 올렸다(`chore(release): v0.3.0`).
- **남은 순서**: 브랜치 push → PR → `main` 병합 → `v0.3.0` 태그(태그 push 가 릴리스를 배포한다). 푸시·PR·태그는 각각 사용자 확인 뒤에 한다.
- **workbench 보관 안내**: 사용자가 저장소 보관(archive)을 마쳤다. 릴리스 노트에 적을 것 — ① 탐색기·에디터·터미널은 Taskbench의 선택 패널로 이동, ② 병합 전 검증 관문(`verify/`·`merge_gate`)은 가져오지 않았다, ③ 패널 켜짐은 저장하지 않고 항상 도킹으로 시작한다.
- **아직 없는 것**: 확장 모드 스크린샷(README 는 도킹 화면 그대로), Windows 에서의 실제 확인(터미널·종료 확인·창 크기), 에디터 부가 기능(변경 거터·문제 표시·프로젝트 검색·심볼·정의 이동).

### 앱 바 패널 메뉴 → 확장 단추 (2026-11-01, 사용자 제안)

- 패널 드롭다운 메뉴를 없애고 **확장 단추 하나**로 바꿨다: 보이는 패널이 하나라도 있으면 모두 끄고(도킹으로), 없으면 모두 켠다(내장 에디터를 껐으면 에디터 제외). 한 패널만 닫는 일은 각 패널 머리줄의 x 가 맡는다. 단추 설명(툴팁)에 개별 패널 단축키를 적는다. 좁은 막대에서는 "더 보기" 메뉴의 한 항목이다. 알림은 한 번만 보내 창 크기가 여러 번 바뀌지 않는다(`PanelLayout.toggleAll`).

### 시작할 때 깜빡임 수정 (2026-11-01)

- **원인**: macOS 는 `.xib`의 800×600 빈 창이 시작 즉시 보였다가 Dart 가 크기·위치를 바꿨고(`MainFlutterWindow.swift`에 window_manager 의 `hiddenWindowAtLaunch()` 호출이 없었다), Windows 는 `flutter_window.cpp`의 첫 프레임 자동 `Show()`가 남아 Dart 의 배치 전에 1280×720 창이 보였다(`main.dart` 주석이 지우라고 한 줄).
- **수정**: Windows 자동 `Show()` 삭제 — 창은 첫 프레임 뒤 Dart 의 `show()`로만 보인다. macOS 는 창을 **투명(alpha 0)한 채 시작**하고 Dart 가 크기·위치를 정한 뒤 `setOpacity(1)`로 보인다. (처음에는 `hiddenWindowAtLaunch()`로 숨겼는데, 보이지 않는 창은 Flutter 가 프레임을 만들지 않아서 "첫 프레임 뒤에 보이기"가 영영 오지 않았고 `open`으로 켜면 창이 안 떴다 — 실제 실행으로 잡아 고쳤다.) 덧붙여 macOS 는 매번 가운데로 뜨던 것을 **도킹 모드의 창 위치를 기억**(`window_pos_dock`)해 복원하고, 기억한 위치가 어느 모니터에도 안 걸치면 가운데로 둔다.
- 확인함(macOS, `open`으로 켜기): 켜기 → 창 이동 → 종료 → 다시 켜기에서 창이 깜빡임 없이 저장한 위치(120,90)에 바로 뜨고, 저장 위치가 모니터 밖이면 가운데에 뜬다. 창 위치·알파는 `CGWindowList` 폴링으로 쟀다. 확인 못 함: Windows(이 환경에서 빌드도 못 했다).

### 패널 카드 (2026-11-01, 사용자 제안·모서리 14px 확정)

- 탐색기와 가운데(에디터|터미널)를 **도크 열의 칸과 같은 둥근 카드**(`PanelCard`: `GlassCard`, 모서리 14)로 바꿨다. 평평한 패널·구분선은 없앴다(결정 §1.13 의 "workbench 처럼 평평한 패널"을 대체). 창 가장자리(왼쪽·위·아래)와 카드 사이는 8px(`PanelWidths.pad`·`handle`) — **카드 사이의 틈이 곧 크기 조절 손잡이**이고, 올리거나 끌 때만 선이 보인다.
- 계산 변화: `handle` 6→8, `areaMin`에 가장자리 여백 8 추가. 카드 테두리(1px×2)만큼 안쪽 내용은 좁다 — 가운데 최소 폭 기준 테스트를 `minCenter - 2`로 조정.
- 알려 둠: 가운데 카드와 도크 열 사이는 손잡이 8 + 아코디언의 왼쪽 여백 8 = 16 으로 카드 사이(8)보다 넓다 (도크 열을 하나의 덩어리로 보이게 하는 효과도 있다).

### 제목 줄 전체 폭 + 카드 색 통일 (2026-11-01, 사용자 변경)

- **제목 줄(폴더·설정)과 브랜치 줄은 확장 모드에서도 창 전체 폭**으로 맨 위에 둔다. 그 아래에 탐색기 카드 · 가운데 카드 · 도크 열(아코디언)이 나란히 놓인다. 도킹 모드(좁은 창)는 전과 같다. 셸의 `_body(top, accordion)`가 두 모드의 배치를 맡고, 제목 줄과 아코디언에 각각 `GlobalKey`를 달아 모드를 오가도 State 가 유지된다. Git 칸의 "넓은 창 배치" 방지용 `MediaQuery` 크기 덮어쓰기는 아코디언에만 적용한다. 끌어놓기 안내는 이제 두 모드 모두 창 전체에 덮는다.
- **패널 카드는 Git & GitHub 카드와 같은 색 테마**(`GlassCard(active: true)`: 주색 워시·테두리·약한 글로우)를 쓴다. 접힌 Runner 칸은 그대로 차분하다.
- 화면 확인(macOS 다크): 켜기→확장 후 제목 줄 전체 폭, 카드 정렬, 색 일치 확인. 밝은 테마·Windows 는 확인 못 함. 도크 열의 최소 폭 380(제목 줄이 좁아지는 한계에서 정한 값)은 그대로 두었다.

## 6. 위험과 결정이 필요한 것

**위험**

| 위험 | 대응 |
|---|---|
| `command_runner` 두 벌이 296줄 다름 (PATH 해석, 취소, stdin 등) | 2단계에서 두 쪽 테스트를 먼저 모아 돌리고 합친다 |
| 설정 키·ARB 키 충돌 | 접두어 체계(공통 설정 키·문구는 규약 이름 그대로, Dock 고유만 접두어) + 중복 검사 테스트 |
| 색 구성이 화면 일부에만 적용됨 (`AppColors` 직접 사용) | §1.8 테마 읽기 규칙 + 이식 시 치환 + 규칙 테스트 |
| 접힌 Dock이 살아 있어 메모리·타이머가 두 배 | 폴링(기기 감시, git 상태)은 접히면 주기를 늘린다 |
| 단축키 충돌 (`⌘1–7` 등) | §1.5 규칙 + 단축키 표 테스트 |
| 테스트 41개 이식 중 경로·키 변경으로 대량 실패 | 단계 3·4에서 Dock별로 끊어 이식 |
| 확장 모드: 편집 중인 파일이 있는데 브랜치가 바뀜 (저장 안 된 변경 손실·다른 브랜치에 없는 파일) | 단계 16에서 §1.10 정책에 열린 파일 처리를 추가. 저장 안 된 변경이 있으면 전환 전에 알린다 |
| 확장 모드: 도킹↔확장 전환에서 도크 열 상태(펼침·스크롤·실행 중 빌드)가 사라짐 | 단계 11의 완료 조건으로 못 박고 골든·위젯 테스트로 검증 |
| 확장 모드: 터미널의 네이티브 의존(`flutter_pty`)이 macOS·Windows 빌드·서명·설치 프로그램에 영향 | 단계 14에서 두 플랫폼 빌드와 설치 프로그램까지 확인 후에 다음 단계로 |
| 확장 모드: workbench `ui/`의 공용 화면과 에디터 화면이 얽혀 있음 (확인한 것은 파일 단위 참조까지) | 단계 15에서 에디터용·공용으로 나누고, 도크·Git 코드가 에디터를 참조하지 않는 경계 테스트 추가 |

**결정 기록** (✅ = 2026-10-31 사용자 확정)

1. ✅ **"docking 시 무리 없이"** 는 *창을 화면 가장자리에 붙일 때 불편함 없이*(§1.5 해석)로 이해했습니다. 다른 뜻이면 알려 주세요.
2. ✅ 플랫폼은 macOS + Windows만? (예 — Branch의 Linux는 뺌)
3. ✅ Flutty의 **Git 탭 제거**에 동의? (예 — Branch Dock이 대신함)
4. ✅ macOS 서명 시크릿 `🔑` → **설정 창의 구역으로** (앱 바 아이콘 없음; 처음 제안했던 "서명 탭 안"에서 변경)
5. ✅ 기존 두 앱 설정(최근 폴더, 도구 경로)을 첫 실행 때 **가져오기** 할지? (안 함 — 식별자가 달라 샌드박스가 다르고, 최근 목록은 금방 다시 쌓임)
6. ✅ 동시에 **둘 다 펼치기**(분할)는 불필요한가? (불필요 — 요청이 "하나를 전체 화면"이므로)
7. ✅ **칸 이름**: ~~고유 이름(`Rusty Dock` …)~~ → 결정 13으로 대체. Rust 칸은 `Rust Runner`, Electron 칸은 `Electron Runner`.
8. ✅ **실행기 칸 노출 방식**: 감지된 실행기만 칸을 보이기(§4.1 제안) vs 항상 모든 칸을 보이고 감지 안 되면 비활성? (제안: 감지된 것만 — 최소 높이 560에서 칸이 많으면 내용이 좁아지므로)
9. ✅ 확장 대상이 Rust·Electron 외에 더 있는지? → **답: 더 늘어날 수 있음.** 그래서 runner 목록을 열린 구조로 둔다 (§4.1 "칸 추가 절차"). 구체적인 다음 대상은 정해지면 §4 표에 추가
10. ✅ **확정 (2026-10-31)** **비-git 폴더**: 시작 화면은 Branch처럼 *저장소* 열기이므로 git이 아닌 Flutter 폴더는 열리지 않습니다(`git init`을 권유). Flutty만 단독으로 쓰는 경우를 위해 "git 없이 열기"를 허용할까요? (제안: 허용하지 않음 — 공유 영역의 브랜치 줄이 의미를 잃고, 상태가 한 가지 줄어듭니다)
11. ✅ **확정** **편집기 단추의 기본 폴더**: 저장소 루트(제안) vs 내가 고른 폴더 vs 감지된 프로젝트 폴더 — 기본 하나와 ▾ 메뉴로 나머지를 제공하는 §1.9 안으로 괜찮은지?
12. ✅ **확정** **브랜치 전환 중 실행**: Flutty 실행 중 브랜치가 바뀌면 *배너만* 띄우고 중지하지 않는 §1.10 안으로 괜찮은지? (대안: 확인 창으로 중지 여부를 묻기 — 밖에서 바뀐 경우엔 막을 수 없어서 배너를 제안)
13. ✅ **확정 (2026-10-31)** **칸 제목은 하는 일을 보인다**: 원래 앱의 이름(Branch Dock·Flutty Dock)은 사용자에게 의미가 없다. 제목을 `Git & GitHub`, `Flutter Runner`로 바꾸고 새 칸도 `Rust Runner`, `Electron Runner`로 한다 (Android Studio 메뉴가 같은 이름을 쓴다). 앱 이름·식별자·저장소 이름에는 여전히 기술 이름을 넣지 않는다. 내부 id(`branch`·`flutty`·`rust`·`electron`)와 설정 키는 그대로. 이 문서의 화면 그림(§1)과 단계 결과에 남은 "Branch Dock"·"Flutty Dock"은 당시 이름이다.

**확장 모드 결정 (2026-11-01, 사용자 확정 — §1.13)**

14. ✅ 기본은 **도킹 모드**, 탐색기·에디터·터미널 중 하나라도 켜면 **확장 모드**다. 확장 중에는 도킹 모드 전환이 비활성화되고, 모두 끄면 도킹으로 돌아간다. 모드는 패널 상태에서 파생한다.
15. ✅ 가운데 영역은 **에디터 / 터미널 전환형**이다. 전환해도 파일·세션은 유지한다.
16. ✅ 에디터만 끄면 터미널만, 둘 다 끄면 탐색기와 도크 열만 보인다. **도크 열(Git & GitHub, Runner 아코디언)은 두 모드에서 같고** 폭과 무관하게 아코디언을 유지한다. (§1.5 폭 대응표의 "840 이상" 행은 이로써 삭제.)
17. ✅ 에디터는 **선택 기능**이다. 끄면 외부 VS Code로 연다. 빌드는 하나, 실행 중에 결정한다.
18. ✅ 저장소의 **하위 폴더**를 열면 저장소 루트로 연다 (기존 동작 유지).
19. ✅ 저장소가 아니고 하위에 저장소가 여럿이면 **목록을 보여 주고 고르게** 한다. `git init`은 상·하위 어디에도 저장소가 없고 위험한 위치가 아닐 때만 제안한다.
20. ✅ **개발 기반은 taskbench**다. daylight-workbench의 탐색기·에디터·터미널을 확장 패널 모듈로 옮겨 오고, 통합 후 workbench는 보관(archive)한다. 같은 코드를 두 앱이 복사해 따로 고쳐 가는 일을 되풀이하지 않는다 (workbench `lib/branchdock/`와 taskbench `lib/docks/branch/`는 경로가 같은 파일 50개가 하나도 바이트 단위로 같지 않다 — import 경로·접두어 차이만인지 실제 로직 차이인지는 아직 읽지 않았다). 확인 필요: 두 앱의 branch 코드 중 어느 쪽이 최신인지 (단계 착수 전에 diff로 가린다).
21. ✅ **검증 관문(병합 전 로컬 검증 기록)은 가져오지 않는다** (2026-11-01 확정 — 사용자가 쓰지 않음). workbench의 `verify/`·`merge_gate`는 이식 대상에서 제외하고, workbench 보관 시 사라지는 기능으로 릴리스 노트에 적는다. 근거: [docs/WORKBENCH_MERGE.md](docs/WORKBENCH_MERGE.md) §3 B-1.
22. ✅ **아이콘은 taskbench 방식(`Icons.x_rounded`)으로 통일한다** (2026-11-01 확정). workbench의 `context.icons`/`studio_icons`는 가져오지 않고, 에디터·탐색기·터미널·diff 이식 때 해당 파일(약 24개)의 아이콘 호출을 변환한다 (단계 13~15). 근거: [docs/WORKBENCH_MERGE.md](docs/WORKBENCH_MERGE.md) §4-1.
23. ✅ **패널(탐색기·에디터·터미널)의 켜짐은 저장하지 않는다 — 앱은 항상 도킹 모드(기본 화면)로 시작한다** (2026-11-01, 사용자 제안·확정). 저장하는 것은 내장 에디터 설정(`editor_embedded`)과 가운데에서 마지막으로 본 쪽(`panel_center`), 모드별 너비뿐이다. 근거: 켜 둔 채 종료하면 다음 시작이 큰 창으로 열려 좁힐 수 없다는 실사용 지적.
24. ✅ **모드가 바뀌어도 창 높이는 유지한다** (너비만 바뀜). 탐색기를 켠 채 에디터를 켜면 높이가 바뀌던 문제 (사용자 지적).
