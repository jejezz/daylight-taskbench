# Gradle runner 계획 (단계 9, 후보)

> 상태: **계획서만 있음. 코드는 없다.** 순서(Rust·Electron보다 먼저인지)와 §10 질문은 구현을 정할 때 사용자가 답한다.
> 기준 문서: [PLAN.md](../PLAN.md) §4, §1.10 / 같은 구조의 [docs/RUST_RUNNER.md](RUST_RUNNER.md) (겹치는 설명은 여기서 줄이고 그쪽을 가리킨다).

## 0. 이 문서가 기대는 사실

- 칸은 `DockModule`(`isRunner => true`) 하나로 붙인다. `RunnerModule` 인터페이스는 **아직 없다** (RUST_RUNNER §0).
- `ProjectDetector`/`findWithDepth`(`lib/workspace/project_detector.dart`)가 있고, 새 종류는 `detectAt`만 구현하면 된다.
- Flutty가 이미 **adb 기기 목록**(`ProcessDeviceService._android`: `adb devices -l`), **`adb` 도구 경로 등록**(`ToolPaths`), **adb 환경 점검**(`doctor/checks.dart`)을 갖고 있다. Android 칸은 이것과 같은 일을 한다 → **복사하지 않고 공통으로 뽑는다** (§7).
- 실행·취소·출력 스트림은 `FluttyController`에 묶여 있다. Rust 계획의 **`RunSession` 추출(7a)** 이 먼저 끝나 있어야 한다. 이 계획이 Rust보다 먼저 가면 그 추출이 이 계획의 첫 단계가 된다 (§9의 9a).

## 1. 목표와 범위

**목표**: 고른 폴더가 Gradle 프로젝트이면 칸이 켜진다. 모양이 둘이다 (§4.0).
- **Android 앱**이면: 버튼으로 **빌드 · USB 기기에 설치 · 실행 · 테스트 · 린트**.
- **그 밖의 Gradle 프로젝트**(Java·Kotlin JVM, Spring Boot 등)면: `./gradlew tasks`에서 읽은 **작업 선택기**와 바로가기(`build` · `test` · `run`/`bootRun` · `clean`).

어느 쪽이든 출력을 스트림으로 보고, 버튼이 실행할 **정확한 명령을 그대로 보여 준다**. 도구(JDK, Android SDK, Gradle 래퍼)는 사용자가 설치한 것을 쓴다.

**Flutter 칸과의 관계**: Flutter 프로젝트도 `android/` 안에 Gradle 프로젝트를 가진다. 그런 폴더는 **Flutter Runner의 몫**이다 (§3 제외 규칙). Gradle 칸은 *Flutter가 아닌* Gradle 프로젝트 — 네이티브 Android(Kotlin/Java)와 JVM 프로젝트 — 를 위한 것이다.

**하지 않는 것**: Play 스토어 업로드, 키스토어 만들기·관리, AVD(에뮬레이터) 만들기·시작 (이미 떠 있는 에뮬레이터는 `adb`가 보여 주므로 대상으로는 나온다), 디버거, Gradle 스크립트 편집, Kotlin Multiplatform·Compose Multiplatform 데스크톱 타깃, Android Studio·IntelliJ를 대신하는 프로젝트 가져오기, JVM 앱의 디버거·프로파일러, Gradle 플러그인 개발.

## 2. 이름

- id `gradle`, 설정 키 접두어 `gradle.`, ARB 접두어 `gr`.
  - **`test/keys_test.dart`의 허용 접두어 목록에 `gradle.`를 더해야 한다** (지금은 `branch.` `flutty.` `rust.` `electron.` `tool_path_`만 허용).
- 칸 제목 **`Gradle Runner`** (PLAN 결정 13: 하는 일이 보이는 이름. Flutter·Rust처럼 *프로젝트 종류*로 이름 짓는다 — 사용자 결정). 처음 제안한 `Android Runner`는 Flutter Runner도 Android 앱을 빌드·설치하므로 두 칸을 구분해 주지 못해 바꿨다.

## 3. 감지 (`GradleDetector`)

