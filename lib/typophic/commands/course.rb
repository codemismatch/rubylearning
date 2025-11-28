require 'yaml'
require 'fileutils'
require 'optparse'

module Typophic
  module Commands
    module Course
      DATA_FILE = File.join("data", "courses.yml")

      def self.run(argv)
        subcommand = argv.shift
        case subcommand
        when "new"
          new_course(argv)
        when "add-module"
          add_module(argv)
        when "add-tutorial"
          add_tutorial(argv)
        else
          puts "Usage: typophic course [new|add-module|add-tutorial] ..."
          exit 1
        end
      end

      def self.new_course(argv)
        options = {}
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic course new TITLE --id ID"
          opts.on("--id ID", "Course ID (slug)") { |v| options[:id] = v }
        end
        
        args = parser.parse(argv)
        title = args.join(" ")
        
        if title.empty? || !options[:id]
          puts "Error: Title and --id are required."
          puts parser
          exit 1
        end

        courses = load_courses
        if courses.any? { |c| c["id"] == options[:id] }
          puts "Error: Course with ID '#{options[:id]}' already exists."
          exit 1
        end

        new_course = {
          "id" => options[:id],
          "title" => title,
          "description" => "New course description",
          "modules" => []
        }

        courses << new_course
        save_courses(courses)
        puts "Created course: #{title} (#{options[:id]})"
      end

      def self.add_module(argv)
        options = {}
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic course add-module COURSE_ID TITLE --id MODULE_ID"
          opts.on("--id ID", "Module ID (slug)") { |v| options[:id] = v }
        end

        args = parser.parse(argv)
        course_id = args.shift
        title = args.join(" ")

        if !course_id || title.empty? || !options[:id]
          puts "Error: Course ID, Title, and --id are required."
          puts parser
          exit 1
        end

        courses = load_courses
        course = courses.find { |c| c["id"] == course_id }
        
        unless course
          puts "Error: Course '#{course_id}' not found."
          exit 1
        end

        course["modules"] ||= []
        if course["modules"].any? { |m| m["id"] == options[:id] }
          puts "Error: Module '#{options[:id]}' already exists in course '#{course_id}'."
          exit 1
        end

        new_module = {
          "id" => options[:id],
          "title" => title,
          "tutorials" => []
        }

        course["modules"] << new_module
        save_courses(courses)
        puts "Added module '#{title}' to course '#{course_id}'"
      end

      def self.add_tutorial(argv)
        if argv.length < 3
          puts "Usage: typophic course add-tutorial COURSE_ID MODULE_ID TUTORIAL_SLUG"
          exit 1
        end

        course_id = argv[0]
        module_id = argv[1]
        tutorial_slug = argv[2]

        courses = load_courses
        course = courses.find { |c| c["id"] == course_id }
        unless course
          puts "Error: Course '#{course_id}' not found."
          exit 1
        end

        mod = course["modules"]&.find { |m| m["id"] == module_id }
        unless mod
          puts "Error: Module '#{module_id}' not found in course '#{course_id}'."
          exit 1
        end

        mod["tutorials"] ||= []
        if mod["tutorials"].include?(tutorial_slug)
          puts "Tutorial '#{tutorial_slug}' is already in module '#{module_id}'."
          exit 0
        end

        mod["tutorials"] << tutorial_slug
        save_courses(courses)
        puts "Added tutorial '#{tutorial_slug}' to module '#{module_id}'"
      end

      private

      def self.load_courses
        return [] unless File.exist?(DATA_FILE)
        YAML.load_file(DATA_FILE) || []
      end

      def self.save_courses(courses)
        FileUtils.mkdir_p(File.dirname(DATA_FILE))
        File.write(DATA_FILE, courses.to_yaml)
      end
    end
  end
end
