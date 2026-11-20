# Node runner 계획 (단계 8)

> 상태: **계획서만 있음. 코드는 없다.** §10 결정은 2026-11-20 확정, 구현은 보류.
> 기준 문서: [PLAN.md](../PLAN.md) §4, §1.10 / 같은 구조로 이미 만든 [Gradle Runner](GRADLE_RUNNER.md), [Avalonia Runner](AVALONIA_RUNNER.md) (겹치는 설명은 줄이고 그쪽을 가리킨다).
> 이 문서는 PLAN.md §4의 "Electron runner"를 **Node runner**로 넓혀 대체한다 (PLAN.md 결정 26).

## 0. 이 문서가 기대는 사실

- 칸은 `DockModule`(`isRunner => true`) 하나로 붙인다. 감지는 `findWithDepth`/`detectAt`(`lib/workspace/project_detector.dart`), 실행·중지·출력은 `core/run_session.dart`(`RunSession`)와 `killProcessTree`를 쓴다. 모두 Gradle·Avalonia 칸이 이미 쓰고 있다 → **공통 추출이 따로 필요 없다.**
- 설정 창에 도구 경로 줄을 더하는 방법(`ToolPaths.register`), 접힌 칸의 `summary`/`mood`/`busy`, 브랜치 전환 배너(§1.10)는 Gradle 칸과 같다.
- 구조 원칙도 같다: **화면에 보이는 명령이 곧 실제로 실행되는 명령이다.** 칸이 접혀 있어도 실행은 이어진다.

## 1. 목표와 범위

**목표**: 고른 폴더가 Node 프로젝트(`package.json`)이면 칸이 켜진다. `package.json`의 `scripts`를 읽어 **실행 · 빌드 · 패키징 · 테스트 · 점검** 단추로 묶어 보여 주고, 어떤 스크립트든 목록에서 골라 돌릴 수 있다. 출력은 스트림으로 보고, 버튼이 실행할 **정확한 명령을 그대로 보여 준다.** Node·패키지 매니저는 사용자가 설치한 것을 쓴다.

**왜 Electron이 아니라 Node인가**: `package.json` 하나로 Electron 앱, Vite·Next 같은 웹 프런트엔드, Express 같은 서버, 일반 CLI를 모두 같은 방식으로 다룰 수 있다. Electron은 칸이 아니라 **프로젝트 종류(§3.2)** 로 취급해, 패키징 산출물 폴더 열기·환경 점검 같은 Electron 전용 동작만 그 안에서 켠다. (Avalonia가 .NET 칸 안의 종류인 것과 같은 생각.)

**하지 않는 것**: 스크립트·`package.json` 편집, 의존성 추가·삭제·업데이트 관리(`npm install`만 단추로 둔다), 디버거·프로파일러, 코드 서명·공증(키·인증서를 건드리지 않는다 — Gradle 결정 4와 같은 이유), npm 레지스트리 로그인·`publish`, Node 버전 관리자(nvm·fnm·volta) 설치·전환, React Native·Tauri·Deno 프로젝트 전용 지원 (`package.json`이 있으면 *일반 Node*로는 다뤄지지만 전용 바로가기는 없다), monorepo 도구(turbo·nx) 전용 기능.

## 2. 이름

- id `node`, 설정 키 접두어 `node.`, ARB 접두어 `nd` (구현 때 기존 키와 겹치지 않는지 확인).
  - **`test/keys_test.dart`의 `_dockPrefixes`에서 예약해 둔 `electron.`을 `node.`로 바꾼다.**
- 칸 제목 **`Node Runner`** (PLAN 결정 13: 하는 일이 보이는 이름. 상표인 `Electron`·`Node.js` 공식 로고·이름 변형은 앱 이름·식별자에 넣지 않는다 — 제목에는 기능을 알리는 용도로만).
- 코드 `lib/docks/node/`, 테스트 `test/node/`.

## 3. 감지 (`NodeDetector`)

`lib/docks/node/detect/node_detector.dart`, `kind => 'node'`.

