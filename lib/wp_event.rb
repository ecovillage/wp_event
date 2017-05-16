require "wp_event/version"

require "wp_event/cli/logging"
require "wp_event/cli"
require "wp_event/cli/tool"

require "wp_event/lambdas"

require 'compostr'

require "wp_event/custom_post_types/category"
require "wp_event/custom_post_types/event"
require "wp_event/custom_post_types/referee"
require "wp_event/event_factory"

require "wp_event/post_type"
require "wp_event/post_meta_data"
require "wp_event/category_post"
require "wp_event/event_post"
require "wp_event/referee_post"

require "wp_event/downloader"
require "wp_event/image_download"
require "wp_event/image_upload"
require "wp_event/image_uploader"

require "wp_event/referee_syncer"
require "wp_event/event_syncer"

require "wp_event/couch_import/couch_event"
require "wp_event/couch_import/couch_event_category"
require "wp_event/couch_import/couch_db"
require "wp_event/couch_import/couch_importer"
require "wp_event/couch_import/couch_referee"
require "wp_event/couch_import/lambdas"

require 'ostruct'
require 'yaml'
require 'rubypress'

module WPEvent
  def self.logger
    # ruby 2.4 will ship with Logger.new(STDOUT, formatter: ...)
    @@logger ||= Logger.new(STDOUT).tap do |l|
      l.formatter = CLI::Logging::ColoredFormatter.new
    end
  end

  def self.logger= logger
    @@logger = logger
  end

  def self.delete_post post_id
    Compostr::wp.deletePost(blog_id: 0, post_id: post_id)
  end
end
