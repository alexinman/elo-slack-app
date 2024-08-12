module Minitest::Assertions
  def assert_equivalent(expected, actual, options={})
    case expected
    when Hash
      assert_hash_equivalent(expected, actual, options)
    when Array
      assert_array_equivalent(expected, actual, options)
    when Regexp
      assert_match(expected, actual, options[:message])
    when :present
      assert actual.present?, "Expected #{actual.inspect} to be present. #{options[:message]}"
    when :any
      # do nothing because anything is allowed
    when nil
      if options[:allow_nil]
        assert_nil actual, options[:message]
      else
        assert_not_nil expected, "Cannot expect nil. To explicitly expect nil, provide the allow_nil option."
      end
    else
      assert_equal expected, actual, options[:message]
    end
  end

  def assert_hash_equivalent(expected, actual, options={})
    assert actual.instance_of?(Hash) || actual.instance_of?(ActiveSupport::HashWithIndifferentAccess), "Expected #{actual.inspect} to be a Hash, but was #{actual.class.inspect}. #{options[:message]}"
    expected.each do |key, expected_v|
      case expected_v
      when :include_key
        assert actual.key?(key), "Expected #{actual.inspect} to include key #{key.inspect}. #{options[:message]}"
      when :exclude_key
        assert !actual.key?(key), "Expected #{actual.inspect} to exclude key #{key.inspect}. #{options[:message]}"
      else
        opts = options.dup
        opts[:message] = "#{opts[:message]}[#{key.inspect}]"
        assert_equivalent(expected_v, actual[key], opts)
      end
    end
  end

  def assert_array_equivalent(expected, actual, options={})
    assert actual.instance_of?(Array), "Expected #{actual.inspect} to be an Array, but was #{actual.class.inspect}. #{options[:message]}"
    assert_equal expected.size, actual.size, "Expected array sizes to be equal. #{options[:message]}"
    expected.count.times do |i|
      opts = options.dup
      opts[:message] = "#{opts[:message]}[#{i}]"
      assert_equivalent expected[i], actual[i], opts
    end
  end

  def assert_json_response(expected, options={})
    assert_response :ok, json_response
    assert_hash_equivalent(expected, json_response, options)
  end

  def json_response
    @json_response ||= JSON.parse(response.body) rescue nil
  end
end