### 3.1 켜지는 조건 (`detectAt(dir)`, 한 폴더만)

폴더 바로 아래에 `package.json`이 있고, 읽을 수 있는 JSON 객체이며, 아래 중 하나를 만족한다.
- `scripts`에 항목이 하나 이상 있다, 또는
- §3.2의 알려진 의존성(electron·vite·next 등)이 `dependencies`/`devDependencies`에 있다.

`scripts`도 알려진 의존성도 없는 `package.json`(라이브러리 메타데이터만 있는 것)은 감지하지 않는다 — 칸이 할 일이 없다.

**제외 규칙 (겹침 방지)**
- 같은 폴더에 `pubspec.yaml`이 있다 → Flutter Runner의 몫 (Flutter 프로젝트 루트의 도구용 `package.json`).
- 폴더 이름이 `node_modules`·`dist`·`build`·`out`·`release`·`.git` (이미 공통 건너뛰기 규칙에 없는 것은 추가).
- `package.json`에 `react-native` 의존성이 있으면 감지는 하되 **종류 칩에 "React Native"** 를 보이고 전용 바로가기는 켜지 않는다 (Gradle 칸은 그 `android/`를 이미 제외한다).

`findWithDepth`가 depth 0 → 1이므로 프로젝트 루트에서 연 경우와, 그 위 폴더에서 연 경우 `app/`·`desktop/`이 depth 1에서 잡히는 경우 둘 다 된다. 여럿이면 칸 머리 드롭다운 + `node.project_choice:<dir>`. **workspaces monorepo**는 루트 `package.json`만 잡는다 (하위 패키지는 depth 0에서 이미 잡혔으므로 찾지 않는다). 하위 패키지를 고르는 기능은 만들지 않는다 (§10 결정 4).

### 3.2 프로젝트 종류 (칸 안에서, 감지 뒤)

`DetectedProject`는 종류 공통 최소 정보라 종류를 담지 않는다. 칸이 `package.json`을 읽어 정한다 (위에서 아래, 처음 맞는 것).

| 종류 | 판정 (`dependencies` + `devDependencies`) | 칩 |
|---|---|---|
| **Electron** | `electron` | `Electron` |
| **웹 프런트엔드** | `vite`·`next`·`nuxt`·`astro`·`react-scripts`·`@angular/cli`·`@sveltejs/kit`·`webpack-dev-server`·`parcel` | `Web` |
| **서버** | `express`·`fastify`·`koa`·`@nestjs/core`·`hono` | `Server` |
| **React Native** | `react-native` | `React Native` |
| **일반 Node** | 위에 없음 | `Node` |

- 종류는 **어떤 스크립트를 기본으로 고를지, 어떤 보조 단추를 켤지** 만 정한다. 모든 종류에서 스크립트 목록·실행은 같다.
- `name`은 `package.json`의 `name`(없으면 폴더 이름), `version`은 `version`(있으면).
- 읽기는 `json.decode` 한 번이다. 깨진 JSON이면 칸은 켜지고 "읽지 못했습니다(이유)"를 보인다.

## 4. `package.json`에서 명령을 알아내는 방법

`package.json`에는 "이것이 실행 명령"이라는 표시가 없다. 그래서 **이름과 값으로 역할을 추정하고, 확신이 없으면 사용자가 목록에서 고른다.** 추정은 칸을 켜고 기본 단추를 채우는 용도일 뿐이고, 어떤 스크립트도 목록에서 직접 실행할 수 있다.

### 4.1 패키지 매니저 판별 (`PackageManager`)

위에서 아래, 처음 맞는 것. 판별 결과와 근거(예: "pnpm — pnpm-lock.yaml")를 칸에 보인다.

1. 사용자가 이 폴더에 고른 값 (`node.options:<dir>`의 `pm`)
2. 잠금 파일: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `bun.lock`·`bun.lockb` → bun, `package-lock.json`·`npm-shrinkwrap.json` → npm
3. `package.json`의 `packageManager` 필드 (`pnpm@9.1.0` → pnpm)
4. npm

