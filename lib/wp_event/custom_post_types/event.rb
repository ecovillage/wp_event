module WPEvent
  module CustomPostTypes
    class Event < CustomPostType
      attr_accessor :referee_id_qualification_map

      wp_post_type 'ev7l-event'

      wp_post_title_alias    'name'
      wp_post_content_alias  'description'

      wp_custom_field_multi  'event_category_id'
      wp_custom_field_multi  'referee_id'

      wp_custom_field_single 'uuid'
      wp_custom_field_single 'fromdate' # Ideally: type: :date, out: :to_i
      wp_custom_field_single 'todate'
      wp_custom_field_single 'arrival'
      wp_custom_field_single 'departure'
      wp_custom_field_single 'current_infos'
      wp_custom_field_single 'costs_participation'
      wp_custom_field_single 'costs_catering'
      wp_custom_field_single 'info_housing'
      wp_custom_field_single 'participants_please_bring'
      wp_custom_field_single 'participants_prerequisites'
      wp_custom_field_single 'registration_needed'


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
