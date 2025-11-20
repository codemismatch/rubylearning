/**
 * Ruby Exec Support Module
 * Handles runnable Ruby code blocks with Run/Check buttons
 */

async function addRubyExecSupport() {
  // Add Ruby execution support when there are runnable code blocks
  // OR when the inline Ruby console drawer is present.
  const rubyBlocks = document.querySelectorAll('.code-window pre[data-executable="true"], pre[data-practice-chapter]');
  const hasInlineConsole = !!document.querySelector('.ruby-irb[data-ruby-console="true"]');
  if (rubyBlocks.length === 0 && !hasInlineConsole) return;
  
  try {
    // Use the Ruby WASM loader module
    const vm = await window.RubyWasmLoader.initializeRubyVM();
    
    // Initialize stdlib polyfills (Time, JSON, StringIO)
    if (window.RubyStdlibPolyfills) {
      window.RubyStdlibPolyfills.initializeRubyStdlibPolyfills(vm);
    }
    
    // Initialize test framework
    if (window.RubyTestFramework) {
      window.RubyTestFramework.initializeRubyTestFramework(vm);
    }

    // Wire interactive stdin via Ruby's JS bridge
    try {
      const setupResult = vm.eval(`
        require 'js'
        
        # Override Kernel#gets to use JS prompt
        module Kernel
          alias_method :__original_wasm_gets, :gets
          
          def gets(*args)
            # Prompt via JS - use JS.global.call syntax
            result = JS.global.call(:prompt, "Ruby input >")
            if result.nil?
              return nil
            end
            result_str = result.to_s
            return nil if result_str == "null"
            result_str + "\\n"
          end
        end
        
        # Test that gets override works
        $gets_test = defined?(gets) ? "method_defined" : "method_undefined"
        "gets_override_ready"
      `);
      console.log('stdin override installed:', setupResult.toString());
      
      const getsTest = vm.eval('$gets_test');
      console.log('gets method status:', getsTest.toString());
    } catch (err) {
      console.error('Failed to install stdin override:', err);
    }

    // Initialize any inline Ruby consoles (virtual irb) before wiring code blocks
    if (hasInlineConsole && window.RubyConsole) {
      window.RubyConsole.initRubyConsoles(vm);
    }

    // Progress tracking across both practice items and runnable examples
    const chapterKeyPrefix = `rl:chapter:${window.location.pathname.replace(/\/$/, '')}`;
    let exampleCounter = 0;

    rubyBlocks.forEach((pre, index) => {
      // Accept either explicit ruby code blocks or ruby-exec markers
      const codeBlock = pre.querySelector('code.language-ruby, code.ruby-exec');
      if (!codeBlock) return;

      const practiceChapter = pre.dataset.practiceChapter || codeBlock.dataset.practiceChapter;
      const practiceIndex = pre.dataset.practiceIndex ? parseInt(pre.dataset.practiceIndex, 10) : null;
      const practiceTest = pre.dataset.test || codeBlock.dataset.test || "";
      const isPracticeCheck = !!practiceChapter && !Number.isNaN(practiceIndex) && practiceTest.trim().length > 0;
      // Index for non-practice example blocks
      const exampleIndex = isPracticeCheck ? null : exampleCounter++;

      // Store reference to the original plain text for reliable code extraction
      let currentPlainText = (codeBlock.textContent || '').replace(/\s+$/, '');
      codeBlock.dataset.plainText = currentPlainText;
      const editorWrapper = pre.parentElement;
      
      // Use the overlay editor module
      const overlay = window.CodeOverlayEditor.initOverlayEditor(pre, codeBlock, currentPlainText, (latestValue) => {
        currentPlainText = latestValue;
        codeBlock.dataset.plainText = latestValue;
      });
      const textarea = overlay.textarea;

      // Create output area
      const outputArea = document.createElement('div');
      outputArea.className = 'output-area';
      const outputContent = document.createElement('pre');
      outputContent.className = 'output-content';
      outputArea.appendChild(outputContent);

      // Add run/check button to the header
      const header = pre.closest('.code-window')?.querySelector('.code-header') || pre.parentElement?.querySelector('.code-header');
      if (header && !header.querySelector('.run-button')) {
        // For practice blocks, only show Check button (which runs tests)
        // For non-practice blocks, show Run button
        const mainButton = document.createElement('button');
        mainButton.className = 'run-button';
        
        if (isPracticeCheck) {
          mainButton.classList.add('check-button');
          mainButton.textContent = '✔ Check';
        } else {
          mainButton.innerHTML = '▶ &nbsp;Run';
        }
        
        header.appendChild(mainButton);

        // Insert output area after the <pre>
        editorWrapper.parentNode.insertBefore(outputArea, editorWrapper.nextSibling);

        // Shared execution logic
        const executeCode = async (runTests) => {
          // CRITICAL: Always extract the current plain text, not from DOM
          const userCode = currentPlainText.trim();
          outputContent.textContent = 'Executing Ruby code...\n';

          try {
            const heredocTag = 'RUBYEXEC';
            const coreConstants = new Set([
              'String', 'Integer', 'Numeric', 'Float', 'Fixnum', 'Bignum',
              'Array', 'Hash', 'Range', 'Symbol', 'Object', 'Kernel',
              'Enumerable', 'Comparable', 'File', 'Dir', 'IO', 'Process'
            ]);

            const normalized = userCode.replace(/^(\s*)(class|module)\s+([A-Z]\w*)/gm, (match, indent, keyword, name) => {
              const qualified = coreConstants.has(name) ? `::${name}` : name;
              return `${indent}${keyword} ${qualified}`;
            });
            const programLines = [
              "require 'js'",
              "",
              // Include test framework for practice tests
              ...(isPracticeCheck && practiceTest.trim().length > 0 && window.RubyTestFramework 
                ? [window.RubyTestFramework.getTestFrameworkCode()] 
                : []),
              "",
              "$__exec_output_buffer__ = +\"\"",
              "$__last_prompt_line__ = nil",
              "",
              "# Create a simple StringIO-like wrapper for output",
              "class SimpleStringIO",
              "  def initialize(buffer)",
              "    @buffer = buffer",
              "  end",
              "  def string",
              "    @buffer",
              "  end",
              "  def puts(*args)",
              "    if args.empty?",
              "      @buffer << \"\\n\"",
              "    else",
              "      args.each { |arg| @buffer << arg.to_s << \"\\n\" }",
              "    end",
              "    nil",
              "  end",
              "  def print(*args)",
              "    @buffer << args.join",
              "    nil",
              "  end",
              "  def write(str)",
              "    @buffer << str.to_s",
              "    str.to_s.length",
              "  end",
              "  def truncate(pos = 0)",
              "    @buffer.slice!(pos..-1)",
              "    pos",
              "  end",
              "  def rewind",
              "    # No-op for string buffer",
              "    0",
              "  end",
              "end",
              "",
              "$__exec_output__ = SimpleStringIO.new($__exec_output_buffer__)",
              "",
              "# Override Kernel methods to capture output and provide gets",
              "module Kernel",
              "  # Capture output to string buffer",
              "  def puts(*args)",
              "    if args.empty?",
              "      $__exec_output_buffer__ << \"\\n\"",
              "      $__last_prompt_line__ = nil",
              "    else",
              "      args.each do |arg|",
              "        $__exec_output_buffer__ << arg.to_s << \"\\n\"",
              "        $__last_prompt_line__ = arg.to_s",
              "      end",
              "    end",
              "    nil",
              "  end",
              "",
              "  def print(*args)",
              "    text = args.join",
              "    $__exec_output_buffer__ << text",
              "    $__last_prompt_line__ = text unless text.empty?",
              "    nil",
              "  end",
              "",
              "  def p(*args)",
              "    args.each { |arg| $__exec_output_buffer__ << arg.inspect << \"\\n\" }",
              "    args.length <= 1 ? args.first : args",
              "  end",
              "",
              "  # Override gets to prompt via JS when available, using the",
              "  # last printed line as the prompt text when possible.",
              "  alias __typophic_original_gets gets unless method_defined?(:__typophic_original_gets)",
              "  def gets(*args)",
              "    if defined?(JS) && JS.respond_to?(:global)",
              "      prompt_text = $__last_prompt_line__.to_s.strip",
              "      prompt_text = 'Ruby input >' if prompt_text.empty?",
              "      result = JS.global.call(:prompt, prompt_text)",
              "      return nil if result.nil?",
              "      result.to_s + \"\\n\"",
              "    else",
              "      __typophic_original_gets(*args)",
              "    end",
              "  end",
              "end",
              ""
            ];

            // For practice blocks, always run tests (Check button)
            if (isPracticeCheck && practiceTest.trim().length > 0) {
              // Detect test format: unit test (uses assertions) vs regex (checks output.string)
              const isUnitTest = practiceTest.includes('assert') || 
                                 practiceTest.includes('assert_equal') ||
                                 practiceTest.includes('assert_includes') ||
                                 practiceTest.includes('assert_match') ||
                                 practiceTest.includes('assert_respond_to') ||
                                 practiceTest.includes('assert_kind_of') ||
                                 practiceTest.includes('assert_raises');
              
              const testTag = 'RUBYTEST';
              
              if (isUnitTest) {
                // Unit test format: execute student code and test code in the same eval block
                // This ensures they share the same binding so variables are accessible
                programLines.push(
                  "# Execute student code and tests in the same binding",
                  "begin",
                  `  eval <<-'${heredocTag}'`,
                  "# Student code:",
                  normalized,
                  "",
                  "# Make output variable available to tests",
                  "output = $__exec_output__",
                  "",
                  "# Test code:",
                  practiceTest,
                  heredocTag,
                  "",
                  "# If we get here, all tests passed",
                  "test_result = true",
                  "rescue Test::Unit::AssertionFailedError => e",
                  "  $__exec_output_buffer__ << \"Test failed: \#{e.message}\\n\"",
                  "  test_result = false",
                  "rescue Exception => e",
                  "  $__exec_output_buffer__ << \"Error: \#{e.class}: \#{e.message}\\n\"",
                  "  test_result = false",
                  "end",
                  "output_text = $__exec_output_buffer__",
                  "output_text + \"\\n__TEST__=\#{test_result ? 'PASS' : 'FAIL'}\""
                );
              } else {
                // Legacy regex format: execute student code first, then check output.string
                programLines.push(
                  "# Execute student code first",
                  "begin",
                  `  eval <<-'${heredocTag}'`,
                  normalized,
                  heredocTag,
                  "rescue Exception => e",
                  "  $__exec_output_buffer__ << \"Error: \#{e.class}: \#{e.message}\\n\"",
                  "end",
                  "",
                  "# Make output variable available to tests (StringIO-like object)",
                  "output = $__exec_output__",
                  "",
                  "# Run regex-based test on output",
                  "test_result = begin",
                  "  begin",
                  `    __test_value__ = (eval <<-'${testTag}')`,
                  practiceTest,
                  testTag,
                  "    __test_value__ = true if __test_value__.nil?",
                  "    !!__test_value__",
                  "  rescue Exception => e",
                  "    # Swallow test framework details; surface only a concise error.",
                  "    $__exec_output_buffer__ << \"Test error: \#{e.message}\\n\"",
                  "    false",
                  "  end",
                  "rescue Exception => e",
                  "  $__exec_output_buffer__ << \"Test error: \#{e.message}\\n\"",
                  "  false",
                  "end",
                  "output_text = $__exec_output_buffer__",
                  "output_text + \"\\n__TEST__=\#{test_result ? 'PASS' : 'FAIL'}\""
                );
              }
            } else {
              // Non-practice blocks: execute student code and return output
              programLines.push(
                "begin",
                `  eval <<-'${heredocTag}'`,
                normalized,
                heredocTag,
                "rescue Exception => e",
                "  $__exec_output_buffer__ << \"Error: \#{e.class}: \#{e.message}\\n\"",
                "end",
                "",
                "# Return the string buffer directly for non-practice blocks",
                "$__exec_output_buffer__"
              );
            }

            const result = vm.eval(programLines.join("\n"));
            let outputText = result?.toString?.() ?? '';

            let testPassed = null;
            if (isPracticeCheck) {
              const markerMatch = outputText.match(/__TEST__=(PASS|FAIL)\s*$/);
              if (markerMatch) {
                testPassed = markerMatch[1] === 'PASS';
                outputText = outputText.replace(/\s*__TEST__=(PASS|FAIL)\s*$/, '');
              }
            }

            outputContent.textContent = outputText ? `>> ${outputText}` : '>>';

            if (isPracticeCheck && practiceChapter && testPassed !== null) {
              const feedback = document.querySelector(
                `.practice-feedback[data-practice-chapter="${practiceChapter}"][data-practice-index="${practiceIndex}"]`
              );
              if (feedback) {
                feedback.textContent = testPassed
                  ? '✅ Challenge passed! Practice item marked complete.'
                  : '❌ Not yet. Adjust your code and try again.';
              }

              if (testPassed) {
                if (window.TypophicPractice && typeof window.TypophicPractice.markPracticeItem === 'function') {
                  window.TypophicPractice.markPracticeItem(practiceChapter, practiceIndex, true);
                }
                // Use UI effects module
                if (window.UIEffects) {
                  window.UIEffects.launchConfettiAround(header || pre);
                }
              } else {
                // Reveal "Show code" button after first failed attempt
                const existing = header.querySelector('.show-solution-button');
                if (!existing) {
                  const showButton = document.createElement('button');
                  showButton.className = 'show-solution-button';
                  showButton.textContent = 'Show code';
                  header.appendChild(showButton);

                  showButton.addEventListener('click', () => {
                    try {
                      const solutionKey = `${practiceChapter}:${practiceIndex}`;
                      const solutionNode = document.querySelector(
                        `script[data-practice-solution="${solutionKey}"]`
                      );
                      if (!solutionNode) {
                        console.warn('Solution not found for:', solutionKey);
                        return;
                      }

                      const solution = solutionNode.textContent.replace(/^\s+|\s+$/g, '');
                      overlay.setValue(solution);
                    } catch (err) {
                      console.warn('Failed to show solution:', err);
                    }
                  });
                }
              }
            }
          } catch (err) {
            outputContent.textContent = `Error: ${err.message}`;
          }
        };

        // Wire up button event listener
        mainButton.addEventListener('click', async () => {
          await executeCode(isPracticeCheck);
          // Mark example as executed for progress tracking
          if (!isPracticeCheck && exampleIndex != null) {
            try { window.localStorage.setItem(`${chapterKeyPrefix}:example:${exampleIndex}`, '1'); } catch (_) {}
          }
        });
      }
    });
    // Persist examples total count for progress rings on index page
    try { window.localStorage.setItem(`${chapterKeyPrefix}:examples_total`, String(exampleCounter)); } catch (_) {}
  } catch (error) {
    console.warn('Ruby execution support failed to initialize:', error);
  }
}

// Export for use in other modules
window.RubyExec = {
  addRubyExecSupport
};
