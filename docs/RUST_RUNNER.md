# Rust runner 계획 (단계 7)

> 상태: **계획서만 있음. 코드는 아직 한 줄도 없다.** 사용자 확인을 받은 뒤 §9 순서로 만든다.
> 기준 문서: [PLAN.md](../PLAN.md) §4 (확장), §1.10 (브랜치 전환). 이 문서는 §4를 **지금 코드에 맞춰** 구체화한다.

## 0. PLAN §4와 지금 코드의 차이 (먼저 바로잡을 것)

PLAN §4.1은 `RunnerModule`, `RunSession` 같은 이름을 썼지만 단계 1~6에서 실제로 만든 것은 더 작다.
이 계획은 **실제 코드를 기준**으로 한다.

| PLAN §4의 말 | 실제 코드 | 이 계획의 결정 |
|---|---|---|
| `RunnerModule extends DockModule` (`targets`, `profiles`, `capabilities`, `doctor`) | 없음. `DockModule.isRunner => true`만 있다 (`lib/docks/dock_module.dart`) | **만들지 않는다.** Rust가 두 번째 구현이지만 Flutty와 모양이 아직 다르다(§7). 세 번째(Electron) 때 겹치는 부분만 올린다 |
| `ProjectDetector` + `DetectedProject` | 있다 (`lib/workspace/project_detector.dart`, `findWithDepth`, `FlutterDetector`) | `CargoDetector`를 같은 모양으로 더한다 |
| `RunSession` 공통 추출 | 없음. 실행·취소·키 입력이 `FluttyController.start/cancel/sendKey`에 들어 있다 | Rust 칸을 만들기 **전에** 먼저 추출한다 (§7, 단계 7a) |
| 공통 UI를 `core/ui/`로 | 출력 뷰어·복사 버튼·명령 표시는 이미 `lib/core/ui/`. **기록 탭(`LogTab`)은 아직 Flutty 안** | 기록 탭도 `core/ui/`로 옮긴다 (7a) |
| 빈 칸 안내 | `RunEmptyDock`의 `dockNoProjectBody`는 "Flutter 프로젝트를 찾지 못했습니다"만 말한다 | 문구를 "지원하는 프로젝트(Flutter·Rust)"로 고친다 (ko·en) |

## 1. 목표와 범위

**목표**: 공유 영역에서 고른 폴더가 Rust 프로젝트(`Cargo.toml`)이면 아코디언에 Rust 칸이 켜지고,
`cargo`의 build · run · test · check · clippy · fmt를 **버튼으로 실행하고 출력을 스트림으로 본다.**
Branch · Flutty와 같은 원칙을 지킨다: 버튼이 실행할 **정확한 명령을 그대로 보여 준다**, 도구는 사용자가
설치한 것을 호출한다(번들 없음).

**하지 않는 것 (범위 밖)**: 크레이트 게시(`cargo publish`), `cargo install` 관리, 디버거, rust-analyzer,
`cargo watch` 류 자동 재실행, 원격·컨테이너 빌드, 툴체인 설치(안내만), Cargo.toml 편집기.

## 2. 이름

- 칸 id는 `rust` (설정 키 접두어 `rust.`, 저장된 펼침 상태, ARB 접두어 `rd`). 키 접두어 `rust.`는
  `test/keys_test.dart`가 이미 허용한다.
- **칸 제목은 상표를 직접 쓰지 않는 이름**이어야 한다 (PLAN §4.4). 임시 후보 `Rusty Dock`. 확정 전까지 코드·ARB의
  표시 문자열은 한 곳(`dockRustTitle`)에만 둬서 이름만 바꾸면 되게 한다. → §10 질문 1.
- 설명 문구(README·칸 안내)에서만 "Rust", "Cargo"를 기술 이름으로 쓴다.

## 3. 감지 (`CargoDetector`)

