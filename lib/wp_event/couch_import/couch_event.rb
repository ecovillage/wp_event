require 'json'

module WPEvent
  module CouchImport
    class CouchEvent
      extend Compostr::Logging

      attr_accessor :title, :description,
        :from, :to, :category_names, :uuid,
        :arrival, :departure, :current_infos, :costs_participation,
        :costs_catering, :info_housing, :other_infos, :participants_prerequisites,
        :participants_please_bring, :registration_needed,
        :document, :referee_and_qualifications,
        :image_url, :timestamp

      def initialize uuid: nil, title: nil, description: nil, from: nil,
        to: nil, category_names: nil, referee_and_qualifications: nil,
        arrival: nil, departure: nil, current_infos: nil,
        costs_participation: nil, costs_catering: nil, info_housing: nil, other_infos: nil,
        participants_prerequisites: nil, participants_please_bring: nil,
        image_url: nil, registration_needed: true, cancel_conditions: nil, timestamp: DateTime.now, document: nil
        @uuid        = uuid
        @title       = title
        @description = description
        @from        = from
        @to          = to
        @category_names = category_names
        @referee_and_qualifications = referee_and_qualifications
        @document    = document
        @image_url   = image_url
        @timestamp   = timestamp
        @arrival     = arrival
        @departure   = departure
        @current_infos = current_infos
        @costs_participation = costs_participation
        @costs_catering = costs_catering
        @info_housing = info_housing
        @other_infos  = other_infos
        @participants_prerequisites = participants_prerequisites
        @participants_please_bring = participants_please_bring
        @registration_needed = registration_needed
        @cancel_conditions   = cancel_conditions
      end

      # From
      #   "referees" => [ {"qualification"=>".q.", "can_talk_to"=>true, "l_booking"=>"...", "l_person"=>"luuid", l_reservation"=>"..." } ]
      #   return: [{referee_uuid: 'luuid', qualification: '.q.']
      def self.extract_referees document
        referee_doc = document.dig('g_value', 'referees') || []
        referee_doc.map{|ref| {qualification: ref["qualification"], uuid: ref['l_person']}}
      end

      def self.from_couch_doc document
        WPEvent::CouchImport::CouchEvent.new uuid: document["_id"],
          title: document.dig("g_value", "title"),
          description: document.dig("g_value", "description_long"),
          to:   Date.strptime(document.dig("g_value", "date_to"),   "%d.%m.%Y"),
          from: Date.strptime(document.dig("g_value", "date_from"), "%d.%m.%Y"),
          category_names: document.dig("g_value", "categories"),
          referee_and_qualifications: extract_referees(document),
          arrival: web_notice_array_val(document, "arrival", "Anreise"),
          departure: web_notice_array_val(document, "departure", "Abreise"),
          costs_catering: web_notice_array_val(document, "cost_housing", "Biovollverpflegung"),
          info_housing: web_notice_array_val(document, "housing", "Unterkunft"),
          other_infos: other_web_notices(document),
          costs_participation: web_notice_array_val(document, "cost_seminar", "Seminarkosten"),
          registration_needed: document.dig("g_value", "registration_needed"),
          participants_prerequisites: document.dig("g_value", "attendee_preconditions"),
          participants_please_bring: document.dig("g_value", "please_bring"),
          cancel_conditions: document.dig("g_value", "cancel_conditions"),
          current_infos: document.dig("g_value", "web_notice"),
          image_url: document.dig("g_value", "thumbnail"),
          document: document,
          timestamp: Time.at(document.dig("g_timestamp").to_i).to_datetime
      end

      def self.pull_from_couchdb uuid
        begin
          response = CouchDB.get_doc uuid
          return nil if !response.dig("g_value", "publish_web")
          from_couch_doc response
        rescue StandardError => e
          error "Error caught: #{e.inspect} at #{caller[0]}"
          nil
        end
      end

      def self.pull_from_couchdb_between from, to
        begin
          response = CouchDB.get_seminar_docs_by_date from, to
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

      def self.other_web_notices document
        known_labels = ["Anreise", "Abreise", "Biovollverpflegung",
                        "Unterkunft", "Seminarkosten"]

        notices = document.dig("g_value", "web_notice_array")
        return nil if notices.nil?

        unknown_notices = notices.select do |notice|
          !known_labels.include?(notice['label'])
        end

        unknown_notices.map do |notice|
          "<div><h3>#{notice['label']}</h3>#{notice['text']}</div>"
        end.join("\n")
      end

      def self.web_notice_array_val document, field, label="FORBIDDENLABELNAME"
        notices = document.dig("g_value", "web_notice_array")
        return nil if notices.nil?

        notice = notices.find(&WPEvent::CouchImport::Lambdas.web_notice_array_find(field, label))
        return nil if notice.nil?

        notice["text"]
      end

      def to_json *a
        { uuid:           @uuid,
          name:           @title,
          description:    @description,
          fromdate:       @from,
          todate:         @to,
          category_names: @category_names,
          referee_qualifications: @referee_and_qualifications,
          image_url:      @image_url,
          arrival:        @arrival,
          departure:      @departure,
          current_infos:  @current_infos,
          costs_participation: @costs_participation,
          costs_catering: @costs_catering,
          info_housing:   @info_housing,
          other_infos:    @other_infos,
          participants_please_bring: @participants_please_bring,
          participants_prerequisites: @participants_prerequisites,
          registration_needed: @registration_needed,
          cancel_conditions:   @cancel_conditions,
          timestamp:      @timestamp
        }.to_json(*a)
      end
    end
  end
end
