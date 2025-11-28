---
layout: tutorial
title: "Chapter 43 &ndash; Socket Programming & Threads"
permalink: /tutorials/ruby-socket-programming/
difficulty: intermediate
summary: Build a tiny TCP server and client with Ruby's socket library, understand ports/IPs, and use threads to handle multiple connections.
previous_tutorial:
  title: "Chapter 42: Ruby Constants"
  url: /tutorials/ruby-constants/
next_tutorial:
  title: "Chapter 44: Ruby Threads"
  url: /tutorials/ruby-threads/
related_tutorials:
  - title: "Ruby Threads"
    url: /tutorials/ruby-threads/
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
---

> Adapted from Satish Talim's "Socket Programming and Threads" lesson, updated for Typophic.

Networking in Ruby leans on the BSD sockets API but trims away the ceremony. A socket represents one conversation between two endpoints; the server waits for clients, and each client exchanges data over its own connection.

### TCP/IP refresher

- **Client vs server**: The client initiates a request (e.g., your browser), while the server listens for inbound requests and answers them.
- **Ports**: Integers between `0` and `65535`. Well-known services occupy 0-1023 (`80`=HTTP, `25`=SMTP), registered services use 1024-49151, and dynamic/private ports use 49152-65535.
- **IP addresses**: IPv4 addresses are four bytes (e.g., `132.163.4.102`). `127.0.0.1` / `localhost` is the loopback address that always points to the current machine.

A socket is the combination of an IP address and a port. Ruby mirrors the BSD API, so if you've written network code in C, the same ideas apply.

### Ruby's socket classes

Load the standard library with `require "socket"`. The important classes:

- `Socket`: low-level API that matches the original BSD calls.
- `TCPSocket`: wraps a connection-oriented TCP client.
- `TCPServer`: helper for listening sockets that accept incoming TCP connections.

All of these inherit from `IO`, so familiar methods like `read`, `write`, and `close` work as expected.

### Add threads for concurrent clients

Ruby's threads are lightweight enough for simple demos. Before writing your own code, skim the dedicated [Ruby Threads](/tutorials/ruby-threads/) guide so you know how scheduling and synchronization work.

### Date-Time server (`p068dtserver.rb`)

<div class="code-window">
  <div class="code-header">
    <div class="window-btn red"></div>
    <div class="window-btn yellow"></div>
    <div class="window-btn green"></div>
    <div class="window-title">p068dtserver.rb</div>
  </div>
  <pre data-executable="true"><code class="language-ruby">
# Date Time Server - server side using thread
require "socket"

# In this browser simulation, TCPServer connects to an echo server
server = TCPServer.new("localhost", 80)

puts "Server started. Handling 3 clients then exiting..."

# Run only 3 times to avoid infinite loop in browser
3.times do
  # accept() simulates a client connecting
  Thread.start(server.accept) do |socket|
    puts "Client connected"
    socket.write(Time.now.to_s)
    puts "Sent time: #{Time.now}"
    socket.close
    puts "Client closed"
  end
  sleep(1) # Pause between connections
end
puts "Server finished."
</code></pre>
</div>

> **Note:** In this browser environment, `TCPServer` is simulated by connecting to a public WebSocket echo server. `Thread.start` runs the block immediately.

Key steps:

1. `TCPServer.new` binds to a port (simulated here).
2. `server.accept` waits for a client.
3. `Thread.start` handles the client.
4. `socket.write` sends the timestamp.

Run the server in one terminal with `ruby p068dtserver.rb`; it will block, waiting for clients.

### Date-Time client (`p069dtclient.rb`)

<div class="code-window">
  <div class="code-header">
    <div class="window-btn red"></div>
    <div class="window-btn yellow"></div>
    <div class="window-btn green"></div>
    <div class="window-title">p069dtclient.rb</div>
  </div>
  <pre data-executable="true"><code class="language-ruby">
require "socket"

# Connect to the server (redirects to echo server in browser)
socket = TCPSocket.new("localhost", 80)

# Read initial welcome message from echo server
sleep(1)
welcome = socket.recv(1000)
puts "Server says: #{welcome.strip}"

# Send a message
puts "Sending request..."
socket.write("What time is it?")

# Read response
sleep(1)
response = socket.recv(100)
puts "Received: #{response}"

socket.close
</code></pre>
</div>

`TCPSocket.new` opens a TCP connection to the host/port pair. `recv(100)` reads up to 100 bytes; the server only sends a timestamp, so that is sufficient. Remember to close the socket so the server can reclaim resources.

### Practice checklist

- [ ] Sketch the client-server flow for your own app idea and label which side initiates the connection.
- [ ] Replace `localhost` with a LAN IP to confirm the code works between two real machines.
- [ ] Send a full sentence from the server and have the client acknowledge receipt before closing.
- [ ] Experiment with `Thread.start` vs. sequential handling to see how concurrency affects throughput.
- [ ] Wrap the server loop with logging and exception handling so failures don't crash the process.

