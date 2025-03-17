#!/usr/bin/env ruby

# Script to check the project structure and fix common issues
# Usage: ruby tools/check-structure.rb

puts "=== Checking Ruby Learning project structure ==="

# Check public directory
if Dir.exist?('public')
  puts "✓ Public directory exists"
else
  puts "✗ Public directory not found - have you built the site yet?"
  puts "  Run bin/typophic-build to generate the site"
end

# Check for tutorials.html issue
if Dir.exist?('public/tutorials.html')
  puts "! Found 'tutorials.html' as a directory instead of a file"
  puts "  This is a known issue - fixing..."
  
  if File.exist?('public/tutorials.html/index.html')
    # Create a 'tutorials' directory if not exists
    Dir.mkdir('public/tutorials') unless Dir.exist?('public/tutorials')
    
    # Move the index.html file
    require 'fileutils'
    FileUtils.cp('public/tutorials.html/index.html', 'public/tutorials/index.html')
    
    # Create a redirect file
    File.write('public/tutorials.html', <<~HTML)
      <!DOCTYPE html>
      <html>
      <head>
        <meta http-equiv="refresh" content="0;url=/tutorials/">
        <title>Redirecting...</title>
      </head>
      <body>
        <p>Redirecting to <a href="/tutorials/">tutorials</a>...</p>
      </body>
      </html>
    HTML
    
    puts "✓ Fixed tutorials.html issue"
  else
    puts "! Unable to fix tutorials.html issue - index.html not found"
  end
end

# Check for unprocessed template variables in HTML files
puts "Checking for unprocessed template variables..."
unprocessed_files = []

Dir.glob("public/**/*.html").each do |file|
  next if File.directory?(file)
  
  content = File.read(file)
  if content.include?('<%=') || content.include?('<%')
    unprocessed_files << file
  end
end

if unprocessed_files.empty?
  puts "✓ No unprocessed template variables found"
else
  puts "! Found #{unprocessed_files.size} files with unprocessed template variables"
  unprocessed_files.each do |file|
    puts "  - #{file}"
  end
  puts "  Run ruby tools/fix-paths.rb after building to fix these issues"
end

# Check for existence of critical files
critical_files = [
  'public/index.html',
  'public/css/style.css',
  'public/js/prism.js'
]

critical_files.each do |file|
  if File.exist?(file)
    puts "✓ Found #{file}"
  else
    puts "✗ Missing #{file} - site may not display correctly"
  end
end

puts "=== Structure check complete ==="
