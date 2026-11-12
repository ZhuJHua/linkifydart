/// Link detection and custom protocol registration.
library;

import 'options.dart';
import 'parser.dart';
import 'scanner.dart';
import 'token.dart';

/// A link detector with an isolated custom protocol registry.
///
/// Methods mirror the top-level API without sharing its registrations.
/// Register custom protocols before [tokenize], [find], or [test], or call
/// [init] to activate registrations added after the first use.
class Linkify {
  /// Creates a detector with the built-in protocols and no custom protocols.
  Linkify();

  final List<(String, bool)> _customProtocols = [];
  Scanner? _scanner;
  Parser? _parser;

  /// Registers a custom protocol named [scheme].
  ///
  /// The name must contain lowercase ASCII letters or digits, optionally
  /// separated by single hyphens. Invalid names throw [ArgumentError].
  /// If [optionalSlashes] is true, both `scheme:value` and `scheme://value`
  /// are recognized; otherwise `://` is required.
  /// Registrations after initialization become active on [init].
  void registerCustomProtocol(String scheme, {bool optionalSlashes = false}) {
    if (!RegExp(r'^[0-9a-z]+(-[0-9a-z]+)*$').hasMatch(scheme)) {
      throw ArgumentError.value(scheme, 'scheme', 'Invalid protocol format');
    }
    _customProtocols.add((scheme, optionalSlashes));
  }

  /// Rebuilds the machines, including protocols registered after first use.
  void init() {
    final scanner = Scanner(_customProtocols);
    _scanner = scanner;
    _parser = Parser(scanner.groups);
  }

  /// Clears the state machines and all custom protocols.
  void reset() {
    _scanner = null;
    _parser = null;
    _customProtocols.clear();
  }

  /// Splits [input] into URL, email, plain text, and newline tokens.
  ///
  /// Tokens preserve the original text and its UTF-16 source offsets.
  /// An empty input produces an empty list.
  List<LinkifyToken> tokenize(String input) {
    if (_scanner == null) init();
    return _parser!.parse(input, _scanner!.scan(input));
  }

  /// Finds links in [input], applying [options] to each accepted link.
  ///
  /// Set [type] to `'url'` or `'email'` to filter results. A null or empty type
  /// accepts both. Each result contains `type`, `value`, `isLink`, `href`,
  /// `start`, and `end`; offsets always refer to the original input.
  List<Map<String, Object>> find(
    String input, {
    String? type,
    LinkifyOptions options = const LinkifyOptions(),
  }) {
    return [
      for (final token in tokenize(input))
        if (token.isLink &&
            (type == null || type.isEmpty || token.type == type) &&
            options.check(token))
          options.toObject(token),
    ];
  }

  /// Whether all of [input] is a single link of the requested [type].
  ///
  /// A null or empty type accepts URLs and emails. Surrounding whitespace is
  /// significant and is not trimmed.
  bool test(String input, {String? type}) {
    final tokens = tokenize(input);
    return tokens.length == 1 &&
        tokens.first.isLink &&
        (type == null || type.isEmpty || tokens.first.type == type);
  }
}

final Linkify _defaultLinkify = Linkify();

/// Splits [input] into links, text, and newlines using the shared detector.
///
/// See [Linkify.tokenize] for token types and source offsets.
List<LinkifyToken> tokenize(String input) => _defaultLinkify.tokenize(input);

/// Finds links in [input] using the shared detector.
///
/// See [Linkify.find] for [type] filtering, [options], and result fields.
List<Map<String, Object>> find(
  String input, {
  String? type,
  LinkifyOptions options = const LinkifyOptions(),
}) =>
    _defaultLinkify.find(input, type: type, options: options);

/// Whether all of [input] is a single link of the requested [type].
///
/// Uses the shared detector. See [Linkify.test] for whitespace handling.
bool test(String input, {String? type}) =>
    _defaultLinkify.test(input, type: type);

/// Registers [scheme] on the shared detector.
///
/// See [Linkify.registerCustomProtocol] for valid names and [optionalSlashes].
/// Call [init] if the detector has already been used.
void registerCustomProtocol(String scheme, {bool optionalSlashes = false}) =>
    _defaultLinkify.registerCustomProtocol(
      scheme,
      optionalSlashes: optionalSlashes,
    );

/// Rebuilds the shared detector, activating all registered custom protocols.
void init() => _defaultLinkify.init();

/// Clears the shared detector and removes all registered custom protocols.
void reset() => _defaultLinkify.reset();