Summary: Ruby sockets piggyback on familiar IO primitives, so once you understand ports/IPs you can craft small TCP services with only a few dozen lines of code. Next, deepen your concurrency toolbox in the Ruby Threads chapter.

#### Practice 1 - Sketching client-server flow

**Goal:** Sketch the client-server flow for an app and label which side initiates the connection.

#> ruby :practice

# TODO: Write two puts statements describing the flow.
# 1. Server: Create TCPServer, then accept.
# 2. Client: Create TCPSocket to initiate connection.

```solution
puts "Server: TCPServer.new('localhost', 3000) then accept connections"
puts "Client: TCPSocket.new('localhost', 3000) initiates connection"
```

```test
result = false
out = output.string.downcase
if out.include?("server") && out.include?("client") && out.include?("accept") && out.include?("initiate")
  result = true
else
  output.puts("Make sure to mention both Server (accept) and Client (initiate).")
end
result
```

#!

#### Practice 2 - LAN IP vs localhost

**Goal:** Show how you would replace `localhost` with a LAN IP.

#> ruby :practice

# TODO: Define a variable `lan_ip` with value "192.168.1.10"
# Then print the code to create a TCPSocket connecting to that IP on port 3000.

```solution
lan_ip = "192.168.1.10"
puts "TCPSocket.new('#{lan_ip}', 3000)"
```

```test
result = false
out = output.string
if out.include?("192.168.1.10") && out.include?("TCPSocket.new") && out.include?("3000")
  result = true
else
  output.puts("Print the TCPSocket.new line using the lan_ip variable.")
end
result
```

#!

#### Practice 3 - Simple message and acknowledgement

**Goal:** Send a full sentence from the server and have the client acknowledge receipt.

#> ruby :practice

# TODO: Use the MockConnection class to simulate a conversation.
# 1. Server sends "Hello from server"
# 2. Client receives it and prints it
# 3. Client sends "ACK"
# 4. Server receives it and prints it

```solution
class MockConnection
  def initialize
    @server_inbox = []
    @client_inbox = []
  end

  def server_puts(message)
    @client_inbox << message
  end

  def client_gets
    @client_inbox.shift
  end

  def client_puts(message)
    @server_inbox << message
  end

  def server_gets
    @server_inbox.shift
  end
end

conn = MockConnection.new
conn.server_puts("Hello from server")
message = conn.client_gets
puts "Client received: #{message}"
conn.client_puts("ACK")
ack = conn.server_gets
puts "Server received acknowledgement: #{ack}"
```

```test
result = false
out = output.string
if out.include?("Client received: Hello from server") && out.include?("Server received acknowledgement: ACK")
  result = true
else
  output.puts("Ensure both client and server print their received messages.")
end
result
```

#!

#### Practice 4 - Threads vs sequential handling

**Goal:** Contrast `Thread.start` with sequential handling in a server loop.

#> ruby :practice

# TODO: Iterate through `clients` twice.
# First loop: Print "Handling #{client} sequentially"
# Second loop: Use Thread.new to print "Handling #{client} in thread #{Thread.current.object_id}"
# Remember to join threads!

```solution
clients = %w[alpha beta gamma]

puts "Sequential handling:"
clients.each do |client|
  puts "Handling #{client} sequentially"
end

puts "Threaded handling:"
threads = clients.map do |client|
  Thread.new do
    puts "Handling #{client} in thread #{Thread.current.object_id}"
  end
end

threads.each(&:join)
```

```test
result = false
out = output.string
if out.include?("Sequential handling") && out.include?("Threaded handling") && out.include?("in thread")
  result = true
else
  output.puts("Print both sequential and threaded handling messages.")
end
result
```

#!

#### Practice 5 - Logging and exception handling

**Goal:** Wrap the server loop with logging and exception handling.

#> ruby :practice

# TODO: Wrap the server.accept call in a begin/rescue block.
# Log "accepted #{client}" on success.
# Log "socket error: #{e.message}" on failure.

```solution
begin
  require "monitor"
rescue LoadError
end

unless defined?(MonitorMixin)
  module MonitorMixin
    def mon_initialize; end
    def mon_enter; end
    def mon_exit; end
  end
end

require "logger"

class FakeServer
  def initialize(events)
    @events = events.dup
  end

  def pending?
    !@events.empty?
  end

  def accept
    raise IOError, "no clients waiting" if @events.empty?
    event = @events.shift
    raise IOError, "simulated failure" if event == :error
    "client:#{event}"
  end
end

server = FakeServer.new([:alpha, :error, :beta])
logger = Logger.new($stdout)

while server.pending?
  begin
    client = server.accept
    logger.info("accepted #{client}")
  rescue => e
    logger.error("socket error: #{e.message}")
  end
end
```

```test
result = false
out = output.string
if out.include?("accepted client:alpha") && out.include?("socket error: simulated failure") && out.include?("accepted client:beta")
  result = true
else
  output.puts("Ensure you log both successes and errors.")
end
result
```

#!
