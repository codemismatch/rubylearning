#!/usr/bin/env ruby

# Universal path fixer for both local and GitHub Pages deployments
# Usage: ruby fix-paths.rb [--local | --github]

require 'fileutils'
require 'optparse'

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: fix-paths.rb [options]"
  
  opts.on("--local", "Fix paths for local development") do
    options[:mode] = :local
  end
  
  opts.on("--github", "Fix paths for GitHub Pages deployment") do
    options[:mode] = :github
  end
end.parse!

# Default to github mode if not specified
options[:mode] ||= :github

# The base path depends on deployment mode
BASE_PATH = options[:mode] == :local ? '' : '/rubylearning'
mode_name = options[:mode] == :local ? "local development" : "GitHub Pages"

puts "=== Fixing paths for #{mode_name} ==="

# Get the public directory
public_dir = 'public'
unless Dir.exist?(public_dir)
  puts "Error: public directory not found!"
  exit 1
end

# Function to backup a file before modifying it
def backup_file(file)
  backup = "#{file}.bak"
  if !File.exist?(backup)
    FileUtils.cp(file, backup)
    puts "  - Created backup: #{backup}"
  end
end

# Fix HTML files
puts "Fixing HTML files..."
Dir.glob("#{public_dir}/**/*.html").each do |file|
  # Skip if it's a directory (fixes the tutorials.html directory issue)
  next if File.directory?(file)
  
  content = File.read(file)
  backup_file(file)
  
  # Fix unprocessed ERB template variables
  # Replace <%= base_path %> with the actual path
  content.gsub!(/<%=\s*base_path\s*%>/, BASE_PATH)
  
  # Handle base tag depending on mode
  if options[:mode] == :local
    # For local: remove base tag or set to root
    if content.include?('<base href=')
      content.gsub!(/<base href=["'][^"']*["']>/, '<base href="/">')
      puts "  - Updated base tag for local in: #{file}"
    end
  else
    # For GitHub: ensure correct base tag
    if !content.include?('<base href=') && content.include?('<head>')
      content.gsub!('<head>', "<head>\n  <base href=\"#{BASE_PATH}/\">")
      puts "  - Added base tag to: #{file}"
    elsif content.include?('<base href=')
      content.gsub!(/<base href=["'][^"']*["']>/, "<base href=\"#{BASE_PATH}/\">")
      puts "  - Updated base tag for GitHub in: #{file}"
    end
  end
  
  # Handle links and script paths
  if options[:mode] == :local
    # For local: use root-relative paths
    updated_content = content.gsub(/href=["']((?!http|https|\/\/|#)[^"']*)["']/) do |match|
      path = $1
      # Don't modify already root-relative paths that start with /
      if path.start_with?('/')
        match
      else
        # Make root-relative
        "href=\"/#{path}\""
      end
    end
    
    # Do the same for src attributes
    updated_content = updated_content.gsub(/src=["']((?!http|https|\/\/|#)[^"']*)["']/) do |match|
      path = $1
      if path.start_with?('/')
        match
      else
        "src=\"/#{path}\""
      end
    end
  else
    # For GitHub: prefix with BASE_PATH
    updated_content = content
      .gsub(/href=["']\/(?!http|https|\/|#)([^"']*)["']/, "href=\"#{BASE_PATH}/\\1\"")
      .gsub(/src=["']\/(?!http|https|\/|#)([^"']*)["']/, "src=\"#{BASE_PATH}/\\1\"")
      
    # Fix relative paths that don't start with /
    updated_content = updated_content
      .gsub(/href=["']((?!http|https|\/|#|#{BASE_PATH})[^"'\/][^"']*)["']/, "href=\"#{BASE_PATH}/\\1\"")
      .gsub(/src=["']((?!http|https|\/|#|#{BASE_PATH})[^"'\/][^"']*)["']/, "src=\"#{BASE_PATH}/\\1\"")
  end
  
  if content != updated_content
    File.write(file, content)
    puts "  - Updated paths in: #{file}"
  end
end

