module WPEvent
  module CustomPostTypes
    class Category < CustomPostType
      wp_post_type 'ev7l-event-category'
      wp_post_title_alias    'name'
      wp_custom_field_single 'uuid'
      wp_post_content_alias  'description'
    end
  end
end

