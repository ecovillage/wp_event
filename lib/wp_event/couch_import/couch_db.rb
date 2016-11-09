require 'open-uri'
require 'rest-client'

module WPEvent
  module CouchImport
    module CouchDB
      def self.get_doc uuid
        base_url = "http://localhost:5984/fk_seminar/"
        JSON.parse RestClient.get(base_url + uuid)
      end
    end
  end
end
