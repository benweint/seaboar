require 'time'
require 'uri'

module Seaboar
  class ParseError < RuntimeError; end
  class InvalidSimpleTypeError < ParseError; end

  class Parser
    # Major types
    MAJ_TYPE_UINT        = 0
    MAJ_TYPE_NEG_INT     = 1
    MAJ_TYPE_BYTE_STR    = 2
    MAJ_TYPE_UTF8_STR    = 3
    MAJ_TYPE_ARRAY       = 4
    MAJ_TYPE_MAP         = 5
    MAJ_TYPE_TAG         = 6
    MAJ_TYPE_FLOAT_OTHER = 7

    LENGTH_INDEFINITE = 31

    # Subtypes for MAJ_TYPE_UINT / MAJ_TYPE_NEG_INT
    UINT_MAX_INLINE = 23
    SUBTYPE_UINT8   = 24
    SUBTYPE_UINT16  = 25
    SUBTYPE_UINT32  = 26
    SUBTYPE_UINT64  = 27

    # Subtypes for MAJ_TYPE_TAG
    TAG_DATETIME_STR     = 0
    TAG_EPOCH_TIME       = 1
    TAG_BIGNUM           = 2
    TAG_NEG_BIGNUM       = 3
    TAG_DECIMAL_FRACTION = 4
    TAG_BIGFLOAT         = 5
    # 6..20 unallocated
    TAG_BASE64_URL       = 21
    TAG_BASE64           = 22
    TAG_BASE16           = 23
    TAG_CBOR             = 24
    # 25..31 unallocated
    TAG_UTF8_URI         = 32
    TAG_UTF8_BASE64_URL  = 33
    TAG_UTF8_BASE64      = 34
    TAG_UTF8_REGEX       = 35
    TAG_MIME             = 36

    # Subtypes for MAJ_TYPE_FLOAT_OTHER
    SIMPLE_MAXINLINE = 23
    SIMPLE_ONE_BYTE  = 24
    FLOAT_HALF       = 25
    FLOAT_SINGLE     = 26
    FLOAT_DOUBLE     = 27
    INDEFINITE_BREAK = 31

    # Known simple types
    SIMPLE_FALSE = 20
    SIMPLE_TRUE  = 21
    SIMPLE_NULL  = 22
    SIMPLE_UNDEF = 23

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
        parse_indefinite { |chunk| str << chunk }
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
        str = ''
        parse_indefinite { |chunk| str << chunk }
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
        parse_indefinite { |chunk| array << chunk }
      else
        length = parse_uint(extra)
        length.times { array << parse_one }
      end
      array
    end

    def parse_map(extra)
      map = {}
      if extra == LENGTH_INDEFINITE
        keys_and_values = []
        parse_indefinite { |chunk| keys_and_values << chunk }
        map = Hash[*keys_and_values]
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

    def parse_indefinite
      target_depth = @indefinite.size
      @indefinite.push(true)
      loop do
        chunk = parse_one
        break if @indefinite.size == target_depth
        yield chunk
      end
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

    def parse
      while (@cursor < @input.bytesize)
        parse_one
      end
      @value
    end
  end
end