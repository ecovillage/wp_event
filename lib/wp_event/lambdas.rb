module WPEvent
  module Lambdas
    def self.with_cf_uuid(uuid)
      uuid_selector = lambda do |x|
        x["custom_fields"].find do |f|
          f["key"] == "uuid" && f["value"] == uuid
        end
      end
    end
  end
end
