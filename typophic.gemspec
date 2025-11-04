# frozen_string_literal: true

require_relative "lib/typophic/version"

Gem::Specification.new do |spec|
  spec.name          = "typophic"
  spec.version       = Typophic::VERSION
  spec.authors       = ["Ruby Learning"]
  spec.email         = ["maintainers@rubylearning.in"]

  spec.summary       = "Typophic static site generator"
  spec.description   = "A dogfooded static site generator powering rubylearning and other ERB-driven themes."
  spec.license       = "MIT"

  spec.homepage      = "https://github.com/codemismatch/rubylearning"

  lib_files   = Dir.glob("lib/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  theme_files = Dir.glob("themes/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.files         = lib_files + theme_files +
                      Dir.glob("bin/typophic") +
                      ["README.md", "typophic.gemspec", "config.yml"]
  spec.bindir        = "bin"
  spec.executables   = ["typophic"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 3.0")

  spec.add_runtime_dependency "psych", "~> 4.0"
  spec.add_runtime_dependency "listen", "~> 3.0"
  spec.add_runtime_dependency "ostruct", "~> 0.6.3"
  spec.add_runtime_dependency "logger", "~> 1.7.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/codemismatch/rubylearning/issues",
    "source_code_uri" => "https://github.com/codemismatch/rubylearning"
  }
end
