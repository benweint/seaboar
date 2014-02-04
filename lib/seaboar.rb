module Seaboar
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
  UINT_MAX        = 0xffffffffffffffff
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

  def self.parse(input)
    Seaboar::Parser.new(input).parse
  end

  def self.encode(input, options={})
    Seaboar::Encoder.new(input, options).encode
  end
end

require "seaboar/version"
require "seaboar/parser"
require "seaboar/encoder"
