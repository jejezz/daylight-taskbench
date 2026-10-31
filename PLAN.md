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
│ ▣ my_app ▾                      ⟳  📌  ⚙  ⓘ           │ ① 디렉터리 바      높이 44
│ ⎇ feature/login ▾  ↑2 ↓0 ● 변경 3          [ </> VS ] │ ② 브랜치 줄        높이 32
├────────────────────────────────────────────────────────┤
│ ▾ ⎇ Branch Dock                                        │ ③ 제목 (눌러서 펼침) 높이 40
│ ┌────────────────────────────────────────────────────┐ │
│ │ (Branch Dock 내용 — 펼쳤을 때 남는 높이 전체)      │ │ ④ 내용
│ └────────────────────────────────────────────────────┘ │
│ ▸ ▶ Flutty Dock    my_app · iPhone 15 · Debug          │ ③ 제목 (접힘)
└────────────────────────────────────────────────────────┘
```

- **① 디렉터리 바**: 왼쪽 = 디렉터리 이름(누르면 최근 목록 · 폴더 열기 ⌘O · 저장소 닫기 · 창 붙이기, 툴팁에 전체 경로). 오른쪽 = 아이콘(새로 고침 · 항상 위 · 설정 · 정보). 폴더 끌어다 놓기는 창 전체가 받고 이 영역이 반응한다 (§1.11).
- **② 브랜치 줄**: 현재 브랜치 칩(누르면 브랜치 빠른 전환), `↑↓`·변경 수 pill, 오른쪽 끝 **편집기에서 열기** 단추. 자세한 동작은 §1.9.
- **③ 제목 + ④ 내용 = 아코디언(스택 카드)**: 제목은 항상 보이고 **제목을 누르면 그 내용이 남는 화면 전체로 펼쳐진다. 동시에 하나만 펼친다** (다른 쪽은 제목 한 줄로 접힘). 제목 순서는 고정(Branch 위, Flutty 아래) — 펼쳐도 제목이 자리를 바꾸지 않는다.
- 접힌 제목에도 **한 줄 요약**을 보여 줘서 펼치지 않고도 상태를 안다.
- 지금은 칸이 둘이지만 Rust·Electron runner가 더 붙는다 (§4). 칸은 `DockModule` 목록이고, 실행기 칸은 **그 디렉터리에서 프로젝트가 감지될 때만** 제목이 나타난다. 그림의 두 칸은 "Branch + Flutter 프로젝트" 경우다.

### 1.2 두 가지 상태

**A. Branch Dock 펼침** (기본) — 공유 영역은 그대로, 아래만 바뀐다

```
│ ▣ my_app ▾                                  ⟳ 📌 ⚙ ⓘ  │
│ ⎇ feature/login ▾  ↑2 ↓0 ● 변경 3          [ </> VS ] │  ← 공유
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
│ ▣ my_app ▾                                  ⟳ 📌 ⚙ ⓘ  │
│ ⎇ feature/login ▾  ↑2 ↓0 ● 변경 3          [ </> VS ] │  ← 공유 (같은 내용)
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

- 기본 **440×960**, 최소 **380×560**. 최소 높이(560)에서도 `76(공유 두 줄) + 40+40(제목 둘) + 내용 ≥ 400`이 남는다 (560−76−80 = 404) (아래 §1.7 검증 항목).
- **크기·위치 기억** 필수 (`window-placement.md`의 `placeWindowAtStartup` 규칙, 모니터가 사라진 경우 기본 위치로).
- **화면 가장자리에 붙이기**(오른쪽/왼쪽), **항상 위**(핀). 두 앱에 있던 `dockWindow`/`DockSide`를 하나로 합친다.
- 도킹/해제, 모니터 이동, 창 크기 변경 중에 **펼침 상태·스크롤·입력 중 값이 사라지지 않는다**: 접힌 Dock도 위젯을 살려 둔다(`Offstage` + `TickerMode`로 애니메이션만 끔). 빌드 중인 Flutty를 접어도 프로세스와 출력은 계속된다.
- 폭 대응:

  | 폭 | 배치 |
  |---|---|
  | 380–839 | 위 골격 그대로 (아코디언) |
  | 840 이상 `P2` | 아코디언 유지하되 내용 최대 폭 제한 + 좌우 여백. 좌우 2열은 하지 않는다 (요구는 "한 번에 하나 전체 화면") |

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
| **편집기에서 열기** (②, 오른쪽 끝) | `</>` 아이콘 단추. 툴팁에 **실제로 실행될 명령** | 설정한 편집기(없으면 VS Code)로 폴더를 연다. 찾지 못하면 설치 링크만 보여 준다 (Branch 동작 그대로) |

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
- 최소 높이 계산: `76 + 40 × (칸 수) + 내용 ≥ 400`. 칸이 3개면 364px, 4개면 약 324px — 최소 높이 560에서 불충분해지면 **제목 줄을 36으로 줄이는 밀도 단계**를 둔다(§1.7 검증에 칸 4개 케이스 추가).

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

