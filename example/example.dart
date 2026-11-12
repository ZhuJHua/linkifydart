import 'package:linkifydart/linkifydart.dart' as linkify;

void main() {
  const input = 'Visit example.com or email hello@example.com.';
  print('Links: ${linkify.find(input)}');
  print('Whole URL: ${linkify.test('example.com', type: 'url')}');

  for (final token in linkify.tokenize(input)) {
    if (token.isLink) {
      print('${token.type} at ${token.start}:${token.end}: '
          '${token.toHref('https')}');
    }
  }

  final formatted = linkify.find(
    input,
    options: linkify.LinkifyOptions(
      defaultProtocol: 'https',
      format: linkify.LinkOption.transform((value) => value.toUpperCase()),
      validate: linkify.LinkOption.byType({
        'email': linkify.TokenOption.transform(
          (value) => value.endsWith('@example.com'),
        ),
      }),
      truncate: const linkify.LinkOption.value(16),
    ),
  );
  print('Formatted links: $formatted');
}