`lib/docks/rust/cargo/cargo_detector.dart`, `kind => 'cargo'`. `detectAt(dir)`은 한 폴더만 본다.
depth 0 → 1 규칙은 `findWithDepth`가 이미 처리한다 (`target`·`node_modules`·`build`·`dist`와 점 폴더는 건너뜀).

| 경우 | 판정 |
|---|---|
| `Cargo.toml`에 `[package]`가 있다 | 프로젝트. `name`·`version`은 `[package]`에서 |
| `Cargo.toml`에 `[workspace]`만 있다 (가상 워크스페이스) | **프로젝트 하나**로 본다. 이름은 폴더 이름, 버전 없음. 멤버는 칸 안에서 고른다 (§4) |
| `[workspace]`와 `[package]`가 둘 다 있다 | 루트 패키지가 있는 워크스페이스 — 프로젝트 하나, 멤버 목록에 루트 포함 |
| `Cargo.toml`이 있지만 깨져서 읽을 수 없다 | 프로젝트로는 잡되(칸이 켜짐), 칸 안에 "Cargo.toml을 읽지 못했습니다 + 이유"를 보인다. 조용히 사라지지 않게 |

- 이 단계의 파싱은 **가벼운 TOML 읽기**(섹션 헤더와 `name`/`version` 한 줄)만 한다. 새 의존성(`toml` 패키지)은
  꼭 필요해질 때까지 넣지 않는다. 자세한 구조(bin·feature 목록)는 `cargo metadata`가 있을 때 거기서 얻는다 (§4).
- **겹치는 감지**: `gui/pubspec.yaml`(Flutter)이 있는 Rust 저장소는 두 칸이 같이 켜진다 (PLAN §4.2, 의도한 동작).
  `src-tauri/Cargo.toml`을 가진 Electron·Tauri 폴더에서도 Rust 칸이 depth 1에서 켜진다 — 이것도 그대로 둔다
  (실제로 그 안에 Rust 프로젝트가 있으므로).
- 같은 종류가 depth 1에서 여럿이면 칸 머리 드롭다운에서 고르고 폴더별로 기억한다 (`rust.project_choice:<dir>`).

## 4. 칸의 화면

Flutty와 같은 틀: 칸 머리(프로젝트 드롭다운 · 버전 · 상태 칩) + 탭. 탭은 셋이다 —
**Run · Doctor · Log** (`rust.last_tab_id`에 이름으로 저장, Flutty와 같은 방식).

### 4.1 Run 탭

위에서 아래로:

1. **동작**: `Build` `Run` `Test` `Check` `Clippy` `Fmt` 중 하나 (분할 단추). 기본은 마지막에 쓴 것 (`rust.command:<dir>`).
2. **대상**: 워크스페이스면 패키지(`-p`) 드롭다운(기본 "전체"), bin이 둘 이상이면 `--bin` 드롭다운,
   `Run`에서만 `--example` 선택 가능.
3. **프로필**: Debug / Release / (사용자 정의 프로필이 `Cargo.toml`에 있으면 그 이름들). `--release` 또는 `--profile <이름>`.
4. **고급** (접힘): feature 체크 목록 + `--all-features` / `--no-default-features`, 대상 triple(`--target`,
   `rustup target list --installed`에서), `--` 뒤에 붙일 프로그램 인자, 환경 변수 두 개의 토글(`RUST_BACKTRACE=1`,
   `RUST_LOG` 값) — 값은 폴더별로 저장.
5. **명령 미리보기**: 지금 설정이 만들 **실제 명령줄 전체**를 항상 보여 주고 복사할 수 있다 (`core/ui/command_text`).
   버튼을 누르면 정확히 이 명령이 실행된다 (Flutty `InstallPlan`이 단계 목록을 그대로 실행하는 것과 같은 원칙).
6. **실행/중지 단추** + 단계 상태 칩 + **출력 영역**(스트림, `core/ui/output_viewer`). 끝나면 종료 코드와 걸린 시간.
7. 실패했을 때 처방 한 줄(`explainFailure`와 같은 방식): `linker not found`, `could not find Cargo.toml`,
   `error: no such command: clippy` → Doctor 탭의 해당 항목으로 가는 링크.

