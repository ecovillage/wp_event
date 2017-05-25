require 'logger'

module WPEvent
  module CLI
    module Logging
      # Cheap little Logger Formatter that picks
      # colors for severity classes if STDOUT is a tty
      # (regardless of whether the logger logs to STDOUT or not).
      class ColoredFormatter < Logger::Formatter
        attr_accessor :colorize

        NOTHING         = '\e[0;0m'
        IN_NOTHING      = '%s'
        IN_BLACK        = "\e[30m%s\e[0;0m"
        IN_RED          = "\e[31m%s\e[0;0m"
        IN_GREEN        = "\e[32m%s\e[0;0m"
        IN_BROWN        = "\e[33m%s\e[0;0m"
        IN_BLUE         = "\e[34m%s\e[0;0m"
        IN_PURPLE       = "\e[35m%s\e[0;0m"
        IN_CYAN         = "\e[36m%s\e[0;0m"
        IN_LIGHT_GRAY   = "\e[37m%s\e[0;0m"
        IN_DARK_GRAY    = "\e[30m%s\e[0;0m"
        IN_LIGHT_RED    = "\e[31m%s\e[0;0m"
        IN_LIGHT_GREEN  = "\e[32m%s\e[0;0m"
        IN_YELLOW       = "\e[33m%s\e[0;0m"
        IN_LIGHT_BLUE   = "\e[34m%s\e[0;0m"
        IN_LIGHT_PURPLE = "\e[35m%s\e[0;0m"
        IN_LIGHT_CYAN   = "\e[36m%s\e[0;0m"
        IN_WHITE        = "\e[37m%s\e[0;0m"

        SEVERITY_COLOR_MAP = { "DEBUG" => IN_YELLOW,
                               "INFO"  => IN_GREEN,
                               "ERROR" => IN_RED }

        def initialize
          super
          # Alternatively poor-mans solution STDOUT.tty?
          # We need to hack our way into logger (logdev is not accessible from outside)
          @colorize = Compostr::logger.instance_eval("@logdev&.dev&.tty?")
        end

        def call(severity, time, progname, msg)
          orig = super(severity, time, progname, msg)
          return orig if !@colorize
          SEVERITY_COLOR_MAP.fetch(severity, IN_NOTHING) % orig
        end
      end
    end
  end
end
