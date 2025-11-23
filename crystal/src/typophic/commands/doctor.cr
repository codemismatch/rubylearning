require "./base"

module Typophic
  module Commands
    class Doctor < Base
      def self.run(args : Array(String))
        new.run(args)
      end

      def run(args : Array(String)) : Nil
        puts "Doctor command - TODO: Port from Ruby"
      end
    end
  end
end
