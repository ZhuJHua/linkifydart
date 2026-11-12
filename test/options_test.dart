import 'package:test/test.dart';
import 'package:linkifydart/linkifydart.dart' hide test;

void main() {
  const input = 'abc.com bar.com a@example.com';
  const values = ['abc.com', 'bar.com', 'a@example.com'];
  const hrefs = ['http://abc.com', 'http://bar.com', 'mailto:a@example.com'];
  final scenarios = <String, (LinkifyOptions, List<String>, List<String>)>{
    'format transform': (
      LinkifyOptions(
        format: LinkOption.transform((value) => value.toUpperCase()),
      ),
      ['ABC.COM', 'BAR.COM', 'A@EXAMPLE.COM'],
      hrefs,
    ),
    'format callback': (
      LinkifyOptions(
        format: LinkOption.callback(
          (value, type, token) => '$type:${token.start}:$value',
        ),
      ),
      ['url:0:abc.com', 'url:8:bar.com', 'email:16:a@example.com'],
      hrefs,
    ),
    'format per-type transform': (
      LinkifyOptions(
        format: LinkOption.byType({
          'url': TokenOption.transform((value) => value.toUpperCase()),
        }),
      ),
      ['ABC.COM', 'BAR.COM', 'a@example.com'],
      hrefs,
    ),
    'format per-type callback': (
      LinkifyOptions(
        format: LinkOption.byType({
          'url': TokenOption.callback((value, token) => '${token.end}:$value'),
        }),
      ),
      ['7:abc.com', '15:bar.com', 'a@example.com'],
      hrefs,
    ),
    'formatHref transform': (
      LinkifyOptions(
        formatHref: LinkOption.transform(
          (href) => href.replaceAll('http://', 'https://'),
        ),
      ),
      values,
      ['https://abc.com', 'https://bar.com', 'mailto:a@example.com'],
    ),
    'formatHref callback': (
      LinkifyOptions(
        formatHref: LinkOption.callback(
          (href, type, token) => '$href?type=$type&end=${token.end}',
        ),
      ),
      values,
      [
        'http://abc.com?type=url&end=7',
        'http://bar.com?type=url&end=15',
        'mailto:a@example.com?type=email&end=29',
      ],
    ),
    'formatHref per-type transform': (
      LinkifyOptions(
        formatHref: LinkOption.byType({
          'url': TokenOption.transform(
            (href) => href.replaceAll('http://', 'https://'),
          ),
        }),
      ),
      values,
      ['https://abc.com', 'https://bar.com', 'mailto:a@example.com'],
    ),
    'formatHref per-type callback': (
      LinkifyOptions(
        formatHref: LinkOption.byType({
          'email': TokenOption.callback(
            (href, token) => '$href?start=${token.start}',
          ),
        }),
      ),
      values,
      ['http://abc.com', 'http://bar.com', 'mailto:a@example.com?start=16'],
    ),
    'validate transform': (
      LinkifyOptions(
        validate: LinkOption.transform((value) => value != 'bar.com'),
      ),
      ['abc.com', 'a@example.com'],
      ['http://abc.com', 'mailto:a@example.com'],
    ),
    'validate callback': (
      LinkifyOptions(
        validate: LinkOption.callback(
          (value, type, token) =>
              type == 'email' || token.start == 0 && value.startsWith('abc'),
        ),
      ),
      ['abc.com', 'a@example.com'],
      ['http://abc.com', 'mailto:a@example.com'],
    ),
    'validate per-type transform': (
      LinkifyOptions(
        validate: LinkOption.byType({
          'url': TokenOption.transform((value) => value != 'bar.com'),
        }),
      ),
      ['abc.com', 'a@example.com'],
      ['http://abc.com', 'mailto:a@example.com'],
    ),
    'validate per-type callback': (
      LinkifyOptions(
        validate: LinkOption.byType({
          'url': TokenOption.callback(
            (value, token) => token.start == 0 && value.startsWith('abc'),
          ),
        }),
      ),
      ['abc.com', 'a@example.com'],
      ['http://abc.com', 'mailto:a@example.com'],
    ),
    'truncate transform': (
      LinkifyOptions(
        truncate: LinkOption.transform(
          (value) => value.startsWith('a@') ? 0 : 3,
        ),
      ),
      ['abc…', 'bar…', 'a@example.com'],
      hrefs,
    ),
    'truncate callback': (
      LinkifyOptions(
        truncate: LinkOption.callback(
          (value, type, token) =>
              type == 'url' ? token.end - token.start - 4 : value.length,
        ),
      ),
      ['abc…', 'bar…', 'a@example.com'],
      hrefs,
    ),
    'truncate per-type transform': (
      LinkifyOptions(
        truncate: LinkOption.byType({
          'url': TokenOption.transform((value) => value.indexOf('.')),
        }),
      ),
      ['abc…', 'bar…', 'a@example.com'],
      hrefs,
    ),
    'truncate per-type callback': (
      LinkifyOptions(
        truncate: LinkOption.byType({
          'url': TokenOption.callback(
            (value, token) => token.end - token.start == value.length ? 3 : 0,
          ),
        }),
      ),
      ['abc…', 'bar…', 'a@example.com'],
      hrefs,
    ),
  };
  for (final entry in scenarios.entries) {
    test('unannotated ${entry.key}', () {
      final result = find(input, options: entry.value.$1);
      expect(result.map((link) => link['value']), entry.value.$2);
      expect(result.map((link) => link['href']), entry.value.$3);
    });
  }

  test('callback order, source arguments and filtered links', () {
    final calls = <String>[];
    final result = find(
      'abc.com bar.com',
      options: LinkifyOptions(
        defaultProtocol: 'https',
        validate: LinkOption.callback((value, type, token) {
          calls.add('validate:$value:$type:${token.start}');
          return value != 'bar.com';
        }),
        truncate: LinkOption.callback((value, type, token) {
          calls.add('truncate:$value:$type:${token.start}');
          return 3;
        }),
        format: LinkOption.callback((value, type, token) {
          calls.add('format:$value:$type:${token.start}');
          return value.toUpperCase();
        }),
        formatHref: LinkOption.callback((href, type, token) {
          calls.add('formatHref:$href:$type:${token.start}');
          return '$href?end=${token.end}';
        }),
      ),
    );
    expect(result.single, {
      'type': 'url',
      'value': 'ABC…',
      'isLink': true,
      'href': 'https://abc.com?end=7',
      'start': 0,
      'end': 7,
    });
    expect(calls, [
      'validate:abc.com:url:0',
      'truncate:abc.com:url:0',
      'format:abc.com:url:0',
      'formatHref:https://abc.com:url:0',
      'validate:bar.com:url:8',
    ]);
  });

  test('nullable validation and truncation callbacks', () {
    expect(
      find(
        'abc.com',
        options: LinkifyOptions(
          validate: LinkOption.transform(
            (value) => value.isEmpty ? true : null,
          ),
        ),
      ),
      isEmpty,
    );
    expect(
      find(
        'abc.com',
        options: LinkifyOptions(
          truncate: LinkOption.transform(
            (value) => value.isNotEmpty ? null : 0,
          ),
        ),
      ).single['value'],
      'abc.com',
    );
    expect(
      find(
        input,
        options: LinkifyOptions(
          validate: LinkOption.byType({
            'url': TokenOption.callback(
              (value, token) =>
                  value.length == token.end - token.start ? null : true,
            ),
          }),
          truncate: LinkOption.byType({
            'email': TokenOption.callback(
              (value, token) =>
                  value.length == token.end - token.start ? null : 0,
            ),
          }),
        ),
      ).single['value'],
      'a@example.com',
    );
  });

  test('constant options and missing type keys retain defaults', () {
    const options = LinkifyOptions(
      format: LinkOption.byType({'url': TokenOption.value('URL')}),
      formatHref: LinkOption.value('destination'),
      validate: LinkOption.byType({'email': TokenOption.value(null)}),
      truncate: LinkOption.value(0),
    );
    final result = find(input, options: options);
    expect(result.map((link) => link['value']), ['URL', 'URL']);
    expect(result.map((link) => link['href']), ['destination', 'destination']);
  });
}
