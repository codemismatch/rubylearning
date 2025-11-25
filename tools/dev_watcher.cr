require "file_watcher"
require "process"

# Configuration
# We assume we are running from the 'crystal' directory where shard.yml is
CRYSTAL_DIR = Dir.current
SRC_DIR = File.join(CRYSTAL_DIR, "src")
BIN_PATH = File.join(CRYSTAL_DIR, "bin", "typophic")
BUILD_CMD = "crystal build src/bin/typophic.cr -o bin/typophic"

puts "🚀 Starting Typophic Dev Watcher..."
puts "📂 Watching: #{SRC_DIR}"

current_process : Process? = nil

def build_binary
  puts "🔨 Building Typophic..."
  start_time = Time.monotonic
  
  status = Process.run(BUILD_CMD, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
  
  if status.success?
    elapsed = Time.monotonic - start_time
    puts "✅ Build successful in #{elapsed.total_seconds.round(2)}s"
    return true
  else
    puts "❌ Build failed!"
    return false
  end
end

def start_server
  puts "⚡ Starting server..."
  # Pass through arguments from the script invocation
  args = ARGV.join(" ")
  cmd = "#{BIN_PATH} s --watch #{args}"
  
  # Spawn the server process
  Process.new(cmd, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
end

def restart_server(process : Process?)
  if process && !process.terminated?
    puts "🔄 Stopping current server (PID: #{process.pid})..."
    process.signal(Signal::TERM)
    begin
      process.wait
    rescue
      process.signal(Signal::KILL)
    end
  end
  
  if build_binary
    return start_server
  else
    puts "⚠️  Waiting for fix..."
    return nil
  end
end

# Initial build and start
if build_binary
  current_process = start_server
end

# Watch for changes
FileWatcher.watch(SRC_DIR) do |event|
  if event.path.ends_with?(".cr")
    puts "\n📝 Change detected: #{event.path}"
    current_process = restart_server(current_process)
  end
end
