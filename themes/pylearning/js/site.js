// Placeholder entrypoint for pylearning theme.
// All shared scripts (prism, code-enhancements, tutorial-enhancements) and the
// Python runtime (python-runtime/console/exec) are loaded via script tags in
// the default layout and this theme's theme.yml manifest — do NOT inject them
// here as well, or every enhancer runs twice (duplicate progress markers).
(function () {
  if (typeof console !== "undefined") {
    console.debug("pylearning site.js loaded");
  }
})();
