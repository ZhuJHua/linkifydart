/// Lexical scanning and compact TLD decoding.
library;

import 'fsm.dart';
import 'text.dart' as tk;
import 'tlds.dart';
import 'token.dart';

/// Scans text into lexical tokens with UTF-16 source offsets.
class Scanner extends MachineBuilder {
  /// Builds transitions for built-in and [customSchemes] protocols.
  ///
  /// Each custom entry contains a name and whether `//` is optional.
  Scanner([List<(String, bool)> customSchemes = const []]) {
    final startState = start;
    final tlds = decodeTlds(encodedTlds);
    final utlds = decodeTlds(encodedUtlds);
    tt(startState, "'", tk.apostrophe);
    tt(startState, '{', tk.openBrace);
    tt(startState, '}', tk.closeBrace);
    tt(startState, '[', tk.openBracket);
    tt(startState, ']', tk.closeBracket);
    tt(startState, '(', tk.openParen);
    tt(startState, ')', tk.closeParen);
    tt(startState, '<', tk.openAngleBracket);
    tt(startState, '>', tk.closeAngleBracket);
    tt(startState, '（', tk.fullWidthLeftParen);
    tt(startState, '）', tk.fullWidthRightParen);
    tt(startState, '「', tk.leftCornerBracket);
    tt(startState, '」', tk.rightCornerBracket);
    tt(startState, '『', tk.leftWhiteCornerBracket);
    tt(startState, '』', tk.rightWhiteCornerBracket);
    tt(startState, '＜', tk.fullWidthLessThan);
    tt(startState, '＞', tk.fullWidthGreaterThan);
    tt(startState, '&', tk.ampersand);
    tt(startState, '*', tk.asterisk);
    tt(startState, '@', tk.at);
    tt(startState, '`', tk.backTick);
    tt(startState, '^', tk.caret);
    tt(startState, ':', tk.colon);
    tt(startState, ',', tk.comma);
    tt(startState, '\$', tk.dollar);
    tt(startState, '.', tk.dot);
    tt(startState, '=', tk.equals);
    tt(startState, '!', tk.exclamation);
    tt(startState, '-', tk.hyphen);
    tt(startState, '%', tk.percent);
    tt(startState, '|', tk.pipe);
    tt(startState, '+', tk.plus);
    tt(startState, '#', tk.pound);
    tt(startState, '?', tk.query);
    tt(startState, '"', tk.quote);
    tt(startState, '/', tk.slash);
    tt(startState, ';', tk.semi);
    tt(startState, '~', tk.tilde);
    tt(startState, '_', tk.underscore);
    tt(startState, '\\', tk.backSlash);
    tt(startState, '・', tk.fullWidthMiddleDot);

    final num = tr(startState, CharacterClass.digit, tk.num, ['numeric']);
    tr(num, CharacterClass.digit, num);
    final asciinumeric = tr(
      num,
      CharacterClass.asciiLetter,
      tk.asciiNumerical,
      ['asciinumeric'],
    );
    final alphanumeric = tr(num, CharacterClass.letter, tk.alphaNumerical, [
      'alphanumeric',
    ]);

    final word = tr(startState, CharacterClass.asciiLetter, tk.word, ['ascii']);
    tr(word, CharacterClass.digit, asciinumeric);
    tr(word, CharacterClass.asciiLetter, word);
    tr(asciinumeric, CharacterClass.digit, asciinumeric);
    tr(asciinumeric, CharacterClass.asciiLetter, asciinumeric);

    final uWord = tr(startState, CharacterClass.letter, tk.uword, ['alpha']);
    tr(uWord, CharacterClass.asciiLetter);
    tr(uWord, CharacterClass.digit, alphanumeric);
    tr(uWord, CharacterClass.letter, uWord);
    tr(alphanumeric, CharacterClass.digit, alphanumeric);
    tr(alphanumeric, CharacterClass.asciiLetter);
    tr(alphanumeric, CharacterClass.letter, alphanumeric);

    final nl = tt(startState, lf, tk.nl, ['whitespace']);
    final cr = tt(startState, carriageReturn, tk.ws, ['whitespace']);
    final ws = tr(startState, CharacterClass.space, tk.ws, ['whitespace']);
    tt(startState, objectReplacement, ws);
    tt(cr, lf, nl);
    tt(cr, objectReplacement, ws);
    tr(cr, CharacterClass.space, ws);
    tt(ws, carriageReturn);
    tt(ws, lf);
    tr(ws, CharacterClass.space, ws);
    tt(ws, objectReplacement, ws);

    final emoji = tr(startState, CharacterClass.emoji, tk.emoji, ['emoji']);
    tt(emoji, '#');
    tr(emoji, CharacterClass.emoji, emoji);
    tt(emoji, emojiVariation, emoji);

    final emojiJoiner = tt(emoji, emojiJoinerCharacter);
    tt(emojiJoiner, '#');
    tr(emojiJoiner, CharacterClass.emoji, emoji);

    final wordjr = <(CharacterClass, State?)>[
      (CharacterClass.asciiLetter, word),
      (CharacterClass.digit, asciinumeric),
    ];
    final uwordjr = <(CharacterClass, State?)>[
      (CharacterClass.asciiLetter, null),
      (CharacterClass.letter, uWord),
      (CharacterClass.digit, alphanumeric),
    ];
    for (var index = 0; index < tlds.length; index++) {
      fastts(startState, tlds[index], tk.tld, tk.word, wordjr);
    }
    for (var index = 0; index < utlds.length; index++) {
      fastts(startState, utlds[index], tk.utld, tk.uword, uwordjr);
    }
    addToGroups(tk.tld, ['tld', 'ascii']);
    addToGroups(tk.utld, ['utld', 'alpha']);

    fastts(startState, 'file', tk.scheme, tk.word, wordjr);
    fastts(startState, 'mailto', tk.scheme, tk.word, wordjr);
    fastts(startState, 'http', tk.slashScheme, tk.word, wordjr);
    fastts(startState, 'https', tk.slashScheme, tk.word, wordjr);
    fastts(startState, 'ftp', tk.slashScheme, tk.word, wordjr);
    fastts(startState, 'ftps', tk.slashScheme, tk.word, wordjr);
    addToGroups(tk.scheme, ['scheme', 'ascii']);
    addToGroups(tk.slashScheme, ['slashscheme', 'ascii']);

    customSchemes = [...customSchemes]
      ..sort((left, right) => left.$1.compareTo(right.$1));
    for (var index = 0; index < customSchemes.length; index++) {
      final sch = customSchemes[index].$1;
      final optionalSlashSlash = customSchemes[index].$2;
      final flags = optionalSlashSlash ? ['scheme'] : ['slashscheme'];
      if (sch.contains('-')) {
        flags.add('domain');
      } else if (!sch.split('').any(CharacterClass.asciiLetter.matches)) {
        flags.add('numeric');
      } else if (sch.split('').any(CharacterClass.digit.matches)) {
        flags.add('asciinumeric');
      } else {
        flags.add('ascii');
      }

      ts(startState, sch, sch, flags);
    }

    ts(startState, 'localhost', tk.localhost, ['ascii']);

    startState.fallback = State(tk.sym);
  }

