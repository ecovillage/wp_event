require "wp_event/version"

require "wp_event/post_type"
require "wp_event/post_meta_data"
require "wp_event/category_post"
require "wp_event/event_post"
require "wp_event/referee_post"
require "wp_event/entity_cache"

require "wp_event/cli/logging"
require "wp_event/cli"
require "wp_event/cli/tool"

require "wp_event/downloader"
require "wp_event/image_download"
require "wp_event/image_upload"
require "wp_event/image_uploader"
require "wp_event/media_library_cache"

require "wp_event/referee_syncer"
require "wp_event/event_syncer"

require "wp_event/couch_import/couch_event"
require "wp_event/couch_import/couch_event_category"
require "wp_event/couch_import/couch_db"
require "wp_event/couch_import/couch_importer"
require "wp_event/couch_import/couch_referee"

require 'ostruct'
require 'yaml'
require 'rubypress'

module WPEvent
  def self.load_conf
    @config = OpenStruct.new YAML.load_file 'wp_event.conf'
  end

  def self.config
    @config ||= load_conf
  end

  #  wp.getPosts(blog_id: 0, filter: {post_type: 'event'})
  # .collect{|| .. "custom_fields" ... ["key"] == "uuid" ...
  # #f12ab-ab21f
  def self.find_post_by_uuid uuid
    posts = find_all_posts

    custom_uuid_field_value = lambda do |c|
      c["custom_fields"]&.find{|f| f["key"] == "uuid"}&.fetch("value") == uuid
    end

    #"post_modified_gmt"

    posts.find &custom_uuid_field_value
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.logger= logger
    @@logger = logger
  end

  def self.find_all_posts
    wp.getPosts(blog_id: 0, filter: {post_type: Event::TYPE})
  end

  def self.delete_post post_id
    wp.deletePost(blog_id: 0, post_id: post_id)
  end

  def self.wp
    @wp ||= Rubypress::Client.new(host: config.host,
                                  username: config.username,
                                  password: config.password)
  end
end
