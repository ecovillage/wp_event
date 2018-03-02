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
    include WPEvent::CLI
    include WPEvent::CLI::Tool

    attr_accessor :category_cache, :referee_cache, :raise_on_missing_referee

    def initialize raise_on_missing_referee: true
      @category_cache = Compostr::EntityCache.new(WPEvent::CustomPostTypes::Category)
      @referee_cache  = Compostr::EntityCache.new(WPEvent::CustomPostTypes::Referee)
      @raise_on_missing_referee = raise_on_missing_referee
    end

    # Modifies event_json!
    def from_json event_json
      # Transform string keys to symbol keys.
      # This **could** be done directly while parsing the json:
      #   x = JSON.parse json, symbolize_names: true
      event_json.keys.each do |key|
        event_json[(key.to_sym rescue key) || key] = event_json.delete(key)
      end

      # Dealingn with legacy stuff, this is a workaround the old legacy stuff.
      # Sometimes category-names are still a string-encoded array (and not an Array).
      # Thus we run through a second JSON-parsing step here.
      category_names = event_json.delete :category_names
      category_ids   = category_ids(JSON.parse category_names.to_s)

      event_json[:event_category_id] = category_ids
      event_json[:fromdate] = DateTime.parse(event_json[:fromdate]).to_time.to_i rescue ''
      event_json[:todate]   = DateTime.parse(event_json[:todate]).to_time.to_i rescue ''

      ref_data = referee_data(event_json)
      referee_ids = ref_data.map{|k,v| v[:id]}.compact
      missing_referee_uuids = ref_data.values.select{|v| v[:id].nil?}.map{|v| v[:uuid]}

      if !missing_referee_uuids.empty?
        if @raise_on_missing_referee
          raise MissingRefereeError.new "Required referee missing", missing_referee_uuids
        else
          warn "Required referee missing #{missing_referee_uuids}"
        end
      end

      event_json[:referee_id] = referee_ids

      event = WPEvent::CustomPostTypes::Event.new **event_json
      ref_data.values.select{|v| !v[:id].nil?}.each do |v|
        event.add_referee(v[:id], v[:qualification])
      end

      event
    end

    private

    # from {uuid: 1, q: '2'} we will get
    # { 1 => {uuid: 1, id: 123, q: '2'} }
    def referee_data event_json
      return {} if !event_json[:referee_qualifications]
      # from {uuid: 1, q: '2'} we need {id: 123, q: '2'}
      data = {}
      event_json[:referee_qualifications].each do |rq|
        uuid = rq["uuid"]
        data[uuid] = { uuid: uuid,
                       id: @referee_cache.id_of_uuid(uuid),
                       qualification: rq["qualification"] }
      end
      data
    end

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
