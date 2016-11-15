module WPEvent
  module CategoryPost
    extend PostType

    # An category has the following information:
    #   - description (in post_content)

    TYPE = 'ev7l-event-category'

    def self.create uuid, name, text, attachment_id=nil
      # TODO these might be helpful and are overly verbose, extract
      if name.nil?
        WPEvent.logger.warn "Name of category (#{uuid}) is nil! Setting to empty value."
        name = ""
      end
      if text.nil?
        WPEvent.logger.warn "Description of category (#{uuid}) is nil! Setting to empty value."
        text = ""
      end
      content = { post_type:    TYPE,
                  post_status:  "publish",
                  post_data:    Time.now,
                  post_content: text || "",
                  post_title:   name || "",
                  # ids here?
                  #'terms_names' => array('category' => $cats, 'post_tag' => $ts )
                  # tags_input = ["name1", "name2" ... also valid?
                  # THIS was working: terms_names: {'event-category-7l' => ['Seminar'] + category_names, 'language' => ['Deutsch']},
                  terms_names: {'language' => ['Deutsch']},
                  # -> terms_names : {category: ['event'], post_tag:  ...
                  # might also be terms_names: {taxonomy_name: ["value-in-taxonomy"] ...
                  custom_fields: [{ key: "uuid", value: uuid}],
                  post_author: 1 }

      if attachment_id
        content[:post_thumbnail] = attachment_id
      end

      WPEvent::wp.newPost(blog_id: 0,
                          content: content)
    end

    def self.add_event event_pid, event_category_pid
      category = self.by_post_id event_category_pid
      event_data = category["custom_fields"].select{|f| f["key"] = 'event_ids'}
      event_ids = event_data.map{|d| d["value"]}
      if event_ids.include? event_pid.to_s
        true
      else
        WPEvent::wp.editPost blog_id: 0,
                             post_id: event_category_pid,
                             content: { custom_fields: [key: 'events', value: event_pid.to_s]}
      end
    end
  end
end
