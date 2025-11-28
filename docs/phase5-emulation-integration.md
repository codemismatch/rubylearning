# Phase 5 Technical Design: Browser Emulation Integration

## Objective
Replace manual "bash in JS" polyfills with a robust, persistent filesystem (ZenFS) and a proper shell emulator, while **retaining our lightweight JS polyfills for the Ruby Standard Library** to avoid large downloads.

## 1. Architecture Overview

```mermaid
graph TD
    UI[xterm.js Terminal] <--> Shell[Bash Emulator]
    Shell <--> |Commands (ls, cd)| FS[ZenFS]
    Shell <--> |Execution (ruby)| WASM[Ruby WASM]
    WASM <--> |File I/O| FS
    WASM <--> |Stdlib (Time, JSON)| Polyfills[JS Polyfills]
    FS <--> |Persistence| IDB[IndexedDB]
```

## 2. Component Integration

### A. ZenFS Setup (User Data Only)
We will use **ZenFS** to provide persistence for *user-created files*, not the Ruby stdlib.
1.  **Mounts**:
    -   `/home/rubylearner`: **IndexedDB** backend. This ensures user files (`hello.txt`, `script.rb`) persist across page reloads.
    -   `/tmp`: **InMemory** backend.
    -   *(Removed)* `/usr/lib/ruby`: We will **not** mount a full HTTP backend for stdlib, as we are emulating it.

### B. Ruby WASM + WASI + ZenFS
We need to wire WASI to ZenFS for file operations, but keep our polyfills for library features.
-   **WASI Shim**: Use a shim (like `@bjorn3/browser_wasi_shim`) to route file syscalls (`open`, `read`, `write`) to ZenFS.
-   **Polyfills**: Continue to inject `ruby-stdlib-polyfills.js` into the VM.
    -   This file manually defines `Time`, `JSON`, `TCPSocket` using `JS.global`.
    -   This avoids the need for `time.rb` or `json.rb` to exist in the filesystem.

### C. Bash Emulator + ZenFS
The shell emulator will interact with ZenFS to manage the user's workspace.
-   **Command Mapping**:
    -   `ls`: `fs.readdir('/home/rubylearner')`
    -   `cat`: `fs.readFile(...)`
    -   `rm`: `fs.unlink(...)`

### D. Bash Emulator + Ruby WASM
When `ruby script.rb` is run:
1.  **Shell**: Reads `script.rb` from ZenFS.
2.  **VM**: Instantiates Ruby WASM.
3.  **Execution**:
    -   The VM runs the script.
    -   If the script does `File.write`, WASI routes it to ZenFS (IndexedDB).
    -   If the script does `Time.now`, the JS polyfill handles it.

## 3. Implementation Steps
1.  **Vendor Libraries**: `zenfs`, `xterm.js`, `browser_wasi_shim`.
2.  **Initialize FS**: Set up ZenFS with IndexedDB at `/home`.
3.  **Shell UI**: Implement `xterm.js` interface.
4.  **Update Ruby Exec**:
    -   Remove the manual `Kernel` monkey-patches for `ls`/`cat` (let the Shell handle it).
    -   Keep the `Kernel` monkey-patches for `puts`/`gets` (to route I/O to xterm).
    -   Keep `ruby-stdlib-polyfills.js`.
