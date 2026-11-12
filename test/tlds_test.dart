import 'dart:io';

import 'package:linkifydart/src/scanner.dart';
import 'package:linkifydart/src/tlds.dart';
import 'package:test/test.dart';

import '../tool/update_tlds.dart' as updater;

void main() {
  test('shipped ASCII TLD trie round trips', () {
    final words = decodeTlds(encodedTlds);
    expect(updater.encodeTlds(words), encodedTlds);
    expect(
      words,
      containsAll([
        'com',
        'xyz',
        'uk',
        'vermögensberater',
        'vermögensberatung',
      ]),
    );
  });
  test('shipped Unicode TLD trie round trips', () {
    final words = decodeTlds(encodedUtlds);
    expect(updater.encodeTlds(words), encodedUtlds);
    expect(words, containsAll(['中国', 'السعودية', 'москва']));
  });
  test('Unicode comes from IANA Punycode entries', () {
    final (ascii, unicode) = updater.parseIana(
      '# Version\nCOM\nXN--FIQS8S\nXN--P1AI\nXN--VERMGENSBERATER-CTB\nXN--VERMGENSBERATUNG-PWB\n',
    );
    expect(ascii, ['com', 'vermögensberater', 'vermögensberatung']);
    expect(unicode, ['рф', '中国']);
  });
  test('Punycode supplementary code point', () {
    expect(updater.decodePunycode('e28h'), '😀');
    expect(updater.decodePunycode('fsqu00a'), '例子');
    expect(updater.decodePunycode('bcher-kva'), 'bücher');
  });
  test(
    'prefix words in compact trie',
    () => expect(
      decodeTlds(updater.encodeTlds(['car', 'cars', 'cat', 'cats'])),
      ['car', 'cars', 'cat', 'cats'],
    ),
  );

  for (final (index, contents) in [
    '',
    '# No domains\n',
    'COM\nCOM\n',
    '<html>Server error</html>\n',
  ].indexed) {
    test('rejects malformed IANA list $index', () {
      expect(() => updater.parseIana(contents), throwsFormatException);
    });
  }

  test('rejects invalid Punycode', () {
    expect(() => updater.decodePunycode('!'), throwsFormatException);
  });

  group('updater CLI', () {
    late Directory temporary;

    setUp(() async {
      temporary = await Directory('.dart_tool').createTemp('tld_update_test_');
    });

    tearDown(() async {
      await temporary.delete(recursive: true);
    });

    Future<ProcessResult> runUpdater(List<String> arguments) => Process.run(
          Platform.resolvedExecutable,
          ['tool/update_tlds.dart', ...arguments],
        );

    test('updates offline without prompting and preserves generated format',
        () async {
      const source = '# Version\nCOM\nXN--FIQS8S\n';
      final input = File('${temporary.path}/iana.txt');
      final output = File('${temporary.path}/tlds.dart');
      await input.writeAsString(source);
      final result = await runUpdater([
        '--source',
        input.path,
        '--output',
        output.path,
      ]);
      expect(result.exitCode, 0, reason: result.stderr.toString());
      final generated = await output.readAsString();
      final (ascii, unicode) = updater.parseIana(source);
      expect(generated, contains("'${updater.encodeTlds(ascii)}'"));
      expect(generated, contains("'${updater.encodeTlds(unicode)}'"));
      expect(generated, startsWith('/// Compact TLD tries'));
      expect(generated, isNot(contains(String.fromCharCode(0x2028))));
      expect(generated, isNot(contains(String.fromCharCode(0x2029))));
      expect(generated, isNot(contains(String.fromCharCode(0x85))));
    });

    test('fails on malformed input without replacing the existing output',
        () async {
      final input = File('${temporary.path}/iana.txt');
      final output = File('${temporary.path}/tlds.dart');
      await input.writeAsString('<html>Server error</html>\n');
      await output.writeAsString('existing output');
      final result = await runUpdater([
        '--source',
        input.path,
        '--output',
        output.path,
      ]);
      expect(result.exitCode, isNonZero);
      expect(result.stderr, contains('TLD update failed:'));
      expect(await output.readAsString(), 'existing output');
    });

    test('fails when an argument is missing', () async {
      final result = await runUpdater(['--source']);
      expect(result.exitCode, isNonZero);
      expect(result.stderr, contains('Usage:'));
    });

    test('fails when the destination cannot be written', () async {
      final input = File('${temporary.path}/iana.txt');
      await input.writeAsString('COM\n');
      final result = await runUpdater([
        '--source',
        input.path,
        '--output',
        temporary.path,
      ]);
      expect(result.exitCode, isNonZero);
      expect(result.stderr, contains('TLD update failed:'));
    });
  });
}
