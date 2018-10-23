module WPEvent
  module LegacyGlue
    class RefereeSync
      include WPEvent::CLI::Logging
      include WPEvent::CLI
      include WPEvent::CLI::Tool

      attr_accessor :referee_cache
      attr_accessor :media_cache
      attr_accessor :image_uploader
      attr_accessor :syncer

      def initialize referee_cache=Compostr::EntityCache.new(
                                     WPEvent::CustomPostTypes::Referee),
                     media_cache=Compostr::MediaLibraryCache.new,
                     image_uploader=Compostr::ImageUploader.new(nil, media_cache)
        @referee_cache  = referee_cache
        @media_cache    = media_cache
        @image_uploader = image_uploader
        @syncer         = Compostr::Syncer.new image_uploader
      end

      def sync referees=[]
        referees.each_with_index do |referee, idx|
          wp_referee = referee_cache.in_mem_lookup(referee["uuid"])
        
          info "(#{idx + 1}/#{referees.length}): Processing referee with uuid #{referee['uuid']}"
        
          # Transform string keys to symbol keys.
          # This **could** be done directly while parsing the json:
          #   x = JSON.parse json, symbolize_names: true
          referee.keys.each do |key|
            referee[(key.to_sym rescue key) || key] = referee.delete(key)
          end
        
          debug "Referee from cache: #{wp_referee}"
        
          referee_cpt_instance = WPEvent::CustomPostTypes::Referee.new(**referee)
        
          attachment_id = image_uploader.process(referee[:image_url])
          referee_cpt_instance.featured_image_id = attachment_id
        
          syncer.merge_push referee_cpt_instance, WPEvent::CustomPostTypes::Referee.from_content_hash(wp_referee)
        end
        
        debug "Finished referee sync (#{WPEvent::VERSION})"
      end

    end
  end
end
