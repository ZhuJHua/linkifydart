/// Lexical token category names shared by the scanner and parser.
library;

/// The token category for ASCII letters.
const word = 'WORD';

/// The token category for Unicode letters.
const uword = 'UWORD';

/// The token category for ASCII letters and digits.
const asciiNumerical = 'ASCIINUMERICAL';

/// The token category for Unicode letters and digits.
const alphaNumerical = 'ALPHANUMERICAL';

/// The token category for the localhost name.
const localhost = 'LOCALHOST';

/// The token category for ASCII TLDs.
const tld = 'TLD';

/// The token category for Unicode TLDs.
const utld = 'UTLD';

/// The token category for protocols with optional slashes.
const scheme = 'SCHEME';

/// The token category for protocols requiring slashes.
const slashScheme = 'SLASH_SCHEME';

/// The token category for ASCII digits.
const num = 'NUM';

/// The token category for whitespace.
const ws = 'WS';

/// The token category for newlines.
const nl = 'NL';

/// The token category for an opening brace.
const openBrace = 'OPENBRACE';

/// The token category for a closing brace.
const closeBrace = 'CLOSEBRACE';

/// The token category for an opening bracket.
const openBracket = 'OPENBRACKET';

/// The token category for a closing bracket.
const closeBracket = 'CLOSEBRACKET';

/// The token category for an opening parenthesis.
const openParen = 'OPENPAREN';

/// The token category for a closing parenthesis.
const closeParen = 'CLOSEPAREN';

/// The token category for an opening angle bracket.
const openAngleBracket = 'OPENANGLEBRACKET';

/// The token category for a closing angle bracket.
const closeAngleBracket = 'CLOSEANGLEBRACKET';

/// The token category for a full-width left parenthesis.
const fullWidthLeftParen = 'FULLWIDTHLEFTPAREN';

/// The token category for a full-width right parenthesis.
const fullWidthRightParen = 'FULLWIDTHRIGHTPAREN';

/// The token category for a left corner bracket.
const leftCornerBracket = 'LEFTCORNERBRACKET';

/// The token category for a right corner bracket.
const rightCornerBracket = 'RIGHTCORNERBRACKET';

/// The token category for a left white corner bracket.
const leftWhiteCornerBracket = 'LEFTWHITECORNERBRACKET';

/// The token category for a right white corner bracket.
const rightWhiteCornerBracket = 'RIGHTWHITECORNERBRACKET';

/// The token category for a full-width less-than sign.
const fullWidthLessThan = 'FULLWIDTHLESSTHAN';

/// The token category for a full-width greater-than sign.
const fullWidthGreaterThan = 'FULLWIDTHGREATERTHAN';

/// The token category for an ampersand.
const ampersand = 'AMPERSAND';

/// The token category for an apostrophe.
const apostrophe = 'APOSTROPHE';

/// The token category for an asterisk.
const asterisk = 'ASTERISK';

/// The token category for an at sign.
const at = 'AT';

/// The token category for a backslash.
const backSlash = 'BACKSLASH';

/// The token category for a backtick.
const backTick = 'BACKTICK';

/// The token category for a caret.
const caret = 'CARET';

/// The token category for a colon.
const colon = 'COLON';

/// The token category for a comma.
const comma = 'COMMA';

/// The token category for a dollar sign.
const dollar = 'DOLLAR';

/// The token category for a dot.
const dot = 'DOT';

/// The token category for an equals sign.
const equals = 'EQUALS';

/// The token category for an exclamation mark.
const exclamation = 'EXCLAMATION';

/// The token category for a hyphen.
const hyphen = 'HYPHEN';

/// The token category for a percent sign.
const percent = 'PERCENT';

/// The token category for a vertical bar.
const pipe = 'PIPE';

/// The token category for a plus sign.
const plus = 'PLUS';

/// The token category for a hash sign.
const pound = 'POUND';

/// The token category for a question mark.
const query = 'QUERY';

/// The token category for a double quote.
const quote = 'QUOTE';

/// The token category for a full-width middle dot.
const fullWidthMiddleDot = 'FULLWIDTHMIDDLEDOT';

/// The token category for a semicolon.
const semi = 'SEMI';

/// The token category for a slash.
const slash = 'SLASH';

/// The token category for a tilde.
const tilde = 'TILDE';

/// The token category for an underscore.
const underscore = 'UNDERSCORE';

/// The token category for emoji.
const emoji = 'EMOJI';

/// The token category for other symbols.
const sym = 'SYM';
