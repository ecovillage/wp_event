# WPEvent

Ruby scripts to populate siebenlinden.org wordpress installation with event, referee and event category data.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'auto_event_post'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install auto_event_post

## Usage

wp_event ships with a couple of tools

### wp_event.config

Tools rely on `wp_event.conf` being present in your current working directory.  An example file is provided as `wp_event.conf.sample`.  Its content is rather self-explanatory:

    # wp_event.conf
    host: "wp_event.mydomain"
    username: "admin"
    password: "buzzword"

### wp_event

Execute as `wp_event` (or `bundle exec exe/wp_event` in development setup).
Call with `wp_event --help` for information about the options.

## Wordpress setup

Use the `e7l-events` wordpress plugin.

metakeys starting with "_" are by default hidden!

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` (or `bundle console` in a checkout) for an interactive prompt that will allow you to experiment. Run `bundle exec auto_event_post` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ecovillage/wp_event.

