// 저장소가 아닌 폴더를 열었을 때의 분기 (PLAN.md §1.13):
//   · 하위에 저장소들이 있으면 → `git init`을 권하지 않고 그 목록에서 고르게 한다 (상위 폴더에 init하면 중첩된다)
//   · 하위에도 없고 안전한 위치면 → "Git 저장소로 만들까요?"
//   · 홈·바탕화면·문서·시스템 폴더 같은 위치면 → `git init`을 제안하지 않는다
// 파일 시스템만 보는 로직이라 위젯 없이 테스트한다.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 저장소가 아닌 폴더에 대한 분석 결과.
class NotRepoInfo {
  const NotRepoInfo({
    required this.path,
    this.childRepos = const [],
    required this.initAllowed,
    this.isFlutterProject = false,
    this.hasGitignore = false,
  });

  /// 분석한 폴더(정규화된 경로).
  final String path;

  /// 하위(최대 2단계)에서 찾은 저장소 루트, 이름순.
  final List<String> childRepos;

  /// 이 폴더에 `git init`을 제안해도 되는가: 하위에 저장소가 없고 위험한 위치가 아닐 때만 true.
  final bool initAllowed;

  /// `pubspec.yaml`이 Flutter 프로젝트를 가리킨다 → Flutter용 `.gitignore`를 제안한다.
  final bool isFlutterProject;

  /// 이미 `.gitignore`가 있다 → 덮어쓰지 않는다.
  final bool hasGitignore;
}

class FolderScanner {
  FolderScanner({String? home, this.maxDepth = 2, this.maxRepos = 30})
    : home = home ?? _homeDir();

  /// 사용자 홈 폴더. 테스트에서 바꾼다.
  final String? home;

  /// 하위 저장소를 찾는 깊이: 1 = 바로 아래, 2 = 그 아래까지.
  final int maxDepth;

  /// 이만큼 찾으면 멈춘다 (목록이 끝없이 길어지지 않게).
  final int maxRepos;

  /// 찾지 않고 내려가지도 않는 폴더 이름 (빌드 산출물·의존성).
  static const _skip = {
    'node_modules',
    'build',
    'target',
    'dist',
    'Pods',
    'vendor',
    'venv',
    'out',
  };

  Future<NotRepoInfo> analyze(String dir) async {
    final children = await findChildRepos(dir);
    final unsafe = isUnsafeInitLocation(dir);
    return NotRepoInfo(
      path: dir,
      childRepos: children,
      initAllowed: children.isEmpty && !unsafe,
      isFlutterProject: _isFlutterProject(dir),
      hasGitignore: File(p.join(dir, '.gitignore')).existsSync(),
    );
  }

  /// [dir] 아래에서 `.git`이 있는 폴더를 [maxDepth]단계까지 찾는다. 저장소를 찾으면 그 안으로는 들어가지 않고,
  /// `.`으로 시작하는 폴더와 빌드 산출물 폴더는 건너뛴다. 심볼릭 링크는 따라가지 않는다.
  Future<List<String>> findChildRepos(String dir) async {
    final found = <String>[];
    final queue = Queue<(String, int)>()..add((dir, 0));
    while (queue.isNotEmpty && found.length < maxRepos) {
      final (current, depth) = queue.removeFirst();
      List<FileSystemEntity> entries;
      try {
        entries = await Directory(current).list(followLinks: false).toList();
      } on FileSystemException {
        continue;
      }
      entries.sort((a, b) => a.path.compareTo(b.path));
      for (final e in entries) {
        if (e is! Directory) continue;
        final name = p.basename(e.path);
        if (name.startsWith('.') || _skip.contains(name)) continue;
        if (_hasGit(e.path)) {
          found.add(e.path);
          if (found.length >= maxRepos) break;
        } else if (depth + 1 < maxDepth) {
          queue.add((e.path, depth + 1));
        }
      }
    }
    found.sort();
    return found;
  }

  /// `.git`은 폴더이거나(일반 저장소) 파일이다(worktree·서브모듈).
  static bool _hasGit(String dir) {
    final git = p.join(dir, '.git');
    return FileSystemEntity.typeSync(git, followLinks: false) !=
        FileSystemEntityType.notFound;
  }

  static bool _isFlutterProject(String dir) {
    try {
      final f = File(p.join(dir, 'pubspec.yaml'));
      return f.existsSync() && f.readAsStringSync().contains('sdk: flutter');
    } on FileSystemException {
      return false;
    }
  }

  /// 저장소를 만들면 위험한 위치인가: 파일 시스템 루트, 홈과 그 위, 홈 아래 바탕화면·문서 같은 기본 폴더, 시스템 폴더.
  /// 폴더를 잘못 열었을 때 홈 전체가 저장소가 되는 사고를 막는다.
  bool isUnsafeInitLocation(String path) {
    final win = Platform.isWindows;
    // Windows 와 macOS 의 파일 시스템은 대소문자를 구분하지 않는 쪽이 기본이다.
    final fold = win || Platform.isMacOS;
    String n(String s) {
      var t = p.normalize(s).replaceAll('\\', '/');
      if (fold) t = t.toLowerCase();
      while (t.length > 1 && t.endsWith('/')) {
        t = t.substring(0, t.length - 1);
      }
      return t;
    }

    final target = n(path);
    if (p.dirname(path) == path) return true; // 파일 시스템 루트

    final exact = <String>{};
    final prefixes = <String>[];
    final h = home;
    if (h != null && h.isNotEmpty) {
      exact
        ..add(n(h))
        ..add(n(p.dirname(h)));
      for (final d in const [
        'Desktop',
        'Documents',
        'Downloads',
        'Library',
        'Music',
        'Movies',
        'Videos',
        'Pictures',
        'Public',
        'Applications',
        'AppData',
      ]) {
        exact.add(n(p.join(h, d)));
      }
    }
    if (win) {
      exact.addAll(['c:/users']);
      prefixes.addAll([
        'c:/windows',
        'c:/program files',
        'c:/program files (x86)',
        'c:/programdata',
      ]);
    } else {
      exact.addAll(['/users', '/home', '/applications', '/opt', '/var', '/tmp']);
      prefixes.addAll([
        '/system',
        '/usr',
        '/bin',
        '/sbin',
        '/etc',
        '/library',
        '/private/etc',
      ]);
    }
    if (exact.contains(target)) return true;
    return prefixes.any((x) => target == x || target.startsWith('$x/'));
  }

  static String? _homeDir() {
    final env = Platform.environment;
    return Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
  }
}

/// Flutter 프로젝트용 `.gitignore` (flutter create 가 만드는 것과 같은 범위).
const flutterGitignoreTemplate = r'''# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.build/
.buildlog/
.history
.svn/
.swiftpm/
migrate_working_dir/

# IDE
*.iml
*.ipr
*.iws
.idea/

# Flutter / Dart
**/doc/api/
.dart_tool/
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/
/coverage/

# Symbolication / obfuscation
app.*.symbols
app.*.map.json

# Android
/android/app/debug
/android/app/profile
/android/app/release
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/local.properties
**/android/gradlew
**/android/gradlew.bat
**/android/key.properties
*.jks

# iOS / macOS
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/DerivedData/
**/ios/**/Pods/
**/ios/Flutter/ephemeral/
**/macos/Flutter/ephemeral/
**/macos/Pods/
''';
