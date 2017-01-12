module WPEvent
  class CustomField
    attr_accessor :id, :key, :value
  end

  # Base class to inherit from for Classes that map to Wordpress
  # Custom Post Types.
  class CustomPostType
    attr_accessor :post_id, :title, :content, :featured_image_id
    # TODO fields later will need meta-meta-data, on an instance basis, too.
    @@fields = []

    def self.wp_post_type(wp_post_type)
      # TODO syntax: define_method("....")

      # Class wide variable (could also be a constant)
      self.class_eval("@@post_type = '#{wp_post_type}'.freeze")
      # Class accessor method
      self.class_eval("def self.post_type; @@post_type; end")
      # Instance accessor method
      self.class_eval("def post_type; @@post_type; end")
    end

    # Defines accessor methods for the field, which will only
    # allow a single value.
    #
    # Note that the accessor only wears strings and automatically strips
    def self.wp_custom_field_single(field_key)
      # def field_key=(new_value)
      #   @field_key = new_value.to_s.strip
      # end
      self.class_eval("def #{field_key.to_s}=(new_value); @#{field_key.to_s} = new_value.to_s.strip; end")
      # def field_key
      #   @field_key
      # end
      self.class_eval("def #{field_key.to_s}; return @#{field_key.to_s}; end")
      # Add field to @@field list
      self.class_eval("(@@fields ||= []) << '#{field_key}'")
    end

    def has_custom_field? field_name
      @@fields.include? field_name
    end

    def initialize **kwargs
      kwargs.each do |k,v|
        if k == :title
          @title = v
        elsif k == :content
          @content = v
        elsif k == :post_id
          @post_id = v
        elsif k == :featured_image_id
          @featured_image_id = v
        # Better: has_custom_field?
        elsif respond_to?(k)
          #puts "respond to #{k}->setting!"
          #puts("#{k}=('#{v}')")
          #self.instance_eval("#{k} = '#{v}'")
          self.send(((k.to_s) + "=").to_sym, v)
          #self.instance_eval "puts 'self.inseval: #{self}'"
        end
      end
    end
  end
end
