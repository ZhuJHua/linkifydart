# linkifydart

A dependency-free Dart port of **[linkifyjs 4.3.3](https://github.com/nfrasser/linkifyjs)**
for finding URLs and email addresses in plain text. It preserves the core
scanner/parser model, custom protocols, and UTF-16 source offsets. Works with
Dart 3.0 or later, including Flutter projects.

linkifyjs is by Nick Frasser and is distributed under the
[MIT license](https://github.com/nfrasser/linkifyjs/blob/v4.3.3/LICENSE).
This port is also MIT licensed and retains the original copyright in [LICENSE](LICENSE).

## Install

```yaml
dependencies:
  linkifydart: ^0.1.0
```

```sh
dart pub get
```

## Usage

```dart
import 'package:linkifydart/linkifydart.dart' as linkify;

void main() {
  final links = linkify.find('Visit example.com or email hi@example.com');
  print(links.first['href']); // http://example.com

  print(linkify.test('example.com', type: 'url')); // true
  print(linkify.test(' example.com ')); // false

  for (final token in linkify.tokenize('Visit example.com!')) {
    if (token.isLink) {
      print(token.toHref('https')); // https://example.com
      print('${token.start}:${token.end}'); // 6:17
    }
  }
}
```

`find` returns maps with `type`, `value`, `isLink`, `href`, `start`, and `end`.
`type` is `url` or `email`; `tokenize` also returns `text` and `nl` tokens.
Offsets count UTF-16 code units, matching Dart's `String.substring`, with an
inclusive start and exclusive end. Formatting never changes the source offsets.
`test` requires the entire input to be one link and does not trim whitespace.

Use `Linkify()` for an independent detector with its own custom protocols:

```dart
final detector = linkify.Linkify();
detector.registerCustomProtocol('my-app', optionalSlashes: true);
print(detector.test('my-app:open')); // true
```

Protocol names contain lowercase ASCII letters or digits, optionally separated
by single hyphens. By default, custom protocols require `://`.
Register before first use, or call `init()` to activate later registrations.
`reset()` removes all custom protocols. The top-level API shares one detector.

## API mapping from linkifyjs

| linkifyjs | Dart |
| --- | --- |
| `tokenize(text)` | `tokenize(text)` returns `List<LinkifyToken>` |
| `find(text, type?, options?)` | `find(text, type: ..., options: LinkifyOptions(...))` returns a list of maps |
| `test(text, type?)` | `test(text, type: ...)` |
| `registerCustomProtocol(name, optionalSlashSlash)` | `registerCustomProtocol(name, optionalSlashes: ...)` |
| `init()` / `reset()` | `init()` / `reset()` |
| token `t` / `v` / `tk` | `type` / `value` / `tokens` |
| token `isLink` | `isLink` |
| URL `hasProtocol()` | `hasProtocol` getter; false for other token types |
| token `startIndex()` / `endIndex()` | `start` / `end` getters |
| token `toString()` | `toString()` |
| token `toHref(protocol)` / `toObject(protocol)` | Same methods; optional positional protocol defaults to `http` |

`Linkify` provides the same detection and registration methods as the top-level
API. Named arguments replace the JavaScript overloads. Pass `type: 'url'` or
`type: 'email'` to filter results; null or an empty string accepts both.

## Options

Pass `LinkifyOptions` to `find`:

```dart
final links = linkify.find(
  'example.com hi@example.com',
  options: linkify.LinkifyOptions(
    defaultProtocol: 'https',
    format: linkify.LinkOption.transform((value) => value.toUpperCase()),
    formatHref: linkify.LinkOption.callback(
      (href, type, token) => '$href?start=${token.start}',
    ),
    validate: linkify.LinkOption.byType({
      'email': linkify.TokenOption.transform(
        (value) => value.endsWith('@example.com'),
      ),
    }),
    truncate: const linkify.LinkOption.value(20),
  ),
);
```

| Option | Type | Default |
| --- | --- | --- |
| `defaultProtocol` | `String` | `http`, without `://` |
| `format` | `LinkOption<String>?` | Preserve source text |
| `formatHref` | `LinkOption<String>?` | Preserve the generated destination |
| `validate` | `LinkOption<bool?>?` | Accept every detected link |
| `truncate` | `LinkOption<num?>?` | No truncation |

`LinkOption.value` supplies a constant. `LinkOption.transform` receives the
value. `LinkOption.callback` receives `(value, type, token)`.
`LinkOption.byType` maps token types to `TokenOption.value`,
`TokenOption.transform`, or `TokenOption.callback`; the last receives
`(value, token)`. Types are inferred from the selected option.

Missing per-type entries use the option's default. Null validation, either as
the option or a callback result, suppresses a link. Use
`TokenOption.value(null)` for an explicit null per-type value.
Null and zero truncation limits disable truncation; a negative limit displays
only an ellipsis. Truncation counts UTF-16 code units and appends an ellipsis
after the selected prefix.

Validation runs first, followed by the truncation-limit callback, display
formatting, and destination formatting. The limit applies to the formatted
display text. Callbacks receive source text, except `formatHref`, which receives
the destination with its protocol. Email destinations use `mailto:`; explicit
URL protocols are preserved.

## TLD updates

`dart run tool/update_tlds.dart` downloads the
[IANA TLD list](https://data.iana.org/TLD/tlds-alpha-by-domain.txt), decodes
Punycode labels, checks the trie round trip, and regenerates `lib/src/tlds.dart`.
The two mixed-script German TLDs use the same trie grouping as linkifyjs.
The updater accepts `--source URL-or-file` for offline input and `--output file`
for an alternate destination. It requires no interactive input and exits with
a nonzero code on failure.

The weekly GitHub Action runs the updater and tests, then opens a pull request
when the generated list changes. It can also be run with `workflow_dispatch`.
TLD updates can change which bare domains are recognized.

## Scope

This package contains the core URL/email detector. It does not include linkifyjs
plugins, DOM/HTML rendering, or framework-specific widgets and integration
wrappers. For example, plugin-based mention, hashtag, and IP detection are not
included. The scanner's Unicode letter and emoji tables use Unicode 18.0.

See [example/example.dart](example/example.dart) for a runnable example:

```sh
dart run example/example.dart
```