  /// The initial scanner state.
  final State start = State();

  /// The carriage-return character.
  static const carriageReturn = '\r';

  /// The line-feed character.
  static const lf = '\n';

  /// The emoji presentation variation selector.
  static const emojiVariation = '\ufe0f';

  /// The zero-width joiner used in emoji sequences.
  static const emojiJoinerCharacter = '\u200d';

  /// The object replacement character, treated as whitespace.
  static const objectReplacement = '\ufffc';

  /// Adds a word path with default tokens and character-class [patterns].
  State fastts(
    State state,
    String input,
    String token,
    String defaultToken,
    List<(CharacterClass, State?)> patterns,
  ) {
    for (var index = 0; index < input.length - 1; index++) {
      final char = input[index];
      state = state.jumps.putIfAbsent(
        char,
        () => State(defaultToken)..patterns.addAll(patterns),
      );
    }
    final next = State(token)..patterns.addAll(patterns);
    state.jumps[input[input.length - 1]] = next;
    return next;
  }

  /// Scans [input], matching ASCII case-insensitively and preserving its text.
  List<ScanToken> scan(String input) {
    final characters = stringToArray(
      input.replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => match[0]!.toLowerCase(),
      ),
    );
    final result = <ScanToken>[];
    var index = 0;
    var offset = 0;
    while (index < characters.length) {
      var state = start;
      final begin = offset;
      var acceptedIndex = index;
      var acceptedOffset = offset;
      String? acceptedType;
      while (index < characters.length) {
        final next = state.go(characters[index]);
        if (next == null) break;
        state = next;
        offset += characters[index++].length;
        if (state.token != null) {
          acceptedIndex = index;
          acceptedOffset = offset;
          acceptedType = state.token;
        }
      }
      index = acceptedIndex;
      offset = acceptedOffset;
      result.add(
        ScanToken(acceptedType!, input.substring(begin, offset), begin, offset),
      );
    }
    return result;
  }
}

/// Splits [input] into code-point strings, preserving unpaired surrogates.
List<String> stringToArray(String input) {
  final result = <String>[];
  var index = 0;
  while (index < input.length) {
    final first = input.codeUnitAt(index);
    final paired = first >= 0xd800 &&
        first <= 0xdbff &&
        index + 1 < input.length &&
        input.codeUnitAt(index + 1) >= 0xdc00 &&
        input.codeUnitAt(index + 1) <= 0xdfff;
    final width = paired ? 2 : 1;
    result.add(input.substring(index, index + width));
    index += width;
  }
  return result;
}

/// Decodes the compact trie representation of a TLD list.
List<String> decodeTlds(String encoded) {
  final words = <String>[];
  final stack = <String>[];
  var index = 0;
  while (index < encoded.length) {
    var end = index;
    while (end < encoded.length &&
        encoded.codeUnitAt(end) >= 48 &&
        encoded.codeUnitAt(end) <= 57) {
      end++;
    }
    if (end > index) {
      words.add(stack.join());
      final count = int.parse(encoded.substring(index, end));
      stack.removeRange(stack.length - count, stack.length);
      index = end;
    } else {
      stack.add(encoded[index++]);
    }
  }
  return words;
}
