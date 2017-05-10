module WPEvent
  module CouchImport
    module Lambdas
      def self.web_notice_array_find(field_name, label_name="FORBIDDENLABELNAME")
        web_notice_finder = lambda do |x|
          x["field"] == field_name || x['label'] == label_name
        end
      end
    end
  end
end
