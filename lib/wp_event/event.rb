require 'date'
require 'time'

module WPEvent
  module Event

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

    def self.by_post_id post_id
      WPEvent::wp.getPost blog_id: 0,
                          post_id: post_id
    end

    def self.get_all_posts
      WPEvent::wp.getPosts blog_id: 0,
                           filter: { post_type: TYPE , number: 100_000 }
    end

    def self.in_wordpress? uuid
      # TODO extract lambda
      get_all_posts.find {|p| p["custom_fields"].find {|f| f["key"] == "uuid" && f["value"] == uuid}}
    end

    def self.create uuid, name, date_range, text, category_ids=[]
      category_hashes = category_ids.map{|c| {key: 'event_categories', value: c}}
      content = { post_type: TYPE,
                  post_status: "publish",
                  post_data: Time.now,
                  post_content: text,
                  post_title: name,
                  # tags_input ...
                  terms_names: {'language' => ['Deutsch']},
                  custom_fields: [
                      { key: "uuid",     value: uuid },
                      { key: "fromdate", value: date_range.first.to_time.to_i },
                      { key: "todate",   value: date_range.last.to_time.to_i }
                    ] | category_hashes,
                  post_author: 1 }

      #puts content.to_yaml
      WPEvent::wp.newPost(blog_id: 0,
                          content: content)
    end

    def self.fetch_name_pid_map
      get_all_posts.map {|p| [p["post_title"], p["post_id"]]}.to_h
    end
  end
end
