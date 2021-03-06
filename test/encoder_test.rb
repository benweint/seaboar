require_relative('test_helper')

class EncodingTests < MiniTest::Test
  def assert_encode(object, expected, options={})
    expected = hex_string_to_byte_string(expected)
    actual = Seaboar.encode(object, options)
    msg = "Failed to encode #{object.inspect}\n"
    msg << "Expected bytes: #{format_byte_string(expected)}\n"
    msg << "Actual bytes:   #{format_byte_string(actual)}\n\n"
    assert_equal(expected, actual, msg)
  end

  def test_encode_zero
    assert_encode(0, "00")
  end

  def test_encode_one
    assert_encode(1, "01")
  end

  def test_encode_ten
    assert_encode(10, "0a")
  end

  def test_encode_23
    assert_encode(23, "17")
  end

  def test_encode_24
    assert_encode(24, "1818")
  end

  def test_encode_25
    assert_encode(25, "1819")
  end

  def test_encode_100
    assert_encode(100, "1864")
  end

  def test_encode_1000
    assert_encode(1000, "1903e8")
  end

  def test_encode_1000000
    assert_encode(1000000, "1a000f4240")
  end

  def test_encode_1000000000000
    assert_encode(1000000000000, "1b000000e8d4a51000")
  end

  def test_encode_18446744073709551615
    assert_encode(18446744073709551615, "1bffffffffffffffff")
  end

  def test_encode_18446744073709551616
    assert_encode(18446744073709551616, "c249010000000000000000")
  end

  def test_encode_negative_18446744073709551616
    assert_encode(-18446744073709551616, "3bffffffffffffffff")
  end

  def test_encode_negative_18446744073709551617
    assert_encode(-18446744073709551617, "c349010000000000000000")
  end

  def test_encode_negative_one
    assert_encode(-1, "20")
  end

  def test_encode_negative_ten
    assert_encode(-10, "29")
  end

  def test_encode_negative_100
    assert_encode(-100, "3863")
  end

  def test_encode_negative_1000
    assert_encode(-1000, "3903e7")
  end

  def test_encode_float_zero
    assert_encode(0.0, "f90000")
  end

  def test_encode_float_negative_zero
    assert_encode(-0.0, "f98000", :float_width => :half)
  end

  def test_encode_float_one
    assert_encode(1.0, "f93c00", :float_width => :half)
  end

  def test_encode_float_1_point_1
    assert_encode(1.1, "fb3ff199999999999a")
  end

  def _test_encode_float_1_point_5
    assert_encode(1.5, "f93e00")
  end

  def _test_encode_float_65504
    assert_encode(65504.0, "f97bff")
  end

  def test_encode_float_100000
    assert_encode(100000.0, "fa47c35000")
  end

  def test_encode_float_large
    assert_encode(3.4028234663852886e+38, "fa7f7fffff")
  end

  def test_encode_float_larger
    assert_encode(1.0e+300, "fb7e37e43c8800759c")
  end

  def _test_encode_float_small
    assert_encode(5.960464477539063e-8, "f90001")
  end

  def _test_encode_float_smallish
    assert_encode(0.00006103515625, "f90400")
  end

  def _test_encode_float_negative_four
    assert_encode(-4.0, "f9c400")
  end

  def test_encode_float_negative_four_point_one
    assert_encode(-4.1, "fbc010666666666666")
  end

  def test_encode_float_infinity
    assert_encode(Float::INFINITY, "f97c00")
  end

  def test_encode_float_nan
    assert_encode(Float::NAN, "f97e00")
  end

  def test_encode_float_negative_infinity
    assert_encode(-Float::INFINITY, "f9fc00")
  end

  def _test_encode_float_infinity_single
    assert_encode(Float::INFINITY, "fa7f800000", :float_width => :single)
  end

  def _test_encode_float_nan_single
    assert_encode(Float::NAN, "fa7fc00000", :float_width => :single)
  end

  def _test_encode_float_negative_infinity_single
    assert_encode(-Float::INFINITY, "faff800000", :float_width => :single)
  end

  def _test_encode_float_infinity_double
    assert_encode(Float::INFINITY, "fb7ff0000000000000", :float_width => :double)
  end

  def _test_encode_float_nan_double
    assert_encode(Float::NAN, "fb7ff8000000000000", :float_width => :double)
  end

  def _test_encode_float_negative_infinity_double
    assert_encode(-Float::INFINITY, "fbfff0000000000000", :float_width => :double)
  end

  def test_encode_false
    assert_encode(false, "f4")
  end

  def test_encode_true
    assert_encode(true, "f5")
  end

  def test_encode_null
    assert_encode(nil, "f6")
  end

  def test_encode_time_string
    assert_encode(Time.iso8601("2013-03-21T20:04:00Z"), "c074323031332d30332d32315432303a30343a30305a", :time_type => :string)
  end

  def test_encode_time_integer
    assert_encode(Time.at(1363896240), "c11a514b67b0", :time_type => :integer)
  end

  def test_encode_time_float
    assert_encode(Time.at(1363896240.5), "c1fb41d452d9ec200000", :time_type => :float)
  end

  def test_encode_empty_byte_string
    assert_encode(''.force_encoding('ASCII-8BIT'), "40")
  end

  def test_encode_byte_string
    assert_encode([1,2,3,4].pack('C*'), "4401020304")
  end

  def test_encode_empty_string
    assert_encode("", "60")
  end

  def test_encode_a
    assert_encode("a", "6161")
  end

  def test_encode_ietf
    assert_encode("IETF", "6449455446")
  end

  def test_encode_escaped
    assert_encode("\"\\", "62225c")
  end

  def test_encode_U_00FC
    assert_encode("\u00fc", "62c3bc")
  end

  def test_encode_U_6C34
    assert_encode("\u6c34", "63e6b0b4")
  end

  def test_encode_U_10151
    assert_encode("\u{10151}", "64f0908591")
  end

  def test_encode_empty_array
    assert_encode([], "80")
  end

  def test_encode_simple_array
    assert_encode([1, 2, 3], "83010203")
  end

  def test_encode_nested_arrays
    assert_encode([1, [2, 3], [4, 5]], "8301820203820405")
  end

  def test_encode_longer_array
    assert_encode([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25], "98190102030405060708090a0b0c0d0e0f101112131415161718181819")
  end

  def test_encode_empty_hash
    assert_encode({}, "a0")
  end

  def test_encode_simple_hash
    assert_encode({ 1 => 2, 3 => 4 }, "a201020304")
  end

  def test_encode_hash_with_arrays
    assert_encode({ "a" => 1, "b" => [2, 3] }, "a26161016162820203")
  end

  def test_encode_array_with_embedded_hash
    assert_encode([ "a", { "b" => "c" }], "826161a161626163")
  end

  def test_encode_stringy_hash
    assert_encode({"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E"}, "a56161614161626142616361436164614461656145")
  end

  def test_encode_array_with_nil
    assert_encode([nil], "81f6")
  end
end
