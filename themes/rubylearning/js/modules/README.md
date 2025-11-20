# Code Enhancements Modules

This directory contains the refactored code enhancement modules, split from the original monolithic `code-enhancements.js` file.

## Module Structure

### Core Utilities
- **ruby-syntax-highlighting.js** - Syntax highlighting utilities for Ruby code using Prism.js
- **ui-effects.js** - Visual effects like confetti animations

### Code UI Components
- **code-copy-buttons.js** - Adds copy buttons to code blocks
- **code-overlay-editor.js** - Creates editable overlay for code blocks with syntax highlighting

### Ruby Console
- **ruby-console-drawer.js** - Toggle functionality for the Ruby console drawer
- **ruby-console.js** - Interactive Ruby console (IRB) interface with command history and readline shortcuts

### Ruby Execution
- **ruby-wasm-loader.js** - Handles loading and initialization of Ruby WASM module
- **ruby-exec.js** - Runnable Ruby code blocks with Run/Check buttons and test execution

## Loading Order

Modules are loaded in dependency order:

1. **ruby-syntax-highlighting.js** - No dependencies
2. **ui-effects.js** - No dependencies
3. **code-copy-buttons.js** - Depends on syntax highlighting
4. **code-overlay-editor.js** - Depends on syntax highlighting
5. **ruby-console-drawer.js** - Standalone
6. **ruby-wasm-loader.js** - Needed by exec and console
7. **ruby-console.js** - Depends on WASM loader and syntax highlighting
8. **ruby-exec.js** - Depends on WASM loader, overlay editor, and UI effects

## Main Entry Point

The main `code-enhancements.js` file coordinates loading all modules and initializes features in the correct order.

## Usage

All modules export their functionality via the `window` object:
- `window.RubySyntaxHighlighting`
- `window.UIEffects`
- `window.CodeCopyButtons`
- `window.CodeOverlayEditor`
- `window.RubyConsoleDrawer`
- `window.RubyConsole`
- `window.RubyWasmLoader`
- `window.RubyExec`

## Benefits of Refactoring

1. **Maintainability** - Each module has a single, clear responsibility
2. **Testability** - Modules can be tested independently
3. **Reusability** - Modules can be used in other contexts
4. **Readability** - Smaller files are easier to understand
5. **Performance** - Modules can be loaded conditionally if needed
