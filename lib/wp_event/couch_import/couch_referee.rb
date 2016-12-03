require 'json'

module WPEvent
  module CouchImport
    class CouchReferee
      attr_accessor :name, :description, :uuid, :document, :image_url

      def initialize uuid, name, description, document=nil, image_url=nil
        @uuid        = uuid
        @name        = name
        @description = description
        @document    = document
        @image_url   = image_url
      end

      def self.pull_from_couchdb uuid
        begin
          response = CouchDB.get_doc uuid
          from_couch_doc response
        rescue Exception => e
          nil
        end
      end

      def to_json *a
        { uuid:        @uuid,
          name:        @name,
          description: @description,
          image_url:   @image_url
        }.to_json(*a)
      end

      def self.from_couch_doc document
        WPEvent::CouchImport::CouchReferee.new document["_id"],
          document.dig("g_value", "firstname").to_s + " " + document.dig("g_value", "lastname").to_s,
          document.dig("g_value", "description"),
          document,
          document.dig("g_value", "image")
      end
    end
  end
end

