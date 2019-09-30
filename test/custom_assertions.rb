module Minitest::Assertions
  def assert_equivalent(expected, actual, message=nil, options={})
    case expected
    when Hash
      assert_hash_equivalent(expected, actual, message, options)
    when Array
      assert_array_equivalent(expected, actual, message, options)
    when Regexp
      assert_match(expected, actual, message)
    when :present
      assert actual.present?, "Expected #{actual.inspect} to be present. #{message}"
    when :any
      # do nothing because anything is allowed
    when nil
      if options[:allow_nil]
        assert_nil actual, message
      else
        assert_not_nil expected, "Cannot expect nil. To explicitly expect nil, provide the allow_nil option."
      end
    else
      assert_equal expected, actual, message
    end
  end

  def assert_hash_equivalent(expected, actual, message=nil, options={})
    assert actual.instance_of?(Hash) || actual.instance_of?(ActiveSupport::HashWithIndifferentAccess), "Expected #{actual.inspect} to be a Hash, but was #{actual.class.inspect}. #{message}"
    expected.each do |key, expected_v|
      case expected_v
      when :include_key
        assert actual.key?(key), "Expected #{actual.inspect} to include key #{key.inspect}. #{message}"
      when :exclude_key
        assert !actual.key?(key), "Expected #{actual.inspect} to exclude key #{key.inspect}. #{message}"
      else
        assert_equivalent(expected_v, actual[key], "#{message}[#{key.inspect}]", options)
      end
    end
  end

  def assert_array_equivalent(expected, actual, message=nil, options={})
    assert actual.instance_of?(Array), "Expected #{actual.inspect} to be an Array, but was #{actual.class.inspect}. #{message}"
    assert_equal expected.size, actual.size, "Expected array sizes to be equal. #{message}"
    expected.count.times do |i|
      assert_equivalent expected[i], actual[i], "#{message}[#{i}]", options
    end
  end
end