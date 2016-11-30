module WPEvent
  # Cache name->id for media items
  # pretty wet copy of entitycache. Unclear how to DRY this up.
  class MediaLibraryCache
    attr_accessor :name_id_map

    def initialize
      @name_id_map = nil
    end

    # return id of given name, initializing the cache
    # if necessary
    def id_of_name name
      return [] if name.nil? || name.empty?
      name_id_map[name]
    end

    # return array of ids to given names, initializing the cache
    # if necessary
    def id_of_names names
      return [] if names.nil? || names.empty?
      names.map{|name| name_id_map[name]}
    end

    # init and return @name_id_map
    def name_id_map
      if @name_id_map.nil?
        @name_id_map = create_name_id_map
      end
      @name_id_map || {}
    end

    private
    def create_name_id_map
      items = WPEvent::wp.getMediaLibrary(blog_id: 0)

      items.map do |i|
        uri = URI.parse URI.encode(i['link'])
        filename = File.basename uri.path

        [filename, i['attachment_id']]
      end.to_h
    end
  end
end
