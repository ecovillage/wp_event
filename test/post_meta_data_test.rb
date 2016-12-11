require 'test_helper'

class PostMetaDataTest < Minitest::Test
  def test_initialization
    data = WPEvent::PostMetaData.new test_key: 'test_value', test_key2: :test_value2
    assert_equal data.values(:test_key2), [:test_value2]
    assert_equal data.values(:test_key),  ['test_value']
  end

  def test_update_or_create
    data = WPEvent::PostMetaData.new test_key: 'test_value',
      test_key2: :test_value2
    data.update_or_create :test_key2, :new_value2
    data.update_or_create :test_key3, :value3
    assert_equal data.values(:test_key2), [:new_value2]
    assert_equal data.values(:test_key),  ['test_value']
    assert_equal data.values(:test_key3), [:value3]
  end

end
