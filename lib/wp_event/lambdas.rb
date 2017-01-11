module WPEvent
  module Lambdas
    # true if given obj has hash entry "custom_fields"
    # with key-value hashes within it that define given uuid.
    def self.with_cf_uuid(uuid)
      uuid_selector = lambda do |x|
        x["custom_fields"].find do |f|
          f["key"] == "uuid" && f["value"] == uuid
        end
      end
    end
  end
end
