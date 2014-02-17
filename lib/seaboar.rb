require "seaboar/version"
require "seaboar/constants"
require "seaboar/decoder"
require "seaboar/encoder"

module Seaboar
  def self.decode(input)
    Seaboar::Decoder.new(input).decode
  end

  def self.encode(input, options={})
    Seaboar::Encoder.new(input, options).encode
  end
end
