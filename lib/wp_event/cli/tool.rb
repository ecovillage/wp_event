module WPEvent
  module CLI
    # Basic Tool helpers.
    # A tool reads or writes from STDIN or a given file argument.
    # In contrast to the supercool ARGF in ruby, we will not read from
    # multiple files and as an addition have the possibility to define the
    # place to output via an option (as opposed to an argume).
    #
    # Like in `execute_tool MYFILE` vs `execute_tool --outfile MYFILE`.
    #
    # Following out (and in) specifications should be possible
    #
    # `tool`      (goes to/comes from STDOUT/STDIN)
    # `tool -`    (goes to/comes from STDOUT/STDIN)
    # `tool FILE` (goes to/comes from FILE)
    # `tool --outfile FILE` (goes to/comes from FILE)
    # `tool --outfile -`    (goes to/comes from STDOUT/STDIN)
    #
    # Not possible should be
    #
    # `tool --outfile FILE1 FILE`
    #
    # Also, the tool should fail if the specified file does exist.  If the user wants to overwrite data, she should redirect its output like this
    #
    # `tool > THISFILEWILLBEOVERWRITTEN.json`
    #
    # In any case where output goes to STDOUT, logging shall happen on STDERR.
    module Tool
      include Compostr::Logging

      class InputArgumentError < StandardError
      end

      # TODO USAGE BANNER

      def exit_on_arg_and_outfile! argv, options
        if ARGV.length == 1 && options[:outfile]
          exit_with 1, "Cannot specify both --outfile and argument"
        end
      end

      def compress_to_outfile! argv, options
        options[:outfile] = ARGV[0] if ARGV.length == 1
      end

      def exit_or_get_out_stream argv, options
        exit_on_arg_and_outfile! argv, options
        compress_to_outfile! argv, options

        out = options[:outfile]
        if out == "-" || argv.length == 0 && options[:outfile].nil?
          $stdout
        else
          if File.exist?(out)
            exit_with 2, "Output file #{out} exists already, aborting."
          end
          File.open(out, 'w')
        end
      end

      # Returns either the IO representing input (opening last argument
      # as file, if needed), or throws an InputArgumentError (might get
      # a different name in near future).
      def input_stream_or_exit

        if ARGV.length != 1 && STDIN.tty?
          # No input argument and STDIN is terminal.
          raise InputArgumentError.new("Please provide json input file path or pipe into me.")
        end

        if (ARGV.length == 1) && !File.exist?(ARGV[0])
          raise InputArgumentError.new("Input file does not exist!")
        end

        #if !STDIN.tty?
        #  ARGV[0] = STDIN
        #end

        input = ARGV.length == 1 ? File.open(ARGV[0]) : STDIN
      end

      # Inits the (Compostr) logger.
      def self.init_logger verbose: false, stderr: false
        # ruby 2.4 will ship with Logger.new(STDOUT, formatter: ...)
        Compostr.logger = Logger.new(stderr ? STDERR : STDOUT).tap do |l|
          l.formatter = CLI::Logging::ColoredFormatter.new
          l.level = verbose ? Logger::DEBUG : Logger::INFO
        end
      end
    end
  end
end
