require 'date'
require 'time'

module WPEvent
  module RefereePost
    extend PostType

    TYPE = 'ev7l-referee'

    def self.create uuid, name, text, featured_image_id=nil
      content = { post_type:    TYPE,
                  post_status:  "publish",
                  post_data:    Time.now,
                  post_content: text,
                  post_title:   name,
                  # tags_input ...
                  terms_names: {'language' => ['Deutsch']},
                  custom_fields: [
                      { key: "uuid", value: uuid },
                    ],
                  post_author: 1 }
      if featured_image_id
        content["post_thumbnail"] = featured_image_id.to_s
      end

      WPEvent::wp.newPost(blog_id: 0,
                          content: content)
    end
  end
end
