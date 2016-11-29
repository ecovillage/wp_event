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

    def self.update wp_post, name, date_range, text,
                    category_ids=[], referee_qualifications=[],
                    featured_image_id=nil

      # TODO image, categories, date range ....
      referee_hashes = referee_qualification_updates(wp_post, referee_qualifications)

      content = {
        post_title:   name,
        post_content: text,
        custom_fields: referee_hashes

      WPEvent::wp.editPost(blog_id: 0,
                           post_id: wp_post['post_id'],
                           content: content)
    end


    # Compare referee and qualification data from wordpress with given absolute values.
    # Results in the needed arguments for editPost to set the correct referee and qualification data
    # - referee_qualification is a list of hashes (id, qualification)
    def self.referee_qualification_updates wp_event, referee_qualifications
      # Populate with data which we want to have
      result_meta_data = WPEvent::PostMetaData.new

      referee_qualifications.each do |ref_q|
        result_meta_data.add nil, 'referee_id', ref_q[:id]
        result_meta_data.add nil, "referee_#{ref_q[:id]}_qualification", ref_q[:qualification]
      end

      meta_data = WPEvent::PostMetaData.new wp_event
      meta_data.fields_with_key('referee_id').each do |field|
        if rf = result_meta_data.field_with_key_value(field.key, field.value)
          if rf.id
            # Get rid of an encountered duplicate (will delete for empty values)
            result_meta_data.add field.id, nil, nil
          else
            # Set the id (change fields value)
            rf.id = field.id
          end
        else
          # No entry for this ref yet, delete it!
          result_meta_data.add field.id, nil, nil
        end
      end

      meta_data.fields_with_key_regex(/referee_\d*_qualification/).each do |field|
        if rf = result_meta_data.fields_with_key(field.key).first
          if rf.id
            # Get rid of an encountered duplicate (will delete for empty values)
            result_meta_data.add field.id, nil, nil
          else
            # Set the id (change fields value)
            rf.id = field.id
          end
        else
          # No entry for this ref yet, delete it!
          result_meta_data.add field.id, nil, nil
        end
      end

      result_meta_data.to_custom_fields_hash
    end
  end
end
