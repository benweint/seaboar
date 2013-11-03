require_relative('test_helper')

class DiagnosticTests < MiniTest::Unit::TestCase
  diagnostics_dir = File.expand_path(File.join(File.dirname(__FILE__), 'diagnostics'))
  Dir.glob(File.join(diagnostics_dir, "*.cbor")) do |cbor_filename|
    rb_filename = cbor_filename.gsub(/\.cbor$/, '.rb')
    diag_name = cbor_filename.gsub(/\.cbor$/, '')

    define_method("test_#{diag_name}") do
      expected_result = eval(File.read(rb_filename))
      actual_result = Seaboar.parse(File.read(cbor_filename))
      if expected_result.respond_to?(:nan?) && expected_result.nan?
        assert(actual_result.nan?)
      else
        assert_equal(expected_result, actual_result)
      end
    end
  end
end