require_relative('test_helper')

class EncodingTests < MiniTest::Unit::TestCase
  def assert_decode(bytes, expected)
    bytes = hex_string_to_byte_string(bytes)
    actual = Seaboar.parse(bytes)
    msg = "Failed to decode #{format_byte_string(bytes)}\n"
    msg << "Expected: #{expected.inspect}\n"
    msg << "Actual:   #{actual.inspect}\n\n"
    if expected.is_a?(Float) && expected.nan?
      assert actual.nan?, msg
    else
      assert_equal(expected, actual, msg)
    end
  end

  def test_decode_zero
    assert_decode("00", 0)
  end

  def test_decode_one
    assert_decode("01", 1)
  end

  def test_decode_ten
    assert_decode("0a", 10)
  end

  def test_decode_23
    assert_decode("17", 23)
  end

  def test_decode_24
    assert_decode("1818", 24)
  end

  def test_decode_25
    assert_decode("1819", 25)
  end

  def test_decode_100
    assert_decode("1864", 100)
  end

  def test_decode_1000
    assert_decode("1903e8", 1000)
  end
  
  def test_decode_1000000
    assert_decode("1a000f4240", 1000000)
  end
  
  def test_decode_1000000000000
    assert_decode("1b000000e8d4a51000", 1000000000000)
  end
  
  def test_decode_18446744073709551615
    assert_decode("1bffffffffffffffff", 18446744073709551615)
  end
  
  def test_decode_18446744073709551616
    assert_decode("c249010000000000000000", 18446744073709551616)
  end
  
  def test_decode_negative_18446744073709551616
    assert_decode("3bffffffffffffffff", -18446744073709551616)
  end
  
  def test_decode_negative_18446744073709551617
    assert_decode("c349010000000000000000", -18446744073709551617)
  end
  
  def test_decode_negative_one
    assert_decode("20", -1)
  end
  
  def test_decode_negative_10
    assert_decode("29", -10)
  end
  
  def test_decode_negative_100
    assert_decode("3863", -100)
  end
  
  def test_decode_negative_1000
    assert_decode("3903e7", -1000)
  end
  
  def test_decode_zero_float
    assert_decode("f90000", 0.0)
  end
  
  def test_decode_negative_zero_float
    assert_decode("f98000", -0.0)
  end
  
  def test_decode_one_float
    assert_decode("f93c00", 1.0)
  end
  
  def test_decode_one_point_one_float
    assert_decode("fb3ff199999999999a", 1.1)
  end
  
  def test_decode_one_point_five_float
    assert_decode("f93e00", 1.5)
  end
  
  def test_decode_65504_float
    assert_decode("f97bff", 65504.0)
  end
  
  def test_decode_100000_float
    assert_decode("fa47c35000", 100000.0)
  end
  
  def test_decode_large_single_float
    assert_decode("fa7f7fffff", 3.4028234663852886e+38)
  end
  
  def test_decode_large_double_float
    assert_decode("fb7e37e43c8800759c", 1.0e+300)
  end
  
  def test_decode_tiny_half_float
    assert_decode("f90001", 5.960464477539063e-08)
  end
  
  def test_decode_tinyish_half_float
    assert_decode("f90400", 6.103515625e-05)
  end
  
  def test_decode_negative_four_float
    assert_decode("f9c400", -4.0)
  end
  
  def test_decode_negative_four_point_one_float
    assert_decode("fbc010666666666666", -4.1)
  end
  
  def test_decode_infinity_half
    assert_decode("f97c00", Float::INFINITY)
  end
  
  def test_decode_nan_half
    assert_decode("f97e00", Float::NAN)
  end
  
  def test_decode_negative_infinity_half
    assert_decode("f9fc00", -Float::INFINITY)
  end
  
  def test_decode_infinity_single
    assert_decode("fa7f800000", Float::INFINITY)
  end
  
  def test_decode_nan_single
    assert_decode("fa7fc00000", Float::NAN)
  end
  
  def test_decode_negative_infinity_single
    assert_decode("faff800000", -Float::INFINITY)
  end
  
  def test_decode_infinity_double
    assert_decode("fb7ff0000000000000", Float::INFINITY)
  end
  
  def test_decode_nan_double
    assert_decode("fb7ff8000000000000", Float::NAN)
  end
  
  def test_decode_negative_infinity_double
    assert_decode("fbfff0000000000000", -Float::INFINITY)
  end
  
  def test_decode_false
    assert_decode("f4", false)
  end
  
  def test_decode_true
    assert_decode("f5", true)
  end
  
  def test_decode_nil
    assert_decode("f6", nil)
  end
  
  def test_decode_nil_again
    assert_decode("f7", nil)
  end
  
  def test_decode_iso_time
    assert_decode("c074323031332d30332d32315432303a30343a30305a", Time.iso8601("2013-03-21T20:04:00Z"))
  end
  
  def test_decode_unix_int_time
    assert_decode("c11a514b67b0", Time.at(1363896240))
  end
  
  def test_decode_unix_float_time
    assert_decode("c1fb41d452d9ec200000", Time.at(1363896240.5))
  end
  
  def test_decode_url
    assert_decode("d82076687474703a2f2f7777772e6578616d706c652e636f6d", URI("http://www.example.com"))
  end
  
  def test_decode_empty_byte_string
    assert_decode("40", "".force_encoding("ASCII-8BIT"))
  end
  
  def test_decode_byte_string
    assert_decode("4401020304", [1,2,3,4].pack('C*'))
  end
  
  def test_decode_empty_utf8_string
    assert_decode("60", "")
  end
  
  def test_decode_string_a
    assert_decode("6161", "a")
  end
  
  def test_decode_string_IETF
    assert_decode("6449455446", "IETF")
  end
  
  def test_decode_string_escapes
    assert_decode("62225c", '"\\')
  end

  def test_decode_diag055
    assert_decode("62c3bc", "\u00fc")
  end

  def test_decode_diag056
    assert_decode("63e6b0b4", "\u6c34")
  end

  def test_decode_diag057
    assert_decode("64f0908591", "\u{10151}")
  end
  
  def test_decode_empty_array
    assert_decode("80", [])
  end
  
  def test_decode_simple_array
    assert_decode("83010203", [1, 2, 3])
  end
  
  def test_decode_nested_array
    assert_decode("8301820203820405", [1, [2, 3], [4, 5]])
  end
  
  def test_decode_longer_array
    assert_decode("98190102030405060708090a0b0c0d0e0f101112131415161718181819", [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25])
  end
  
  def test_decode_empty_hash
    assert_decode("a0", {})
  end
  
  def test_decode_simple_hash
    assert_decode("a201020304", {1 => 2, 3 => 4})
  end
  
  def test_decode_hash_with_array_value
    assert_decode("a26161016162820203", {"a" => 1, "b" => [2, 3]})
  end
  
  def test_decode_array_with_embedded_hash
    assert_decode("826161a161626163", ["a", {"b" => "c"}])
  end
  
  def test_decode_hash_with_string_keys
    assert_decode("a56161614161626142616361436164614461656145", { "a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E" })
  end
  
  def test_decode_diag067
    assert_decode("5f42010243030405ff", [1,2,3,4,5].pack("C*"))
  end
  
  def test_decode_streaming_string
    assert_decode("7f657374726561646d696e67ff", "streaming")
  end
  
  def test_decode_streaming_array_empty
    assert_decode("9fff", [])
  end
  
  def test_decode_diag070
    assert_decode("9f018202039f0405ffff", [1, [2, 3], [4, 5]])
  end
  
  def test_decode_diag071
    assert_decode("9f01820203820405ff", [1, [2, 3], [4, 5]])
  end
  
  def test_decode_diag072
    assert_decode("83018202039f0405ff", [1, [2, 3], [4, 5]])
  end
  
  def test_decode_diag073
    assert_decode("83019f0203ff820405", [1, [2, 3], [4, 5]])
  end
  
  def test_decode_diag074
    assert_decode("9f0102030405060708090a0b0c0d0e0f101112131415161718181819ff", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25])
  end
  
  def test_decode_diag075
    assert_decode("bf61610161629f0203ffff", { "a" => 1, "b" => [2, 3] })
  end
  
  def test_decode_diag076
    assert_decode("826161bf61626163ff", ["a", { "b" => "c" }])
  end
  
  def test_decode_diag077
    assert_decode("bf6346756ef563416d7421ff", { "Fun" => true, "Amt" => -2 })
  end
end
