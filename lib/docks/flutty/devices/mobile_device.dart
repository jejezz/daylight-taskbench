import '../../../core/devices/mobile_device.dart';
import '../flutter/flutter_project.dart';

// [Taskbench에서 달라진 곳] MobileDevice·parseAdbDevices·parseDevicectl 은 core/devices 로 옮겼다.
// 기존 import 가 그대로 동작하도록 다시 내보낸다.
export '../../../core/devices/mobile_device.dart';

/// 이 컴퓨터를 대상으로 쓸 수 있으면 그 "기기". **프로젝트가 이 OS의 데스크톱을 이미 지원할 때만**
/// (macOS면 `macos/`, Windows면 `windows/` 폴더가 있을 때) 돌려준다 — 없는 플랫폼을 만들어 주지는 않는다.
MobileDevice? hostDesktopDevice(
  FlutterProject? project, {
  required bool isMac,
  required bool isWindows,
}) {
  if (project == null) return null;
  if (isMac && project.hasMacos) {
    return const MobileDevice(
      id: 'macos',
      name: 'macOS',
      platform: DevicePlatform.macos,
      link: DeviceLink.local,
    );
  }
  if (isWindows && project.hasWindows) {
    return const MobileDevice(
      id: 'windows',
      name: 'Windows',
      platform: DevicePlatform.windows,
      link: DeviceLink.local,
    );
  }
  return null;
}
