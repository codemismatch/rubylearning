# frozen_string_literal: true

require "fileutils"

module Typophic
  module Commands
    module Clean
      module_function

      def run(argv)
        target = argv.shift || "public"
        if !Dir.exist?(target)
          puts "Nothing to clean: #{target} does not exist"
          return
        end
        FileUtils.rm_rf(Dir.glob(File.join(target, "*")))
        puts "Cleaned #{target}/"
      end
    end
  end
end

