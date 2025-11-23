require "./base"

module Typophic
  module Commands
    class Theme < Base
      def self.run(args : Array(String))
        new.run(args)
      end

      def run(args : Array(String)) : Nil
        puts "Theme command - TODO: Port from Ruby"
      end
    end
  end
end
