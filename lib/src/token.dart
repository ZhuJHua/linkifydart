/// Tokens and source offsets returned by link detection.
library;

/// A scanner token with UTF-16 offsets into the original input.
class ScanToken {
  /// Creates a token spanning [start] (inclusive) to [end] (exclusive).
  ///
  /// [type] is the scanner's lexical category and [value] is the source text.
  const ScanToken(this.type, this.value, this.start, this.end);

  /// The lexical category, such as `'WORD'`, `'TLD'`, or `'DOT'`.
  final String type;

  /// The original source text covered by this token.
  final String value;

  /// The inclusive UTF-16 code-unit offset into the original input.
  final int start;

  /// The exclusive UTF-16 code-unit offset into the original input.
  final int end;

  /// Returns the lexical category, value, and offsets as `t`, `v`, `s`, and `e`.
  Map<String, Object> toObject() => {
        't': type,
        'v': value,
        's': start,
        'e': end,
      };
}

/// A URL, email, plain text, or newline, with UTF-16 source offsets.
class LinkifyToken {
  /// Creates a token with an immutable copy of its scanner [tokens].
  ///
  /// [type] is `'url'`, `'email'`, `'text'`, or `'nl'`, and [value] preserves
  /// the original text. Supply a nonempty list so [start] and [end] are defined.
  LinkifyToken(this.type, this.value, List<ScanToken> tokens)
      : tokens = List.unmodifiable(tokens);

  /// The token category: `'url'`, `'email'`, `'text'`, or `'nl'`.
  final String type;

  /// The original source text covered by this token.
  final String value;

  /// The immutable scanner tokens making up this token.
  final List<ScanToken> tokens;

  /// Whether this token represents a URL or email address.
  bool get isLink => type == 'url' || type == 'email';

  /// Whether a URL token already contains an explicit protocol.
  ///
  /// Returns false for emails, plain text, and newlines.
  bool get hasProtocol =>
      type == 'url' &&
      tokens.length >= 2 &&
      tokens.first.type != 'LOCALHOST' &&
      tokens[1].type == 'COLON';

  /// The inclusive UTF-16 code-unit offset into the original input.
  int get start => tokens.first.start;

  /// The exclusive UTF-16 code-unit offset into the original input.
  int get end => tokens.last.end;

  /// Returns the original source [value].
  @override
  String toString() => value;

  /// Returns a destination using [defaultProtocol] for URLs without a protocol.
  ///
  /// Email addresses receive `mailto:`. Explicit URL protocols and non-link
  /// values are preserved. The default protocol omits the `://` suffix.
  String toHref([String defaultProtocol = 'http']) => switch (type) {
        'email' => 'mailto:$value',
        'url' => hasProtocol ? value : '$defaultProtocol://$value',
        _ => value,
      };

  /// Returns `type`, `value`, `isLink`, `href`, `start`, and `end` in a map.
  ///
  /// Uses [toHref] with [defaultProtocol] to construct the destination.
  Map<String, Object> toObject([String defaultProtocol = 'http']) => {
        'type': type,
        'value': value,
        'isLink': isLink,
        'href': toHref(defaultProtocol),
        'start': start,
        'end': end,
      };
}
