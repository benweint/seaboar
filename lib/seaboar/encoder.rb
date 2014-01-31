module Seaboar
  class Encoder
    FLOAT_WIDTHS = {
      :half => FLOAT_HALF
    }

    DEFAULTS = {
      :float_width => :half
    }

    def initialize(input, options={})
      @input = input
      @output = ""
      @output.force_encoding('ASCII-8BIT')
      @options = DEFAULTS.merge(options)
    end

    def encode_fixnum(n)
      type = n >= 0 ? MAJ_TYPE_UINT : MAJ_TYPE_NEG_INT
      value = type == MAJ_TYPE_UINT ? n : -1 - n

      if value <= UINT_MAX_INLINE
        put_type(type, value)
      else
        put_numeric_bytes(type, value)
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

    def encode_float(n, width)
      case n
      when Float::INFINITY
        put_type(MAJ_TYPE_FLOAT_OTHER, FLOAT_WIDTHS[width])
      else
      end
    end

    def encode
      current = @input
      case current
      when Fixnum
        encode_fixnum(current)
      when Float
        encode_float(current, @options[:float_width])
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
