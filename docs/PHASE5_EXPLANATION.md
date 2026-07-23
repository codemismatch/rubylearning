# Phase 5: Browser Emulation Integration - Explained

## What is Phase 5?

Phase 5 is a planned enhancement to replace the current **manual "bash in JS" polyfills** with a more robust, production-ready system that includes:

1. **Persistent filesystem** (ZenFS) - Files persist across page reloads
2. **Proper shell emulator** (bash-like commands) - Real terminal experience
3. **Terminal UI** (xterm.js) - Professional terminal interface

**Current Status**: ✅ Design document exists, ❌ Implementation not started

---

## Current System (Before Phase 5)

### How It Works Now

Right now, the Ruby execution system uses:

1. **Ruby WASM** - Runs Ruby code in the browser
2. **Manual Polyfills** - JavaScript implementations of Ruby stdlib features:
   - `Time` class (uses JavaScript `Date`)
   - `JSON` (uses JavaScript `JSON`)
   - `StringIO` (string-based buffer)
   - `TCPSocket` (uses WebSockets)
3. **In-Memory Filesystem** - Files exist only during the session
4. **Manual Command Polyfills** - Ruby methods like `ls`, `cat` are monkey-patched into `Kernel`

### Current Limitations

#### 1. **No Persistent Storage**
```ruby
# User creates a file
File.write("my_script.rb", "puts 'hello'")

# User refreshes the page
# ❌ File is gone! It was only in memory
```

#### 2. **No Real Terminal**
- Users can't run shell commands like `ls`, `cd`, `cat` directly
- Instead, they have to use Ruby methods: `Dir.entries`, `File.read`, etc.
- No terminal UI - just code execution buttons

#### 3. **Manual Polyfills Are Fragile**
```ruby
# Current: Manual monkey-patching
module Kernel
  def ls(path = ".")
    Dir.entries(path).each { |f| puts f }
  end
end
```
- These are custom implementations that might not match real behavior
- Hard to maintain and extend

#### 4. **No File Persistence**
- Files created during a session are lost on page refresh
- Can't build up a workspace over time
- Can't save work between sessions

---

## Phase 5 Vision (After Implementation)

### What It Will Provide

#### 1. **Persistent Filesystem (ZenFS)**

**Problem Solved**: Files persist across page reloads

```ruby
# User creates a file
File.write("/home/rubylearner/my_script.rb", "puts 'hello'")

# User refreshes the page
# ✅ File still exists! Stored in IndexedDB
File.read("/home/rubylearner/my_script.rb")  # => "puts 'hello'"
```

**How It Works**:
- Uses **ZenFS** - a filesystem library that stores data in IndexedDB
- Mounts `/home/rubylearner` to IndexedDB backend
- Files persist in browser storage
- Works offline

#### 2. **Real Terminal Interface (xterm.js)**

**Problem Solved**: Professional terminal experience

**Before (Current)**:
```
[Run Button] → Executes Ruby code
[Check Button] → Runs tests
```

**After (Phase 5)**:
```
$ ls
my_script.rb
hello.txt
notes.md

$ cat my_script.rb
puts 'hello'

$ ruby my_script.rb
hello

$ cd /home/rubylearner
$ pwd
/home/rubylearner
```

**How It Works**:
- Uses **xterm.js** - a terminal emulator library
- Provides a real terminal UI in the browser
- Users can type commands like in a real terminal
- Supports bash-like commands: `ls`, `cd`, `cat`, `rm`, `mkdir`, etc.

#### 3. **Shell Emulator**

**Problem Solved**: Real shell commands instead of Ruby methods

**Before (Current)**:
```ruby
# User has to use Ruby methods
Dir.entries(".").each { |f| puts f }
File.read("script.rb")
```

**After (Phase 5)**:
```bash
# User can use shell commands
$ ls
$ cat script.rb
$ ruby script.rb
```

**How It Works**:
- Shell emulator interprets commands
- Maps shell commands to filesystem operations
- `ls` → `fs.readdir()`
- `cat` → `fs.readFile()`
- `rm` → `fs.unlink()`
- `ruby script.rb` → Executes Ruby WASM

#### 4. **WASI Integration**

**Problem Solved**: Proper file I/O routing

**How It Works**:
- **WASI** (WebAssembly System Interface) provides system calls
- **browser_wasi_shim** routes WASI calls to ZenFS
- When Ruby code does `File.write`, it goes through WASI → ZenFS → IndexedDB
- Seamless integration between Ruby and filesystem

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface                        │
│  ┌──────────────────────────────────────────────────┐   │
│  │         xterm.js Terminal UI                      │   │
│  │  $ ls                                             │   │
│  │  $ cat script.rb                                  │   │
│  │  $ ruby script.rb                                 │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                        ↕
┌─────────────────────────────────────────────────────────┐
│                  Shell Emulator                         │
│  • Parses commands (ls, cd, cat, ruby)                  │
│  • Routes to appropriate handler                        │
└─────────────────────────────────────────────────────────┘
        ↕                    ↕
