# frozen_string_literal: true

require "../spec_helper"



# Helper to access private methods for testing pipeline
class PipelineTester < Typophic::Builder
  def initialize
    super({
      "source_dir" => "test_content",
      "output_dir" => "test_public",
      "verbose" => "false"
    })
  end

    def test_pipeline_markdown(content)
      pipeline_markdown(content, Hash(String, YAML::Any).new)
    end

    def test_full_pipeline(content)
      run_content_pipeline(Hash(String, YAML::Any).new, content)
    end
  end

  def tester
    PipelineTester.new
  end

describe Typophic::Builder do
  # Setup test environment
  Spec.before_each do
    FileUtils.rm_rf("themes") if Dir.exists?("themes")
    FileUtils.mkdir_p(File.join("themes", "rubylearning", "layouts"))
    File.write("config.yml", "theme: rubylearning")
  end

  Spec.after_each do
    FileUtils.rm_rf("themes")
    FileUtils.rm_rf("config.yml")
    FileUtils.rm_rf("test_content")
    FileUtils.rm_rf("test_public")
  end



  describe "#pipeline_markdown" do

    it "renders headings correctly" do
      input = <<-MD
      # Heading 1
      ## Heading 2
      ### Heading 3
      MD
      
      output = tester.test_pipeline_markdown(input)
      output.should contain("<h1>Heading 1</h1>")
      output.should contain("<h2>Heading 2</h2>")
      output.should contain("<h3>Heading 3</h3>")
    end

    it "renders headings with custom slugs" do
      input = "# My Heading {#custom-id}"
      output = tester.test_pipeline_markdown(input)
      output.should contain("<h1 id=\"custom-id\">My Heading</h1>")
    end

    it "renders paragraphs" do
      input = <<-MD
      Para 1
      
      Para 2
      MD
      
      output = tester.test_pipeline_markdown(input)
      output.should contain("<p>Para 1</p>")
      output.should contain("<p>Para 2</p>")
    end

    it "renders bold text" do
      input = "This is **bold** text"
      output = tester.test_pipeline_markdown(input)
      output.should contain("This is <strong>bold</strong> text")
    end

    it "renders inline code" do
      input = "This is `code` text"
      output = tester.test_pipeline_markdown(input)
      output.should contain("This is <code>code</code> text")
    end

    it "renders links" do
      input = "[Link Text](http://example.com)"
      output = tester.test_pipeline_markdown(input)
      output.should contain("<a href=\"http://example.com\">Link Text</a>")
    end

    it "renders unordered lists" do
      input = <<-MD
      - Item 1
      - Item 2
      MD
      
      output = tester.test_pipeline_markdown(input)
      output = tester.test_pipeline_markdown(input)
      # Allow newlines in output
      output.should match(/<ul>\s*<li>Item 1<\/li>\s*<li>Item 2<\/li>\s*<\/ul>/m)
    end

    it "renders fenced code blocks" do
      input = <<-MD
      ```ruby
      def hello
        puts "world"
      end
      ```
      MD
      
      output = tester.test_pipeline_markdown(input)
      output.should contain("<div class=\"code-window\">")
      output.should contain("<span class=\"window-title\">ruby.rb</span>")
      output.should contain("class=\"language-ruby\"")
      output.should contain("def hello")
    end

    it "renders fenced code blocks without language" do
      input = <<-MD
      ```
      plain text
      ```
      MD
      
      output = tester.test_pipeline_markdown(input)
      output.should contain("<div class=\"code-window\">")
      output.should contain("<span class=\"window-title\">code</span>")
      output.should contain("plain text")
    end

    it "protects pre blocks from markdown processing" do
      input = <<-MD
      <pre>
      # Not a heading
      **Not bold**
      </pre>
      MD
      
      output = tester.test_pipeline_markdown(input)
      output.should contain("# Not a heading")
      output.should contain("**Not bold**")
      output.should_not contain("<h1>")
      output.should_not contain("<strong>")
    end

    it "handles nested formatting correctly" do
      input = "**Bold with `code` inside**"
      output = tester.test_pipeline_markdown(input)
      output.should contain("<strong>Bold with <code>code</code> inside</strong>")
    end
    
    it "handles complex list items" do
       input = <<-MD
       - Item with **bold**
       - Item with `code`
       MD
       
       output = tester.test_pipeline_markdown(input)
       output.should contain("<li>Item with <strong>bold</strong></li>")
       output.should contain("<li>Item with <code>code</code></li>")
    end

    it "does not merge practice code and run code" do
      input = <<-MD
      #> ruby :practice
      # Practice code
      ```solution
      # Solution
      ```
      ```test
      # Test
      ```
      #!
      #> ruby :run
      puts "Run code"
      #!
      
      ```ruby-exec
      puts "Exec code"
      ```
      MD
      
      # We need to run the full pipeline to test interaction between practice and hash blocks
      output = tester.test_full_pipeline(input)
      
      # Check that we have a practice block
      output.should contain("data-practice-chapter")
      
      # Check that we have a run block (code window with ruby-exec)
      # The run block should NOT be inside the practice block
      # And the practice block should NOT consume the run block
      
      # If they are merged, the run code "puts \"Run code\"" might be missing or inside the practice block
      # Note: code content is HTML escaped, so we search for the content string
      output.should contain("Run code")
      output.should contain("Exec code")
      
      # Verify they are separate entities
      # This is a bit hard to regex exactly without parsing HTML, but we can check order and presence
      output.should match(/data-practice-chapter.*Run code/m)
      output.should match(/Run code.*Exec code/m)
    end
  end
end
