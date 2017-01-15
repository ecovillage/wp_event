module WPEvent
  # Magically syncs custom posts between json, intermediate representation
  # or other forms with data in wordpress. Scary API award.
  class Syncer
    include WPEvent::CLI::Logging

    attr_accessor :image_uploader

    def initialize image_uploader
      @image_uploader = image_uploader
    end

    # merge and sync ...!
    # TODO json: new or old? symbols or strings?
    def create_or_update custom_post, json
      if custom_post.in_wordpress?

        info "#{custom_post.class.name} with UUID #{custom_post.uuid} found, updating"

        # Symbolize the keys here?
        new_entity = custom_post.class.new(**json)
        new_entity.integrate_field_ids custom_post
        content = new_entity.to_content_hash
        content[:term_names]  = { 'language' => ['Deutsch'] }
        content[:post_author] = 1

        # ... ! keys of json symbolized?
        attachment_id = @image_uploader.process json['image_url']
        new_entity.featured_image_id = attachment_id

        debug "Updating post with id #{custom_post.post_id}"
        debug "Content is: #{content}"
        debug "Old entity: #{custom_post.to_s}"

        WPEvent::wp.editPost(blog_id: 0,
                             post_id: custom_post.post_id,
                             content: content)
      else
        # Create
        info "#{custom_post.class.name} with UUID #{custom_post.uuid} not found, creating"
        content = custom_post.to_content_hash
        content[:term_names]  = { 'language' => ['Deutsch'] }
        content[:post_author] = 1

        attachment_id = @image_uploader.process json['image_url']
        custom_post.featured_image_id = attachment_id

        debug "Create Post with wp-content: #{content}"

        WPEvent::wp.newPost(blog_id: 0,
                            content: content)
      end
    end
  end
end
