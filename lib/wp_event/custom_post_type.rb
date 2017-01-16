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
  #
  # Besides the post_id, title, content and featured_image (id) that
  # define a post, the CustomPostType likely will own custom field
  # values.  These are specified with wp_custom_field_single and wp_custom_field_multi (depending on their type).
  class CustomPostType
    attr_accessor :post_id, :title, :content, :featured_image_id
    # TODO fields later will need meta-meta-data, on an instance basis, too.
    attr_accessor :fields, :multi_fields

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
      self.class_eval("def #{field_key.to_s}=(new_value); field('#{field_key.to_s}').value = new_value.to_s.strip; end")
      # def field_key
      #   field(field_key).value
      # end
      self.class_eval("def #{field_key.to_s}; return field('#{field_key.to_s}').value; end")

      # Add field to @supported_(single_)fields.
      # This is declared in the class, thus a kindof CLASS variable!
      self.class_eval("(@supported_single_fields ||= []) << '#{field_key}'")
    end

    # Specify a field that will make and take a fine array.
    def self.wp_custom_field_multi(field_key)
      # def field_key=(new_value)
      #   multi_field('field_key') = new_value.map{|v| CustomFieldValue.new(nil, 'field_key', v)}
      # end
      # TODO recycle!
      self.class_eval("def #{field_key.to_s}=(new_value); @multi_fields['#{field_key.to_s}'] = new_value.map{|v| CustomFieldValue.new(nil, '#{field_key.to_s}', v)}; end")
      # def field_key
      #   multi_field(field_key).map(&:value)
      # end
      self.class_eval("def #{field_key.to_s}; return multi_field('#{field_key.to_s}').map(&:value); end")

      # Add field to @supported_(multi_)fields.
      # This is declared in the class, thus a kindof CLASS variable!
      self.class_eval("(@supported_multi_fields ||= []) << '#{field_key}'")
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
      supported_fields.include? field_name
    end

    def initialize **kwargs
      @fields = Hash.new
      @fields.default_proc = proc do |hash, key|
        hash[key] = CustomFieldValue.new(nil, key, nil)
      end
      @multi_fields = Hash.new
      @multi_fields.default_proc = proc do |hash, key|
        hash[key] = []
      end
      kwargs.each do |k,v|
        if k == :title
          # strip ?
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

    def field(field_name)
      @fields[field_name]
    end

    def multi_field(field_name)
      @multi_fields[field_name]
    end

    # Returns list of field keys generally supported by this Custom Post Type
    def supported_fields
      self.class.supported_fields
    end

    # Returns list of field keys generally supported by this Custom Post Type
    def self.supported_fields
      supported_single_fields | supported_multi_fields
    end

    def self.supported_single_fields
      instance_variable_get(:@supported_single_fields) || []
    end

    def self.supported_multi_fields
      instance_variable_get(:@supported_multi_fields) || []
    end

    # From a Hash as returned by RubyPress's getPost(s) method
    # populate and return a new CustomPostType-instance.
    def self.from_content_hash content_hash
      entity = new(post_id: content_hash["post_id"],
                   content: content_hash["post_content"],
                   title:   content_hash["post_title"])

      custom_fields_list = content_hash["custom_fields"] || []

      supported_fields.each do |field_key|
        if is_single_field? field_key
          field = custom_fields_list.find{|f| f["key"] == field_key}
          if field
            entity.send("#{field_key}=".to_sym, field["value"])
            entity.field(field_key).id = field["id"]
          end
        else
          fields = custom_fields_list.select{|f| f["key"] == field_key}
          entity.send("#{field_key}=".to_sym, fields.map{|f| f["value"]})
          # TODO get the ids in there!
          #entity.field(field_key).id = field["id"]
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
        custom_fields: @fields.map{|k,v| v.to_hash} | @multi_fields.flat_map{|k,v| v.flat_map(&:to_hash)}
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

    def is_multi_field?(field_name)
      self.class.is_multi_field?(field_name)
    end

    def self.is_multi_field?(field_name)
      supported_multi_fields.include? field_name
    end

    def is_single_field?(field_name)
      self.class.is_single_field?(field_name)
    end

    def self.is_single_field?(field_name)
      supported_single_fields.include? field_name
    end

    def in_wordpress?
      post_id.to_s != '' && !!post_id
    end
  end
end
