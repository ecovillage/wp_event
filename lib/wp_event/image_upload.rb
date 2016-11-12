require 'mime-types'

module WPEvent
  class ImageUpload
    attr_accessor :file_path, :post_id

    def initialize file_path, post_id
      @file_path = file_path
      @post_id   = post_id
    end

    # Push data to Wordpress instance, return attachment_id
    def do_upload!
      data = create_data
      response = WPEvent::wp.uploadFile(data: data)
      response["attachment_id"]
    end

    private

    def create_data
      {
        name: @file_path,
        type: MIME::Types.type_for(file_path).first.to_s,
        post_id: @post_id,
        bits: XMLRPC::Base64.new(IO.read file_path)
      }
    end
  end
end
