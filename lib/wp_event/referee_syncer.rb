module WPEvent
  class RefereeSyncer
    include WPEvent::CLI::Logging

    attr_accessor :media_cache, :image_uploader

    def initialize media_cache, image_uploader
      @media_cache    = media_cache
      @image_uploader = image_uploader
    end

    def create_or_update wp_referee, referee_json
      attachment_id = @image_uploader.process referee_json['image_url']

      if wp_referee
        info "Referee with UUID #{referee_json['uuid']} found, updating"
        WPEvent::RefereePost.update wp_referee,
                                    referee_json["firstname"],
                                    referee_json["lastname"],
                                    referee_json["description"],
                                    attachment_id
      else
        info "Referee with UUID #{referee_json['uuid']} not found, creating"
        wp_referee = WPEvent::RefereePost.create referee_json["uuid"],
                                                 referee_json["firstname"],
                                                 referee_json["lastname"],
                                                 referee_json["description"],
                                                 attachment_id
      end
    end

    def self.create_or_update wp_referee, referee_json
      # if wp_referee
      #   info "Referee with UUID #{referee['uuid']} found."
      #   if is_newer?
      # else
      #   check if update
      #   info ...
      # end
      #return what
      # when and where to check modification date
      # when and where to delete when not in whitelist
    end
  end
end
