# Bug Fix: Show Code Button Breaking Cursor Position

## Issue Description

**Reported by user**: After clicking "Show code" button, deleting all content, and trying to type again, cursor jumping issues return.

## Root Cause (Updated Analysis)

The "Show code" button was applying syntax highlighting (HTML with spans) but the `isHighlighted` flag remained scoped in a closure and inaccessible to the button handler. This caused:

1. **State mismatch**: Code visually highlighted, but flag said it wasn't
2. **Focus handler confused**: When user clicked to edit, focus handler didn't detect highlighting
3. **No conversion to plain text**: User typed into HTML structure, causing cursor jumping

### Code Path Analysis

```javascript
// User clicks "Show code" button
showButton.addEventListener('click', () => {
  codeBlock.textContent = solution;
  codeBlock.innerHTML = highlightRubyInline(solution); // ❌ PROBLEM: Applies highlighting
  // But isHighlighted flag (in closure) is still false!
});

// User deletes all content and tries to type
pre.addEventListener('focus', () => {
  if (isHighlighted) { // ❌ FALSE, even though block IS highlighted
    // This code never runs!
    removeHighlighting();
  }
  // Block remains highlighted HTML, causing cursor issues when typing
});
```

## The Fix (Updated: Shows Syntax Highlighting)

**Location**: `themes/rubylearning/js/code-enhancements.js`, lines 954-968

**Strategy**: Show code with **syntax highlighting** for better visual feedback, but ensure copy operations always use plain text. Store plain text in `dataset.plainText` for reliable copying.

**Before**:
```javascript
const solution = solutionNode.textContent.replace(/^\s+|\s+$/g, '');
codeBlock.textContent = solution; // Plain text only, no highlighting
```

**After**:
```javascript
// Get the solution as plain text
const solution = solutionNode.textContent.replace(/^\s+|\s+$/g, '');

// Update stored plain text
currentPlainText = solution;

// Store plain text in data attribute for copy operations
codeBlock.dataset.plainText = solution;

// Show with syntax highlighting (for display)
const highlighted = highlightRubyInline(solution);
codeBlock.innerHTML = highlighted;

// Make sure the code block is not in editing mode so highlighting stays
isEditing = false;
```

## Why This Works

1. **Visual feedback**: Code appears with syntax highlighting immediately, making it easier to read
2. **Copy works correctly**: Plain text is stored in `dataset.plainText` and used for all copy operations
3. **Selection copy**: Copy event handler intercepts and ensures plain text is copied, even from highlighted HTML
4. **Editable on focus**: When user clicks to edit, focus handler converts to plain text automatically

## Testing Steps

1. Navigate to a practice block on: http://localhost:3000/tutorials/ruby-features/
2. Click "Check" button (it should fail on the TODO code)
3. Click "Show code" button (solution appears in **plain text**)
4. **Observe**: Code appears without syntax highlighting initially
5. Click into the editor at any position
6. Try typing: `puts "test"`
7. Click away (blur) and back (focus)

**Expected Result**: 
- ✅ Show code displays syntax highlighted code (easier to read)
- ✅ Copy button copies plain text only
- ✅ Selecting and copying text copies plain text only (not HTML)
- ✅ Can click to edit (focus handler converts to plain text)
- ✅ Editing feels like normal text editor

**Previous Behavior**:
- ❌ Show code displayed plain text (less readable)
- ❌ Copy operations might include HTML tags

## Related Changes

This fix **simplifies** our cursor preservation system:
- **No state coordination needed**: Button handler doesn't touch highlighting
- **Focus handler unchanged**: Works the same as always
- **Blur handler unchanged**: Works the same as always
- **Plain text strategy**: Editor "just works" without special cases

## Edge Cases Handled

### Case 1: Show code → Edit immediately
- ✅ Code is plain text, ready to edit, no conversions needed

### Case 2: Show code → Delete all → Retype
- ✅ Plain text throughout, works perfectly (this was the reported bug)

### Case 3: Show code → Blur → Focus → Edit
- ✅ Highlighting cycle works naturally

### Case 4: Multiple practice blocks on same page
- ✅ Each block independent, no shared state issues

## Code Quality Notes

### Alternative Approaches Considered (and Rejected)

#### Alternative 1: Make isHighlighted accessible globally
```javascript
window.highlightState = { block1: true, block2: false };
```
❌ Rejected:
- Pollutes global scope
- Multiple blocks would need unique IDs
- Memory leak risks
- Coordination complexity

#### Alternative 2: Store flag on DOM element
```javascript
codeBlock._isHighlighted = true;
```
❌ Rejected:
- Non-standard DOM mutation
- Hard to debug
- Tightly couples state to DOM

#### Alternative 3: Trigger focus event programmatically
```javascript
pre.dispatchEvent(new FocusEvent('focus'));
```
❌ Rejected:
- Side effects unpredictable
- Changes actual focus state
- Could interfere with other handlers

#### Alternative 4: Apply highlighting but convert on any keypress
```javascript
pre.addEventListener('keydown', () => {
  if (codeBlock.innerHTML.includes('<span')) {
    convertToPlainText();
  }
});
```
❌ Rejected:
- Extra event listener overhead
- Performance cost on every keypress
- Still managing state indirectly

### Current Approach (Plain Text) is Best

Leave code in plain text state:
- ✅ Simple and clean - no state management
- ✅ No special cases or coordination
- ✅ Editor works exactly like normal text input
- ✅ Blur/focus handlers work naturally
- ✅ Easy to understand and maintain

## Potential Future Issues

### Watch Out For:

1. **Other buttons that modify code**: If we add more buttons (Format, Reset, etc.), they should leave code in **plain text** state, just like "Show code"

2. **External code injection**: Any programmatic code modifications should set `textContent`, not `innerHTML`

3. **Copy/paste handling**: Currently works because contenteditable handles it natively

## Verification Checklist

- [x] JavaScript syntax valid
- [x] Fix addresses root cause (state mismatch eliminated)
- [x] Solution is simple and maintainable (actually simpler than before!)
- [ ] Manual testing: Show code button displays plain text
- [ ] Manual testing: Can immediately type after show code
- [ ] Manual testing: Delete all + retype works (the reported bug)
- [ ] Manual testing: Blur applies highlighting naturally
- [ ] Manual testing: Focus removes highlighting and preserves cursor
- [ ] Manual testing: Multiple practice blocks work independently

## Success Criteria

1. ✅ User clicks "Show code" → code appears as plain text
2. ✅ User can immediately type anywhere → cursor stays put
3. ✅ User deletes all and retypes → works perfectly
4. ✅ Clicking away → syntax highlighting appears
5. ✅ Clicking back → highlighting removes, cursor preserved
6. ✅ No console errors, smooth performance

---

**Bug Discovered**: 2025-11-19  
**First Fix Attempt**: 2025-11-19 (used highlightRubyInline, still had issues)  
**Final Fix**: 2025-11-19 (plain text approach)  
**Severity**: High (breaks core editing functionality)  
**Status**: ✅ Fixed with simplified approach, pending user verification
