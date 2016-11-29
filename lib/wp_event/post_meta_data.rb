module WPEvent
  CustomField = Struct.new :id, :key, :value

  class PostMetaData
    attr_accessor :fields

    def initialize wp_post=nil
      @fields = (wp_post&.fetch('custom_fields') || []).map do |cf|
        CustomField.new cf['id'], cf['key'], cf['value']
      end
    end

    # Add a custom field
    def add id, key, value
      @fields << CustomField.new(id, key, value)
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

    def fields_with_key_regex key_regex
      @fields.select {|f| f.key =~ key_regex}
    end

    # merges second metadata into self.
    # add empty (except for 'id') fields to mark removal (wp xmlrpc)
    # sets id of old custom field entries
    def merge! old_metadata
      old_metadata.each do |field|
        if f = field_with_key_value(field.key, field.value)
          if f.id
            # Get rid of an encountered duplicate (will delete for empty values)
            add field.id, nil, nil
          else
            # Set the id (change fields value)
            f.id = field.id
          end
        else
          # No entry for this ref yet, delete it!
          add field.id, nil, nil
        end
      end
    end

    def to_custom_fields_hash
      result = @fields.map do |field|
        hsh = {}
        hsh['key']   = field.key if field.key
        hsh['value'] = field.value if field.value
        hsh['id']    = field.id if field.id
        hsh
      end
    end
  end
end
