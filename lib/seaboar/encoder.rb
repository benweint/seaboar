module Seaboar
  class Encoder
    FLOAT_WIDTHS = {
      :half   => FLOAT_HALF,
      :single => FLOAT_SINGLE,
      :double => FLOAT_DOUBLE
    }

    DEFAULTS = {
      :float_width => :double,
      :time_types  => :string
    }

    def initialize(input, options={})
      @input = input
      @output = ""
      @output.force_encoding('ASCII-8BIT')
      @options = DEFAULTS.merge(options)
      @float_width = FLOAT_WIDTHS[@options[:float_width]]
      @time_type   = @options[:time_type]
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
      if n.nan?
        put(0x7e); put(0x00)
      else
        case n
        when 0.0
          if n.phase == 0 # +0.0
            put(0x00); put(0x00)
          else # -0.0
            put(0x80); put(0x00)
          end
        when 1.0
          put(0x3c); put(0x00)
        when Float::INFINITY
          put(0x7c); put(0x00)
        when -Float::INFINITY
          put(0xfc); put(0x00)
        end
      end
    end

    def float_auto_width(n)
      if [n].pack("g").unpack("g").first == n
        FLOAT_SINGLE
      else
        FLOAT_DOUBLE
      end
    end

    def encode_float(n)
      if n.nan?
        put_float_special(n)
        return
      end
      case n
      when 0.0, 1.0, Float::INFINITY, -Float::INFINITY
        put_float_special(n)
      when n.nan?
        puts "got a nan!"
        put_float_special(n)
      else
        float_width = float_auto_width(n)
        put_type(MAJ_TYPE_FLOAT_OTHER, float_width)
        case float_width
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

    def put_simple_value(value)
      if value <= SIMPLE_MAXINLINE
        put_type(MAJ_TYPE_FLOAT_OTHER, value)
      else
        put_type(MAJ_TYPE_FLOAT_OTHER, SIMPLE_ONE_BYTE)
        put(value)
      end
    end

    def encode_array(array)
      put_numeric_bytes(MAJ_TYPE_ARRAY, array.size)
      array.each { |v| encode_object(v) }
    end

    def encode_hash(hash)
      put_numeric_bytes(MAJ_TYPE_MAP, hash.size)
      hash.each { |k, v| encode_object(k); encode_object(v) }
    end

    def encode_time(time)
      case @time_type
      when :string
        put_type(MAJ_TYPE_TAG, TAG_DATETIME_STR)
        encode_string(time.iso8601, MAJ_TYPE_UTF8_STR)
      when :integer
        put_type(MAJ_TYPE_TAG, TAG_EPOCH_TIME)
        encode_integer(time.to_i)
      when :float
        put_type(MAJ_TYPE_TAG, TAG_EPOCH_TIME)
        encode_float(time.to_f)
      end
    end

    def encode_object(object)
      case object
      when Integer
        encode_integer(object)
      when Float
        encode_float(object)
      when String
        if object.encoding == Encoding::ASCII_8BIT
          encode_string(object, MAJ_TYPE_BYTE_STR)
        else
          encode_string(object, MAJ_TYPE_UTF8_STR)
        end
      when Array
        encode_array(object)
      when Hash
        encode_hash(object)
      when Time
        encode_time(object)
      when true
        put_simple_value(SIMPLE_TRUE)
      when false
        put_simple_value(SIMPLE_FALSE)
      when nil
        put_simple_value(SIMPLE_NULL)
      end
    end

    def encode
      encode_object(@input)
      @output
    end
  end
end
