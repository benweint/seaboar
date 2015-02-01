require 'minitest/autorun'

require 'time'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'seaboar'

def format_byte_string(s)
  s.unpack("C*").map { |b| "%02x" % b }.join(' ')
end

def hex_string_to_byte_string(s)
  s.scan(/.{2}/).map(&:hex).pack("C*")
end
