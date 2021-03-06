require 'minitest/autorun'
require 'mocha/setup'
require 'timecop'

require 'active_support'

ActiveSupport.test_order = :random if ActiveSupport.respond_to?(:test_order)

require 'active_support/test_case'

require 'active_support/cache/dalli_store_with_cas'