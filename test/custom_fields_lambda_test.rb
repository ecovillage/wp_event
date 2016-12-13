require 'test_helper'

class LamdaTest < Minitest::Test
  # also need a lambda to pick the customfield hash (from array with given key

  def test_me
    posts = [{id: 1, "custom_fields" => [{"key" => "field",
                                          "value" => "vvalue",
                                          "id" => "vid"},
                                         {"key" => "uuid",
                                          "value" => "1234",
                                          "id" => "2"}]},
             {id: 2, "custom_fields" => [{"key" => "field",
                                          "value" => "vvalue2",
                                          "id" => "vid2"}]},
             {id: 3, "custom_fields" => [{"key" => "uuid",
                                          "value" => "abcd",
                                          "id" => "2"}]}
    ]
    p = posts.find &WPEvent::Lambdas.with_cf_uuid('1234')

    assert_equal(posts[0], p)
  end
end
