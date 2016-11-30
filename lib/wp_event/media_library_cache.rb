module WPEvent
  # Cache name->id for media items
  # pretty wet copy of entitycache. Unclear how to DRY this up.
  # Wordpress apparently lowercases file endings on upload, so this fact
  # is respected in the lookup (only file ending is modified).
  class MediaLibraryCache
    attr_accessor :name_id_map

    def initialize
      @name_id_map = nil
    end

    # return id of given name, initializing the cache
    # if necessary
    def id_of_name name
      return [] if name.nil? || name.empty?
      # Downcase file ending
      name_for_wp = File.basename(name, '.*') + File.extname(name).downcase
      name_id_map[name_for_wp]
    end

    # return array of ids to given names, initializing the cache
    # if necessary
    def id_of_names names
      return [] if names.nil? || names.empty?
      names.map{|name| id_of_name name }
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
