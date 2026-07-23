source "https://rubygems.org"

gemspec

# webrick is needed for the server functionality (not included by default in newer Ruby versions)
gem "webrick"
gem "base64"  # Required by Liquid in Ruby 3.4.0+

group :development do
  gem "rake"
  gem "rubocop", require: false
end

# Minification and optimization
gem "htmlcompressor"
gem "terser"
gem "autoprefixer-rails"

gem "sass-embedded", "~> 1.94"
# gem "protocss", path: "./protocss"  # Temporarily disabled - missing gemspec
