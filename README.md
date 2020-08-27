# Cms

## Features
* FormConfig(email_receivers)
* Page (has_seo_tags, has_sitemap_record) - for static pages
* Seo tags(title, keywords, description)
* Sitemap element
* HtmlBlock (name, title, description, image)
* json data - json field for text database column(for example in sqlite3)
* caching in model
* rails_admin custom scopes (tabs on index action)

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

    $ rails g migration CreateCmsTables

```ruby
class CreateCmsTables < ActiveRecord::Migration
    def up
        Cms.create_tables
    end

    def down
        Cms.drop_tables
    end
end
```

all valid tables:  [:form_configs, :pages, :seo_tags, :html_blocks, :sitemap_elements ]

tables set may be changed:
```ruby
Cms.create_tables only: [:form_configs, :pages] # [:form_configs, :pages]
```
or
```ruby
Cms.create_tables except: [:form_configs, :pages] # [:seo_tags, :html_blocks, :sitemap_elements]
```
    $ rails g model FormConfigs::ContactRequest
```ruby
class FormConfigs::ContactRequest < Cms::FormConfig
end
```

    $ rails g model Pages::Home

```ruby
class Pages::Home < Cms::Page
end
```

```ruby
class Article < ActiveRecord::Base
    has_seo_tags
    has_sitemap_record
end
```

`has_seo_tags` is plain has_one association to `Cms::MetaTags` model.
`has_sitemap_record` also is plain association to `Cms::SitemapElement`

## ActionController extensions
```ruby
class ArticlesController < ApplicationController
 before_action :set_article, only: [:show]
 def index
   set_page_metadata(:articles)
 end
 
 def show
   set_page_metadata(@article)
 end
 
 private
 def set_article
   @article = Article.find(params[:id]) rescue nil
   if !@article
     return render_not_found
   end
   
   @article
 end
 
end
end
```

## Move paperclip assets
```ruby
class MyModel < ActiveRecord::Base
  ...
end
```
default paperclip url and path. Can be overriden:
```ruby
Paperclip::Attachment.default_options[:url] = "/:class/:id/:attachment/:style/:basename.:extension"
Paperclip::Attachment.default_options[:path] = "#{Rails.root}/public:url"
Paperclip::Attachment.default_options[:old_url] = "/system/:attachment/:id/:style/:basename.:extension"
Paperclip::Attachment.default_options[:old_path] = "#{Rails.root}/public#{Paperclip::Attachment.default_options[:old_url]}"
end

```ruby
MyModel.move_images(arguments)
```

arguments:
  1. old_path_pattern
    default: Paperclip::Attachment.default_options[:old_path], new_path_pattern = Paperclip::Attachment.default_options[:path]
  2. new_path_pattern
    default: Paperclip::Attachment.default_options[:path]
    
    
## Caching
in your model
```ruby
class Article < ActiveRecord::Base
  has_cache
  
  # def cache_instances
  # [self]
  # end
  
  # def url(locale = I18n.locale)
  #   your logic goes here...; returns string
  # end
end
```

More advanced example:
```ruby
class Article < ActiveRecord::Base
    has_cache do
      with_locales(:uk, :ru) do
        pages self
        pages(:home, :about, :contacts, Product.published, Article.published) do
          fragments "header", "footer"
        end
        
        fragments :mini_cart
      end
    
      with_locales(:all) do
        pages(:services, :sitemap) if image.changed?
      end
    end
end
```

## rails_admin custom scopes
Warning: this functionality works properly with rails_admin 1.4.2 and does not work with rails_admin 2.0.2. Other version were not tested.

## Development

### TODO:
Caching
notify associations about changes
lib/cms/active_record_extensions.rb #has_content_blocks
# define_method "#{name}_changed?"

I18n Cms.t must support 'raise: true' option


After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cms.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