잠금 파일이 둘 이상이면 가장 최근에 바뀐 것을 쓰고 Doctor가 경고한다.

| 매니저 | 스크립트 실행 | 설치 |
|---|---|---|
| npm | `npm run <s>` (인자는 `-- <args>`) | 잠금 파일 있으면 `npm ci`, 없으면 `npm install` |
| pnpm | `pnpm run <s>` | `pnpm install` |
| yarn | `yarn run <s>` | `yarn install` |
| bun | `bun run <s>` | `bun install` |

Windows에서는 `npm.cmd`·`pnpm.cmd`·`yarn.cmd`처럼 실제 실행 파일 이름을 쓴다 (`command_runner`가 처리). 미리보기에는 사용자가 터미널에 치는 모양(`npm run dev`)을 보인다.

### 4.2 스크립트 역할 분류 (`ScriptRole`)

스크립트마다 역할을 하나 붙인다. **이름**으로 먼저, 이름으로 모르면 **값**(명령 본문)으로 판단한다.

| 역할 | 이름 규칙 | 값 규칙 (이름이 안 맞을 때) |
|---|---|---|
| **실행** `run` | `start`, `dev`, `serve`, `develop`, `watch`, `electron:dev`, `start:dev`, `dev:*` | `electron .`, `electron-forge start`, `vite`(인자 없음), `next dev`, `nodemon`, `ts-node-dev`, `tsx watch` |
| **빌드** `build` | `build`, `compile`, `build:*`(패키징 단어가 없는 것), `tsc` | `vite build`, `next build`, `tsc`, `webpack`, `esbuild` |
| **패키징** `package` | `package`, `make`, `dist`, `pack`, `release`, `electron:build`, `build:win`·`build:mac`·`dist:*` | `electron-builder`, `electron-forge make`, `electron-forge package`, `electron-packager` |
| **테스트** `test` | `test`, `test:*`, `e2e`, `vitest`, `jest` | `vitest`, `jest`, `mocha`, `playwright test`, `node --test` |
| **점검** `lint` | `lint`, `lint:*`, `typecheck`, `type-check`, `format:check`, `check` | `eslint`, `prettier --check`, `tsc --noEmit` |
| **그 밖** `other` | 위에 없음 | |

- `pre<name>`·`post<name>` (npm이 자동으로 이어 돌리는 것)은 목록에서 **숨기고** 해당 스크립트 줄 끝에 "pre·post 포함" 표시만 둔다. 직접 돌리는 단추는 두지 않는다 (이중 실행 방지).
- 한 역할에 후보가 여럿이면 **우선순위**로 기본을 정한다 (아래 4.3). 나머지는 같은 칩의 ▾ 메뉴에 나온다.
- 값 규칙은 **단어 경계 포함 검사**(`\belectron-builder\b`)다. `&&`·`;`로 이어진 명령은 조각마다 본다. 쉘 문법을 해석하지 않는다.

### 4.3 기본 선택 우선순위 (종류별)

| 종류 | 실행 | 빌드 | 패키징 |
|---|---|---|---|
| Electron | `start` > `dev` > `electron:dev` > `start:dev` | `build` > `compile` | `package` > `make` > `dist` > `electron:build` (스크립트가 없으면 단추를 만들지 않는다 — §10 결정 3) |
| 웹 | `dev` > `start` > `serve` | `build` | (없음) |
| 서버 | `dev` > `start:dev` > `start` | `build` | (없음) |
| 일반 | `start` > `dev` | `build` | (없음) |

마지막으로 고른 스크립트는 폴더·브랜치와 무관하게 `node.action:<dir>`로 기억하고, 스크립트가 사라졌으면 기본으로 돌린다.

### 4.4 판단이 틀렸을 때

