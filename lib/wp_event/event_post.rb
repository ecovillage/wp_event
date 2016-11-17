require 'date'
require 'time'

module WPEvent
  module EventPost
    extend WPEvent::PostType

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


    # Create a post of custom post_type in wordpress instance.
    # - name is the title
    # - date_range is a range of two dates (start to end),
    # - text is the content
    # - uuid and category_ids are meta data for relations
    # - referee_qualification is a list of hashes (id, qualification)
    def self.create uuid, name, date_range, text, category_ids=[], referee_qualifications=[], featured_image_id=nil
      category_hashes = category_ids.map{|c| {key: 'event_category_id', value: c}}
      referee_hashes  = referee_qualifications.map do |referee_q|
        [ { key: 'referee_id',
            value: referee_q[:id] },
          { key: "referee_#{referee_q[:id]}_qualification",
            value: referee_q[:qualification] }
        ]
      end.flatten

      content = { post_type:    TYPE,
                  post_status:  "publish",
                  post_data:    Time.now,
                  post_content: text,
                  post_title:   name,
                  # tags_input ...
                  terms_names: {'language' => ['Deutsch']},
                  custom_fields: [
                      { key: "uuid",     value: uuid },
                      { key: "fromdate", value: date_range.first.to_time.to_i },
                      { key: "todate",   value: date_range.last.to_time.to_i }
                    ] | category_hashes,
                  post_author: 1 }
      if featured_image_id
        content["post_thumbnail"] = featured_image_id.to_s
      end

      #puts content.to_yaml
      WPEvent::wp.newPost(blog_id: 0,
                          content: content)
    end

    def self.fetch_name_pid_map
      get_all_posts.map {|p| [p["post_title"], p["post_id"]]}.to_h
    end
  end
end
