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

      referee_hashes = referee_qualification_updates(wp_post, referee_qualifications)

      old_metadata  = WPEvent::PostMetaData.new wp_post

      from_date_cf_ids = old_metadata.ids_for('fromdate')
      to_date_cf_ids   = old_metadata.ids_for('todate')

      # Populate 'time' fields
      time_metadata = WPEvent::PostMetaData.new
      time_metadata.add(from_date_cf_ids.first || '',
                        'fromdate',
                        date_range.first.to_time.to_i)
      time_metadata.add(to_date_cf_ids.first || '',
                        'todate',
                        date_range.last.to_time.to_i)

      # Delete duplicates:
      [*from_date_cf_ids[1..-1]].each do |cf_id|
        time_metadata.add cf_id, nil, nil
      end
      [*to_date_cf_ids[1..-1]].each do |cf_id|
        time_metadata.add cf_id, nil, nil
      end

      content = {
        post_title:    name,
        post_content:  text,
        custom_fields: referee_hashes |
                       category_updates(wp_post, category_ids) |
                       time_metadata.to_custom_fields_hash
      }

      # Filename: old_image_url = wp_post.dig("post_thumbnail", "link")
      #           uri = URI.parse(URI.encode old_image_url)
      #           old_image_filename = File.basename uri.path
      # attachment_id:
      # (If not set, post_thumbnail is an empty array).
      old_attachment_id = wp_post['post_thumbnail'].to_h["attachment_id"]

      if old_attachment_id.to_s != featured_image_id.to_s
        content["post_thumbnail"] = featured_image_id.to_s
      end

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

      old_meta_data = WPEvent::PostMetaData.new wp_event
      old_ref_ids = old_meta_data.fields_with_key('referee_id')

      result_meta_data.merge! old_ref_ids

      old_ref_qs = old_meta_data.fields_with_key_regex(/referee_\d*_qualification/)
      result_meta_data.merge! old_ref_qs

      result_meta_data.to_custom_fields_hash
    end

    def self.category_updates wp_event, category_ids
      result_meta_data = WPEvent::PostMetaData.new

      category_ids.each do |c|
        result_meta_data.add nil, 'event_category_id', c
      end

      old_meta_data = WPEvent::PostMetaData.new wp_event
      old_categories = old_meta_data.fields_with_key('event_category_id')
      result_meta_data.merge! old_categories
      result_meta_data.to_custom_fields_hash
    end
  end
end
