/**
 * Shared helpers for tracking executable example progress across languages.
 * Stores counts in localStorage using the existing chapterKeyPrefix scheme.
 */

window.TypophicExamples = window.TypophicExamples || {};

window.TypophicExamples.markExampleCompleted = function (chapterKeyPrefix, exampleIndex) {
  if (chapterKeyPrefix == null || exampleIndex == null) return;
  try {
    window.localStorage.setItem(`${chapterKeyPrefix}:example:${exampleIndex}`, '1');
  } catch (_) { }
};

window.TypophicExamples.setExamplesTotal = function (chapterKeyPrefix, total) {
  if (chapterKeyPrefix == null || total == null) return;
  try {
    window.localStorage.setItem(`${chapterKeyPrefix}:examples_total`, String(total));
  } catch (_) { }
};

