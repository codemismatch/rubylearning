/**
 * Ruby language support for Prism.js
 */
(function (Prism) {
	Prism.languages.ruby = Prism.languages.extend('clike', {
		'comment': [
			/#.*/,
			{
				pattern: /^=begin\s[\s\S]*?^=end/m,
				greedy: true
			}
		],
		'class-name': {
			pattern: /(\b(?:class)\s+|\bcatch\s+\()[\w.\\]+/i,
			lookbehind: true,
			inside: {
				'punctuation': /[.\\]/
			}
		},
		'keyword': /\b(?:alias|and|BEGIN|begin|break|case|class|def|define_method|defined|do|each|else|elsif|END|end|ensure|extend|for|if|in|include|module|new|next|nil|not|or|prepend|protected|private|public|raise|redo|require|rescue|retry|return|self|super|then|throw|undef|unless|until|when|while|yield)\b/,
		'operator': /\.{2,3}|&\.|===|<?=>|[!=]?~|(?:&&|\|\||<<|>>|\*\*|[+\-*/%<>!^&|=])=?|([?:$@])/,
		'punctuation': /[(){}[\];.,]/
	});

	Prism.languages.insertBefore('ruby', 'number', {
		'symbol': {
			pattern: /:[a-zA-Z_]\w*[?!]?/,
			greedy: true
		},
		'builtin': /\b(?:Array|Bignum|Binding|Class|Continuation|Dir|Exception|FalseClass|File|Fixnum|Float|Hash|Integer|IO|MatchData|Method|Module|NilClass|Numeric|Object|Proc|Range|Regexp|String|Struct|Symbol|TMS|Thread|ThreadGroup|Time|TrueClass|puts|print|p|gets|readline|getc|putc|printf|sprintf|warn|abort|exit|sleep|at_exit|fork|exec|system|load|require|require_relative|gem|catch|throw|raise|fail|loop|caller|binding|eval|local_variables|global_variables|instance_variables|class_variables|block_given|lambda|proc|define_method|method_missing|respond_to|send|public_send|instance_eval|instance_exec|class_eval|class_exec|module_eval|module_exec)\b/,
		'constant': /\b[A-Z]\w*(?:[?!]|\b)/
	});

	Prism.languages.ruby.string = [
		{
			pattern: /%[qQiIwWxs]?([^a-zA-Z0-9\s{(\[<])(?:(?!\1)[^\\]|\\[\s\S])*\1/,
			greedy: true,
			inside: {
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /%[qQiIwWxs]?\([^)]*\)/,
			greedy: true,
			inside: {
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /%[qQiIwWxs]?\{[^}]*\}/,
			greedy: true,
			inside: {
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /%[qQiIwWxs]?\[[^\]]*\]/,
			greedy: true,
			inside: {
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /%[qQiIwWxs]?<[^>]*>/,
			greedy: true,
			inside: {
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /("|')(?:#\{[^}]+\}|#(?!\{)|\\(?:\r\n|[\s\S])|(?!\1)[^\\#\r\n])*\1/,
			greedy: true,
			inside: {
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /<<[-~]?([a-z_]\w*)[\r\n](?:.*[\r\n])*?[\t ]*\1/i,
			alias: 'heredoc-string',
			greedy: true,
			inside: {
				'delimiter': {
					pattern: /^<<[-~]?[a-z_]\w*|[a-z_]\w*$/i,
					alias: 'symbol',
					inside: {
						'punctuation': /^<<[-~]?/
					}
				},
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		},
		{
			pattern: /<<[-~]?'([a-z_]\w*)'[\r\n](?:.*[\r\n])*?[\t ]*\1/i,
			alias: 'heredoc-string',
			greedy: true,
			inside: {
				'delimiter': {
					pattern: /^<<[-~]?'[a-z_]\w*'|[a-z_]\w*$/i,
					alias: 'symbol',
					inside: {
						'punctuation': /^<<[-~]?'|'$/,
					}
				}
			}
		},
		{
			pattern: /<<[-~]?"([a-z_]\w*)"[\r\n](?:.*[\r\n])*?[\t ]*\1/i,
			alias: 'heredoc-string',
			greedy: true,
			inside: {
				'delimiter': {
					pattern: /^<<[-~]?"[a-z_]\w*"|[a-z_]\w*$/i,
					alias: 'symbol',
					inside: {
						'punctuation': /^<<[-~]?"|"$/,
					}
				},
				'interpolation': {
					pattern: /#\{[^}]+\}/,
					inside: {
						'delimiter': {
							pattern: /^#\{|\}$/,
							alias: 'punctuation'
						},
						rest: Prism.languages.ruby
					}
				}
			}
		}
	];

	Prism.languages.rb = Prism.languages.ruby;
}(Prism));