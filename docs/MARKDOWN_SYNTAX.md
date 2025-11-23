# Markdown Syntax Reference

This document describes the custom Markdown syntax extensions supported by Typophic for authoring interactive Ruby tutorials.

## Table of Contents

1. [Executable Ruby Code Blocks](#executable-ruby-code-blocks)
2. [Practice Exercise Blocks](#practice-exercise-blocks)
3. [Markdown Formatting](#markdown-formatting)

---

## Executable Ruby Code Blocks

### Syntax: ` ```ruby-exec` 

Use triple backticks with the `ruby-exec` language identifier to create executable Ruby code blocks that display a "Run" button in the browser.

**Example:**
````markdown
```ruby-exec
puts "Hello, Ruby!"
puts 2 + 2
```
````

**Features:**
- Code is executed in a Ruby WASM VM in the browser
- Output is displayed below the code block
- Supports all standard Ruby syntax and many standard library methods
- Input can be captured via `gets` (prompts user via JavaScript)

**When to use:**
- Interactive code examples that students should run
- Demonstrations of Ruby features
- Code snippets that benefit from live execution

---

## Practice Exercise Blocks

Practice blocks create interactive coding exercises with built-in tests, solution code, and feedback.

### Syntax

```markdown
**Goal:** Brief description of what the student should accomplish.

#> ruby :practice

# TODO: Instructions for the student
# Additional hints or context

```solution
# Complete solution code
def solution_method
  puts "This is the answer"
end
```

```test
# Test code that validates the solution
out = output.string
out.include?('answer') && out.lines.size >= 1
```

#!
```

### Components

#### 1. Goal Line (Optional but Recommended)

```markdown
**Goal:** Description of the exercise goal.
```

- Uses Markdown bold syntax (`**text**`)
- Appears above the practice block
- Helps students understand what they're trying to achieve

#### 2. Practice Block Delimiters

```markdown
#> ruby :practice
...
#!
```

- `#> ruby :practice` marks the start of a practice block
- `#!` marks the end of the practice block
- Everything between these markers is part of the exercise

#### 3. Initial Code / TODO Comments

The code between `#> ruby :practice` and the first ` ```solution` block is what students see initially in the editor.

```markdown
# TODO: Write a method that prints "Hello, World!"
# Hint: Use puts
```

**Best practices:**
- Start with `# TODO:` to clearly indicate what needs to be done
- Include hints or context in comments
- Keep it concise but informative
- You can include blank lines for readability

#### 4. Solution Code Block

```markdown
```solution
# Complete, working solution
def greet
  puts "Hello, World!"
end
```
```

- Marked with ` ```solution` (no language identifier needed)
- Contains the complete, correct solution
- Hidden from students until they click "Show code" after a failed attempt
- Should be well-formatted and follow Ruby best practices

#### 5. Test Code Block

```markdown
```test
# Test validation code
out = output.string
out.include?('Hello') && out.include?('World')
```
```

- Marked with ` ```test` (no language identifier needed)
- Contains Ruby code that validates the student's solution
- Has access to an `output` variable (StringIO-like object) containing all `puts`/`print` output
- Should return `true` for a passing test, `false` for a failing test

**Test Code Patterns:**

**Pattern 1: Output String Validation (Legacy/Regex Style)**
```ruby
out = output.string
out.include?('expected text') && out.lines.size >= 2
```

**Pattern 2: Unit Test Style (Recommended)**
```ruby
require 'test/unit'
include Test::Unit::Assertions

assert_equal(expected, actual)
assert_includes(collection, item)
assert_match(pattern, string)
```

**Available Variables in Test Code:**
- `output` - StringIO-like object with all program output
- `output.string` - Full output as a string
- Any variables defined in the student's code (same binding)

#### 6. Closing Delimiter

```markdown
#!
```

- Marks the end of the practice block
- Must be on its own line

### Complete Example

```markdown
#### Practice 1 - Basic Output

**Goal:** Print a greeting message using `puts`.

#> ruby :practice

# TODO: Write code that prints "Hello, Ruby Learning!"
# Use the puts method to output the message.

```solution
puts "Hello, Ruby Learning!"
```

```test
out = output.string
out.include?('Hello') && out.include?('Ruby Learning')
```

#!
```

### Practice Block Features

- **Check Button**: Students click "Check" to run their code and see test results
- **Visual Feedback**: 
  - 🟢 Green circle emoji indicates test passed
  - 🔴 Red circle emoji indicates test failed
- **Show Code Button**: Appears after first failed attempt, reveals the solution
- **Progress Tracking**: Completed exercises are tracked (if enabled)
- **Error Display**: Syntax errors and runtime errors are shown clearly

### HTML Output Structure

The parser converts practice blocks into HTML with:

- `<pre>` tag with `data-executable="true"` and practice attributes
- `<div class="practice-feedback">` for displaying test results
- `<script type="text/plain" data-practice-solution="...">` containing the solution code

**Note:** You don't need to write this HTML manually—the parser handles it automatically.

---

## Markdown Formatting

### Bold Text

```markdown
**Bold text** becomes <strong>Bold text</strong>
```

Use for:
- Goal descriptions in practice blocks
- Emphasis in regular content

### Inline Code

```markdown
Use `method_name` for inline code references.
```

### Code Blocks

Regular code blocks (non-executable):

````markdown
```ruby
# This is just syntax highlighting
def example
  puts "not executable"
end
```
````

---

## Pipeline Processing Order

The content pipeline processes blocks in this order:

1. **RuboCop formatting** (if enabled) - Formats Ruby code
2. **Hash blocks** (`#> ... #!`) - Processes special block syntax
3. **Practice blocks** (`#> ruby :practice ... #!`) - Converts to HTML structure
4. **Ruby-exec blocks** (` ```ruby-exec`) - Makes code executable
5. **Markdown conversion** - Converts Markdown to HTML

This order ensures that:
- Code is formatted before being displayed
- Practice blocks are converted before markdown processing
- Executable blocks get proper attributes
- Markdown formatting (like `**bold**`) is applied correctly

---

## Migration from Legacy HTML Format

If you have existing practice blocks using HTML format:

**Old Format:**
```html
<p><strong>Goal:</strong> Description</p>
<pre class="language-ruby" data-executable="true" 
     data-practice-chapter="..." data-practice-index="0"
     data-test="..."><code class="language-ruby">
# TODO: ...
</code></pre>
<div class="practice-feedback" ...></div>
<script type="text/plain" data-practice-solution="...">
# Solution code
</script>
```

**New Format:**
```markdown
**Goal:** Description

#> ruby :practice

# TODO: ...

```solution
# Solution code
```

```test
# Test code
```

#!
```

**Benefits of New Format:**
- Human-readable and editable
- No HTML entity escaping needed (`&`, `>=`, `&&` work naturally)
- Easier to maintain and review
- Version control friendly
- Consistent with Markdown conventions

---

## Tips and Best Practices

### Writing Good Practice Exercises

1. **Clear Goals**: Make the goal statement specific and actionable
2. **Helpful TODOs**: Provide enough context without giving away the solution
3. **Robust Tests**: Test for the essential behavior, not implementation details
4. **Clean Solutions**: Write solutions that demonstrate best practices
5. **Progressive Difficulty**: Start simple, build complexity gradually

### Test Code Guidelines

- **Be Flexible**: Accept different valid approaches
- **Clear Errors**: Test code should produce helpful error messages
- **Output Validation**: Use `output.string` to check printed output
- **Unit Tests**: Prefer `assert_*` methods for clearer feedback
- **Edge Cases**: Consider empty inputs, nil values, etc.

### Code Examples

- **Executable Examples**: Use ` ```ruby-exec` for interactive demos
- **Reference Code**: Use regular ` ```ruby` for non-interactive examples
- **Practice Blocks**: Use `#> ruby :practice` for exercises with tests

---

## Implementation Notes

### Crystal Builder (`crystal/src/typophic/builder.cr`)

The Crystal implementation includes:
- `pipeline_practice_blocks` - Parses `#> ruby :practice` syntax
- `pipeline_ruby_exec` - Processes ` ```ruby-exec` blocks
- `pipeline_markdown` - Converts Markdown to HTML, including `**bold**` syntax
- HTML escaping for attributes to prevent XSS

### Ruby Builder (`lib/typophic/builder.rb`)

The Ruby implementation mirrors the Crystal functionality:
- Same pipeline order and processing
- Compatible syntax and output
- Can be used interchangeably with Crystal version

### JavaScript (`themes/rubylearning/js/modules/ruby-exec.js`)

The frontend handles:
- Ruby WASM VM initialization
- Code execution and output capture
- Test evaluation and result display
- Visual feedback with emoji indicators (🟢/🔴)
- Solution reveal functionality

---

## Troubleshooting

### Practice block not rendering

- Check that `#!` closing delimiter is on its own line
- Verify `#> ruby :practice` syntax is correct
- Ensure solution and test blocks use triple backticks with correct labels

### Test not running

- Verify test code is valid Ruby syntax
- Check that test returns a boolean value
- Ensure `output.string` is used correctly for output validation

### Code not executing

- Verify ` ```ruby-exec` syntax (not just ` ```ruby`)
- Check that Ruby WASM VM is loaded in browser
- Look for JavaScript console errors

### HTML entities appearing in code

- The builder automatically escapes HTML in attributes
- Write normal characters (`&`, `>=`, `&&`) in Markdown
- The parser handles escaping automatically

---

## Examples Gallery

See `content/pages/tutorials/` for real-world examples of:
- Executable code examples
- Practice exercises with various test patterns
- Goal descriptions and TODO comments
- Solution code formatting
