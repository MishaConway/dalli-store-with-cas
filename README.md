# DalliStoreWithCas

Provides ActiveSupport::Cache::DalliStoreWithCas which inherits dalli's ActiveSupport::Cache::DalliStore cache adapter 
extends it with two new methods, cas and cas_multi. These methods are specifically implemented to be compatible with IdentityCache
so it's good news for 
    
    - those wishing to use Dalli with IdentityCache with full support 
      (with normal DalliStore, IdentityCache activates its 'fallback fetcher',
       which doesn't protect against various race conditions leading to corrupted data 
    
    - those who just want cas support on DalliStore

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dalli-store-with-cas'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dalli-store-with-cas

## Usage

Usage instructions to be added

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Tests

Tests can be run via

    ruby -Ilib:test test/test_dalli_store_with_cas.rb

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MishaConway/dalli-store-with-cas.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
