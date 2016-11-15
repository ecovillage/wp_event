require 'open-uri'
require 'rest-client'

module WPEvent
  module CouchImport
    module CouchDB
      BASE_URL = "http://localhost:5984/fk_seminar/"

      def self.get_doc uuid
        JSON.parse RestClient.get(BASE_URL + uuid)
      end

      # While this might be abstracted, it might as well be
      # considered smelly legacy shortcut.
      def self.get_seminar_docs_by_date from, to
        url = BASE_URL + "_design/sl_seminar/_view/seminar_by_date"
        url = url + "?startkey=#{URI::encode([from.year.to_s, from.month.to_s, from.day.to_s].to_json)}"
        url = url + "&endkey=#{URI::encode([to.year.to_s, to.month.to_s, to.day.to_s].to_json)}"
        # Fetch the docs, one by one.
        rows = JSON.parse(RestClient.get(url))["rows"]
        rows.map{|r| get_doc r["id"]}
      end

      # While this might be abstracted, it might as well be
      # considered smelly legacy shortcut.
      def self.get_seminar_docs_by_month year, month
        url = BASE_URL + "_design/sl_seminar/_view/seminar_by_month"
        url = url + "?key=#{URI::encode([year.to_s, "%.2d"%month.to_i].to_json)}"
        # Fetch the docs, one by one.
        rows = JSON.parse(RestClient.get(url))["rows"]
        rows.map{|r| get_doc r["id"]}
      end

      def self.get_all_categories
        # TODO this view actually includes all info (besides uuid?), no need to fetch one-by-one
        url = BASE_URL + "_design/sl_seminar/_view/categories_all"
        # Fetch the docs, one by one.
        rows = JSON.parse(RestClient.get(url))["rows"]
        rows.map{|r| get_doc r["id"]}
      end

      def self.get_all_referees
        # TODO this view actually includes all info (besides uuid?), no need to fetch one-by-one
        url = BASE_URL + "_design/sl_seminar/_view/person_referee_by_name"
        rows = JSON.parse(RestClient.get(url))["rows"]
        # Fetch the docs, one by one.
        rows.map{|r| get_doc r["id"]}
      end
    end
  end
end
