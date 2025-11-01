#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'erb'

class HugoToTypophicConverter
  def initialize(hugo_theme_path, typophic_theme_name)
    @hugo_theme_path = hugo_theme_path
    @typophic_theme_name = typophic_theme_name
    @typophic_theme_path = File.join(File.dirname(hugo_theme_path), typophic_theme_name)
  end

  def convert
    puts "Converting Hugo theme '#{@hugo_theme_path}' to Typophic theme '#{@typophic_theme_name}'..."
    
    # Create Typophic theme structure
    create_typophic_structure
    
    # Convert layout files
    convert_layouts
    
    # Convert partial files
    convert_partials
    
    # Copy assets
    copy_assets
    
    # Convert data files
    convert_data_files
    
    puts "Conversion complete! New Typophic theme created at: #{@typophic_theme_path}"
  end

  private

  def create_typophic_structure
    %w[layouts includes css js images].each do |dir|
      path = File.join(@typophic_theme_path, dir)
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      puts "Created directory: #{path}"
    end
  end

  def convert_layouts
    hugo_layouts_path = File.join(@hugo_theme_path, 'layouts')
    return unless Dir.exist?(hugo_layouts_path)
    
    # Process all layout files
    Dir.glob(File.join(hugo_layouts_path, '**', '*.html')).each do |hugo_file|
      relative_path = hugo_file.sub("#{hugo_layouts_path}/", "")
      
      # Skip non-HTML files if any
      next unless hugo_file.end_with?('.html')
      
      # Convert Hugo template syntax to Typophic ERB syntax
      content = File.read(hugo_file)
      next if content.nil?  # Skip if content is nil
      
      converted_content = convert_hugo_syntax_to_erb(content)
      # Apply post-processing to fix any conversion issues
      converted_content = post_process_content(converted_content)
      
      # Determine Typophic layout path
      typophic_path = determine_typophic_path(relative_path)
      
      # Ensure directory exists
      FileUtils.mkdir_p(File.dirname(typophic_path))
      
      # Write converted file
      File.write(typophic_path, converted_content)
      puts "Converted layout: #{relative_path} -> #{typophic_path}"
    end
  end

  def determine_typophic_path(relative_path)
    case relative_path
    when %r{_default/single\.html}
      File.join(@typophic_theme_path, 'layouts', 'page.html')
    when %r{_default/list\.html}
      File.join(@typophic_theme_path, 'layouts', 'list.html')
    when 'index.html'
      File.join(@typophic_theme_path, 'layouts', 'home.html')
    when %r{partials/}
      # Partials go to includes
      include_path = relative_path.sub('partials/', '').sub(%r{^/}, '')
      File.join(@typophic_theme_path, 'includes', "_#{include_path}")
    when %r{page/}, %r{services/}, %r{team/}
      # These are typically page templates, convert to regular layouts
      File.join(@typophic_theme_path, 'layouts', relative_path)
    else
      File.join(@typophic_theme_path, 'layouts', relative_path)
    end
  end

  def convert_partials
    # Partials are already handled in convert_layouts, but let's ensure all partials are processed
    hugo_partials_path = File.join(@hugo_theme_path, 'layouts', 'partials')
    return unless Dir.exist?(hugo_partials_path)
    
    Dir.glob(File.join(hugo_partials_path, '**', '*.html')).each do |partial_file|
      relative_path = partial_file.sub("#{hugo_partials_path}/", "")
      content = File.read(partial_file)
      next if content.nil?  # Skip if content is nil
      
      converted_content = convert_hugo_syntax_to_erb(content)
      # Apply post-processing to fix any conversion issues
      converted_content = post_process_content(converted_content)
      
      # Partials go to includes with underscore prefix
      typophic_path = File.join(@typophic_theme_path, 'includes', "_#{relative_path}")
      FileUtils.mkdir_p(File.dirname(typophic_path))
      
      File.write(typophic_path, converted_content)
      puts "Converted partial: #{relative_path} -> #{typophic_path}"
    end
  end

  def copy_assets
    %w[css js images].each do |asset_dir|
      source_dir = File.join(@hugo_theme_path, asset_dir)
      dest_dir = File.join(@typophic_theme_path, asset_dir)
      
      if Dir.exist?(source_dir)
        FileUtils.cp_r(source_dir, dest_dir)
        puts "Copied assets: #{asset_dir}"
      end
    end
  end

  def convert_data_files
    hugo_data_path = File.join(@hugo_theme_path, 'data')
    typophic_data_path = File.join(@typophic_theme_path, 'data')
    
    if Dir.exist?(hugo_data_path)
      FileUtils.cp_r(hugo_data_path, typophic_data_path)
      puts "Copied data files: #{hugo_data_path} -> #{typophic_data_path}"
    end
  end

  def convert_hugo_syntax_to_erb(content)
    return "" if content.nil? # Return empty string if content is nil
    
    result = content.dup
    
    # First pass: Convert template definitions (Hugo layouts often use define/end)
    result = convert_template_definitions(result)
    
    # Convert Hugo variable references to ERB
    
    # Handle .Site.Params.* - this is the most problematic pattern causing sitepage issues
    result.gsub!(/\{\{\s*\.Site\.Params\.([a-zA-Z0-9_]+)\s*\}\}/) do |match|
      param_name = Regexp.last_match(1)
      "<%= site['#{param_name}'] %>"
    end
    
    # Handle .Site.Params with more complex nested access
    result.gsub!(/\{\{\s*\.Site\.Params\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\s*\}\}/) do |match|
      param_name = Regexp.last_match(1)
      subparam_name = Regexp.last_match(2)
      "<%= site['#{param_name}'] && site['#{param_name}']['#{subparam_name}'] %>"
    end
    
    # Handle .Site.* - site-level variables
    result.gsub!(/\{\{\s*\.Site\.([a-zA-Z0-9_]+)\s*\}\}/) do |match|
      var_name = Regexp.last_match(1)
      "<%= site['#{var_name}'] %>"
    end
    
    # Handle .Param (for page params) - Hugo's .Param function
    result.gsub!(/\{\{\s*\.Param\s+["']([^"']+)["']\s*\}\}/) do |match|
      param_name = Regexp.last_match(1)
      "<%= page['#{param_name}'] %>"
    end
    
    # Handle .Params.* - page parameters
    result.gsub!(/\{\{\s*\.Params\.([a-zA-Z0-9_]+)\s*\}\}/) do |match|
      param_name = Regexp.last_match(1)
      "<%= page['#{param_name}'] %>"
    end
    
    # Handle common page variables
    result.gsub!(/\{\{\s*\.Title\s*\}\}/, '<%= page["title"] %>')
    result.gsub!(/\{\{\s*\.Content\s*\}\}/, '<%= content %>')
    result.gsub!(/\{\{\s*\.Description\s*\}\}/, '<%= page["description"] || site["description"] %>')
    result.gsub!(/\{\{\s*\.Date\s*\}\}/, '<%= page["date"] %>')
    result.gsub!(/\{\{\s*\.Permalink\s*\}\}/, '<%= page["url"] %>')
    result.gsub!(/\{\{\s*\.RelPermalink\s*\}\}/, '<%= url_for(page["permalink"]) %>')
    result.gsub!(/\{\{\s*\.URL\s*\}\}/, '<%= page["url"] %>')
    result.gsub!(/\{\{\s*\.IsHome\s*\}\}/, '<%= page["section"] == "home" || page["slug"] == "index" %>')
    
    # Handle .Site.Home.RelPermalink -> url for home page
    result.gsub!(/\{\{\s*\.Site\.Home\.RelPermalink\s*\}\}/, '<%= url_for("/") %>')
    
    # Handle URL functions with path handling
    result.gsub!(/\{\{\s*([a-zA-Z0-9_]+)\s*\|\s*relURL\s*\}\}/, '<%= asset_path(\1) %>')
    result.gsub!(/\{\{\s*["']([^"']+)["']\s*\|\s*relURL\s*\}\}/, '<%= asset_path("\1") %>')
    result.gsub!(/\{\{\s*([a-zA-Z0-9_]+)\s*\|\s*absURL\s*\}\}/, '<%= absolute_url(\1) %>')
    result.gsub!(/\{\{\s*["']([^"']+)["']\s*\|\s*absURL\s*\}\}/, '<%= absolute_url("\1") %>')
    
    # Handle range functions with simple collections
    result = convert_range_syntax(result)
    
    # Handle conditionals (if statements)
    result = convert_conditional_syntax(result)
    
    # Handle partial calls
    result.gsub!(/\{\{\s*partial\s+["']([^"']+)["']\s*\}\}/, '<%= render_partial("\1") %>')
    # Handle partials with context (dict function in Hugo) - simplified
    result.gsub!(/\{\{\s*partial\s+["']([^"']+)["']\s+(.+?)\s*\}\}/) do |match|
      partial_name = Regexp.last_match(1)
      context = Regexp.last_match(2)
      # For now, we'll render without context and add a comment to indicate manual review is needed
      "<%= render_partial('#{partial_name}') %> <%# REVIEW: Context #{context} needs manual conversion %>"
    end
    
    # Handle template functions that are Hugo-specific
    result.gsub!(/\{\{\s*\.Site\.Data\.([a-zA-Z0-9_]+)\s*\}\}/, '<%= site[:data] && site[:data]["\1"] %>')
    result.gsub!(/\{\{\s*\.Site\.Data\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\s*\}\}/, '<%= site[:data] && site[:data]["\1"] && site[:data]["\1"]["\2"] %>')
    
    # Handle . - represents current context (usually page) 
    result.gsub!(/\{\{\s*\.\s*\}\}/, '<%= page %>')
    
    # More general . variable handling
    result.gsub!(/\{\{\s*\.\s*([a-zA-Z0-9_]+)\s*\}\}/, '<%= page["\1"] %>')
    
    # Handle Hugo functions (like trim, lower, upper, etc.)
    result.gsub!(/\{\{\s*trim\s+["']([^"']*)["']\s+["']([^"']*)["']\s*\}\}/, '<%= "\1".gsub("\2", "") %>')
    result.gsub!(/\{\{\s*lower\s+(.+?)\s*\}\}/, '<%= \1.to_s.downcase %>')
    result.gsub!(/\{\{\s*upper\s+(.+?)\s*\}\}/, '<%= \1.to_s.upcase %>')
    result.gsub!(/\{\{\s*len\s+(.+?)\s*\}\}/, '<%= \1.length %>')
    result.gsub!(/\{\{\s*replace\s+(.+?)\s+["']([^"']*)["']\s+["']([^"']*)["']\s*\}\}/, '<%= \1.to_s.gsub("\2", "\3") %>')
    
    # Handle where functions (simplified - these require careful review)
    result.gsub!(/\{\{\s*where\s+(.+?)\s+["']([^"']*)["']\s+["']([^"']*)["']\s*\}\}/) do |match|
      collection = Regexp.last_match(1)
      field = Regexp.last_match(2)
      value = Regexp.last_match(3)
      "<% # WARNING: Hugo where function #{collection} #{field} #{value} - requires manual implementation %>"
    end
    
    # Handle .Render calls
    result.gsub!(/\{\{\s*\.Render\s+["']([^"']+)["']\s*\}\}/, '<%= render_partial("\1") %> <%# Manual review needed %>')

    result
  end

  def convert_template_definitions(content)
    return "" if content.nil? # Return empty string if content is nil
    
    result = content.dup
    
    # Handle Hugo's define/end template pattern - replace with comments since Typophic doesn't use this
    result.gsub!(/{{\s*define\s+["']([^"']+)["']\s*}}((?:.|\n)*?){{\s*end\s*}}/) do |match|
      template_name = Regexp.last_match(1)
      template_body = Regexp.last_match(2) || ""
      
      # Hugo defines are like partials in Typophic
      # For Typophic, we'll add as a comment since main templates don't use this pattern
      "\n<%# Hugo template definition: #{template_name} - #{template_body.strip} %>\n"
    end
    
    # Handle template blocks specifically
    result.gsub!(/{{\s*block\s+["']([^"']+)["']\s*}}((?:.|\n)*?){{\s*end\s*}}/) do |match|
      block_name = Regexp.last_match(1)
      block_body = Regexp.last_match(2) || ""
      # In Typophic, blocks are handled differently or content is passed directly
      block_body
    end
    
    # Handle template use
    result.gsub!(/{{\s*template\s+["']([^"']+)["']\s*}}/) do |match|
      template_name = Regexp.last_match(1)
      # This would be a partial in Typophic
      "<%= render_partial('#{template_name.sub(/^partials\//, '')}') %>"
    end
    
    result
  end

  def convert_range_syntax(content)
    return content if content.nil? # Return original content if nil
    
    result = content.dup
    
    # Handle simple range over data collections
    result.gsub!(/\{\{\s*range\s+(?:\$[a-zA-Z0-9_]*\s*:)?\s*\.Site\.Data\.([a-zA-Z0-9_]+)\s*\}\}((?:.|\n)*?)\{\{\s*end\s*\}\}/) do |match|
      collection = "site[:data] && site[:data]['#{Regexp.last_match(1)}'] || []"
      inner_content = Regexp.last_match(2) || ""
      
      # Replace . references inside the range with the iteration variable (default 'item')
      inner_converted = convert_range_content(inner_content, 'item')
      
      "<% #{collection}.each do |item| %>\n#{inner_converted}<% end %>"
    end
    
    # Handle range over site pages
    result.gsub!(/\{\{\s*range\s+(?:\$[a-zA-Z0-9_]*\s*:)?\s*\.Site\.RegularPages\s*\}\}((?:.|\n)*?)\{\{\s*end\s*\}\}/) do |match|
      collection = "site[:collections] && site[:collections].values.flatten || []"
      inner_content = Regexp.last_match(1) || ""
      
      inner_converted = convert_range_content(inner_content, 'page_item')
      
      "<% #{collection}.each do |page_item| %>\n#{inner_converted}<% end %>"
    end
    
    # Handle generic range (most common case)
    result.gsub!(/\{\{\s*range\s+(?:\$[a-zA-Z0-9_]*\s*:)?\s*(.+?)\s*\}\}((?:.|\n)*?)\{\{\s*end\s*\}\}/) do |match|
      collection = Regexp.last_match(1) || ""
      inner_content = Regexp.last_match(2) || ""
      
      # Determine the iteration variable name
      var_name = 'item' # default
      if collection.match(/\$([a-zA-Z0-9_]+)/)
        var_name = Regexp.last_match(1)
      end
      
      inner_converted = convert_range_content(inner_content, var_name)
      
      "<% #{collection.gsub(/\$([a-zA-Z0-9_]+)/, var_name)}.each do |#{var_name}| %>\n#{inner_converted}<% end %>"
    end
    
    result
  end

  def convert_range_content(content, var_name)
    return content if content.nil?
    
    result = content.dup
    
    # Replace . references inside the range with the iteration variable
    result.gsub!(/\{\{\s*\.\s*\}\}/, "<%= #{var_name} %>")
    result.gsub!(/\{\{\s*\.\s*([a-zA-Z0-9_]+)\s*\}\}/, "<%= #{var_name}['\\1'] %>")
    
    # Handle more complex nested references
    result.gsub!(/\{\{\s*\.([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\s*\}\}/, "<%= #{var_name}['\\1']['\\2'] %>")
    
    result
  end

  def convert_conditional_syntax(content)
    return content if content.nil? # Return original content if nil
    
    result = content.dup
    
    # Handle if/else blocks
    result.gsub!(/\{\{\s*if\s+(.+?)\s*\}\}((?:.|\n)*?)\{\{\s*else\s*\}\}((?:.|\n)*?)\{\{\s*end\s*\}\}/m) do |match|
      condition = Regexp.last_match(1)
      true_content = Regexp.last_match(2)
      false_content = Regexp.last_match(3)
      
      next match if condition.nil? || true_content.nil? || false_content.nil?  # Return original if any match is nil
      
      converted_condition = convert_hugo_condition(condition.strip)
      
      "<% if #{converted_condition} %>\n#{true_content}<% else %>\n#{false_content}<% end %>"
    end
    
    # Handle simple if blocks
    result.gsub!(/\{\{\s*if\s+(.+?)\s*\}\}((?:.|\n)*?)\{\{\s*end\s*\}\}/m) do |match|
      condition = Regexp.last_match(1)
      inner_content = Regexp.last_match(2)
      
      next match if condition.nil? || inner_content.nil?  # Return original if any match is nil
      
      converted_condition = convert_hugo_condition(condition.strip)
      
      "<% if #{converted_condition} %>\n#{inner_content}<% end %>"
    end
    
    # Handle if/else if/else blocks
    result.gsub!(/\{\{\s*if\s+(.+?)\s*\}\}((?:.|\n)*?)\{\{\s*else if\s+(.+?)\s*\}\}((?:.|\n)*?)\{\{\s*else\s*\}\}((?:.|\n)*?)\{\{\s*end\s*\}\}/m) do |match|
      condition1 = Regexp.last_match(1)
      content1 = Regexp.last_match(2)
      condition2 = Regexp.last_match(3)
      content2 = Regexp.last_match(4)
      else_content = Regexp.last_match(5)
      
      next match if condition1.nil? || content1.nil? || condition2.nil? || content2.nil? || else_content.nil?  # Return original if any match is nil
      
      converted_condition1 = convert_hugo_condition(condition1.strip)
      converted_condition2 = convert_hugo_condition(condition2.strip)
      
      "<% if #{converted_condition1} %>\n#{content1}<% elsif #{converted_condition2} %>\n#{content2}<% else %>\n#{else_content}<% end %>"
    end
    
    result
  end

  def convert_hugo_condition(condition)
    return "" if condition.nil? # Return empty string if condition is nil
    
    # Convert Hugo condition syntax to Ruby
    result = condition.dup
    
    # Handle comparison operators
    result.gsub!(/\s+eq\s+/, ' == ')
    result.gsub!(/\s+ne\s+/, ' != ')
    result.gsub!(/\s+lt\s+/, ' < ')
    result.gsub!(/\s+le\s+/, ' <= ')
    result.gsub!(/\s+gt\s+/, ' > ')
    result.gsub!(/\s+ge\s+/, ' >= ')
    result.gsub!(/\s+and\s+/, ' && ')
    result.gsub!(/\s+or\s+/, ' || ')
    result.gsub!(/\s+not\s+/, ' !')
    
    # Handle .Site.Params references in conditions
    result.gsub!(/\.Site\.Params\.([a-zA-Z0-9_]+)/, 'site["\1"]')
    
    # Handle .Param references in conditions
    result.gsub!(/\.Param\s+["']([^"']+)["']/, 'page["\1"]')
    
    # Handle .Params references in conditions
    result.gsub!(/\.Params\.([a-zA-Z0-9_]+)/, 'page["\1"]')
    
    # Handle .Site.* in conditions
    result.gsub!(/\.Site\.([a-zA-Z0-9_]+)/, 'site["\1"]')
    
    # Handle . variables in conditions (context-dependent)
    result.gsub!(/\.([a-zA-Z0-9_]+)/, 'page["\1"]')
    
    # Handle Hugo's len function in conditions
    result.gsub!(/len\s+(.+?)(\s+|(?=\s|$))/, '\1.length\2')
    
    # Handle boolean values
    result.gsub!(/\btrue\b/, 'true')
    result.gsub!(/\bfalse\b/, 'false')
    
    result.strip
  end

  def post_process_content(content)
    # Fix any concatenation issues that may have occurred during conversion
    # For example, fixing "sitepage" issues that occurred in the first version
    result = content.dup
    
    # Fix common concatenation errors
    result.gsub!(/sitepage\./, 'site["')  # Fix the "sitepage" concatenation issue
    result.gsub!(/pagepage\./, 'page["')  # Similar for page
    
    # Fix nested access that was incorrectly converted
    result.gsub!(/site\[([a-zA-Z0-9_]+)\]\[([a-zA-Z0-9_]+)\]/, 'site["\1"] && site["\1"]["\2"]')
    
    # Clean up any remaining Hugo syntax that wasn't converted
    result.gsub!(/\{\{(.+?)\}\}/) do |match|
      # If we still have Hugo syntax after conversion, mark it for manual review
      content = Regexp.last_match(1).strip
      "<%# UNCONVERTED HUGO SYNTAX: {{ #{content} }} - Manual review required %>"
    end
    
    result
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.length < 2
    puts "Usage: ruby hugo_to_typophic_converter.rb <hugo_theme_path> <new_typophic_theme_name>"
    exit 1
  end

  hugo_theme_path = ARGV[0]
  typophic_theme_name = ARGV[1]

  if !Dir.exist?(hugo_theme_path)
    puts "Error: Hugo theme path does not exist: #{hugo_theme_path}"
    exit 1
  end

  converter = HugoToTypophicConverter.new(hugo_theme_path, typophic_theme_name)
  converter.convert
end