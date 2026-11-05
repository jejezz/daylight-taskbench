// Avalonia 칸: 속성 풀이·감지·명령 계획·실패 설명·칸의 약속 (docs/AVALONIA_RUNNER.md).

import 'dart:io';

import 'package:daylight_taskbench/core/run_session.dart';
import 'package:daylight_taskbench/docks/avalonia/avalonia_dock.dart';
import 'package:daylight_taskbench/docks/avalonia/detect/avalonia_detector.dart';
import 'package:daylight_taskbench/docks/avalonia/detect/avalonia_project.dart';
import 'package:daylight_taskbench/docks/avalonia/run/avalonia_plan.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

const _appCsproj = '''
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <AssemblyName>\$(AppFileName)</AssemblyName>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Avalonia" Version="12.1.5" />
    <PackageReference Include="Avalonia.Desktop" Version="12.1.5" />
  </ItemGroup>
</Project>
''';

const _props = '''
<Project>
  <PropertyGroup>
    <AppVersion>1.0.0-rc.1</AppVersion>
    <AppFileName>DaylightCommander</AppFileName>
  </PropertyGroup>
</Project>
''';

const _testCsproj = '''
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup><OutputType>Exe</OutputType></PropertyGroup>
  <ItemGroup><PackageReference Include="xunit" Version="2.9.0" /></ItemGroup>
</Project>
''';

void _write(String path, String text) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(text);
}

