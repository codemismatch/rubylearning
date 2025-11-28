---
title: Test Socket Polyfill
layout: page
---

# Test Socket Polyfill

This page tests if the `TCPSocket` polyfill correctly connects to `wss://echo.websocket.org` and echoes data back.

<div class="code-window">
  <div class="code-header">
    <div class="code-title">Socket Test</div>
  </div>
  <pre data-executable="true"><code class="language-ruby">
require 'socket'

puts "Connecting to echo server (via localhost redirect)..."
# The polyfill redirects localhost to echo.websocket.org
socket = TCPSocket.new('localhost', 80)
puts "Connected!"

message = "Hello from Ruby WASM!"
puts "Sending: #{message}"
socket.write(message)

puts "Reading response..."
# The polyfill buffers messages, so we might need a small sleep to ensure data arrives
sleep(1)
response = socket.recv(100)
puts "Received: #{response}"

socket.close
puts "Connection closed."
</code></pre>
</div>
