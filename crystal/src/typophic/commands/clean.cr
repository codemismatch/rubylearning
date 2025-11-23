require "./base"

module Typophic
  module Commands
    class Clean < Base
      def self.run(args : Array(String))
        new.run(args)
      end

      def run(args : Array(String)) : Nil
        puts "Clean command - TODO: Port from Ruby"
        # TODO: Remove public/ directory
      end
    end
  end
end
