# Practice Test Writing Guide

This guide explains how to write unit tests for practice exercises using the new test framework.

## Overview

Practice tests now use **unit tests with assertions** instead of regex patterns on output strings. This approach:
- Tests actual behavior, not output format
- Provides clear error messages
- Teaches proper testing practices
- Is more maintainable

## Test Framework

The test framework provides minitest-style assertions:

- `assert(condition, message)` - Basic assertion
- `assert_equal(expected, actual, message)` - Equality check
- `assert_not_equal(expected, actual, message)` - Inequality check
- `assert_nil(obj, message)` - Check for nil
- `assert_not_nil(obj, message)` - Check for non-nil
- `assert_true(obj, message)` - Check for true
- `assert_false(obj, message)` - Check for false
- `assert_includes(collection, item, message)` - Check inclusion
- `assert_match(pattern, string, message)` - Regex match
- `assert_respond_to(obj, method, message)` - Check method exists
- `assert_kind_of(klass, obj, message)` - Check class/type
- `assert_raises(exception_class, message) { ... }` - Check exception

## Writing Tests

### Format

Tests are written in the `data-test` attribute of practice code blocks:

```html
<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/example"
     data-practice-index="0"
     data-test="
# Your test code here
assert_equal 42, result
">
```

### Test Execution Flow

1. **Student code executes first** - Sets variables, defines methods, etc.
2. **Test code runs** - Can access variables/methods from student code
3. **Assertions verify** - Each assertion checks expected behavior
4. **Result reported** - ✅ if all pass, ❌ with error message if any fail

### Example 1: Testing Variables

**Student Task**: Set variables demonstrating operator precedence

**Student Code**:
```ruby
a = true and b = false
c = true && d = false
```

**Test**:
```ruby
# Test that student code demonstrates and/&& precedence differences
assert_not_nil defined?(a), 'Variable a should be defined'
assert_equal true, a, 'and has lower precedence, so a should be true'
assert_equal false, b, 'b should be false'
assert_equal false, c, '&& has higher precedence, so c should be false'
assert_equal false, d, 'd should be false'
```

### Example 2: Testing Methods

**Student Task**: Write a method that calculates sum

**Student Code**:
```ruby
def sum(a, b)
  a + b
end
```

**Test**:
```ruby
# Test the sum method
assert_respond_to self, :sum, 'sum method should be defined'
assert_equal 5, sum(2, 3), 'sum(2, 3) should return 5'
assert_equal 0, sum(-1, 1), 'sum(-1, 1) should return 0'
```

### Example 3: Testing Output (when needed)

**Student Task**: Print formatted output

**Student Code**:
```ruby
puts "Hello, #{name}!"
```

**Test** (using output variable):
```ruby
# Check output contains expected text
out = output.string
assert_match /Hello/, out, 'Output should contain "Hello"'
assert_match /#{name}/, out, 'Output should contain name'
```

### Example 4: Testing Classes

**Student Task**: Create a class with methods

**Student Code**:
```ruby
class Calculator
  def add(a, b)
    a + b
  end
end
```

**Test**:
```ruby
# Test the Calculator class
assert_kind_of Class, Calculator, 'Calculator should be a class'
calc = Calculator.new
assert_kind_of Calculator, calc, 'calc should be a Calculator instance'
assert_equal 7, calc.add(3, 4), 'add(3, 4) should return 7'
```

## Migration from Regex Tests

### Old Regex Format (still supported)
```ruby
out = output.string
lines = out.lines.map(&:strip)
lines.any? { |l| l.match?(/pattern/) } && lines.any? { |l| l.include?('text') }
```

### New Unit Test Format (preferred)
```ruby
# Test actual behavior
assert_equal expected_value, actual_value, 'Clear error message'
assert_includes collection, item, 'Item should be in collection'
```

## Best Practices

1. **Test behavior, not output** - Prefer testing return values and variables over output strings
2. **Clear error messages** - Include helpful messages in assertions
3. **Test edge cases** - Include tests for boundary conditions
4. **One concept per test** - Each assertion should test one thing
5. **Use appropriate assertions** - Choose the right assertion for the check

## Backward Compatibility

The system supports both formats:
- **Regex format**: Detected by absence of `assert` keywords
- **Unit test format**: Detected by presence of `assert` keywords

Legacy regex tests continue to work, but new tests should use the unit test format.

## Error Messages

When an assertion fails, students see:
```
Test failed: Expected true, got false - and has lower precedence, so a should be true
```

This helps students understand what went wrong and how to fix it.
