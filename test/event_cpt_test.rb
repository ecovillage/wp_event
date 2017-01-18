require 'test_helper'

class EventCPTTest < Minitest::Test
  def test_from_json
    from_json = {
                 :uuid        => "8fac",
                 :name        => "Bar",
                 :description => "Bar open till 22h!",
                 :fromdate    => DateTime.parse("2017-04-02").to_time.to_i,
                 :todate      => DateTime.parse("2017-04-03").to_time.to_i,
                 }
    event = WPEvent::CustomPostTypes::Event.new **from_json

    assert_equal "1491091200", event.fromdate
    assert_equal "1491177600", event.todate
    assert_equal "Bar", event.name
    assert_equal "Bar", event.title
    assert_equal "Bar open till 22h!", event.description
    assert_equal "Bar open till 22h!", event.content
  end

  def test_add_referee
    event = WPEvent::CustomPostTypes::Event.new
    event.add_referee('12', 'Magician')
    asserted_content = { post_type: "ev7l-event",
                         post_status: "publish",
                         post_title: "",
                         post_content: "",
                         custom_fields: [{:key=>"referee_12_qualification", :value=>"Magician"}]}
    content = event.to_content_hash
    content.delete(:post_data)
    assert_equal asserted_content, content
  end

  def test_referee_qa_field_id_recycling
    event = WPEvent::CustomPostTypes::Event.new
    event.add_referee('12', 'Magician')
    #other_event
    asserted_content = { post_type: "ev7l-event",
                         post_status: "publish",
                         post_title: "",
                         post_content: "",
                         custom_fields: [{:key=>"referee_12_qualification", :value=>"Magician"}]}
    content = event.to_content_hash
    content.delete(:post_data)
    assert_equal asserted_content, content
  end
end