옵션 저장: `rust.options:<dir>` 한 키에 JSON (Flutty `flutty.build_options:<dir>`와 같은 방식, 폴더마다 따로).
모르는 필드는 버리고 읽는다 (버전이 올라가도 깨지지 않게).

**왜 `Run`이 따로 "빌드+실행"이 아닌가**: `cargo run`이 이미 빌드까지 한다. 그래서 Flutty의 `RunPhase`
(빌드/실행 분리)는 가져오지 않는다. 단계는 대부분 명령 하나다 — `Test`만 `--no-run` 옵션 없이 하나로 둔다.

### 4.2 Doctor 탭 (환경 점검)

`core/ui/check_tile`로 항목을 보여 준다. 항목은 한 번에 읽고, 브랜치가 바뀌면 "오래된 값"으로 표시한다
(Flutty `diagnosticsStale`과 같은 규칙).

| 항목 | 방법 | 실패 시 안내 |
|---|---|---|
| `cargo` · `rustc` 있음/버전 | `cargo --version`, `rustc --version` | rustup 설치 링크 (자동 설치하지 않음) |
| 툴체인 | `rustup show active-toolchain` (rustup이 없으면 항목 생략) | `rustup default stable` 명령을 보여 줌(복사만) |
| `clippy` · `rustfmt` 구성요소 | `cargo clippy --version`, `cargo fmt --version` | `rustup component add clippy rustfmt` 복사 |
| 설치된 triple | `rustup target list --installed` | 크로스 빌드를 고른 경우에만 경고 |
| 링커/빌드 도구 | macOS: `xcode-select -p`. Windows: `where link.exe` 또는 `vswhere`로 MSVC Build Tools | 설치 안내 링크 |
| `Cargo.toml` 읽힘 | `cargo metadata --no-deps --format-version 1` 성공 여부 | 오류 첫 줄 |
| `Cargo.lock` | 파일 있음 (`--locked` 쓸 때만 의미) | 정보 수준 |

### 4.3 Log 탭

앱 전체 `CommandLog`를 보여 주는 지금의 Flutty `LogTab`을 `lib/core/ui/`로 옮겨 **두 칸이 같은 위젯을 쓴다** (7a).
기록은 칸이 아니라 앱 단위이므로 Rust 명령도 Flutty 명령도 한 목록에 섞여 쌓인다. 문제가 되면(구분이 필요하면)
항목에 칸 id를 붙여 거른다 — 지금은 만들지 않는다.

### 4.4 접힌 제목 · 색 · 바쁨

- `summary`: 한 줄. 예: `debug · my_bin` / 실행 중 `running · my_bin` / 실패 `check failed`.
- `mood`: Flutty와 같은 우선순위 — 일하는 중(working) > 실패(failed) > 경고(warning) > 성공(success) > 쉼(idle).
  경고 = Doctor에 문제가 있음 또는 브랜치가 바뀐 뒤 아직 안 읽은 점검.
- `busy`: 명령이 도는 동안 true (점이 깜빡이고, 다른 저장소를 열 때 확인을 받는다 — 기존 규칙).
- `appliesTo`: `projects.isNotEmpty`.

## 5. 브랜치 전환 (§1.10 약속)

`RustDock.onHeadChange`는 **접혀 있어도** 불린다. 하는 일:

1. `CargoDetector`로 다시 찾는다. 브랜치마다 `Cargo.toml`이 있거나 없을 수 있다 → 칸이 켜지고 꺼질 수 있다.
2. 캐시된 `cargo metadata`(bin·feature·멤버 목록)를 **버린다** — 다른 브랜치에선 목록이 다르다. 저장된 옵션 중
   더 이상 없는 bin·feature는 조용히 빼고 칸에 "바뀐 브랜치에 없어 뺐습니다"를 한 번 보여 준다.
