require 'json'

module WPEvent
  module CouchImport
    class CouchEvent
      attr_accessor :title, :description, :from, :to, :categories, :uuid, :document
      def initialize uuid, title, description, from, to, categories, document=nil
        @uuid        = uuid
        @title       = title
        @description = description
        @from        = from
        @to          = to
        @categories  = categories
        @document    = document
      end

      def self.from_couch_doc document
        WPEvent::CouchImport::CouchEvent.new document["_id"],
          document.dig("g_value", "title"),
          document.dig("g_value", "description_long"),
          Date.strptime(document.dig("g_value", "date_from"), "%d.%m.%Y"),
          Date.strptime(document.dig("g_value", "date_to"),   "%d.%m.%Y"),
          document.dig("g_value", "categories"),
          document
      end

      def self.pull_from_couchdb uuid
        begin
          response = CouchDB.get_doc uuid
          return nil if !response.dig("g_value", "publish_web")
          from_couch_doc response
        rescue Exception => e
          nil
        end
      end

      def self.pull_from_couchdb_between from, to
        begin
          response = CouchDB.get_seminar_docs_by_month 2016, 11
          response.select! {|doc| doc.dig("g_value", "publish_web")}
          response.map do |document|
            from_couch_doc document
          end.compact
        rescue Exception => e
          STDERR.puts $! # last exception
          STDERR.puts $@ # last backtrace
          nil
        end
      end

      def to_json *a
        { uuid:        @uuid,
          name:        @title,
          description: @description,
          fromdate:    @from,
          todate:      @to
        }.to_json(*a)
      end
    end
  end
end
