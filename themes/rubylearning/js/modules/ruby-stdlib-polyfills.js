/**
 * Ruby Standard Library Polyfills
 * Implements common stdlib classes using JavaScript
 */

function initializeRubyStdlibPolyfills(vm) {
  try {
    // StringIO polyfill - make require 'stringio' work
    vm.eval(`
      class StringIO
        def initialize(str = "")
          @buffer = str.is_a?(String) ? str.dup : str.to_s
        end
        
        def string
          @buffer
        end
        
        def puts(*args)
          if args.empty?
            @buffer << "\\n"
          else
            args.each { |arg| @buffer << arg.to_s << "\\n" }
          end
          nil
        end
        
        def print(*args)
          @buffer << args.join
          nil
        end
        
        def write(str)
          @buffer << str.to_s
          str.to_s.length
        end
        
        def read(length = nil)
          if length.nil?
            result = @buffer
            @buffer = ""
            result
          else
            result = @buffer[0, length]
            @buffer = @buffer[length..-1] || ""
            result
          end
        end
        
        def gets(sep = $/)
          idx = @buffer.index(sep)
          if idx
            result = @buffer[0..idx]
            @buffer = @buffer[(idx + sep.length)..-1] || ""
            result
          else
            result = @buffer
            @buffer = ""
            result.empty? ? nil : result
          end
        end
        
        def truncate(pos = 0)
          @buffer.slice!(pos..-1)
          pos
        end
        
        def rewind
          # No-op for string buffer
          0
        end
        
        def eof?
          @buffer.empty?
        end
        
        def close
          # No-op
        end
        
        def closed?
          false
        end
      end
    `);
    
    // String methods polyfill - ensure common string methods work
    // Note: The 'iupcase' error suggests methods might be getting corrupted
    // We'll ensure all common methods exist and work correctly
    vm.eval(`
      # Ensure String class has all common methods
      # Add implementations using JavaScript for reliability
      class String
        # Always ensure upcase works - use JS for reliability
        alias_method :__original_upcase, :upcase if method_defined?(:upcase)
        def upcase
          if defined?(JS) && JS.respond_to?(:global)
            begin
              JS.global.eval("('\#{self}').toUpperCase()").to_s
            rescue
              # Fallback to original if it exists
              if method_defined?(:__original_upcase)
                __original_upcase
              else
                self.tr('a-z', 'A-Z')
              end
            end
          elsif method_defined?(:__original_upcase)
            __original_upcase
          else
            self.tr('a-z', 'A-Z')
          end
        end
        
        alias_method :__original_downcase, :downcase if method_defined?(:downcase)
        def downcase
          if defined?(JS) && JS.respond_to?(:global)
            begin
              JS.global.eval("('\#{self}').toLowerCase()").to_s
            rescue
              method_defined?(:__original_downcase) ? __original_downcase : self.tr('A-Z', 'a-z')
            end
          elsif method_defined?(:__original_downcase)
            __original_downcase
          else
            self.tr('A-Z', 'a-z')
          end
        end
        
        unless method_defined?(:capitalize)
          def capitalize
            if self.empty?
              self
            else
              self[0].upcase + self[1..-1].downcase
            end
          end
        end
        
        unless method_defined?(:reverse)
          def reverse
            if defined?(JS) && JS.respond_to?(:global)
              JS.global.eval("('\#{self}').split('').reverse().join('')").to_s
            else
              # Fallback implementation
              result = ""
              (self.length - 1).downto(0) { |i| result << self[i] }
              result
            end
          end
        end
        
        unless method_defined?(:strip)
          def strip
            if defined?(JS) && JS.respond_to?(:global)
              JS.global.eval("('\#{self}').trim()").to_s
            else
              self.gsub(/^\\s+|\\s+$/, '')
            end
          end
        end
        
        unless method_defined?(:lstrip)
          def lstrip
            if defined?(JS) && JS.respond_to?(:global)
              JS.global.eval("('\#{self}').replace(/^\\s+/, '')").to_s
            else
              self.gsub(/^\\s+/, '')
            end
          end
        end
        
        unless method_defined?(:rstrip)
          def rstrip
            if defined?(JS) && JS.respond_to?(:global)
              JS.global.eval("('\#{self}').replace(/\\s+$/, '')").to_s
            else
              self.gsub(/\\s+$/, '')
            end
          end
        end
        
        unless method_defined?(:length)
          def length
            if defined?(JS) && JS.respond_to?(:global)
              JS.global.eval("('\#{self}').length").to_i
            else
              # Fallback - count bytes/characters
              self.bytesize
            end
          end
        end
        
        unless method_defined?(:size)
          alias_method :size, :length
        end
        
        unless method_defined?(:empty?)
          def empty?
            self.length == 0
          end
        end
        
        unless method_defined?(:include?)
          def include?(substr)
            self.index(substr) != nil
          end
        end
        
        unless method_defined?(:start_with?)
          def start_with?(*prefixes)
            prefixes.any? { |prefix| self[0, prefix.length] == prefix }
          end
        end
        
        unless method_defined?(:end_with?)
          def end_with?(*suffixes)
            suffixes.any? { |suffix| self[-suffix.length..-1] == suffix }
          end
        end
        
        unless method_defined?(:gsub)
          def gsub(pattern, replacement = nil, &block)
            if block_given?
              self.split(pattern).map { |part| block.call(part) }.join
            elsif replacement
              self.split(pattern).join(replacement.to_s)
            else
              self
            end
          end
        end
        
        unless method_defined?(:sub)
          def sub(pattern, replacement = nil, &block)
            if block_given?
              parts = self.split(pattern, 2)
              parts.length > 1 ? parts[0] + block.call(parts[1]) + parts[2..-1].join : self
            elsif replacement
              parts = self.split(pattern, 2)
              parts.length > 1 ? parts[0] + replacement.to_s + parts[2..-1].join : self
            else
              self
            end
          end
        end
      end
    `);
    
    // Time class polyfill using JavaScript Date
    vm.eval(`
      class Time
        include Comparable
        
        def self.now
          js_date = JS.global.eval("new Date()")
          time = allocate
          time.instance_variable_set(:@js_date, js_date)
          time.instance_variable_set(:@utc, false)
          time
        end
        
        def self.new(year = nil, month = nil, day = nil, hour = nil, min = nil, sec = nil, usec = nil)
          if year.nil?
            now
          else
            # Create JS Date from components
            js_str = "\#{year}-\#{month.to_s.rjust(2, '0')}-\#{day.to_s.rjust(2, '0')}T\#{hour.to_s.rjust(2, '0')}:\#{min.to_s.rjust(2, '0')}:\#{sec.to_s.rjust(2, '0')}"
            js_date = JS.global.eval("new Date('\#{js_str}')")
            time = allocate
            time.instance_variable_set(:@js_date, js_date)
            time.instance_variable_set(:@utc, false)
            time
          end
        end
        
        def self.utc(year, month = 1, day = 1, hour = 0, min = 0, sec = 0, usec = 0)
          js_str = "\#{year}-\#{month.to_s.rjust(2, '0')}-\#{day.to_s.rjust(2, '0')}T\#{hour.to_s.rjust(2, '0')}:\#{min.to_s.rjust(2, '0')}:\#{sec.to_s.rjust(2, '0')}Z"
          js_date = JS.global.eval("new Date('\#{js_str}')")
          time = allocate
          time.instance_variable_set(:@js_date, js_date)
          time.instance_variable_set(:@utc, true)
          time
        end
        
        def self.parse(str)
          js_date = JS.global.eval("new Date('\#{str}')")
          time = allocate
          time.instance_variable_set(:@js_date, js_date)
          time.instance_variable_set(:@utc, false)
          time
        end
        
        def initialize_copy(other)
          @js_date = other.instance_variable_get(:@js_date)
          @utc = other.instance_variable_get(:@utc)
        end
        
        def year
          @js_date.call(:getFullYear).to_i
        end
        
        def month
          @js_date.call(:getMonth).to_i + 1
        end
        
        def day
          @js_date.call(:getDate).to_i
        end
        
        def hour
          @js_date.call(:getHours).to_i
        end
        
        def min
          @js_date.call(:getMinutes).to_i
        end
        
        def sec
          @js_date.call(:getSeconds).to_i
        end
        
        def wday
          @js_date.call(:getDay).to_i
        end
        
        def yday
          start = JS.global.eval("new Date(\#{year}, 0, 1)")
          diff = (@js_date.call(:getTime).to_i - start.call(:getTime).to_i) / 1000
          (diff / 86400).to_i + 1
        end
        
        def strftime(format)
          js_date = @js_date
          format.gsub(/%[a-zA-Z%]/) do |spec|
            case spec
            when '%Y' then js_date.call(:getFullYear).to_s
            when '%m' then (js_date.call(:getMonth).to_i + 1).to_s.rjust(2, '0')
            when '%d' then js_date.call(:getDate).to_s.rjust(2, '0')
            when '%H' then js_date.call(:getHours).to_s.rjust(2, '0')
            when '%M' then js_date.call(:getMinutes).to_s.rjust(2, '0')
            when '%S' then js_date.call(:getSeconds).to_s.rjust(2, '0')
            when '%w' then js_date.call(:getDay).to_s
            when '%j' then yday.to_s.rjust(3, '0')
            when '%Y-%m-%d' then "\#{year}-\#{month.to_s.rjust(2, '0')}-\#{day.to_s.rjust(2, '0')}"
            when '%H:%M:%S' then "\#{hour.to_s.rjust(2, '0')}:\#{min.to_s.rjust(2, '0')}:\#{sec.to_s.rjust(2, '0')}"
            when '%Y/%m/%d %H:%M' then "\#{year}/\#{month.to_s.rjust(2, '0')}/\#{day.to_s.rjust(2, '0')} \#{hour.to_s.rjust(2, '0')}:\#{min.to_s.rjust(2, '0')}"
            when '%%' then '%'
            else spec
            end
          end
        end
        
        def to_s
          strftime("%Y-%m-%d %H:%M:%S")
        end
        
        def ctime
          days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
          months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          "\#{days[wday]} \#{months[month - 1]} \#{day.to_s.rjust(2, ' ')} \#{hour.to_s.rjust(2, '0')}:\#{min.to_s.rjust(2, '0')}:\#{sec.to_s.rjust(2, '0')} \#{year}"
        end
        
        def +(seconds)
          new_js_date = JS.global.eval("new Date(\#{@js_date.call(:getTime).to_i + (seconds * 1000)})")
          new_time = Time.allocate
          new_time.instance_variable_set(:@js_date, new_js_date)
          new_time.instance_variable_set(:@utc, @utc)
          new_time
        end
        
        def -(other)
          if other.is_a?(Time)
            (@js_date.call(:getTime).to_i - other.instance_variable_get(:@js_date).call(:getTime).to_i) / 1000.0
          else
            new_js_date = JS.global.eval("new Date(\#{@js_date.call(:getTime).to_i - (other * 1000)})")
            new_time = Time.allocate
            new_time.instance_variable_set(:@js_date, new_js_date)
            new_time.instance_variable_set(:@utc, @utc)
            new_time
          end
        end
        
        def <=>(other)
          return nil unless other.is_a?(Time)
          @js_date.call(:getTime).to_i <=> other.instance_variable_get(:@js_date).call(:getTime).to_i
        end
        
        def utc?
          @utc == true
        end
        
        def getutc
          if utc?
            self
          else
            js_str = @js_date.call(:toISOString).to_s
            js_date = JS.global.eval("new Date('\#{js_str}')")
            time = Time.allocate
            time.instance_variable_set(:@js_date, js_date)
            time.instance_variable_set(:@utc, true)
            time
          end
        end
        
        def localtime
          if utc?
            js_str = @js_date.call(:toISOString).to_s
            js_date = JS.global.eval("new Date('\#{js_str}')")
            time = Time.allocate
            time.instance_variable_set(:@js_date, js_date)
            time.instance_variable_set(:@utc, false)
            time
          else
            self
          end
        end
        
        def inspect
          "\#<Time: \#{to_s}>"
        end
      end
    `);
    
    // JSON polyfill using JavaScript JSON
    vm.eval(`
      module JSON
        def self.generate(obj)
          js_json = JS.global.eval("JSON")
          js_json.call(:stringify, convert_to_js(obj)).to_s
        end
        
        def self.dump(obj)
          generate(obj)
        end
        
        def self.parse(str)
          js_json = JS.global.eval("JSON")
          js_obj = js_json.call(:parse, str.to_s)
          convert_from_js(js_obj)
        end
        
        def self.convert_to_js(obj)
          case obj
          when Hash
            js_obj = JS.global.eval("({})")
            obj.each do |k, v|
              key = k.is_a?(Symbol) ? k.to_s : k.to_s
              js_obj[key] = convert_to_js(v)
            end
            js_obj
          when Array
            js_arr = JS.global.eval("([])")
            obj.each_with_index do |item, idx|
              js_arr[idx] = convert_to_js(item)
            end
            js_arr
          when String, Numeric, TrueClass, FalseClass, NilClass
            obj
          else
            obj.to_s
          end
        end
        
        def self.convert_from_js(js_obj)
          # Check if it's an array-like object
          if js_obj.respond_to?(:length) && !js_obj.respond_to?(:to_h)
            result = []
            len = js_obj.length.to_i
            (0...len).each do |i|
              result << convert_from_js(js_obj[i])
            end
            result
          elsif js_obj.respond_to?(:to_h)
            # It's an object/hash
            result = {}
            js_obj.to_h.each do |k, v|
              key = k.to_s.to_sym rescue k.to_s
              result[key] = convert_from_js(v)
            end
            result
          else
            # Primitive value - try to convert appropriately
            val_str = js_obj.to_s
            # Try to convert numbers
            if val_str.match(/^-?\\d+$/)
              val_str.to_i
            elsif val_str.match(/^-?\\d+\\.\\d+$/)
              val_str.to_f
            elsif val_str == 'true'
              true
            elsif val_str == 'false'
              false
            elsif val_str == 'null' || val_str == 'undefined'
              nil
            else
              val_str
            end
          end
        end
      end
    `);
    
    console.log('Ruby stdlib polyfills initialized');
  } catch (err) {
    console.warn('Failed to initialize Ruby stdlib polyfills:', err);
  }
}

// Export for use in other modules
window.RubyStdlibPolyfills = {
  initializeRubyStdlibPolyfills
};
