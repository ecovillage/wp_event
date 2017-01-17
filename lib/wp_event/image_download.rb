module WPEvent
  class ImageDownload
    include WPEvent::CLI::Logging
    include WPEvent::CLI

    attr_accessor :image_store
    attr_accessor :image_source

    def initialize image_store, image_source
      @image_source = image_source
      @image_store  = image_store
      # We will URI.join later, which will treat non trailing-slash
      # URLs as non-paths.
      if @image_source && !@image_source.empty? && @image_source[-1] != '/'
        @image_source += '/'
      end
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
        size = File.size(store_path)/1000.0
        info "Downloaded to #{store_path} (about #{size.to_i}K)."
        if size < 1
          error "Downloaded file seems to be empty"
        elsif size < 50.0
          warn "Very small image file"
        end
      end
    end

    def ready?
      return !@image_source.nil? && !@image_store.nil?
    end

    # Creates image store directory, exits if fail.
    def prepare!
      if !ready?
        warn "Image download options not present, Will not download images."
      else
        begin
          FileUtils::mkdir_p(@image_store)
          info "Created image store directory #{@image_store}"
        rescue Exception => e
          debug "Image store could not be created: #{$@}"
          exit_with 7, "Image store could not be created: #{$!}"
        end
      end
    end
  end
end
