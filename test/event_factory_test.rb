require 'test_helper'

class EventFactoryTest < Minitest::Test
  def test_from_json
    from_json = {:uuid        => "8fac",
                 :name        => "Bar",
                 :description => "Bar open till 22h!",
                 :fromdate    => "2017-04-02",
                 :todate      => "2017-04-03",
                 :category_names => ["Fun","Evening"]}
    event_factory = WPEvent::EventFactory.new
    event_factory.category_cache.define_singleton_method(:id_of_names) do |category_names|
      [1, 2]
    end

    event = event_factory.from_json from_json

    assert_equal([1,2], event.event_category_id)
    assert_equal "1491091200", event.fromdate
    assert_equal "1491177600", event.todate
    assert_equal "Bar", event.name
    assert_equal "Bar open till 22h!", event.description
    assert_equal "Bar open till 22h!", event.content
  end

  def test_from_json_raises_on_nonex_cat
    from_json = {:uuid        => "8fac",
                 :name        => "Bar",
                 :description => "Bar open till 22h!",
                 :category_names => ["Fun","Evening"]}
    event_factory = WPEvent::EventFactory.new
    event_factory.category_cache.define_singleton_method(:id_of_names) do |category_names|
      [1, nil]
    end

    assert_raises WPEvent::MissingCategoryError do
      event = event_factory.from_json from_json
    end
  end
end
