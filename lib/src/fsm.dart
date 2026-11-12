/// Finite-state machine transitions used by the scanner and parser.
library;

import 'unicode.dart';

/// Character categories recognized by scanner transitions.
enum CharacterClass {
  /// Lowercase ASCII letters.
  asciiLetter,

  /// Unicode letters from the supported property table.
  letter,

  /// Unicode emoji from the supported property table.
  emoji,

  /// ASCII decimal digits.
  digit,

  /// Whitespace code points recognized by the scanner.
  space;

  /// Whether the first code point of nonempty [input] belongs to this class.
  bool matches(String input) {
    final point = input.runes.first;
    return switch (this) {
      asciiLetter => point >= 97 && point <= 122,
      letter => inRanges(point, letterRanges),
      emoji => inRanges(point, emojiRanges),
      digit => point >= 48 && point <= 57,
      space => point >= 9 && point <= 13 ||
          point == 32 ||
          point == 160 ||
          point == 0x1680 ||
          point >= 0x2000 && point <= 0x200a ||
          point == 0x2028 ||
          point == 0x2029 ||
          point == 0x202f ||
          point == 0x205f ||
          point == 0x3000 ||
          point == 0xfeff,
    };
  }
}

/// A state with exact, character-class, and fallback transitions.
class State {
  /// Creates a state, optionally accepting [token].
  State([this.token]);

  /// The accepted token category, or null for a non-accepting state.
  String? token;

  /// Transitions keyed by exact input values.
  final Map<String, State> jumps = {};

  /// Ordered character-class transitions; null targets are skipped.
  final List<(CharacterClass, State?)> patterns = [];

  /// The transition used when no exact or character-class entry matches.
  State? fallback;

  /// Returns the transition for [input], or null if no transition applies.
  State? go(String input) {
    final exact = jumps[input];
    if (exact != null) return exact;
    for (final (pattern, next) in patterns) {
      if (next != null && pattern.matches(input)) return next;
    }
    return fallback;
  }
}

/// Builds transitions and tracks related token categories.
class MachineBuilder {
  /// Creates a builder with no token groups.
  MachineBuilder();

  /// Token categories indexed by group name.
  final Map<String, List<String>> groups = {};

  /// Adds [token] to [flags] and their implied groups.
  void addToGroups(String token, List<String> flags) {
    final expanded = flags.toSet();
    if (expanded.contains('numeric')) {
      expanded.addAll(['asciinumeric', 'alphanumeric']);
    }
    if (expanded.contains('ascii')) {
      expanded.addAll(['asciinumeric', 'alpha']);
    }
    if (expanded.contains('asciinumeric') || expanded.contains('alpha')) {
      expanded.add('alphanumeric');
    }
    if (expanded.contains('alphanumeric') || expanded.contains('emoji')) {
      expanded.add('domain');
    }
    for (final flag in expanded) {
      final group = groups.putIfAbsent(flag, () => []);
      if (!group.contains(token)) group.add(token);
    }
  }

  /// Adds an exact transition, inheriting an existing transition's properties.
  ///
  /// [next] is a target [State], an accepting token name, or null.
  State tt(State state, String input, [Object? next, List<String>? flags]) {
    if (next is State) {
      state.jumps[input] = next;
      return next;
    }
    final template = state.go(input);
    final result = State(template?.token);
    if (template != null) {
      result.jumps.addAll(template.jumps);
      result.patterns.addAll(template.patterns);
      result.fallback = template.fallback;
    }
    if (next is String && next.isNotEmpty) {
      final inherited = [
        for (final entry in groups.entries)
          if (entry.value.contains(result.token)) entry.key,
        ...?flags,
      ];
      addToGroups(next, inherited);
      result.token = next;
    }
    state.jumps[input] = result;
    return result;
  }

  /// Adds the same exact transition for every value in [inputs].
  void ta(State state, List<String> inputs, [Object? next]) {
    for (final input in inputs) {
      tt(state, input, next);
    }
  }

  /// Adds a character-class transition and optional token group [flags].
  State tr(
    State state,
    CharacterClass pattern, [
    Object? next,
    List<String>? flags,
  ]) {
    final result = next is State ? next : State(next as String?);
    if (next is String && flags != null) addToGroups(next, flags);
    state.patterns.add((pattern, result));
    return result;
  }

  /// Adds exact transitions through each UTF-16 code unit in [input].
  State ts(State state, String input, [Object? next, List<String>? flags]) {
    for (var index = 0; index < input.length - 1; index++) {
      state = tt(state, input[index]);
    }
    return input.isEmpty
        ? state
        : tt(state, input[input.length - 1], next, flags);
  }
}
