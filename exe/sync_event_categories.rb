#!/usr/bin/env ruby

require 'wp_event'
require 'optparse'
require 'json'

options = {}

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$PROGRAM_NAME} [options]"
  opts.separator "sync a list of event categories with event categories registered in wordpress instance"
  opts.separator "Common options"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on_tail("-h", "--help", "Show this message and exit") do
    puts opts
    exit
  end
  opts.on_tail("--version", "Show version and exit") do
    puts WPEvent::VERSION
    exit
  end
  opts.separator "Will exit with 0 on success"
end

# Process options
option_parser.parse!

exit 0
