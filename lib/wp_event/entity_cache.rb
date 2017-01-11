module WPEvent
  class EntityCache
    attr_accessor :cpt, :name_id_map, :uuid_id_map
    attr_accessor :full_data

    # cpt has to be a WPEvent::PostType extending class/module
    def initialize cpt
      @cpt         = cpt
      @name_id_map = nil
      @uuid_id_map = nil
      if !cpt.is_a? WPEvent::PostType
        raise "Unsupported Entity for EntityCache: #{cpt.class}"
      end
    end

    def in_mem_lookup uuid
      @full_data ||= cpt.get_all_posts
      @full_data.find &WPEvent::Lambdas.with_cf_uuid(uuid)
    end

    def id_of_name name
      return [] if name.nil? || name.empty?
      name_id_map[name]
    end

    def id_of_names names
      return [] if names.nil? || names.empty?
      names.map{|name| name_id_map[name]}
    end

    def id_of_uuid uuid
      return [] if uuid.nil? || uuid.empty?
      uuid_id_map[uuid]
    end

    def id_of_uuids uuids
      return [] if uuids.nil? || uuids.empty?
      uuids.map{|uuid| id_of_uuid uuid}
    end

    # init and return @name_id_map
    def name_id_map
      if @name_id_map.nil?
        @name_id_map = cpt.name_pid_map
      end
      @name_id_map || {}
    end

    def uuid_id_map
      if @uuid_id_map.nil?
        @uuid_id_map = cpt.uuid_pid_map
      end
      @uuid_id_map || {}
    end
  end
end
