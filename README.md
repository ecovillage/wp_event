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

wp_event ships with a couple of tools.
These roughly follow the three basic custom wordpress post types: `Event`, `EventCategory` and `Referee` (the respective Wordpress CPTs are prefixed with `ev7l`, like `ev7l-event`).

For each type, there is one tool to list, update or create an entity with given (command line) parameters.
There is one tool to update/'synchronize' the entities in the wordpress instance with a list of entities read from a (json) file.
Finally, there is a tool to create a json file with legacy data from a supercustom couchdb; take this as an example if you like.

### Global configuration with wp_event.config

Tools rely on `wp_event.conf` being present in your current working directory.  An example file is provided as `wp_event.conf.sample`.  Its content is rather self-explanatory:

    # wp_event.conf
    host: "wp_event.mydomain"
    username: "admin"
    password: "buzzword"

### wp_event

Execute as `wp_event` (or `bundle exec exe/wp_event` in development setup).
Call with `wp_event --help` for information about the options.

#### export an event

`wp_event --export -id 2`

### wp_category

Execute as `wp_category` (or `bundle exec exe/wp_category` in development setup).
Call with `wp_event --help` for information about the options.

### sync_categories

Consumes a JSON file with event categories like this

    [
      {
        "uuid": "1234-1234-abcd-defa",
        "name": "numbers",
        "description": "Numeric events"
      },
      {
        "uuid": "dead-beef-abcd-defa",
        "name": "nutrition",
        "description": "Events dealing with nondestructive nutrition"
      }
    ]

### sync_events

Consumes a JSON file with event categories like this

    [
      {
        "uuid": "1a3b-1234-abcd-defa",
        "name": "Counting for accountants",
        "description": "advanced calculator needed",
        "fromdate": "2016-11-11 11:00",
        "todate": "2016-11-13 13:00"
      },
      {
        "uuid": "a123-a234-abcd-def1",
        "name": "Counting for accountants II",
        "description": "advanced calculator needed",
        "fromdate": "2016-12-11 11:00",
        "todate": "2016-12-13 13:00"
      }
    ]

### Import data from legacy database

As long as you can export your data from the legacy database into json format (as given above), you'll be fine.  If you have problems in doing so, feel free to contact us.

For Sieben Linden legacy data, export of it is shipped within this gem (with most code residing in `lib/wp_event/couch_import` and `exe/legacy`).

## Wordpress setup

Use the [ev7l-events](https://github.com/ecovillage/ev7l-events) wordpress plugin.

metakeys starting with "_" are by default hidden!

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` (or `bundle console` in a checkout) for an interactive prompt that will allow you to experiment. Run `bundle exec auto_event_post` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


### Design and decisions

This section is written without great care and will receive love once things settled.

Aim is to not reimplement ActiveRecord and work in agile fashion with intermediate cleanups in between.

We deal with three separate abstraction layers of entities (which correspond to Wordpress Posts of a Custom Post Type).  On example of `Event`:

  - the **post** `lib/wp_event/event_post.rb` handles
    - creation of new 'Event' Posts.
    - checking for existence of Posts with specific uuid metadata-key (and value)
    - returning wordpress data for given post (but **not** as an instance of EventPost!)
    It thus has multiple responsabilities that are not yet nicely separated or united.
  - a command line interface for creation and listing (in `exe/wp_event`)
  - the json representation, consumed in `exe/sync_events`, created in `exe/legacy/pull_events`
  - a legacy representation in `couch_event`

As the entities share a lot of common structure, part of its functionality (that goes i.e. beyond creation) is included from `WPEvent::PostType`.

To speed up access and bundle common data fetching and querying functionality, a `EntityCache` is implemented in `lib/wp_event/entity_cache`.  This can be used to speed up lookups (e.g. `uuid` to `id`, `uuid` to `name` ...).

In the longer run, all the lookup and low-level access should be moved to the `PostType`, `EntityCache` and possible other modules and classes.

The idea is to keep the entity classes itself lean (in contrast to glue the persistence layer directly to them).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ecovillage/wp_event.

