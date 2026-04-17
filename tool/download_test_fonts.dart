// Downloads Noto fonts used for golden tests into test/fonts/.cache/.
// Run with: `dart run tool/download_test_fonts.dart`
// The cache is gitignored; CI runs this before `flutter test`.

import 'dart:io';

const _fonts = <String, String>{
  // Noto Sans Regular (Latin, punctuation, combining marks)
  'NotoSans-Regular.ttf':
      'https://raw.githubusercontent.com/notofonts/notofonts.github.io/main/fonts/NotoSans/full/ttf/NotoSans-Regular.ttf',
  // Noto Naskh Arabic Regular (Arabic with proper shaping)
  'NotoNaskhArabic-Regular.ttf':
      'https://raw.githubusercontent.com/notofonts/notofonts.github.io/main/fonts/NotoNaskhArabic/full/ttf/NotoNaskhArabic-Regular.ttf',
  // Noto Sans JP (Japanese hiragana/katakana/kanji coverage). The
  // `notofonts/notofonts.github.io` subset doesn't ship the CJK
  // families; pull the variable TTF from `google/fonts` instead. The
  // %5B/%5D is literal `[wght]` axis-tag encoding in the filename.
  'NotoSansJP-Regular.ttf':
      'https://github.com/google/fonts/raw/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf',
  // Noto Sans Devanagari Regular (for conjunct shaping)
  'NotoSansDevanagari-Regular.ttf':
      'https://raw.githubusercontent.com/notofonts/notofonts.github.io/main/fonts/NotoSansDevanagari/full/ttf/NotoSansDevanagari-Regular.ttf',
  // Noto Color Emoji (for ZWJ emoji sequences in golden tests)
  'NotoColorEmoji.ttf':
      'https://raw.githubusercontent.com/googlefonts/noto-emoji/main/fonts/NotoColorEmoji.ttf',
};

Future<void> main(List<String> args) async {
  final cacheDir = Directory('test/fonts/.cache');
  if (!cacheDir.existsSync()) cacheDir.createSync(recursive: true);

  final client = HttpClient();
  try {
    for (final entry in _fonts.entries) {
      final file = File('${cacheDir.path}/${entry.key}');
      if (file.existsSync() && file.lengthSync() > 0) {
        stdout.writeln('OK       ${entry.key}');
        continue;
      }
      stdout.writeln('DOWNLOAD ${entry.key}');
      final request = await client.getUrl(Uri.parse(entry.value));
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln(
          'FAILED   ${entry.key}: HTTP ${response.statusCode} for ${entry.value}',
        );
        exitCode = 1;
        continue;
      }
      await response.pipe(file.openWrite());
      stdout.writeln('WROTE    ${file.path} (${file.lengthSync()} bytes)');
    }
  } finally {
    client.close(force: true);
  }

  if (exitCode != 0) {
    stderr.writeln('\nSome fonts failed to download. Check URLs above.');
  } else {
    stdout.writeln('\nAll test fonts are present in ${cacheDir.path}.');
  }
}
