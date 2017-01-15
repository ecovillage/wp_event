module WPEvent
  module CustomPostTypes
    class Referee < CustomPostType
      wp_post_type 'ev7l-referee'
      wp_custom_field_single 'uuid'
      wp_custom_field_single 'firstname'
      wp_custom_field_single 'lastname'

      # Or alias title to full_name ?? With undef and co ...
      def title
        full_name
      end

      def full_name
        "#{firstname} #{lastname}"
      end
    end
  end
end
