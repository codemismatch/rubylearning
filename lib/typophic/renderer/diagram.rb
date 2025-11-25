# frozen_string_literal: true

require "fileutils"
require "digest"

module Typophic
  module Renderer
    class Diagram
      def self.mermaid(content, options = {})
        # Parse options
        caption = options["caption"] || ""
        css_class = options["class"] || "mermaid-diagram"
        
        # Generate a unique ID for the diagram
        diagram_id = "mermaid-#{Digest::MD5.hexdigest(content)[0..7]}"
        
        # Build the HTML
        html = []
        html << %(<div class="diagram-container #{css_class}">)
        html << %(<div class="mermaid" id="#{diagram_id}">)
        html << content.strip
        html << %(</div>)
        if !caption.empty?
          html << %(<p class="diagram-caption">#{caption}</p>)
        end
        html << %(</div>)
        
        html.join("\n")
      end

      def self.ditaa(content, options = {})
        output_path = options["output"]
        
        unless output_path
          return %(<div class="error">Ditaa block missing 'output' option. Example: #> ditaa: output=media/images/diagram.png</div>)
        end
        
        # Ensure output directory exists
        full_output_path = File.join("public", output_path)
        FileUtils.mkdir_p(File.dirname(full_output_path))
        
        # Create temp file for ditaa input
        temp_input = File.join(Dir.tmpdir, "ditaa_input_#{Process.pid}.txt")
        File.write(temp_input, content)
        
        # Run ditaa command
        ditaa_cmd = "ditaa"
        if system("which #{ditaa_cmd} > /dev/null 2>&1")
          system("#{ditaa_cmd} #{temp_input} #{full_output_path} -E -S 2>&1")
          
          # Clean up temp file
          File.delete(temp_input) if File.exist?(temp_input)
          
          # Return image tag
          caption = options["caption"] || ""
          css_class = options["class"] || "ditaa-diagram"
          
          html = []
          html << %(<div class="diagram-container #{css_class}">)
          html << %(<img src="/#{output_path}" alt="#{caption}" />)
          if !caption.empty?
            html << %(<p class="diagram-caption">#{caption}</p>)
          end
          html << %(</div>)
          
          html.join("\n")
        else
          File.delete(temp_input) if File.exist?(temp_input)
          %(<div class="error">Ditaa command not found. Please install ditaa to generate diagrams.</div>)
        end
      rescue => e
        File.delete(temp_input) if defined?(temp_input) && File.exist?(temp_input)
        %(<div class="error">Error generating ditaa diagram: #{e.message}</div>)
      end

      private

      def self.parse_options(options_string)
        options = {}
        return options if options_string.nil? || options_string.empty?
        
        # Split by spaces but respect quotes
        tokens = options_string.scan(/(\w+)=(?:"([^"]*)"|(\S+))/)
        
        tokens.each do |key, quoted_val, unquoted_val|
          options[key] = quoted_val || unquoted_val
        end
        
        options
      end
    end
  end
end
