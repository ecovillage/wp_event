module WPEvent

  class MissingCategoryError < StandardError
    attr_accessor :missing_categories
    def initialize msg="Category(es) do(es) not exist", missing_categories
      @missing_categories = missing_categories
      super(msg)
    end
  end

  class MissingRefereeError < StandardError
    attr_accessor :missing_referees
    def initialize msg="Referee(s) do(es) not exist", missing_referees
      @missing_referees = missing_referees
      super(msg)
    end
  end

  class EventSyncer
    include WPEvent::CLI::Logging
    include WPEvent::CLI

    attr_accessor :category_cache, :referee_cache, :media_cache, :image_uploader
    attr_accessor :raise_on_missing_referee

    def initialize category_cache, referee_cache, media_cache, image_uploader, raise_on_missing_referee: true
      @category_cache = category_cache
      @referee_cache  = referee_cache
      @media_cache    = media_cache
      @image_uploader = image_uploader
      @raise_on_missing_referee = raise_on_missing_referee
    end

    def create_or_update wp_event, event_json
      category_ids  = category_ids(event_json)
      referees      = referee_data(event_json)
      maybe_raise_on_missing_referees(event_json, referees)
      attachment_id = @image_uploader.process event_json['image_url']

      if wp_event
        info "Updating event"
        # TODO check timestamps (wp["time modifica....
        WPEvent::EventPost.update wp_event,
                                  event_json["name"],
                                  get_timerange(event_json),
                                  event_json["description"],
                                  category_ids,
                                  referees,
                                  attachment_id
      else
        info "Creating event"
        WPEvent::EventPost.create event_json["uuid"],
                                  event_json["name"],
                                  get_timerange(event_json),
                                  event_json["description"],
                                  category_ids,
                                  referees,
                                  attachment_id
      end
    end

    def maybe_raise_on_missing_referees(event_json, referees)
      # TODO Throw exception instead
      missing_referees = missing_referees(event_json)
      if !missing_referees(event_json).empty?
        missing_referees.each do |ref|
          warn "Referee missing - UUID: #{ref['uuid']}"
        end

        if @raise_on_missing_referee
          # raise MissingRefereeError.new ...
          raise MissingRefereeError.new "Required referee missing", missing_referees
        else
          warn "At least one required referee is missing, but --ignore-missing-referees is set, ignoring ALL referees."
          referees = []
        end
      end
    end

    def referee_data event_json
      return [] if !event_json['referee_qualifications']
      # from {uuid: 1, q: '2'} we need {id: 123, q: '2'}
      event_json["referee_qualifications"].map do |ref_qua|
        { id: @referee_cache.id_of_uuid(ref_qua["uuid"]),
          qualification: ref_qua["qualification"] }
      end
    end

    def missing_referees event_json
      return [] if !event_json["referee_qualifications"]
      missing_referees = event_json["referee_qualifications"].select do |ref_qa|
        @referee_cache.id_of_uuid(ref_qa["uuid"]).to_s == ''
      end
    end

    def category_ids event_json
      ids = @category_cache.id_of_names event_json["category_names"]

      if ids.include?(nil)
        raise MissingCategoryError.new(ids)
      end

      ids
    end

    private
    def get_timerange event_json
      DateTime.parse(event_json["fromdate"])..DateTime.parse(event_json["todate"])
    end
  end
end