- 역할 칩에는 "추정"임을 알리는 작은 표시가 있고(이름 규칙에서 맞았으면 없음, 값 규칙에서 맞았으면 있음), **스크립트 목록**(전체 + 각 스크립트의 실제 명령 한 줄)에서 어느 것이든 바로 실행할 수 있다.
- 역할을 사용자가 바꾸는 UI는 만들지 않는다 (YAGNI). 틀린 기본은 목록에서 골라 실행하면 마지막 선택으로 기억된다.

## 5. 칸의 화면

칸 머리(프로젝트 드롭다운 · 이름·버전 · 종류 칩 · 패키지 매니저 칩) + 탭 **Run · Doctor · Log** (기기가 없다).

### 5.1 Run 탭

1. **동작 칩** (이 순서, 해당 역할의 스크립트가 있을 때만): `실행` · `빌드` · `패키징`(Electron) · `테스트` · `점검` · `설치`.
   - 칩을 누르면 그 역할의 기본 스크립트로 즉시 실행하는 분할 단추. ▾로 같은 역할의 다른 스크립트를 고른다.
   - `설치`는 `node_modules`가 없거나 잠금 파일이 더 새로울 때 칸 머리에 "의존성 설치가 필요합니다" 안내와 함께 강조한다. **자동으로 설치하지 않는다.**
2. **스크립트 목록**(접힘): 이름 · 역할 배지 · 실제 명령 한 줄. 검색 가능. 누르면 그 스크립트를 실행한다.
3. **옵션**(접힘): 패키지 매니저 고르기, **추가 인자** 한 줄(공백 나눔·따옴표 존중, npm은 `--` 뒤에 붙인다).
4. **명령 미리보기**: 실행될 전체 명령을 항상 보이고 복사 가능 (예: `npm run dev -- --port 4000`). 환경 변수를 바꿨다면 옆에 "환경: …"을 보인다 (§7).
5. **실행/중지** + 출력(스트림). 실행·dev 서버는 계속 도는 프로세스라 **중지**가 핵심이다 (`killProcessTree`로 자식까지 끝낸다 — Windows에서 `npm.cmd` → `node` 자식이 남지 않게).
6. 끝나면 (패키징·빌드 후) **산출물 폴더 열기** 단추 (§5.3).

`실행` 동작이 이미 도는 중이면 단추는 `중지`로 바뀌고 다른 동작은 막힌다 (동시에 한 개, Gradle과 같음).

### 5.2 출력

- `NO_COLOR=1`·`FORCE_COLOR=0`을 주어 ANSI 색을 막는다 (뷰어가 색을 해석하지 않으므로). 사용자의 추가 인자·환경으로 덮어쓸 수 있다.
- dev 서버가 `http://localhost:PORT` 같은 주소를 출력하면 그 줄에 **링크 열기**를 붙인다 — 첫 버전에 넣는다 (§10 결정 2).
- 출력 없이 오래 걸리면(첫 `install` 등) "패키지를 내려받는 중일 수 있습니다" 표시를 띄운다.

### 5.3 패키징과 산출물 폴더 (Electron)

- 패키징 스크립트가 `electron-builder`면 산출물 폴더는 `package.json`의 `build.directories.output`(없으면 `dist`), `electron-builder.yml`/`.json`의 `directories.output`, `electron-forge`면 `out/make`(없으면 `out`)이다. 읽지 못하면 위 후보 중 **실제로 있는 폴더**를 연다.
- **서명·공증은 건드리지 않는다.** 서명 환경이 없어 패키징이 실패하거나 서명 없이 만들어지면 그대로 보여 주고 처방만 한 줄 알린다 (macOS `CSC_IDENTITY_AUTO_DISCOVERY=false` 안내 등).
- Windows에서 electron-builder가 "Cannot create symbolic link"로 실패하는 경우(개발자 모드 꺼짐)를 처방으로 알린다 (§6).

### 5.4 접힌 제목 · 색 · 바쁨

- `summary`: 대기 `dev · npm` / 실행 중 `running dev` / 실패 `build failed` / 설치 필요 `install needed`.
- `mood`: working > failed > warning(Doctor 문제·오래된 점검·설치 필요) > success > idle.
- `busy`: 명령이 도는 동안. `appliesTo`: `projects.isNotEmpty`.

