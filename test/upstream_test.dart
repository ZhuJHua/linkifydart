import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:linkifydart/linkifydart.dart' as linkify;
import 'package:linkifydart/src/parser.dart';
import 'package:linkifydart/src/scanner.dart';

List<Map<String, Object?>> fixtures(String name) => (jsonDecode(
      File('test/fixtures/$name.json').readAsStringSync(),
    ) as List<Object?>)
        .cast<Map<String, Object?>>();

void main() {
  group('upstream scanner', () {
    final scanners = <String, Scanner>{};
    for (final (index, fixture) in fixtures('scanner').indexed) {
      test('case $index: ${fixture['input']}', () {
        final schemes = fixture['schemes']! as List<Object?>;
        final scanner = scanners.putIfAbsent(
          jsonEncode(schemes),
          () => Scanner([
            for (final scheme in schemes.cast<List<Object?>>())
              (scheme[0]! as String, scheme[1]! as bool),
          ]),
        );
        final tokens = scanner.scan(fixture['input']! as String);
        expect(tokens.map((token) => token.type), fixture['types']);
        expect(tokens.map((token) => token.value), fixture['values']);
        expect(tokens.map((token) => token.toObject()), fixture['expected']);
      });
    }
    test('custom protocol group inheritance', () {
      final scanner = Scanner([
        ('twitter', false),
        ('steam', true),
        ('org', false),
        ('geo', false),
        ('42', true),
        ('view-source', false),
        ('ms-settings', true),
      ]);
      expect(scanner.groups['scheme'], [
        'SCHEME',
        '42',
        'ms-settings',
        'steam',
      ]);
      expect(scanner.groups['slashscheme'], [
        'SLASH_SCHEME',
        'geo',
        'org',
        'twitter',
        'view-source',
      ]);
      expect(scanner.groups['tld'], contains('org'));
    });
  });
  group('upstream parser', () {
    final scanner = Scanner([('steam', true), ('view-source', false)]);
    final parser = Parser(scanner.groups);
    for (final (index, fixture) in fixtures('parser').indexed) {
      test('case $index: ${fixture['input']}', () {
        final input = fixture['input']! as String;
        final tokens = parser.parse(input, scanner.scan(input));
        expect(tokens.map((token) => token.type), fixture['types']);
        expect(tokens.map((token) => token.toString()), fixture['values']);
        expect(tokens.map((token) => token.value), fixture['values']);
      });
    }
    test('source offsets', () {
      const input = 'Hello github.com!';
      expect(
        parser
            .parse(input, scanner.scan(input))
            .map((token) => token.toObject()),
        [
          {
            'type': 'text',
            'value': 'Hello ',
            'href': 'Hello ',
            'isLink': false,
            'start': 0,
            'end': 6,
          },
          {
            'type': 'url',
            'value': 'github.com',
            'href': 'http://github.com',
            'isLink': true,
            'start': 6,
            'end': 16,
          },
          {
            'type': 'text',
            'value': '!',
            'href': '!',
            'isLink': false,
            'start': 16,
            'end': 17,
          },
        ],
      );
    });
  });
  group('upstream test', () {
    final detector = linkify.Linkify();
    for (final (index, fixture) in fixtures('test').indexed) {
      test('case $index: ${fixture['input']}', () {
        expect(
          detector.test(
            fixture['input']! as String,
            type: fixture['type'] as String?,
          ),
          fixture['expected'],
        );
      });
    }
  });
}