3. Doctor 결과를 "오래된 값"으로 표시.
4. 명령이 **실행 중이었다면 중지하지 않는다.** 배너 "빌드/실행 중 브랜치가 `X`로 바뀌었습니다"만 띄운다
   (`branchChangedWhileRunning`, 확정된 결정 12번). `cargo`는 파일을 읽으며 진행하므로 중간에 소스가 바뀌면
   결과를 믿을 수 없다는 점을 배너 문구에 적는다.
5. 병합/리베이스 같은 작업이 진행 중일 때(`operationInProgress`) Run 단추는 경고를 단다 — 충돌 표식이 든
   소스를 빌드해 헛걸음하지 않게. 막지는 않는다.

## 6. 설정 · 도구 경로 · PATH

- 키: `rust.last_tab_id`, `rust.command:<dir>`, `rust.options:<dir>`, `rust.project_choice:<dir>`. 보간 키는
  `prefix + path`로 쓴다 (keys_test 규칙). 설정 구역은 **만들지 않는다** — 칸 고유 설정이 아직 없다.
- 도구: `ToolPaths.register(ToolSpec('cargo','cargo'))`, `rustup`, `rustc`는 설정 창 "도구" 구역에 줄이 생긴다
  (Flutty의 `configurableTools` 방식). 공통 키 `tool_path_cargo` 등.
- **PATH 함정**: Finder·시작 메뉴에서 연 GUI 앱은 셸 PATH를 못 받는다. 이미 macOS는 로그인 셸 PATH를 읽지만
  (`resolvePath`), `~/.cargo/bin`은 후보 목록(`_commonToolDirs`)에 없다. 로그인 셸이 못 읽는 경우를 위해
  macOS `$HOME/.cargo/bin`, Windows `%USERPROFILE%\.cargo\bin`(그리고 `CARGO_HOME`이 있으면 그 `bin`)을 후보에 더한다.
  → `command_runner`의 변경이므로 **공통 테스트(`command_runner_test`)에 케이스를 더하고** 한다.
- Windows에서 `cargo.exe`는 `runInShell`로 도는 지금 경로를 그대로 타면 된다. `flutter`처럼 Git Bash를 거칠 필요 없음.

## 7. 공통 추출 — `RunSession` (단계 7a, Rust 코드보다 먼저)

Rust를 Flutty 복사본으로 만들면 실행·취소·출력 처리가 두 벌이 된다. 그래서 **먼저 Flutty에서 뽑는다.**
동작은 바뀌지 않아야 하고, Flutty 테스트가 그 증거다.

`lib/core/run_session.dart` (이름 확정 전 임시):

- 입력: 단계 목록(`args`, `workingDirectory`, `environment`, `interactive`), `CommandRunner`.
- 하는 일: 단계를 차례로 실행, 단계별 상태(`StepStatus`: pending/running/done/failed/cancelled), 하나 실패하면 중단,
  `cancel()`, `sendKey()`, 실행 파일 없음(127) 감지, 실패 원문(`combined`)을 처방 함수에 넘기기.
- **Flutty에 남는 것**: `InstallPlan`(어떤 단계를 만들지), 기기 목록, 서명, `explainFailure`, `RunPhase`.
- **Rust가 쓰는 것**: 단계 한 개짜리 목록 + 출력 스트림. 핫 리로드 같은 `sendKey`는 안 쓴다.

두 가지 새 문제를 이때 함께 푼다:

1. **긴 출력**: `cargo build`는 수천 줄을 낸다. 지금 `CommandLogEntry.append`는 끝없이 쌓고 청크마다
   `log.update()`로 화면을 다시 그린다. → 항목 출력에 **상한(예: 마지막 2 MB만 유지)** 과 갱신 묶기(예: 100 ms에 한 번)를 넣는다.
   Flutty에도 이득이다. 상한에 걸리면 "앞부분 N줄 생략" 표시를 남긴다.
