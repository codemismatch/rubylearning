/**
 * Ruby Console Drawer Module
 * Handles the toggle functionality for the Ruby console drawer
 */

function initRubyConsoleDrawer() {
  const drawer = document.querySelector('.ruby-console-drawer');
  if (!drawer) return;
  const toggle = drawer.querySelector('.ruby-console-toggle');
  if (!toggle) return;

  const icon = toggle.querySelector('.ruby-console-toggle-icon');
  const input = drawer.querySelector('.ruby-irb-input');

  const setState = (open) => {
    drawer.classList.toggle('ruby-console-drawer--open', open);
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    
    // Focus input when drawer opens
    if (open && input) {
      // Small delay to allow CSS transition to start
      setTimeout(() => {
        input.focus();
      }, 100);
    }
  };

  toggle.addEventListener('click', () => {
    const open = !drawer.classList.contains('ruby-console-drawer--open');
    setState(open);
  });
}

// Export for use in other modules
window.RubyConsoleDrawer = {
  initRubyConsoleDrawer
};
