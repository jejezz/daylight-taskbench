/// 파일 트리에서 아이콘과 색을 고르는 파일 종류. 이름과 확장자만 보고 정한다 (파일을 읽지 않는다).
library;

enum FileKind {
  /// Dart 소스.
  dart,

  /// `pubspec.yaml`·`pubspec.lock` — Flutter 패키지 정보.
  package,

  /// `analysis_options.yaml` 등 분석·설정 파일.
  settings,

  /// YAML.
  yaml,

  /// JSON·ARB.
  json,

  /// Markdown·텍스트 문서.
  document,

  /// 그림 파일.
  image,

  /// HTML·XML·CSS·plist.
  markup,

  /// Kotlin·Swift·C/C++·Java·JavaScript·Python·SQL 등 다른 언어의 소스, 빌드 스크립트.
  source,

  /// 셸·PowerShell·배치 스크립트.
  script,

  /// `.gitignore`·`.lock`·`.properties`·`.ini` 같은 설정·잠금 파일.
  config,

  /// 그 밖의 파일.
  other,
}

const _images = {
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'bmp',
  'svg',
  'ico',
  'icns',
  'heic',
};
const _markup = {'html', 'htm', 'xml', 'css', 'plist', 'xib', 'storyboard'};
const _source = {
  'kt',
  'kts',
  'java',
  'swift',
  'm',
  'mm',
  'c',
  'h',
  'cc',
  'cpp',
  'hpp',
  'cmake',
  'gradle',
  'js',
  'ts',
  'py',
  'sql',
  'rs',
  'go',
};
const _scripts = {'sh', 'bash', 'zsh', 'ps1', 'bat', 'cmd'};
const _documents = {'md', 'markdown', 'txt', 'rst'};
const _config = {
  'ini',
  'properties',
  'lock',
  'toml',
  'env',
  'iml',
  'gitignore',
  'gitattributes',
};

/// [path]의 파일 종류.
FileKind fileKindOf(String path) {
  final name =
      path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).lastOrNull ?? '';
  final lower = name.toLowerCase();
  switch (lower) {
    case 'pubspec.yaml' || 'pubspec.lock':
      return FileKind.package;
    case 'analysis_options.yaml' || 'build.yaml' || 'l10n.yaml':
      return FileKind.settings;
    case 'cmakelists.txt' || 'dockerfile' || 'makefile':
      return FileKind.source;
    case 'license' || 'readme' || 'changelog':
      return FileKind.document;
  }
  // `.gitignore`처럼 점으로 시작하는 이름은 이름 전체가 확장자 구실을 한다.
  final dot = lower.lastIndexOf('.');
  if (dot < 0) return FileKind.other;
  final ext = lower.substring(dot + 1);
  if (ext == 'dart') return FileKind.dart;
  if (ext == 'yaml' || ext == 'yml') return FileKind.yaml;
  if (ext == 'json' || ext == 'arb') return FileKind.json;
  if (_documents.contains(ext)) return FileKind.document;
  if (_images.contains(ext)) return FileKind.image;
  if (_markup.contains(ext)) return FileKind.markup;
  if (_source.contains(ext)) return FileKind.source;
  if (_scripts.contains(ext)) return FileKind.script;
  if (_config.contains(ext)) return FileKind.config;
  return FileKind.other;
}
