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

    def self.update wp_post, firstname, lastname, text, featured_image_id=nil
      if text.nil?
        WPEvent.logger.warn "Description of referee (#{uuid}) is nil! Setting to empty value."
        text = ""
      end

      # Name change not yet supported
      metadata = WPEvent::PostMetaData.new wp_post: wp_post
      metadata.update_or_create "firstname", firstname
      metadata.update_or_create "lastname",  lastname
      puts metadata.to_yaml

      content = { post_content: text || "",
                  post_title:   "#{firstname} #{lastname}",
                  custom_fields: metadata.to_custom_fields_hash
      }

      old_attachment_id = wp_post['post_thumbnail'].to_h["attachment_id"]

      if old_attachment_id.to_s != featured_image_id.to_s
        content["post_thumbnail"] = featured_image_id.to_s
      end

      WPEvent::wp.editPost(blog_id: 0,
                           post_id: wp_post['post_id'],
                           content: content)
    end
  end
end
