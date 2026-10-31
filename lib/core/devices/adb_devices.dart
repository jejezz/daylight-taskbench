// `adb devices -l` 로 Android 기기 목록을 읽는다. Flutty 칸의 기기 서비스와 Gradle 칸이 함께 쓴다.

import '../command_runner.dart';
import 'mobile_device.dart';

class AdbDevices {
  const AdbDevices(this.runner);

  final CommandRunner runner;

  /// 연결된 Android 기기·떠 있는 에뮬레이터. `adb` 가 없거나 실패하면 빈 목록.
  Future<List<MobileDevice>> list() async {
    final r = await runner.run(['adb', 'devices', '-l'], quiet: true);
    return r.ok ? parseAdbDevices(r.stdout) : const [];
  }
}
