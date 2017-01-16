module WPEvent
  # Create an event from an json representation.
  #
  # The JSON data should follow the format as given in README.
  #
  # As event-categories within are referenced by name, a lookup
  # is made (using a Cache).  If a category name is encountered
  # which is not yet registered as Post in Wordpress, a
  # WPEvent::MissingCategoryError is raised.
  class EventFactory
    include WPEvent::CLI::Logging
    include WPEvent::CLI

    attr_accessor :category_cache

    def initialize #image_uploader, raise_on_missing_referee: true
      @category_cache = WPEvent::EntityCache.new(WPEvent::CategoryPost)
    end

    # Modifies event_json!
    def from_json event_json
      # Transform string keys to symbol keys.
      # This **could** be done directly while parsing the json:
      #   x = JSON.parse json, symbolize_names: true
      event_json.keys.each do |key|
        event_json[(key.to_sym rescue key) || key] = event_json.delete(key)
      end

      category_names = event_json.delete :category_names
      category_ids   = category_ids(category_names)

      event_json[:event_category_id] = category_ids
      event_json[:fromdate] = DateTime.parse(event_json[:fromdate]).to_time.to_i
      event_json[:todate]   = DateTime.parse(event_json[:todate]).to_time.to_i

      WPEvent::CustomPostTypes::Event.new **event_json
    end

    private

    # Get wp-ids of event-categories.
    # Raise MissingCategoryError if not found.
    def category_ids category_names
      ids = @category_cache.id_of_names category_names

      if ids.include?(nil)
        raise MissingCategoryError.new(ids)
      end

      ids
    end
  end
end
