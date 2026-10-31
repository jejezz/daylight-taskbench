# Daylight Taskbench

Flutter 앱을 GitHub에서 만들고 굴리는 도킹형 데스크톱 작업대 (macOS / Windows). 편집기 옆에 세로로 세워 두고
**한 저장소(폴더)** 를 기준으로 Git·GitHub 도구(**Branch Dock**)와 실기기 빌드·설치(**Flutty Dock**)를
아코디언 칸으로 번갈아 펼쳐 쓴다. 이후 Rust runner, Electron runner 등 실행기 칸을 더 꽂을 수 있게 설계한다.
daylight-commander 계열 앱. 처음 작업 이름은 Fig(Flutter in GitHub)였고 어디에도 남기지 않는다.

릴리스·버전·패키징·정보 창·아이콘·라이선스·UI/UX·글꼴·언어·테마는
https://github.com/jejezz/application-release-templates/tree/main/conventions
규약을 따른다. 이 앱에 적용된 규약 버전: conventions-v1

- 표시 이름 `Daylight Taskbench`, 파일 이름 `DaylightTaskbench`, 패키지 `daylight_taskbench`,
  식별자 `art.zoomon.daylighttaskbench` (macOS Debug 빌드는 `.dev`), 저장소 `daylight-taskbench`.
  식별자와 `installer/windows/app.iss`의 `AppId`는 릴리스 후 바꾸지 않는다.
- 이름에 "Flutter"·"GitHub"·"Git"·"Rust"·"Electron"을 넣지 않는다 (상표). 설명 문구에서만 쓴다.
- 원본 앱 branch-dock-flutter, flutty-dock-flutter는 **수정하지 않는다.** 필요한 코드는 이 프로젝트로 복사해서
  쓴다 (daylight-workbench와 같은 방식). 달라진 곳은 코드에 `[Taskbench에서 달라진 곳]` 주석으로 표시한다.
- **계획과 화면은 [PLAN.md](PLAN.md)가 기준이다.** 이어서 작업할 때 먼저 읽는다 (화면 §1, 합치기 §3, 확장 §4, 단계 §5, 결정 기록 §6).
  현재 단계: 0 완료(골격), 1 완료(셸: 시작 화면·공유 영역·아코디언·설정 창·장식) 2 완료(공통 코어: command_runner 합집합·도구 경로·키 검사) 3 완료(Branch Dock 이식) 4 완료(Flutty Dock 이식) 5 완료(연결) → 6(릴리스 준비).
- 플랫폼은 macOS + Windows (Linux 없음). 릴리스 워크플로에서도 build-linux 잡을 뺐다.
- macOS 샌드박스는 꺼져 있다 (`app-sandbox=false`) — git/gh/flutter를 호출하고 임의 폴더를 연다.
- 창은 도킹형 세로 창(440×960, 최소 380×560)이다. 크기·위치를 기억한다.
- 작업은 브랜치 → 커밋 → 사용자 확인 후 `main` 병합. push는 요청받을 때만.

## 테마 규칙

- 색·글꼴·간격 값은 `lib/theme/`에만 둔다. 화면 코드는 `Colors.*`, `AppColors.*`를 직접 쓰지 않고
  `Theme.of(context)`(`colorScheme`, `dividerColor`)에서 읽는다 (settings.md "색을 테마에서 읽기").

- 설정 규약은 `settings.md`와 `settings-screen.md`가 어긋난다 — 충돌한 곳은 `settings.md`/`localization.md` 쪽을 따랐다 (PLAN.md "단계 1 결과").
- 새 칸(runner)은 `lib/docks/registry.dart`에 한 줄 + `test/dock_contract_test.dart` 통과로 붙인다.
- 위젯 테스트 함정: 실제 파일 I/O 는 `tester.runAsync` 안에서, 포커스된 TextField 가 있으면 `pumpAndSettle` 대신 `pump` (안 그러면 테스트가 멈춘다).
