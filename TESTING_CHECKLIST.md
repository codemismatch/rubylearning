# Code Editor Testing Checklist

## Quick Start

1. **Hard refresh your browser** (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows/Linux)
2. Navigate to: http://localhost:3000/tutorials/ruby-features/
3. Scroll to the practice sections with interactive code editors

## Test Scenarios

### ✅ Test 1: Cursor Position Preservation on Click

**Goal**: Verify cursor stays where you click

**Steps**:
1. Find the first ruby-exec code block (should have sample code)
2. Click in the MIDDLE of a word (e.g., click between 'p' and 'u' in 'puts')
3. **Expected**: Cursor appears exactly where you clicked
4. **Previously broken**: Cursor would jump to end of code

**Pass criteria**: Cursor appears at click position, not at end

---

### ✅ Test 2: Typing Behavior

**Goal**: Verify normal typing works smoothly

**Steps**:
1. Click into any position in code editor
2. Type: `x = 42`
3. **Expected**: Characters appear at cursor position
4. **Expected**: No jumping or flickering
5. Wait 1 second - syntax highlighting should appear

**Pass criteria**: Typing is smooth, highlighting appears after pause

---

### ✅ Test 3: Enter Key (The Original Issue!)

**Goal**: Verify Enter key creates newlines without cursor jumping

**Steps**:
1. Click at end of first line of code
2. Press Enter
3. **Expected**: New blank line created, cursor on new line
4. Type: `puts "line 2"`
5. Press Enter again
6. Type: `puts "line 3"`
7. **Expected**: Three lines of code, cursor at end of third line