## 6. 환경 점검 (Doctor 탭)

칸을 처음 펼칠 때(그리고 **다시 점검** 단추)와 브랜치가 바뀌면 "오래된 값" 표시 (Flutty `diagnosticsStale`과 같은 규칙).

| 항목 | 방법 | 실패 시 |
|---|---|---|
| Node | `node --version` | 설치 안내. GUI로 연 앱은 셸 PATH를 못 받으므로 설정 창에서 `node` 경로 지정 가능 |
| Node 버전 요구 | `.nvmrc`·`.node-version`·`package.json`의 `engines.node`와 실제 버전을 비교 (단순 `>=N`·`N.x`·정수만 비교, 못 읽으면 건너뜀) | 경고 (막지 않음). nvm·fnm·volta 사용 중이면 "터미널에서 연 앱만 그 버전을 쓴다" 안내 |
| 패키지 매니저 | `<pm> --version` | 없으면 설치 안내(pnpm·yarn은 `corepack enable` 안내) |
| `packageManager` 필드 | 필드의 매니저·버전과 실제를 비교 | 다르면 경고 |
| 잠금 파일 | 둘 이상이면 | 경고 |
| `node_modules` | 폴더 존재, 잠금 파일(또는 `package.json`)보다 오래됨 | 설치 단추로 연결 (`설치`) |
| **`ELECTRON_RUN_AS_NODE`** (Electron만) | 환경에 설정돼 있는지 | **자식 프로세스 환경에서 빼서 실행**하고 그 사실을 미리보기에 보인다 (§7). VS Code 터미널에서 띄운 앱이 이 값을 물려받으면 Electron이 일반 Node처럼 돌아 창이 안 뜬다 |
| Electron 바이너리 (Electron만) | `node_modules/electron/dist` 존재 | 없으면 `Electron failed to install correctly` 처방 — `node_modules/electron`을 지우고 다시 설치 |
| 프로젝트 읽힘 | `package.json` 파싱 성공 여부 | 첫 오류 줄 |

## 7. 설정 · 도구 경로 · 환경

- 키: `node.last_tab_id`, `node.action:<dir>`, `node.options:<dir>`(JSON: `pm`·추가 인자, 모르는 필드는 버리고 읽는다), `node.project_choice:<dir>`.
- 도구 경로: 설정 창 "도구"에 `node` 한 줄을 더하고, **패키지 매니저(npm·pnpm·yarn·bun)는 `node` 경로와 같은 폴더에서 먼저 찾는다** (Node 설치 폴더에 같이 있다). `command_runner`의 후보 경로에 Windows `C:\Program Files\nodejs`·`%APPDATA%\npm`, macOS `/opt/homebrew/bin`·`/usr/local/bin`·`~/.volta/bin`을 더한다 (nvm·fnm 같은 셸 초기화에 기대는 것은 후보에 넣지 않는다).
- **환경 주입은 최소로, 미리보기에 보인다.**
  - 추가: `NO_COLOR=1`, `FORCE_COLOR=0`, `npm_config_update_notifier=false`(업데이트 알림이 출력을 어지럽히지 않게).
  - 제거: Electron 종류일 때 `ELECTRON_RUN_AS_NODE`.
  - 우리가 찾은 `node`가 PATH에 없으면 그 폴더를 PATH 앞에 더한다 ("PATH에 …를 더했습니다" 안내를 따로 보인다, Avalonia와 같은 방식).
- 앱에 Node를 번들하지 않는다.

## 8. 실패 설명

출력에서 알아낼 수 있는 원인은 한 줄 처방으로 알린다 (`explainFailure` 방식, 원문 텍스트 매칭).

