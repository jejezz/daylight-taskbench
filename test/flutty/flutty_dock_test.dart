// Flutty 칸 모듈의 약속: 고른 폴더 → 프로젝트 → 컨트롤러, 실행 중 브랜치 변경 알림, 늦은 시작, 설정 구역.

import 'dart:io';

import 'package:daylight_taskbench/docks/flutty/devices/device_service.dart';
import 'package:daylight_taskbench/docks/flutty/devices/mobile_device.dart';
import 'package:daylight_taskbench/docks/flutty/doctor/diagnostics.dart';
import 'package:daylight_taskbench/docks/flutty/flutter/flutter_project.dart';
import 'package:daylight_taskbench/docks/flutty/flutty_dock.dart';
import 'package:daylight_taskbench/docks/flutty/install/flutty_controller.dart';
import 'package:daylight_taskbench/theme/taskbench_style.dart';
import 'package:daylight_taskbench/workspace/git_state.dart';
import 'package:daylight_taskbench/workspace/workspace.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support.dart';

class _NoDevices implements DeviceService {
  int calls = 0;

  @override
  Future<List<MobileDevice>> list() async {
    calls++;
    return const [];
  }
}

class _FakeDiagnostics implements DiagnosticsService {
  @override
  Future<Diagnostics> collect(FlutterProject? project) async =>
      Diagnostics(flutter: const ToolInfo('3'), xcode: const ToolInfo('1'), adb: const ToolInfo('1'), collectedAt: DateTime(2026));
}

const _pubspec = 'name: demo_app\nversion: 2.0.0+1\ndependencies:\n  flutter:\n    sdk: flutter\n';

void main() {
  late Directory dir;
  late _NoDevices devices;

  setUp(() async {
    dir = await tempDir('fluttydock2');
    File('${dir.path}/pubspec.yaml').writeAsStringSync(_pubspec);
    devices = _NoDevices();
  });

  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150)); // 진행 중인 감지가 끝난 뒤 지운다
    dir.deleteSync(recursive: true);
  });

  Future<(FluttyDock, Workspace, FakeGitStateSource)> setup() async {
    final ws = await makeWorkspace();
    final source = FakeGitStateSource(GitState(root: dir.path, branch: 'main', sha: '1'));
    ws.attachForTest(source, selectedDir: dir.path);
    final controller = FluttyController(runner: ws.runner, deviceService: devices, diagnosticsService: _FakeDiagnostics(), hostIsMac: false, hostIsWindows: false);
    final dock = FluttyDock(controller: controller)..attach(ws);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return (dock, ws, source);
  }

  test('감지한 프로젝트가 컨트롤러로 넘어간다 (기기 목록은 칸을 펼치기 전에는 읽지 않는다)', () async {
    final (dock, ws, _) = await setup();
    expect(dock.appliesTo(ws), isTrue);
    expect(dock.controller!.project?.name, 'demo_app');
    expect(devices.calls, 0);
    dock.ensureStarted();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(devices.calls, 1);
    dock.ensureStarted(); // 두 번 불러도 한 번만 시작한다
    expect(devices.calls, 1);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('실행 중에 브랜치가 바뀌면 알림만 남기고 멈추지 않는다 (§1.10)', () async {
    final (dock, ws, _) = await setup();
    final c = dock.controller!;
    expect(dock.mood(ws), TaskbenchMood.idle);

    final main = GitState(root: dir.path, branch: 'main', sha: '1');
    final feature = GitState(root: dir.path, branch: 'feature', sha: '2');
    dock.onHeadChange(ws, HeadChange(main, feature, HeadChangeKind.branch));
    expect(dock.branchChangedWhileRunning, isNull); // 실행 중이 아니면 알리지 않는다

    c.running = true;
    expect(dock.busy(ws), isTrue);
    expect(dock.mood(ws), TaskbenchMood.working);
    dock.onHeadChange(ws, HeadChange(main, feature, HeadChangeKind.branch));
    expect(dock.branchChangedWhileRunning, 'feature');
    expect(c.running, isTrue); // 중단하지 않는다

    dock.dismissBranchBanner();
    expect(dock.branchChangedWhileRunning, isNull);
    c.running = false;
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('프로젝트가 사라지면 칸이 숨고 컨트롤러 프로젝트도 비워진다', () async {
    final (dock, ws, _) = await setup();
    File('${dir.path}/pubspec.yaml').deleteSync();
    dock.onHeadChange(
      ws,
      HeadChange(GitState(root: dir.path, branch: 'main', sha: '1'), GitState(root: dir.path, branch: 'main', sha: '2'), HeadChangeKind.commit),
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(dock.appliesTo(ws), isFalse);
    expect(dock.controller!.project, isNull);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('브랜치가 바뀌면 읽어 둔 점검 결과가 오래된 값으로 표시되고, 다시 읽으면 풀린다 (§1.10)', () async {
    final (dock, ws, _) = await setup();
    final c = dock.controller!;
    final main = GitState(root: dir.path, branch: 'main', sha: '1');
    final feature = GitState(root: dir.path, branch: 'feature', sha: '2');
    c.markDiagnosticsStale(); // 시작 전이거나 결과가 없으면 아무 일도 없다
    expect(c.diagnosticsStale, isFalse);
    dock.onHeadChange(ws, HeadChange(main, feature, HeadChangeKind.branch));
    expect(c.diagnosticsStale, isFalse);
    dock.ensureStarted();
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(c.diagnostics, isNotNull);
    dock.onHeadChange(ws, HeadChange(main, feature, HeadChangeKind.branch));
    expect(c.diagnosticsStale, isTrue);
    await c.runDiagnostics();
    expect(c.diagnosticsStale, isFalse);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });

  test('병합·rebase 중이거나 실행 중 브랜치가 바뀌면 접힌 제목 점이 주의색이 된다', () async {
    final (dock, ws, source) = await setup();
    expect(dock.mood(ws), TaskbenchMood.idle);
    source.set(GitState(root: dir.path, branch: 'main', sha: '1', operation: RepoOperation.merging));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(dock.operationInProgress(ws), isTrue);
    expect(dock.mood(ws), TaskbenchMood.warning);
    source.set(GitState(root: dir.path, branch: 'main', sha: '1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(dock.mood(ws), TaskbenchMood.idle);
    dock.detach(ws);
    dock.dispose();
    ws.dispose();
  });
}
