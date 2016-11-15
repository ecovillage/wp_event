module WPEvent
  module CouchImport
    module CouchImporter
      def self.get_all_categories
        CouchDB.get_all_categories.map {|doc| CouchEventCategory.from_couch_doc doc}
      end

      def self.get_all_referees
        CouchDB.get_all_referees.map {|doc| CouchReferee.from_couch_doc doc}
      end
    end
  end
end
