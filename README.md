# Cms

## Features
* FormConfig(email_receivers)
* Page (has_seo_tags, has_sitemap_record) - for static pages
* Seo tags(title, keywords, description)
* Sitemap element
* HtmlBlock (name, title, description, image)
* json data - json field for text database column(for example in sqlite3)
* caching in model

## Installation


Add this line to your application's Gemfile:

```ruby
gem 'cms'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cms

## Usage

rails g migration CreateCmsTables
class CreateCmsTables < ActiveRecord::Migration
    def up
        Cms.create_tables
    end

    def down
        Cms.drop_tables
    end
end

all valid tables:  [:form_configs, :pages, :seo_tags, :html_blocks, :sitemap_elements ]

tables set may be changed:
Cms.create_tables only: [:form_configs, :pages] # [:form_configs, :pages]
Cms.create_tables except: [:form_configs, :pages] # [:seo_tags, :html_blocks, :sitemap_elements]

rails g model FormConfigs::ContactRequest
class FormConfigs::ContactRequest < Cms::FormConfig
end

rails g model Pages::Home
class Pages::Home < Cms::Page
end

class Article < ActiveRecord::Base
    has_seo_tags
    has_sitemap_record
end

TODO: Write usage instructions here

## Move paperclip assets
class MyModel < ActiveRecord::Base
  ...
end

default paperclip url and path. Can be overriden:

Paperclip::Attachment.default_options[:url] = "/:class/:id/:attachment/:style/:basename.:extension"
Paperclip::Attachment.default_options[:path] = "#{Rails.root}/public:url"
Paperclip::Attachment.default_options[:old_url] = "/system/:attachment/:id/:style/:basename.:extension"
Paperclip::Attachment.default_options[:old_path] = "#{Rails.root}/public#{Paperclip::Attachment.default_options[:old_url]}"

MyModel.move_images(arguments)
arguments:
  1. old_path_pattern
    default: Paperclip::Attachment.default_options[:old_path], new_path_pattern = Paperclip::Attachment.default_options[:path]
  2. new_path_pattern
    default: Paperclip::Attachment.default_options[:path]

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cms.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

