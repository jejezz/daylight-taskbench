import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daylight_taskbench/core/command_log.dart';
import 'package:daylight_taskbench/core/command_runner.dart';
import 'package:daylight_taskbench/docks/flutty/devices/device_service.dart';
import 'package:daylight_taskbench/docks/flutty/devices/mobile_device.dart';
import 'package:daylight_taskbench/docks/flutty/doctor/diagnostics.dart';
import 'package:daylight_taskbench/docks/flutty/flutter/flutter_project.dart';
import 'package:daylight_taskbench/docks/flutty/install/flutty_controller.dart';
import 'package:daylight_taskbench/l10n/app_localizations.dart';
import 'package:daylight_taskbench/docks/flutty/ui/banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Devices implements DeviceService {
  @override
  Future<List<MobileDevice>> list() async => const [];
}

class _Diag implements DiagnosticsService {
  _Diag({required this.adbFound});
  final bool adbFound;

  @override
  Future<Diagnostics> collect(FlutterProject? project) async => Diagnostics(
    flutter: const ToolInfo('3.47.1'),
    xcode: const ToolInfo('27.0'),
    adb: ToolInfo(adbFound ? '37.0.1' : null),
    collectedAt: DateTime(2026, 10, 10),
  );
}

const _androidProject = FlutterProject(path: '/p/app', name: 'app', hasIos: true, hasAndroid: true);
const _iosOnlyProject = FlutterProject(path: '/p/app', name: 'app', hasIos: true, hasAndroid: false);

Future<FluttyController> _controller({required bool adbFound, FlutterProject? project}) async {
  SharedPreferences.setMockInitialValues({});
  final c = FluttyController(
    runner: CommandRunner(log: CommandLog(), path: '/usr/bin'),
    deviceService: _Devices(),
    diagnosticsService: _Diag(adbFound: adbFound),
  )..project = project;
  await c.runDiagnostics();
  return c;
}

Future<void> _pump(WidgetTester tester, FluttyController c) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: NextStepBanner(controller: c)),
  ),
);

void main() {
  testWidgets('a missing adb beats "connect a device" and offers the tool paths button', (tester) async {
    final c = await _controller(adbFound: false, project: _androidProject);
    await _pump(tester, c);
    expect(find.text('adb wasn\'t found (needed to install on Android)'), findsOneWidget);
    expect(find.text('Connect and select a device'), findsNothing);
    expect(find.text('Set tool paths…'), findsOneWidget);
    await tester.tap(find.text('Show how to fix'));
    await tester.pumpAndSettle();
    expect(find.textContaining('platform-tools'), findsWidgets);
  });

  testWidgets('before a project is opened, opening one comes first', (tester) async {
    final c = await _controller(adbFound: false);
    await _pump(tester, c);
    expect(find.text('Open a Flutter project first'), findsOneWidget);
    expect(find.textContaining('adb wasn'), findsNothing);
  });

  testWidgets('an iOS-only project does not need adb, so the normal next step shows', (tester) async {
    final c = await _controller(adbFound: false, project: _iosOnlyProject);
    await _pump(tester, c);
    expect(find.text('Connect and select a device'), findsOneWidget);
    expect(find.text('Set tool paths…'), findsNothing);
  });

  testWidgets('with adb present nothing about adb is shown', (tester) async {
    final c = await _controller(adbFound: true, project: _androidProject);
    await _pump(tester, c);
    expect(find.textContaining('adb wasn'), findsNothing);
    expect(find.text('Connect and select a device'), findsOneWidget);
  });
}
