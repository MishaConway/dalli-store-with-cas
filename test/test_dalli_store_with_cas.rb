require 'test_helper'
require 'logger'

class TestDalliStoreWithCas < ActiveSupport::TestCase
	setup do
		@cache = ActiveSupport::Cache.lookup_store(:dalli_store_with_cas, expires_in: 60, raise_errors: false)
		@cache.clear

		# Enable ActiveSupport notifications. Can be disabled in Rails 5.
		Thread.current[:instrument_cache_store] = true
	end

	def test_should_read_and_write_strings
		assert @cache.write('foo', 'bar')
		assert_equal 'bar', @cache.read('foo')
	end

	def test_should_overwrite
		@cache.write('foo', 'bar')
		@cache.write('foo', 'baz')
		assert_equal 'baz', @cache.read('foo')
	end

	def test_fetch_without_cache_miss
		@cache.write('foo', 'bar')
		@cache.expects(:write).never
		assert_equal 'bar', @cache.fetch('foo') { 'baz' }
	end

	def test_fetch_with_cache_miss
		@cache.expects(:write).with('foo', 'baz', {})
		assert_equal 'baz', @cache.fetch('foo') { 'baz' }
	end

	def test_fetch_with_forced_cache_miss
		@cache.write('foo', 'bar')
		@cache.expects(:read).never
		@cache.expects(:write).with('foo', 'bar', force: true)
		@cache.fetch('foo', force: true) { 'bar' }
	end

	def test_fetch_with_cached_nil
		store = ActiveSupport::Cache::DalliStoreWithCas.new([], cache_nils: true)
		store.write('foo', nil)
		store.expects(:write).never
		assert_nil store.fetch('foo') { 'baz' }
	end

	def test_cas
		@cache.write('foo', 'blah')
		assert(@cache.cas('foo') do |value|
			assert_equal 'blah', value
			'bar'
		end)
		assert_equal 'bar', @cache.read('foo')
	end

	def test_cas_with_cache_failure
		@cache.write('failing_key', 'blah')
		refute @cache.cas('failing_key') { |_value| raise Dalli::DalliError }
	end

	def test_cas_with_conflict
		@cache.write('foo', 'bar')
		refute @cache.cas('foo') { |_value|
			@cache.write('foo', 'baz')
			'biz'
		}
		assert_equal 'baz', @cache.read('foo')
	end

	def test_cas_multi_with_empty_set
		refute @cache.cas_multi { |_hash| flunk }
	end

	def test_cas_multi
		@cache.write('foo', 'bar')
		@cache.write('fud', 'biz')
		assert_equal true, (@cache.cas_multi('foo', 'fud') do |hash|
			assert_equal({ "foo" => "bar", "fud" => "biz" }, hash)
			{ "foo" => "baz", "fud" => "buz" }
		end)
		assert_equal({ "foo" => "baz", "fud" => "buz" }, @cache.read_multi('foo', 'fud'))
	end

	def test_cas_multi_with_altered_key
		@cache.write('foo', 'baz')
		assert @cache.cas_multi('foo') { |_hash| { 'fu' => 'baz' } }
		assert_nil @cache.read('fu')
		assert_equal 'baz', @cache.read('foo')
	end

	def test_cas_multi_with_cache_miss
		assert(@cache.cas_multi('not_exist') do |hash|
			assert hash.empty?
			{}
		end)
	end

	def test_cas_multi_with_partial_miss
		@cache.write('foo', 'baz')
		assert(@cache.cas_multi('foo', 'bar') do |hash|
			assert_equal({ "foo" => "baz" }, hash)
			{}
		end)
		assert_equal 'baz', @cache.read('foo')
	end

	def test_cas_multi_with_partial_update
		@cache.write('foo', 'bar')
		@cache.write('fud', 'biz')
		assert(@cache.cas_multi('foo', 'fud') do |hash|
			assert_equal({ "foo" => "bar", "fud" => "biz" }, hash)

			{ "foo" => "baz" }
		end)
		assert_equal({ "foo" => "baz", "fud" => "biz" }, @cache.read_multi('foo', 'fud'))
	end

	def test_cas_multi_with_partial_conflict
		@cache.write('foo', 'bar')
		@cache.write('fud', 'biz')
		result = @cache.cas_multi('foo', 'fud') do |hash|
			assert_equal({ "foo" => "bar", "fud" => "biz" }, hash)
			@cache.write('foo', 'bad')
			{ "foo" => "baz", "fud" => "buz" }
		end
		assert result
		assert_equal({ "foo" => "bad", "fud" => "buz" }, @cache.read_multi('foo', 'fud'))
	end

	def test_should_read_and_write_hash
		assert @cache.write('foo', a: "b")
		assert_equal({ a: "b" }, @cache.read('foo'))
	end

	def test_should_read_and_write_integer
		assert @cache.write('foo', 1)
		assert_equal 1, @cache.read('foo')
	end

	def test_should_read_and_write_nil
		assert @cache.write('foo', nil)
		assert_equal nil, @cache.read('foo')
	end

	def test_should_read_and_write_false
		assert @cache.write('foo', false)
		assert_equal false, @cache.read('foo')
	end

	def test_read_multi
		@cache.write('foo', 'bar')
		@cache.write('fu', 'baz')
		@cache.write('fud', 'biz')
		assert_equal({ "foo" => "bar", "fu" => "baz" }, @cache.read_multi('foo', 'fu'))
	end

	def test_read_multi_with_expires
		@cache.write('foo', 'bar', expires_in: 1)
		@cache.write('fu', 'baz')
		@cache.write('fud', 'biz')
		sleep 2
		assert_equal({ "fu" => "baz" }, @cache.read_multi('foo', 'fu'))
	end

	def test_read_multi_not_found
		assert_equal({}, @cache.read_multi('foe', 'fue'))
	end

	def test_read_multi_with_empty_set
		assert_equal({}, @cache.read_multi)
	end

	def test_read_and_write_compressed_small_data
		@cache.write('foo', 'bar', compress: true)
		assert_equal 'bar', @cache.read('foo')
	end

	def test_read_and_write_compressed_large_data
		@cache.write('foo', 'bar', compress: true, compress_threshold: 2)
		assert_equal 'bar', @cache.read('foo')
	end

	def test_read_and_write_compressed_nil
		@cache.write('foo', nil, compress: true)
		assert_nil @cache.read('foo')
	end

	def test_cache_key
		obj = Object.new
		def obj.cache_key
			:foo
		end
		@cache.write(obj, "bar")
		assert_equal "bar", @cache.read("foo")
	end

	def test_param_as_cache_key
		obj = Object.new
		def obj.to_param
			"foo"
		end
		@cache.write(obj, "bar")
		assert_equal "bar", @cache.read("foo")
	end

	def test_array_as_cache_key
		@cache.write([:fu, "foo"], "bar")
		assert_equal "bar", @cache.read("fu/foo")
	end

	def test_hash_as_cache_key
		@cache.write({ foo: 1, fu: 2 }, "bar")
		assert_equal "bar", @cache.read("foo=1/fu=2")
	end

	def test_keys_are_case_sensitive
		@cache.write("foo", "bar")
		assert_nil @cache.read("FOO")
	end

	def test_exist
		@cache.write('foo', 'bar')
		assert_equal true, @cache.exist?('foo')
		assert_equal false, @cache.exist?('bar')
	end

	def test_delete
		@cache.write('foo', 'bar')
		assert @cache.exist?('foo')
		assert @cache.delete('foo')
		assert !@cache.exist?('foo')

		assert_equal nil, @cache.delete('foo')
	end

	def test_initialize_accepts_a_list_of_servers_in_options
		options = ["localhost:21211"]
		cache = ActiveSupport::Cache.lookup_store(:dalli_store_with_cas, options)
		servers = cache.instance_variable_get(:@data).instance_variable_get(:@servers)
		assert_equal ["localhost:21211"], extract_host_port_pairs(servers)
	end

	def test_multiple_servers
		options = ["localhost:21211", "localhost:11211"]
		cache = ActiveSupport::Cache.lookup_store(:dalli_store_with_cas, options)
		servers = extract_host_port_pairs(cache.instance_variable_get(:@data).instance_variable_get(:@servers))
		assert_equal ["localhost:21211", "localhost:11211"], servers
	end

	def test_logger_defaults_to_dalli_logger
		assert_equal Dalli.logger, @cache.logger
	end

	private

	def extract_host_port_pairs(servers)
		servers.map { |host| host.split(':')[0..1].join(':') }
	end
end