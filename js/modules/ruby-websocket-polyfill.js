/**
 * WebSocket Polyfill for Ruby Socket Classes
 * Makes TCPSocket/TCPServer work in browsers using WebSockets
 * 
 * Limitations:
 * - TCPServer cannot work (browsers can't create servers)
 * - TCPSocket connects to WebSocket servers (not raw TCP)
 * - Uses public echo server for testing: wss://echo.websocket.org
 */

function initializeRubyWebSocketPolyfill(vm) {
  try {
    vm.eval(`
      require 'js'
      
      # Ensure sleep method exists (for waiting on async operations)
      # Note: This is a simple busy-wait sleep - not ideal but works for short durations
      unless Kernel.respond_to?(:sleep)
        module Kernel
          def sleep(seconds = nil)
            if seconds.nil?
              # Sleep indefinitely - not recommended
              loop { sleep(1) }
            else
              # Simple busy-wait sleep (for short durations only)
              start = Time.now
              while (Time.now - start) < seconds
                # Small busy-wait loop
                1000.times { }
              end
              seconds
            end
          end
          module_function :sleep
        end
      end
      
      # WebSocket-based TCP Socket polyfill
      class TCPSocket
        def initialize(host, port)
          @host = host.to_s
          @port = port.to_i
          @closed = false
          @buffer = []
          @buffer_mutex = Object.new
          @ws = nil
          @connected = false
          @connection_promise = nil
          
          # Map common localhost ports to WebSocket URLs
          # For testing, use public echo server
          ws_url = if @host == "localhost" || @host == "127.0.0.1"
            # Use public echo server for localhost connections
            "wss://echo.websocket.org"
          else
            # For other hosts, try to construct WebSocket URL
            protocol = port == 443 ? "wss" : "ws"
            "\#{protocol}://\#{@host}:\#{@port}"
          end
          
          # Create WebSocket connection using JS bridge
          @socket_id = "\#{@host}:\#{@port}:\#{Time.now.to_f}"
          
          # Initialize global buffer storage
          JS.global.eval("
            if (window.__ruby_ws_buffers__ === undefined) {
              window.__ruby_ws_buffers__ = {};
            }
            window.__ruby_ws_buffers__['\#{@socket_id}'] = [];
            window.__ruby_ws_connections__ = window.__ruby_ws_connections__ || {};
            window.__ruby_ws_connections__['\#{@socket_id}'] = { connected: false, error: null };
          ")
          
          # Create WebSocket and set up event handlers using JS
          # Test connection first with console logging
          test_code = "
            (function() {
              console.log('[Ruby WebSocket] Testing connection to: \#{ws_url}');
              var ws = new WebSocket('\#{ws_url}');
              var socket_id = '\#{@socket_id}';
              
              ws.onopen = function(event) {
                console.log('[Ruby WebSocket] Connection opened for socket_id:', socket_id);
                if (window.__ruby_ws_connections__ && window.__ruby_ws_connections__[socket_id]) {
                  window.__ruby_ws_connections__[socket_id].connected = true;
                  window.__ruby_ws_connections__[socket_id].error = null;
                  console.log('[Ruby WebSocket] Connection marked as connected');
                } else {
                  console.error('[Ruby WebSocket] Connection info not found for socket_id:', socket_id);
                }
              };
              
              ws.onmessage = function(event) {
                console.log('[Ruby WebSocket] Message received:', event.data);
                if (window.__ruby_ws_buffers__ && window.__ruby_ws_buffers__[socket_id]) {
                  window.__ruby_ws_buffers__[socket_id].push(event.data);
                  console.log('[Ruby WebSocket] Message added to buffer');
                } else {
                  console.error('[Ruby WebSocket] Buffer not found for socket_id:', socket_id);
                }
              };
              
              ws.onerror = function(error) {
                console.error('[Ruby WebSocket] Error occurred:', error);
                if (window.__ruby_ws_connections__ && window.__ruby_ws_connections__[socket_id]) {
                  window.__ruby_ws_connections__[socket_id].error = error || 'WebSocket error';
                  window.__ruby_ws_connections__[socket_id].connected = false;
                }
              };
              
              ws.onclose = function(event) {
                console.log('[Ruby WebSocket] Connection closed. Code:', event.code, 'Reason:', event.reason);
                if (window.__ruby_ws_connections__ && window.__ruby_ws_connections__[socket_id]) {
                  if (!window.__ruby_ws_connections__[socket_id].connected) {
                    window.__ruby_ws_connections__[socket_id].error = 'Connection closed before opening (code: ' + event.code + ')';
                  }
                }
              };
              
              console.log('[Ruby WebSocket] WebSocket created, readyState:', ws.readyState);
              
              // Store WebSocket in global registry for send operations
              if (!window.__ruby_ws_sockets__) {
                window.__ruby_ws_sockets__ = {};
              }
              window.__ruby_ws_sockets__[socket_id] = ws;
              
              return ws;
            })()
          "
          
          @ws = JS.global.eval(test_code)
          puts "WebSocket created, readyState: \#{@ws[:readyState] || @ws['readyState']}" rescue nil
          
          # Wait for connection (with timeout)
          start_time = Time.now
          timeout_seconds = 5.0
          connected = false
          error_msg = nil
          
          while (Time.now - start_time) < timeout_seconds
            # Check WebSocket readyState first (most reliable)
            ready_state_js = @ws[:readyState] || @ws['readyState']
            if ready_state_js
              ready_state = ready_state_js.to_i
              if ready_state == 1  # OPEN
                @connected = true
                connected = true
                break
              elsif ready_state == 3  # CLOSED
                # Check if we ever connected
                conn_info = JS.global.eval("window.__ruby_ws_connections__['\#{@socket_id}']")
                if conn_info && (conn_info[:connected] || conn_info['connected'])
                  # We connected but then closed - that's OK, connection was established
                  @connected = true
                  connected = true
                  break
                else
                  # Never connected, this is a failure
                  error_msg = "WebSocket closed without connecting (readyState=3)"
                  break
                end
              end
            end
            
            # Check connection status from JS
            conn_info = JS.global.eval("window.__ruby_ws_connections__['\#{@socket_id}']")
            if conn_info
              # Use [:property] syntax for JS object properties
              connected_flag = conn_info[:connected] || conn_info['connected']
              if connected_flag == true
                @connected = true
                connected = true
                break
              end
              
              # Only set error_msg, don't break - wait for timeout or readyState check
              error_flag = conn_info[:error] || conn_info['error']
              if error_flag && !error_msg
                error_msg = error_flag.to_s
              end
            end
            
            # Small sleep to avoid busy waiting
            sleep(0.05)
          end
          
          # Only raise error if we didn't connect AND we have an error or timeout
          unless connected || @connected
            error_detail = error_msg ? " - \#{error_msg}" : " (timeout after \#{timeout_seconds}s)"
            raise "Connection failed to \#{ws_url}\#{error_detail}"
          end
        end
        
        def write(data)
          raise "Socket is closed" if @closed
          raise "Socket not connected" unless @connected
          
          # Convert data to string - handle Time objects and other types
          begin
            data_str = if data.nil?
              ""
            elsif data.respond_to?(:to_s)
              result = data.to_s
              if result.nil? || result == ""
                data.inspect
              else
                result
              end
            else
              data.inspect
            end
            
            # Ensure we have a valid string
            data_str = "" if data_str.nil?
            data_str = data_str.to_s if !data_str.is_a?(String)
            
            # Send data using JS directly to avoid Ruby WASM async IO issues
            # Escape the string properly for JavaScript
            escaped_str = data_str.gsub("\\", "\\\\").gsub("'", "\\'").gsub('"', '\\"').gsub("\n", "\\n").gsub("\r", "\\r")
            
            # Use JS.global.eval to call send method directly
            send_result = JS.global.eval("
              (function() {
                try {
                  var ws = window.__ruby_ws_sockets__ || {};
                  var socket_id = '\#{@socket_id}';
                  if (ws[socket_id] && ws[socket_id].readyState === 1) {
                    ws[socket_id].send('\#{escaped_str}');
                    return true;
                  } else {
                    console.error('[Ruby WebSocket] Socket not found or not open. Socket ID:', socket_id, 'ReadyState:', ws[socket_id] ? ws[socket_id].readyState : 'undefined');
                    return false;
                  }
                } catch(e) {
                  console.error('[Ruby WebSocket] Send error:', e);
                  return false;
                }
              })()
            ")
            
            unless send_result
              raise "Failed to send data - socket not connected or not found"
            end
            
            data_str.length
          rescue => e
            raise "Failed to send data: \#{e.class}: \#{e.message}"
          end
        end
        
        def puts(*args)
          if args.empty?
            write("\\n")
          else
            args.each { |arg| write(arg.to_s + "\\n") }
          end
          nil
        end
        
        def print(*args)
          write(args.join)
          nil
        end
        
        def recv(maxlen)
          raise "Socket is closed" if @closed
          raise "Socket not connected" unless @connected
          
          # Wait for data in buffer (with timeout)
          start_time = Time.now
          loop do
            buffer_js = JS.global.eval("window.__ruby_ws_buffers__['\#{@socket_id}']")
            buffer = buffer_js.to_a
            if !buffer.empty?
              # Get first message
              data = buffer[0].to_s
              # Remove from buffer
              JS.global.eval("window.__ruby_ws_buffers__['\#{@socket_id}'].shift()")
              # Limit to maxlen
              return data[0, maxlen]
            end
            
            if (Time.now - start_time) > 5.0
              raise "Receive timeout"
            end
            sleep(0.1)
          end
        end
        
        def gets(sep = $/)
          raise "Socket is closed" if @closed
          raise "Socket not connected" unless @connected
          
          result = ""
          start_time = Time.now
          
          loop do
            if (Time.now - start_time) > 5.0
              raise "Receive timeout"
            end
            
            buffer_js = JS.global.eval("window.__ruby_ws_buffers__['\#{@socket_id}']")
            buffer = buffer_js.to_a
            
            if buffer.empty?
              # Check if connection is closed
              ready_state = @ws[:readyState] || @ws['readyState']
              if ready_state && ready_state.to_i == 3  # CLOSED
                return result.empty? ? nil : result
              end
              sleep(0.1)
              next
            end
            
            # Get first message
            chunk = buffer[0].to_s
            JS.global.eval("window.__ruby_ws_buffers__['\#{@socket_id}'].shift()")
            
            result << chunk
            
            # Check if we have the separator
            if idx = result.index(sep)
              # Return up to and including separator
              line = result[0..idx]
              # Keep remainder in buffer
              remainder = result[(idx + sep.length)..-1]
              if !remainder.nil? && !remainder.empty?
                JS.global.eval("window.__ruby_ws_buffers__['\#{@socket_id}'].unshift('" + remainder.gsub("'", "\\\\'").gsub('"', '\\\\"') + "')")
              end
              return line
            end
            
            # If connection closed and we have data, return what we have
            ready_state = @ws[:readyState] || @ws['readyState']
            if ready_state && ready_state.to_i == 3  # CLOSED
              return result.empty? ? nil : result
            end
          end
        end
        
        def close
          return if @closed
          @closed = true
          if @ws && @connected
            @ws.call(:close) rescue nil
          end
          # Clean up buffer
          JS.global.eval("delete window.__ruby_ws_buffers__['\#{@socket_id}']") rescue nil
        end
        
        def closed?
          return true if @closed
          return false unless @ws
          ready_state = @ws[:readyState] || @ws['readyState']
          ready_state && ready_state.to_i == 3
        end
        
        def inspect
          # Simple inspect without any IO operations
          status = @connected ? 'connected' : 'disconnected'
          "\#<TCPSocket:\#{@host}:\#{@port} \#{status}>"
        end
        
        def to_s
          # Simple to_s without any IO operations
          inspect
        end
      end
      
      # TCPServer polyfill - simulated server for educational purposes
      # In browsers, we simulate server behavior by accepting connections to WebSocket servers
      class TCPServer
        def initialize(host = "0.0.0.0", port = nil)
          @host = host.to_s
          @port = port.to_i
          @closed = false
          @accept_queue = []
          
          # Store server info for accept() to use
          # When accept() is called, we'll create a TCPSocket connected to a WebSocket server
          # This simulates a client connecting to our "server"
        end
        
        def accept
          raise "Server is closed" if @closed
          
          # Simulate accepting a connection by creating a TCPSocket
          # In a real server, this would block until a client connects
          # In browser, we simulate by connecting to a WebSocket server
          # For the demo, we connect to echo server which simulates a client connecting
          
          # Retry logic - simulate waiting for a client to connect
          max_retries = 3
          retry_count = 0
          
          begin
            # Create and return a TCPSocket (simulating a client connection)
            # This socket is already connected, simulating accept() returning a connected socket
            socket = TCPSocket.new(@host, @port)
            socket
          rescue => e
            retry_count += 1
            if retry_count < max_retries
              # Wait a bit before retrying (simulate blocking)
              sleep(0.5)
              retry
            else
              # After retries, raise the error
              raise "Failed to accept connection after \#{max_retries} attempts: \#{e.message}"
            end
          end
        end
        
        def close
          @closed = true
        end
        
        def closed?
          @closed
        end
        
        def inspect
          # Simple inspect without any IO operations
          "\#<TCPServer:\#{@host}:\#{@port}>"
        end
        
        def to_s
          # Simple to_s without any IO operations
          inspect
        end
      end
      
      # Thread support for concurrent execution
      # In browser, we simulate threads - execute blocks immediately but track them as threads
      class Thread
        @@threads = []
        @@thread_id_counter = 0
        
        def self.start(*args, &block)
          # Create a new thread and execute the block
          thread = Thread.new(*args, &block)
          @@threads << thread
          thread
        end
        
        def self.new(*args, &block)
          thread_obj = allocate
          thread_obj.instance_variable_set(:@args, args)
          thread_obj.instance_variable_set(:@block, block)
          thread_obj.instance_variable_set(:@alive, true)
          thread_obj.instance_variable_set(:@value, nil)
          thread_obj.instance_variable_set(:@thread_id, @@thread_id_counter += 1)
          thread_obj.instance_variable_set(:@completed, false)
          
          # Execute the block immediately (simulate thread execution)
          # In a real implementation, this would run concurrently
          begin
            if block
              thread_obj.instance_variable_set(:@value, block.call(*args))
            end
            thread_obj.instance_variable_set(:@completed, true)
          rescue => e
            thread_obj.instance_variable_set(:@completed, true)
            thread_obj.instance_variable_set(:@error, e)
          ensure
            thread_obj.instance_variable_set(:@alive, false)
          end
          
          thread_obj
        end
        
        def initialize(*args, &block)
          @args = args
          @block = block
          @alive = true
          @value = nil
          @thread_id = @@thread_id_counter += 1
          @completed = false
        end
        
        def join(timeout = nil)
          # Thread already executed synchronously, so just return value
          @value
        end
        
        def alive?
          @alive
        end
        
        def value
          @value
        end
        
        def self.current
          # Return a mock current thread (singleton pattern)
          @current_thread ||= begin
            thread = allocate
            thread.instance_variable_set(:@alive, true)
            thread.instance_variable_set(:@thread_id, 0)
            thread.instance_variable_set(:@completed, true)
            thread
          end
          @current_thread
        end
        
        def self.list
          @@threads
        end
      end
      
      # WebSocket polyfill ready - socket classes moved to stdlib polyfills
      "websocket_polyfill_ready"
    `);
    
    console.log('Ruby WebSocket polyfill initialized');
  } catch (err) {
    console.warn('Failed to initialize Ruby WebSocket polyfill:', err);
  }
}

// Export for use in other modules
window.RubyWebSocketPolyfill = {
  initializeRubyWebSocketPolyfill
};
