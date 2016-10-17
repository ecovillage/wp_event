require 'open-uri'
require 'rest-client'

module WPEvent
  class CouchEvent
    attr_accessor :title, :description, :from, :to, :categories, :uuid
    def initialize uuid, title, description, from, to, categories
      @uuid        = uuid
      @title       = title
      @description = description
      @from        = from
      @to          = to
      @categories  = categories
    end

    def self.pull_from_couchdb uuid
      base_url = "http://localhost:5984/fk_seminar/"
      begin
        response = JSON.parse RestClient.get(base_url + uuid)
        return nil if !response["g_value"]["publish_web"]
        WPEvent::CouchEvent.new response["_id"],
          response["g_value"]["title"],
          response["g_value"]["description_long"],
          response["g_value"]["from"],
          response["g_value"]["to"],
          response["g_value"]["categories"]
      rescue Exception => e
        nil
      end
    end
  end
end
