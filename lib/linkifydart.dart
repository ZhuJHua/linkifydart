/// Detects URLs and email addresses in plain text.
///
/// A dependency-free Dart port of
/// [linkifyjs 4.3.3](https://github.com/nfrasser/linkifyjs), distributed under
/// the MIT license. Source offsets use UTF-16 code units, as Dart strings do.
///
/// ```dart
/// import 'package:linkifydart/linkifydart.dart' as linkify;
///
/// final links = linkify.find('Visit example.com or email hi@example.com');
/// print(links.first['href']); // http://example.com
///
/// final token = linkify.tokenize('example.com').single;
/// print(token.toHref('https')); // https://example.com
/// ```
///
/// Use [Linkify] for an isolated custom protocol registry and [LinkifyOptions]
/// to configure formatting, validation, and truncation in [find].
library;

export 'src/linkify.dart';
export 'src/options.dart';
export 'src/token.dart';
