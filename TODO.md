# Tutorial Chapter Review Checklist

1. classes-and-objects.md
2. duck-typing.md
3. files-gems-next-steps.md
4. first-ruby-program.md
5. flow-control-collections.md
6. fun-with-strings.md
7. getting-input.md
8. including-other-files.md
9. installation-setup.md
10. meet-ruby.md
11. methods-and-blocks.md
12. modules-and-mixins.md
13. more-on-ruby-methods.md
14. more-on-strings.md
15. mutable-and-immutable-objects.md
16. numbers-in-ruby.md
17. object-serialization.md
18. quick-intro-to-ruby.md
19. rails-hotwire-feedback.md
20. rails-project-setup.md
21. rails-routes-controllers.md
22. read-write-files.md
23. ruby-access-control.md
24. ruby-arrays.md
25. ruby-blocks.md
26. ruby-constants.md
27. ruby-exceptions.md
28. ruby-features.md
29. ruby-hashes.md
30. ruby-inheritance.md
31. ruby-logging.md
32. ruby-method-missing.md
33. ruby-names.md
34. ruby-open-classes.md
35. ruby-overloading-methods.md
36. ruby-overriding-methods.md
37. ruby-procs.md
38. ruby-random-numbers.md
39. ruby-ranges.md
40. ruby-regular-expressions.md
41. ruby-ri-tool.md
42. ruby-self.md
43. ruby-socket-programming.md
44. ruby-symbols.md
45. ruby-syntactic-sugar.md
46. ruby-time-class.md
47. scope.md
48. simple-constructs.md
49. variables-and-assignment.md
50. writing-our-own-class.md
51. writing-own-ruby-methods.md

## Theme importer follow-ups

- [x] Extend `typophic theme import` to handle archives/Git sources, richer rewrites (filters/tags, asset URL adjustments), and friendlier reports.
- [ ] Mirror the Ruby theme import workflow in the Crystal CLI (`crystal/src/typophic/commands/theme.cr`).
- [x] Assess themes/ to pick the best candidate for Typophic augmentation vs pulling a fresh theme from GitHub.
- [x] Converted via ThemeImporter: `hydejack-typophic`, `minimal-mistakes-typophic` (new copies under themes/).
- [x] Add compatibility passes for lightweight themes (`hugo-serif-typophic`, `hugo-serif-typophic-v2`, `mria`, `bonsaiblog`) to align with rubylearning layout and validate with debug logs during build.
- [ ] Resolve remaining Sass compilation errors (seen during build: “expected '{'” in theme assets).