| 출력 | 처방 |
|---|---|
| `'xxx' is not recognized`, `xxx: command not found`, `Cannot find module` (프로젝트 안) | `node_modules`가 없다 → `설치` |
| `EADDRINUSE` | 포트가 사용 중 — 다른 서버를 끄거나 포트를 바꾸는 인자 |
| `Electron failed to install correctly` | `node_modules/electron`을 지우고 다시 설치 |
| `ERR_OSSL_EVP_UNSUPPORTED`, `error:0308010C` | 오래된 webpack과 새 Node의 조합 — Node를 낮추거나 `NODE_OPTIONS=--openssl-legacy-provider` |
| `Unsupported engine`, `EBADENGINE` | `engines.node`와 현재 Node 버전 불일치 (Doctor 항목) |
| `ENOENT … spawn npm` | `npm`을 못 찾음 — 도구 경로 |
| `Cannot create symbolic link` (Windows, electron-builder) | Windows 개발자 모드를 켜거나 관리자 권한 |
| `ELIFECYCLE`, `npm ERR!` 꼬리 줄 | 원인이 아닌 소음이다 — 위쪽 첫 오류 줄을 가리킨다 |
| `EACCES` | 쓰기 권한 (전역 설치를 시도했는지 확인) |

## 9. 브랜치 전환 (§1.10 약속)

Gradle 계획 §5와 같다. Node에서 추가로:
- 브랜치마다 `package.json`의 스크립트·의존성이 다를 수 있다 → 스크립트 목록·역할·종류·패키지 매니저를 다시 읽는다. 저장된 스크립트가 사라졌으면 기본으로 돌리고 한 번 알린다.
- `node_modules`는 브랜치를 넘어 남으므로 잠금 파일이 바뀌었으면 "의존성 설치가 필요할 수 있습니다" 배너 + `설치` 강조.
- 실행 중이면 **중지하지 않고** 배너만. dev 서버가 파일 변경을 감시해 새 브랜치 코드로 다시 빌드할 수 있다는 점을 문구에 적는다.

## 10. 결정 기록 (2026-11-20, 제안값으로 사용자 확정)

1. ✅ **이름**: `Node Runner` (PLAN.md 결정 26).
2. ✅ **dev 서버 주소 링크** 열기를 첫 버전에 넣는다 (한 줄 정규식, 외부 브라우저로 열기).
3. ✅ **Electron 패키징 스크립트가 없으면** 단추를 만들지 않는다 (스크립트가 없는 프로젝트의 설정을 우리가 추측하게 된다. 스크립트 목록에서 고르게만 한다).
4. ✅ **monorepo(workspaces)**: 루트만 잡는 것으로 시작하고, 하위 패키지 선택기는 필요할 때 더한다.
5. ✅ **bun·pnpm·yarn Berry(PnP)**: 명령은 만들되 실제로는 npm·pnpm만 확인했다고 알려 둔다.
6. ✅ **React Native·Tauri**: 감지는 하되 전용 바로가기 없이 둔다.

## 11. 테스트 계획

| 파일 | 내용 |
|---|---|
| `test/node/node_detector_test.dart` | 스크립트만/의존성만/둘 다 없음, 깨진 JSON, **Flutter 루트 제외**, depth 0→1, `node_modules`·`dist` 건너뛰기, workspaces 루트만 |
| `test/node/node_kind_test.dart` | 종류 판정 우선순위(Electron·웹·서버·RN·일반), 의존성/devDependencies 둘 다 |
| `test/node/package_manager_test.dart` | 잠금 파일·`packageManager` 필드·사용자 지정 우선순위, 잠금 파일 여럿 |
| `test/node/script_role_test.dart` | 이름 규칙·값 규칙(`electron .`, `electron-builder`, `vite build`), `pre`/`post` 숨기기, 기본 선택 우선순위(종류별) |
| `test/node/command_plan_test.dart` | 매니저별 명령, npm `--` 인자, Windows `.cmd`, 환경 주입·제거 표시, 산출물 폴더 후보 |
| `test/node/doctor_test.dart` | 가짜 `CommandRunner`·임시 폴더로 항목별 결과 (`node_modules` 없음, `engines` 불일치, `ELECTRON_RUN_AS_NODE`) |
| `test/node/failure_hint_test.dart` | 실제 npm·Electron 오류 문구 샘플 → 처방 |
| `test/node/node_dock_test.dart` | 감지 → `appliesTo`, 브랜치 전환 시 재읽기·배너, `mood`/`busy`/`summary` |
| `test/dock_contract_test.dart`, `keys_test.dart`, `theme_rules_test.dart` | 자동 |

