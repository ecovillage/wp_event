require 'mime-types'

module WPEvent
  class ImageUploader
    attr_accessor :image_store
    attr_accessor :media_cache

    def initialize image_store, media_cache
      if !image_store
        WPEvent.logger.warn "ImageUploader will search media in current directory (no source specified)."
      end
      @image_store = image_store || '.'
      @media_cache = media_cache
    end

    # Returns attachment id of an image already uploaded
    # or attachment_id of image after fresh upload
    # (or nil if path empty)
    def process rel_path
      return nil if rel_path.to_s.strip.empty?

      # Do we need URI encoding here?
      if attachment_id = @media_cache.id_of_name(rel_path)
        WPEvent.logger.debug "Image already uploaded."
      else
        path = File.join(@image_store, rel_path)
        WPEvent.logger.info "Uploading file #{path}"
        upload = WPEvent::ImageUpload.new(path)
        attachment_id = upload.do_upload!
        WPEvent.logger.debug "Uploaded image id: #{attachment_id}"
      end

      return attachment_id
    end
  end
end
