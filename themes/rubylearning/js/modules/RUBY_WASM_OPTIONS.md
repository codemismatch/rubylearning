# Ruby WASM Size Options

## Current Setup

Currently using: `@ruby/3.4-wasm-wasi@2.7.2` with `ruby.wasm` (minimal build)
- **Size**: ~2-3MB (compressed) / ~8-10MB (uncompressed)
- **Includes**: Ruby core only, no stdlib
- **Status**: ✅ Optimized - StringIO dependency removed via monkey patching

## Available Builds

### 1. `ruby.wasm` (Current - Minimal) ✅
- **Size**: ~2-3MB compressed
- **Includes**: Ruby core only, NO stdlib
- **URL**: `https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.2/dist/ruby.wasm`
- **Status**: ✅ Using - StringIO replaced with string-based output capture

### 2. `ruby+stdlib.wasm` (Full - Not Needed)
- **Size**: ~15-20MB compressed
- **Includes**: Complete Ruby stdlib
- **URL**: `https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.2/dist/ruby+stdlib.wasm`
- **Status**: ❌ Not needed - StringIO implemented via monkey patching

## What Our Code Needs

From `ruby-exec.js` and `ruby-console.js`:

**Required:**
- `js` - Ruby-WASM JS bridge (built-in to wasm-wasi package)
- String output capture - Implemented via monkey patching Kernel methods

**Optional:**
- `test/unit/assertions` - Only for practice/test blocks (wrapped in rescue LoadError)

## Implementation Details

Instead of using `StringIO`, we:
1. Use a simple string buffer: `$__exec_output__ = +""`
2. Monkey patch `Kernel#puts`, `Kernel#print`, `Kernel#p` to append to the string
3. For console, create a simple IO-like object that captures to string

## Size Comparison

| Build | Compressed | Uncompressed | Status |
|-------|-----------|--------------|--------|
| `ruby.wasm` | ~2-3MB | ~8-10MB | ✅ Using (optimized) |
| `ruby+stdlib.wasm` | ~15-20MB | ~50-60MB | ❌ Not needed |

## Optimization Options

### Option 1: Lazy Load (Current Implementation)
✅ **Already implemented** - Only loads when runnable code is present
- Pages without runnable code: 0MB Ruby WASM
- Pages with runnable code: ~15-20MB Ruby WASM

### Option 2: Use Older Ruby Version
- `@ruby/3.2-wasm-wasi` might be slightly smaller
- Trade-off: Missing newer Ruby features

### Option 3: Stream/Compress Loading
- Use `WebAssembly.compileStreaming` (already using ✅)
- Enable gzip/brotli compression on server (CDN handles this ✅)

### Option 4: Custom Build (Advanced)
- Build custom Ruby WASM with only needed stdlib modules
- Would require custom build pipeline
- Trade-off: Maintenance complexity

### Option 5: Code Splitting by Feature
- Load `ruby.wasm` first (~2-3MB)
- Load stdlib modules on-demand (if possible)
- **Challenge**: StringIO is needed immediately

## Recommendation

**Keep current setup** (`ruby+stdlib.wasm`) because:

1. ✅ **Already optimized**: Only loads when needed (conditional loading)
2. ✅ **Required features**: Need StringIO which requires stdlib
3. ✅ **CDN caching**: jsDelivr CDN caches aggressively
4. ✅ **Streaming**: Already using compileStreaming for faster parse
5. ✅ **User experience**: Load happens in background, doesn't block UI

## Performance Notes

- **First load**: ~15-20MB download (cached by browser/CDN)
- **Subsequent loads**: Served from cache (near-instant)
- **Parse time**: ~1-2 seconds on modern devices
- **Memory**: ~50-60MB RAM when loaded

## Alternative: Server-Side Execution

If WASM size is a concern, consider:
- Server-side Ruby execution API
- Trade-off: Requires backend infrastructure, latency, security considerations
