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
        { id: @id, key: @key, value: @value || ''}
      else
        { key: @key, value: @value || ''}
      end
    end
  end

  # Base class to inherit from for Classes that map to Wordpress
  # Custom Post Types.
  class CustomPostType
    attr_accessor :post_id, :title, :content, :featured_image_id
    # TODO fields later will need meta-meta-data, on an instance basis, too.
    attr_accessor :fields

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
      #   field('field_key') = new_value.to_s.strip
      # end
      self.class_eval("def #{field_key.to_s}=(new_value); field('#{field_key}').value = new_value.to_s.strip; end")
      # def field_key
      #   field(field_key).value
      # end
      self.class_eval("def #{field_key.to_s}; return field('#{field_key.to_s}').value; end")
      # Add field to @@fields_proto list
      self.class_eval("(@@fields_proto ||= [])")
      self.class_eval("@@fields_proto << '#{field_key}'")
      # Add field to @supported_fields.
      # This is declared in the class, thus a kindof CLASS variable!
      self.class_eval("(@supported_fields ||= []) << '#{field_key}'")
    end

    def self.wp_post_title_alias(title_alias)
      self.class_eval("alias :#{title_alias.to_sym}= :title=")
      self.class_eval("alias :#{title_alias.to_sym}  :title")
    end

    def self.wp_post_content_alias(content_alias)
      self.class_eval("alias :#{content_alias.to_sym}= :content=")
      self.class_eval("alias :#{content_alias.to_sym}  :content")
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
        elsif respond_to?(k.to_sym)
          #puts "respond to #{k}->setting!"
          #puts("#{k}=('#{v}')")
          #self.instance_eval("#{k} = '#{v}'")
          self.send(((k.to_s) + "=").to_sym, v)
          #self.instance_eval "puts 'self.inseval: #{self}'"
        end
      end
    end

    def custom_fields_hash
      @fields.values.map(&:to_hash)
    end

    #def self.fields
    #  self.class.class_variable_get(:@@fields_proto)
    #  #self.class.class_variable_get(:@@fields_proto)
    #end

    def field(field_name)
      @fields[field_name]
    end

    def supported_fields
      self.class.instance_variable_get(:@supported_fields)
    end

    def self.supported_fields
      instance_variable_get(:@supported_fields)
    end

    def self.from_content_hash content_hash
      entity = new(post_id: content_hash["post_id"],
                   content: content_hash["post_content"],
                   title:   content_hash["post_title"])
      custom_fields_list = content_hash["custom_fields"] || []
      supported_fields.each do |field_key|
        field = custom_fields_list.find{|f| f["key"] == field_key}
        if field
          entity.send("#{field_key}=".to_sym, field["value"])
          entity.field(field_key).id = field["id"]
        end
      end
      entity
    end

    def to_content_hash
      content = {
        post_type:     post_type,
        post_status:   'publish',
        post_data:     Time.now,
        post_title:    title    || '', # why does content need '@'?
        post_content:  @content || '',
        custom_fields: @fields.map{|k,v| v.to_hash}
      }
      if featured_image_id
        content[:post_thumbnail] = featured_image_id.to_s
      end
      content
    end

    def integrate_field_ids other_entity
      # new from old
      fields.values.each do |f|
        f.id = other_entity.field(f.key).id
      end

      # old to new
      #other_entity.fields.each do |f|
      #  field(f.key).id = f.id
      #end
    end

    def in_wordpress?
      post_id.to_s != '' && !!post_id
    end
  end
end
