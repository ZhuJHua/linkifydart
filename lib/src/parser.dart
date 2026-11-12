/// Parser transitions for links, plain text, and newlines.
library;

import 'fsm.dart';
import 'text.dart' as tk;
import 'token.dart';

/// Combines scanner tokens into links, plain text, and newlines.
class Parser extends MachineBuilder {
  /// Builds parser transitions from the scanner's token [groups].
  Parser(Map<String, List<String>> groups) {
    final qsAccepting = <String>[
      ...groups['domain']!,
      tk.ampersand,
      tk.asterisk,
      tk.at,
      tk.backSlash,
      tk.backTick,
      tk.caret,
      tk.dollar,
      tk.equals,
      tk.hyphen,
      tk.num,
      tk.percent,
      tk.pipe,
      tk.plus,
      tk.pound,
      tk.slash,
      tk.sym,
      tk.tilde,
      tk.underscore,
    ];

    final qsNonAccepting = [
      tk.apostrophe,
      tk.colon,
      tk.comma,
      tk.dot,
      tk.exclamation,
      tk.percent,
      tk.query,
      tk.quote,
      tk.semi,
      tk.openAngleBracket,
      tk.closeAngleBracket,
      tk.openBrace,
      tk.closeBrace,
      tk.closeBracket,
      tk.openBracket,
      tk.openParen,
      tk.closeParen,
      tk.fullWidthLeftParen,
      tk.fullWidthRightParen,
      tk.leftCornerBracket,
      tk.rightCornerBracket,
      tk.leftWhiteCornerBracket,
      tk.rightWhiteCornerBracket,
      tk.fullWidthLessThan,
      tk.fullWidthGreaterThan,
    ];

    final localpartAccepting = [
      tk.ampersand,
      tk.apostrophe,
      tk.asterisk,
      tk.backSlash,
      tk.backTick,
      tk.caret,
      tk.dollar,
      tk.equals,
      tk.hyphen,
      tk.openBrace,
      tk.closeBrace,
      tk.percent,
      tk.pipe,
      tk.plus,
      tk.pound,
      tk.query,
      tk.slash,
      tk.sym,
      tk.tilde,
      tk.underscore,
    ];

    final startState = start;
    final localpart = tt(startState, tk.tilde);
    ta(localpart, localpartAccepting, localpart);
    ta(localpart, groups['domain']!, localpart);

    final domain = State();
    final scheme = State();
    final slashScheme = State();
    ta(startState, groups['domain']!, domain);
    ta(startState, groups['scheme']!, scheme);
    ta(startState, groups['slashscheme']!, slashScheme);

    ta(domain, localpartAccepting, localpart);
    ta(domain, groups['domain']!, domain);

    final localpartAt = tt(domain, tk.at);

    tt(localpart, tk.at, localpartAt);

    tt(scheme, tk.at, localpartAt);
    tt(slashScheme, tk.at, localpartAt);

    final localpartDot = tt(localpart, tk.dot);
    ta(localpartDot, localpartAccepting, localpart);
    ta(localpartDot, groups['domain']!, localpart);

    final emailDomain = State();
    ta(localpartAt, groups['domain']!, emailDomain);
    ta(emailDomain, groups['domain']!, emailDomain);
    final emailDomainDot = tt(emailDomain, tk.dot);
    ta(emailDomainDot, groups['domain']!, emailDomain);

    final email = State('email');
    ta(emailDomainDot, groups['tld']!, email);
    ta(emailDomainDot, groups['utld']!, email);
    tt(localpartAt, tk.localhost, email);

    final emailDomainHyphen = tt(emailDomain, tk.hyphen);
    tt(emailDomainHyphen, tk.hyphen, emailDomainHyphen);
    ta(emailDomainHyphen, groups['domain']!, emailDomain);
    ta(email, groups['domain']!, emailDomain);
    tt(email, tk.dot, emailDomainDot);
    tt(email, tk.hyphen, emailDomainHyphen);

    final domainHyphen = tt(domain, tk.hyphen);
    final domainDot = tt(domain, tk.dot);
    tt(domainHyphen, tk.hyphen, domainHyphen);
    ta(domainHyphen, groups['domain']!, domain);
    ta(domainDot, localpartAccepting, localpart);
    ta(domainDot, groups['domain']!, domain);

    final domainDotTld = State('url');
    ta(domainDot, groups['tld']!, domainDotTld);
    ta(domainDot, groups['utld']!, domainDotTld);
    ta(domainDotTld, groups['domain']!, domain);
    ta(domainDotTld, localpartAccepting, localpart);
    tt(domainDotTld, tk.dot, domainDot);
    tt(domainDotTld, tk.hyphen, domainHyphen);
    tt(domainDotTld, tk.at, localpartAt);

    final domainDotTldColon = tt(domainDotTld, tk.colon);
    final domainDotTldColonPort = State('url');
    ta(domainDotTldColon, groups['numeric']!, domainDotTldColonPort);

    final url = State('url');

    final urlNonaccept = State();

    ta(url, qsAccepting, url);
    ta(url, qsNonAccepting, urlNonaccept);
    ta(urlNonaccept, qsAccepting, url);
    ta(urlNonaccept, qsNonAccepting, urlNonaccept);

    tt(domainDotTld, tk.slash, url);
    tt(domainDotTldColonPort, tk.slash, url);

    final schemeColon = tt(scheme, tk.colon);
    final slashSchemeColon = tt(slashScheme, tk.colon);
    final slashSchemeColonSlash = tt(slashSchemeColon, tk.slash);

    final uriPrefix = tt(slashSchemeColonSlash, tk.slash);

    ta(scheme, groups['domain']!, domain);
    tt(scheme, tk.dot, domainDot);
    tt(scheme, tk.hyphen, domainHyphen);
    ta(slashScheme, groups['domain']!, domain);
    tt(slashScheme, tk.dot, domainDot);
    tt(slashScheme, tk.hyphen, domainHyphen);

    ta(schemeColon, groups['domain']!, url);
    tt(schemeColon, tk.slash, url);
    tt(schemeColon, tk.query, url);
    ta(uriPrefix, groups['domain']!, url);
    ta(uriPrefix, qsAccepting, url);
    tt(uriPrefix, tk.slash, url);

    final bracketPairs = [
      [tk.openBrace, tk.closeBrace],
      [tk.openBracket, tk.closeBracket],
      [tk.openParen, tk.closeParen],
      [tk.openAngleBracket, tk.closeAngleBracket],
      [tk.fullWidthLeftParen, tk.fullWidthRightParen],
      [tk.leftCornerBracket, tk.rightCornerBracket],
      [tk.leftWhiteCornerBracket, tk.rightWhiteCornerBracket],
      [tk.fullWidthLessThan, tk.fullWidthGreaterThan],
    ];

    for (var index = 0; index < bracketPairs.length; index++) {
      final [opening, closing] = bracketPairs[index];
      final urlOpen = tt(url, opening);

      tt(urlNonaccept, opening, urlOpen);

      final urlOpenQ = State('url');
      ta(urlOpen, qsAccepting, urlOpenQ);

      final urlOpenSyms = State();
      ta(urlOpen, qsNonAccepting, urlOpenSyms);

      tt(urlOpen, closing, url);

      ta(urlOpenQ, qsAccepting, urlOpenQ);
      ta(urlOpenQ, qsNonAccepting, urlOpenSyms);
      ta(urlOpenSyms, qsAccepting, urlOpenQ);
      ta(urlOpenSyms, qsNonAccepting, urlOpenSyms);

      tt(urlOpenQ, closing, url);
      tt(urlOpenSyms, closing, url);
    }

    tt(startState, tk.localhost, domainDotTld);
    tt(startState, tk.nl, 'nl');
  }

