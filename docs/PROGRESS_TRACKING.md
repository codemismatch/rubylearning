# Progress Tracking System Documentation

## Overview

The progress tracking system monitors user engagement with tutorial chapters by tracking scroll position, practice checklist completion, and sample code execution. Progress is stored in browser localStorage and displayed as visual indicators on the chapter list.

## Changes Made

### Date: November 27, 2025

#### 1. Enhanced Scroll Tracking
**File**: `themes/rubylearning/js/tutorial-enhancements.js`

**Before**: Binary tracking - only marked as "read" when user scrolled past 70% of content.

**After**: Continuous scroll percentage tracking (0-100%) that updates in real-time as the user scrolls.

**Changes**:
- Replaced `trackLessonReading()` function to track continuous scroll percentage
- Stores scroll percentage in `rl:chapter:{path}:scroll-percent` (0-100)
- Throttled updates to localStorage (every 100ms) to avoid excessive writes
- Removed binary `lesson-read` flag in favor of continuous percentage

#### 2. Added Sample Code Execution Tracking
**File**: `themes/rubylearning/js/tutorial-enhancements.js`

**Before**: Only tracked practice checklist items.

**After**: Now tracks both practice items AND sample code execution.

**Changes**:
- Reads `rl:chapter:{path}:example:{index}` keys to count executed examples
- Reads `rl:chapter:{path}:examples_total` to get total example count
- Includes example completion in progress calculation

#### 3. Updated Progress Calculation Formula
**File**: `themes/rubylearning/js/tutorial-enhancements.js` (function: `initChapterListProgress()`)

**New Formula**:

**If chapter has BOTH practice items AND sample code:**
- 40% for scroll percentage (0-100% of content scrolled)
- 30% for practice items completion
- 30% for sample code execution

**If chapter has only practice items:**
- 50% for scroll percentage
- 50% for practice items

**If chapter has only sample code:**
- 50% for scroll percentage
- 50% for sample code

**If chapter has neither:**
- 100% based on scroll percentage only

**Minimum Progress**: If a chapter is visited but has 0% progress, it shows 10% (indicates page was opened).

## localStorage Keys

### Per Chapter Keys

All keys use the format: `rl:chapter:{path}` where `{path}` is the chapter URL path (e.g., `/tutorials/quick-intro`).

| Key | Type | Description |
|-----|------|-------------|
| `rl:chapter:{path}:visited` | Boolean (`'1'` or not set) | Set when chapter page loads |
| `rl:chapter:{path}:scroll-percent` | Number (0-100) | Continuous scroll percentage |
| `rl:chapter:{path}:total` | Number | Total count of practice checklist items |
| `rl:chapter:{path}:item:{index}` | Boolean (`'1'` or `'0'`) | Individual practice item completion (indexed from 0) |
| `rl:chapter:{path}:complete` | Boolean (`'1'` or `'0'`) | Set when all practice items are completed |
| `rl:chapter:{path}:examples_total` | Number | Total count of runnable code examples |
| `rl:chapter:{path}:example:{index}` | Boolean (`'1'` or not set) | Individual example execution (indexed from 0) |

### Legacy Keys (No Longer Used)

- `rl:chapter:{path}:lesson-read` - Replaced by `scroll-percent`

## Visual Indicators

Progress is displayed as circular markers next to chapter links in the learning path:

- **Green circle with checkmark** (`is-complete`): 100% progress
- **Red/primary color wedge** (`is-partial`): 1-99% progress (shows percentage via conic-gradient)
- **Gray circle with border** (`is-pending`): 0% progress (not started)

The wedge angle represents the completion percentage using CSS `conic-gradient`.

## Code Locations

### Main Implementation
- **File**: `themes/rubylearning/js/tutorial-enhancements.js`
- **Functions**:
  - `trackLessonReading()` - Tracks scroll percentage continuously
  - `initChapterListProgress()` - Calculates and displays progress on chapter list
  - `initPracticeChecklists()` - Tracks practice item completion
  - `updateChapterCompletion()` - Updates completion status when practice items change

### Sample Code Tracking
- **File**: `themes/rubylearning/js/modules/ruby-exec.js`
- **Lines**: ~558-566
- Marks examples as executed when "Run" button is clicked
- Stores in: `rl:chapter:{path}:example:{index}`

### CSS Styling
- **File**: `themes/rubylearning/css/tutorials.css`
- **Lines**: ~161-195
- Styles for `.chapter-progress-marker` with conic-gradient for partial progress

## Example Calculation

For a chapter at `/tutorials/quick-intro` with:
- Scroll: 60% scrolled
- Practice items: 3 total, 2 completed
- Sample code: 5 total, 4 executed

**Calculation**:
```
Scroll contribution: (60 / 100) * 40 = 24%
Practice contribution: (2 / 3) * 30 = 20%
Examples contribution: (4 / 5) * 30 = 24%
Total: 24 + 20 + 24 = 68%
```

Result: Red wedge showing 68% completion.

## Testing

To test the progress tracking:

1. **Scroll Tracking**: Open a chapter and scroll through it. Check localStorage for `scroll-percent` value.
2. **Practice Items**: Check/uncheck practice checklist items. Verify progress updates.
3. **Sample Code**: Run code examples. Verify they're tracked in localStorage.
4. **Visual Display**: Check the chapter list page to see progress indicators update.

## Browser Compatibility

- Uses `localStorage` API (available in all modern browsers)
- Uses `window.scrollY` and `document.documentElement.scrollTop` for scroll tracking
- Uses CSS `conic-gradient` for progress visualization (supported in modern browsers)

## Future Enhancements

Potential improvements:
- Add time-based tracking (time spent on chapter)
- Add quiz/assessment completion tracking
- Add progress export/import functionality
- Add progress analytics dashboard
- Add progress reset functionality