수동(자동화 어려움): 실제 Electron 앱의 `start`가 창을 띄우고 **중지**가 자식까지 끝내는지(Windows·macOS), electron-builder 패키징과 산출물 폴더 열기, 첫 `install` 중 화면 반응, VS Code 터미널에서 띄운 앱에서 `ELECTRON_RUN_AS_NODE` 제거 확인.

## 12. 단계

| 단계 | 내용 | 기준 |
|---|---|---|
| **8a** 감지·파서 | `NodeDetector`(제외 규칙 포함), `package.json` 읽기·종류 판정, 패키지 매니저 판별, 스크립트 역할 분류, `NodeDock` 빈 몸통, 레지스트리 한 줄, `node.` 키 접두어 허용, ARB `nd` | 계약 테스트 통과, Flutter 폴더에선 켜지지 않음 |
| **8b** Run 탭 | 동작 칩·스크립트 목록·옵션·명령 미리보기·실행/중지·출력·산출물 폴더 열기 | 예제 Electron·Vite 프로젝트에서 실행·중지 |
| **8c** Doctor·도구 | Node·매니저·`node_modules`·`engines`·Electron 점검, 환경 주입·제거, 도구 경로, 실패 처방 | Node 없는 컴퓨터에서 안내가 정확 |
| **8d** 연결 | 브랜치 전환, 접힌 제목·색·busy, 설치 필요 안내 | 접힌 채 dev 서버가 계속 돌고 전환 배너가 뜬다 |
| **8e** 마무리 | README 기능 줄(영·한), 스크린샷, PLAN "단계 8 결과", `dockNoProjectBody` 문구에 Node 추가, 릴리스 점검 | `check_readme.py`·감사 `go` |

릴리스는 사용자 기능 추가이므로 **minor**. 빈 칸 안내(`dockNoProjectBody`)는 "지원하는 프로젝트(Flutter, Gradle, Avalonia, Node …)"로 고친다. 칸 순서는 Branch → Flutter → Gradle → Avalonia → Node (감지된 것만 보인다).

## 13. 위험

| 위험 | 대응 |
|---|---|
| 스크립트 이름·값 규칙이 틀린 기본을 고른다 | 규칙은 **기본 단추를 채우는 용도로만.** 스크립트 목록에서 어느 것이든 실행하고, 마지막 선택을 기억한다 |
| 쉘 문법(`&&`·환경 변수 접두어·`cross-env`)을 해석할 수 없다 | 해석하지 않는다. 명령 본문을 단어 경계로 검사하고 그대로 `npm run`에 맡긴다 |
| GUI 앱이 nvm·fnm·volta의 PATH를 못 받아 Node 버전이 다르다 | Doctor가 `engines`/`.nvmrc`와 실제를 비교해 경고하고, 설정 창에서 `node` 경로를 지정한다 |
| Windows에서 `npm.cmd` 아래 자식 프로세스가 중지 뒤에도 남는다 | `killProcessTree`(공통)로 끝낸다. 수동 확인 항목 |
| `ELECTRON_RUN_AS_NODE`를 물려받아 Electron이 창 없이 끝난다 | 자식 환경에서 제거하고 미리보기·Doctor에 보인다 |
| `node_modules`가 브랜치와 어긋난다 | 잠금 파일 비교 + 배너. 자동 설치는 하지 않는다 |
| Flutter 프로젝트의 도구용 `package.json`에서 칸이 켜져 혼란 | §3.1 제외 규칙 + 테스트 |
| 출력이 매우 많다 (dev 서버) | 공통 `CommandLogEntry` 1 MiB 꼬리 상한과 갱신 묶기를 그대로 쓴다 |
