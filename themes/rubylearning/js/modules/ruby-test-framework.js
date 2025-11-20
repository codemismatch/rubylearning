/**
 * Ruby Test Framework
 * Provides Test::Unit/Minitest-style assertions for practice exercises
 * Based on Test::Unit::Assertions
 */

function initializeRubyTestFramework(vm) {
  try {
    // Define the test framework class once in the VM
    vm.eval(`
      # Test::Unit-style assertions module
      # Based on Ruby's Test::Unit::Assertions
      module Test
        module Unit
          class AssertionFailedError < StandardError; end
          
          module Assertions
            # Assert that condition is true
            def assert(condition, message = "Assertion failed")
              raise AssertionFailedError, message unless condition
            end
            
            # Assert that expected == actual
            def assert_equal(expected, actual, message = nil)
              msg = message || "Expected \#{expected.inspect}, got \#{actual.inspect}"
              raise AssertionFailedError, msg unless expected == actual
            end
            
            # Assert that expected != actual
            def assert_not_equal(expected, actual, message = nil)
              msg = message || "Expected not \#{expected.inspect}, but got \#{actual.inspect}"
              raise AssertionFailedError, msg if expected == actual
            end
            
            # Assert that obj is nil
            def assert_nil(obj, message = "Expected nil, got \#{obj.inspect}")
              raise AssertionFailedError, message unless obj.nil?
            end
            
            # Assert that obj is not nil
            def assert_not_nil(obj, message = "Expected non-nil value, got nil")
              raise AssertionFailedError, message if obj.nil?
            end
            
            # Assert that obj is true
            def assert_true(obj, message = "Expected true, got \#{obj.inspect}")
              raise AssertionFailedError, message unless obj == true
            end
            
            # Assert that obj is false
            def assert_false(obj, message = "Expected false, got \#{obj.inspect}")
              raise AssertionFailedError, message unless obj == false
            end
            
            # Assert that collection includes item
            def assert_includes(collection, item, message = nil)
              msg = message || "Expected \#{collection.inspect} to include \#{item.inspect}"
              raise AssertionFailedError, msg unless collection.respond_to?(:include?) && collection.include?(item)
            end
            
            # Assert that string matches pattern
            def assert_match(pattern, string, message = nil)
              msg = message || "Expected \#{string.inspect} to match \#{pattern.inspect}"
              raise AssertionFailedError, msg unless string.match?(pattern)
            end
            
            # Assert that obj responds to method
            def assert_respond_to(obj, method, message = nil)
              msg = message || "Expected \#{obj.inspect} to respond to :\#{method}"
              raise AssertionFailedError, msg unless obj.respond_to?(method)
            end
            
            # Assert that obj is a kind of klass
            def assert_kind_of(klass, obj, message = nil)
              msg = message || "Expected \#{obj.inspect} to be a kind of \#{klass}"
              raise AssertionFailedError, msg unless obj.is_a?(klass)
            end
            
            # Assert that block raises expected_exception
            def assert_raises(expected_exception = StandardError, message = nil)
              begin
                yield
                msg = message || "Expected \#{expected_exception} to be raised, but nothing was raised"
                raise AssertionFailedError, msg
              rescue expected_exception => e
                return e
              rescue => e
                msg = message || "Expected \#{expected_exception}, but got \#{e.class}: \#{e.message}"
                raise AssertionFailedError, msg
              end
            end
            
            # Make all methods available as module functions
            module_function :assert, :assert_equal, :assert_not_equal, :assert_nil, :assert_not_nil,
                          :assert_true, :assert_false, :assert_includes, :assert_match,
                          :assert_respond_to, :assert_kind_of, :assert_raises
          end
        end
      end
      
      "test_framework_ready"
    `);
    
    console.log('Ruby test framework initialized');
  } catch (err) {
    console.warn('Failed to initialize Ruby test framework:', err);
  }
}

// Get the test framework code to include in each execution
function getTestFrameworkCode() {
  return `
    # Include Test::Unit::Assertions for practice tests
    begin
      include Test::Unit::Assertions
    rescue NameError
      # Fallback if Test::Unit not available (shouldn't happen)
    end
  `;
}

// Export for use in other modules
window.RubyTestFramework = {
  initializeRubyTestFramework,
  getTestFrameworkCode
};
