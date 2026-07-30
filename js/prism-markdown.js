(function (Prism) {
	// Allow only one line break
	var inner = /(?:\\.|[^\\\n\r]|(?:\n|\r\n?)(?!\n|\r\n?))/.source;

	/**
	 * This function is intended for the creation of the bold or italic pattern.
	 *
	 * @param {string} pattern This pattern must match the string that will be emphasized (e.g. `**foo**`)
	 * @returns {RegExp}
	 */
	function createInlineEmphasis(pattern) {
		var escaped = pattern.replace(/[\\\[\]]/g, '\\$&');
		return RegExp(
			/(^|[^\\])/.source + 
			'(?:' + escaped + ')' + 
			'(?:(?:\\\\\\n|[^\\\\])*?\\n)?' + 
			'(?:(?:\\\\\\n|[^\\\\])*?)'
		);
	}

	Prism.languages.markdown = Prism.languages.extend('markup', {});
	Prism.languages.insertBefore('markdown', 'prolog', {
		'front-matter-block': {
			pattern: /^---[\s\S]*?^---$/m,
			greedy: true,
			inside: {
				'punctuation': /^---|^---$/,
				'front-matter': {
					pattern: /\S+(?:\s+\S+)*/,
					alias: ['yaml', 'language-yaml'],
					inside: Prism.languages.yaml
				}
			}
		},
		'blockquote': {
			// > ...
			pattern: /^>(?:[\t ]*>)*/m,
			alias: 'punctuation'
		},
		'table': {
			pattern: /\|.+?\|(?:\n|\r\n?)[|:][-\t:| ]+(?=\n)/,
			inside: {
				'table-header-row': {
					pattern: /^.*\|(?:\n|\r\n?)\|(?:[-:]\|)+(?=\n)/,
					inside: {
						'table-header': {
							pattern: /\|(?:[^|\r\n])+/,
							alias: 'important'
						},
						'punctuation': /\||[-:]/
					}
				},
				'table-data-rows': {
					pattern: /(?:\n|\r\n?)(?:\|(?:[^|\r\n])+)+(?:\n|\r\n?)/,
					inside: {
						'table-data': {
							pattern: /\|(?:[^|\r\n])+/,
						},
						'punctuation': /\|/
					},
				},
				'punctuation': /\|/
			}
		},
		'code': [
			{
				// Prefixed by 4 spaces or 1 tab and preceded by an empty line
				pattern: /(?:\n|\r\n?)(?:(?:\t|[ ]{4}).*(?:\n|\r\n?))+/,
				alias: 'keyword'
			},
			{
				// ```optional language
				// code block
				// ```
				pattern: /^```[\s\S]*?^```$/m,
				greedy: true,
				inside: {
					'code-block': {
						pattern: /^(```.*(?:\n|\r\n?))[\s\S]+?(?=(?:\n|\r\n?)^```$)/m,
						lookbehind: true
					},
					'code-language': {
						pattern: /^(```).+/,
						lookbehind: true
					},
					'punctuation': /```/
				}
			}
		],
		'title': [
			{
				// title 1
				// =======

				// title 2
				// -------
				pattern: /\S.*(?:\n|\r\n?)(?:==+|--+)(?=[ \t]*$)/m,
				alias: 'important',
				inside: {
					punctuation: /==+$|--+$/
				}
			},
			{
				// # title 1
				// ###### title 6
				pattern: /(^|[^\\])#.+/,
				lookbehind: true,
				alias: 'important',
				inside: {
					punctuation: /^#+|#+$/
				}
			}
		],
		'hr': {
			// ***
			// ---
			// * * *
			// -----------
			pattern: /(^|[^\\])([*-])(?:\s*\2){2,}(?=\s*$)/m,
			lookbehind: true,
			alias: 'punctuation'
		},
		'list': {
			// * item
			// + item
			// - item
			// 1. item
			pattern: /(^|[^\\])(?:[*+-]|\d+\.)(?=[\t ].)/m,
			lookbehind: true,
			alias: 'punctuation'
		},
		'url-reference': {
			// [id]: http://example.com "Optional title"
			// [id]: http://example.com 'Optional title'
			// [id]: http://example.com (Optional title)
			// [id]: <http://example.com> "Optional title"
			pattern: /!?\[[^\]]+\]:[\t ]+(?:\S+|<(?:\\.|[^>\\])+>)(?:[\t ]+(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\)))?/,
			inside: {
				'variable': {
					pattern: /^(!?\[)[^\]]+/,
					lookbehind: true
				},
				'string': /(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\((?:\\.|[^)\\])*\))$/,
				'punctuation': /^[\[\]!:]|[<>]/
			},
			alias: 'url'
		},
		'bold': {
			// **strong**
			// __strong__

			// allow one nested instance of italic text using the same delimiter
			pattern: /(^|[^\\])(\*\*|__)(?:(?:\r?\n|[^\\])|(?:\\.))*?\2/,
			lookbehind: true,
			greedy: true,
			inside: {
				'content': {
					pattern: /(^..)[\s\S]+(?=..$)/,
					lookbehind: true,
					inside: {} // see below
				},
				'punctuation': /\*\*|__/
			}
		},
		'italic': {
			// *em*
			// _em_

			// allow one nested instance of bold text using the same delimiter
			pattern: /(^|[^\\])([*_])(?:(?:\r?\n|[^\\])|(?:\\.))*?\2/,
			lookbehind: true,
			greedy: true,
			inside: {
				'content': {
					pattern: /(^.)[\s\S]+(?=.$)/,
					lookbehind: true,
					inside: {} // see below
				},
				'punctuation': /[*_]/
			}
		},
		'strike': {
			// ~~strike through~~
			// ~strike~
			pattern: /(^|[^\\])(~~?)(?:(?:\r?\n|[^\\])|(?:\\.))*?\2/,
			lookbehind: true,
			greedy: true,
			inside: {
				'content': {
					pattern: /(^~~?)[\s\S]+(?=\1$)/,
					lookbehind: true,
					inside: {} // see below
				},
				'punctuation': /~~?/
			}
		},
		'code-snippet': {
			// `code`
			// ``code``
			pattern: /(^|[^\\`])(?:``[^`\r\n]+(?:`[^`\r\n]+)*``(?!`)|`[^`\r\n]+`(?!`))/,
			lookbehind: true,
			greedy: true,
			alias: ['code', 'keyword']
		},
		'url': {
			// [example](http://example.com "Optional title")
			// [example][id]
			// [example] [id]
			pattern: /(^|[^\\])\[[^\[\]]+\](?:\([^\s)]+(?:[\t ]+"(?:\\.|[^"\\])*")?\)|[ \t]?\[[^\[\]]+\])/,
			lookbehind: true,
			greedy: true,
			inside: {
				'operator': /^!/,
				'content': {
					pattern: /(^\[)[^\]]+(?=\])/,
					lookbehind: true,
					inside: {} // see below
				},
				'variable': {
					pattern: /(^\][ \t]?\[)[^\]]+(?=\]$)/,
					lookbehind: true
				},
				'url': {
					pattern: /(^\]\()[^\s)]+/,
					lookbehind: true
				},
				'string': {
					pattern: /(^[ \t]+)"(?:\\.|[^"\\])*"(?=\)$)/,
					lookbehind: true
				}
			}
		}
	});

	['url', 'bold', 'italic', 'strike'].forEach(function (token) {
		['url', 'bold', 'italic', 'strike', 'code-snippet'].forEach(function (inside) {
			if (token !== inside) {
				Prism.languages.markdown[token].inside.content.inside[inside] = Prism.languages.markdown[inside];
			}
		});
	});

	Prism.hooks.add('after-tokenize', function (env) {
		if (env.language !== 'markdown' && env.language !== 'md') {
			return;
		}

		function walkTokens(tokens) {
			if (!tokens || typeof tokens === 'string') {
				return;
			}

			for (var i = 0, l = tokens.length; i < l; i++) {
				var token = tokens[i];

				if (token.type !== 'code') {
					walkTokens(token.content);
					continue;
				}

				/*
				 * Add the correct `language-xxxx` class to this code block. Keep in mind that the `code-language` token
				 * is optional. But the grammar is defined so that there is only one case we have to handle:
				 *
				 * token.content = [
				 *     <span class="punctuation">```</span>,
				 *     <span class="code-language">xxxx</span>,
				 *     \n, // exactly one new lines (\r or \n or \r\n)
				 *     <span class="code-block">...</span>,
				 *     \n, // exactly one new lines again
				 *     <span class="punctuation">```</span>
				 * ];
				 */

				var codeLang = token.content[1];
				var codeBlock = token.content[3];

				if (codeLang && codeBlock
					&& codeLang.type === 'code-language' && codeBlock.type === 'code-block'
					&& typeof codeLang.content === 'string') {

					// this might be a language that Prism does not support

					// do some replacements to support C++, C#, and F#
					var lang = codeLang.content.replace(/\b(?:csharp|cs|dotnet|fsharp|fs)\b/g, function (matched) {
						return {
							'cs': 'csharp',
							'dotnet': 'csharp',
							'fs': 'fsharp'
						}[matched] || matched;
					}).toLowerCase();

					// get alias(es) and language
					var alias = getAlias(lang) || [];
					if (!Array.isArray(alias)) { alias = [alias]; }
					var aliasMap = {};
					for (var i = 0, l = alias.length; i < l; i++) {
						aliasMap[alias[i]] = true;
					}

					// add aliases and language
					token.attributes = token.attributes || {};
					token.attributes['language-' + lang] = '';
					token.content = createLanguageCodeBlock(token.content, lang, aliasMap);
				}
			}
		}

		function createLanguageCodeBlock(tokens, lang, aliasMap) {
			var tokensCopy = [];
			for (var i = 0, l = tokens.length; i < l; i++) {
				var token = tokens[i];
				var value = token.content;

				if (token.type === 'code-block') {
					var codeLang = lang;
					var grammar = Prism.languages[codeLang];

					if (!grammar) {
						for (var alias in aliasMap) {
							if (Prism.languages[alias]) {
								grammar = Prism.languages[alias];
								codeLang = alias;
								break;
							}
						}
					}

					if (!grammar) {
						grammar = Prism.languages.clike;
					}

					// add code class for styling
					token.classes.push('language-' + codeLang);

					token.content = Prism.highlight(value, grammar, codeLang);
				}

				tokensCopy.push(token);
			}

			return tokensCopy;
		}

		function getAlias(id) {
			if (Prism.languages[id]) {
				return id;
			}
			for (var langId in Prism.languages) {
				var lang = Prism.languages[langId];
				if (typeof lang !== 'function' && lang.alias) {
					if (Array.isArray(lang.alias) && lang.alias.indexOf(id) >= 0) {
						return langId;
					} else if (lang.alias === id) {
						return langId;
					}
				}
			}
			return null;
		}

		walkTokens(env.tokens);
	});

	Prism.hooks.add('wrap', function (env) {
		if (env.type !== 'code-block') {
			return;
		}

		var codeLang = '';
		for (var i = 0, l = env.classes.length; i < l; i++) {
			var cls = env.classes[i];
			var match = /language-(.+)/.exec(cls);
			if (match) {
				codeLang = match[1];
				break;
			}
		}

		var grammar = Prism.languages[codeLang];

		if (!grammar) {
			if (codeLang && codeLang !== 'none' && Prism.plugins.autoloader) {
				var id = 'md-' + new Date().valueOf() + '-' + Math.floor(Math.random() * 1e16);
				env.attributes['id'] = id;

				Prism.plugins.autoloader.loadLanguages(codeLang, function () {
					var ele = document.getElementById(id);
					if (ele) {
						ele.innerHTML = Prism.highlight(ele.textContent, Prism.languages[codeLang], codeLang);
					}
				});
			}
		}
	});

	// Customize Prism for Markdown
	Prism.languages.md = Prism.languages.markdown;

}(Prism));