`lib/docks/gradle/detect/gradle_detector.dart`, `kind => 'gradle'`.

프로젝트 후보 조건 (`detectAt(dir)`, 한 폴더만): `settings.gradle` 또는 `settings.gradle.kts`가 있다. (설정 파일 없이 `build.gradle`과 `gradlew`만 있는 단일 프로젝트도 후보로 본다.)

**제외 규칙 (겹침 방지)**: 아래 중 하나면 이 폴더는 **감지하지 않는다**.
- 부모 폴더에 `pubspec.yaml`이 있다 (Flutter의 `android/`).
- 부모 폴더의 `package.json`에 `react-native` 의존성이 있다 (React Native의 `android/`).
- 폴더 이름이 `build`·`.gradle`·`node_modules` (건너뛰는 폴더, 이미 공통 규칙).

**모양 판정 (칸 안에서, 감지 뒤)**: `DetectedProject`는 종류 공통 최소 정보라 모양을 담지 않는다. 칸이 프로젝트를 읽어 정한다.
- 모듈 목록은 `include(":app", ":feature:x")` / `include ':app'` 줄에서 읽는다. 읽지 못하면 `app/`을 시험한다 (Android Studio 기본 구조).
- 어떤 모듈의 `build.gradle(.kts)`에 `com.android.application`(`id("com.android.application")`, `alias(libs.plugins.android.application)` 포함)이 있으면 **Android 앱** 모양 — 그 모듈들이 실행 대상이다. 라이브러리 모듈(`com.android.library`)은 목록에서 뺀다.
- 없으면 **일반 Gradle** 모양. `application` 플러그인·`org.springframework.boot` 플러그인이 있으면 `run`/`bootRun` 바로가기를 켠다.

`findWithDepth`는 depth 0 → 1이므로 "프로젝트 루트에서 연 경우"와 "그 위 폴더(`~/work`)에서 연 경우 `myapp/`이 depth 1에서 잡히는 경우" 둘 다 된다. 여럿이면 칸 머리 드롭다운 + `gradle.project_choice:<dir>`.

`DetectedProject`: `name`은 `rootProject.name`(없으면 폴더 이름), `version`은 앱 모듈의 `versionName` 또는 루트의 `version =`(있으면). 읽기는 **한 줄 단위의 가벼운 파싱**이다. Groovy/Kotlin DSL을 해석하지 않는다 — 못 읽는 경우는 칸 안에서 "읽지 못했습니다(이유)"로 보이고, 단추는 막히지 않는다(직접 입력).

## 4. 칸의 화면

### 4.0 두 모양

Flutty와 같은 틀: 칸 머리(프로젝트 드롭다운 · 버전 · 칩 — `Android` 또는 `JVM`) + 탭.
- **Android 앱 모양**: **Run · Devices · Doctor · Log**. Devices는 Flutty 탭을 **같은 위젯으로 공유**한다 (§7).
- **일반 Gradle 모양**: **Run · Doctor · Log** (기기가 없다). Run 탭은 §4.1b.

### 4.1 Android 앱의 Run 탭

1. **모듈**: 앱 모듈이 하나면 숨기고, 둘 이상이면 드롭다운 (`:app`, `:wear` …).
2. **변형(variant)**: `빌드 타입(debug/release/…) × flavor`. 처음엔 파일에서 읽은 목록으로 즉시 보이고, "정확한 목록 불러오는 중…"으로 `./gradlew :<module>:tasks --group=install -q`를 **한 번 백그라운드에서** 돌려 정확한 `install<Variant>` 목록으로 바꾼다 (Gradle 설정 단계라 느림 → 칸이 처음 펼쳐질 때, 폴더·브랜치별 캐시). 실패하면 파일 읽기 결과를 그대로 쓰고 칸은 계속 쓸 수 있다.
3. **대상 기기**: `adb` 기기 목록에서 선택 (USB · 무선 · 에뮬레이터). 마지막 선택은 프로젝트별 기억 (`gradle.project_device:<dir>`).
4. **동작** (분할 단추): `Install & run`(기본) · `Install` · `Assemble`(APK만) · `Bundle`(AAB, release만) · `Test` · `Lint` · `Clean`.
5. **고급**(접힘): `--offline`, `--stacktrace`, `--no-daemon` 토글, 추가 인자 한 줄, 환경 변수는 만들지 않는다(YAGNI).
6. **명령 미리보기**: 실제로 실행될 전체 명령(들)을 항상 보이고 복사 가능. 예: `./gradlew --console=plain :app:installDebug` → `adb -s <id> shell monkey -p com.example.app -c android.intent.category.LAUNCHER 1`. Windows는 `gradlew.bat`.
7. **실행/중지** + 단계 상태 칩 + 출력(스트림). 끝나면 산출물 위치(`app/build/outputs/apk/debug/…`)와 **폴더 열기** 단추.