2. **중지의 의미**: `RunHandle.cancel()`은 `Process.kill()`로 `cargo` 프로세스만 죽인다. macOS에서 `cargo run`은
   자식 바이너리가 따로 돌 수 있고, Windows에서는 `cargo`가 자식을 띄우므로 **자식이 고아로 남는다.**
   → Windows는 `taskkill /T /F /PID`, macOS는 프로세스 그룹에 시그널을 보내는 방식을 `RunHandle`에 더한다.
   Flutty의 `flutter run`에도 같은 문제가 있을 수 있으므로 이 수정은 공통이고, 수동으로 확인한다(§8).

기록 탭을 `core/ui/`로 옮기는 일도 7a에 넣는다 (§4.3).

## 8. 테스트 계획

기존 원칙: 실제 파일 I/O는 `tester.runAsync`, 포커스된 TextField가 있으면 `pump`, 프로세스를 띄우는 코드는 칸이 **처음 펼쳐질 때** 시작(지연 시작 — fake zone의 타이머 문제).

| 파일 | 내용 |
|---|---|
| `test/rust/cargo_detector_test.dart` | 패키지 / 가상 워크스페이스 / 둘 다 / 깨진 파일 / depth 0 → 1 / `target` 건너뜀 / Flutter와 같은 폴더에서 둘 다 켜짐 |
| `test/rust/command_plan_test.dart` | 옵션 → 명령줄 (모든 조합: `-p`, `--bin`, `--example`, 프로필, features, `--target`, `--` 인자). 명령줄 인용(공백·특수문자) |
| `test/rust/run_options_test.dart` | JSON 저장·복원, 모르는 필드 무시, 사라진 bin·feature 정리 |
| `test/rust/doctor_test.dart` | 가짜 `CommandRunner`로 항목별 성공/실패/도구 없음, 오래된 값 표시 |
| `test/rust/rust_dock_test.dart` | 감지 → `appliesTo`, 브랜치 전환 시 재감지·캐시 폐기, 실행 중 전환 배너, `mood`/`busy`/`summary` |
| `test/run_session_test.dart` | 추출한 코어: 순서, 실패 중단, 취소, 127, 긴 출력 상한 |
| `test/dock_contract_test.dart` | `createDocks()`에 한 줄 더하면 자동으로 받는다 (id 유일, 접혀도 `onHeadChange` 수신) |
| 기존 `test/flutty/*` | **7a에서 한 줄도 고치지 않고 통과해야 한다** (추출의 증거) |
| `test/keys_test.dart`, `theme_rules_test.dart` | 새 키·색 규칙을 자동으로 검사 |
| `test/command_runner_test.dart` | `~/.cargo/bin` 후보, 프로세스 그룹/트리 종료 |

수동 확인(자동화 어려움): 실제 `cargo`가 있는 컴퓨터에서 작은 예제 크레이트로 build/run/test/clippy, Run 중 중지가
자식 프로세스까지 끝내는지(macOS·Windows 각각), Windows에서 링커 없음 메시지, 긴 빌드 출력 중 창이 얼지 않는지.

## 9. 단계 (각 단계 끝에 `flutter analyze` + 전체 테스트, 사용자 확인 후 다음)

| 단계 | 내용 | 끝났다고 보는 기준 |
|---|---|---|
| **7a** 공통 추출 | `RunSession` 추출, `LogTab`을 `core/ui/`로, 출력 상한·갱신 묶기, 중지가 자식까지 닿게 | 기존 Flutty 테스트 **수정 없이** 통과 + 새 `run_session_test` |
| **7b** 감지 · 뼈대 | `CargoDetector`, `RustDock` 빈 몸통, 레지스트리 한 줄, `rust.*` 키, ARB 접두어, 칸 이름 자리, `dockNoProjectBody` 문구 | 계약 테스트 통과, Rust 폴더를 열면 칸 제목이 켜진다 |
| **7c** Run 탭 | 옵션 모델 · 명령 미리보기 · 실행/중지 · 출력 · 실패 처방 | 예제 크레이트로 build/run/test가 돈다 |
| **7d** Doctor 탭 · 도구 경로 | 점검 항목, `cargo`·`rustup` 도구 경로, PATH 후보 | 도구가 없는 컴퓨터에서 안내가 정확하다 |
| **7e** 연결 | 브랜치 전환(§5), 접힌 제목·색·busy, 배너 | 접힌 채 빌드가 계속되고 전환 배너가 뜬다 |
| **7f** 마무리 | README(영·한) 기능 줄, 스크린샷/GIF 갱신, PLAN.md "단계 7 결과", CLAUDE.md 단계 줄, 릴리스 점검 | `check_readme.py` 통과, 릴리스 감사 `go` |

