module Seaboar
  class Encoder
    FLOAT_WIDTHS = {
      :half   => FLOAT_HALF,
      :single => FLOAT_SINGLE,
      :double => FLOAT_DOUBLE
    }

    DEFAULTS = {
      :float_width => :double
    }

    def initialize(input, options={})
      @input = input
      @output = ""
      @output.force_encoding('ASCII-8BIT')
      @options = DEFAULTS.merge(options)
      @float_width = FLOAT_WIDTHS[@options[:float_width]]
    end

    def encode_integer(n)
      value = n >= 0 ? n : -1 - n
      if value <= UINT_MAX
        type = n >= 0 ? MAJ_TYPE_UINT : MAJ_TYPE_NEG_INT
        put_numeric_bytes(type, value)
      else
        put_type(MAJ_TYPE_TAG, n >= 0 ? TAG_BIGNUM : TAG_NEG_BIGNUM)
        bytestr = ''.force_encoding('ASCII-8BIT')
        while value > 0
          bytestr << (value & 0xff)
          value = value >> 8
        end
        encode_string(bytestr.reverse, MAJ_TYPE_BYTE_STR)
      end
    end

    def put(byte)
      @output << byte.chr
    end

    def put_bytes(byte_string)
      @output << byte_string
    end

    def put_type(type, extra)
      put(((type << 5) & 0b11100000) | (extra & 0b00011111))
    end

    def put_numeric_bytes(type, n)
      type_bits = type << 5
      case
      when n <= UINT_MAX_INLINE
        put(type_bits | n)
      when n <= 0xff
        put(type_bits | SUBTYPE_UINT8)
        put(n)
      when n <= 0xffff
        put(type_bits | SUBTYPE_UINT16)
        put_bytes([n].pack("S>"))
      when n <= 0xffffffff
        put(type_bits | SUBTYPE_UINT32)
        put_bytes([n].pack("L>"))
      when n <= 0xffffffffffffffff
        put(type_bits | SUBTYPE_UINT64)
        put_bytes([n].pack("Q>"))
      end
    end

    def put_float_special(n)
      put_type(MAJ_TYPE_FLOAT_OTHER, FLOAT_HALF)
      case n
      when 0.0
        put(0x00); put(0x00)
      when -0.0
        put(0x80); put(0x00)
      when 1.0
        put(0x3c); put(0x00)
      when Float::INFINITY
        
      end
    end

    def encode_float(n)
      case n
      when 0.0, -0.0, 1.0, Float::INFINITY
        put_float_special(n)
      else
        put_type(MAJ_TYPE_FLOAT_OTHER, @float_width)
        case @float_width
        when FLOAT_SINGLE
          put_bytes([n].pack("g"))
        when FLOAT_DOUBLE
          put_bytes([n].pack("G"))
        end
      end
    end

    def encode_string(s, type)
      nbytes = s.bytesize
      put_numeric_bytes(type, nbytes)
      s.each_byte { |b| put(b) }
    end

    def encode
      current = @input
      case current
      when Integer
        encode_integer(current)
      when Float
        encode_float(current)
      when String
        if current.encoding == 'ASCII-8BIT'
        else
        end
      when Array
      when Hash
      end
      @output
    end
  end
end
