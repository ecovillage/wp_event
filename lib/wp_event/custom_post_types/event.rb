module WPEvent
  module CustomPostTypes
    class Event < CustomPostType
      attr_accessor :referee_id_qualification_map

      wp_post_type 'ev7l-event'
      wp_post_title_alias    'name'
      wp_post_content_alias  'description'
      wp_custom_field_single 'uuid'
      wp_custom_field_single 'fromdate' # Ideally: type: :date, out: :to_i
      wp_custom_field_single 'todate'
      wp_custom_field_multi  'event_category_id'
      wp_custom_field_multi  'referee_id'

      def initialize(**kwargs)
        super(**kwargs)
        @referee_id_qualification_map = {}
      end

      def add_referee(id, qualification)
        @referee_id_qualification_map[id] = qualification
        ref_qa_field_name = "referee_#{id}_qualification"
        @fields[ref_qa_field_name] = CustomFieldValue.new(nil, ref_qa_field_name, qualification)
      end
    end
  end
end
