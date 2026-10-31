<!-- From jejezz/application-release-templates common/tool/readme @ conventions-v1.
     tool/readme/init_readme.py가 만든 파일입니다 — conventions/readme-guide.md 참고.
     {{TODO: …}}를 모두 채우십시오. 하나라도 남아 있으면 tool/readme/check_readme.py가 실패합니다. -->

<p align="center">
  <img src="assets/icon/app_icon.png" width="128" alt="Daylight Taskbench 아이콘">
</p>

<h1 align="center">Daylight Taskbench</h1>

<p align="center">
  편집기 옆에 세워 두는 **Flutter 앱용 GitHub 작업대** — Git·GitHub 도구와 실기기 빌드·설치를 한 창에서.
</p>

<p align="center">
  <a href="https://github.com/jejezz/daylight-taskbench/releases/latest"><img src="https://img.shields.io/github/v/release/jejezz/daylight-taskbench?style=flat-square&color=4c9dff" alt="최신 릴리스"></a>
  <a href="https://github.com/jejezz/daylight-taskbench/releases"><img src="https://img.shields.io/github/downloads/jejezz/daylight-taskbench/total?style=flat-square&color=7c5cff" alt="다운로드"></a>
  <img src="https://img.shields.io/badge/platform-macOS%20%C2%B7%20Windows-34d399?style=flat-square" alt="macOS · Windows">
  <img src="https://img.shields.io/badge/built%20with-Flutter-02569b?style=flat-square" alt="Flutter">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/jejezz/daylight-taskbench?style=flat-square" alt="MIT 라이선스"></a>
</p>

<p align="center">
  <a href="README.md">English</a> · <b>한국어</b>
</p>

<p align="center">
  <img src="docs/screenshots/demo.gif" width="720" alt="Daylight Taskbench 데모: 저장소를 열고 Branch Dock과 Flutty Dock을 오가는 흐름">
</p>

## 기능

- **폴더 하나, Dock 둘** — Git 폴더를 한 번 고르거나 끌어다 놓으면 공유 막대에 폴더, 현재 브랜치, "편집기에서 열기"가 나오고 두 Dock이 모두 따라갑니다. 앱 안에서든 터미널에서든 브랜치를 바꾸면 두 Dock이 함께 갱신됩니다.
- **Branch Dock: Git·GitHub** — 변경과 커밋 상자, 브랜치, 태그, 원격, 안내식 릴리스 흐름, PR, CI 실행, 기록 그래프, 충돌·임시 저장 복구. 실제 `git`과 `gh`를 실행하고 명령을 그대로 보여 줍니다.
- **Flutty Dock: 실기기 빌드·설치** — 폴더(또는 한 단계 아래)에서 Flutter 프로젝트를 찾아 USB iPhone, Android 폰, 이 컴퓨터에 빌드·설치하고, 실행 중에는 핫 리로드를 보냅니다. 점검 탭이 Flutter, Xcode, adb, 서명 인증서·프로파일을 확인합니다.
- **도킹을 위한 창** — 편집기 옆에 세우는 440×960 창(최소 380×560)이고 위치를 기억합니다. 실행기 Dock(Rust, Electron 등)은 레지스트리에 한 줄이면 더해집니다.
- **라이트·다크, 한국어·English** — 시스템 설정을 따르거나 설정에서 고릅니다 (색 구성, 글자 크기, 고대비)

<p align="center">
  <img src="docs/screenshots/home.png" width="360" alt="공유 막대 아래의 Branch Dock (라이트·다크)">
  <img src="docs/screenshots/detail.png" width="360" alt="Flutty Dock: Flutter 프로젝트의 빌드·실행 옵션">
</p>

## 설치

[**Releases**](https://github.com/jejezz/daylight-taskbench/releases/latest)에서 받습니다.

| OS | 파일 |
|---|---|
| macOS 12.0 이상 | `DaylightTaskbench-<버전>-macos-universal.dmg` — 열어서 앱을 Applications 폴더로 끌어다 놓으세요 |
| Windows 10/11 (x64) | `DaylightTaskbench-<버전>-windows-x64-setup.exe` |

**Windows:** 설치 프로그램에 아직 코드 서명이 없어서 SmartScreen이 "Windows의 PC 보호" 창을 띄웁니다. **추가 정보 → 실행**을 누르세요.

## 동작 방식

Daylight Taskbench는 Git이나 Flutter 도구를 다시 만들지 않습니다. 설치된 `git`, `gh`, `flutter`, `adb`를 실행하고 그 출력을 보여 줄 뿐입니다. 하나의 워크스페이스 객체가 저장소의 HEAD를 지켜보다가 브랜치, 커밋, 병합 상태가 바뀌면 접혀 있는 Dock까지 모두에게 알립니다. 이미 실행 중인 빌드는 브랜치를 바꿔도 멈추지 않고 알림만 띄웁니다.

## 개발

```bash
flutter pub get
flutter run -d macos
```

Flutter(stable)가 필요하고, Dock이 쓰는 `git`과 선택적으로 `gh`, `flutter`, `adb`가 PATH에 있어야 합니다 (경로는 설정 → 도구에서 지정할 수 있습니다). macOS와 Windows만 지원합니다. 설계와 결정: [PLAN.md](PLAN.md).

릴리스: `scripts/bump-version.sh patch` → 병합 → `vX.Y.Z` 태그. CI가 모든 플랫폼을 빌드해서 올립니다. 규칙: [application-release-templates/conventions](https://github.com/jejezz/application-release-templates/tree/main/conventions).

## 크레딧

- 글꼴: [서울남산체](https://www.seoul.go.kr/seoul/font.do) (서울특별시)
- 아이콘: [Icons8](https://icons8.com)

## 라이선스

[MIT](LICENSE) © 2026 Jongyun Ahn