**Pass criteria**: 
- Enter key creates newlines consistently
- Cursor stays on the new line (doesn't jump back)
- All lines are preserved

---

### ✅ Test 4: Deleting All Content

**Goal**: Verify you can delete everything and start fresh

**Steps**:
1. Select all code (Cmd+A or Ctrl+A)
2. Press Delete/Backspace
3. **Expected**: All code disappears
4. Type: `def hello`
5. Press Enter
6. Type: `  puts "hi"`
7. Press Enter
8. Type: `end`

**Pass criteria**: 
- Can delete all content without errors
- Can type fresh code normally
- Multi-line code works correctly

---

### ✅ Test 5: Arrow Key Navigation

**Goal**: Verify cursor moves naturally with keyboard

**Steps**:
1. Click into editor
2. Press Home (cursor should jump to start of line)
3. Press End (cursor should jump to end of line)
4. Press ↑ (cursor should move up one line)
5. Press ↓ (cursor should move down one line)
6. Press ← and → (cursor should move left/right by one character)

**Pass criteria**: All navigation keys work as expected

---

### ✅ Test 6: Mouse Click Navigation

**Goal**: Verify you can click anywhere to position cursor

**Steps**:
1. Click at beginning of first line
2. Verify cursor appears there
3. Click at end of last line
4. Verify cursor appears there
5. Click in the middle of a word
6. Verify cursor appears in that word
7. Type a character
8. **Expected**: Character inserts at cursor position

**Pass criteria**: Click-to-position works everywhere

---

### ✅ Test 7: Focus/Blur Cycle

**Goal**: Verify syntax highlighting appears and disappears correctly

**Steps**:
1. Type some Ruby code: `puts "hello".upcase`
2. Wait 1 second - syntax highlighting should appear while still focused
3. Click OUTSIDE the editor (blur/unfocus)
4. **Expected**: Code is syntax highlighted (colors applied)
5. Click back INTO the editor at a specific word
6. **Expected**: Highlighting disappears, plain text shown for editing
7. **Expected**: Cursor is at the position where you clicked, not at end

**Pass criteria**:
- Syntax highlighting appears on blur
- Highlighting removed on focus
- Cursor position preserved when returning to editor

---

### ✅ Test 8: Live Highlighting While Typing

**Goal**: Verify debounced live highlighting works

**Steps**:
1. Click into editor
2. Type: `def greet`
3. Wait 1 second without typing
4. **Expected**: Syntax highlighting appears (def should be colored)
5. Continue typing: `(name)`
6. **Expected**: Highlighting briefly disappears
7. Wait 1 second again
8. **Expected**: Full method signature is highlighted

**Pass criteria**: 
- Highlighting appears after ~800ms pause
- Cursor position stable throughout
- No flickering or jumping

---

### ✅ Test 9: Copy/Paste

**Goal**: Verify paste operations work correctly

**Steps**:
1. Copy this code to clipboard:
   ```ruby
   def calculate(x, y)
     result = x + y
     puts "Result: #{result}"
     result
   end
   ```
2. Click into editor
3. Paste (Cmd+V or Ctrl+V)
4. **Expected**: All lines appear correctly
5. Wait for syntax highlighting

**Pass criteria**: Pasted code appears correctly with proper newlines

---

### ✅ Test 10: Run Code Button

**Goal**: Verify code execution still works with new highlighting

**Steps**:
1. Type valid Ruby code: `puts "Hello World"`
2. Click "Run" button (or "Check" for practice blocks)
3. **Expected**: Code executes, output appears below
4. Edit the code
5. Run again
6. **Expected**: New output appears

**Pass criteria**: Code execution works normally

---

### ✅ Test 11: Show Code Button (Plain Text State)

**Goal**: Verify "Show code" button leaves editor in ready-to-edit state

**Steps**:
1. Navigate to practice block with "Show code" button
2. Click "Check" button (should fail on TODO)
3. Click "Show code" button
4. **Expected**: Solution code appears as **plain text** (no syntax highlighting)
5. Immediately click into the middle of the code
6. **Expected**: Cursor appears where you clicked
7. Type some characters
8. **Expected**: Characters insert at cursor position, no jumping
9. Delete all content (Cmd+A or Ctrl+A, then Delete)
10. Type new code: `puts "test"`
11. **Expected**: Typing works smoothly, like normal editor

**Pass criteria**: 
- Show code displays plain text (not highlighted initially)
- Can immediately edit without focus/blur cycle
- Cursor stays where clicked
- Delete all + retype works perfectly (this was the reported bug)

---

### ✅ Test 12: Show Code → Blur → Focus Cycle

**Goal**: Verify highlighting applies naturally after showing code

**Steps**:
1. Click "Show code" button (code appears in plain text)
2. Click away from the editor (blur)
3. **Expected**: Syntax highlighting appears naturally
4. Click back into the editor at a specific position
5. **Expected**: Highlighting disappears, cursor at clicked position
6. Type some characters
7. **Expected**: Normal typing behavior, no cursor jumping
8. Click away again (blur)
9. **Expected**: Highlighting reappears

**Pass criteria**: 
- Blur/focus cycle works naturally after show code
- Highlighting appears/disappears correctly
- Cursor position preserved throughout

---

## Expected Behavior Summary

### What Should Work Now:
- ✅ Click anywhere to position cursor (not forced to end)
- ✅ Type naturally without cursor jumping
- ✅ Enter key creates newlines reliably
- ✅ Delete all content and start fresh
- ✅ Navigate with arrow keys
- ✅ Syntax highlighting appears on blur
- ✅ Live highlighting while typing (after 800ms pause)
- ✅ Cursor position preserved through highlight cycles
- ✅ **NEW**: "Show code" button displays plain text, immediately editable
- ✅ **NEW**: After show code, can delete all and retype without issues

### What Was Broken Before:
- ❌ Cursor always jumped to end on focus
- ❌ Enter key created newline but cursor jumped back
- ❌ Deleting all content caused issues
- ❌ Comments spanning multiple lines broke cursor position
- ❌ **NEW**: Show code button applied highlighting, causing state mismatch
- ❌ **NEW**: After show code + delete all, cursor would jump when typing

## Reporting Issues

If you find any problems, please note:

1. **What you did** (exact steps)
2. **What you expected** (desired behavior)
3. **What actually happened** (actual behavior)
4. **Browser console errors** (F12 → Console tab)

### Debug Mode

Add `?debug=caret` to URL for caret position debugging:
```
http://localhost:3000/tutorials/ruby-features/?debug=caret
```

This will log cursor position updates to console.

## Browser Requirements

- **Tested**: Chrome 90+, Firefox 88+, Safari 14+
- **Required**: ES6+ support
- **Required**: contenteditable support

## Known Limitations

1. **Debounce delay**: 800ms might feel slow - can be adjusted in code
2. **Large code blocks**: Cursor position may be slightly off with 500+ lines
3. **Right-to-left text**: Not tested with RTL scripts

## Success Criteria

The implementation is successful if:
- [ ] All 12 test scenarios pass (including new show code tests)
- [ ] No console errors appear
- [ ] Editing feels natural and responsive
- [ ] Users don't notice cursor jumping issues
- [ ] Code execution (Run/Check buttons) works normally
- [ ] Show code button displays plain text, immediately editable
- [ ] Delete all + retype works after show code (the reported bug fix)

---

**Testing Date**: _____________

**Tested By**: _____________

**Browser**: _____________

**Status**: ⬜ Pass / ⬜ Fail / ⬜ Needs adjustment

**Notes**:
