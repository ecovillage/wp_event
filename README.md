# WPEvent

Ruby scripts to populate siebenlinden.org wordpress installation with event, referee and event category data.  The companion for the [ev7l-events Wordpress Plugin](https://github.com/ecovillage/ev7l-events).

Currently in a WIP state, where the [Compostr](https://github.com/ecovillage/compostr) gem is extracted, which will deal with most not-so-specific tasks.

Licensed under the GPLv3+, Copyright 2016, 2017 Felix Wolfsteller.

## Installation

To use the **standalone** functionality, install it yourself as:

    $ gem install wp_event

For **library usage** add this line to your application's Gemfile:

```ruby
gem 'wp_event'
```

And execute:

    $ bundle

## Usage

wp_event ships with a couple of tools.
These roughly follow the three basic custom wordpress post types of the ev7l-events Wordpress plugin: `Event`, `EventCategory` and `Referee` (the respective Wordpress CPTs are prefixed with `ev7l`, like `ev7l-event`).

For each type, three tools exist:

  - there is one tool to list, update or create an entity with given (command line) parameters.
  - the second tool updates/'synchronizes' the entities in the wordpress instance with a list of entities read from a (json) file.
  - finally, there is a tool to create a json file with legacy data from a supercustom couchdb; take this as an example of how to create a json file (to be used with a 'sync'-tool) if you like.

### Global configuration with compostr.conf

Tools rely on the file `compostr.conf` being present in your current working directory.  An example file is provided as `wp_event.conf.sample`.  Its content is rather self-explanatory (listing Wordpress credentials):

    # compostr.conf
    host:     "wp_event.mydomain"
    username: "admin"
    password: "buzzword"

### wp_event

Creates, updates or exports an event.
Execute as `wp_event` (or `bundle exec exe/wp_event` in development setup).
Call like `wp_event --help` for information about the options.

An example usage might look like

    $ wp_event --uuid 1234-4321-1234-4321 \
               --from "2017-02-20 10:00" \
               --to   "2017-02-22 18:00" \
               --name "Circles of friendship" \
               --categories "Social,Fun,Sponsored" \
               --referees   "Felix Wolfsteller" \
               --description "Rather long text, <em>with</em> markup ..."

#### export an event from the Wordpress installation

`wp_event --export --id 2`

### wp_category

Creates or updates an event category.
Execute as `wp_category` (or `bundle exec exe/wp_category` in development setup).
Call like `wp_category --help` for information about the options.

### wp_referee

Creates or updates a referee.
Execute as `wp_referee` (or `bundle exec exe/wp_category` in development setup).
Call with `wp_referee --help` for information about the options.

### sync_categories

Consumes a JSON file with event categories like this

    [
      {
        "uuid": "1234-1234-abcd-defa",
        "name": "numbers",
        "description": "Numeric events",
        "image_url":   "numers-category.png"
      },
      {
        "uuid": "dead-beef-abcd-defa",
        "name": "nutrition",
        "description": "Events dealing with nondestructive nutrition"
      }
    ]

and change corresponding data (identified by the UUID) in the wordpress instance.

### sync_events

Consumes a JSON file with events like this

    [
      {
        "uuid": "1a3b-1234-abcd-defa",
        "name": "Counting for accountants",
        "description": "advanced calculator needed",
        "fromdate": "2016-11-11 11:00",
        "todate": "2016-11-13 13:00",
        "image_url": "accountants-event.png"
      },
      {
        "uuid": "a123-a234-abcd-def1",
        "name": "Counting for accountants II",
        "description": "advanced calculator needed",
        "fromdate": "2016-12-11 11:00",
        "todate": "2016-12-13 13:00"
      }
    ]

and change corresponding data (identified by the UUID) in the wordpress instance.  There are many more relevant fields (call with `--help` to see them).

### sync_referees

Consumes a JSON file with referee information like this

    [
      {
        "uuid":        "1a3b-1234-abcd-defa",
        "firstname":   "Hannah",
        "lastname":    "Barber",
        "description": "Cutting edge referee",
        "image_url":   "hanna_barber.png",
      },
      {
        "uuid":      "a123-a234-abcd-def1",
        "firstname": "Josh",
        "lastname":  "Conceptual",
      }
    ]

and change corresponding data (identified by the UUID) in the wordpress instance.

### Import data from legacy databases

As long as you can export your data from the legacy database into the json format (as given above), you'll be fine.  If you have problems in doing so, feel free to contact us.

For Sieben Linden legacy data, export functionality of it is shipped within this gem (with most code residing in `lib/wp_event/couch_import` and `exe/legacy`).

The tools should work hand in hand with the `sync` family of tools, such that you can connect them via pipes:

    $ bundle exec exe/legacy/pull_events --outfile - | bundle exec exe/sync_events

The generated JSON files can then be used to update the data found in the wordpress installation.

## Wordpress setup

Use the [ev7l-events](https://github.com/ecovillage/ev7l-events) wordpress plugin.

metakeys starting with "_" are by default hidden!

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` (or `bundle console` in a checkout) for an interactive prompt that will allow you to experiment. Run `bundle exec auto_event_post` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


### Design and decisions

This section is written **without great care and will receive love __once things settled__**.

Parts have been written in [doc/custom_post_types](doc/custom_post_types).

Aim is to not to re-implement [ActiveRecord]() or [Roar]() but to have a tailored solution for off-the-beat wordpress Custom Post Type post updates (and creations).

At the end of the day, WPEvent is used to pass a hash to [rubypress](), which bloats it into a xmlrpc blob to be fired towards your wordpress installation.

We deal with three separate abstraction layers of entities (which correspond to Wordpress Posts of a Custom Post Type).  On example of `Event`:

  - the **post** `lib/wp_event/event_post.rb` handles


#### History

We deal with three separate abstraction layers of entities (which correspond to Wordpress Posts of a Custom Post Type).  On example of `Event`:

  - the **post** `lib/wp_event/event_post.rb` handles
    - creation and update of new 'Event' Posts.
    - checking for existence of Posts with specific uuid metadata-key (and value).
    - returning wordpress data for given post (but **not** as an instance of EventPost!).
    It thus has multiple responsabilities that are not yet nicely separated or united.
    It is a **module** though, so we do not deal with objects in the typical sense on that layer (in contrast to ActiveRecord pattern).
  - a command line interface for creation and listing (in `exe/wp_event`)
  - the json representation, consumed in `exe/sync_events`, created in `exe/legacy/pull_events`
  - a legacy representation in `couch_event`

As the entities share a lot of common structure, part of its functionality (i.e. checking for presence of an entity with given UUID) is included from `WPEvent::PostType`.

To speed up access and bundle common data fetching and querying functionality, a `EntityCache` is implemented in `lib/wp_event/entity_cache`.  This can be used to speed up lookups (e.g. `uuid` to `id`, `uuid` to `name` ...).

In the longer run, all the lookup and low-level access should be moved to the `PostType`, `EntityCache` and possible other modules and classes.

The idea is to keep the entity classes itself lean (in contrast to glue the persistence layer directly to them).

To ease Creation and Handling of Worpdresses Custom Fields for Posts (e.g. starting date of an event is modelled as such), the `PostMetaData` class helps with these.

Finally, to work with 'Featured Image' and thumbnails for posts, `ImageUpload` helps pushing media/attachments to the wordpress installation.

### Legacy import code

Legacy data is imported via an `export` to json in our example.
The `CouchImporter` does bulk mapping of couchdb documents to `couch_\<entity\>` classes like `CouchEvent` (which then do the mapping themselves).

The `CouchDB` module deals with picking up data from specific views (or documents).

## Lessons learned

It looks as if Custom field (metadata) values are stripped by wordpress upon insertion ("here be spaces     " becomes "here be spaces").

A relatively hard-to-debug "TypeError: wrong argument type String (expected Symbol)" is thrown when you try to initialize a CustomPostType with a hash that contains String (not symbol) keys.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ecovillage/wp_event.

