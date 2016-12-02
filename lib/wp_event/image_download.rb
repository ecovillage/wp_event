module WPEvent
  class ImageDownload
    include WPEvent::CLI::Logging

    attr_accessor :image_store
    attr_accessor :image_source

    def initialize image_store, image_source
      @image_source = image_source
      @image_store  = image_store
    end

    def download! rel_path
      # Downloader.download!
      store_path = File.join(@image_store, rel_path)
      if File.exist?(store_path)
        info "Image file #{rel_path} already present in image store"
      else
        uri = URI.join(@image_source, rel_path)
        info "Downloading image file from #{uri}"
        WPEvent::Downloader::download!(uri, store_path)
        info "Downloaded into #{store_path}"
      end
    end

    def ready?
      return !@image_source.nil? && !@image_store.nil?
    end
  end
end
