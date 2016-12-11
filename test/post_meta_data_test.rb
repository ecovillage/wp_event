require 'test_helper'

class PostMetaDataTest < Minitest::Test
  def test_initialization
    data = WPEvent::PostMetaData.new test_key: 'test_value', test_key2: :test_value2
    assert_equal data.multivalued?(:test_key2), false
    assert_equal data.values(:test_key2), [:test_value2]
    assert_equal data.values(:test_key),  ['test_value']
  end
end
