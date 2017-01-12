module WPEvent
  class CustomFieldValue
    attr_accessor :id, :key, :value

    def initialize id, key, value
      @id    = id
      @key   = key
      @value = value
    end

    def to_hash
      if @id
        { id: @id, key: @key, value: @value}
      else
        { key: @key, value: @value}
      end
    end
  end

  # Base class to inherit from for Classes that map to Wordpress
  # Custom Post Types.
  class CustomPostType
    attr_accessor :post_id, :title, :content, :featured_image_id
    # TODO fields later will need meta-meta-data, on an instance basis, too.

    def self.wp_post_type(wp_post_type)
      # TODO syntax: define_method("....")

      # Class wide variable (could also be a constant)
      self.class_eval("POST_TYPE = '#{wp_post_type}'.freeze")
      # Class accessor method
      # def self.post_type
      #   POST_TYPE
      # end
      self.class_eval("def self.post_type; POST_TYPE; end")
      # Instance accessor method
      # def post_type
      #   POST_TYPE
      # end
      self.class_eval("def post_type; POST_TYPE; end")
    end

    # Defines accessor methods for the field, which will only
    # allow a single value.
    #
    # Note that the accessor only wears strings and automatically strips
    def self.wp_custom_field_single(field_key)
      # def field_key=(new_value)
      #   @field_key = new_value.to_s.strip
      # end
      self.class_eval("def #{field_key.to_s}=(new_value); field('#{field_key}').value = new_value; @#{field_key.to_s} = new_value.to_s.strip; end")
      # def field_key
      #   @field[field_key].value = new_value
      #   @field_key
      # end
      self.class_eval("def #{field_key.to_s}; return @#{field_key.to_s}; end")
      # Add field to @@field list
      self.class_eval("(@@fields_proto ||= [])")
      self.class_eval("@@fields_proto << '#{field_key}'")
    end

    def has_custom_field? field_name
      self.class.class_variable_get(:@@fields_proto).include? field_name
    end

    def initialize **kwargs
      @fields = Hash.new
      @fields.default_proc = proc do |hash, key|
        hash[key] = CustomFieldValue.new(nil, key, nil)
      end
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

    def custom_fields_hash
      self.class.class_variable_get(:@@fields).map do |field|
        field_sym = field.to_sym
        { key: field_sym, value: send(field_sym) }
      end
    end

    def fields
      @@fields_proto
    end

    def self.fields
      @@fields_proto
    end

    def field(field_name)
      @fields[field_name]
    end

    def to_content_hash
      content = {
        post_type:   post_type,
        post_status: 'publish',
        post_data:   Time.now,
        post_title:  title,
        custom_fields: @fields.map{|k,v| v.to_hash}
      }
    end
  end
end
