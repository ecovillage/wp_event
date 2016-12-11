module WPEvent
  CustomField = Struct.new :id, :key, :value

  class PostMetaData
    attr_accessor :fields

    def initialize wp_post=nil, **kvargs
      @fields = (wp_post&.fetch('custom_fields') || []).map do |cf|
        CustomField.new cf['id'], cf['key'], cf['value']
      end
      kvargs.each do |k,v|
        add nil, k, v
      end
    end

    # Add and return a custom field
    def add id, key, value
      new_field = CustomField.new(id, key, value)
      @fields << new_field
      new_field
    end

    # true iff multiple values for key found
    def multivalued? field_key
      @fields.count {|f| f.key == field_key} > 1
    end

    # maps all values with given key
    def values field_key
      fields_with_key(field_key).map &:value
    end

    # returns fields with given key
    def fields_with_key field_key
      @fields.select {|f| f.key == field_key}
    end

    # return FIRST field with given k/v pair
    def field_with_key_value field_key, field_value
      @fields.first {|f| f.key == field_key && f.value == field_value}
    end

    # returns field id for first field with given key
    def id_for field_key
      @fields.first {|f| f.key == field_key}&.id
    end

    # Return array of field ids for fields with given key
    def ids_for field_key
      fields_with_key(field_key).map &:id
    end

    def fields_with_key_regex key_regex
      @fields.select {|f| f.key =~ key_regex}
    end

    # Returns field with given id (nil if none found)
    def field_for id
      @fields.first {|f| f.id == id}
    end

    # Returns field with given id (create new if none found)
    # if none found, the given field is initialized with nil
    # values such that it will be 'deleted' if not populated.
    def field_or_create_for id
      field_for(id) || add(id, nil, nil)
    end

    # Update or create given field (identified by key)
    def update_or_create key, value
      field = fields_with_key(key).first
      (field || add(nil, key, value)).value = value
    end

    # Mark field with given id for deletion by setting key, value to nil
    def mark_for_deletion! field_id
      field = field_or_create_for(field_id)
      field.value  = nil
      field.key    = nil
    end

    # merges second metadata into self.
    # add empty (except for 'id') fields to mark removal (wp xmlrpc)
    # sets id of old custom field entries
    def merge! old_metadata
      old_metadata.each do |field|
        if f = field_with_key_value(field.key, field.value)
          if f.id
            # Get rid of an encountered duplicate (will delete for empty values)
            mark_for_deletion! field.id
          else
            # Set the id (change fields value)
            f.id = field.id
          end
        else
          # No entry for this ref yet, delete it!
          mark_for_deletion! field.id
        end
      end
    end

    def to_custom_fields_hash
      result = @fields.map do |field|
        hsh = {}
        hsh['key']   = field.key.to_s   if field.key
        hsh['value'] = field.value.to_s if field.value
        hsh['id']    = field.id         if field.id
        hsh
      end
    end
  end
end
