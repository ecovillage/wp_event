module WPEvent
  module Downloader
    # Download URL into path
    def self.download! url, path
      File.open(path, "w") do |f|
        IO.copy_stream(open(url), f)
      end
    end
  end
end
