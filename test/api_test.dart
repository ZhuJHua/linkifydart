import 'package:test/test.dart';
import 'package:linkifydart/linkifydart.dart' as linkify;
import 'package:linkifydart/linkifydart.dart' show LinkOption, TokenOption;

void main() {
  late linkify.Linkify detector;
  setUp(() => detector = linkify.Linkify());

  group('upstream find', () {
    test('empty string', () => expect(detector.find(''), isEmpty));
    test('plain text', () => expect(detector.find('Hello World!'), isEmpty));
    test(
      'link object',
      () => expect(detector.find('hello.world!'), [
        {
          'type': 'url',
          'value': 'hello.world',
          'href': 'http://hello.world',
          'isLink': true,
          'start': 0,
          'end': 11,
        },
      ]),
    );
    test(
      'type filter',
      () => expect(
        detector.find(
          'For help with github.com, please contact support@example.com',
          type: 'email',
        ),
        [
          {
            'type': 'email',
            'value': 'support@example.com',
            'href': 'mailto:support@example.com',
            'isLink': true,
            'start': 41,
            'end': 60,
          },
        ],
      ),
    );
    test(
      'truncate option',
      () => expect(
        detector.find(
          'Does www.truncate.com work with truncate?',
          options: const linkify.LinkifyOptions(truncate: LinkOption.value(10)),
        ),
        [
          {
            'type': 'url',
            'value': 'www.trunca…',
            'href': 'http://www.truncate.com',
            'isLink': true,
            'start': 5,
            'end': 21,
          },
        ],
      ),
    );
    test(
      'type and options',
      () => expect(
        detector.find(
          'Does www.truncate.com work with example@truncate.com?',
          type: 'email',
          options: const linkify.LinkifyOptions(truncate: LinkOption.value(10)),
        ),
        [
          {
            'type': 'email',
            'value': 'example@tr…',
            'href': 'mailto:example@truncate.com',
            'isLink': true,
            'start': 32,
            'end': 52,
          },
        ],
      ),
    );
    test('validation callback', () {
      final result = detector.find(
        'foo.com and bar.com and baz.com',
        options: linkify.LinkifyOptions(
          validate: LinkOption.transform((value) => value != 'bar.com'),
        ),
      );
      expect(result, [
        {
          'type': 'url',
          'value': 'foo.com',
          'href': 'http://foo.com',
          'isLink': true,
          'start': 0,
          'end': 7,
        },
        {
          'type': 'url',
          'value': 'baz.com',
          'href': 'http://baz.com',
          'isLink': true,
          'start': 24,
          'end': 31,
        },
      ]);
    });
  });

  group('upstream custom protocols', () {
    setUp(() {
      detector.registerCustomProtocol('view-source');
      detector.registerCustomProtocol('instagram', optionalSlashes: true);
      detector.registerCustomProtocol('magnet', optionalSlashes: true);
    });
    for (final input in [
      'instagram:user/nfrasser',
      'instagram://user/nfrasser',
      'magnet:?xt=urn:btih:5a7f5e0f3ce439e2f1a83e718a8405ec8809110b&dn=ernfkjenrkfk%5FSQ80%5FV%5Fv1.0.0%5Ferfnkerkf%5Ferfnkerkfefrfvegrteggt.net.rar',
      'view-source://http://github.com/',
    ]) {
      test(
        'detects $input',
        () => expect(detector.test(input, type: 'url'), isTrue),
      );
    }
    test(
      'requires double slash',
      () => expect(
        detector.test('view-source:http://github.com/', type: 'url'),
        isFalse,
      ),
    );
    test('registration after init requires reinit', () {
      detector.init();
      detector.registerCustomProtocol('fb');
      expect(detector.test('fb://feed'), isFalse);
      detector.init();
      expect(detector.test('fb://feed'), isTrue);
    });
    for (final scheme in [
      '-',
      '-fb',
      'fb-',
      'git+https',
      'FB',
      'a--b',
      'a\n',
      '',
    ]) {
      test(
        'rejects scheme ${scheme.codeUnits}',
        () => expect(
          () => detector.registerCustomProtocol(scheme),
          throwsArgumentError,
        ),
      );
    }
  });

  group('token API', () {
    test('preserves explicit protocol case', () {
      final token = detector
          .tokenize('Ftps://www.github.com/Hypercontext/linkify')
          .single;
      expect(token.isLink, isTrue);
      expect(token.hasProtocol, isTrue);
      expect(token.toHref('https'), token.value);
      expect(token.toString(), token.value);
    });
    test('default protocol', () {
      final token = detector.tokenize('co.co/?o=%2D&p=@gc#wat').single;
      expect(token.hasProtocol, isFalse);
      expect(token.toHref(), 'http://co.co/?o=%2D&p=@gc#wat');
      expect(token.toObject('https')['href'], 'https://co.co/?o=%2D&p=@gc#wat');
    });
    test('email, text and newline', () {
      final tokens = detector.tokenize('hi a@example.com\n');
      expect(tokens.map((token) => token.type), ['text', 'email', 'nl']);
      expect(tokens[1].toHref('https'), 'mailto:a@example.com');
      expect(tokens.first.isLink, isFalse);
      expect(tokens.last.toHref(), '\n');
    });
    test('Unicode separators preserve source offsets', () {
      final tokens = detector.tokenize(
        'a.com\u2028b.com\u2029c.com\u0085d.com',
      );
      expect(tokens.map((token) => token.type), [
        'url',
        'text',
        'url',
        'text',
        'url',
        'text',
        'url',
      ]);
      expect(tokens.map((token) => token.value), [
        'a.com',
        '\u2028',
        'b.com',
        '\u2029',
        'c.com',
        '\u0085',
        'd.com',
      ]);
      expect(tokens.map((token) => token.start), [0, 5, 6, 11, 12, 17, 18]);
      expect(tokens.map((token) => token.end), [5, 6, 11, 12, 17, 18, 23]);
    });
    test('only LF and CRLF produce newline tokens', () {
      final tokens = detector.tokenize('a.com\r\nb.com\nc.com\rd.com');
      expect(tokens.map((token) => token.type), [
        'url',
        'nl',
        'url',
        'nl',
        'url',
        'text',
        'url',
      ]);
      expect(tokens.map((token) => token.value), [
        'a.com',
        '\r\n',
        'b.com',
        '\n',
        'c.com',
        '\r',
        'd.com',
      ]);
      expect(tokens.map((token) => token.start), [0, 5, 7, 12, 13, 18, 19]);
      expect(tokens.map((token) => token.end), [5, 7, 12, 13, 18, 19, 24]);
    });
    test(
      'localhost port is not a protocol',
      () => expect(
        detector.tokenize('localhost:3000').single.hasProtocol,
        isFalse,
      ),
    );
    test('UTF-16 offsets and source coverage', () {
      const input = '😀中文 example.com\r\n👩‍🔬a@例子.中国';
      final tokens = detector.tokenize(input);
      expect(tokens.map((token) => token.value).join(), input);
      var offset = 0;
      for (final token in tokens) {
        expect(token.start, offset);
        expect(input.substring(token.start, token.end), token.value);
        offset = token.end;
      }
      expect(offset, input.length);
      expect(tokens.first.end, 5);
    });
  });

  group('formatting options', () {
    test('callbacks receive source values, type and token', () {
      final seen = <String>[];
      final result = detector.find(
        'abc.com',
        options: linkify.LinkifyOptions(
          defaultProtocol: 'https',
          format: LinkOption.callback((value, type, token) {
            seen.add('$value:$type:${token.start}');
            return 'ABC';
          }),
          formatHref: LinkOption.callback((value, type, token) {
            seen.add('$value:$type:${token.end}');
            return '$value?q=1';
          }),
          truncate: const LinkOption.value(2),
        ),
      );
      expect(result.single['value'], 'AB…');
      expect(result.single['href'], 'https://abc.com?q=1');
      expect(seen, ['abc.com:url:0', 'https://abc.com:url:7']);
    });
    test('per-type callbacks and fallback', () {
      final result = detector.find(
        'abc.com a@example.com',
        options: linkify.LinkifyOptions(
          format: LinkOption.byType({
            'email': TokenOption.callback(
              (value, token) => '${token.type}:$value',
            ),
          }),
          formatHref: LinkOption.byType({
            'url': TokenOption.callback((href, token) => '$href/${token.type}'),
          }),
          truncate: const LinkOption.byType({'email': TokenOption.value(5)}),
        ),
      );
      expect(result.map((item) => item['value']), ['abc.com', 'email…']);
      expect(result.map((item) => item['href']), [
        'http://abc.com/url',
        'mailto:a@example.com',
      ]);
    });
    test('per-type validation fallback', () {
      final result = detector.find(
        'abc.com a@example.com',
        options: const linkify.LinkifyOptions(
          validate: LinkOption.byType({'url': TokenOption.value(false)}),
        ),
      );
      expect(result.single['type'], 'email');
    });
    test('single argument callbacks in type maps', () {
      final result = detector.find(
        'abc.com a@example.com',
        options: linkify.LinkifyOptions(
          format: LinkOption.byType({
            'url': TokenOption.transform((value) => value.toUpperCase()),
          }),
          validate: LinkOption.byType({
            'email': TokenOption.transform((value) => value.isEmpty),
          }),
        ),
      );
      expect(result.single['value'], 'ABC.COM');
    });
    test('null validation suppresses links', () {
      expect(
        detector.find(
          'abc.com',
          options: const linkify.LinkifyOptions(validate: null),
        ),
        isEmpty,
      );
      expect(
        detector.find(
          'abc.com',
          options: const linkify.LinkifyOptions(
            validate: LinkOption.byType({'url': TokenOption.value(null)}),
          ),
        ),
        isEmpty,
      );
    });
    test(
      'zero disables truncation',
      () => expect(
        detector
            .find(
              'abc.com',
              options: const linkify.LinkifyOptions(
                truncate: LinkOption.value(0),
              ),
            )
            .single['value'],
        'abc.com',
      ),
    );
    test('unknown and empty type filters', () {
      expect(detector.find('abc.com', type: 'unknown'), isEmpty);
      expect(detector.find('abc.com', type: ''), hasLength(1));
    });
  });

  test('reset clears all protocols', () {
    detector.registerCustomProtocol('steam', optionalSlashes: true);
    expect(detector.test('steam:hello'), isTrue);
    detector.reset();
    expect(detector.test('steam:hello'), isFalse);
    expect(detector.test('example.com'), isTrue);
  });
  test('instances isolate protocols', () {
    detector.registerCustomProtocol('steam', optionalSlashes: true);
    expect(detector.test('steam:hello'), isTrue);
    expect(linkify.Linkify().test('steam:hello'), isFalse);
  });
  test('top-level API', () {
    linkify.reset();
    linkify.registerCustomProtocol('steam', optionalSlashes: true);
    linkify.init();
    expect(linkify.test('steam:hello'), isTrue);
    expect(
      linkify.tokenize('example.com').single.toHref(),
      'http://example.com',
    );
    expect(
      linkify
          .find(
            'example.com',
            options: const linkify.LinkifyOptions(defaultProtocol: 'https'),
          )
          .single['href'],
      'https://example.com',
    );
    linkify.reset();
    expect(linkify.test('steam:hello'), isFalse);
  });
  test('test requires a complete link without trimming', () {
    for (final input in [
      '',
      ' example.com',
      'example.com ',
      'example.com\n',
      'abc.com def.com',
    ]) {
      expect(detector.test(input), isFalse, reason: input);
    }
  });
  test('long rejected candidates complete and preserve input', () {
    for (final input in [
      'a' * 51200,
      '${'a.' * 25000}invalidtld',
      '${'😀a.' * 5000}invalidtld',
    ]) {
      expect(
        detector.tokenize(input).map((token) => token.value).join(),
        input,
      );
      expect(detector.find(input), isEmpty);
    }
  });
}
