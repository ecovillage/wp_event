require 'test_helper'

class BookCPT < WPEvent::CustomPostType
  wp_post_type "books"
  wp_custom_field_single "num_pages"
  wp_custom_field_single "uuid"
  wp_custom_field_single "price"
  wp_post_content_alias  "description" # 'alias'
  wp_custom_field_multi  "author_id"

  additional_field_action :ignore
end

class MovieCPT < WPEvent::CustomPostType
  wp_post_type "movies"
  wp_post_title_alias    "name" # 'alias'
  wp_custom_field_single "year"

  additional_field_action :delete
end

class BoardgameCPT < WPEvent::CustomPostType
  wp_post_type "boardgames"
  wp_post_title_alias    "name" # 'alias'
  wp_custom_field_single "year"

  additional_field_action :add
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

  def test_double_splat_init
    hash = {name: 'Splatter'}
    movie = MovieCPT.new **hash
    assert_equal "Splatter", movie.title

    # Notice this will fail with nasty-to-debug
    # "TypeError: wrong argument type String (expected Symbol)":
    # MovieCPT.new **{ 'name' => 'Splatter' }
  end

  def test_nil_guard_content_hash
    book = BookCPT.new price: nil
    content_hash = book.to_content_hash
    content_hash.delete :post_data
    assert_equal({ post_type:    'books',
                   post_status:  'publish',
                   post_title:   '',
                   post_content: '',
                   custom_fields: [
                     { key: 'price', value: ''},
                   ]},
                 content_hash)
  end

  def test_title_content_featured_image_id
    book = BookCPT.new content: 'See more inside!', title: 'The first book', featured_image_id: "20"
    assert_equal "The first book",   book.title
    assert_equal "See more inside!", book.content
    assert_equal "20",               book.featured_image_id
  end

  def test_fields
    asserted_field_list = ['num_pages', 'uuid', 'price', 'author_id']
    assert_equal asserted_field_list, BookCPT.supported_fields
    assert_equal asserted_field_list, BookCPT.new.supported_fields
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
    # obsolete?
    book = BookCPT.new price: '12.2', uuid: '1222'
    assert_equal([{key: 'price', value: '12.2'}, {key: 'uuid', value: '1222'}],
                 book.custom_fields_hash)
  end

  def test_integrate_field_ids
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

  def test_integrate_field_ids_multi
    old_book_data = { "post_type"  => "book",
                      "custom_fields" => [
                        {"id" => "1", "key" => "author_id", "value" => "12"},
                        {"id" => "2", "key" => "author_id", "value" => "13"},
                      ]
    }
    old_book = BookCPT.from_content_hash old_book_data
    book = BookCPT.new author_id: ['14']
    book.integrate_field_ids old_book

    assert_equal ['14'], book.author_id
    asserted_fields = [{ :id => "1", :key => "author_id", :value => '14' },
                       # following is NOT present: ":key => nil, :value => '" to mark deletion
                       { :id => "2"}
    ]
    assert_equal asserted_fields, book.multi_field("author_id").map(&:to_hash)
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

  def test_from_content_hash_nil
    content_hash = nil
    book = BookCPT.from_content_hash content_hash
    assert_nil nil, book
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

  def test_is_multi_field?
    book = BookCPT.new post_id: ""
    assert_equal true, BookCPT.is_multi_field?('author_id')
    assert_equal true, book.is_multi_field?('author_id')
    assert_equal false, BookCPT.is_multi_field?('price')
    assert_equal false, book.is_multi_field?('price')
    assert_equal false, BookCPT.is_multi_field?('miles')
    assert_equal false, book.is_multi_field?('miles')
  end

  def test_is_single_field?
    book = BookCPT.new post_id: ""
    assert_equal true, BookCPT.is_single_field?('price')
    assert_equal true, book.is_single_field?('price')
    assert_equal false, BookCPT.is_single_field?('author_id')
    assert_equal false, book.is_single_field?('author_id')
    assert_equal false, BookCPT.is_single_field?('miles')
    assert_equal false, book.is_single_field?('miles')
  end

  def test_multi_custom_field
    book = BookCPT.new author_id: [1,2,3]
    assert_equal [1,2,3], book.author_id
    assert_equal(
      [{key: 'author_id', value: 1},
       {key: 'author_id', value: 2},
       {key: 'author_id', value: 3},
      ], book.to_content_hash[:custom_fields])
  end

  def test_multi_custom_field_from_hash
    content_hash = { "post_id"     => "1066", "post_title" => "Typs fr dummis",
                     "post_type"  => "book",
                     "custom_fields" => [
                       {"id" => "522", "key" => "author_id", "value" => "HansenID"},
                       {"id" => "271", "key" => "author_id", "value" => "JohnsonID"},
                     ]
    }
    book = BookCPT.from_content_hash content_hash
    assert_equal ["HansenID", "JohnsonID"], book.author_id
  end

  def test_set_field_id
    content_hash = { "post_title" => "Typs fr dummis", "post_type"  => "book",
                     "custom_fields" => [
                       {"id" => "522", "key" => "author_id", "value" => "12"},
                       {"key" => "author_id", "value" => "13"},
                     ]
    }
    book = BookCPT.from_content_hash content_hash
    assert_equal "522", book.multi_field("author_id")[0].id
    assert_equal nil,   book.multi_field("author_id")[1].id

    book.set_field_id("author_id", "12", "912")
    assert_equal "912", book.multi_field("author_id")[0].id
    assert_equal nil,   book.multi_field("author_id")[1].id
  end

  def test_additional_field_action_add
    dungeonlord = BoardgameCPT.new
    assert dungeonlord.additional_field_action == :add

    space_alert = BoardgameCPT.new fun: 'extreme'
    assert_equal 'extreme', space_alert.field(:fun).value

    space_alert.field(:fun).id = 10
    dungeonlord.integrate_field_ids space_alert
    assert_equal 'extreme', dungeonlord.field(:fun).value
    assert_equal 10,        dungeonlord.field(:fun).id
  end
end
