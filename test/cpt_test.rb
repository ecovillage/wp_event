require 'test_helper'

class BookCPT < WPEvent::CustomPostType
  wp_post_type "books"
  wp_custom_field_single "num_pages"
  wp_custom_field_single "uuid"
  wp_custom_field_single "price"
  wp_post_content_alias   "description" # 'alias'
  #wp_custom_field_multi  "author_id"
  #wp_custom_field_multi  "author_uuid"
end

class MovieCPT < WPEvent::CustomPostType
  wp_post_type "movies"
  wp_post_title_alias     "name" # 'alias'
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
    movie = MovieCPT.new
    assert_equal "movies", movie.post_type
  end

  def test_title_content_featured_image_id
    book = BookCPT.new content: 'See more inside!', title: 'The first book', featured_image_id: "20"
    assert_equal "The first book",   book.title
    assert_equal "See more inside!", book.content
    assert_equal "20",               book.featured_image_id
  end

  def test_fields
    assert_equal ['num_pages', 'uuid', 'price'], BookCPT.supported_fields
    assert_equal ['num_pages', 'uuid', 'price'], BookCPT.new.supported_fields
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
    new_book = BookCPT.new title: 'Going home', price: '12.2', uuid: '1122', content: 'back-coming for beginners'
    content_hash = new_book.to_content_hash
    content_hash.delete :post_data
    assert_equal({ post_type:   'books',
                   post_status: 'publish',
                   post_title:  'Going home',
                   post_content:  'back-coming for beginners',
                   custom_fields: [
                     { key: 'price', value: '12.2'},
                     { key: 'uuid', value: '1122' } ]},
                 content_hash)
    book = BookCPT.new title: 'home', price: '12.2', uuid: '1122',
      featured_image_id: '2', post_id: '22'
    content_hash = book.to_content_hash
    content_hash.delete :post_data
    assert_equal({ post_type:    'books',
                   post_status:  'publish',
                   post_title:   'home',
                   post_content: '',
                   post_thumbnail: '2',
                   custom_fields: [
                     { key: 'price', value: '12.2'},
                     { key: 'uuid', value: '1122' } ]},
                 content_hash)
  end

  def test_custom_fields_hash
    book = BookCPT.new price: '12.2', uuid: '1222'
    assert_equal([{key: 'price', value: '12.2'}, {key: 'uuid', value: '1222'}],
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
    old_book = BookCPT.from_content_hash old_book_data
    book = BookCPT.new uuid: '1111-2222', title: 'Typos for dummies', price: "12.2"
    book.integrate_field_ids old_book
    assert_equal "Typos for dummies", book.title
    assert_equal "522", book.field("price").id
    assert_equal "12.2", book.field("price").value
    assert_equal "12.2", book.price
  end

  def test_single_custom_field
    book = BookCPT.new uuid: '1234-4321'
    assert_equal "1234-4321", book.uuid
  end

  def test_title_alias
    movie = MovieCPT.new name: 'The superanimal'
    assert_equal "The superanimal", movie.title
    assert_equal "The superanimal", movie.name

    movie.name = "The superanimal 2"
    assert_equal "The superanimal 2", movie.title
    assert_equal "The superanimal 2", movie.name

    movie.title = "The superanimal 3"
    assert_equal "The superanimal 3", movie.title
    assert_equal "The superanimal 3", movie.name

    movie = MovieCPT.new title: 'The superanimal'
    assert_equal "The superanimal", movie.title
    assert_equal "The superanimal", movie.name
  end

  def test_content_aliases
    book = BookCPT.new description: 'The ultimate superanimal book'
    assert_equal "The ultimate superanimal book", book.description
    assert_equal "The ultimate superanimal book", book.content

    book.description = "The ultimate superanimal book 2"
    assert_equal "The ultimate superanimal book 2", book.description
    assert_equal "The ultimate superanimal book 2", book.content

    book.description = "The ultimate superanimal book 3"
    assert_equal "The ultimate superanimal book 3", book.description
    assert_equal "The ultimate superanimal book 3", book.content

    book = BookCPT.new description: 'The ultimate superanimal book'
    assert_equal "The ultimate superanimal book", book.description
    assert_equal "The ultimate superanimal book", book.content
  end

  def test_change
    book = BookCPT.new uuid: '1234-4321'
  end

  def test_from_content_hash
    content_hash = { "post_id"     => "1066",    "post_title" => "Typs fr dummis",
                     "post_status" => "publish", "post_type"  => "book",
                     "post_name"   => "typs-fr-dummis", "post_content" => "",
                     "post_thumbnail" => [],
                     "custom_fields" => [
                       {"id" => "522", "key" => "price", "value" => "12.1"},
                       {"id" => "271", "key" => "uuid",  "value" => "1111-2222"},
                     ]
    }
    book = BookCPT.from_content_hash content_hash
    assert_equal "1066", book.post_id
    assert_equal "", book.content
    assert_equal "Typs fr dummis", book.title
    assert_equal "12.1", book.price
    assert_equal "522", book.field("price").id
    assert_equal "1111-2222", book.uuid
    # TODO test thumbnail setting: "post_thumbnail" => []
  end

  def test_in_wordpress?
    book = BookCPT.new post_id: "12"
    assert_equal true, book.in_wordpress?
    book = BookCPT.new price: '22.0'
    assert_equal false, book.in_wordpress?
    book = BookCPT.new post_id: ""
    assert_equal false, book.in_wordpress?
  end

  # test_multi_custom_field
  # test_update
end