┌──────────────┐    ┌──────────────────────────────┐
│   ZenFS      │    │      Ruby WASM                │
│  Filesystem  │◄───┤  (Ruby Interpreter)          │
│              │    │                               │
│  /home/      │    │  File.write() ──┐            │
│  rubylearner │    │  Time.now()     │            │
│              │    │  JSON.parse()   │            │
│  /tmp/       │    └─────────────────┼────────────┘
└──────────────┘                     │
        ↕                            │
┌──────────────┐                     │
│  IndexedDB   │                     │
│  (Browser    │                     │
│   Storage)   │                     │
└──────────────┘                     │
                                      │
                        ┌─────────────┘
                        │
                ┌───────▼──────────┐
                │  JS Polyfills    │
                │  (Time, JSON)    │
                └──────────────────┘
```

---

## What Stays the Same

### ✅ Keep JS Polyfills for Stdlib

**Why**: To avoid large downloads

- **Current**: `ruby.wasm` (~2-3MB) + JS polyfills = Small bundle
- **Alternative**: `ruby+stdlib.wasm` (~15-20MB) = Large bundle

**Phase 5 keeps**:
- `ruby-stdlib-polyfills.js` for `Time`, `JSON`, `TCPSocket`
- These are lightweight and work well
- No need to load full stdlib from filesystem

### ✅ Keep Kernel I/O Routing

**Why**: To route `puts`/`gets` to terminal

- `Kernel#puts` → Outputs to xterm.js terminal
- `Kernel#gets` → Reads from xterm.js terminal
- This provides the interactive terminal experience

---

## What Changes

### ❌ Remove Manual Command Polyfills

**Before**:
```ruby
# Manual monkey-patching
module Kernel
  def ls(path = ".")
    Dir.entries(path).each { |f| puts f }
  end
end
```

**After**:
```bash
# Real shell command
$ ls
```

The shell emulator handles `ls`, not Ruby.

### ✅ Add Persistent Storage

**Before**: Files lost on refresh  
**After**: Files persist in IndexedDB

### ✅ Add Terminal UI

**Before**: Code execution buttons  
**After**: Full terminal interface

---

## Implementation Steps

### 1. Install Dependencies
```bash
npm install zenfs xterm @bjorn3/browser_wasi_shim
# Or vendor them in the theme
```

### 2. Initialize ZenFS
```javascript
import { fs } from 'zenfs';
import { IndexedDB } from 'zenfs/backends/IndexedDB';

// Mount IndexedDB at /home/rubylearner
await fs.mount('/home/rubylearner', new IndexedDB());
```

### 3. Set Up Terminal UI
```javascript
import { Terminal } from 'xterm';

const terminal = new Terminal();
terminal.open(document.getElementById('terminal'));
```

### 4. Create Shell Emulator
```javascript
// Parse commands and route to handlers
function executeCommand(cmd) {
  if (cmd === 'ls') {
    return fs.readdir('/home/rubylearner');
  } else if (cmd.startsWith('cat ')) {
    return fs.readFile(cmd.split(' ')[1]);
  } else if (cmd.startsWith('ruby ')) {
    return executeRubyScript(cmd.split(' ')[1]);
  }
  // ... etc
}
```

### 5. Wire WASI to ZenFS
```javascript
import { WASI } from '@bjorn3/browser_wasi_shim';

const wasi = new WASI({
  // Route file operations to ZenFS
  fs: zenfs
});
```

### 6. Update Ruby Exec
- Remove manual `ls`/`cat` polyfills
- Keep `puts`/`gets` routing to terminal
- Keep stdlib polyfills

---

## Benefits of Phase 5

### 1. **Better User Experience**
- Real terminal interface (familiar to developers)
- Files persist across sessions
- Can build up a workspace over time

### 2. **More Robust**
- Uses proven libraries (ZenFS, xterm.js)
- Less custom code to maintain
- Better error handling

### 3. **More Features**
- Can add more shell commands easily
- Can support file operations better
- Can add features like history, autocomplete

### 4. **Professional Feel**
- Looks like a real development environment
- More engaging for learners
- Better for teaching command-line skills

---

## Current Status

- ✅ **Design Document**: Complete (`docs/phase5-emulation-integration.md`)
- ✅ **Research**: Done (architecture planned)
- ❌ **Implementation**: Not started
- ❌ **Dependencies**: Not installed
- ❌ **Integration**: Not integrated

---

## When to Implement Phase 5?

**Priority**: Medium-Low

**Reasons to implement**:
- Users request persistent file storage
- Want to add terminal-based tutorials
- Want more professional feel

**Reasons to wait**:
- Current system works for most use cases
- Phase 5 is a significant refactor
- Other features (minification, theme fixes) are higher priority

---

## Summary

**Phase 5** is about upgrading from a simple code execution system to a full terminal-based development environment with persistent storage. It's a nice-to-have enhancement that would make the learning experience more professional and feature-rich, but the current system works well for most tutorial needs.

**Current System**: ✅ Works well for tutorials  
**Phase 5**: 🎯 Would make it even better, but not urgent