- 앱 이름은 `Daylight Taskbench`라 문제 없다. 칸 제목과 소개 문구에서 "Rust", "Electron"은 **기술 이름을 설명하려는 용도**로만 쓰고, 칸의 고유 이름은 Flutty처럼 따로 짓는다 (`Flutty Dock`이 Flutter 상표를 피한 것과 같은 방식). 이름 후보는 아래 §6 질문.
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
| **7. Rust runner** (확장) | `RunSession` 추출 → Rust 감지·칸·설정 구역·환경 점검(cargo/rustup) | 별도 계획서 `docs/RUST_RUNNER.md`를 먼저 쓰고 승인 후 시작 |
| **8. Electron runner** (확장) | Electron 감지·칸·스크립트 실행·패키징 | 〃 `docs/ELECTRON_RUNNER.md` + `RunnerModule` 모양 재검증 |

단계 1을 먼저 하는 이유: 기능은 이미 있으므로 틀릴 수 있는 것은 **화면**이다. 자리표시자 셸로 구성을 먼저 눈으로 확정하고 나서 기능을 채운다.

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

**결정 기록** (✅ = 2026-10-31 사용자 확정)

1. ✅ **"docking 시 무리 없이"** 는 *창을 화면 가장자리에 붙일 때 불편함 없이*(§1.5 해석)로 이해했습니다. 다른 뜻이면 알려 주세요.
2. ✅ 플랫폼은 macOS + Windows만? (예 — Branch의 Linux는 뺌)
3. ✅ Flutty의 **Git 탭 제거**에 동의? (예 — Branch Dock이 대신함)
4. ✅ macOS 서명 시크릿 `🔑` → **설정 창의 구역으로** (앱 바 아이콘 없음; 처음 제안했던 "서명 탭 안"에서 변경)
5. ✅ 기존 두 앱 설정(최근 폴더, 도구 경로)을 첫 실행 때 **가져오기** 할지? (안 함 — 식별자가 달라 샌드박스가 다르고, 최근 목록은 금방 다시 쌓임)
6. ✅ 동시에 **둘 다 펼치기**(분할)는 불필요한가? (불필요 — 요청이 "하나를 전체 화면"이므로)
7. ✅ **칸 이름**: Rust 칸·Electron 칸의 고유 이름은? 제안 — 임시로 `Rusty Dock`, `Volt Dock`(Flutty/Branch와 같은 `-y`/`Dock` 계열). 상표를 직접 쓰지 않는 이름이면 무엇이든 가능. (정해질 때까지는 코드·ARB에 `rust` / `electron` id만 쓰고 표시 이름은 나중에.)
8. ✅ **실행기 칸 노출 방식**: 감지된 실행기만 칸을 보이기(§4.1 제안) vs 항상 모든 칸을 보이고 감지 안 되면 비활성? (제안: 감지된 것만 — 최소 높이 560에서 칸이 많으면 내용이 좁아지므로)
9. ✅ 확장 대상이 Rust·Electron 외에 더 있는지? → **답: 더 늘어날 수 있음.** 그래서 runner 목록을 열린 구조로 둔다 (§4.1 "칸 추가 절차"). 구체적인 다음 대상은 정해지면 §4 표에 추가
10. ✅ **확정 (2026-10-31)** **비-git 폴더**: 시작 화면은 Branch처럼 *저장소* 열기이므로 git이 아닌 Flutter 폴더는 열리지 않습니다(`git init`을 권유). Flutty만 단독으로 쓰는 경우를 위해 "git 없이 열기"를 허용할까요? (제안: 허용하지 않음 — 공유 영역의 브랜치 줄이 의미를 잃고, 상태가 한 가지 줄어듭니다)
11. ✅ **확정** **편집기 단추의 기본 폴더**: 저장소 루트(제안) vs 내가 고른 폴더 vs 감지된 프로젝트 폴더 — 기본 하나와 ▾ 메뉴로 나머지를 제공하는 §1.9 안으로 괜찮은지?
12. ✅ **확정** **브랜치 전환 중 실행**: Flutty 실행 중 브랜치가 바뀌면 *배너만* 띄우고 중지하지 않는 §1.10 안으로 괜찮은지? (대안: 확인 창으로 중지 여부를 묻기 — 밖에서 바뀐 경우엔 막을 수 없어서 배너를 제안)
