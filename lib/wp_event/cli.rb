module WPEvent
  module CLI
    extend WPEvent::CLI::Logging
    def errxit exit_code=1, msg
      STDERR.puts msg
      error msg
      exit exit_code
    end
  end
end
