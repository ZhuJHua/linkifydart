/// Typed formatting, validation, and truncation options.
library;

import 'token.dart';

/// A typed constant, transformation, callback, or per-token-type option.
///
/// Use with [LinkifyOptions] to format links or select which links to include.
sealed class LinkOption<T> {
  const LinkOption._();

  /// Uses [value] for every token.
  const factory LinkOption.value(T value) = _LinkValue<T>;

  /// Computes an option from the source text, or href for href formatting.
  const factory LinkOption.transform(T Function(String value) callback) =
      _LinkTransform<T>;

  /// Computes an option from the value, token type, and source token.
  const factory LinkOption.callback(
    T Function(String value, String type, LinkifyToken token) callback,
  ) = _LinkCallback<T>;

  /// Resolves options by token type, such as `'url'` or `'email'`.
  ///
  /// Missing keys use the default for the corresponding [LinkifyOptions]
  /// field. An explicit nullable value is distinct from a missing key.
  const factory LinkOption.byType(Map<String, TokenOption<T>> options) =
      _LinkByType<T>;

  T _resolve(String value, LinkifyToken token, T fallback);
}

/// An option for one token type in [LinkOption.byType].
sealed class TokenOption<T> {
  const TokenOption._();

  /// Uses [value] for every token of the selected type.
  const factory TokenOption.value(T value) = _TokenValue<T>;

  /// Computes an option from the source text, or href for href formatting.
  const factory TokenOption.transform(T Function(String value) callback) =
      _TokenTransform<T>;

  /// Computes an option from the value and source token.
  const factory TokenOption.callback(
    T Function(String value, LinkifyToken token) callback,
  ) = _TokenCallback<T>;

  T _resolve(String value, LinkifyToken token);
}

final class _LinkValue<T> extends LinkOption<T> {
  const _LinkValue(this.value) : super._();
  final T value;

  @override
  T _resolve(String value, LinkifyToken token, T fallback) => this.value;
}

final class _LinkTransform<T> extends LinkOption<T> {
  const _LinkTransform(this.callback) : super._();
  final T Function(String value) callback;

  @override
  T _resolve(String value, LinkifyToken token, T fallback) => callback(value);
}

final class _LinkCallback<T> extends LinkOption<T> {
  const _LinkCallback(this.callback) : super._();
  final T Function(String value, String type, LinkifyToken token) callback;

  @override
  T _resolve(String value, LinkifyToken token, T fallback) =>
      callback(value, token.type, token);
}

final class _LinkByType<T> extends LinkOption<T> {
  const _LinkByType(this.options) : super._();
  final Map<String, TokenOption<T>> options;

  @override
  T _resolve(String value, LinkifyToken token, T fallback) {
    final option = options[token.type];
    return option == null ? fallback : option._resolve(value, token);
  }
}

final class _TokenValue<T> extends TokenOption<T> {
  const _TokenValue(this.value) : super._();
  final T value;

  @override
  T _resolve(String value, LinkifyToken token) => this.value;
}

final class _TokenTransform<T> extends TokenOption<T> {
  const _TokenTransform(this.callback) : super._();
  final T Function(String value) callback;

  @override
  T _resolve(String value, LinkifyToken token) => callback(value);
}

final class _TokenCallback<T> extends TokenOption<T> {
  const _TokenCallback(this.callback) : super._();
  final T Function(String value, LinkifyToken token) callback;

  @override
  T _resolve(String value, LinkifyToken token) => callback(value, token);
}

/// Formatting and validation options applied to detected links.
///
/// Validation runs before conversion. Conversion resolves [truncate], then
/// [format], then [formatHref]. Callbacks receive the original source text,
/// except [formatHref] callbacks, which receive the destination.
class LinkifyOptions {
  /// Creates options with identity formatting and validation enabled.
  ///
  /// The default has no truncation and uses `'http'` for URLs without a
  /// protocol. Pass [LinkOption] values or callbacks to override each option.
  const LinkifyOptions({
    this.defaultProtocol = 'http',
    this.format,
    this.formatHref,
    this.validate = const LinkOption<bool?>.value(true),
    this.truncate = const LinkOption<num?>.value(double.infinity),
  });

  /// The protocol used for bare URLs, without the `://` suffix.
  final String defaultProtocol;

  /// Formats the displayed value before truncation.
  ///
  /// Null or a missing per-type option preserves the original text.
  final LinkOption<String>? format;

  /// Formats the destination after [defaultProtocol] has been applied.
  ///
  /// Null or a missing per-type option preserves the destination.
  final LinkOption<String>? formatHref;

  /// Determines whether a detected link is included.
  ///
  /// Only true accepts a token. Null, including a callback returning null,
  /// rejects it; missing per-type entries accept it.
  final LinkOption<bool?>? validate;

  /// Limits the formatted value's length in UTF-16 code units.
  ///
  /// Values longer than the limit receive an additional ellipsis. Null, zero,
  /// and infinity disable truncation; negative limits produce only an ellipsis.
  /// Source offsets and destinations are unaffected.
  final LinkOption<num?>? truncate;

  /// Whether [token] is accepted by [validate].
  bool check(LinkifyToken token) =>
      validate?._resolve(token.value, token, true) == true;

  /// Converts [token] to a map with formatting and truncation applied.
  ///
  /// Preserves the token's type, link flag, and source offsets. This method
  /// does not validate the token; call [check] separately when needed.
  Map<String, Object> toObject(LinkifyToken token) {
    final limit = truncate?._resolve(token.value, token, double.infinity);
    var value =
        format?._resolve(token.value, token, token.value) ?? token.value;
    if (limit != null && limit != 0 && value.length > limit) {
      value = '${value.substring(0, limit < 0 ? 0 : limit.toInt())}…';
    }
    final href = token.toHref(defaultProtocol);
    return {
      ...token.toObject(defaultProtocol),
      'value': value,
      'href': formatHref?._resolve(href, token, href) ?? href,
    };
  }
}