**`Install & run` = 두 단계**: ① `installDebug`(Gradle이 빌드까지 한다) ② `adb shell monkey -p <applicationId> … 1`로 실행 (런처 Activity 이름을 몰라도 되는 가장 단순한 방법).
- `applicationId`는 `build.gradle`의 `applicationId "…"`/`applicationId = "…"`에서 읽고, 못 읽으면 설치 뒤 기기에서 `adb shell pm list packages -3`을 비교하는 대신 **빌드된 APK에서** `aapt2 dump packagename`으로 읽는다(빌드 도구가 있을 때). 둘 다 안 되면 실행 단계는 건너뛰고 "설치만 했습니다" 안내.
- 변형에 `applicationIdSuffix`(`.debug`)가 있으면 그것을 붙인다.

옵션 저장: `gradle.options:<dir>` JSON, 모르는 필드는 버리고 읽는다.

### 4.1b 일반 Gradle의 Run 탭

1. **작업 선택기**: `./gradlew tasks --all -q`(설정 단계라 느림 → 칸이 처음 펼쳐질 때 백그라운드, 폴더·브랜치별 캐시)로 읽은 작업을 그룹별로 검색해 고른다. 읽는 동안·실패했을 때는 바로가기만 보인다.
2. **바로가기**: `build` · `test` · `check` · `clean` · (`application`이면 `run`, Spring Boot면 `bootRun`).
3. **프로젝트** 드롭다운(`:app`, `:core` …): 고르면 `:<project>:<task>`로 만든다.
4. **고급**: `--offline` · `--stacktrace` · `--no-daemon` · `--continue`, 추가 인자 한 줄.
5. 명령 미리보기·실행/중지·출력은 §4.1과 같다. `run`/`bootRun`은 오래 도는 프로세스이므로 중지 단추가 핵심이다.

### 4.2 Gradle 출력

- 항상 `--console=plain`을 붙인다 (진행 막대의 ANSI·덮어쓰기 출력 방지).
- 처음 실행은 Gradle 배포판·의존성을 내려받아 몇 분 걸린다. **출력이 한동안 없어도** "Gradle이 준비 중입니다 (처음 한 번은 몇 분)" 표시를 띄운다 (출력 없이 N초 지나면).
- 실패 처방(`explainFailure` 방식, 원문 텍스트 매칭): `SDK location not found` → Doctor의 SDK 항목, `Failed to install the following Android SDK packages … license` → 라이선스 명령 복사, `Unsupported class file major version`/`requires Java 17` → JDK 항목, `Could not resolve …` → `--offline` 끄기·네트워크, `Keystore file … not found` → 서명 안내, `INSTALL_FAILED_*` → 기기 항목(저장 공간·서명 충돌·USB 설치 허용).

### 4.3 Devices 탭 (Android 앱 모양만)

Flutty의 기기 탭에서 **Android 부분만** 보이는 같은 위젯 (iOS·데스크톱은 이 칸에선 숨김). 승인 대기(`unauthorized`)·USB 디버깅 안내 문구도 그대로.

### 4.4 Doctor 탭

