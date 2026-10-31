import 'package:flutter/widgets.dart';

import 'workspace.dart';

/// 설정 창처럼 Workspace 를 직접 받지 않는 곳이 읽는다 (칸의 설정 구역: 편집기 명령·자동 fetch 등).
class WorkspaceScope extends InheritedNotifier<Workspace> {
  const WorkspaceScope({super.key, required Workspace workspace, required super.child}) : super(notifier: workspace);

  static Workspace? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<WorkspaceScope>()?.notifier;
}
