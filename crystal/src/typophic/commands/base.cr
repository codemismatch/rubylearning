module Typophic
  module Commands
    abstract class Base
      abstract def run(args : Array(String)) : Nil
    end
  end
end
