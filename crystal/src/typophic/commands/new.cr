require "./base"

module Typophic
  module Commands
    class New < Base
      def self.run(args : Array(String))
        new.run(args)
      end

      def run(args : Array(String)) : Nil
        puts "New command - TODO: Port from Ruby"
      end
    end
  end
end
