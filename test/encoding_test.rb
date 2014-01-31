require_relative('test_helper')

class EncodingTests < MiniTest::Unit::TestCase
  def assert_encode(object, expected)
    expected_bytes = expected.scan(/.{2}/).map(&:hex)
    expected_bin   = expected_bytes.pack("C*")
    actual = Seaboar.encode(object)
    msg = "Failed to encode #{object.inspect}\n"
    msg << "Expected bytes: #{expected_bin.unpack('C*').map { |b| b.to_s(16) }.join(' ')}\n"
    msg << "Actual bytes:   #{actual.unpack('C*').map { |b| b.to_s(16) }.join(' ')}\n\n"
    assert_equal(expected_bin, actual, msg)
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
    assert_encdoe(1.1, "fb3ff199999999999a")
  end
end
