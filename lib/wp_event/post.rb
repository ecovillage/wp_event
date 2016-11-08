require 'date'
require 'time'

module WPEvent
  module Post

    # An event has the following information:
    #   - referee
    #   - description (in post_content)
    #   - start and end date and time
    #   - current actual information
    #   - 'please bring'
    #   - prices
    #   - bookers info
    #   - categories

    TYPE = 'ev7l-event'

    def self.uuid_in_wordpress? uuid
      in_wordpress? uuid
    end

    def self.in_wordpress? uuid
      all_posts = WPEvent::wp.getPosts blog_id: 0,
                                       filter: { post_type: TYPE }
      # TODO extract lambda
      all_posts.find {|p| p["custom_fields"].find {|f| f["key"] == "uuid" && f["value"] == uuid}}
    end

    def self.create uuid, name, date_range, text, category_names=[]
      content = { post_type: TYPE,
                  post_status: "publish",
                  post_data: Time.now,
                  post_content: text,
                  post_title: name,
                  # ids here?
                  #'terms_names' => array('category' => $cats, 'post_tag' => $ts )
                  # tags_input = ["name1", "name2" ... also valid?
                  terms_names: {'category' => ['Seminar'] + category_names, 'language' => ['Deutsch']},
                  # -> terms_names : {category: ['event'], post_tag:  ...
                  # might also be terms_names: {taxonomy_name: ["value-in-taxonomy"] ...
                  custom_fields: [{ key: "uuid", value: uuid}],
                  post_author: 1 }

      #puts content.to_yaml
      WPEvent::wp.newPost(blog_id: 0,
                                content: content)
    end
  end
end
