require 'date'
require 'time'

module WPEvent
  module RefereePost
    extend PostType

    TYPE = 'ev7l-referee'

    def self.create uuid, firstname, lastname, text, featured_image_id=nil
      if text.nil?
        WPEvent.logger.warn "Description of referee (#{uuid}) is nil! Setting to empty value."
        text = ""
      end

      names = PostMetaData.new firstname: firstname, lastname: lastname

      content = { post_type:    TYPE,
                  post_status:  "publish",
                  post_data:    Time.now,
                  post_content: text || "",
                  post_title:   "#{firstname} #{lastname}",
                  terms_names: {'language' => ['Deutsch']},
                  custom_fields: [
                      { key: "uuid", value: uuid },
                  ] | names.to_custom_fields_hash,
                  post_author: 1 }

      if featured_image_id
        content["post_thumbnail"] = featured_image_id.to_s
      end

      WPEvent::wp.newPost(blog_id: 0,
                          content: content)
    end
  end
end
