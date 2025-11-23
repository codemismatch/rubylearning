# frozen_string_literal: true

require "../spec_helper"
require "file_utils"

# Define a temporary content directory for testing
TEST_CONTENT_DIR = "test_content_for_builder"
TEST_PUBLIC_DIR = "test_public_for_builder"

Spec.before_each do
  # Ensure clean state before each test
  FileUtils.rm_rf(TEST_CONTENT_DIR) if Dir.exists?(TEST_CONTENT_DIR)
  FileUtils.rm_rf(TEST_PUBLIC_DIR) if Dir.exists?(TEST_PUBLIC_DIR)
  FileUtils.rm_rf("themes") if Dir.exists?("themes")
  FileUtils.mkdir_p(File.join("themes", "rubylearning", "layouts"))
  File.write(File.join("themes", "rubylearning", "layouts", "post.html"), "<html>{{ content }}</html>")

  FileUtils.mkdir_p(TEST_CONTENT_DIR)
  FileUtils.mkdir_p(TEST_PUBLIC_DIR)
  
  # Create a dummy config.yml for tests
  File.write("config.yml", <<-YAML
    theme: rubylearning
    url: http://example.com/test
  YAML
  )
end

Spec.after_each do
  FileUtils.rm_rf(TEST_CONTENT_DIR)
  FileUtils.rm_rf(TEST_PUBLIC_DIR)
  FileUtils.rm_rf("config.yml")
  FileUtils.rm_rf("themes")
end

describe Typophic::Builder do
  it "initializes and builds a site without raising errors" do
    # Create dummy content file
    FileUtils.mkdir_p(File.join(TEST_CONTENT_DIR, "posts"))
    File.write(File.join(TEST_CONTENT_DIR, "posts", "my-post.md"), <<-MD
      ---
      title: My Test Post
      layout: post
      ---
      Hello, world!
    MD
    )

    builder = Typophic::Builder.new({
      "source_dir" => TEST_CONTENT_DIR,
      "output_dir" => TEST_PUBLIC_DIR,
      "verbose" => false.to_s # Suppress build output during tests
    })
    
    { builder.build }.should_not raise_error(Exception)
    
    # Assert that output files were created
    Dir.exists?(TEST_PUBLIC_DIR).should be_true
    File.exists?(File.join(TEST_PUBLIC_DIR, "posts", "my-post", "index.html")).should be_true
  end

  # Add more specific tests for various Builder functionalities
end