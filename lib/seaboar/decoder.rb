require 'time'
require 'uri'

module Seaboar
  class ParseError < RuntimeError; end
  class InvalidSimpleTypeError < ParseError; end

  class Decoder
    def initialize(input)
      @value = nil
      @input = input
      @cursor = 0
      @tag = nil
      @stack = []
      @indefinite = []
    end

    def push(value)
      @tag = nil
      @value = value
    end

    def take(n)
      result = @input.byteslice(@cursor, n)
      @cursor += n
      result
    end

    def uint(bytestr)
      bytestr.bytes.inject(0) { |v, x| ((v << 8) | x) }
    end

    def take_uint(extra)
      case
      when extra <= UINT_MAX_INLINE
        extra
      when extra == SUBTYPE_UINT8
        uint(take(1))
      when extra == SUBTYPE_UINT16
        uint(take(2))
      when extra == SUBTYPE_UINT32
        uint(take(4))
      when extra == SUBTYPE_UINT64
        uint(take(8))
      end
    end

    def take_neg_int(extra)
      (-1 - parse_uint(extra))
    end

    def interpret_byte_string(value)
      case @tag
      when nil
        value
      when TAG_BIGNUM
        uint(value)
      when TAG_NEG_BIGNUM
        -1 - uint(value)
      end
    end

    def interpret_numeric(value)
      case @tag
      when TAG_EPOCH_TIME
        Time.at(value)
      else
        value
      end
    end

    def parse_uint(extra)
      interpret_numeric(take_uint(extra))
    end

    def parse_neg_int(extra)
      interpret_numeric(take_neg_int(extra))
    end

    def parse_byte_string(extra)
      if extra == LENGTH_INDEFINITE
        str = ''.force_encoding('ASCII-8BIT')
        parse_indefinite(str)
      else
        str = parse_byte_string_chunk(extra)
      end

      interpret_byte_string(str)
    end

    def parse_byte_string_chunk(extra)
      length = parse_uint(extra)
      take(length)
    end

    def consume_utf8_string(bytesize)
      bytes = take(bytesize)
      bytes.force_encoding('UTF-8')
      bytes
    end

    def parse_utf8_string(extra)
      if extra == LENGTH_INDEFINITE
        str = parse_indefinite('')
      else
        length = parse_uint(extra)
        str = consume_utf8_string(length)
      end
      interpret_utf8_string(str)
    end

    def interpret_utf8_string(raw_str)
      case @tag
      when TAG_DATETIME_STR
        Time.iso8601(raw_str)
      when TAG_UTF8_URI
        URI(raw_str)
      else
        raw_str
      end
    end

    def push_tag(extra)
      @tag = take_uint(extra)
    end

    def parse_simple(extra)
      if extra <= SIMPLE_MAXINLINE
        value = extra
      else
        value = uint(take(1))
      end

      case value
      when SIMPLE_FALSE
        false
      when SIMPLE_TRUE
        true
      when SIMPLE_NULL
        nil
      when SIMPLE_UNDEF
        nil
      else
        raise InvalidSimpleTypeError.new("Invalid simple type #{value} at byte #{@cursor}")
      end
    end

    def parse_float_half
      half = uint(take(2))
      exp  = (half >> 10) & 0x1f
      mant = (half & 0x3ff)

      val = case exp
      when 0
        Math.ldexp(mant, -24)
      when 31
        mant == 0 ? Float::INFINITY : Float::NAN
      else
        Math.ldexp(mant + 1024, exp - 25)
      end

      (half & 0x8000 != 0) ? -val : val
    end

    def parse_float_double
      take(8).unpack("G")[0]
    end

    def parse_float_single
      take(4).unpack("g")[0]
    end

    def parse_array(extra)
      array = []
      if extra == LENGTH_INDEFINITE
        parse_indefinite(array)
      else
        length = parse_uint(extra)
        length.times { array << parse_one }
      end
      array
    end

    def parse_map(extra)
      map = {}
      if extra == LENGTH_INDEFINITE
        map = Hash[*parse_indefinite([])]
      else
        length = parse_uint(extra)
        length.times do
          map[parse_one] = parse_one
        end
      end
      map
    end

    def parse_float_or_simple(extra)
      case
      when extra <= SIMPLE_MAXINLINE || extra == SIMPLE_ONE_BYTE
        parse_simple(extra)
      when extra == FLOAT_HALF
        interpret_numeric(parse_float_half)
      when extra == FLOAT_SINGLE
        interpret_numeric(parse_float_single)
      when extra == FLOAT_DOUBLE
        interpret_numeric(parse_float_double)
      end
    end

    def parse_indefinite(initial)
      target_depth = @indefinite.size
      @indefinite.push(true)
      loop do
        chunk = parse_one
        break if @indefinite.size == target_depth
        initial << chunk
      end
      initial
    end

    def parse_one
      byte = uint(take(1))
      major_type = (byte & 0xE0) >> 5 # top three bytes
      extra      = byte & 0x1F

      case major_type
      when MAJ_TYPE_UINT
        push(parse_uint(extra))
      when MAJ_TYPE_NEG_INT
        push(parse_neg_int(extra))
      when MAJ_TYPE_BYTE_STR
        push(parse_byte_string(extra))
      when MAJ_TYPE_UTF8_STR
        push(parse_utf8_string(extra))
      when MAJ_TYPE_ARRAY
        push(parse_array(extra))
      when MAJ_TYPE_MAP
        push(parse_map(extra))
      when MAJ_TYPE_FLOAT_OTHER
        if extra == INDEFINITE_BREAK
          @indefinite.pop
        else
          push(parse_float_or_simple(extra))
        end
      when MAJ_TYPE_TAG
        push_tag(extra)
      end
    end

    def decode
      while (@cursor < @input.bytesize)
        parse_one
      end
      @value
    end
  end
end