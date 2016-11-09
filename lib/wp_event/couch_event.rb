require 'open-uri'
require 'rest-client'
require 'json'

module WPEvent
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

    def self.pull_from_couchdb uuid
      base_url = "http://localhost:5984/fk_seminar/"
      begin
        response = JSON.parse RestClient.get(base_url + uuid)
        return nil if !response["g_value"]["publish_web"]
        WPEvent::CouchEvent.new response["_id"],
          response["g_value"]["title"],
          response["g_value"]["description_long"],
          Date.strptime(response["g_value"]["date_from"], "%d.%m.%Y"),
          Date.strptime(response["g_value"]["date_to"],   "%d.%m.%Y"),
          response["g_value"]["categories"],
          response
      rescue Exception => e
        nil
      end
    end

    def to_json *a
      { uuid: @uuid,
        title: @title,
        description: @description,
        fromdate: @from,
        todate:  @to
      }.to_json(*a)
    end
  end
end
