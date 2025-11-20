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

```ruby
# Date Time Server - server side using thread
require "socket"

server = TCPServer.new("localhost", 20_000)

loop do
  Thread.start(server.accept) do |socket|
    puts "#{socket} connected"
    socket.write(Time.now)
    puts "#{socket} closing"
    socket.close
  end
end
```

> **Browser Implementation:** `TCPServer` and `Thread` are polyfilled for browser environments. The server code above will run, but note:
> - `TCPServer.accept()` simulates accepting connections by creating `TCPSocket` instances connected to WebSocket servers
> - `Thread.start` executes blocks immediately (simulated concurrency for educational purposes)
> - The server loop will run continuously - use Ctrl+C or stop execution manually
> - For production servers, run on a backend Ruby server; browser clients can connect using `TCPSocket` (polyfilled to use WebSockets)

Key steps:

1. `TCPServer.new("localhost", 20_000)` binds to port `20000` on the loopback interface.
2. `server.accept` blocks until a client connects, returning a `TCPSocket`.
3. `Thread.start` hands each client to its own thread so multiple clients can be served concurrently.
4. `socket.write` sends the timestamp, and `socket.close` releases the connection.

Run the server in one terminal with `ruby p068dtserver.rb`; it will block, waiting for clients.

### Browser Alternative: WebSocket Server

For browser-based applications, WebSockets provide similar functionality:

**Server (Ruby with WebSocket library, e.g., `faye-websocket`):**
```ruby
require 'faye/websocket'
require 'eventmachine'

EM.run do
  EM::WebSocket.start(host: '0.0.0.0', port: 20000) do |ws|
    ws.onopen do |handshake|
      puts "Client connected"
      ws.send(Time.now.to_s)
    end
    
    ws.onclose do
      puts "Client disconnected"
    end
  end
end
```

**Client (JavaScript in browser):**
```javascript
const ws = new WebSocket('ws://localhost:20000');
ws.onmessage = (event) => {
  console.log('Time from server:', event.data);
};
ws.onopen = () => {
  console.log('Connected to server');
};
```

WebSockets provide bidirectional communication similar to TCP sockets but are browser-compatible and use the `ws://` or `wss://` protocols instead of raw TCP.

### Date-Time client (`p069dtclient.rb`)

```ruby
require "socket"

socket = TCPSocket.new("127.0.0.1", 20_000)
time_string = socket.recv(100)

puts time_string

socket.close
```

`TCPSocket.new` opens a TCP connection to the host/port pair. `recv(100)` reads up to 100 bytes; the server only sends a timestamp, so that is sufficient. Remember to close the socket so the server can reclaim resources.

### Practice checklist

- [ ] Sketch the client-server flow for your own app idea and label which side initiates the connection.
- [ ] Replace `localhost` with a LAN IP to confirm the code works between two real machines.
- [ ] Send a full sentence from the server and have the client acknowledge receipt before closing.
- [ ] Experiment with `Thread.start` vs. sequential handling to see how concurrency affects throughput.
- [ ] Wrap the server loop with logging and exception handling so failures don't crash the process.

Summary: Ruby sockets piggyback on familiar IO primitives, so once you understand ports/IPs you can craft small TCP services with only a few dozen lines of code. Next, deepen your concurrency toolbox in the Ruby Threads chapter.

#### Practice 1 - Sketching client-server flow

<p><strong>Goal:</strong> Sketch the client-server flow for an app and label which side initiates the connection.</p>

```ruby
# TODO: Print a brief pseudo-flow describing which side (client or
# server) opens the socket and which accepts connections.
```

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-socket-programming"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-socket-programming:0">
puts "Server: TCPServer.new('localhost', 3000) then accept connections"
puts "Client: TCPSocket.new('localhost', 3000) initiates connection"
</script>

#### Practice 2 - LAN IP vs localhost

<p><strong>Goal:</strong> Show how you would replace `localhost` with a LAN IP.</p>

```ruby
# TODO: Print an example client connection line using a private LAN IP
# such as 192.168.x.x.
```

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-socket-programming"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-socket-programming:1">
puts "TCPSocket.new('192.168.1.10', 3000)"
</script>

#### Practice 3 - Simple message and acknowledgement

<p><strong>Goal:</strong> Send a full sentence from the server and have the client acknowledge receipt.</p>

```ruby
# TODO: Sketch send/receive/ack behaviour in a comment-style snippet.
```

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-socket-programming"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-socket-programming:2">
puts "# server: client.puts 'Hello from server'"
puts "# client: message = socket.gets; socket.puts 'ACK'"
</script>

#### Practice 4 - Threads vs sequential handling

<p><strong>Goal:</strong> Contrast `Thread.start` with sequential handling in a server loop.</p>

```ruby
# TODO: Print pseudo-code that shows a threaded server loop using
# Thread.start for each client.
```

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-socket-programming"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-socket-programming:3">
puts "server = TCPServer.new(3000)"
puts "loop do"
puts "  client = server.accept"
puts "  Thread.start(client) do |sock|"
puts "    # handle client"
puts "  end"
puts "end"
</script>

#### Practice 5 - Logging and exception handling

<p><strong>Goal:</strong> Wrap the server loop with logging and exception handling.</p>

```ruby
# TODO: Print a small example that pairs a server loop with logging
# and exception handling to keep the process alive on failure.
```

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-socket-programming"
     data-practice-index="4"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-socket-programming:4">
puts "loop do"
puts "  begin"
puts "    client = server.accept"
puts "    logger.info('accepted connection')"
puts "  rescue => e"
puts "    logger.error(\"socket error: \#{e.message}\")"
puts "  end"
puts "end"
</script>
