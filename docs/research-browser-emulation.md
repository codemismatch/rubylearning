# Research: Browser-based Filesystem and Shell Emulation

## Objective
To replace manual "bash in JS" polyfills and ad-hoc filesystem emulation with robust, existing libraries.

## Filesystem Emulation

### 1. BrowserFS / ZenFS
-   **Description**: Emulates the Node.js `fs` API in the browser.
-   **Backends**: IndexedDB, LocalStorage, InMemory, ZipFS, HTTPRequest.
-   **Pros**:
    -   Standard Node.js API (familiar).
    -   Persistent storage (IndexedDB) allows users to save work between reloads.
    -   Mountable filesystems (can mix in-memory and persistent).
    -   Integration with Emscripten/WASM (via `FS` mapping).
-   **Cons**: `BrowserFS` is older; `ZenFS` is the modern successor but might have less documentation.

### 2. memfs
-   **Description**: In-memory filesystem with Node.js API.
-   **Pros**: Very fast, simple setup.
-   **Cons**: No persistence by default (data lost on reload).

### Recommendation
**ZenFS (or BrowserFS)** is the best fit because it supports **persistence** (IndexedDB) and **WASI integration**. This would allow us to:
1.  Mount a persistent `/home/user` directory.
2.  Mount a read-only `/usr/lib/ruby` from HTTP (lazy loaded).
3.  Let Ruby WASM interact with this filesystem directly.

## Shell Emulation

### 1. WASM-based Shell (Real Bash/Dash)
-   **Approach**: Compile `bash` or `dash` to WASM/WASI.
-   **Pros**: Authentic behavior (pipes, redirection, variables work exactly like Linux).
-   **Cons**:
    -   Heavy download size.
    -   Complexity in "spawning" other WASM processes (like `ruby`). You need a "kernel" or process manager (e.g., `runwasi` or a custom orchestrator).

### 2. JS-based Shell Emulators
-   **Libraries**: `bash-emulator`, `local-echo` (for xterm.js).
-   **Pros**: Lightweight, easy to extend with custom JS commands.
-   **Cons**: "Fake" behavior. Pipes and complex scripting might not work perfectly.

### Recommendation
For a Ruby learning platform, a **JS-based Shell Emulator** (like `bash-emulator` or a custom implementation on top of `xterm.js`) connected to **ZenFS** is likely sufficient and more performant.
-   We don't need full POSIX compliance.
-   We *do* need `ls`, `cd`, `cat`, `mkdir`, `rm` to work reliably with the filesystem.
-   We need `ruby` to run our WASM module.

## Proposed Architecture (Phase 5)
1.  **Filesystem**: Initialize **ZenFS** with an IndexedDB backend mounted at `/home/rubylearner`.
2.  **Shell UI**: Use **xterm.js** for the terminal interface.
3.  **Command Interpreter**: Use **bash-emulator** (or similar) to parse input.
4.  **Execution**:
    -   `ls`, `cd`, `mkdir`: Map directly to ZenFS API calls.
    -   `ruby`: Instantiate the Ruby WASM module, giving it access to the ZenFS instance (via WASI imports).

This setup removes the manual "mocking" of filesystem state and gives us a real, persistent virtual drive.
