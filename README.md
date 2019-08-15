# DalliStoreWithCas

Provides ActiveSupport::Cache::DalliStoreWithCas which inherits dalli's ActiveSupport::Cache::DalliStore cache adapter 
and extends it with two new methods, cas and cas_multi. These methods are specifically implemented to be compatible with IdentityCache
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

## Config

In your Rails application configs (ex: config/environments/production.rb)

```
config.cache_store = :dalli_store_with_cas
```




## Tests

Tests can be run via

    ruby -Ilib:test test/test_dalli_store_with_cas.rb

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/MishaConway/dalli-store-with-cas.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
