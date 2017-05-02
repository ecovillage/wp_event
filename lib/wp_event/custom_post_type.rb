module WPEvent
  # Describe a Custom Field Value with optionally an id (corresponding to the WordPress data).
  class CustomFieldValue
    attr_accessor :id, :key, :value

    def initialize id, key, value
      @id    = id
      @key   = key
      @value = value
    end

    # Convert to hash that is consumable by RubyPress/Wordpress.
    # Important that neither key nor value are present for custom field
    # values that should be *deleted* in wordpress instance.
    def to_hash
      if @id
        hsh = { id: @id }
        hsh[:key]   = @key if @key
        hsh[:value] = @value if @value
        hsh
      else
        hsh = {}
        hsh[:key]   = @key if @key
        hsh[:value] = @value if @value
        hsh
      end
    end
  end

  # CustomField NullValue Object.
  class NullCustomFieldValue
    def id; nil; end
    def key; nil; end
    def value; nil; end
  end

  # Base class to inherit from for Classes that map to Wordpress
  # Custom Post Types.
  #
  # Besides the post_id, title, content and featured_image (id) that
  # define a post, the CustomPostType likely will own custom field
  # values.  These are specified with wp_custom_field_single and wp_custom_field_multi (depending on their type).
  #
  # To loop over the fields, use @fields and @multi_fields.
  class CustomPostType
    attr_accessor :post_id, :title, :content, :featured_image_id
    # TODO rename to single_fields?
    attr_accessor :fields, :multi_fields

    # Define accessor method to the POST_TYPE (Class#post_type and
    # Instance#post_type).
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
      #   field!('field_key') = new_value.to_s.strip
      # end
      self.class_eval("def #{field_key.to_s}=(new_value); field!('#{field_key.to_s}').value = new_value.to_s.strip; end")
      # def field_key
      #   field?(field_key).value
      # end
      self.class_eval("def #{field_key.to_s}; return field?('#{field_key.to_s}').value; end")

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
      #   multi_field(field_key).map(&:value).compact
      # end
      self.class_eval("def #{field_key.to_s}; return multi_field('#{field_key.to_s}').map(&:value).compact; end")

      # Add field to @supported_(multi_)fields.
      # This is declared in the class, thus a kindof CLASS variable!
      self.class_eval("(@supported_multi_fields ||= []) << '#{field_key}'")
    end

    # Alias the post_title getter and setter with another 'name'.
    def self.wp_post_title_alias(title_alias)
      self.class_eval("alias :#{title_alias.to_sym}= :title=")
      self.class_eval("alias :#{title_alias.to_sym}  :title")
    end

    # Alias the post_content getter and setter with another 'name'.
    def self.wp_post_content_alias(content_alias)
      self.class_eval("alias :#{content_alias.to_sym}= :content=")
      self.class_eval("alias :#{content_alias.to_sym}  :content")
    end

    # This is an instance variable for the Class (not for instances of it)!
    @additional_field_action = :ignore

    # Define whether additional custom fields should be
    #   :ignore -> ignored (default)
    #   :delete -> marked for deletion
    #   :add    -> added
    # Other values for action will silently be ignored.
    def self.additional_field_action(action)
      if [:ignore, :delete, :add].include? action.to_sym
        # @additional_field_action = :action
        self.class_eval("@additional_field_action = :#{action}")
      end
    end

    def additional_field_action
      self.class.instance_variable_get(:@additional_field_action) || :ignore
    end

    def initialize **kwargs
      @fields = Hash.new
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
          self.send(((k.to_s) + "=").to_sym, v)
        elsif additional_field_action == :add
          @fields[k.to_sym] = CustomFieldValue.new(nil, k.to_sym, v)
        end
      end
    end

    def custom_fields_hash
      @fields.values.map(&:to_hash)
    end

    # Access the given field, returns a NullCustomFieldValue if not found.
    # The NullCustomFieldValue does not accept setting any values and
    # returns nil for id, key and value.
    #
    # Use this to (readonly) access a field with given name.
    def field?(field_name)
      if @fields.key? field_name
        @fields[field_name]
      else
        NullCustomFieldValue.new
      end
    end

    # Access (or create) a CustomFieldValue that can hold a single value.
    def field!(field_name)
      # ||= would probably do, too.
      if @fields.key? field_name
        @fields[field_name]
      else
        @fields[field_name] = CustomFieldValue.new(nil, field_name, nil)
      end
    end

    # Access a CustomFieldValue that can hold multiple values (array).
    def multi_field(field_name)
      @multi_fields[field_name]
    end

    # Returns list of field keys generally supported by this Custom Post Type.
    def supported_fields
      self.class.supported_fields
    end

    # Returns list of field keys generally supported by this Custom Post Type.
    def self.supported_fields
      supported_single_fields | supported_multi_fields
    end

    # Returns list of single-valued field keys generally supported
    # by this Custom Post Type.
    def self.supported_single_fields
      instance_variable_get(:@supported_single_fields) || []
    end

    # Returns list of multiple-valued field keys generally supported
    # by this Custom Post Type.
    def self.supported_multi_fields
      instance_variable_get(:@supported_multi_fields) || []
    end

    # True iff supported fields include field_name
    def has_custom_field? field_name
      supported_fields.include? field_name
    end

    # From a Hash as returned by RubyPress's getPost(s) method
    # populate and return a new CustomPostType-instance.
    #
    # Custom field values will be created as specified by
    # the wp_custom_field_single/multi definitions.
    def self.from_content_hash content_hash
      return nil if content_hash.nil?
      entity = new(post_id: content_hash["post_id"],
                   content: content_hash["post_content"],
                   title:   content_hash["post_title"])

      custom_fields_list = content_hash["custom_fields"] || []

      supported_fields.each do |field_key|
        if is_single_field? field_key
          field = custom_fields_list.find{|f| f["key"] == field_key}
          if field
            entity.send("#{field_key}=".to_sym, field["value"])
            entity.field?(field_key).id = field["id"]
          end
        else
          fields = custom_fields_list.select{|f| f["key"] == field_key}
          values = fields.map{|f| f["value"]}
          entity.send("#{field_key}=".to_sym, values)
          # Not elegant: Set the id one per one
          fields.each do |f|
            entity.set_field_id(field_key, f["value"], f["id"])
          end
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

    # When additional_field_action == :ignore (the default) sets (wp) ids
    # of fields for which values are set.
    #
    # If additional_field_action == :add CustomFieldValues of other_entity are
    # copied if not yet existing in this entity (otherwise only the id of
    # the fields are set.
    #
    # Finally, if additional_field_action == :delete , mark the fields which
    # are NOT set in this entity but in the other entity ready for deletion.
    #
    # The ids are taken from other_entity (if available, left empty otherwise).
    def integrate_field_ids other_entity
      # TODO rename and/or restructure this method
      # new from old
      fields.values.each do |f|
        f.id = other_entity.field?(f.key).id
      end

      if additional_field_action == :add
        # old to new
        other_entity.fields.values.each do |f|
          if !@fields.key?(f.key)
            @fields[f.key] = f
          end
        end
      elsif additional_field_action == :delete
        other_entity.fields.values.each do |f|
          if !@fields.key?(f.key)
            # This field will be deleted when used to edit Post
            @fields[f.key] = CustomFieldValue.new(f.id, nil, nil)
          end
        end
      end

      @multi_fields.each do |field_name, mf|
        ids = other_entity.multi_field(field_name).map(&:id)
        mf.each do |mf_entry|
          mf_entry.id = ids.delete_at(0) # keep order, use #pop otherwise
        end
        # If any ids left, delete these custom fields
        ids.each do |id|
          multi_field(field_name) << CustomFieldValue.new(id, nil, nil)
        end
      end
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

    def set_field_id field_key, field_value, field_id
      if is_single_field? field_key
        # ????!! field!
        field?(field_key).id = field_id
      else
        multi_field(field_key).find{|f| f.key == field_key && f.value == field_value}.id = field_id
      end
    end

    # Returns hash where keys are field names where the values differ.
    # values of returned hash are arrays like
    # [own_value, other_different_value].
    # Returns empty hash to signalize equaliness.
    def diff(other_cpt_object)
      diff_fields = {}
      # Fields exclusive to this one.
      (@fields.keys - other_cpt_object.fields.keys).each do |f|
        diff_fields[f] = [@fields[f].value, nil]
      end
      # Fields exclusive to the other.
      (other_cpt_object.fields.keys - @fields.keys).each do |f|
        diff_fields[f] = [nil, other_cpt_object.fields[f].value]
      end
      # Mutual fields
      (@fields.keys | other_cpt_object.fields.keys).each do |f|
        field_value = field?(f).value
        other_field_value = other_cpt_object.field?(f).value
        if other_field_value != field_value
          diff_fields[f] = [field_value, other_field_value]
        end
      end
      # Multi-Fields exclusive to this one.
      (@multi_fields.keys - other_cpt_object.multi_fields.keys).each do |f|
        diff_fields[f] = [@multi_fields[f].value, nil]
      end
      # Multi-Fields exclusive to the other.
      (other_cpt_object.multi_fields.keys - @multi_fields.keys).each do |f|
        diff_fields[f] = [nil, other_cpt_object.multi_fields[f].value]
      end
      # Mutual Multi-fields
      (@multi_fields.keys | other_cpt_object.multi_fields.keys).each do |f|
        field_values = multi_field(f).map(&:value).compact
        other_field_values = other_cpt_object.multi_field(f).map(&:value).compact
        if other_field_values != field_values
          diff_fields[f] = [field_values, other_field_values]
        end
      end
      diff_fields
    end
  end
end
