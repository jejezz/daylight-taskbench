// daylight-terminal-flutter의 models/local_shell.dart에서 가져옴.

/// 로컬 셸의 종류. 경로를 쓰는 방식이 종류마다 다르다.
enum ShellKind {
  /// bash, zsh, fish 같은 sh 계열 (macOS/Linux).
  posix,

  /// PowerShell 7 / Windows PowerShell.
  powershell,

  /// cmd.exe.
  cmd,

  /// Git Bash (MSYS). POSIX 셸이지만 경로가 `/c/Users/...` 모양이다.
  gitBash,

  /// WSL 안의 리눅스 셸. 윈도 경로와 `/mnt/c/...` 사이를 오간다.
  wsl,
}

/// 새 탭으로 열 수 있는 로컬 셸 하나.
class LocalShell {
  const LocalShell({
    required this.id,
    required this.name,
    required this.executable,
    required this.kind,
    this.arguments = const [],
    this.wslDistro,
  });

  /// 목록에서 구분하는 값. 예: `pwsh`, `wsl:Ubuntu-24.04`.
  final String id;

  /// 사람이 보는 이름. 예: `PowerShell 7`.
  final String name;

  final String executable;
  final List<String> arguments;
  final ShellKind kind;

  /// [ShellKind.wsl]일 때 배포판 이름.
  final String? wslDistro;
}
