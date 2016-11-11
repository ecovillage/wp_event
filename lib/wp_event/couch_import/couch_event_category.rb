require 'json'

module WPEvent
  module CouchImport
    class CouchEventCategory
      attr_accessor :name, :description, :uuid, :document
      # shorturl and thumbnail
      def initialize uuid, name, description, document=nil
        @uuid        = uuid
        @name        = name
        @description = description
        @document    = document
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
          description: @description
        }.to_json(*a)
      end

      def self.from_couch_doc document
        WPEvent::CouchImport::CouchEventCategory.new document["_id"],
          document.dig("g_value", "name"),
          document.dig("g_value", "description"),
          document
      end
    end
  end
end

