// 정렬(포맷): Dart 는 `dart format`, JSON·ARB 는 들여쓰기 2칸 (daylight-workbench 의 dart_formatter.dart·json_formatter.dart).
// [Taskbench에서 달라진 곳] 실패 이유는 번역된 문구가 아니라 [FormatFailure](종류 + 값)로 돌려주고, 화면이 번역한다.

import 'dart:convert';
import 'dart:io';

import '../core/command_runner.dart';

enum FormatFailureKind {
  /// `dart` 명령을 찾지 못했다.
  noDart,

  /// 정렬용 임시 파일을 쓰지 못했다. [FormatFailure.detail]은 시스템 오류 문구.
  tempWriteFailed,

  /// 이유를 알 수 없는 실패.
  failed,

  /// `dart format` 이 낸 오류. [FormatFailure.detail]은 오류 첫 줄.
  failedDetail,

  /// JSON 문법 오류. [FormatFailure.detail]은 파서 문구.
  jsonInvalid,
}

class FormatFailure {
  const FormatFailure(this.kind, [this.detail = '']);

  final FormatFailureKind kind;
  final String detail;
}

/// 정렬 결과: 정렬된 글자, 또는 실패 이유.
class FormatResult {
  const FormatResult.ok(String this.text) : failure = null;
  const FormatResult.failed(FormatFailure this.failure) : text = null;

  final String? text;
  final FormatFailure? failure;

  bool get ok => text != null;
}

/// 편집기에 열린 Dart 글(저장하지 않은 수정 포함)을 `dart format`으로 정렬한다.
///
/// 글을 파일 옆의 임시 파일에 쓰고 정렬한 뒤 읽어 온다. 원본 파일은 건드리지 않고, 같은 폴더라서
/// `analysis_options.yaml`의 줄 길이와 패키지의 언어 버전도 그대로 따른다.
class DartFormatter {
  DartFormatter(this.runner);

  final CommandRunner runner;

  Future<FormatResult> format(String path, String text) async {
    final file = File(path);
    final tmp = File(
      '${file.parent.path}${Platform.pathSeparator}.studio_format_${DateTime.now().microsecondsSinceEpoch}.dart',
    );
    try {
      await tmp.writeAsString(text);
      final r = await runner.run(
        ['dart', 'format', tmp.path],
        workingDirectory: file.parent.path,
        quiet: true,
      );
      if (r.exitCode == 127) {
        return const FormatResult.failed(
          FormatFailure(FormatFailureKind.noDart),
        );
      }
      if (!r.ok) {
        return FormatResult.failed(
          _firstError(r.combined, file.uri.pathSegments.last),
        );
      }
      return FormatResult.ok(await tmp.readAsString());
    } on FileSystemException catch (e) {
      return FormatResult.failed(
        FormatFailure(FormatFailureKind.tempWriteFailed, e.message),
      );
    } finally {
      try {
        if (await tmp.exists()) await tmp.delete();
      } on FileSystemException {
        // 임시 파일이 남아도 다음 정리 때 지우면 된다.
      }
    }
  }

  /// 구문 오류 첫 줄만 보여 준다 (임시 파일 이름은 열린 파일의 이름으로 바꿔서).
  static FormatFailure _firstError(String output, String fileName) {
    final line = output
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    final cleaned = line.replaceAll(
      RegExp(r'\.studio_format_\d+\.dart'),
      fileName,
    );
    return cleaned.isEmpty
        ? const FormatFailure(FormatFailureKind.failed)
        : FormatFailure(FormatFailureKind.failedDetail, cleaned);
  }
}

/// JSON·ARB 글을 들여쓰기 2칸으로 정렬한다. 키 순서는 그대로 두고, 끝의 줄바꿈 유무도 원본을 따른다.
FormatResult formatJson(String text) {
  try {
    final value = jsonDecode(text);
    final formatted = const JsonEncoder.withIndent('  ').convert(value);
    return FormatResult.ok(text.endsWith('\n') ? '$formatted\n' : formatted);
  } on FormatException catch (e) {
    return FormatResult.failed(
      FormatFailure(FormatFailureKind.jsonInvalid, e.message),
    );
  }
}