| 항목 | 방법 | 실패 시 |
|---|---|---|
| JDK (모든 모양) | `java -version`, `JAVA_HOME`, `gradle.properties`의 `org.gradle.java.home`, Android Studio 내장 JDK(`…/jbr`) 후보 | 설치/경로 안내. **Gradle·AGP가 요구하는 JDK 대응표는 작게 하드코딩한 "힌트"** 로만 쓴다 (AGP 8.x → 17 등), 틀릴 수 있다고 표시 |
| Android SDK 위치 (Android만) | `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `local.properties`의 `sdk.dir`, 기본 설치 위치(macOS `~/Library/Android/sdk`, Windows `%LOCALAPPDATA%\Android\Sdk`) | 어디서 찾았는지 보이고, 없으면 `local.properties` 줄을 복사할 수 있게 |
| `compileSdk`용 플랫폼·빌드 도구 (Android만) | `platforms/android-<N>`, `build-tools/` 폴더 존재 | `sdkmanager "platforms;android-N"` 명령 복사 |
| SDK 라이선스 (Android만) | `licenses/` 폴더에 필요한 해시 파일 있음 | `sdkmanager --licenses` 복사 |
| `adb` (Android만) | Flutty와 같은 항목 (공통) | 〃 |
| Gradle 래퍼 | `gradlew(.bat)` + `gradle/wrapper/gradle-wrapper.properties` | 없으면 시스템 `gradle`을 쓸지 묻고, 명령 미리보기에 어느 쪽인지 보인다 |
| 릴리스 서명 (Android만) | `release` 변형을 골랐을 때만: `signingConfigs`에 release 언급 + 키스토어 파일 존재 | 경고 (막지 않음) |
| 프로젝트 읽힘 | 모듈·변형 파싱 성공 여부 | 첫 오류 줄 |

브랜치가 바뀌면 "오래된 값" 표시 (Flutty `diagnosticsStale`과 같은 규칙).

### 4.5 접힌 제목 · 색 · 바쁨

- `summary`: Android 앱 `debug · Pixel 7` / 실행 중 `installing · Pixel 7`, 일반 Gradle `build` / 실행 중 `bootRun`, 실패 `build failed`.
- `mood`: working > failed > warning(Doctor 문제·오래된 점검·기기 없음) > success > idle.
- `busy`: 명령이 도는 동안. `appliesTo`: `projects.isNotEmpty`.

## 5. 브랜치 전환 (§1.10 약속)

Rust 계획 §5와 같다. 추가로 Android만의 것:
- 브랜치마다 **모듈 목록·변형·`applicationId`가 다를 수 있다** → 캐시한 변형 목록과 `applicationId`를 버리고 다시 읽는다. 저장된 변형이 사라졌으면 기본(debug)으로 돌리고 한 번 알린다.
- 실행 중이면 **중지하지 않고** 배너만. Gradle은 소스를 읽으며 진행하므로 결과가 섞일 수 있다는 점을 배너 문구에 적는다.
- `build/` 산출물은 브랜치를 넘어 남는다 — 이상한 빌드 오류가 나면 `Clean` 단추를 처방으로 권한다 (Flutty의 `cleanProject` 처방과 같은 생각).

## 6. 설정 · 도구 경로 · PATH

- 키: `gradle.last_tab_id`, `gradle.action:<dir>`, `gradle.options:<dir>`, `gradle.project_choice:<dir>`, `gradle.project_device:<dir>`.
- 도구 경로: `adb`는 Flutty가 이미 등록(`ToolPaths.register`는 중복을 무시). 새로 `java`(JDK), `sdkmanager`, `aapt2`는 **Doctor가 SDK 위치에서 찾아 쓰고**, 설정 창에는 `java`만 줄을 더한다 (SDK 도구는 SDK 경로 하나로 충분).
- **PATH/환경**: Gradle은 `JAVA_HOME`·`ANDROID_HOME`을 환경에서 읽는다. GUI로 연 앱은 셸 환경을 못 받으므로, 실행할 때 **우리가 찾은 JDK/SDK 경로를 환경 변수로 넣어 준다** (`environment:` 인자). 이 값은 명령 미리보기 옆에 "환경: JAVA_HOME=…, ANDROID_HOME=…"로 **보인다** (숨은 마법이 되지 않게). `platform-tools`는 `command_runner`가 이미 후보에 넣는다.

## 7. 공통으로 뽑을 것 (Flutty를 건드리는 부분)

| 추출 | 지금 | 뽑은 뒤 |
|---|---|---|
| **adb 기기 목록·파싱** | `ProcessDeviceService._android`, `parseAdbDevices` 류 (`flutty/devices/`) | `lib/core/adb/adb_devices.dart`. Flutty는 여기서 가져다 쓴다 |
| **기기 감시** | Flutty 컨트롤러가 폴링 | **한 곳의 `DeviceWatcher`** (칸이 둘 이상 구독하면 폴링은 하나, 접힌 칸은 주기를 늘림 — PLAN §6 위험표의 약속). 두 칸이 같은 `adb`를 따로 두드리지 않게 |
| **Devices 탭 위젯의 Android 부분** | `flutty/ui/devices_tab.dart` | `core/ui/`로 옮겨 두 칸이 쓴다 (iOS·데스크톱 섹션은 Flutty에 남김) |
| **adb 점검 항목** | `flutty/doctor/checks.dart` | `core/doctor/adb_check.dart` |
| **`RunSession`** | (Rust 7a) | 이 칸도 그 위에 올린다 |

원칙은 Rust 계획과 같다: **추출은 동작 변경 없이 먼저 하고, Flutty 테스트를 고치지 않고 통과하는 것이 증거다.**

## 8. 테스트 계획

| 파일 | 내용 |
|---|---|
| `test/gradle/gradle_detector_test.dart` | 앱 모듈 있음/없음, `.kts`와 Groovy, 라이브러리 모듈 제외, **Flutter·React Native의 `android/` 제외**, depth 0→1, 깨진 파일 |
| `test/gradle/gradle_parse_test.dart` | `include` 줄, `buildTypes`/`productFlavors`, `applicationId`/`namespace`/`versionName`, `compileSdk` — Groovy·Kotlin DSL·버전 카탈로그 별칭 샘플 |
| `test/gradle/command_plan_test.dart` | 옵션·변형·기기 → 명령줄(들). flavor+buildType 이름 조합(`installFreeDebug`), Windows `gradlew.bat`, `--console=plain`, 환경 표시 |
| `test/gradle/doctor_test.dart` | 가짜 `CommandRunner`·임시 SDK 폴더로 항목별 결과, 라이선스 폴더, `local.properties` |
| `test/gradle/failure_hint_test.dart` | 실제 Gradle 오류 문구 샘플 → 처방 |
| `test/gradle/gradle_dock_test.dart` | 감지 → `appliesTo`, 브랜치 전환 시 캐시 폐기·배너, `mood`/`busy`/`summary` |
| `test/core/adb_devices_test.dart` | 추출한 파싱 (기존 `banner_adb_test`·`devices_tab_test`는 **수정 없이** 통과) |
| `test/dock_contract_test.dart`, `keys_test.dart`, `theme_rules_test.dart` | 자동 |

수동(자동화 어려움): 실제 USB 폰/에뮬레이터에 설치·실행, 첫 실행 Gradle 다운로드 중 화면 반응, `Install & run`이 `applicationIdSuffix`가 있는 프로젝트에서 맞는 패키지를 띄우는지, 중지가 Gradle 클라이언트를 끝내는지(데몬은 남음), Windows 경로.

## 9. 단계

| 단계 | 내용 | 기준 |
|---|---|---|
| **9a** 공통 추출 | (Rust 7a가 안 끝났다면) `RunSession` 추출 + `DeviceWatcher`·adb 파싱·Devices 탭·adb 점검 공통화 | 기존 Flutty 테스트 **수정 없이** 통과 |
| **9b** 감지·뼈대 | `GradleDetector`(제외 규칙 포함), 가벼운 Gradle 파서, `GradleDock` 빈 몸통, 레지스트리 한 줄, `gradle.` 키 접두어 허용, ARB `ad` | 계약 테스트 통과, Flutter 폴더에선 켜지지 않음 |
| **9c** Run 탭 | 변형·기기·동작·명령 미리보기·실행/중지·출력·산출물 열기 | 예제 프로젝트에서 Install & run |
| **9d** Doctor·도구 | JDK/SDK/라이선스/래퍼 점검, 환경 변수 주입, 실패 처방 | JDK·SDK 없는 컴퓨터에서 안내가 정확 |
| **9e** 연결 | 브랜치 전환, 접힌 제목·색·busy, `Stop daemons`(`./gradlew --stop`) | 접힌 채 빌드가 계속되고 전환 배너가 뜬다 |
| **9f** 마무리 | README 기능 줄, 스크린샷·GIF, PLAN "단계 9 결과", 릴리스 점검 | `check_readme.py`·감사 `go` |

릴리스는 사용자 기능 추가이므로 **minor**. 빈 칸 안내(`dockNoProjectBody`)는 "지원하는 프로젝트(Flutter, Gradle …)"로 고친다.

## 10. 사용자에게 묻는 것

1. ~~범위와 이름~~ → **확정: `Gradle Runner`**, Android 앱 흐름 + 일반 Gradle 작업 선택기 (§4.0). 새 질문: JVM 쪽 첫 버전을 바로가기만으로 제한할까, 작업 선택기(§4.1b)까지 넣을까? (제안: 둘 다 — 선택기는 `tasks` 출력 파싱뿐이라 비용이 작다)
2. **Logcat 탭**을 첫 버전에 넣을까? (제안: 나중. 넣으면 `adb logcat` 스트림·필터·상한이 필요해 한 단계가 늘어난다)
3. **에뮬레이터 시작**(`emulator -avd`)? (제안: 첫 버전은 제외 — 떠 있는 것만 대상으로 보인다)
4. **릴리스 서명**: 키스토어를 건드리지 않고 Gradle이 실패하면 처방만 보여 주는 것으로 충분한가? (제안: 예)
5. **`Bundle`(AAB)과 산출물 폴더 열기**를 첫 버전에 넣을까? (제안: 둘 다 넣는다 — 비용이 작다)
6. **Flutter·React Native의 `android/` 제외**(§3)에 동의하는가? (제안: 예. Flutter는 Flutter Runner가 맡는다)
7. **순서**: Android를 Rust·Electron보다 앞에 둘까? (참고: Android는 Flutty와 겹치는 부분이 커서 `DeviceWatcher` 공통화가 실제로 쓰이는 첫 사례가 된다. 사용 빈도도 Rust보다 높다고 판단하면 앞에 두는 것이 합리적)

## 11. 위험

| 위험 | 대응 |
|---|---|
| Gradle DSL을 정확히 해석할 수 없다 (Groovy/Kotlin/버전 카탈로그/`apply from`) | 가벼운 파싱은 **칸을 켜고 초기 목록을 보이는 용도**로만. 정답은 Gradle 자신(`tasks --group=install`)이고, 둘 다 안 되면 직접 입력 |
| 설정 단계가 느려 UI가 멈춘 듯 보임 | 백그라운드 + "불러오는 중" + 캐시. 칸이 처음 펼쳐질 때만 시작 (지연 시작) |
| Gradle 데몬이 남아 메모리를 쓴다 | 중지는 클라이언트만 끈다고 UI에 밝히고 `Stop daemons`를 제공 |
| JDK/AGP 대응표가 낡는다 | 하드코딩은 작게, "힌트"로 표시. 틀려도 실행은 막지 않는다 |
| 두 칸(Flutter·Android)이 같은 `adb`를 동시에 두드림 | `DeviceWatcher` 공유 + 접힌 칸은 주기 연장 |
| Flutter 프로젝트에서 Android 칸이 켜져 혼란 | §3 제외 규칙 + 테스트 |
| 환경 변수 주입이 사용자의 셸 설정과 달라 "내 터미널에선 되는데" | 주입한 값을 미리보기에 그대로 보이고, 설정 창에서 `java` 경로를 지정할 수 있게 |
