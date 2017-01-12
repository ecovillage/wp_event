require 'test_helper'

class BookCPT < WPEvent::CustomPostType
  wp_post_type "books"
  wp_custom_field_single "num_pages"
  wp_custom_field_single "uuid"
  wp_custom_field_single "price"
  #wp_custom_field_multi  "author_id"
  #wp_custom_field_multi  "author_uuid"
  #wp_title_field "name" # 'alias', some for content
end

class MovieCPT < WPEvent::CustomPostType
  wp_post_type "movies"
  wp_custom_field_single "year"
end

class CPTTest < Minitest::Test
  def test_post_type_dec
    assert_equal "books", BookCPT.post_type
    book = BookCPT.new
    assert_equal "books", book.post_type
  end

  def test_other_post_type_dec
    assert_equal "movies", MovieCPT.post_type
    book = MovieCPT.new
    assert_equal "movies", book.post_type
  end

  def test_title_content_featured_image_id
    book = BookCPT.new content: 'See more inside!', title: 'The first book', featured_image_id: "20"
    assert_equal "The first book",   book.title
    assert_equal "See more inside!", book.content
    assert_equal "20",               book.featured_image_id
  end

  def test_fields
    assert_equal [''], BookCPT.fields
    assert_equal [''], BookCPT.new.fields
    #assert_equal [''], WPEvent::CustomPostType.class_variables
    #assert_equal [''], BookCPT.class_variables
  end

  def test_has_field
    book = BookCPT.new
    assert_equal true,  book.has_custom_field?("uuid")
    assert_equal false, book.has_custom_field?("year")
  end

  def test_custom_field_getter
    book = BookCPT.new
    assert_equal true,  book.respond_to?("uuid")
    assert_equal false, book.respond_to?("year")
  end

  #def test_from_wp_data
  #  old_book_data = { "post_id"     => "1066",    "post_title" => "Typs fr dummis",
  #                    "post_status" => "publish", "post_type"  => "book",
  #                    "post_name"   => "typs-fr-dummis", "post_content" => "",
  #                    "post_thumbnail" => [],
  #                    "custom_fields" => [
  #                      {"id" => "522", "key" => "price", "value" => "12.1"},
  #                      {"id" => "271", "key" => "uuid",  "value" => "1111-2222"},
  #                    ]
  #  }
  #  book = BookCPT.from_wp_data old_book_data
  #end

  def test_field_setting_and_getting
    book = BookCPT.new price: '1'
    assert_equal "1", book.price

    book.price = '2'
    assert_equal "2", book.price
  end

  def test_field_strip
    book = BookCPT.new price: '  Spaces around me  '
    assert_equal "Spaces around me", book.price
  end

  def test_field_makes_string
    book = BookCPT.new price: 12.2
    assert_equal "12.2", book.price
  end

  def test_to_content_hash
    book = BookCPT.new title: 'home', price: '12.2', uuid: '1122'
    content_hash = book.to_content_hash
    content_hash.delete :post_data
    assert_equal({ post_type: 'books', post_status: 'publish',
                   post_title: 'home',
                   custom_fields: [
                     { key: 'price', value: '12.2'},
                     { key: 'uuid', value: '1122' } ]},
                 content_hash)
  end

  def test_custom_fields_hash
    book = BookCPT.new price: '12.2'
    assert_equal([{key: 'price', value: '12.2'}, {key: 'uuid', value: '1122'}],
                 book.custom_fields_hash)
  end

  def test_update
    old_book_data = { "post_id"     => "1066",    "post_title" => "Typs fr dummis",
                      "post_status" => "publish", "post_type"  => "book",
                      "post_name"   => "typs-fr-dummis", "post_content" => "",
                      "post_thumbnail" => [],
                      "custom_fields" => [
                        {"id" => "522", "key" => "price", "value" => "12.1"},
                        {"id" => "271", "key" => "uuid",  "value" => "1111-2222"},
                      ]
    }
    book = BookCPT.new uuid: '1111-2222', title: 'Typos for dummies', price: 12.2
  end

  def test_single_custom_field
    book = BookCPT.new uuid: '1234-4321'
    assert_equal "1234-4321", book.uuid
  end

  def test_content_title_aliases
    # Needs different class. Accept setter and getter
  end

  def test_featured_image_id
    # Needs different class. Accept setter and getter
  end

  # test_multi_custom_field
  # test_update
  # test_metadata_creation
end
