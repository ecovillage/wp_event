module WPEvent
  class EntityCache
    attr_accessor :cpt, :name_id_map

    # TODO make contract on cpt
    def initialize cpt
      @cpt         = cpt
      @name_id_map = nil
      # if !cpt.defined? :fetch_name_pid_map
      #   raise ...
    end

    def id_of_name name
      return [] if name.nil? || name.empty?
      name_id_map[name]
    end

    def id_of_names names
      return [] if names.nil? || names.empty?
      names.map{|name| name_id_map[name]}
    end

    # init and return @name_id_map
    def name_id_map
      if @name_id_map.nil?
        @name_id_map = cpt.send :fetch_name_pid_map
      end
      @name_id_map || {}
    end
  end
end
