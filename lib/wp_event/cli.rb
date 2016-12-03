module WPEvent
  module CLI
    extend WPEvent::CLI::Logging

    # Logger#error and STDERR.puts given error message
    # and exits with exit_code
    def exit_with exit_code=1, msg
      STDERR.puts msg
      error msg
      exit exit_code
    end

    # Either opens file with given name or return STDOUT, when '-' is given.
    def io_out_from_arg outfile
      if outfile == '-'
        $stdout
      else
        File.open(outfile, 'w')
      end
    end
  end
end
