require "seaboar/version"
require "seaboar/parser"

module Seaboar
  def self.parse(input)
    parser = Seaboar::Parser.new(input)
    parser.parse
  end
end
