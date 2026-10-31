// 명령 단계 목록을 차례로 실행하는 공통 엔진. Flutty 칸의 `FluttyController.start` 에서 뽑았다 —
// Gradle 칸도 같은 실행·취소·키 입력·실패 처리를 쓴다 (docs/GRADLE_RUNNER.md §7).
//
// 이 파일은 "무슨 단계를 만들지"(InstallPlan, Gradle 명령 조립)나 "실패를 어떻게 설명할지"(처방)를 모른다.
// 그건 각 칸의 몫이고, 여기서는 단계를 실행하고 상태를 알리는 일만 한다.

import 'command_runner.dart';

enum StepStatus { pending, running, done, failed, cancelled }

/// 실행할 명령 한 개. 화면에 보이는 명령과 실제로 실행하는 명령이 같다.
abstract interface class RunStep {
  List<String> get args;
  String? get workingDirectory;

  /// 이 명령에만 더하는 환경 변수.
  Map<String, String> get environment;

  /// 계속 실행되는 단계(`flutter run`, `bootRun`): 끝나는 것이 아니라 사용자가 멈춘다. 표준 입력을 열어 둔다.
  bool get interactive;
}

/// [RunSession.run] 의 끝 모양.
class RunSessionResult {
  const RunSessionResult({this.failedIndex, this.failedResult, this.cancelled = false});

  /// 실패한 단계의 번호. 실패가 없으면 null.
  final int? failedIndex;

  /// 실패한 단계의 결과 (출력 원문은 처방을 고르는 데 쓴다).
  final CommandResult? failedResult;

  /// 사용자가 중간에 멈췄다.
  final bool cancelled;

  bool get ok => failedIndex == null && !cancelled;
}

class RunSession {
  RunSession(this.runner);

  final CommandRunner runner;
  RunHandle? _handle;

  /// 단계를 실행하는 중인가.
  bool get running => _handle != null;

  /// [steps] 중 [indices] 만 차례로 실행한다. 하나라도 실패하면 거기서 멈춘다.
  /// [onStatus] 는 단계의 상태가 바뀔 때마다 불린다 (실행 시작, 끝, 실패, 취소).
  Future<RunSessionResult> run(
    List<RunStep> steps,
    Iterable<int> indices, {
    void Function(int index, StepStatus status)? onStatus,
  }) async {
    final handle = _handle = RunHandle();
    try {
      for (final i in indices) {
        final step = steps[i];
        onStatus?.call(i, StepStatus.running);
        final r = await runner.run(
          step.args,
          workingDirectory: step.workingDirectory,
          environment: step.environment,
          handle: handle,
          keepStdinOpen: step.interactive,
        );
        if (handle.cancelled) {
          onStatus?.call(i, StepStatus.cancelled);
          return const RunSessionResult(cancelled: true);
        }
        // 계속 실행되는 단계(`flutter run`)는 사용자가 `q`로 끝내도 정상이다.
        if (r.ok || step.interactive && r.exitCode == 0) {
          onStatus?.call(i, StepStatus.done);
          continue;
        }
        onStatus?.call(i, StepStatus.failed);
        return RunSessionResult(failedIndex: i, failedResult: r);
      }
      return const RunSessionResult();
    } finally {
      _handle = null;
    }
  }

  /// 실행 중인 단계를 끝낸다 (자식 프로세스까지).
  void cancel() => _handle?.cancel();

  /// 실행 중인 단계의 표준 입력으로 키를 보낸다 (`flutter run` 의 `r`, `R`, `q`).
  void send(String key) => _handle?.send(key);
}
