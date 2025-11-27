/**
 * Ruby WASM Loader Module
 * Handles loading and initialization of Ruby WASM module
 */

async function setupRubyWasm() {
  // Check if Ruby WASM is already loaded
  if (window.rubyWasmLoaded === true) {
    return window.rubyWasmModule;
  }
  
  // Mark as loading to prevent multiple simultaneous loads
  if (window.rubyWasmLoaded === 'loading') {
    // Wait for the existing load to complete
    let retries = 0;
    while (window.rubyWasmLoaded === 'loading' && retries < 50) {
      await new Promise(resolve => setTimeout(resolve, 100));
      retries++;
    }
    if (window.rubyWasmLoaded === true) {
      return window.rubyWasmModule;
    }
  }
  
  window.rubyWasmLoaded = 'loading';
  
  try {
    // Use dynamic import with full URL string literal
    // The +esm suffix tells jsdelivr to serve ES module format
    const wasmModule = await import('https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.2/dist/browser/+esm');
    window.rubyWasmLoaded = true;
    window.rubyWasmModule = wasmModule;
    return wasmModule;
  } catch (error) {
    window.rubyWasmLoaded = false;
    console.error('Failed to load Ruby WASM module:', error);
    throw error;
  }
}

async function initializeRubyVM() {
  try {
    const wasmModule = await setupRubyWasm();
    const { DefaultRubyVM } = wasmModule;
    
    const response = await fetch('https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.2/dist/ruby.wasm');
    const module = await WebAssembly.compileStreaming(response);
    const instance = await DefaultRubyVM(module);
    const vm = instance.vm;
    
    console.log('Ruby VM initialized successfully');
    
    // Expose the VM globally so other helpers can reuse it
    window.TypophicRubyVM = vm;
    
    return vm;
  } catch (error) {
    console.error('Failed to initialize Ruby VM:', error);
    throw error;
  }
}

// Export for use in other modules
window.RubyWasmLoader = {
  setupRubyWasm,
  initializeRubyVM
};
