# Ruby-Exec Code Block Fixes

## Issues Fixed

### 1. **Stale Code Execution**
**Problem:** When pasting code or editing, the exec block would continue to evaluate old code.

**Root Cause:** Code extraction used `codeBlock.textContent` which referenced the DOM, but the DOM could contain stale highlighted HTML instead of the current plain text.

**Solution:** Introduced a `currentPlainText` variable that:
- Stores the actual plain text content
- Updates immediately on every input event
- Is used as the source for code execution (not the DOM)

```javascript
// Before (BROKEN):
const userCode = codeBlock.textContent.trim();

// After (FIXED):
let currentPlainText = codeBlock.textContent;
const updatePlainText = () => {
  currentPlainText = codeBlock.textContent;
};
// Later during execution:
const userCode = currentPlainText.trim();
```

### 2. **Cursor Position Issues**
**Problem:** 
- Clicking last line/character and pressing Enter wouldn't move cursor correctly
- Cursor would appear on wrong line after second Enter
- Active content highlighting would disappear when clicking

**Root Cause:** Complex cursor position tracking with `getCursorPosition()` and `setCursorPosition()` was fighting with the browser's natural cursor handling, especially during focus/blur events.

**Solution:** 
- Simplified to let the browser handle cursor positioning naturally
- Added explicit Enter key handler that properly inserts `\n` character
- Removed complex cursor position save/restore logic
- Made contenteditable on `<code>` element instead of `<pre>` for better control

```javascript
// Handle Enter key to ensure proper line breaks
codeBlock.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    
    // Insert a newline character
    const selection = window.getSelection();
    if (!selection.rangeCount) return;
    
    const range = selection.getRangeAt(0);
    range.deleteContents();
    range.insertNode(document.createTextNode('\n'));
    
    // Move cursor after the newline
    range.collapse(false);
    selection.removeAllRanges();
    selection.addRange(range);
    
    // Trigger input event to update stored text
    codeBlock.dispatchEvent(new Event('input', { bubbles: true }));
  }
});
```

### 3. **Highlighting State Management**
**Problem:** Active content highlighting would disappear when clicking, making it hard to see syntax while editing.

**Root Cause:** The focus/blur handlers were toggling between highlighted and plain text, but the state tracking (`isHighlighted` flag) wasn't reliable, and the DOM manipulation was interfering with editing.

**Solution:** Implemented a cleaner state machine:
- **While editing (focused):** Show plain text only, no highlighting
- **While not editing (blurred):** Show syntax highlighted version
- Track editing state with `isEditing` flag
- Update `currentPlainText` on every input
- Only apply highlighting when not actively editing

```javascript
let isEditing = false;

// Handle focus - switch to plain text for editing
codeBlock.addEventListener('focus', () => {
  isEditing = true;
  convertToPlainText();
});

// Handle blur - apply syntax highlighting
codeBlock.addEventListener('blur', () => {
  isEditing = false;
  updatePlainText();
  applySyntaxHighlighting();
});

// Apply syntax highlighting without losing cursor position
const applySyntaxHighlighting = () => {
  if (isEditing || document.activeElement === codeBlock) {
    // Don't highlight while actively editing
    return;
  }
  // ... apply highlighting
};
```

### 4. **Paste Behavior**
**Problem:** Pasting code wouldn't update the execution context properly.

**Root Cause:** Default paste behavior wasn't updating the `currentPlainText` variable.

**Solution:** Added explicit paste handler that:
- Prevents default paste behavior
- Extracts plain text from clipboard
- Inserts at cursor position as text node
- Updates `currentPlainText` immediately

```javascript
codeBlock.addEventListener('paste', (e) => {
  e.preventDefault();
  
  // Get plain text from clipboard
  const text = (e.clipboardData || window.clipboardData).getData('text/plain');
  
  // Insert at cursor position
  const selection = window.getSelection();
  if (!selection.rangeCount) return;
  
  const range = selection.getRangeAt(0);
  range.deleteContents();
  range.insertNode(document.createTextNode(text));
  
  // Move cursor to end of inserted text
  range.collapse(false);
  selection.removeAllRanges();
  selection.addRange(range);
  
  // Update stored text
  updatePlainText();
});
```

### 5. **Delete Behavior**
**Problem:** Deleting all code would still show old results when running.

**Root Cause:** Same as issue #1 - stale code extraction.

**Solution:** Fixed by using `currentPlainText` which updates on every input event, including deletions.

## Technical Implementation

### Double Buffering Approach

The new implementation uses a "double buffering" pattern:

1. **Edit Buffer (Plain Text):** `currentPlainText` variable stores the actual code
2. **Display Buffer (Highlighted):** DOM shows syntax-highlighted version when not editing

```
User edits → updatePlainText() → currentPlainText updated
                                         ↓
                                  On blur → applySyntaxHighlighting()
                                                  ↓
                                           DOM shows highlighted version
```

### Event Flow

1. **Focus:** Convert highlighted DOM to plain text
2. **Input:** Update `currentPlainText` immediately
3. **Blur:** Apply syntax highlighting from `currentPlainText`
4. **Run:** Execute code from `currentPlainText` (never from DOM)

## CSS Improvements

Added better styling for the editable code blocks:

- Orange caret color (`#f97316`) for visibility
- Subtle focus outline
- Slightly different background when focused
- Better padding and line-height for comfortable editing

## Testing Checklist

- [x] Click anywhere in code and start typing - cursor appears correctly
- [x] Click last line, last character and press Enter - cursor moves to new line
- [x] Press Enter again - cursor moves to next line (not skipping)
- [x] Edit code and press Run - new code executes
- [x] Copy/paste code from elsewhere and press Run - pasted code executes
- [x] Delete all code and press Run - no output (or error, not old code)
- [x] Syntax highlighting appears when not editing
- [x] Syntax highlighting disappears when editing (plain text shown)
- [x] Multiple edits in succession work correctly
- [x] Paste, edit, run sequence works correctly

## Files Modified

1. `themes/rubylearning/js/code-enhancements.js` - Main logic fixes
2. `themes/rubylearning/css/enhanced-code.css` - Styling improvements

## Migration Notes

No breaking changes. The new implementation is fully backward compatible with existing ruby-exec blocks. The contenteditable is now on the `<code>` element instead of `<pre>`, which provides better control but doesn't affect existing HTML structure.