void main() {
  group('속성 풀이', () {
    test('한 줄 속성을 모으고 \$(이름)을 푼다', () {
      final props = parseMsbuildProperties(_props);
      expect(props['AppFileName'], 'DaylightCommander');
      expect(resolveMsbuild(r'$(AppFileName)', props), 'DaylightCommander');
      expect(resolveMsbuild(r'$(Nope)', props), isNull);
      expect(resolveMsbuild('Plain', props), 'Plain');
    });

    test('Avalonia 실행 프로젝트만 앱으로 본다', () {
      expect(isAvaloniaApp(_appCsproj), isTrue);
      expect(isAvaloniaApp(_testCsproj), isFalse);
      expect(isAvaloniaApp('<Project><PropertyGroup><OutputType>Library</OutputType></PropertyGroup><ItemGroup><PackageReference Include="Avalonia" /></ItemGroup></Project>'), isFalse);
    });
  });

  group('감지·읽기', () {
    late Directory dir;
    setUp(() async => dir = await tempDir('avalonia'));
    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      dir.deleteSync(recursive: true);
    });

    void solution() {
      _write('${dir.path}/App.slnx', '<Solution/>');
      _write('${dir.path}/Directory.Build.props', _props);
      _write('${dir.path}/src/App/App.csproj', _appCsproj);
      _write('${dir.path}/tests/T/T.csproj', _testCsproj);
      _write('${dir.path}/src/App/obj/Other.csproj', _appCsproj); // obj 는 건너뛴다
    }

    test('솔루션 폴더를 프로젝트로 읽고 어셈블리 이름을 Directory.Build.props 로 푼다', () async {
      solution();
      final found = await const AvaloniaDetector().detect(dir.path);
      expect(found, hasLength(1));
      final p = await AvaloniaProject.read(dir.path);
      expect(p.solution, 'App.slnx');
      expect(p.version, '1.0.0-rc.1');
      expect(p.apps.map((a) => a.relativePath), ['src/App/App.csproj']);
      expect(p.apps.single.assemblyName, 'DaylightCommander');
    });

    test('상위 폴더면 바로 아래 폴더들에서 찾는다 (depth 1)', () async {
      Directory('${dir.path}/proj').createSync();
      _write('${dir.path}/proj/App.sln', '');
      _write('${dir.path}/proj/App/App.csproj', _appCsproj);
      final found = await const AvaloniaDetector().detect(dir.path);
      expect(found.map((p) => p.name), ['proj']);
    });

    test('Avalonia 가 아닌 .NET 폴더는 감지하지 않는다', () async {
      _write('${dir.path}/X.slnx', '');
      _write('${dir.path}/X/X.csproj', _testCsproj);
      expect(await const AvaloniaDetector().detect(dir.path), isEmpty);
    });
  });

  group('명령 계획', () {
    const app = AvaloniaApp(relativePath: 'src/App/App.csproj', assemblyName: 'DaylightCommander');
    const withSln = AvaloniaProject(path: '/p', name: 'p', solution: 'App.slnx', apps: [app]);
    const noSln = AvaloniaProject(path: '/p', name: 'p', apps: [app]);

    AvaloniaPlan plan(AvaloniaAction a, {AvaloniaProject? p = withSln, AvaloniaOptions o = const AvaloniaOptions(), bool vs = false}) => buildAvaloniaPlan(
          project: p,
          app: app,
          action: a,
          options: o,
          isWindows: true,
          basePath: 'C:/bin',
          vswhereDirExists: vs,
        );

    test('실행: dotnet run -c Release --project <csproj>, 계속 도는 단계', () {
      final s = plan(AvaloniaAction.run).steps.single;
      expect(s.args, ['dotnet', 'run', '-c', 'Release', '--project', r'src\App\App.csproj']);
      expect(s.interactive, isTrue);
      expect(s.workingDirectory, '/p');
      expect(s.environment['DOTNET_CLI_TELEMETRY_OPTOUT'], '1');
      expect(s.commandLine, startsWith('DOTNET_CLI_TELEMETRY_OPTOUT=1 '));
    });

    test('테스트: dotnet test <솔루션>, 솔루션이 없으면 막는다', () {
      expect(plan(AvaloniaAction.test).steps.single.args, ['dotnet', 'test', 'App.slnx']);
      expect(plan(AvaloniaAction.test, p: noSln).blocker, AvaloniaBlocker.noSolution);
    });

    test('AOT 게시 후 실행: 게시 → 실행 파일, vswhere 폴더가 PATH 에 더해진다', () {
      final pl = plan(AvaloniaAction.aotRun, vs: true);
      expect(pl.steps, hasLength(2));
      expect(pl.steps[0].args, ['dotnet', 'publish', r'src\App\App.csproj', '-c', 'Release', '-r', 'win-x64', '-p:PublishAot=true', '-o', r'publish\aot']);
      expect(pl.steps[0].environment['PATH'], 'C:/bin;$vswhereDir');
      expect(pl.steps[0].environment['OS'], 'Windows_NT');
      expect(pl.steps[0].commandLine.contains('PATH='), isFalse);
      expect(pl.steps[0].commandLine.contains('OS='), isFalse);
      expect(pl.pathExtended, isTrue);
      expect(pl.steps[1].args, [r'publish\aot\DaylightCommander.exe']);
      expect(pl.steps[1].interactive, isTrue);
    });

    test('vswhere 폴더가 없으면 PATH 를 건드리지 않는다', () {
      final pl = plan(AvaloniaAction.publishAot);
      expect(pl.steps.single.environment.containsKey('PATH'), isFalse);
      expect(pl.pathExtended, isFalse);
    });

    test('옵션: Debug·RID·AOT 폴더·추가 인자', () {
      const o = AvaloniaOptions(debug: true, rid: 'win-arm64', aotDir: 'out/aot/', extraArgs: '--no-restore "-p:A=b c"');
      final s = plan(AvaloniaAction.publishAot, o: o).steps.single;
      expect(s.args, ['dotnet', 'publish', r'src\App\App.csproj', '-c', 'Debug', '-r', 'win-arm64', '-p:PublishAot=true', '-o', r'out\aot', '--no-restore', '-p:A=b c']);
      expect(AvaloniaOptions.fromJson(o.toJson()).rid, 'win-arm64');
      expect(AvaloniaOptions.fromJson('깨진 값').isDefault, isTrue);
    });

    test('macOS: osx-arm64, ./ 로 실행', () {
      final pl = buildAvaloniaPlan(project: withSln, app: app, action: AvaloniaAction.aotRun, options: const AvaloniaOptions(), isMacOS: true);
      expect(pl.steps[0].args, containsAllInOrder(['-r', 'osx-arm64']));
      expect(pl.steps[1].args, ['./publish/aot/DaylightCommander']);
    });

    test('프로젝트나 앱이 없으면 막는다', () {
      expect(buildAvaloniaPlan(project: null, app: null, action: AvaloniaAction.run, options: const AvaloniaOptions()).blocker, AvaloniaBlocker.noProject);
      expect(buildAvaloniaPlan(project: withSln, app: null, action: AvaloniaAction.run, options: const AvaloniaOptions()).blocker, AvaloniaBlocker.noApp);
    });
  });

  test('실패 원인을 알아낸다', () {
    expect(explainAvaloniaFailure('error : Platform linker not found'), AvaloniaFailure.aotLinker);
    expect(explainAvaloniaFailure('error MSB3027: Could not copy'), AvaloniaFailure.fileLocked);
    expect(explainAvaloniaFailure('error NETSDK1045: The current .NET SDK does not support'), AvaloniaFailure.sdk);
    expect(explainAvaloniaFailure('NU1301: Unable to load the service index'), AvaloniaFailure.restore);
    expect(explainAvaloniaFailure('all good'), isNull);
  });

  group('칸', () {
    late Directory dir;
    setUp(() async => dir = await tempDir('avdock'));
    tearDown(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      dir.deleteSync(recursive: true);
    });

    test('프로젝트가 있으면 켜지고, 브랜치가 바뀌면(접혀 있어도) 다시 찾는다', () async {
      final ws = await makeWorkspace();
      final source = FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: '1'));
      ws.attachForTest(source, selectedDir: dir.path);
      final dock = AvaloniaDock()..attach(ws);
      ws.headChanges.listen((c) => dock.onHeadChange(ws, c));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(dock.appliesTo(ws), isFalse);
      expect(dock.id, 'avalonia');
      expect(dock.isRunner, isTrue);

      _write('${dir.path}/App.slnx', '<Solution/>');
      _write('${dir.path}/App/App.csproj', _appCsproj);
      source.set(GitState(root: dir.path, branch: 'feature', sha: '2'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(dock.appliesTo(ws), isTrue);
      expect(dock.project!.apps.single.assemblyName, 'App');
      expect(dock.controller!.plan.runnable, isTrue);
      expect(dock.controller!.statuses.every((s) => s == StepStatus.done), isTrue);

      dock.detach(ws);
      dock.dispose();
      ws.dispose();
    });
  });
}