  /// The initial parser state.
  final State start = State();

  /// Parses [tokens] while preserving text and UTF-16 offsets from [input].
  List<LinkifyToken> parse(String input, List<ScanToken> tokens) {
    final result = <LinkifyToken>[];
    final memo = <(State, int), (String, int)?>{};
    var cursor = 0;
    var textStart = 0;
    while (cursor < tokens.length) {
      var state = start;
      var index = cursor;
      final path = <(State, int)>[];
      (String, int)? accepted;
      while (true) {
        final key = (state, index);
        if (memo.containsKey(key)) {
          accepted = memo[key];
          break;
        }
        path.add(key);
        final next =
            index < tokens.length ? state.go(tokens[index].type) : null;
        if (next == null) break;
        state = next;
        index++;
      }
      // Cache suffix results so rejected candidates cannot repeatedly rescan long inputs.
      for (final key in path.reversed) {
        if (accepted == null && key.$1.token != null) {
          accepted = (key.$1.token!, key.$2);
        }
        memo[key] = accepted;
      }
      if (accepted == null) {
        cursor++;
        continue;
      }
      if (textStart < cursor) {
        result.add(_token('text', input, tokens, textStart, cursor));
      }
      result.add(_token(accepted.$1, input, tokens, cursor, accepted.$2));
      cursor = accepted.$2;
      textStart = cursor;
    }
    if (textStart < tokens.length) {
      result.add(_token('text', input, tokens, textStart, tokens.length));
    }
    return result;
  }

  LinkifyToken _token(
    String type,
    String input,
    List<ScanToken> tokens,
    int begin,
    int end,
  ) =>
      LinkifyToken(
        type,
        input.substring(tokens[begin].start, tokens[end - 1].end),
        tokens.sublist(begin, end),
      );
}
