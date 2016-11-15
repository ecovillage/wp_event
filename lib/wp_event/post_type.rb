module WPEvent
  # Include this module to include a thin layer towards the persistence
  # engine (Wordpress... :) ).
  #
  # Your including class or module needs to specify the TYPE constant.
  module PostType
    # Return all posts (wordpress response) of type.
    def get_all_posts
      WPEvent::wp.getPosts blog_id: 0,
        filter: { post_type: const_get(:TYPE), number: 100_000 }
    end

    # Return wordpress response to getPost.
    def by_post_id post_id
      WPEvent::wp.getPost blog_id: 0,
                          post_id: post_id
    end

    def uuid_in_wordpress? uuid
      in_wordpress? uuid
    end

    def in_wordpress? uuid
      # TODO extract lambda
      get_all_posts.find {|p| p["custom_fields"].find {|f| f["key"] == "uuid" && f["value"] == uuid}}
    end

    def name_pid_map
      get_all_posts.map {|p| [p["post_title"], p["post_id"]]}.to_h
    end

    def uuid_pid_map
      get_all_posts.map do |post|
        # TODO lambda
        uuid = post["custom_fields"].find {|f| f["key"] == "uuid"}&.fetch("value", nil)
        [uuid, post["post_id"]]
      end.to_h
    end
  end
end
