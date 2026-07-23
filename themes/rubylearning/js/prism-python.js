/* PrismJS 1.30.0 language definition for Python.
 * Extracted from the official Prism distribution.
 * https://prismjs.com/
 */
(function (Prism) {
  Prism.languages.python = {
    'comment': {
      pattern: /(^|[^\\])#.*/,
      lookbehind: true
    },
    'triple-quoted-string': {
      pattern: /("""|''')[\s\S]+?\1/,
      greedy: true,
      alias: 'string'
    },
    'string': {
      pattern: /("|')(?:\\.|(?!\1)[^\\\r\n])*\1/,
      greedy: true
    },
    'function': {
      pattern: /((?:^|\s)def[ \t]+)[a-zA-Z_]\w*(?=\s*\()/g,
      lookbehind: true
    },
    'class-name': {
      pattern: /(\bclass\s+)[a-zA-Z_]\w*(?=\s*[:\(])/,
      lookbehind: true
    },
    'decorator': {
      pattern: /(^\s*)@\w+(?:\.\w+)*/,
      lookbehind: true,
      alias: ['annotation', 'punctuation']
    },
    'keyword': /\b(?:and|as|assert|async|await|break|class|continue|def|del|elif|else|except|False|finally|for|from|global|if|import|in|is|lambda|None|nonlocal|not|or|pass|raise|return|True|try|while|with|yield)\b/,
    'builtin': /\b(?:abs|all|any|ascii|bin|bool|bytearray|bytes|callable|chr|classmethod|compile|complex|dict|dir|divmod|enumerate|eval|exec|filter|float|format|frozenset|getattr|globals|hasattr|hash|help|hex|id|input|int|isinstance|issubclass|iter|len|list|locals|map|max|memoryview|min|next|object|oct|open|ord|pow|print|property|range|repr|reversed|round|set|setattr|slice|sorted|staticmethod|str|sum|super|tuple|type|vars|zip)\b/,
    'boolean': /\b(?:True|False)\b/,
    'number': /\b(?:0[xX][\da-fA-F]+|0[oO][0-7]+|0[bB][01]+|\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)\b/,
    'operator': /[-+%=]=?|!=|<=?|>=?|\/\/=?|\*\*=?|[@]/,
    'punctuation': /[{}[\];(),.:]/
  };
})(Prism);

