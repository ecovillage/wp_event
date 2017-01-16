module WPEvent
  module CustomPostTypes
    class Event < CustomPostType
      wp_post_type 'ev7l-event'
      wp_post_title_alias    'name'
      wp_post_content_alias  'description'
      wp_custom_field_single 'uuid'
      wp_custom_field_single 'fromdate' # Ideally: type: :date, out: :to_i
      wp_custom_field_single 'todate'
      wp_custom_field_multi  'event_category_id'
      wp_custom_field_multi  'referee_id'
    end
  end
end
