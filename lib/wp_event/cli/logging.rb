require 'logger'

module WPEvent
  module CLI
    # Module to extend to get easy access to standard log functions.
    # These are debug, info, warn, error and fatal.
    # All log functions use the WPEvent.logger (which can be customized).
    # A typical client will just `extend WPEvent::Logging` .
    module Logging
      def debug msg
        WPEvent.logger.debug msg
      end
      def info msg
        WPEvent.logger.info msg
      end
      def warn msg
        WPEvent.logger.warn msg
      end
      def error msg
        WPEvent.logger.error msg
      end
      def fatal msg
        WPEvent.logger.fatal msg
      end
    end
  end
end