릴리스: 칸 하나가 늘어나는 사용자 기능이므로 **0.2.0**(minor). 7f 뒤에 `release/v0.2.0` → PR → 병합 → 확인 후 태그.

## 10. 사용자에게 묻는 것 (코딩 전에 정해야 함)

1. **칸 이름**: 임시 `Rusty Dock`. 상표를 직접 쓰지 않는 이름이면 무엇이든 가능. (Branch/Flutty와 같은 `-y`·`Dock` 계열 권장)
2. **첫 버전의 동작 범위**: 위 6개(Build·Run·Test·Check·Clippy·Fmt) 모두 넣을까, 아니면 Build·Run·Test로 시작할까?
   (제안: 6개 — 단추 하나 늘리는 비용이 작고 명령 조립 코드는 같다.)
3. **크로스 빌드 `--target`**: 첫 버전에 넣을까 (제안: 넣는다, 고급 접힘 안에. 설치 안 된 triple은 Doctor가 경고).
4. **워크스페이스**: 멤버를 `-p` 드롭다운으로 고르는 정도면 충분한가, 멤버별로 탭/요약을 따로 보이길 원하는가? (제안: 드롭다운만)
5. **Run 기본 프로필**: Debug(제안 — `cargo run` 기본과 같음) vs Flutty처럼 Release 기본.
6. **7a 먼저**: 공통 추출(7a)을 Rust 코드보다 앞서 별도 커밋으로 끝내는 순서에 동의하는가? (제안: 예 — Flutty 동작을 건드리는 위험을 Rust와 섞지 않으려고)
7. **Tauri 같은 혼합 프로젝트**: `src-tauri/Cargo.toml`이 있으면 Rust 칸이 켜지는 것(§3)으로 괜찮은가?

## 11. 위험

| 위험 | 대응 |
|---|---|
| 추출(7a)이 Flutty를 깨뜨림 | 동작 변경 없이 옮기고, 기존 Flutty 테스트를 고치지 않는 것을 기준으로 삼는다. 실패하면 되돌린다 |
| 중지가 자식 프로세스를 못 끝내 고아 프로세스 | 플랫폼별 종료 방법 + 수동 확인. 못 끝내면 UI에 "백그라운드에 남았을 수 있음"을 숨기지 않고 보인다 |
| 긴 출력으로 화면이 느려짐 | 출력 상한 + 갱신 묶기 (7a) |
| `Cargo.toml` 가벼운 파싱이 특수 문법에서 틀림 | `cargo metadata`가 되면 그것을 정답으로 쓰고, 파싱은 칸을 켤지 정하는 최소한으로만 쓴다 |
| 칸이 늘어 최소 높이 560에서 좁아짐 | 칸 셋(Branch·Flutty·Rust)이 동시에 켜지는 경우를 `shell_test`의 380×560 케이스에 추가 (PLAN §4.1 밀도 단계 검토) |
| PATH에 cargo가 없어 "도구 없음"으로 오해 | `~/.cargo/bin` 후보 추가 + 설정 창에서 경로 지정 + Doctor가 어디서 찾았는지 표시 |
| Electron 때 인터페이스가 맞지 않음 | `RunnerModule`을 아직 만들지 않으므로 고칠 것이 적다. Electron 단계에서 두 구현의 공통만 올린다 |
