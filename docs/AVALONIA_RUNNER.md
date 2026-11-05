# Avalonia Runner

Avalonia(.NET) 앱을 Taskbench에서 빌드·실행·테스트하는 칸이다. 구조는 [Gradle Runner](GRADLE_RUNNER.md)와 같다:
화면에 보이는 명령이 곧 실제로 실행되는 명령이고, 칸이 접혀 있어도 실행은 이어진다.

- 코드: `lib/docks/avalonia/` (id `avalonia`, ARB 접두어 `av`, 설정 키 접두어 `avalonia.`)
- 테스트: `test/avalonia/avalonia_test.dart`

## 켜지는 조건

고른 폴더(없으면 바로 아래 폴더들)에 **Avalonia 앱 프로젝트**가 있으면 칸이 켜진다.

- 앱 프로젝트 = `.csproj` 안에 `<PackageReference Include="Avalonia…">` 와 `<OutputType>Exe|WinExe</OutputType>`.
  폴더 아래 두 단계(`src/App/App.csproj`)까지 찾고 `bin`·`obj`·`publish` 는 건너뛴다.
- 폴더에 솔루션(`.slnx`/`.sln`)이 있거나, `.csproj` 가 폴더 바로 아래에 있어야 한다 (상위 폴더를 잘못 잡지 않으려는 규칙).
- 어셈블리 이름(= 실행 파일 이름)은 MSBuild를 돌리지 않고 읽는다: csproj의 `<AssemblyName>` 이 `$(AppFileName)` 같으면
  폴더 루트의 `Directory.Build.props` 속성으로 푼다. 버전은 같은 파일의 `AppVersion`/`Version`.

## 동작 (칸 위쪽 칩, 이 순서)

| 동작 | 명령 (작업 폴더 = 프로젝트 루트) |
|---|---|
| 빌드 | `dotnet build <csproj> -c Release` |
| 테스트 | `dotnet test <솔루션>` (솔루션이 없으면 막힘) |
| 실행 | `dotnet run -c Release --project <csproj>` — 앱 창이 닫히거나 **중지**를 누를 때까지 계속 돈다 |
| AOT 게시 | `dotnet publish <csproj> -c Release -r <RID> -p:PublishAot=true -o <AOT 폴더>` |
| AOT 게시 후 실행 | 위 게시 → `<AOT 폴더>\<어셈블리>.exe` 실행 (시작 속도를 재는 용도) |
| 정리 | `dotnet clean <솔루션> -c Release` |

모든 `dotnet` 명령에 `DOTNET_CLI_TELEMETRY_OPTOUT=1`, `DOTNET_NOLOGO=1` 을 준다.

**AOT 단계의 환경** (Windows)
- `C:\Program Files (x86)\Microsoft Visual Studio\Installer`(`vswhere.exe` 위치)가 있으면 PATH에 더한다. 없으면 NativeAOT 링크가 실패한다.
  설정 창 "도구"에서 `vswhere` 를 직접 지정하면 그 폴더가 PATH 앞에 들어간다.
- `OS=Windows_NT` 를 준다. Git Bash에서 띄운 앱은 `OS` 가 `MINGW64_NT-…` 로 바뀌어 있고, 그러면 MSBuild가
  `Cross-OS native compilation is not supported.` 로 게시를 거부한다 (실제로 겪었다).
- PATH·OS는 명령 미리보기에는 적지 않는다 (PATH를 더했다는 안내만 따로 보인다).

## 옵션 (폴더마다 저장, `avalonia.options:<dir>`)

- **Debug로 빌드** — 끄면 Release (기본).
- **런타임 식별자** — 비우면 이 컴퓨터용: Windows `win-x64`, macOS `osx-arm64`, 그 밖 `linux-x64`.
- **AOT 게시 폴더** — 프로젝트 루트 기준, 기본 `publish/aot`. 절대 경로도 된다.
- **추가 인자** — 명령 끝에 붙는다 (공백으로 나누고 따옴표 존중).

고른 앱 csproj·동작도 폴더마다 기억한다. `dotnet` 경로는 설정 창 "도구"에서 지정한다.

## 환경 점검

**점검** 탭에서, 칸을 처음 펼칠 때(그리고 **다시 점검** 단추) `dotnet --version`, 앱 프로젝트 수, 솔루션 파일, AOT 링크 도구(vswhere)를 확인해 한 줄씩 보인다.
`dotnet` 을 못 찾으면 칸 색이 경고가 된다.

## 실패 설명

출력에서 알아낼 수 있는 원인은 한 줄 처방으로 알린다: AOT 링크 도구 없음, SDK 버전 불일치(`NETSDK1045`),
출력 파일 사용 중(`MSB3027` — 이미 떠 있는 앱을 닫기), NuGet 복원 실패(`NU1301`), RID 오류.

## 알려 둠

- 빌드·테스트·게시는 대상 프로젝트 안의 `bin/`·`obj/` 를 쓴다 (`dotnet` 이 하는 일). AOT 산출물은 기본으로 `<프로젝트>/publish/aot` 에 생긴다 —
  해당 저장소의 `.gitignore` 에 `publish/` 가 있는지 확인한다.
- macOS 경로(`osx-arm64`, `./publish/aot/<이름>`)는 계획만 세워 단위 테스트했고 실제 Mac에서는 돌려 보지 않았다.
- 칸 순서는 Branch → Flutter Runner → Gradle Runner → Avalonia Runner. 감지된 것만 보인다.
