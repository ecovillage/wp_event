module WPEvent
  module CustomPostTypes
    class Event < Compostr::CustomPostType
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
      wp_custom_field_single 'other_infos'
      wp_custom_field_single 'costs_participation'
      wp_custom_field_single 'costs_catering'
      wp_custom_field_single 'info_housing'
      wp_custom_field_single 'participants_please_bring'
      wp_custom_field_single 'participants_prerequisites'
      wp_custom_field_single 'registration_needed'
      wp_custom_field_single 'cancel_conditions'


      def initialize(**kwargs)
        super(**kwargs)
        @referee_id_qualification_map = {}
      end

      # override aliased method (why alias_method does not do this job in
      # compostr custom_post_type is yet unclear to me)
      def description=(new_value)
        self.content=(new_value)
      end

      # Strip script tags from content.
      def content=(new_value)
        new_value_unscript = new_value.gsub(/<script.*script>/,'')
        super(new_value_unscript)
      end

      def add_referee(id, qualification)
        @referee_id_qualification_map[id] = qualification
        ref_qa_field_name = "referee_#{id}_qualification"
        @fields[ref_qa_field_name] = Compostr::CustomFieldValue.new(nil, ref_qa_field_name, qualification)
      end

      # TODO Move this in correct way to compostr/custom_post_type.rb
      #
      # Event is using a kind of "has_many :referees" with additional attributes
      # which is not supported by compostr.
      # Example:
      #   event:
      #     referee_id: [22, 33]
      #     referee_22_qualification: 'some text'
      #     referee_33_qualification: 'other text'
      # These additional attributes need to be registered in a Event instance.
      # To complicate issues, due to prior bugs, the additional fields might have
      # multiple values, where they should only have one:
      #   referee_33_qualification: ['old_text', 'new_text']
      # This from_content_hash-implementation tries to remove the 'duplicates'
      # (which can contain multiple different values) while merging in the last.
      def self.from_content_hash content_hash
        entity = super(content_hash)#.from_content_hash(content_hash)
        return entity if entity.nil?

        custom_fields_list = content_hash["custom_fields"] || []

        # Overflow fields are fields not defined as single or multiple
        overflow_fields = custom_fields_list.map{|f| f["key"]} - supported_fields

        # 'duplicate' removal
        ref_qa_field_key_names = overflow_fields.select{|f| f =~ /referee.*qualification/}
        ref_qualification_fields = custom_fields_list.select{|f| ref_qa_field_key_names.include? f["key"]}
        # Map name (e.g. referee_33_qualification) to wordpress field id list (e.g. [1282, 2981])
        ref_qa_field_ids = ref_qualification_fields.inject(Hash.new) {|h,c| (h[c["key"]] ||= []) << c["id"] ; h }
        ref_qa_field_ids.each do |k,i|
          #puts "Field #{k} has #{i.count} values (#{i.inspect})"
          # Remove all but the last
          i[0..-2].each do |id|
            entity.multi_field(k.to_s) << Compostr::DeleteCustomFieldValue.new(id)
          end
        end
        # end of duplicate removal

        # Although these fields are marked "multi" before, until know this
        # does not hurt the implementation
        overflow_fields.each do |f|
          entity.field!(f).id    = custom_fields_list.find{|c| c["key"] == f}["id"]
          entity.field!(f).value = custom_fields_list.find{|c| c["key"] == f}["value"]
        end

        entity
      end
    end
  end
end
