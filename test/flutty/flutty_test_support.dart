// Flutty 이식 테스트용 도우미. 원본의 controller.openProject(dir) 에 해당하는 일을 칸이 하는 방식으로 한다
// (폴더 → FlutterProject.detect → setProject).

import 'package:daylight_taskbench/docks/flutty/flutter/flutter_project.dart';
import 'package:daylight_taskbench/docks/flutty/install/flutty_controller.dart';

extension OpenProjectForTest on FluttyController {
  /// 프로젝트를 열었으면 true. 아니면 현재 프로젝트를 그대로 둔다.
  Future<bool> openProject(String dir) async {
    final found = await FlutterProject.detect(dir);
    projectError = found == null ? dir : null;
    if (found == null) {
      notifyListeners();
      return false;
    }
    await setProject(found);
    return true;
  }
}