# Fix CSS files (url() references)
puts "Fixing CSS files..."
Dir.glob("#{public_dir}/**/*.css").each do |file|
  # Skip if it's a directory
  next if File.directory?(file)
  
  content = File.read(file)
  backup_file(file)
  
  if options[:mode] == :local
    # For local: use root-relative paths in CSS
    updated_content = content.gsub(/url\(["']?((?!http|https|\/\/|data:|#)[^\/][^\)'"]*)["']?\)/) do |match|
      path = $1
      "url(/#{path})"
    end
  else
    # For GitHub: prefix with BASE_PATH
    updated_content = content
      .gsub(/url\(["']?\/(?!http|https|\/|#)([^\)'"]*?)["']?\)/, "url(#{BASE_PATH}/\\1)")
      
    # Also fix relative paths
    updated_content = updated_content
      .gsub(/url\(["']?((?!http|https|\/|#|#{BASE_PATH})[^\/][^\)'"]*)["']?\)/, "url(#{BASE_PATH}/\\1)")
  end
    
  if content != updated_content
    File.write(file, updated_content)
    puts "  - Updated paths in: #{file}"
  end
end

# Fix JS files (if they contain any absolute paths)
puts "Fixing JavaScript files..."
Dir.glob("#{public_dir}/**/*.js").each do |file|
  # Skip if it's a directory
  next if File.directory?(file)
  
  # Fix Prism.js regex issue in prism-markdown.js
  if file.end_with?('prism-markdown.js')
    content = File.read(file)
    backup_file(file)
    
    # Check if it contains the problematic regex pattern
    if content.include?('\\2') && content.include?('createInlineEmphasis')
      # Replace with fixed version
      fixed_content = <<~JS
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
			pattern: /(^|[^\\])\[[^\[\]]+\]\([^\(\)]+\)/,
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
      JS
      
      File.write(file, fixed_content)
      puts "  - Fixed Prism.js regex issue in: #{file}"
    else
      puts "  - Prism.js file already fixed or using a different version."
    end
  elsif options[:mode] == :github
    # For other JS files, fix paths for GitHub Pages
    content = File.read(file)
    updated_content = content
      .gsub(/(["'])\/(?!http|https|\/|#)([^"']*)["']/, "\\1#{BASE_PATH}/\\2\\1")
      
    if content != updated_content
      File.write(file, updated_content)
      puts "  - Updated paths in: #{file}"
    end
  end
end

# Fix ERB template variables that weren't processed in generated HTML files
puts "Fixing unprocessed ERB template variables..."
Dir.glob("#{public_dir}/**/*.html").each do |file|
  # Skip if it's a directory
  next if File.directory?(file)
  
  content = File.read(file)
  
  # Replace all kinds of ERB template variables that might be left unprocessed
  if content.include?('<%=') || content.include?('<%')
    # Replace template variables with appropriate values
    updated_content = content
      .gsub(/<%=\s*base_path\s*%>/, BASE_PATH)
      .gsub(/<%=\s*site\.name\s*%>/, "Ruby Learning")
      .gsub(/<%=\s*Time\.now\.year\s*%>/, Time.now.year.to_s)
      .gsub(/<%=\s*page\.title\s*%>/, "Ruby Learning")
      .gsub(/<%=\s*page\.description\s*%>/, "A Ruby Learning site")
      .gsub(/<%.*?%>/, '') # Remove any remaining ERB tags
    
    if content != updated_content
      File.write(file, updated_content)
      puts "  - Fixed template variables in: #{file}"
    end
  end
end

# Additional GitHub Pages specific actions
if options[:mode] == :github
  # Create a .nojekyll file to prevent GitHub from processing the site with Jekyll
  File.write("#{public_dir}/.nojekyll", '')
  puts "Created .nojekyll file"
  
  # Create a CNAME file if it doesn't exist
  unless File.exist?("#{public_dir}/CNAME")
    # The CNAME file is empty by default, you'll need to add your domain if needed
    File.write("#{public_dir}/CNAME", '')
    puts "Created empty CNAME file (add your custom domain if needed)"
  end
  
  # Create a simple 404 page if it doesn't exist
  unless File.exist?("#{public_dir}/404.html")
    File.write("#{public_dir}/404.html", <<~HTML)
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta http-equiv="refresh" content="3;url=#{BASE_PATH}/">
        <title>Page Not Found</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          h1 { color: #d9534f; }
          a { color: #0275d8; text-decoration: none; }
          a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <h1>Page Not Found</h1>
        <p>Sorry, the page you were looking for doesn't exist.</p>
        <p>You will be redirected to the <a href="#{BASE_PATH}/">homepage</a> in a few seconds.</p>
      </body>
      </html>
    HTML
    puts "Created 404.html page"
  end
end

puts "=== Path fixing complete! ==="
if options[:mode] == :local
  puts "Your site should now work correctly on local development server"
else
  puts "Your site should now work correctly at https://metcritical.github.io#{BASE_PATH}/"
end
